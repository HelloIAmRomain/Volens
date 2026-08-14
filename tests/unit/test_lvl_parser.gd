extends GutTest
## Tests du convertisseur .lvl (avance sur T-074) : aller-retour, stabilité
## de l'attribution des ids (ordre de lecture), rejet de chaque cas d'erreur.
## Revue générale des contrôles RG à la conversion : 6 août 2026.

const FLOOR := 6  # plancher de période passé explicitement dans les tests

## En-tête minimal valide ; les tests le surchargent ligne par ligne.
func _header(overrides: Dictionary = {}) -> String:
	var base := {
		"id": "test_lvl",
		"allowed_rules": "[R01]",
		"slots": "1",
		"max_ticks": "50",
	}
	for k in overrides:
		base[k] = overrides[k]
	var out := ""
	for k in base:
		if base[k] != null:
			out += "%s: %s\n" % [k, base[k]]
	return out

## Grille valide 8×10 : lumière, bande de sortie, 20 agents (plancher RG-14).
func _grid(rows_override: Dictionary = {}) -> String:
	var rows := [
		". . . L . . . .",
		"E E E E E E E E",
		". . . . . . . .",
		". . . . . . . .",
		". . . . . . . .",
		". . . . . . . .",
		"o o o o o o o o",
		"o o o o o o o o",
		"o o o o . . . .",
		". . . . . . . .",
	]
	for y in rows_override:
		rows[y] = rows_override[y]
	return "\n".join(PackedStringArray(rows))

## Par défaut, un objectif d'extraction est fourni (un niveau sans
## accomplissement est refusé — exigence T-074).
func _parse(header_overrides: Dictionary = {}, rows_override: Dictionary = {}, extra_header := "objective: extraction 100\n") -> Dictionary:
	var text := _header(header_overrides) + extra_header + "---\n" + _grid(rows_override) + "\n"
	return LvlParser.parse(text, FLOOR)

func _errors_joined(result: Dictionary) -> String:
	return ", ".join(result["errors"] as PackedStringArray)

# --- chemin nominal ---------------------------------------------------------

func test_valid_level_parses_without_errors() -> void:
	var result := _parse()
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))
	var level: Dictionary = result["level"]
	assert_eq(level["id"], "test_lvl")
	assert_eq(level["slots"], 1)
	assert_eq(level["allowed_rules"], [1])
	assert_eq(level["grid"]["size"], [8, 10])
	assert_eq(level["grid"]["cells"][3], GridState.CellType.LIGHT_SOURCE, "L en (3,0)")
	assert_eq(level["grid"]["cells"][8], GridState.CellType.EXIT, "E en (0,1)")
	assert_eq((level["agents"] as Array).size(), 20)
	assert_eq(level["objectives"], [{"type": "extraction", "percent": 100}])

func test_agent_ids_follow_reading_order() -> void:
	# Convention n°1 (déterminisme) : ligne par ligne, gauche à droite.
	# 20 agents dont trois positions distinctives (première, deuxième, dernière).
	var result := _parse({}, {
		5: ". . . . . o . .",
		6: "o o o o o o o o",
		7: "o o o o o o o o",
		8: "o o o . . . . .",
	})
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))
	var agents: Array = result["level"]["agents"]
	assert_eq(agents[0]["pos"], [5, 5], "id 0 : première case lue")
	assert_eq(agents[1]["pos"], [0, 6], "id 1 : ligne suivante, colonne 0")
	assert_eq(agents[19]["pos"], [2, 8], "id 19 : dernière case lue")

func test_spacing_between_symbols_is_ignored() -> void:
	var compact := _parse({}, {8: "oooo...."})
	assert_eq((compact["errors"] as PackedStringArray).size(), 0, "symboles collés acceptés")
	assert_eq((compact["level"]["agents"] as Array).size(), 20)

