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

func clone() -> GridState:
	var copy := GridState.new()
	copy.size = size
	copy.cells = cells.duplicate()
	copy.pheromone = pheromone.duplicate()
	copy.cycle_index = cycle_index.duplicate()
	copy.cycles = []
	for c in cycles:
		copy.cycles.append(c.clone())
	return copy
