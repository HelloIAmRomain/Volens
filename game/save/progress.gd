class_name Progress
extends RefCounted
## Progression du joueur : niveaux résolus et meilleure performance.
## Aucune donnée personnelle, aucune transmission (ENF-30/31).

const PATH := "user://progress.json"
const SCHEMA_VERSION := 1

## id de niveau -> { "ticks": int, "lost": int } de la MEILLEURE résolution.
var solved: Dictionary = {}

static func load_from_disk() -> Progress:
	var p := Progress.new()
	var data := SaveStore.read(PATH, SCHEMA_VERSION)
	var raw: Dictionary = data.get("solved", {})
	for key in raw:
		p.solved[String(key)] = raw[key]
	return p

func save_to_disk() -> void:
	SaveStore.write(PATH, {"solved": solved}, SCHEMA_VERSION)

func is_solved(level_id: String) -> bool:
	return solved.has(level_id)

func best_ticks(level_id: String) -> int:
	if not solved.has(level_id):
		return -1
	return int((solved[level_id] as Dictionary).get("ticks", -1))

## N'enregistre que si c'est mieux : le joueur ne perd jamais un record en
## rejouant moins bien (EF-11).
func record_win(level_id: String, ticks: int, lost: int) -> void:
	var previous := best_ticks(level_id)
	if previous == -1 or ticks < previous:
		solved[level_id] = {"ticks": ticks, "lost": lost}
		save_to_disk()

func reset() -> void:
	solved = {}
	SaveStore.erase(PATH)
