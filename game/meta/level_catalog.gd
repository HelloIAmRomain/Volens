class_name LevelCatalog
extends RefCounted
## Catalogue du chapitre 1. Les niveaux 3 à 5 sont **verrouillés en attendant
## leur conception** : l'IA ne conçoit pas les niveaux (DCT §12.4), et leur
## fiche dépend de la révision du système de règles.

const LEVELS := [
	{"id": "ch1_01", "name": "La nuée", "path": "res://data/levels/ch1_01.json", "ready": true},
	{"id": "ch1_02", "name": "Le détour", "path": "res://data/levels/ch1_02.json", "ready": true},
	{"id": "ch1_03", "name": "À concevoir", "path": "", "ready": false},
	{"id": "ch1_04", "name": "À concevoir", "path": "", "ready": false},
	{"id": "ch1_05", "name": "À concevoir", "path": "", "ready": false},
]

static func count() -> int:
	return LEVELS.size()

static func entry(index: int) -> Dictionary:
	if index < 0 or index >= LEVELS.size():
		return {}
	return LEVELS[index]

static func index_of(level_id: String) -> int:
	for i in range(LEVELS.size()):
		if LEVELS[i]["id"] == level_id:
			return i
	return -1

static func path_of(level_id: String) -> String:
	var i := index_of(level_id)
	return "" if i < 0 else String(LEVELS[i]["path"])

## Premier niveau non résolu et jouable, ou le dernier jouable si tout est
## résolu. Sert au bouton « Continuer » du menu.
static func next_playable(progress: Progress) -> String:
	var last := ""
	for entry_data in LEVELS:
		if not bool(entry_data["ready"]):
			continue
		last = String(entry_data["id"])
		if not progress.is_solved(last):
			return last
	return last

static func load_level_data(level_id: String) -> Dictionary:
	var path := path_of(level_id)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
