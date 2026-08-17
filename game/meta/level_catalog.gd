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
	{"id": "ch2_05", "name": "Les deux moitiés", "path": "res://data/levels/ch2_05.json", "ready": true},
	{"id": "ch3_01", "name": "La trace des autres", "path": "res://data/levels/ch3_01.json", "ready": true},
	{"id": "ch3_02", "name": "La trace qui s'efface", "path": "res://data/levels/ch3_02.json", "ready": true},
	{"id": "ch3_03", "name": "Le repli", "path": "res://data/levels/ch3_03.json", "ready": true},
	{"id": "ch3_04", "name": "Le long relais", "path": "res://data/levels/ch3_04.json", "ready": true},
	{"id": "ch4_01", "name": "Le premier fardeau", "path": "res://data/levels/ch4_01.json", "ready": true},
	{"id": "ch4_02", "name": "Le sas", "path": "res://data/levels/ch4_02.json", "ready": true},
	{"id": "ch4_03", "name": "La navette", "path": "res://data/levels/ch4_03.json", "ready": true},
	{"id": "ch4_04", "name": "Le tri", "path": "res://data/levels/ch4_04.json", "ready": true},
	{"id": "ch5_01", "name": "Le passage", "path": "res://data/levels/ch5_01.json", "ready": true},
	{"id": "ch5_02", "name": "Les deux vigies", "path": "res://data/levels/ch5_02.json", "ready": true},
	{"id": "ch5_03", "name": "La fenêtre", "path": "res://data/levels/ch5_03.json", "ready": true},
	{"id": "ch5_04", "name": "Trop et pas assez", "path": "res://data/levels/ch5_04.json", "ready": true},
	{"id": "ch5_05", "name": "Deux fois le prix", "path": "res://data/levels/ch5_05.json", "ready": true},
	{"id": "ch5_06", "name": "Le triple verrou", "path": "res://data/levels/ch5_06.json", "ready": true},
	{"id": "ch5_07", "name": "La bascule", "path": "res://data/levels/ch5_07.json", "ready": true},
	{"id": "ch6_01", "name": "Le droit d'ignorer", "path": "res://data/levels/ch6_01.json", "ready": true},
	{"id": "ch6_02", "name": "La piste interdite", "path": "res://data/levels/ch6_02.json", "ready": true},
	{"id": "ch6_03", "name": "Personne ne reste", "path": "res://data/levels/ch6_03.json", "ready": true},
	{"id": "ch6_04", "name": "Attendre ou traverser", "path": "res://data/levels/ch6_04.json", "ready": true},
	{"id": "ch6_05", "name": "Le sas rouvert", "path": "res://data/levels/ch6_05.json", "ready": true},
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

## --- CHAPITRES ------------------------------------------------------------
##
## Le numero de chapitre est DEDUIT de l'identifiant (`ch3_02` -> 3), jamais
## saisi a cote. Une seconde declaration serait une seconde verite, et l'on
## sait ce qu'il advient de celles-la : elles divergent, et la divergence ne se
## voit que par accident (invariant n°16).
static func chapter_of(level_id: String) -> int:
	if not level_id.begins_with("ch"):
		return 0
	var underscore := level_id.find("_")
	if underscore < 2:
		return 0
	return int(level_id.substr(2, underscore - 2))

## Titre de chapitre, tel que le CDC §7.2 les nomme.
const CHAPTER_TITLES := {
	1: "Le mouvement élémentaire",
	2: "La coordination",
	3: "La mémoire du monde",
	4: "Le transport",
	5: "Le sacrifice et la régulation",
	6: "L'exception",
}

static func chapter_title(chapter: int) -> String:
	return String(CHAPTER_TITLES.get(chapter, "Chapitre %d" % chapter))

## Numeros de chapitre presents au catalogue, en ordre croissant. Calcule, pas
## declare : ajouter un niveau suffit a faire apparaitre son chapitre.
static func chapters() -> Array[int]:
	var out: Array[int] = []
	for entry_data in LEVELS:
		var c := chapter_of(String(entry_data["id"]))
		if c > 0 and not out.has(c):
			out.append(c)
	out.sort()
	return out

## Un chapitre est ouvert des que son PREMIER niveau l'est. Le verrouillage
## reste celui des niveaux : on n'ajoute pas une seconde serrure par-dessus.
static func is_chapter_unlocked(chapter: int, progress: Progress) -> bool:
	for entry_data in LEVELS:
		if chapter_of(String(entry_data["id"])) == chapter:
			return is_unlocked(String(entry_data["id"]), progress)
	return false

## Niveaux resolus / total pour un chapitre — le seul chiffre que l'ecran de
## selection ait besoin d'afficher a cote d'un titre.
static func chapter_progress(chapter: int, progress: Progress) -> Vector2i:
	var solved := 0
	var total := 0
	for entry_data in LEVELS:
		if chapter_of(String(entry_data["id"])) != chapter:
			continue
		total += 1
		if progress.is_solved(String(entry_data["id"])):
			solved += 1
	return Vector2i(solved, total)

static func load_level_data(level_id: String) -> Dictionary:
	var path := path_of(level_id)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
