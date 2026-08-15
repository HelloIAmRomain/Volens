extends GutTest
## INVARIANT N°11 — `slots` a une source de vérité unique.
##
## Pour chaque niveau du catalogue, l'écran de jeu expose **exactement** le
## nombre de rangs que le validateur énumère. Ni plus, ni moins.
##
## CE QUI SE JOUE ICI N'EST PAS COSMÉTIQUE. Le validateur énumère l'espace des
## piles jusqu'à `slots` et en tire `expected_wins` — le nombre de piles
## gagnantes. Si l'écran de jeu ouvre un rang de plus, le joueur atteint des
## piles que personne n'a comptées, et alors :
##
##   · `expected_wins = 1` sur ch1_02 devient FAUX. La leçon du niveau —
##     « une seule pile gagne, et c'est l'ordre qui décide » — ne tient plus.
##   · N_win cesse d'être une propriété du NIVEAU pour devenir une propriété
##     d'un sous-ensemble arbitraire de ce que le joueur peut faire. QN-01 et
##     QN-02, qui raisonnent sur des classes de piles, perdent leur objet.
##
## Fermer les rangs excédentaires réglait le cas de ch1_02. Ce test règle la
## CLASSE : aucun niveau, présent ou futur, ne peut diverger sans le dire.

const RULES_PATH := "res://data/rules.json"

func _params() -> RuleParams:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	return RuleParams.from_dict(rules if rules is Dictionary else {})

func _playable_levels() -> Array:
	var out: Array = []
	for entry in LevelCatalog.LEVELS:
		if not bool(entry["ready"]):
			continue
		var data := LevelCatalog.load_level_data(String(entry["id"]))
		if not data.is_empty():
			out.append({"id": String(entry["id"]), "data": data})
	return out

func test_the_catalogue_actually_has_playable_levels() -> void:
	# Sans cette garde, tous les tests ci-dessous passeraient à vide le jour
	# où le catalogue casse — et l'invariant ne serait plus surveillé.
	assert_gt(_playable_levels().size(), 0,
		"aucun niveau jouable : les autres tests de ce fichier ne prouveraient rien")

func test_the_game_screen_opens_exactly_the_ranks_the_validator_enumerates() -> void:
	for level in _playable_levels():
		var data: Dictionary = level["data"]
		var screen := GameScreen.new()
		add_child_autofree(screen)
		screen.load_level(data, _params(), String(level["id"]))

		# La longueur maximale réellement énumérée par le validateur, mesurée
		# sur l'énumération elle-même — pas relue dans le fichier de niveau.
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		var enumerated := StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data))
		var longest := 0
		for stack in enumerated:
			longest = maxi(longest, (stack as Array).size())

		assert_eq(screen._open_slots, longest,
			"%s : l'écran ouvre %d rangs, le validateur en énumère %d" % [
				level["id"], screen._open_slots, longest])

func test_no_reachable_stack_escapes_the_enumerated_space() -> void:
	# La formulation forte de l'invariant : toute pile que l'interface peut
	# produire appartient à l'espace énuméré. On la vérifie en remplissant
	# chaque écran jusqu'à saturation, par le chemin sans glissement.
	for level in _playable_levels():
		var data: Dictionary = level["data"]
		var screen := GameScreen.new()
		add_child_autofree(screen)
		screen.load_level(data, _params(), String(level["id"]))

		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		var space := {}
		for stack in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
			space[str(stack)] = true

		# On tente de poser TOUTES les règles autorisées, dans l'ordre, sur
		# tous les rangs affichés — y compris ceux que le niveau ferme.
		for rank in range(UiMetrics.SLOT_COUNT):
			for rule_id in allowed:
				screen._on_chip_tapped(rule_id)
				screen._on_slot_tapped(rank)
		var built: Array[int] = screen._compact_stack()
		assert_true(space.has(str(built)),
			"%s : l'interface a produit la pile %s, que le validateur n'énumère pas" % [
				level["id"], str(built)])
		assert_lte(built.size(), LevelSpec.open_slots(data),
			"%s : pile de %d règles pour %d rangs déclarés" % [
				level["id"], built.size(), LevelSpec.open_slots(data)])

func test_slots_is_read_in_exactly_one_place() -> void:
	# Garde LEXICALE, la seule qui empêche la brèche de se rouvrir par une
	# relecture ailleurs. `LevelSpec` a le droit de connaître la clé ; le
	# convertisseur `.lvl` aussi, parce qu'il la PARSE depuis un en-tête texte
	# au lieu de la consommer. Personne d'autre.
	#
	# Les rapports du validateur PORTENT une clé `slots` : les lire n'est pas
	# lire un niveau. Ils y accèdent donc par indexation directe, ce qui les
	# distingue lexicalement d'une lecture de données de niveau — et rend
	# cette garde utilisable sans exception à rallonge.
	var allowed_files := [
		"res://core/sim/level_spec.gd",
		"res://tools/lvl/lvl_parser.gd",
	]
	var offenders: Array[String] = []
	for path in _all_gd_files("res://core") + _all_gd_files("res://game") + _all_gd_files("res://tools"):
		if allowed_files.has(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		if text.contains("get(\"slots\""):
			offenders.append(path)
	assert_eq(offenders, [] as Array[String],
		"la clé `slots` doit se lire par LevelSpec.open_slots() et nulle part ailleurs")

func _all_gd_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path + "/" + entry
		if dir.current_is_dir():
			out.append_array(_all_gd_files(full))
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return out

## Invariant n°15 : tout niveau du catalogue déclare la géométrie sur laquelle
## ses paramètres ont été mesurés, et cette déclaration est encore vraie.
func test_every_level_is_calibrated_on_its_current_geometry() -> void:
	# `_playable_levels()` filtre le catalogue : elle peut renvoyer une liste
	# vide sans qu'une ligne de ce fichier change.
	assert_gt(_playable_levels().size(), 0, "aucun niveau jouable : le filtre a tout écarté")
	for level in _playable_levels():
		var data: Dictionary = level["data"]
		var declared := LevelSpec.calibrated_on(data)
		assert_ne(declared, "", "%s : aucune calibration déclarée" % level["id"])
		assert_eq(declared, LevelSpec.geometry_hash(data),
			"%s : paramètres calibrés sur une autre géométrie (invariant n°15)" % level["id"])
