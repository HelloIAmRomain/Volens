class_name LevelCatalog
extends RefCounted
## Catalogue des niveaux, conçus et valides — un chapitre apres l'autre.
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
	{"id": "ch2_01", "name": "Trois portes", "path": "res://data/levels/ch2_01.json", "ready": true},
	{"id": "ch2_02", "name": "Sans lumière", "path": "res://data/levels/ch2_02.json", "ready": true},
	{"id": "ch2_03", "name": "La mauvaise porte", "path": "res://data/levels/ch2_03.json", "ready": true},
	{"id": "ch2_04", "name": "Le détour long", "path": "res://data/levels/ch2_04.json", "ready": true},
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

## Niveau suivant dans l'ordre du chapitre, ou "" s'il n'y en a pas.
## Sert au bouton « Niveau suivant » du bilan.
static func level_after(level_id: String) -> String:
	var i := index_of(level_id)
	if i < 0 or i + 1 >= LEVELS.size():
		return ""
	return String(LEVELS[i + 1]["id"])

## PROGRESSION VERROUILLÉE : un niveau n'est ouvert que si le précédent est
## résolu. Le chapitre est une rampe d'apprentissage (CDC §8.5) — chaque
## niveau suppose acquise la leçon du précédent. Y entrer sans elle, c'est
## buter sur un dispositif qu'on n'a pas les moyens de lire, et conclure que
## le jeu est obscur alors qu'il est simplement lu dans le désordre.
##
## Le premier niveau est toujours ouvert : il n'a pas de prédécesseur.
static func is_unlocked(level_id: String, progress: Progress) -> bool:
	var i := index_of(level_id)
	if i < 0 or not bool(LEVELS[i]["ready"]):
		return false
	if i == 0:
		return true
	return progress.is_solved(String(LEVELS[i - 1]["id"]))

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
