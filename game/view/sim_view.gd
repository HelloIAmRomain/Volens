class_name SimView
extends Node2D
## Rendu de la simulation (T-030, DCT §6). Ne lit `core/` que pour afficher :
## aucune décision de jeu ici, aucune écriture dans l'état. Sens de dépendance
## respecté — game/view → core/replay → core/sim, jamais l'inverse.
##
## DT-13 : nuée et traînées en MultiMesh 2D (un appel de dessin chacune),
## halos et hachures par shaders `canvas_item` sur des primitives, zéro
## texture importée. ÉCART À SIGNALER : les cases sont rendues en MultiMesh
## plutôt qu'en TileMapLayer — un TileMapLayer impose un atlas de texture, ce
## que « tout le visuel est procédural » interdit, et une grille de niveau ne
## dépasse pas 14x18 = 252 cases. Un seul appel de dessin dans les deux cas.
##
## DCT §6.2 : la position affichée est interpolée entre le tick courant et le
## suivant, au prorata du temps écoulé — 60 i/s quelle que soit la cadence de
## simulation, sans contact avec `sim` (DT-06 : la simulation n'a pas d'horloge).

## Calques. L'ordre en z n'est PAS la hiérarchie de dominance de DA-02 : la
## sortie est une feature du sol, elle passe donc sous la nuée ; la lumière
## aussi, un agent qui la foule doit la masquer. La dominance, elle, tient à
## la luminosité par unité de surface — voir `ViewPalette`.
enum Layer { DECOR = 0, EXIT = 5, DANGER = 10, LIGHT = 15, TRAIL = 20, AGENT = 30, GOAL = 40 }

const AGENT_SHADER := preload("res://game/view/shaders/agent.gdshader")
const HALO_SHADER := preload("res://game/view/shaders/halo.gdshader")
const HATCH_SHADER := preload("res://game/view/shaders/hatch.gdshader")
const LIGHT_SHADER := preload("res://game/view/shaders/light.gdshader")
const EXIT_SHADER := preload("res://game/view/shaders/exit.gdshader")

## Traînée : longueur en TICKS, pas en images — c'est la forme collective
## dans le temps de simulation qui est en question (DA-01), pas un flou.
var trail_ticks: int = 6
## Coloration des agents par règle décisionnaire — SURCOUCHE DE DIAGNOSTIC,
## jamais l'état normal du jeu. DA-01 fait de la forme collective le
## personnage principal, et une nuée à quatre couleurs détruit cette lecture.
## Elle n'est allumée que depuis le banc (`game/bench/`, jetable) ; l'écran de
## jeu ne l'expose pas. Quand elle s'allume, le terrain se désature pour que
## les teintes réservées aux éléments ne puissent pas être confondues avec les
## teintes modales du diagnostic (charte, `ViewPalette`).
var show_decision_colors: bool = false:
	set(value):
		show_decision_colors = value
		_apply_diagnostic_mode()
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		_apply_reduced_motion()

var _session: ReplaySession
var _stack: Array[int] = []
var _level_data: Dictionary = {}
var _params: RuleParams

## Interpolation : `_from` est l'état affiché, `_to` le suivant, `_alpha` la
## fraction écoulée entre les deux.
var _from: SimState
var _to: SimState
var _alpha: float = 0.0

var _cell_size: float = 32.0
var _grid_origin: Vector2 = Vector2.ZERO
## Marges réservées à l'interface (gauche, haut, droite, bas), en pixels.
## LA VUE OCCUPE TOUT L'ÉCRAN — c'est le jeu qui est le fond, et l'interface
## qui flotte au-dessus. Mais la nuée ne doit pas se glisser sous les barres :
## le cadrage se calcule donc dans le rectangle libre, pas dans le viewport.
var content_margin: Vector4 = Vector4.ZERO:
	set(value):
		content_margin = value
		_fit_to_viewport()
## Historique des positions par agent, en cases, du plus ancien au plus récent.
var _trails: Array[Array] = []
## Direction accordée au dernier tick, par agent : sert au comptage des
## demi-tours (diagnostic de tremblement, cf. sondes du 6 août).
var _last_dir: Array[Vector2i] = []
var _reversals: int = 0

var _walls_mm: MultiMeshInstance2D
var _danger_mm: MultiMeshInstance2D
var _exit_mm: MultiMeshInstance2D
var _light_mm: MultiMeshInstance2D
var _goal_mm: MultiMeshInstance2D
var _trail_mm: MultiMeshInstance2D
var _pheromone_mm: MultiMeshInstance2D
var _door_mm: MultiMeshInstance2D
var _plate_mm: MultiMeshInstance2D
var _one_way_mm: MultiMeshInstance2D
var _one_way_mark_mm: MultiMeshInstance2D
var _carrier_mm: MultiMeshInstance2D
var _agent_mm: MultiMeshInstance2D
var _deaths_mm: MultiMeshInstance2D
var _grid_lines: Node2D
var _exit_marks: Node2D
var _cargo_marks: Node2D
var _carried_marks: Node2D
var _echoes: Node2D
var _forbidden: Node2D
var _switches: Node2D
var _patrols: Node2D
var _shield_marks: Node2D

## Marques de mort : { cell, age }. Purement visuelles, jamais un état.
var _death_marks: Array = []

## Émis quand des agents franchissent la sortie au tick écoulé. La vue ne
## décide rien : elle constate une différence de compteur et le dit. Sert au
## retour haptique (ENF-24), qui n'est jamais porteur d'information exclusive.
signal agents_exited(count: int)

# --- construction ------------------------------------------------------------

func _ready() -> void:
	_grid_lines = _GridLines.new()
	_grid_lines.z_index = Layer.DECOR
	add_child(_grid_lines)

	_exit_marks = _ExitMarks.new()
	_exit_marks.z_index = Layer.EXIT + 1
	add_child(_exit_marks)

	# La cargaison se dessine AU-DESSUS du sol et SOUS la nuee : un agent est
	# POSE SUR l'objet, il ne disparait pas derriere. Place au-dessus de la nuee,
	# le losange effacait l'agent qui venait le ramasser — soit exactement le
	# moment que le joueur doit voir.
	_cargo_marks = _CargoMarks.new()
	_cargo_marks.z_index = Layer.LIGHT + 1
	add_child(_cargo_marks)

	# La charge PORTEE se dessine au-dessus de la nuee : c'est ce que l'agent
	# tient, pas ce sur quoi il marche.
	_carried_marks = _CarriedMarks.new()
	_carried_marks.z_index = Layer.AGENT + 1
	add_child(_carried_marks)

	# LES ECHOS PASSENT AU-DESSUS DE TOUT. Un evenement qu'on rate ne se rejoue
	# pas : il ne doit etre masque par rien.
	_echoes = _Echoes.new()
	_echoes.z_index = Layer.GOAL + 2
	add_child(_echoes)

	# ZONE INTERDITE : sous la nuee, au-dessus du sol. C'est une contrainte de
	# TERRAIN, pas un evenement.
	_forbidden = _ForbiddenZone.new()
	_forbidden.z_index = Layer.LIGHT + 2
	add_child(_forbidden)

	# La bascule est une commande de TERRAIN : au-dessus du sol, sous la nuée.
	_switches = _SwitchMarks.new()
	_switches.z_index = Layer.LIGHT + 3
	add_child(_switches)

	# La patrouille est un DANGER : même plan que les dangers fixes, au-dessus du
	# sol et sous la nuée.
	_patrols = _PatrolMarks.new()
	_patrols.z_index = Layer.DANGER + 1
	add_child(_patrols)

	# La protection PORTÉE se dessine au-dessus de la nuée, comme la charge.
	_shield_marks = _ShieldMarks.new()
	_shield_marks.z_index = Layer.AGENT + 2
	add_child(_shield_marks)

	_walls_mm = _make_layer(Layer.DECOR, null)
	_exit_mm = _make_layer(Layer.EXIT, EXIT_SHADER)
	_danger_mm = _make_layer(Layer.DANGER, HATCH_SHADER)
	_light_mm = _make_layer(Layer.LIGHT, LIGHT_SHADER)
	_goal_mm = _make_layer(Layer.GOAL, HALO_SHADER)
	# LA PISTE STIGMERGIQUE EST DESSINEE SOUS TOUT LE RESTE, et sans halo. C'est
	# une information de SOL — une trace laissee, pas un objet — et lui donner du
	# relief la ferait concurrencer la nuee, qui est le personnage (DA-01).
	_pheromone_mm = _make_layer(Layer.DECOR + 1, null)
	_door_mm = _make_layer(Layer.GOAL, null)
	_plate_mm = _make_layer(Layer.DECOR + 2, null)
	_one_way_mm = _make_layer(Layer.DECOR + 3, null)
	_one_way_mark_mm = _make_layer(Layer.DECOR + 4, null)
	_trail_mm = _make_layer(Layer.TRAIL, AGENT_SHADER)
	_agent_mm = _make_layer(Layer.AGENT, AGENT_SHADER)
	_carrier_mm = _make_layer(Layer.AGENT + 1, AGENT_SHADER)
	_deaths_mm = _make_layer(Layer.GOAL - 1, AGENT_SHADER)

