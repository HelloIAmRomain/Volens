class_name Session
extends RefCounted
## Recette de la partie en cours + état d'interface [DT-11, DT-14, EF-20/21].
##
## La recette est (niveau, pile) : grâce au déterminisme, rejouer depuis le
## tick 0 reconstruit exactement l'état affiché. On ne sauvegarde donc que le
## **tick** et non l'état, ce qui rend le fichier minuscule et incorruptible
## par nature — il ne peut pas décrire un état impossible.
##
## Écrite à chaque changement de pile, pause, changement de vitesse, et à
## `NOTIFICATION_APPLICATION_PAUSED` — c'est-à-dire avant toute chance d'être
## tuée par le système.

const PATH := "user://session.json"
const SCHEMA_VERSION := 1

var level_id: String = ""
var stack: Array[int] = []
var tick: int = 0
var speed_index: int = 0

func is_valid() -> bool:
	return not level_id.is_empty()

static func load_from_disk() -> Session:
	var s := Session.new()
	var data := SaveStore.read(PATH, SCHEMA_VERSION)
	if data.is_empty():
		return s
	s.level_id = String(data.get("level_id", ""))
	for v in data.get("stack", []):
		s.stack.append(int(v))
	s.tick = maxi(int(data.get("tick", 0)), 0)
	s.speed_index = int(data.get("speed_index", 0))
	return s

func save_to_disk() -> void:
	if not is_valid():
		return
	SaveStore.write(PATH, {
		"level_id": level_id,
		"stack": stack,
		"tick": tick,
		"speed_index": speed_index,
	}, SCHEMA_VERSION)

func clear() -> void:
	level_id = ""
	stack = []
	tick = 0
	speed_index = 0
	SaveStore.erase(PATH)
