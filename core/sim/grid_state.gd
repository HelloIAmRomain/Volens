class_name GridState
extends RefCounted
## Grille du niveau [DCT §4.1]. Cases indexées en ligne : index = y * size.x + x.
##
## Vocabulaire de cases fermé pour la v1.0 [CDC §8.1, RG-14]. RESOURCE,
## DROPOFF, PRESSURE_DOOR et ONE_WAY sont reconnus mais inertes tant que les
## règles qui leur donnent un sens (R06, R11, R12) ne sont pas implémentées
## (hors périmètre du lot S2 — chapitres 2 et 4).
enum CellType {
	EMPTY = 0,
	WALL = 1,
	EXIT = 2,
	STATIC_DANGER = 3,
	CYCLIC_DANGER = 4,
	RESOURCE = 5,
	DROPOFF = 6,
	PRESSURE_DOOR = 7,
	ONE_WAY = 8,
	LIGHT_SOURCE = 9,
	## BASCULE — le complément permanent de la porte à pression.
	##
	## La plaque (`PRESSURE_DOOR`) est MOMENTANÉE : la porte se referme dès que
	## les agents quittent la commande, ce qui oblige à immobiliser une partie de
	## la nuée pendant que l'autre passe. La bascule est son inverse exact : le
	## premier agent qui la foule ouvre les portes **définitivement**.
	##
	## Les deux ensemble donnent le choix que le concepteur demandait : « ça peut
	## être permanent ou activé uniquement à la pression, donc plein de
	## possibilités ». L'un coûte des agents en permanence, l'autre coûte un
	## détour une seule fois.
	##
	## L'ÉTAT TIENT DANS LE TYPE DE CASE, et c'est ce qui rend le mécanisme sûr :
	## l'empreinte d'état couvre déjà `cells`, donc une bascule franchie change
	## l'empreinte sans qu'on ait à toucher `StateHash` — et les recettes d'or des
	## niveaux qui n'en portent pas ne bougent pas d'un bit.
	SWITCH = 10,
	SWITCH_USED = 11,
}

var size: Vector2i = Vector2i.ZERO
var cells: PackedInt32Array = PackedInt32Array()       # CellType par case
var pheromone: PackedInt32Array = PackedInt32Array()   # intensité de piste par case (R08/R09)
var cycles: Array[CycleDef] = []
## Index dans `cycles` pour les cases CYCLIC_DANGER ; -1 = pas de cycle.
var cycle_index: PackedInt32Array = PackedInt32Array()

func index_of(pos: Vector2i) -> int:
	return pos.y * size.x + pos.x

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < size.x and pos.y < size.y

func cell_type_at(pos: Vector2i) -> int:
	return cells[index_of(pos)]

