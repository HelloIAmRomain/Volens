class_name LevelCatalog
extends RefCounted
## Catalogue du chapitre 1 — les cinq niveaux, conçus et validés.
##
## Les niveaux 3 à 5 portent l'arc QN-02 : trois familles de piles, chacune
## gagnante sur exactement deux niveaux, aucune sur les trois. La propriété
## n'est pas déclarative — elle est simulée à chaque exécution des tests
## (`tests/unit/test_chapter1_arc.gd`).

const LEVELS := [
	{"id": "ch1_01", "name": "La nuée", "path": "res://data/levels/ch1_01.json", "ready": true},
	{"id": "ch1_02", "name": "Le détour", "path": "res://data/levels/ch1_02.json", "ready": true},
	{"id": "ch1_03", "name": "Les traînards", "path": "res://data/levels/ch1_03.json", "ready": true},
	{"id": "ch1_04", "name": "Le prix du temps", "path": "res://data/levels/ch1_04.json", "ready": true},
	{"id": "ch1_05", "name": "Plusieurs vérités", "path": "res://data/levels/ch1_05.json", "ready": true},
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