func _make_layer(z: int, shader: Shader) -> MultiMeshInstance2D:
	var node := MultiMeshInstance2D.new()
	node.z_index = z
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = 0
	node.multimesh = mm
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		node.material = mat
	add_child(node)
	return node

func _apply_reduced_motion() -> void:
	for node in [_danger_mm, _goal_mm, _light_mm, _exit_mm]:
		if node != null and node.material is ShaderMaterial:
			(node.material as ShaderMaterial).set_shader_parameter("reduced_motion", reduced_motion)

## Diagnostic allumé : le terrain se désature, la surcouche prend les teintes
## vives. Les deux palettes ne se disputent jamais l'écran (charte, famille 3).
func _apply_diagnostic_mode() -> void:
	var wash: float = 0.35 if show_decision_colors else 1.0
	for node in [_walls_mm, _exit_mm, _danger_mm, _light_mm, _goal_mm]:
		if node != null:
			node.modulate = Color(1.0, 1.0, 1.0, wash)

# --- pilotage ----------------------------------------------------------------

## Charge un niveau. La pile peut ensuite changer sans rechargement.
func load_level(level_data: Dictionary, params: RuleParams, stack: Array[int]) -> void:
	_level_data = level_data
	_params = params
	set_stack(stack)

## Change la pile : nouvel essai, donc nouvelle session (RG-10). C'est
## l'opération qui permet de comparer deux ordonnancements de suite.
func set_stack(stack: Array[int]) -> void:
	_stack = stack.duplicate()
	var initial := SimCore.load_level(_level_data, _params)
	_session = ReplaySession.new(initial, _stack)
	_reset_display()
	_fit_to_viewport()

func reset() -> void:
	if _session == null:
		return
	_session.reset()
	_reset_display()

func _reset_display() -> void:
	_from = _session.current()
	_to = _from
	_alpha = 0.0
	_reversals = 0
	_death_marks = []
	_trails = []
	_last_dir = []
	for i in range(_from.agents.size()):
		_trails.append([_from.agents[i].pos])
		_last_dir.append(Vector2i.ZERO)
	_rebuild_static_layers()

func stack() -> Array[int]:
	return _stack.duplicate()

func current_state() -> SimState:
	return _to

func reversals() -> int:
	return _reversals

## Avance le temps d'affichage de `seconds` à `ticks_per_second`. Les ticks
## sont consommés autant de fois que nécessaire — l'affichage ne saute jamais
## un tick, même si l'image a mis longtemps à venir.
func advance(seconds: float, ticks_per_second: float) -> void:
	if _session == null:
		return
	_alpha += seconds * ticks_per_second
	var guard := 0
	while _alpha >= 1.0 and guard < 64:
		_alpha -= 1.0
		_step_one_tick()
		guard += 1
	if guard >= 64:
		_alpha = 0.0

func step_forward() -> void:
	if _session == null:
		return
	_alpha = 0.0
	_step_one_tick()

## Recule d'un tick par re-simulation (DT-12). Les traînées sont reconstruites
## depuis le début : elles ne sont qu'un affichage, jamais un état.
func step_backward() -> void:
	if _session == null:
		return
	var target: int = maxi(_session.current_tick() - 1, 0)
	seek(target)

func seek(target_tick: int) -> void:
	if _session == null:
		return
	_session.seek(maxi(target_tick, 0))
	_alpha = 0.0
	_to = _session.current()
	_from = _to
	_rebuild_trails_from_scratch()

func _step_one_tick() -> void:
	_from = _to
	_to = _session.step_forward()
	_record_tick(_from, _to)
	_mark_departures(_from, _to)
	var gone: int = _to.counters.exited - _from.counters.exited
	if gone > 0:
		agents_exited.emit(gone)

signal agent_lost(cell: Vector2i)
signal last_agent_exited(cell: Vector2i)

## CE QUI DISPARAIT DOIT SE VOIR DISPARAITRE.
##
## LE DEFAUT QUE CETTE FONCTION CORRIGE, ET IL EST GRAVE : les marques de mort
## etaient remises a zero, filtrees par age et dessinees — mais **rien ne les
## creait jamais**. La croix sur la case fatale n'a pas ete affichee une seule
## fois depuis qu'elle est ecrite. Un agent mourait, l'ecran de defaite
## arrivait, et le joueur n'avait vu ni ou ni pourquoi : « les echecs sont
## incompris » — essai sur l'appareil, 15 aout 2026.
##
## C'est la dixieme fois qu'un element du vocabulaire existe dans le moteur et
## pas a l'ecran (porteur, piste, portes, sens uniques, cargaison…). **Une
## geometrie invisible est une geometrie injuste**, et un evenement invisible
## l'est davantage : il n'y a meme pas de trace a examiner apres coup.
func _mark_departures(before: SimState, after: SimState) -> void:
	var died: int = after.counters.lost - before.counters.lost
	var left: int = after.counters.exited - before.counters.exited
	if died <= 0 and left <= 0:
		return
	var remaining := 0
	for a in after.agents:
		if a.is_present():
			remaining += 1
	var announced := false
	for i in range(mini(before.agents.size(), after.agents.size())):
		if not before.agents[i].is_present() or after.agents[i].is_present():
			continue
		# LA CASE A MONTRER EST CELLE OU L'AGENT EST ALLE, PAS CELLE D'OU IL
		# VENAIT. Un agent meurt en ENTRANT sur le danger : marquer sa position
		# d'avant dessinait l'echo une case a cote de la case rouge, et le
		# controle de letalite y repondait « non, pas de danger ici » — l'echo
		# sortait donc en vert, sur la mauvaise case, pour une mort. Deux erreurs
		# d'un coup, et toutes deux invisibles autrement qu'a la capture.
		var landed: Vector2i = after.agents[i].pos
		var fatal: bool = died > 0 \
			and _is_fatal(after.grid, before.grid, landed, after.tick)
		if fatal:
			_death_marks.append({"cell": landed, "age": 0.0, "fatal": true})
			agent_lost.emit(landed)
			continue
		# LE DERNIER SORTI, ET LUI SEUL. Un anneau par sortie ferait vingt anneaux
		# sur une victoire : du bruit, pas de l'information. C'est l'instant qui
		# TRANCHE qu'il faut montrer — celui apres lequel il ne reste personne.
		#
		# UN SEUL ECHO MEME QUAND PLUSIEURS SORTENT ENSEMBLE. Deux agents peuvent
		# franchir la sortie au MEME tick ; « il ne reste personne » est alors vrai
		# pour les deux, et deux anneaux se superposaient. L'instant est unique,
		# l'echo aussi — le premier par identifiant, l'ordre etant total et fixe
		# (invariant n°8).
		if left > 0 and remaining == 0 and not announced:
			announced = true
			_death_marks.append({"cell": landed, "age": 0.0, "fatal": false})
			last_agent_exited.emit(landed)

## La case etait-elle mortelle ? On interroge la grille d'AVANT autant que celle
## d'apres : un danger cyclique peut s'etre eteint entre les deux, et R13
## « Boucher » efface le danger dans le meme tick que le sacrifice.
func _is_fatal(after_grid: GridState, before_grid: GridState, cell: Vector2i, tick: int) -> bool:
	if before_grid.is_danger_active_at(cell, tick - 1) or before_grid.is_danger_active_at(cell, tick):
		return true
	return after_grid.is_danger_active_at(cell, tick)

## Historique des traînées et comptage des demi-tours : purement descriptif.
func _record_tick(from_state: SimState, to_state: SimState) -> void:
	for i in range(to_state.agents.size()):
		var agent := to_state.agents[i]
		if i < _trails.size():
			var t: Array = _trails[i]
			t.append(agent.pos)
			while t.size() > trail_ticks + 1:
				t.pop_front()
		var moved: Vector2i = agent.pos - from_state.agents[i].pos
		if moved != Vector2i.ZERO:
			if i < _last_dir.size() and _last_dir[i] != Vector2i.ZERO and moved == -_last_dir[i]:
				_reversals += 1
			if i < _last_dir.size():
				_last_dir[i] = moved

## Après un saut dans le temps : rejoue depuis 0 pour reconstituer les
## traînées et le compteur de demi-tours, sans toucher à la session.
func _rebuild_trails_from_scratch() -> void:
	var target: int = _session.current_tick()
	var state := SimCore.load_level(_level_data, _params)
	_trails = []
	_last_dir = []
	for i in range(state.agents.size()):
		_trails.append([state.agents[i].pos])
		_last_dir.append(Vector2i.ZERO)
	_reversals = 0
	for t in range(target):
		var next_state := SimCore.step(state, _stack)
		_record_tick(state, next_state)
		state = next_state

# --- géométrie ---------------------------------------------------------------

