extends GutTest
## HYGIÈNE DE LA SUITE — deux contrôles lexicaux, deux récidives.
##
## Ces tests portent sur les tests eux-mêmes. Ils existent parce que deux
## défauts de la suite se sont reproduits après avoir été corrigés une fois, et
## qu'une note n'a protégé de rien ni l'une ni l'autre fois.

const TESTS_DIR := "res://tests"

func _all_gd(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path + "/" + entry
		if dir.current_is_dir():
			_all_gd(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()

# --- 1. `pending()` est banni ----------------------------------------------

## GUT sort en **code 1** sur un test `pending`. La CI passe donc au rouge, et
## un rouge permanent cesse d'être un signal : on apprend à le lire comme du
## bruit, et la vraie régression suivante passe inaperçue.
##
## Deux occurrences, à deux semaines d'intervalle, toutes deux sur un objectif
## non atteint qu'on voulait « garder visible ». La bonne forme existe et elle
## est employée ailleurs dans cette suite : un **cliquet** — on fige le pire
## cas mesuré, on refuse toute aggravation, et l'on exige d'abaisser le seuil
## le jour où la cible est atteinte. Un objectif non tenu reste ainsi nommé,
## sans rendre la suite rouge.
func test_no_test_uses_pending() -> void:
	var files: Array = []
	_all_gd(TESTS_DIR, files)
	assert_gt(files.size(), 0, "aucun fichier de test trouvé — le balayage est cassé")
	var offenders := PackedStringArray()
	for path in files:
		if path == get_script().resource_path:
			continue   # ce fichier NOMME `pending` pour l'interdire
		var text := FileAccess.get_file_as_string(path)
		for line in text.split("\n"):
			var code := String(line).strip_edges()
			if code.begins_with("#"):
				continue
			if code.contains("pending(") and not code.contains("has_pending"):
				offenders.append("%s : %s" % [path.get_file(), code])
	assert_eq(offenders, PackedStringArray(),
		("`pending()` fait sortir GUT en erreur : la CI passe au rouge et cesse "
		+ "d'être un signal. Utiliser un CLIQUET — figer le pire cas mesuré et "
		+ "refuser l'aggravation. Occurrences : %s") % ", ".join(offenders))

# --- 2. Aucun test ne porte sur un fichier hors dépôt -----------------------

## **Un test dont l'objet n'est pas versionné n'est pas un test.** Il est vert
## sur le poste qui possède le fichier, absent partout ailleurs — donc il ne
## prouve rien, tout en donnant l'apparence d'une couverture.
##
## C'est la **cinquième forme** du piège de l'invariant n°12 : après « paraître
## correct clôt l'examen », « paraître cassé clôt l'examen », « un zéro se
## vérifie comme un chiffre inattendu » et « une note ne protège de rien »,
## voici « un test qui ne s'exécute pas nulle part ressemble à un test ».
##
## Le cas rencontré : un contrôle du préréglage d'export, écrit sur
## `export_presets.cfg` — hors dépôt parce qu'il porte des chemins personnels.
## Le bon objet était le modèle versionné `docs/export_presets.cfg.exemple`.
const UNVERSIONED := [
	"res://export_presets.cfg",   # chemins personnels, hors dépôt
	"res://reports/",             # sorties d'outils, ignorées
	"res://build/",               # artefacts d'export, ignorés
	"res://.godot/",              # cache du moteur
]

func test_no_test_targets_an_unversioned_path() -> void:
	var files: Array = []
	_all_gd(TESTS_DIR, files)
	var offenders := PackedStringArray()
	for path in files:
		if path == get_script().resource_path:
			continue   # ce fichier LISTE les chemins interdits
		var text := FileAccess.get_file_as_string(path)
		for forbidden in UNVERSIONED:
			if not text.contains(String(forbidden)):
				continue
			# Une mention dans un commentaire explicatif est légitime ; c'est
			# l'usage comme OBJET du test qui ne l'est pas.
			for line in text.split("\n"):
				var code := String(line).strip_edges()
				if code.begins_with("#") or code.begins_with("##"):
					continue
				if code.contains(String(forbidden)):
					offenders.append("%s → %s" % [path.get_file(), forbidden])
					break
	assert_eq(offenders, PackedStringArray(),
		("Un test dont l'objet n'est pas versionné n'est pas un test : vert ici, "
		+ "absent ailleurs. Viser le fichier VERSIONNÉ équivalent. Occurrences : %s")
		% ", ".join(offenders))

# --- 3. Un test dont toutes les assertions sont dans une boucle -------------

## **LA PIRE FORME DE LA SÉRIE, et elle mérite qu'on dise pourquoi.**
##
## Un test dont l'objet se vide cesse d'asserter **au moment exact où
## l'objectif est atteint**. Le déclencheur est une BONNE NOUVELLE — la liste
## des manquements s'est vidée, le défaut a été réparé — donc personne ne
## cherche un défaut à ce moment-là. Les cinq formes précédentes se
## déclenchaient sur un incident ; celle-ci se déclenche sur un succès, et
## c'est ce qui la rend invisible.
##
## Cas rencontré le 10 août 2026 : `test_the_known_breaches_are_still_real`
## bouclait sur `S4_KNOWN_BREACHES`. S4 fermée, la liste vidée, la boucle n'a
## plus rien parcouru — zéro assertion, test « risky », et la garantie avait
## disparu sans qu'une seule ligne ait changé.
##
## LA RÈGLE, telle qu'elle doit être tenue :
##
## > **Un test qui itère une liste doit échouer si la liste est vide, ou
## > déclarer explicitement que le vide est le succès attendu.**
##
## Mise en œuvre : toute fonction `test_` qui contient des assertions doit en
## contenir au moins une **hors de toute boucle** — un garde sur la taille de
## la collection, ou l'assertion du cas vide lui-même. À défaut, elle porte le
## marqueur ci-dessous, qui dit en clair que le vide est le succès attendu.
const EMPTY_OK_MARKER := "# VIDE-ATTENDU:"

## CLIQUET — le motif est PARTOUT, et c'est le résultat le plus utile de
## l'audit. Premier passage du contrôle, 10 août 2026 : **28 fonctions sur
## l'ensemble de la suite**, dans onze fichiers sans rapport entre eux. Ce
## n'était donc pas un test à corriger, c'était une habitude d'écriture.
##
## Toutes ne sont pas également exposées, et la distinction gouverne l'ordre
## des réparations :
##
##   · celles dont la collection est **filtrée** dans la boucle (`continue`
##     sur `ready`, sur `tutorial`…) peuvent se vider sans qu'une seule ligne
##     change — un niveau qui cesse d'être prêt suffit. **Réparées d'abord,
##     et retirées de cette liste** ;
##   · celles qui parcourent une constante littérale ne se videront que si
##     quelqu'un vide la constante, geste visible en relecture. Dette, pas
##     danger immédiat.
##
## Le cliquet fige le reste et refuse toute AGGRAVATION : un nouveau test du
## même patron échoue ici. La liste doit décroître, jamais croître.
const LOOPED_ASSERT_DEBT := [
	"test_chapter1_arc.gd : test_every_level_is_winnable_and_none_is_a_formality",
	"test_chapter1_arc.gd : test_the_declared_predictions_match_the_simulation",
	"test_chapter2_rules.gd : test_every_rule_returns_a_unit_step_or_abstains",
	"test_chapter2_rules.gd : test_the_three_rules_are_registered_and_stateless",
	"test_design_sheets.gd : test_the_sheets_match_the_levels_they_describe",
	"test_golden.gd : test_every_recipe_archives_the_current_rules_fingerprint",
	"test_level_field_access.gd : test_level_spec_exposes_every_guarded_field",
	"test_palette_charter.gd : test_element_hues_are_pairwise_distinguishable",
	"test_palette_charter.gd : test_every_vocabulary_entry_has_a_colour",
	"test_palette_charter.gd : test_the_stack_ranks_carry_no_hue_identity",
	"test_screen_layout.gd : test_the_screenshot_harness_covers_every_screen",
	"test_selfcheck_isolation.gd : test_no_shipped_file_names_the_class_statically",
	"test_slots_single_source.gd : test_no_reachable_stack_escapes_the_enumerated_space",
	"test_slots_single_source.gd : test_the_game_screen_opens_exactly_the_ranks_the_validator_enumerates",
	"test_solution_identity.gd : test_every_level_is_solvable_and_none_is_a_formality",
	"test_solution_identity.gd : test_no_stack_solves_the_whole_chapter",
	"test_solution_identity.gd : test_no_two_levels_are_won_by_the_same_set_of_families",
	"test_solution_identity.gd : test_no_two_levels_share_the_same_solution_set",
	"test_state_hash.gd : test_hash_covers_every_significant_field",
	"test_state_hash.gd : test_hex_hash_survives_a_json_round_trip_strictly",
	"test_ui_contract.gd : test_a_locked_rank_is_never_offered_as_the_next_free_one",
	"test_validator.gd : test_enumerate_has_no_duplicate_and_no_repeated_rule",
]

func test_no_test_puts_all_its_assertions_inside_a_loop() -> void:
	var files: Array = []
	_all_gd(TESTS_DIR, files)
	assert_gt(files.size(), 0, "aucun fichier de test trouvé — le balayage est cassé")
	var offenders := PackedStringArray()
	for path in files:
		if path == get_script().resource_path:
			continue   # ce fichier DÉCRIT le motif pour l'interdire
		for entry in _functions_whose_asserts_are_all_looped(path):
			offenders.append("%s : %s" % [path.get_file(), entry])
	offenders.sort()

	var known := PackedStringArray(LOOPED_ASSERT_DEBT)
	known.sort()
	var appeared := PackedStringArray()
	for name in offenders:
		if not known.has(name):
			appeared.append(name)
	assert_eq(appeared, PackedStringArray(),
		("NOUVEAU test dont toutes les assertions sont dans une boucle : le jour où "
		+ "la collection se vide, il n'asserte plus rien et le dit à personne — et ce "
		+ "jour-là est celui où l'objectif est ATTEINT, donc celui où personne ne "
		+ "cherche un défaut. Ajouter une assertion hors boucle (taille de la "
		+ "collection, ou cas vide), ou porter le marqueur `%s`. Occurrences : %s")
		% [EMPTY_OK_MARKER, ", ".join(appeared)])

	# La dette doit DÉCROÎTRE. Une entrée réparée sans être retirée d'ici
	# laisserait le cliquet protéger un motif qui n'existe plus, et le prochain
	# vrai cas passerait pour connu.
	var vanished := PackedStringArray()
	for name in known:
		if not offenders.has(name):
			vanished.append(name)
	assert_eq(vanished, PackedStringArray(),
		"réparés mais toujours listés dans LOOPED_ASSERT_DEBT : les en retirer. %s"
		% ", ".join(vanished))

## Renvoie les noms des fonctions `test_` du fichier dont TOUTES les assertions
## sont imbriquées dans au moins une boucle `for`/`while`.
##
## L'imbrication se lit à l'indentation, comme GDScript lui-même : une boucle
## ouvre à son niveau, et toute ligne strictement plus indentée lui appartient
## jusqu'à la première ligne de niveau inférieur ou égal.
func _functions_whose_asserts_are_all_looped(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var text := FileAccess.get_file_as_string(path)
	var current := ""
	var has_assert := false
	var has_free_assert := false
	var exempt := false
	var loop_indents: Array[int] = []
	for raw_line in text.split("\n"):
		var line := String(raw_line)
		var code := line.strip_edges()
		if code.is_empty():
			continue
		var indent := line.length() - line.lstrip("\t").length()

		if code.begins_with("func "):
			if not current.is_empty() and has_assert and not has_free_assert and not exempt:
				out.append(current)
			current = code.substr(5).split("(")[0] if code.contains("test_") else ""
			has_assert = false
			has_free_assert = false
			exempt = false
			loop_indents.clear()
			continue
		if current.is_empty():
			continue
		if code.contains(EMPTY_OK_MARKER):
			exempt = true
		if code.begins_with("#"):
			continue

		while not loop_indents.is_empty() and indent <= loop_indents[loop_indents.size() - 1]:
			loop_indents.remove_at(loop_indents.size() - 1)
		if code.begins_with("for ") or code.begins_with("while "):
			loop_indents.append(indent)
			continue
		if code.contains("assert_"):
			has_assert = true
			if loop_indents.is_empty():
				has_free_assert = true
	if not current.is_empty() and has_assert and not has_free_assert and not exempt:
		out.append(current)
	return out

func test_every_resource_path_referenced_by_a_test_exists() -> void:
	# Corollaire du précédent : un chemin versionné mais faux donne un test qui
	# ne vérifie rien non plus, silencieusement.
	var files: Array = []
	_all_gd(TESTS_DIR, files)
	var pattern := RegEx.create_from_string('"(res://[^"]+\\.[a-z]+)"')
	var missing := PackedStringArray()
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for m in pattern.search_all(text):
			var target := m.get_string(1)
			if target.begins_with("res://export_presets"):
				continue   # traité par le test précédent
			if not FileAccess.file_exists(target):
				missing.append("%s → %s" % [path.get_file(), target])
	assert_eq(missing, PackedStringArray(),
		"chemins référencés par un test et introuvables : %s" % ", ".join(missing))