func test_json_round_trip_preserves_the_level() -> void:
	var level: Dictionary = _parse({}, {}, "objective: extraction 60\n")["level"]
	var back: Variant = JSON.parse_string(JSON.stringify(level))
	assert_eq(back["grid"]["cells"], Array(level["grid"]["cells"]).map(func(v: Variant) -> float: return float(v)),
		"les cases survivent à l'aller-retour JSON (en nombres, tous < 2^53)")
	assert_eq(int(back["max_ticks"]), int(level["max_ticks"]))
	assert_eq((back["agents"] as Array).size(), (level["agents"] as Array).size())

func test_cyclic_danger_wires_cycle_and_index() -> void:
	var result := _parse({}, {4: ". . C . . . . ."}, "objective: extraction 100\ncycle: period=6 active=3\n")
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))
	var grid: Dictionary = result["level"]["grid"]
	assert_eq(grid["cycles"], [{"period": 6, "active_ticks": 3}])
	assert_eq(grid["cycle_index"][4 * 8 + 2], 0, "la case C pointe le cycle 0")

func test_expected_classes_is_carried_through() -> void:
	var result := _parse({"expected_wins": "1", "expected_classes": "1"})
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))
	assert_eq(int(result["level"]["expected_classes"]), 1)

# --- rejets : structure -------------------------------------------------------

func test_rejects_missing_separator() -> void:
	var result := LvlParser.parse("id: x\n. . .\n", FLOOR)
	assert_string_contains(_errors_joined(result), "---")

func test_rejects_grid_without_agents() -> void:
	var result := _parse({}, {6: ". . . . . . . .", 7: ". . . . . . . .", 8: ". . . . . . . ."})
	assert_string_contains(_errors_joined(result), "aucun agent")

func test_rejects_crowd_below_rg14_floor() -> void:
	# 19 agents : sous le plancher RG-14 (20 à 50) — trou de validation
	# découvert en revue le 6 août 2026, désormais fermé.
	var result := _parse({}, {8: "o o o . . . . ."})
	assert_string_contains(_errors_joined(result), "RG-14")

func test_rejects_crowd_above_rg14_ceiling() -> void:
	var rows: Dictionary = {}
	for y in range(2, 9):
		rows[y] = "o o o o o o o o"  # 7 rangées pleines = 56 agents
	var result := _parse({}, rows)
	assert_string_contains(_errors_joined(result), "RG-14")

func test_rejects_non_rectangular_grid() -> void:
	var result := _parse({}, {5: ". . ."})
	assert_string_contains(_errors_joined(result), "non rectangulaire")

func test_rejects_unknown_symbol() -> void:
	var result := _parse({}, {5: ". . z . . . . ."})
	assert_string_contains(_errors_joined(result), "symbole inconnu")

func test_rejects_one_way_symbols_in_v1() -> void:
	var result := _parse({}, {5: ". . > . . . . ."})
	assert_string_contains(_errors_joined(result), "sens unique")

func test_rejects_grid_too_narrow() -> void:
	var text := _header() + "objective: extraction 100\n---\n" + "\n".join(PackedStringArray([
		". . . . . . .", "E E E E E E E", ". . . . . . .", ". . . . . . .",
		". . . . . . .", ". . . . . . .", ". . o . . . .", ". . . . . . .",
		". . . . . . .", ". . . . . . .",
	])) + "\n"
	var result := LvlParser.parse(text, FLOOR)
	assert_string_contains(_errors_joined(result), "hors bornes")

func test_rejects_grid_not_taller_than_wide() -> void:
	var rows: Array[String] = []
	for i in range(10):
		rows.append(". . . . o . . . . ." if i == 5 else ". . . . . . . . . .")
	var result := LvlParser.parse(_header() + "---\n" + "\n".join(PackedStringArray(rows)) + "\n", FLOOR)
	assert_string_contains(_errors_joined(result), "plus haute que large")

# --- rejets : cycles ----------------------------------------------------------