func _fit_to_viewport() -> void:
	if _to == null:
		return
	var vp := get_viewport_rect().size
	var grid := _to.grid.size
	if grid.x <= 0 or grid.y <= 0:
		return
	# Rectangle LIBRE : le viewport moins ce que l'interface recouvre. La vue
	# occupe tout l'écran — c'est le jeu qui est le fond — mais la nuée ne doit
	# pas se glisser sous les barres, d'où un cadrage calculé ici et non un
	# découpage du rectangle de la vue.
	var free_pos := Vector2(content_margin.x, content_margin.y)
	var free_size := vp - free_pos - Vector2(content_margin.z, content_margin.w)
	if free_size.x <= 0.0 or free_size.y <= 0.0:
		free_pos = Vector2.ZERO
		free_size = vp
	# Marge : 6 % pour que la nuée ne colle pas aux bords.
	var usable := free_size * 0.94
	_cell_size = minf(usable.x / float(grid.x), usable.y / float(grid.y))
	var span := Vector2(grid.x, grid.y) * _cell_size
	_grid_origin = free_pos + (free_size - span) * 0.5
	if _grid_lines != null:
		_grid_lines.configure(grid, _cell_size, _grid_origin)
	_rebuild_static_layers()

func _to_pixels(cell: Vector2) -> Vector2:
	return _grid_origin + (cell + Vector2(0.5, 0.5)) * _cell_size

## Case de grille sous un point de l'écran, ou (-1,-1) hors grille. Sert au
## diagnostic EF-05 : le joueur touche un agent, pas une coordonnée.
func cell_at_pixel(pixel: Vector2) -> Vector2i:
	if _to == null or _cell_size <= 0.0:
		return Vector2i(-1, -1)
	var local := (pixel - _grid_origin) / _cell_size
	var cell := Vector2i(int(floor(local.x)), int(floor(local.y)))
	if not _to.grid.is_in_bounds(cell):
		return Vector2i(-1, -1)
	return cell

## Index de l'agent présent le plus proche d'une case, dans un rayon de
## tolérance — le doigt est large, la case est petite (ENF-01).
func agent_near(cell: Vector2i, tolerance: int = 1) -> int:
	if _to == null:
		return -1
	var best := -1
	var best_dist := tolerance + 1
	for i in range(_to.agents.size()):
		var agent := _to.agents[i]
		if not agent.is_present():
			continue
		var d: int = absi(agent.pos.x - cell.x) + absi(agent.pos.y - cell.y)
		if d < best_dist:
			best_dist = d
			best = i
	return best

## Position affichée d'un agent, pour ancrer une surimpression de diagnostic.
func agent_pixel(index: int) -> Vector2:
	if _to == null or index < 0 or index >= _to.agents.size():
		return Vector2.ZERO
	return _to_pixels(Vector2(_to.agents[index].pos))

## Direction réellement accordée à un agent au dernier tick — à comparer à ce
## que sa règle avait proposé (RG-06 : le pipeline peut refuser).
func last_granted(index: int) -> Vector2i:
	if _from == null or _to == null or index >= _to.agents.size():
		return Vector2i.ZERO
	if not _from.agents[index].is_present() or not _to.agents[index].is_present():
		return Vector2i.ZERO
	return _to.agents[index].pos - _from.agents[index].pos

## État du tick PRÉCÉDENT : c'est sur lui que la décision du dernier
## mouvement a été prise (RG-07, décisions sur cliché immuable).
func previous_state() -> SimState:
	return _from

func tick() -> int:
	return 0 if _to == null else _to.tick

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		return

func _on_viewport_resized() -> void:
	_fit_to_viewport()

# --- dessin ------------------------------------------------------------------

## DÉCOMPOSITION EN RÉGIONS. Le vocabulaire de niveau est fait de cases ;
## l'œil, lui, lit des formes. Deux cases de lumière côte à côte doivent se
## lire comme UNE zone lumineuse, pas comme deux points — et la bande de
## sortie pleine largeur de ch1_01 doit se lire comme une bande.
##
## Algorithme glouton : on prend la case libre la plus haute à gauche, on
## étend vers la droite tant que le type se répète, puis vers le bas tant que
## la ligne entière se répète. Une bande pleine largeur donne UN rectangle,
## un bloc plein en donne un aussi. Les formes concaves se décomposent en
## quelques rectangles, jamais en cases isolées.
func _rects_of(predicate: Callable) -> Array:
	var grid := _to.grid
	var w: int = grid.size.x
	var h: int = grid.size.y
	var taken := {}
	var rects: Array = []
	for y in range(h):
		for x in range(w):
			var key: int = y * w + x
			if taken.has(key) or not predicate.call(Vector2i(x, y)):
				continue
			var rw := 1
			while x + rw < w and not taken.has(y * w + x + rw) and predicate.call(Vector2i(x + rw, y)):
				rw += 1
			var rh := 1
			while y + rh < h:
				var full := true
				for k in range(rw):
					if taken.has((y + rh) * w + x + k) or not predicate.call(Vector2i(x + k, y + rh)):
						full = false
						break
				if not full:
					break
				rh += 1
			for yy in range(y, y + rh):
				for xx in range(x, x + rw):
					taken[yy * w + xx] = true
			rects.append(Rect2i(x, y, rw, rh))
	return rects

