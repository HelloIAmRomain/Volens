extends GutTest
## Les fiches de conception ne mentent pas sur les niveaux qu'elles décrivent.
##
## POURQUOI CE TEST EXISTE. Les cinq fiches de `docs/design/` ont été écrites
## trois fois, et deux fois elles ont été **périmées avant d'être lues** : une
## première fois parce qu'elles décrivaient des niveaux jamais construits, une
## seconde parce que la géométrie et l'échéance avaient changé après leur
## rédaction. Une fiche périmée n'est pas un document incomplet, c'est **une
## source qui ment** — et elle sera relue comme une source.
##
## Chaque fiche porte donc un bloc `json` de relevé. Ce test le confronte au
## fichier de niveau réel. Si le niveau change sans que la fiche suive, la
## suite échoue et nomme l'écart.
##
## Ce qui n'est PAS vérifié ici, et volontairement : la prose. Le raisonnement
## de conception ne se teste pas ; seuls les chiffres le peuvent, et ce sont
## eux qui pourrissent.

const DESIGN_DIR := "res://docs/design"

func _sheet_record(level_id: String) -> Dictionary:
	var path := "%s/%s.md" % [DESIGN_DIR, level_id]
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var start := text.find("```json")
	if start < 0:
		return {}
	start = text.find("\n", start) + 1
	var end := text.find("```", start)
	if end < 0:
		return {}
	var parsed: Variant = JSON.parse_string(text.substr(start, end - start))
	return parsed if parsed is Dictionary else {}

func test_every_ready_level_has_a_design_sheet() -> void:
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		assert_false(_sheet_record(level_id).is_empty(),
			"%s : fiche absente ou sans bloc de relevé" % level_id)

func test_the_sheets_match_the_levels_they_describe() -> void:
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var data := LevelCatalog.load_level_data(level_id)
		var sheet := _sheet_record(level_id)
		if data.is_empty() or sheet.is_empty():
			continue

		assert_eq(String(sheet.get("id", "")), String(data.get("id", "")),
			"%s : identifiant" % level_id)
		assert_eq(int(sheet.get("agents", -1)), (data.get("agents", []) as Array).size(),
			"%s : effectif" % level_id)
		assert_eq((int(sheet["slots"]) if sheet.has("slots") else -1), LevelSpec.open_slots(data),
			"%s : nombre de rangs" % level_id)
		assert_eq((int(sheet["expected_wins"]) if sheet.has("expected_wins") else -1), LevelSpec.expected_wins(data),
			"%s : piles gagnantes annoncées" % level_id)
		# La calibration lie la fiche à une géométrie précise : c'est le champ
		# qui rend l'écart détectable dès qu'un mur bouge.
		assert_eq((String(sheet["calibrated_on"]) if sheet.has("calibrated_on") else ""), LevelSpec.calibrated_on(data),
			"%s : la fiche décrit une AUTRE géométrie que le niveau" % level_id)

		var grid: Array = sheet.get("grid", [])
		var real: Array = (data.get("grid", {}) as Dictionary).get("size", [])
		assert_eq(grid.size(), 2, "%s : dimensions" % level_id)
		if grid.size() == 2 and real.size() == 2:
			assert_eq(int(grid[0]), int(real[0]), "%s : largeur" % level_id)
			assert_eq(int(grid[1]), int(real[1]), "%s : hauteur" % level_id)

func test_no_sheet_describes_a_level_that_does_not_exist() -> void:
	# L'inverse du test précédent : une fiche orpheline est une source qui
	# survit à son objet, et c'est ainsi que les propositions invalidées du
	# chapitre 1 ont failli être relues comme des spécifications.
	var dir := DirAccess.open(DESIGN_DIR)
	assert_not_null(dir, "docs/design/ introuvable")
	if dir == null:
		return
	# `docs/design/` accueille aussi des notes de conception qui ne décrivent
	# aucun niveau (paradigmes d'un chapitre à venir, par exemple). Seuls les
	# fichiers nommés comme un niveau — `chN_MM.md` — sont des fiches.
	var sheet_name := RegEx.create_from_string("^ch\\d_\\d\\d$")
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.ends_with(".md"):
			var level_id := entry.get_basename()
			if sheet_name.search(level_id) != null:
				assert_ne(LevelCatalog.index_of(level_id), -1,
					"%s décrit un niveau absent du catalogue" % entry)
		entry = dir.get_next()
	dir.list_dir_end()

## CDC §8.5 : le bilan d'un niveau OUVERT annonce ses solutions connues.
##
## Le chiffre doit venir du validateur, jamais d'une estimation — sinon le
## jeu annonce au joueur une pluralité qu'il n'a pas mesurée, et P5 (« il n'y
## a pas UNE bonne réponse ») devient une affirmation gratuite.
func test_open_levels_announce_a_measured_number_of_solutions() -> void:
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var data := LevelCatalog.load_level_data(level_id)
		if LevelSpec.is_tutorial(data):
			continue
		var announced: int = SummaryScreen._known_solutions(level_id)
		assert_eq(announced, LevelSpec.expected_wins(data),
			"%s : le bilan annonce %d solutions, le niveau en déclare %d" % [
				level_id, announced, LevelSpec.expected_wins(data)])
		assert_gt(announced, 1,
			"%s est un niveau ouvert : annoncer une seule solution contredirait P5" % level_id)

func test_tutorial_levels_announce_nothing() -> void:
	# Annoncer « 1 solution connue » sur un tutoriel suggérerait qu'on en
	# cherche d'autres, alors que le niveau n'en a qu'une par construction.
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		if not LevelSpec.is_tutorial(LevelCatalog.load_level_data(level_id)):
			continue
		assert_eq(SummaryScreen._known_solutions(level_id), 0,
			"%s est un tutoriel : le bilan ne doit annoncer aucun compte" % level_id)