func test_rejects_cycle_below_the_floor() -> void:
	var result := _parse({}, {4: ". . C . . . . ."}, "objective: extraction 100\ncycle: period=4 active=2\n")
	assert_string_contains(_errors_joined(result), "plancher")

func test_rejects_cyclic_cell_without_cycle_declaration() -> void:
	var result := _parse({}, {4: ". . C . . . . ."})
	assert_string_contains(_errors_joined(result), "aucune ligne `cycle:")

func test_rejects_cycle_declared_without_cyclic_cell() -> void:
	var result := _parse({}, {}, "objective: extraction 100\ncycle: period=6 active=3\n")
	assert_string_contains(_errors_joined(result), "aucune case « C »")

# --- rejets : règles et espace -------------------------------------------------

func test_rejects_unimplemented_rule() -> void:
	# R99 n'existe pas et n'existera jamais : la bibliothèque est FERMÉE à seize
	# règles (CDC §7.2). Ce test visait R07 jusqu'au 14 août 2026, date à
	# laquelle R07 a été implémentée — un test dont l'exemple devient valide
	# cesse de tester ce qu'il annonce, sans jamais le dire.
	var result := _parse({"allowed_rules": "[R01, R99]"})
	assert_string_contains(_errors_joined(result), "non implémentée")

func test_rejects_duplicate_rule() -> void:
	var result := _parse({"allowed_rules": "[R01, R01]"})
	assert_string_contains(_errors_joined(result), "en double")

func test_rejects_invalid_slots() -> void:
	var result := _parse({"slots": "5"})
	assert_string_contains(_errors_joined(result), "slots=5")

func test_rejects_expected_wins_beyond_the_reachable_space() -> void:
	# 1 règle, 1 emplacement : N_total = 2 (pile vide incluse).
	var result := _parse({"expected_wins": "5"})
	assert_string_contains(_errors_joined(result), "N_total=2")

func test_rejects_expected_classes_above_expected_wins() -> void:
	var result := _parse({"expected_wins": "1", "expected_classes": "3"})
	assert_string_contains(_errors_joined(result), "expected_classes=3 > expected_wins=1")

# --- rejets : cohérence des objectifs -------------------------------------------

func test_rejects_level_without_any_achievement() -> void:
	# Un niveau sans accomplissement n'est jamais gagné : refus à la
	# conversion (exigence T-074, notée au carnet le 5 août).
	var result := _parse({}, {}, "objective: preservation 2\n")
	assert_string_contains(_errors_joined(result), "aucun objectif d'accomplissement")

func test_rejects_duplicate_objective_type() -> void:
	var result := _parse({}, {}, "objective: extraction 100\nobjective: extraction 60\n")
	assert_string_contains(_errors_joined(result), "en double")

func test_rejects_extraction_zero_percent() -> void:
	# 0 % serait satisfait par la pile vide : niveau dégénéré garanti.
	var result := _parse({}, {}, "objective: extraction 0\n")
	assert_string_contains(_errors_joined(result), "hors bornes")

func test_rejects_extraction_without_exit() -> void:
	var result := _parse({}, {1: ". . . . . . . ."})
	assert_string_contains(_errors_joined(result), "sans aucune sortie")

func test_rejects_toothless_preservation() -> void:
	# max_lost >= effectif : la contrainte ne peut jamais mordre.
	var result := _parse({}, {}, "objective: extraction 100\nobjective: preservation 20\n")
	assert_string_contains(_errors_joined(result), "sans effet")

func test_rejects_toothless_celerity() -> void:
	# T >= limite du niveau : l'échéance n'ajoute rien.
	var result := _parse({}, {}, "objective: extraction 100\nobjective: celerity 50\n")
	assert_string_contains(_errors_joined(result), "sans effet")

func test_rejects_collect_beyond_the_stock() -> void:
	var result := _parse({}, {}, "objective: collect 1\n")
	assert_string_contains(_errors_joined(result), "inatteignable dès le tick 0")