func _rebuild_static_layers() -> void:
	if _to == null or _walls_mm == null:
		return
	var grid := _to.grid
	var walls: Array = []
	for r in _rects_of(func(p: Vector2i) -> bool: return grid.cell_type_at(p) == GridState.CellType.WALL):
		walls.append(_region_item(r, ViewPalette.WALL, 0.0))
	_fill_items(_walls_mm, walls)

	# CHAQUE BUT A SON TRAITEMENT, et c'est le fond du sujet : les rendre tous
	# avec le même halo faisait de la sortie — large — l'élément dominant, et
	# de la lumière — étroite — un bloc inerte. La hiérarchie DA-02 se joue
	# dans la MANIÈRE de dessiner, pas seulement dans la teinte.
	var exit_rects := _rects_of(func(p: Vector2i) -> bool: return grid.cell_type_at(p) == GridState.CellType.EXIT)
	var exit_items: Array = []
	for r in exit_rects:
		exit_items.append(_region_item(r, ViewPalette.EXIT, EXIT_BLEED))
	_fill_items(_exit_mm, exit_items)
	if _exit_marks != null:
		(_exit_marks as _ExitMarks).configure(exit_rects, grid.size, _cell_size, _grid_origin)

	# ZONE INTERDITE — lue depuis les OBJECTIFS, pas depuis le type de case : une
	# case interdite reste une case vide pour le moteur. C'est exactement ce qui
	# l'a rendue invisible pendant tout le developpement du chapitre 6.
	# BASCULES — armées et dépensées, dessinées séparément : leur état EST le
	# mécanisme, et un joueur qui ne peut pas voir qu'une bascule a servi ne
	# comprend pas pourquoi la porte reste ouverte.
	# PATROUILLES — leur TRAJET et leur position courante. Les deux, et pas
	# seulement la position : un danger mobile dont on ne voit pas le chemin ne se
	# prévoit pas, et un danger imprévisible punit sans rien enseigner. Le jeu
	# n'a aucun aléatoire (invariant n°6) ; il serait absurde d'en simuler un.
	if _patrols != null:
		var routes: Array = []
		var heads: Array[Vector2i] = []
		var nexts: Array[Vector2i] = []
		for pi in range(grid.patrols.size()):
			var route: Array[Vector2i] = []
			for cell in grid.patrols[pi]:
				@warning_ignore("integer_division")
				route.append(Vector2i(cell % grid.size.x, cell / grid.size.x))
			routes.append(route)
			# `_to.tick` explicitement : `tick` désigne une méthode dans cette
			# portée, et la confusion passait le typage sans broncher.
			heads.append(grid.patrol_at(pi, _to.tick))
			nexts.append(grid.patrol_at(pi, _to.tick + 1))
		(_patrols as _PatrolMarks).configure(routes, heads, nexts, _cell_size, _grid_origin)

	if _switches != null:
		var armed: Array[Vector2i] = []
		var spent: Array[Vector2i] = []
		for y in range(grid.size.y):
			for x in range(grid.size.x):
				var sp := Vector2i(x, y)
				match grid.cell_type_at(sp):
					GridState.CellType.SWITCH:
						armed.append(sp)
					GridState.CellType.SWITCH_USED:
						spent.append(sp)
		# ATELIERS À BOUCLIERS : même balayage, même couche — ce sont tous des
		# dispositifs de terrain qu'on traverse pour obtenir quelque chose.
		var shields: Array[Vector2i] = []
		# DANGER CYCLIQUE : la marque est posée DANS LES DEUX PHASES.
		#
		# Le défaut était réel et il tombait sous le principe de clarté : un
		# danger cyclique ALLUMÉ était exactement de la même teinte qu'un danger
		# permanent. Deux zones rigoureusement identiques à l'écran, dont l'une
		# s'éteindra et l'autre jamais — le joueur n'avait aucun moyen de le
		# savoir, et le jeu paraissait capricieux.
		#
		# La phase éteinte, elle, se distinguait déjà par sa teinte dormante.
		# C'était le pire découpage possible : la différence n'apparaissait que
		# lorsqu'elle avait cessé d'être utile, et disparaissait au moment où
		# elle décidait de la vie d'un agent.
		var pulsing: Array[Vector2i] = []
		for y in range(grid.size.y):
			for x in range(grid.size.x):
				var cp := Vector2i(x, y)
				match grid.cell_type_at(cp):
					GridState.CellType.SHIELD:
						shields.append(cp)
					GridState.CellType.CYCLIC_DANGER:
						pulsing.append(cp)
		(_switches as _SwitchMarks).configure(armed, spent, shields, pulsing,
			_cell_size, _grid_origin)

	if _forbidden != null:
		var banned: Array[Vector2i] = []
		for entry in _level_data.get("objectives", []):
			var o: Dictionary = entry
			if String(o.get("type", "")) != "interdiction":
				continue
			for pair in (o.get("cells", []) as Array):
				banned.append(Vector2i(int(pair[0]), int(pair[1])))
		(_forbidden as _ForbiddenZone).configure(banned, _cell_size, _grid_origin)
	_fill_items(_light_mm, _regions_of(GridState.CellType.LIGHT_SOURCE, ViewPalette.LIGHT, LIGHT_BLEED))

	# RESSOURCE ET DEPOT NE SONT PLUS DES ZONES TEINTEES.
	#
	# Le defaut, vu a la capture : les deux etaient rendus comme des BANDES de
	# sol colorees, exactement comme la sortie ou la lumiere. Le joueur voyait
	# deux rectangles de couleurs differentes et n'avait aucun moyen de deviner
	# que l'un est une CHOSE qu'on ramasse et l'autre un ENDROIT ou la poser —
	# il n'y a pas de tutoriel, le jeu doit se lire seul.
	#
	# Desormais : la ressource est un OBJET pose au sol (losange plein, avec son
	# ombre), le depot est un RECEPTACLE ouvert (crochet en U, chevron entrant),
	# et l'agent qui porte arbore le MEME losange. C'est cette identite de forme
	# qui rend la scene lisible sans un mot : on voit le losange quitter le sol
	# et monter sur un agent, puis disparaitre dans le crochet.
	#
	# Seul le depot garde un halo de sol, tres discret : c'est une destination,
	# donc un lieu — mais il ne doit plus se confondre avec la sortie.
	var goals: Array = []
	goals.append_array(_regions_of(GridState.CellType.DROPOFF, ViewPalette.DROPOFF, GOAL_BLEED))
	# PORTE A PRESSION ET SENS UNIQUE, huitieme et septieme elements de RG-14.
	# Ils etaient reconnus par le moteur et absents de l'ecran : une geometrie
	# invisible est une geometrie injuste, et le joueur aurait vu sa nuee butter
	# sur du vide.
	_fill_items(_goal_mm, goals)

	if _cargo_marks != null:
		var resources: Array[Vector2i] = []
		var dropoffs: Array[Vector2i] = []
		for y in range(grid.size.y):
			for x in range(grid.size.x):
				var p := Vector2i(x, y)
				match grid.cell_type_at(p):
					GridState.CellType.RESOURCE:
						resources.append(p)
					GridState.CellType.DROPOFF:
						dropoffs.append(p)
		(_cargo_marks as _CargoMarks).configure(
			resources, dropoffs, _cell_size, _grid_origin)

	# SENS UNIQUE — dessine depuis `one_way_dir`, PAS depuis le type de case.
	# Defaut trouve a la capture : une case a sens unique reste de type EMPTY,
	# son orientation vivant dans une couche a part. Le rendu la cherchait par
	# `cell_type_at` et ne trouvait jamais rien : la geometrie la plus
	# contraignante du jeu — celle qu'on ne peut pas defaire — etait invisible.
	var one_ways: Array = []
	var arrows: Array = []
	for idx in range(grid.one_way_dir.size()):
		var dir: int = grid.one_way_dir[idx]
		if dir < 0:
			continue
		var p := Vector2(idx % grid.size.x, idx / grid.size.x)
		var tint := ViewPalette.ONE_WAY
		tint.a = 0.20
		one_ways.append([p, tint])
		# LA DIRECTION SE MONTRE, elle ne se devine pas : un marqueur decale vers
		# le sens AUTORISE. Sans lui, deux sens uniques opposes seraient
		# identiques a l'oeil, et le joueur ne pourrait pas planifier.
		var mark := ViewPalette.ONE_WAY
		mark.a = 0.90
		arrows.append([p + Vector2(Directions.offset(dir)) * 0.26, mark])
	_fill(_one_way_mm, one_ways, _cell_size * 0.92)
	_fill(_one_way_mark_mm, arrows, _cell_size * 0.30)

## Débords, en cases. La lumière déborde LARGEMENT — c'est ce débord qui la
## fait lire comme une source et non comme une case remplie. La sortie déborde
## à peine : un seuil ne rayonne pas.
const GOAL_BLEED := 0.45
const LIGHT_BLEED := 1.35
const EXIT_BLEED := 0.12

func _regions_of(wanted: int, color: Color, bleed: float) -> Array:
	var grid := _to.grid
	var out: Array = []
	for r in _rects_of(func(p: Vector2i) -> bool: return grid.cell_type_at(p) == wanted):
		out.append(_region_item(r, color, bleed))
	return out

## Construit l'instance d'une région : quad élargi de `bleed` cases, couleur,
## et données par instance — (largeur, hauteur, débord) en CASES. Une seule
## convention pour tous les shaders de région : chacun retrouve seul ses
## coordonnées en cases, et la densité d'un motif ne dépend jamais de la
## taille du quad.
func _region_item(r: Rect2i, color: Color, bleed: float) -> Dictionary:
	var cells := Vector2(r.size.x, r.size.y)
	var span := cells + Vector2(bleed, bleed) * 2.0
	var centre := Vector2(r.position.x, r.position.y) + cells * 0.5
	return {
		"pos": _grid_origin + centre * _cell_size,
		"size": span * _cell_size,
		"color": color,
		"custom": Color(cells.x, cells.y, bleed, 0.0),
	}

## Durée d'une marque de mort ⚙️ : assez pour être vue, pas au point de
## traîner sur l'écran suivant.
const DEATH_MARK_SECONDS := 1.6

func _process(dt: float) -> void:
	if _to == null:
		return
	for mark in _death_marks:
		mark["age"] = float(mark["age"]) + dt
	_death_marks = _death_marks.filter(func(m: Dictionary) -> bool:
		return float(m["age"]) < DEATH_MARK_SECONDS)
	_draw_deaths()
	_draw_dangers()
	_draw_trails()
	_draw_pheromone()
	_draw_doors()
	_draw_agents()

## Les dangers se dessinent aussi par RÉGION, et séparément selon leur phase :
## un danger actif et un danger dormant ne se fondent jamais dans la même
## forme, sans quoi le joueur croirait toute la zone dangereuse.
func _draw_dangers() -> void:
	var grid := _to.grid
	var tick := _to.tick
	var items: Array = []
	var active := func(p: Vector2i) -> bool:
		var t2: int = grid.cell_type_at(p)
		if t2 != GridState.CellType.STATIC_DANGER and t2 != GridState.CellType.CYCLIC_DANGER:
			return false
		return grid.is_danger_active_at(p, tick)
	var dormant := func(p: Vector2i) -> bool:
		var t2: int = grid.cell_type_at(p)
		if t2 != GridState.CellType.CYCLIC_DANGER:
			return false
		return not grid.is_danger_active_at(p, tick)
	for r in _rects_of(active):
		items.append(_region_item(r, ViewPalette.DANGER, 0.0))
	for r in _rects_of(dormant):
		items.append(_region_item(r, ViewPalette.DANGER_DORMANT, 0.0))
	_fill_items(_danger_mm, items)

## UN ECHO : un anneau qui s'ouvre depuis la case et s'efface. Rouge pour une
## mort, vert pour le dernier agent sorti.
##
## POURQUOI UN ANNEAU ET NON UN CLIGNOTEMENT. Un clignotement demande a etre
## regarde au bon moment ; un anneau qui s'ouvre laisse une trace dans le
## mouvement, se remarque du coin de l'oeil, et dit OU l'evenement a eu lieu.
## C'est aussi ce que demande ENF-21 (animations reduites) : l'echo se contente
## alors d'un halo fixe, sans jamais disparaitre.
func _draw_deaths() -> void:
	if _echoes != null:
		(_echoes as _Echoes).configure(_death_marks, DEATH_MARK_SECONDS,
			_cell_size, _grid_origin, reduced_motion)
	_fill(_deaths_mm, [], _cell_size)

func _death_pulse() -> float:
	if _death_marks.is_empty():
		return 0.0
	return float(_death_marks[0]["age"]) / DEATH_MARK_SECONDS

