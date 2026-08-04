class_name Directions
extends RefCounted
## Directions cardinales et ordre de départage fixe (DT-07, docs/ARCHITECTURE.md).
##
## Convention de grille : Y croît vers le bas (case (0,0) en haut à gauche),
## donc Nord = (0,-1) et Sud = (0,+1).

const NORTH: int = 0
const EAST: int = 1
const SOUTH: int = 2
const WEST: int = 3

## Ordre de départage fixe et documenté : Nord > Est > Sud > Ouest (DT-07).
## Toute itération sur les directions candidates suit cet ordre.
const ORDER: Array[int] = [NORTH, EAST, SOUTH, WEST]

const _OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), # NORTH
	Vector2i(1, 0),  # EAST
	Vector2i(0, 1),  # SOUTH
	Vector2i(-1, 0), # WEST
]

static func offset(dir: int) -> Vector2i:
	return _OFFSETS[dir]