func test_rejects_interdiction_cell_out_of_bounds() -> void:
	var result := _parse({}, {}, "objective: extraction 100\nobjective: interdiction (9,9)\n")
	assert_string_contains(_errors_joined(result), "hors de la grille")

# --- critère de fin du lot : ch1_01 de bout en bout ---------------------------

func test_ch1_01_converts_and_validates_at_exactly_one_win() -> void:
	# Le croquis N1 corrigé (bande de sortie, largeur 8) : converti, validé,
	# N_win == 1 — le critère de fin du prompt §9, verrouillé en permanence.
	var text := FileAccess.get_file_as_string("res://data/levels/ch1_01.lvl")
	var result := LvlParser.parse(text, FLOOR)
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))

	var level: Dictionary = result["level"]
	assert_between((level["agents"] as Array).size(), 20, 50, "effectif RG-14")
	assert_true(bool(level["tutorial"]))

	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]
	assert_eq(int(summary["n_stacks"]), 2, "1 règle, 1 emplacement : pile vide + [1]")
	assert_eq(int(summary["n_win"]), 1, "expected_wins de la fiche")
	assert_string_contains(String(summary["qn01_verdict"]), "attendu 1, constaté 1")

# --- Contraintes de géométrie (invariants n°13 et n°14) --------------------
#
# Ces trois contrôles remplacent trois notes de carnet qui n'avaient protégé
# de rien : chacune des trois leçons a récidivé APRÈS avoir été consignée.
# Les tests ci-dessous les éprouvent sur la géométrie fautive elle-même —
# le cas où le mécanisme travaille (invariant n°12), pas un cas commode.

const _GEO_HEAD := """id: geo
name: Geo
allowed_rules: [R01, R02]
slots: 2
max_ticks: 60
objective: extraction 100
---
"""

func _parse_grid(rows: Array) -> Dictionary:
	return LvlParser.parse(_GEO_HEAD + "\n".join(PackedStringArray(rows)), 6, 25)

## Grille de référence : mur percé, nuée compacte, aucun danger.
func _blank_rows() -> Array:
	var rows := [
		". . . . . L . . . . .",
		"# # # # E E E # # # #",
	]
	for i in range(8):
		rows.append(". . . . . . . . . . .")
	for i in range(4):
		rows.append(". . . o o o o o . . .")
	rows.append(". . . . . . . . . . .")
	return rows