func _draw_agents() -> void:
	var items: Array = []
	var carried: Array = []
	var shielded: Array = []
	for i in range(_to.agents.size()):
		var to_agent := _to.agents[i]
		var from_agent := _from.agents[i] if i < _from.agents.size() else to_agent
		# Un agent qui vient de sortir ou de mourir s'efface sur le tick.
		var alpha := 1.0
		if not to_agent.is_present():
			if not from_agent.is_present():
				continue
			alpha = 1.0 - _alpha
		var cell: Vector2 = Vector2(from_agent.pos).lerp(Vector2(to_agent.pos), _alpha)
		var color := ViewPalette.AGENT_PLAIN
		# UN AGENT PROTÉGÉ SE DISTINGUE AU PREMIER COUP D'ŒIL. L'arc posé au-dessus
		# de lui disait déjà « celui-ci est équipé », mais il fallait le chercher :
		# à l'échelle d'une nuée de vingt points en mouvement, une marque de la
		# taille d'un cheveu ne se voit pas. L'agent LUI-MÊME vire vers le bleu du
		# bouclier.
		#
		# ENF-20 TIENT : l'information ne repose PAS sur la seule teinte — l'arc
		# reste, et c'est lui qui parle en niveaux de gris. La couleur ne fait que
		# rendre la lecture immédiate, ce qu'une forme de trois pixels ne peut pas.
		#
		# La surcouche de diagnostic l'emporte, elle : quand on colore par règle
		# décisionnaire, c'est cette question-là qu'on pose, et deux codes de
		# couleur simultanés n'en font aucun.
		if (to_agent.flags & AgentState.PROTEGE) != 0 and to_agent.is_present():
			color = ViewPalette.AGENT_PLAIN.lerp(ViewPalette.SHIELD, 0.72)
		if show_decision_colors and to_agent.is_present():
			color = ViewPalette.slot_color(_deciding_slot(to_agent, _to))
		color.a = alpha
		items.append([cell, color])
		# PORTEUR — un agent qui transporte une ressource porte sa MARQUE. Sans
		# elle, tout le chapitre 4 se joue à l'aveugle : le joueur voit une nuée
		# uniforme et ne peut pas savoir qui a ramassé, donc pas comprendre
		# pourquoi le compteur de livraisons n'avance pas.
		#
		# ENF-20 : l'information n'est pas portée par la seule couleur. C'est un
		# point AJOUTÉ sur l'agent — une forme — qui se voit en niveaux de gris
		# comme en teinte, et sa couleur est celle de la ressource, déjà apprise.
		#
		# C'EST LE MÊME LOSANGE QUE CELUI POSÉ AU SOL, et c'est tout l'intérêt :
		# un carré sur l'agent face à un losange par terre laissait DEVINER le
		# lien. La même forme le rend évident — on voit l'objet quitter le sol
		# et monter sur un agent, sans un mot d'explication.
		if (to_agent.flags & AgentState.PORTEUR) != 0 and to_agent.is_present():
			carried.append([cell, alpha])
		# UN AGENT PROTÉGÉ PORTE SA MARQUE, sans quoi le joueur voit un agent
		# traverser le rouge et survivre sans comprendre pourquoi — et conclut
		# que le danger est capricieux.
		if (to_agent.flags & AgentState.PROTEGE) != 0 and to_agent.is_present():
			shielded.append([cell, alpha])
	_fill(_agent_mm, items, _cell_size * 0.70)
	if _carried_marks != null:
		(_carried_marks as _CarriedMarks).configure(carried, _cell_size, _grid_origin)
	if _shield_marks != null:
		(_shield_marks as _ShieldMarks).configure(shielded, _cell_size, _grid_origin)

## PISTE STIGMERGIQUE (R08/R09). Redessinee a chaque image parce qu'elle change
## a chaque tick : elle s'evapore, et voir l'evaporation est la moitie de ce
## que le chapitre 3 enseigne. Un joueur qui ne voit pas la trace faiblir ne
## peut pas comprendre pourquoi sa queue de nuee s'arrete.
##
## L'INTENSITE PASSE PAR L'OPACITE, jamais par la teinte : la charte reserve
## une teinte par element de vocabulaire (RG-14), et une piste qui changerait
## de couleur en s'estompant en emprunterait a d'autres.
## PORTES A PRESSION ET LEURS COMMANDES. Dessinees a chaque image parce que
## l'etat d'une porte change a chaque tick, et parce que le voir changer EST le
## mecanisme : une porte qui s'ouvre quand deux agents se posent, et se referme
## quand ils repartent, s'explique toute seule si on la regarde.
##
## LES CASES DE COMMANDE SONT MARQUEES, ET C'ETAIT MANQUANT. Elles ne sont pas
## un type de case — le vocabulaire RG-14 est ferme a neuf — mais des cases
## ordinaires rattachees a une porte. Sans marque a l'ecran, le joueur voyait
## une porte fermee et aucune facon d'apprendre ce qui l'ouvre : injouable, et
## aucun test de simulation ne l'aurait dit.
func _draw_doors() -> void:
	if _door_mm == null or _to == null:
		return
	var grid := _to.grid
	if grid.doors.is_empty():
		_fill(_door_mm, [], _cell_size)
		return
	var panels: Array = []
	var plates: Array = []
	for idx in range(grid.door_index.size()):
		if grid.door_index[idx] < 0:
			continue
		var p := Vector2(idx % grid.size.x, idx / grid.size.x)
		var c := ViewPalette.PRESSURE_DOOR
		if grid.cells[idx] == GridState.CellType.PRESSURE_DOOR:
			# OUVERTE = EFFACEE. Une porte franchissable doit se lire comme un
			# passage, pas comme un obstacle d'une autre couleur.
			c.a = 0.22 if grid.doors_open[grid.door_index[idx]] == 1 else 0.92
			panels.append([p, c])
		else:
			c.a = 0.40
			plates.append([p, c])
	_fill(_door_mm, panels, _cell_size * 0.96)
	_fill(_plate_mm, plates, _cell_size * 0.42)

func _draw_pheromone() -> void:
	if _pheromone_mm == null or _to == null:
		return
	var grid := _to.grid
	var items: Array = []
	var ceiling: int = maxi(1, _to.rule_params.trail_max if _to.rule_params != null else 60)
	for idx in range(grid.pheromone.size()):
		var value: int = grid.pheromone[idx]
		if value <= 0:
			continue
		var c := ViewPalette.TRAIL
		# Plancher d'opacite : une trace presque eteinte doit rester VISIBLE, sinon
		# elle disparait de l'ecran avant de disparaitre du modele, et le joueur
		# voit ses agents suivre quelque chose qui n'est plus la.
		# POIDS VISUEL : premiere version mesuree a 0,78 case et 0,62 d'opacite —
		# la piste lisait comme un DALLAGE et dominait l'ecran, alors que la nuee
		# est le personnage (DA-01). Une trace au sol doit se voir sans se
		# regarder : plus petite que la case, et jamais au-dela du tiers d'opacite.
		c.a = 0.08 + 0.30 * (float(mini(value, ceiling)) / float(ceiling))
		items.append([Vector2(idx % grid.size.x, idx / grid.size.x), c])
	_fill(_pheromone_mm, items, _cell_size * 0.52)

func _draw_trails() -> void:
	var items: Array = []
	for i in range(_trails.size()):
		if i >= _to.agents.size() or not _to.agents[i].is_present():
			continue
		var t: Array = _trails[i]
		var color := ViewPalette.AGENT_PLAIN
		if show_decision_colors:
			color = ViewPalette.slot_color(_deciding_slot(_to.agents[i], _to))
		# Le plus ancien est le plus faible ; la tête de traînée est portée
		# par l'agent lui-même.
		for k in range(t.size() - 1):
			var age := float(k + 1) / float(t.size())
			var c := color
			c.a = age * 0.20
			items.append([Vector2(t[k]), c])
	_fill(_trail_mm, items, _cell_size * 0.22)

## Quelle règle a décidé pour cet agent, à ce tick ? Lecture seule : on
## interroge les mêmes règles que la simulation, on n'en réimplémente aucune
## (DT-15). Renvoie l'index d'emplacement, ou -1 si aucune ne s'applique.
func _deciding_slot(agent: AgentState, state: SimState) -> int:
	for i in range(_stack.size()):
		var rule_id: int = _stack[i]
		if rule_id == RuleRegistry.EMPTY:
			continue
		var rule := RuleRegistry.get_rule(rule_id)
		if rule == null:
			continue
		if rule.evaluate(agent, state, state.rule_params) != Rule.ABSTAIN:
			return i
	return -1

## Remplit une couche à partir de régions déjà exprimées en pixels.
func _fill_items(node: MultiMeshInstance2D, items: Array) -> void:
	if node == null:
		return
	var mm := node.multimesh
	mm.instance_count = items.size()
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var span: Vector2 = it["size"]
		mm.set_instance_transform_2d(i, Transform2D(0.0, span, 0.0, it["pos"]))
		mm.set_instance_color(i, it["color"])
		mm.set_instance_custom_data(i, it["custom"])

func _fill(node: MultiMeshInstance2D, items: Array, size: float) -> void:
	if node == null:
		return
	var mm := node.multimesh
	mm.instance_count = items.size()
	for i in range(items.size()):
		var cell: Vector2 = items[i][0]
		mm.set_instance_transform_2d(i, Transform2D(0.0, Vector2(size, size), 0.0, _to_pixels(cell)))
		mm.set_instance_color(i, items[i][1])
		mm.set_instance_custom_data(i, Color(1.0, 1.0, 0.0, 0.0))