func is_walkable(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return cell_type_at(pos) != CellType.WALL

## Un agent vient d'entrer sur une bascule armée : elle se dépense.
##
## IRRÉVERSIBLE, ET C'EST LE MÉCANISME. Une bascule qui se rearmerait ferait un
## puzzle de minutage, où l'on compte les ticks entre deux passages ; une
## bascule à sens unique fait un puzzle de PLANIFICATION, où l'on décide qui va
## la chercher. Le second est le jeu que Volens propose — on compose une
## politique, on ne pilote pas des agents.
func spend_switch(pos: Vector2i) -> bool:
	var idx: int = index_of(pos)
	if cells[idx] != CellType.SWITCH:
		return false
	cells[idx] = CellType.SWITCH_USED
	return true

## Vrai si la case est un danger actif à `tick` (statique = toujours actif ;
## cyclique = actif selon son CycleDef).
func is_danger_active_at(pos: Vector2i, tick: int) -> bool:
	var t: int = cell_type_at(pos)
	if t == CellType.STATIC_DANGER:
		return true
	if t == CellType.CYCLIC_DANGER:
		var idx: int = cycle_index[index_of(pos)]
		if idx < 0:
			return false
		return cycles[idx].is_active_at(tick)
	return false

## SENS UNIQUE (RG-14) — direction AUTORISÉE de la case, indexée comme
## `Directions` ; -1 sur toute case qui n'est pas un sens unique.
##
## Franchissable dans une seule direction : entrer dans la case en s'y
## déplaçant vers `one_way_dir` est permis, tout autre sens est refusé. Le
## contrôle porte sur le PAS, pas sur la case seule — d'où `can_traverse`, que
## toutes les règles emploient à la place de `is_walkable`.
var one_way_dir: PackedInt32Array = PackedInt32Array()

## PORTE À PRESSION (RG-14) — index dans `doors` pour les cases PRESSURE_DOOR
## ET pour leurs cases de commande ; -1 partout ailleurs.
var door_index: PackedInt32Array = PackedInt32Array()
var doors: Array[DoorDef] = []
## État calculé, recalculé à la fin de chaque tick par `recompute_doors` : 1 si
## la porte d'index i est ouverte. Dérivé des positions des agents, jamais saisi.
var doors_open: PackedInt32Array = PackedInt32Array()

func _ensure_layers() -> void:
	var n: int = size.x * size.y
	if one_way_dir.size() != n:
		one_way_dir.resize(n)
		one_way_dir.fill(-1)
	if door_index.size() != n:
		door_index.resize(n)
		door_index.fill(-1)

## Le PAS de `from` vers `to` est-il franchissable ? C'est la question que les
## règles doivent poser — `is_walkable` ne connaît que le mur, et ni un sens
## unique ni une porte fermée ne sont des murs.
##
## `from` est ignoré partout sauf sur un sens unique : le coût est nul et
## l'appel reste lisible.
## TYPE DE CASE NEUTRALISÉ PAR R16, ou -1. Posé sur la grille par `SimCore.step`
## à partir de la pile, jamais saisi et jamais haché : c'est une lecture de la
## PILE, pas un état du monde, et la pile est constante pendant toute une
## simulation.
##
## IL VIT ICI ET NON SUR `SimState` PARCE QUE C'EST ICI QU'IL SERT. Les règles
## demandent « ce pas est-il franchissable ? » à la grille, pas à l'état ; un
## joker rangé ailleurs n'aurait été consulté par personne — défaut mesuré en
## construisant N22, où « ignorer les portes » ne franchissait aucune porte.
var ignored_cell: int = -1

func can_traverse(from: Vector2i, to: Vector2i) -> bool:
	return can_traverse_ignoring(from, to, ignored_cell)

## `ignored` : type de case neutralisé par R16, ou -1. Le mur n'est JAMAIS
## ignorable — le joker ouvrirait sinon tous les niveaux d'un coup, et un jeu
## dont la dernière règle annule la géométrie n'a plus de niveaux.
func can_traverse_ignoring(from: Vector2i, to: Vector2i, ignored: int) -> bool:
	if not is_in_bounds(to):
		return false
	var idx: int = index_of(to)
	var t: int = cells[idx]
	if t == CellType.WALL:
		return false
	if t == CellType.PRESSURE_DOOR and not is_door_open_at(to) and ignored != CellType.PRESSURE_DOOR:
		return false
	if not one_way_dir.is_empty() and ignored != CellType.ONE_WAY:
		var allowed: int = one_way_dir[idx]
		if allowed >= 0 and to - from != Directions.offset(allowed):
			return false
	return true

func is_door_open_at(pos: Vector2i) -> bool:
	if door_index.is_empty():
		return true
	var d: int = door_index[index_of(pos)]
	if d < 0 or d >= doors_open.size():
		return true
	return doors_open[d] == 1

## Recalcule l'état des portes à partir des positions des agents PRÉSENTS.
## Ordre total garanti : les portes sont parcourues par index croissant et les
## cases de commande dans l'ordre du fichier de niveau. Aucun `Dictionary`.
## Une bascule a-t-elle été franchie ? Les portes sont alors ouvertes pour de
## bon, quelles que soient les plaques.
func switch_latched() -> bool:
	for c in cells:
		if c == CellType.SWITCH_USED:
			return true
	return false

func recompute_doors(agents: Array[AgentState]) -> void:
	if doors.is_empty():
		return
	if doors_open.size() != doors.size():
		doors_open.resize(doors.size())
	var counts := PackedInt32Array()
	counts.resize(doors.size())
	for agent in agents:
		if not agent.is_present():
			continue
		var idx: int = index_of(agent.pos)
		var d: int = door_index[idx]
		# Une case de commande est une case ORDINAIRE rattachée à une porte ;
		# le panneau lui-même n'est pas sa propre commande, sans quoi un agent
		# debout dans l'embrasure la maintiendrait ouverte tout seul.
		if d >= 0 and cells[idx] != CellType.PRESSURE_DOOR:
			counts[d] += 1
	# LA BASCULE L'EMPORTE SUR LES PLAQUES, jamais l'inverse : une fois franchie,
	# elle ouvre tout et rien ne referme. C'est ce qui la distingue de la plaque —
	# et c'est aussi ce qui la rend planifiable : le joueur peut envoyer un agent
	# la chercher, puis oublier le problème.
	# `required <= 0` DÉCLARE UNE PORTE À BASCULE SEULE : aucune plaque ne
	# l'ouvre, et il faut le dire explicitement — `counts >= 0` serait vrai
	# d'emblée, et la porte serait ouverte dès le premier tick.
	var latched := switch_latched()
	for i in range(doors.size()):
		var by_plates: bool = doors[i].required > 0 and counts[i] >= doors[i].required
		doors_open[i] = 1 if latched or by_plates else 0

## R13 « Boucher » : le danger cesse définitivement d'exister. Irréversible —
## c'est ce qui fait du sacrifice un choix et non une dépense renouvelable.
func neutralize_danger(pos: Vector2i) -> void:
	var idx: int = index_of(pos)
	if cells[idx] == CellType.STATIC_DANGER or cells[idx] == CellType.CYCLIC_DANGER:
		cells[idx] = CellType.EMPTY
		if not cycle_index.is_empty():
			cycle_index[idx] = -1

func clone() -> GridState:
	var copy := GridState.new()
	copy.size = size
	copy.cells = cells.duplicate()
	copy.pheromone = pheromone.duplicate()
	copy.cycle_index = cycle_index.duplicate()
	copy.one_way_dir = one_way_dir.duplicate()
	copy.door_index = door_index.duplicate()
	copy.doors_open = doors_open.duplicate()
	copy.ignored_cell = ignored_cell
	copy.doors = doors        # immuable après chargement : partagé, jamais muté
	copy.cycles = []
	for c in cycles:
		copy.cycles.append(c.clone())
	return copy