## Avertissements de GÉOMÉTRIE seulement : l'absence de calibration en produit
## un autre, légitime, qui n'a rien à voir avec ce qu'on teste ici.
func _geometry_warnings(result: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for w in result["warnings"]:
		if not String(w).contains("calibrated_on"):
			out.append(String(w))
	return out

func test_a_clean_geometry_raises_nothing() -> void:
	# Sans ce test, les trois suivants pourraient passer sur un contrôle qui
	# crie tout le temps — ce qui ne vaudrait pas mieux qu'un contrôle muet.
	var result := _parse_grid(_blank_rows())
	assert_eq(result["errors"], PackedStringArray(), "aucune erreur attendue")
	assert_eq(_geometry_warnings(result), PackedStringArray(), "aucun avertissement de géométrie")

func test_a_danger_due_north_within_flee_range_warns() -> void:
	var rows: Array = _blank_rows()
	rows[7] = ". . . . . X . . . . ."   # (5,7), plein nord des agents (5,10..13)
	var result := _parse_grid(rows)
	assert_eq(result["errors"], PackedStringArray(), "avertissement, pas refus")
	var geo := _geometry_warnings(result)
	assert_gt(geo.size(), 0,
		"un danger plein nord à portée de fuite doit être signalé (invariant n°14)")
	assert_true(String(geo[0]).contains("NORD"))

func test_a_danger_out_of_flee_range_stays_silent() -> void:
	# (5,2) est à d² = 64 des agents les plus proches : hors de portée, donc
	# aucun cycle possible. Le contrôle ne doit pas crier pour autant.
	var rows: Array = _blank_rows()
	rows[2] = ". . . . . X . . . . ."
	var result := _parse_grid(rows)
	assert_eq(_geometry_warnings(result), PackedStringArray(),
		"hors de portée de fuite : aucun cycle limite possible, donc aucun avertissement")

func test_two_dangers_framing_the_swarm_are_refused() -> void:
	var rows: Array = _blank_rows()
	rows[10] = ". X . o o o o o X . ."
	var result := _parse_grid(rows)
	var errors: PackedStringArray = result["errors"]
	assert_gt(errors.size(), 0, "deux dangers encadrant la nuée doivent être REFUSÉS")
	var found := false
	for e in errors:
		if String(e).contains("encadrent"):
			found = true
	assert_true(found, "l'erreur doit nommer l'encadrement (invariant n°13)")

# --- Calibration : invariant n°15 ------------------------------------------
#
# Un paramètre calibré est un paramètre de la CARTE. Ces tests éprouvent le
# dispositif sur le cas où il travaille : une géométrie qui bouge.

func test_a_level_without_calibration_is_warned_not_refused() -> void:
	var result := _parse_grid(_blank_rows())
	assert_eq(result["errors"], PackedStringArray(), "l'absence de calibration n'est pas une faute")
	var found := false
	for w in result["warnings"]:
		if String(w).contains("calibrated_on"):
			found = true
	assert_true(found, "elle doit au moins être signalée")

func test_a_matching_calibration_passes() -> void:
	var first := _parse_grid(_blank_rows())
	var geometry := String((first["level"] as Dictionary)["geometry_hash"])
	var text := _GEO_HEAD.replace("---\n", "calibrated_on: %s\n---\n" % geometry)
	var result := LvlParser.parse(text + "\n".join(PackedStringArray(_blank_rows())), 6, 25)
	assert_eq(result["errors"], PackedStringArray(), "géométrie inchangée : rien à signaler")
	assert_eq(result["warnings"], PackedStringArray(), "calibration à jour : plus aucun avertissement")

func test_a_moved_wall_invalidates_the_calibration() -> void:
	# LE cas qui a motivé l'invariant : la carte bouge, les paramètres
	# mesurés dessus ne décrivent plus rien, et personne ne s'en aperçoit.
	var first := _parse_grid(_blank_rows())
	var geometry := String((first["level"] as Dictionary)["geometry_hash"])
	var moved: Array = _blank_rows()
	moved[1] = "# # # E E E # # # # #"   # l'ouverture se décale d'une case
	var text := _GEO_HEAD.replace("---\n", "calibrated_on: %s\n---\n" % geometry)
	var result := LvlParser.parse(text + "\n".join(PackedStringArray(moved)), 6, 25)
	var errors: PackedStringArray = result["errors"]
	assert_gt(errors.size(), 0, "une géométrie modifiée doit être REFUSÉE")
	assert_true(String(errors[0]).contains("calibration"),
		"l'erreur doit nommer la calibration, pas un symptôme")

func test_the_fingerprint_ignores_the_parameters_it_protects() -> void:
	# Sinon l'empreinte serait circulaire : changer une échéance invaliderait
	# sa propre calibration, et le dispositif ne pourrait jamais être satisfait.
	var rows: Array = _blank_rows()
	var a := LvlParser.parse(_GEO_HEAD + "\n".join(PackedStringArray(rows)), 6, 25)
	var b := LvlParser.parse(
		_GEO_HEAD.replace("max_ticks: 60", "max_ticks: 90").replace("extraction 100", "extraction 80")
		+ "\n".join(PackedStringArray(rows)), 6, 25)
	assert_eq(String((a["level"] as Dictionary)["geometry_hash"]),
		String((b["level"] as Dictionary)["geometry_hash"]),
		"l'empreinte porte sur la carte, pas sur les paramètres")