# --- grille de fond -----------------------------------------------------------

class _GridLines extends Node2D:
	var _grid: Vector2i = Vector2i.ZERO
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(grid: Vector2i, cell: float, origin: Vector2) -> void:
		_grid = grid
		_cell = cell
		_origin = origin
		queue_redraw()

	## LE MAILLAGE DÉFAISAIT LE TRAVAIL SUR LES RÉGIONS (carnet décision 77).
	## Fusionner les cases contiguës en formes uniques ne sert à rien si l'on
	## retrace ensuite chaque frontière : l'œil redescend au niveau de la case
	## et le plateau se couvre d'un bruit constant.
	##
	## Le monde reste discret, et c'est une information de jeu — mais elle se
	## porte à trois niveaux, du plus fort au plus faible :
	##   1. les frontières INTÉRIEURES, très atténuées, présentes sans être lues ;
	##   2. rien d'autre.
	##
	## NI DALLE NI POURTOUR. Ils y étaient — un fond légèrement éclairci et un
	## cadre net censé dire « le monde s'arrête ici ». Ensemble ils dessinaient
	## une BOÎTE, et le jeu se lisait comme une fenêtre encastrée dans
	## l'interface : un écran dans l'écran. Or c'est le jeu qui compte, et
	## l'interface qui se pose dessus. Les lignes intérieures suffisent à dire
	## que le monde est discret, et elles disent où il s'arrête en s'arrêtant.
	func _draw() -> void:
		if _grid.x <= 0 or _grid.y <= 0:
			return
		var span := Vector2(_grid.x, _grid.y) * _cell
		for x in range(1, _grid.x):
			var px := _origin.x + x * _cell
			draw_line(Vector2(px, _origin.y), Vector2(px, _origin.y + span.y), ViewPalette.GRID_LINE, 1.0)
		for y in range(1, _grid.y):
			var py := _origin.y + y * _cell
			draw_line(Vector2(_origin.x, py), Vector2(_origin.x + span.x, py), ViewPalette.GRID_LINE, 1.0)


## LA SORTIE ET LA LUMIÈRE NE DOIVENT PAS SE CONFONDRE. Deux zones colorées
## côte à côte, l'une verte l'autre lumineuse, ne disent pas ce qu'elles
## font : le joueur voit deux buts sans savoir lequel est lequel, ni ce que
## la nuée va en faire. Une teinte ne suffit pas — et ENF-20 interdit de toute
## façon qu'une information tienne à la seule couleur.
##
## D'où la FORME. La sortie porte des chevrons qui pointent hors du plateau :
## c'est un passage, et un passage a un sens. La lumière, elle, rayonne et
## respire sans direction — on la vise, on ne la traverse pas. Les deux se
## distinguent désormais en silhouette, écran en noir et blanc compris.
class _ExitMarks extends Node2D:
	var _rects: Array = []
	var _grid: Vector2i = Vector2i.ZERO
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(rects: Array, grid: Vector2i, cell: float, origin: Vector2) -> void:
		_rects = rects
		_grid = grid
		_cell = cell
		_origin = origin
		queue_redraw()

	## Direction de sortie : le bord du plateau dont la région est la plus
	## proche — mais SEULEMENT sur les axes où elle ne traverse pas déjà tout
	## le plateau. Une bande pleine largeur touche les bords gauche ET droit à
	## distance nulle : les prendre en compte la faisait sortir de côté alors
	## qu'elle ne fait traverser que verticalement.
	func _outward(r: Rect2i) -> Vector2:
		var best: int = 1 << 30
		var dir := Vector2(0, -1)
		if r.size.y < _grid.y:
			var to_top: int = r.position.y
			var to_bottom: int = _grid.y - (r.position.y + r.size.y)
			if to_top <= to_bottom and to_top < best:
				best = to_top
				dir = Vector2(0, -1)
			elif to_bottom < best:
				best = to_bottom
				dir = Vector2(0, 1)
		if r.size.x < _grid.x:
			var to_left: int = r.position.x
			var to_right: int = _grid.x - (r.position.x + r.size.x)
			if to_left <= to_right and to_left < best:
				best = to_left
				dir = Vector2(-1, 0)
			elif to_right < best:
				best = to_right
				dir = Vector2(1, 0)
		return dir

	func _draw() -> void:
		if _rects.is_empty() or _cell <= 0.0:
			return
		var color := ViewPalette.EXIT.lightened(0.25)
		color.a = 0.75
		var arm: float = _cell * 0.17
		var thickness: float = maxf(_cell * 0.05, 2.0)
		for r in _rects:
			var rect: Rect2i = r
			var dir := _outward(rect)
			# Axe long de la région : c'est le long de celui-ci qu'on répartit
			# les chevrons, pour qu'une bande large en porte plusieurs et une
			# sortie d'une case exactement un.
			var along := Vector2(1, 0) if absf(dir.y) > 0.5 else Vector2(0, 1)
			var count: int = int(along.x * rect.size.x + along.y * rect.size.y)
			# Un chevron toutes les DEUX cases : un par case ferait une frise
			# clignotante, un seul au centre ne dirait pas que toute la bande
			# est traversable. Toujours au moins un.
			var step: int = 2 if count > 2 else 1
			var first: int = ((count - 1) % step) / 2
			for i in range(first, count, step):
				var cell_pos := Vector2(rect.position.x, rect.position.y) \
					+ along * float(i) + Vector2(0.5, 0.5) \
					+ (Vector2.ONE - along.abs()) * (Vector2(rect.size.x, rect.size.y) - Vector2.ONE) * 0.5
				var centre := _origin + cell_pos * _cell
				# Chevron : deux segments qui se rejoignent dans la direction
				# de sortie. Dessiné en primitives, jamais tiré d'une police.
				var side := Vector2(-dir.y, dir.x)
				var tip := centre + dir * arm
				draw_line(tip, centre - dir * arm * 0.4 + side * arm, color, thickness)
				draw_line(tip, centre - dir * arm * 0.4 - side * arm, color, thickness)

## CARGAISON — la ressource et le dépôt, dessinés en FORMES et non en zones.
##
## POURQUOI CETTE CLASSE EXISTE. Les deux étaient rendus comme des bandes de sol
## colorées, au même titre que la sortie ou la lumière. Un joueur découvrant le
## chapitre 4 voyait deux rectangles de teintes différentes, sans aucun moyen de
## deviner que l'un est une CHOSE qu'on ramasse et l'autre un ENDROIT où la
## poser. Le jeu n'a pas de tutoriel : ce qui ne se lit pas seul ne se lit pas.
##
## LE PRINCIPE, ET IL TIENT EN UNE PHRASE : **la forme qu'on ramasse est la
## forme qu'on porte.** Un losange plein posé au sol, le même losange sur
## l'agent qui l'emporte, et un réceptacle ouvert qui l'avale. La séquence se
## raconte sans un mot, et elle se lit aussi en niveaux de gris (ENF-20) parce
## que ce sont des formes, pas des teintes.
class _CargoMarks extends Node2D:
	var _resources: Array[Vector2i] = []
	var _dropoffs: Array[Vector2i] = []
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(resources: Array[Vector2i], dropoffs: Array[Vector2i],
			cell: float, origin: Vector2) -> void:
		_resources = resources
		_dropoffs = dropoffs
		_cell = cell
		_origin = origin
		queue_redraw()

	func _centre(p: Vector2i) -> Vector2:
		return _origin + (Vector2(p) + Vector2(0.5, 0.5)) * _cell

	## Le losange de cargaison. Rendu ici ET sur l'agent porteur : c'est la même
	## fonction, appelée aux deux endroits, pour que les deux ne puissent pas
	## diverger — une identité de forme maintenue à la main finit par se rompre.
	static func draw_cargo(canvas: CanvasItem, centre: Vector2, radius: float,
			alpha: float) -> void:
		var body := ViewPalette.RESOURCE
		body.a = alpha
		var edge := ViewPalette.RESOURCE.lightened(0.45)
		edge.a = alpha
		# L'ombre pose l'objet SUR le sol au lieu de le laisser flotter dedans :
		# sans elle, le losange se lit comme un motif de carrelage.
		var shadow := Color(0.0, 0.0, 0.0, 0.35 * alpha)
		var pts := PackedVector2Array([
			centre + Vector2(0, -radius), centre + Vector2(radius, 0),
			centre + Vector2(0, radius), centre + Vector2(-radius, 0)])
		var under := PackedVector2Array()
		for p in pts:
			under.append(p + Vector2(0, radius * 0.28))
		canvas.draw_colored_polygon(under, shadow)
		canvas.draw_colored_polygon(pts, body)
		canvas.draw_polyline(PackedVector2Array([
			pts[0], pts[1], pts[2], pts[3], pts[0]]), edge,
			maxf(radius * 0.16, 1.5))

	func _draw() -> void:
		if _cell <= 0.0:
			return
		for p in _resources:
			draw_cargo(self, _centre(p), _cell * 0.26, 1.0)

		# LE DÉPÔT EST UN RÉCEPTACLE, PAS UN SOL. Trois côtés d'un carré, ouverts
		# vers le haut, et un chevron qui entre : « ça se met là-dedans ». Une
		# case pleine aurait dit « marche ici », ce qui est le contraire.
		var edge := ViewPalette.DROPOFF.lightened(0.35)
		edge.a = 0.95
		var thickness: float = maxf(_cell * 0.07, 2.0)
		for p in _dropoffs:
			var c := _centre(p)
			var r: float = _cell * 0.28
			draw_polyline(PackedVector2Array([
				c + Vector2(-r, -r * 0.55), c + Vector2(-r, r),
				c + Vector2(r, r), c + Vector2(r, -r * 0.55)]), edge, thickness)
			var tip := c + Vector2(0, r * 0.10)
			draw_line(tip, tip + Vector2(-r * 0.5, -r * 0.55), edge, thickness)
			draw_line(tip, tip + Vector2(r * 0.5, -r * 0.55), edge, thickness)

## LA CHARGE PORTÉE — le même losange, sur l'agent qui l'emporte.
##
## Elle a sa propre classe parce qu'elle bouge à chaque IMAGE (position
## interpolée), là où la cargaison au sol ne change qu'au TICK. Les mêler aurait
## fait redessiner tout le décor soixante fois par seconde pour rien.
class _CarriedMarks extends Node2D:
	var _cells: Array = []
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(cells: Array, cell: float, origin: Vector2) -> void:
		_cells = cells
		_cell = cell
		_origin = origin
		queue_redraw()

	func _draw() -> void:
		if _cell <= 0.0:
			return
		for entry in _cells:
			var p: Vector2 = entry[0]
			var alpha: float = entry[1]
			# Décalée vers le haut : l'objet est TENU, il ne recouvre pas
			# l'agent. Un losange centré effaçait le point qu'il accompagne.
			var centre: Vector2 = _origin + (p + Vector2(0.5, 0.22)) * _cell
			_CargoMarks.draw_cargo(self, centre, _cell * 0.19, alpha)

## ÉCHOS D'ÉVÉNEMENT — un anneau qui s'ouvre depuis la case, puis s'efface.
##
## POURQUOI ILS EXISTENT. « Les échecs sont incompris : on ne comprend pas ce
## qui fait perdre, l'écran de défaite arrive avant le moment fatidique » —
## essai sur l'appareil, 15 août 2026. Un agent mourait sur une case rouge, et
## rien à l'écran ne le disait : ni où, ni quand. Le bilan tombait sur une
## scène où il ne s'était visiblement rien passé.
##
## ROUGE pour une mort, VERT pour le dernier agent sorti — la victoire mérite
## le même traitement que l'échec, et pour la même raison : on doit voir
## l'instant qui a décidé.
##
## UN ANNEAU, PAS UN CLIGNOTEMENT. Un clignotement demande d'être regardé au
## bon moment ; un anneau qui s'ouvre se remarque du coin de l'œil et dit OÙ.
## Sous ENF-21 (animations réduites) il devient un halo fixe qui ne bouge plus,
## sans jamais cesser d'être visible : l'information ne dépend pas du mouvement.
class _Echoes extends Node2D:
	var _marks: Array = []
	var _span: float = 1.6
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO
	var _still: bool = false

	func configure(marks: Array, span: float, cell: float, origin: Vector2,
			reduced: bool) -> void:
		_marks = marks
		_span = maxf(span, 0.001)
		_cell = cell
		_origin = origin
		_still = reduced
		queue_redraw()

	func _draw() -> void:
		if _cell <= 0.0:
			return
		for mark in _marks:
			var age: float = clampf(float(mark["age"]) / _span, 0.0, 1.0)
			var fatal: bool = bool(mark.get("fatal", true))
			var tint: Color = ViewPalette.DANGER.lightened(0.35) if fatal \
				else ViewPalette.EXIT.lightened(0.35)
			var centre: Vector2 = _origin + (Vector2(mark["cell"]) + Vector2(0.5, 0.5)) * _cell
			if _still:
				tint.a = 0.75
				draw_arc(centre, _cell * 0.75, 0.0, TAU, 40, tint,
					maxf(_cell * 0.12, 2.0), true)
				continue
			# Trois anneaux décalés dans le temps : un seul se lit comme une
			# bulle, trois se lisent comme une onde — et une onde a une SOURCE.
			for k in range(3):
				var t: float = age - float(k) * 0.16
				if t <= 0.0 or t >= 1.0:
					continue
				var ring := tint
				ring.a = (1.0 - t) * (1.0 - t) * 0.9
				draw_arc(centre, _cell * (0.35 + 1.5 * t), 0.0, TAU, 40, ring,
					maxf(_cell * 0.14 * (1.0 - t), 1.5), true)
			# L'AGENT RESTE SUR LA CASE ROUGE, LE TEMPS QU'ON LE VOIE.
			#
			# La simulation le retire au tick meme ou il entre sur le danger : il
			# n'etait donc JAMAIS visible sur la case qui le tue, et l'echo seul ne
			# disait pas « c'est un agent qui vient de mourir la ». On ne peut pas
			# ajouter un tick — `step` est une fonction pure et les empreintes d'or
			# en dependent (invariant n°10) — mais on peut le RETENIR A L'ECRAN.
			#
			# Il garde d'abord sa taille et sa teinte d'agent, puis vire vers la
			# teinte de l'evenement en s'effacant : on lit « il est la », puis « il
			# est consume ». Purement visuel, aucun etat.
			if age < 0.45:
				var t2: float = age / 0.45
				var core: Color = ViewPalette.AGENT_PLAIN.lerp(tint, t2 * t2)
				core.a = (1.0 - t2 * t2) * 0.95
				draw_circle(centre, _cell * 0.35 * (1.0 - 0.25 * t2), core)

## ZONE INTERDITE (objectif `interdiction`) — des cases où l'on ne doit pas
## mettre les pieds, sous peine de perdre À L'INSTANT.
##
## POURQUOI CETTE CLASSE EXISTE. Ces cases n'étaient **pas dessinées du tout**.
## Un agent y entrait, la partie était perdue au même tick, et rien à l'écran
## n'avait jamais indiqué qu'il y avait là quoi que ce soit. C'est le onzième
## élément du vocabulaire qui vivait dans le moteur sans exister à l'écran, et
## le plus injuste des onze : les autres rendaient le jeu incompréhensible,
## celui-ci le rendait **arbitraire**.
##
## Elles sont invisibles pour une raison structurelle qu'il faut retenir : une
## case interdite **reste une case VIDE** pour le moteur — l'interdiction vit
## dans l'objectif, pas dans la grille. Le rendu, qui parcourt les types de
## case, ne pouvait donc pas la trouver. Tout ce qui décrit le terrain sans être
## un type de case est un candidat au même oubli.
##
## HACHURES AMBRE, PAS DE ROUGE. Le rouge appartient au danger, qui TUE l'agent
## qui y entre ; l'interdiction ne tue personne, elle disqualifie la tentative.
## Deux conséquences différentes ne portent jamais la même teinte (RG-14).
class _ForbiddenZone extends Node2D:
	var _cells: Array[Vector2i] = []
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(cells: Array[Vector2i], cell: float, origin: Vector2) -> void:
		_cells = cells
		_cell = cell
		_origin = origin
		queue_redraw()

	func _draw() -> void:
		if _cells.is_empty() or _cell <= 0.0:
			return
		var fill := ViewPalette.FORBIDDEN
		fill.a = 0.10
		var edge := ViewPalette.FORBIDDEN
		edge.a = 0.55
		var thickness: float = maxf(_cell * 0.05, 1.5)
		for p in _cells:
			var top_left: Vector2 = _origin + Vector2(p) * _cell
			var rect := Rect2(top_left, Vector2(_cell, _cell))
			draw_rect(rect, fill)
			# Hachures : une trame se lit en niveaux de gris (ENF-20), là où un
			# aplat pâle se confond avec le sol.
			var step: float = _cell * 0.28
			var x: float = step
			while x < _cell * 2.0:
				var a := top_left + Vector2(minf(x, _cell), maxf(x - _cell, 0.0))
				var b := top_left + Vector2(maxf(x - _cell, 0.0), minf(x, _cell))
				draw_line(a, b, edge, thickness)
				x += step
		# Le CONTOUR de la zone, trace en bordant chaque case dont le voisin
		# n'est pas interdit : une zone se lit par sa frontiere, pas par son
		# remplissage.
		var lookup := {}
		for p in _cells:
			lookup[p] = true
		var border := ViewPalette.FORBIDDEN
		border.a = 0.95
		for p in _cells:
			var tl: Vector2 = _origin + Vector2(p) * _cell
			if not lookup.has(p + Vector2i(0, -1)):
				draw_line(tl, tl + Vector2(_cell, 0), border, thickness * 2.0)
			if not lookup.has(p + Vector2i(0, 1)):
				draw_line(tl + Vector2(0, _cell), tl + Vector2(_cell, _cell), border, thickness * 2.0)
			if not lookup.has(p + Vector2i(-1, 0)):
				draw_line(tl, tl + Vector2(0, _cell), border, thickness * 2.0)
			if not lookup.has(p + Vector2i(1, 0)):
				draw_line(tl + Vector2(_cell, 0), tl + Vector2(_cell, _cell), border, thickness * 2.0)

## BASCULES — armées et dépensées.
##
## POURQUOI DEUX ÉTATS DESSINÉS. L'état de la bascule EST le mécanisme : une
## fois franchie, elle ouvre les portes pour de bon. Un joueur qui ne voit pas
## qu'elle a servi ne comprend pas pourquoi la porte reste ouverte — il croit à
## un défaut, ou pire, il croit que la porte s'ouvre toute seule.
##
## ARMÉE : un anneau plein, lumineux, avec un cœur — quelque chose qui appelle.
## DÉPENSÉE : le même anneau, creux et éteint, qui reste en place. Il ne
## disparaît pas : la trace de ce qui a été fait est la moitié de l'explication.
##
## Forme distincte de la plaque à pression (un carré) et de la porte (une
## barre) : trois commandes ne peuvent pas se ressembler (RG-14, ENF-20).
class _SwitchMarks extends Node2D:
	var _armed: Array[Vector2i] = []
	var _spent: Array[Vector2i] = []
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	var _shields: Array[Vector2i] = []
	var _pulsing: Array[Vector2i] = []

	func configure(armed: Array[Vector2i], spent: Array[Vector2i],
			shields: Array[Vector2i], pulsing: Array[Vector2i],
			cell: float, origin: Vector2) -> void:
		_armed = armed
		_spent = spent
		_shields = shields
		_pulsing = pulsing
		_cell = cell
		_origin = origin
		queue_redraw()

	func _centre(p: Vector2i) -> Vector2:
		return _origin + (Vector2(p) + Vector2(0.5, 0.5)) * _cell

	## Combien de cases portent la marque « cette case change ». Publique parce
	## qu'un test doit pouvoir l'interroger : une marque qu'aucune donnée
	## n'alimente est invisible ET silencieuse, et le code a l'air correct.
	func pulsing_count() -> int:
		return _pulsing.size()

	func _draw() -> void:
		if _cell <= 0.0:
			return
		var thickness: float = maxf(_cell * 0.09, 2.0)
		for p in _armed:
			var c := _centre(p)
			var bright := ViewPalette.SWITCH
			bright.a = 0.28
			draw_circle(c, _cell * 0.42, bright)
			var edge := ViewPalette.SWITCH.lightened(0.25)
			edge.a = 0.95
			draw_arc(c, _cell * 0.34, 0.0, TAU, 32, edge, thickness, true)
			draw_circle(c, _cell * 0.15, edge)
		for p in _spent:
			# Éteinte mais PRÉSENTE : c'est la preuve que quelqu'un est passé.
			var c2 := _centre(p)
			var dim := ViewPalette.SWITCH
			dim.a = 0.40
			draw_arc(c2, _cell * 0.34, 0.0, TAU, 32, dim, thickness * 0.7, true)

		# ATELIER À BOUCLIERS — un arc protecteur posé sur un socle. Même forme
		# que la marque portée par l'agent, en plus grand : on doit reconnaître
		# d'un coup d'œil que c'est là qu'on la prend.
		for p in _shields:
			var c3 := _centre(p)
			var halo := ViewPalette.SHIELD
			halo.a = 0.18
			draw_circle(c3, _cell * 0.40, halo)
			var edge := ViewPalette.SHIELD.lightened(0.20)
			edge.a = 0.95
			draw_arc(c3, _cell * 0.30, PI * 1.10, PI * 1.90, 22, edge, thickness, true)
			draw_line(c3 + Vector2(-_cell * 0.22, _cell * 0.16),
				c3 + Vector2(_cell * 0.22, _cell * 0.16), edge, thickness * 0.8)

		# DANGER CYCLIQUE — QUATRE CRANS AUX COINS, dans les deux phases.
		#
		# ILS NE BOUGENT PAS ET NE CLIGNOTENT PAS. Ce que la marque dit n'est pas
		# « en ce moment c'est dangereux » — la teinte de la case le dit déjà, et
		# mieux. Elle dit « CETTE case-là change », ce qui est une propriété
		# permanente et doit donc s'afficher en permanence. Une marque qui
		# apparaîtrait avec le danger n'ajouterait rien à la teinte ; une marque
		# qui clignoterait demanderait d'être regardée au bon moment (ENF-21).
		#
		# QUATRE CRANS PLUTÔT QU'UN ANNEAU : l'anneau est déjà pris par la
		# bascule et par l'atelier, et deux dispositifs qui se ressemblent sont
		# exactement le défaut qu'on corrige ici.
		for p in _pulsing:
			var c4 := _centre(p)
			var mark := ViewPalette.DANGER.lightened(0.45)
			mark.a = 0.85
			var arm: float = _cell * 0.16
			var off: float = _cell * 0.34
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var corner := c4 + Vector2(sx * off, sy * off)
					draw_line(corner, corner - Vector2(sx * arm, 0.0), mark, thickness * 0.8)
					draw_line(corner, corner - Vector2(0.0, sy * arm), mark, thickness * 0.8)

## PATROUILLES — un danger qui se déplace, et le trajet qu'il suit.
##
## ON DESSINE LE CHEMIN AUTANT QUE LE DANGER, et c'est la moitié du mécanisme.
## Un ennemi mobile dont on ne voit pas la route ne se prévoit pas : il punit
## sans rien enseigner, et le joueur conclut que le jeu triche. Volens n'a aucun
## aléatoire (invariant n°6) ; ce serait absurde d'en simuler un.
##
## TROIS NIVEAUX DE LECTURE, du plus faible au plus fort :
##   · le TRAJET, en pointillés éteints — « il passera par là » ;
##   · la case SUIVANTE, en contour — « il y sera au prochain tick », ce qui
##     permet de décider maintenant ;
##   · la case COURANTE, pleine et hachurée comme tout danger — « il y est ».
class _PatrolMarks extends Node2D:
	var _routes: Array = []
	var _heads: Array[Vector2i] = []
	var _nexts: Array[Vector2i] = []
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(routes: Array, heads: Array[Vector2i], nexts: Array[Vector2i],
			cell: float, origin: Vector2) -> void:
		_routes = routes
		_heads = heads
		_nexts = nexts
		_cell = cell
		_origin = origin
		queue_redraw()

	func _rect(p: Vector2i) -> Rect2:
		return Rect2(_origin + Vector2(p) * _cell, Vector2(_cell, _cell))

	func _draw() -> void:
		if _cell <= 0.0 or _routes.is_empty():
			return
		var faint := ViewPalette.DANGER_DORMANT
		faint.a = 0.55
		for route in _routes:
			for p in (route as Array[Vector2i]):
				# Un liseré, pas un aplat : le trajet est une INFORMATION, pas
				# un terrain. Le remplir le ferait lire comme une zone mortelle
				# entière, et le niveau paraîtrait injouable.
				draw_rect(_rect(p).grow(-_cell * 0.34), faint, false,
					maxf(_cell * 0.06, 1.5))
		var soon := ViewPalette.DANGER
		soon.a = 0.55
		for p in _nexts:
			draw_rect(_rect(p).grow(-_cell * 0.10), soon, false,
				maxf(_cell * 0.08, 2.0))
		var here := ViewPalette.DANGER
		here.a = 0.90
		for p in _heads:
			draw_rect(_rect(p).grow(-_cell * 0.06), here)

## LA PROTECTION PORTÉE — un arc au-dessus de l'agent équipé.
##
## POURQUOI ELLE SE DESSINE. Sans elle, le joueur voit un agent traverser une
## case rouge et survivre : il en conclut que le danger est capricieux, ce qui
## est la pire chose qu'un jeu déterministe puisse laisser croire. La marque dit
## « celui-ci est protégé », et sa disparition dit « il ne l'est plus ».
##
## UN ARC, PAS UN DISQUE. Un disque plein aurait la forme de la charge portée
## (le losange) ou de l'agent lui-même ; l'arc évoque ce qu'il est — quelque
## chose qui s'interpose, au-dessus, entre l'agent et ce qui vient.
class _ShieldMarks extends Node2D:
	var _cells: Array = []
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(cells: Array, cell: float, origin: Vector2) -> void:
		_cells = cells
		_cell = cell
		_origin = origin
		queue_redraw()

	func _draw() -> void:
		if _cell <= 0.0:
			return
		for entry in _cells:
			var p: Vector2 = entry[0]
			var alpha: float = entry[1]
			var centre: Vector2 = _origin + (p + Vector2(0.5, 0.5)) * _cell
			var tint := ViewPalette.SHIELD.lightened(0.15)
			tint.a = alpha * 0.95
			draw_arc(centre, _cell * 0.40, PI * 1.15, PI * 1.85, 18, tint,
				maxf(_cell * 0.11, 2.0), true)
