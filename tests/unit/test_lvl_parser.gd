extends GutTest
## Tests du convertisseur .lvl (avance sur T-074) : aller-retour, stabilité
## de l'attribution des ids (ordre de lecture), rejet de chaque cas d'erreur.

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

## Grille valide 8×10 : lumière en haut, bande de sortie, deux agents.
func _grid(rows_override: Dictionary = {}) -> String:
	var rows := [
		". . . L . . . .",
		"E E E E E E E E",
		". . . . . . . .",
		". . . . . . . .",
		". . . . . . . .",
		". . . . . . . .",
		". . . . . . . .",
		". . o . . o . .",
		". . . . . . . .",
		". . . . . . . .",
	]
	for y in rows_override:
		rows[y] = rows_override[y]
	return "\n".join(PackedStringArray(rows))

func _parse(header_overrides: Dictionary = {}, rows_override: Dictionary = {}, extra_header := "") -> Dictionary:
	var text := _header(header_overrides) + extra_header + "---\n" + _grid(rows_override) + "\n"
	return LvlParser.parse(text, FLOOR)

func _errors_joined(result: Dictionary) -> String:
	return ", ".join(result["errors"] as PackedStringArray)

# --- chemin nominal ---------------------------------------------------------

func test_valid_level_parses_without_errors() -> void:
	var result := _parse({"objective": null}, {}, "objective: extraction 100\n")
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))
	var level: Dictionary = result["level"]
	assert_eq(level["id"], "test_lvl")
	assert_eq(level["slots"], 1)
	assert_eq(level["allowed_rules"], [1])
	assert_eq(level["grid"]["size"], [8, 10])
	assert_eq(level["grid"]["cells"][3], GridState.CellType.LIGHT_SOURCE, "L en (3,0)")
	assert_eq(level["grid"]["cells"][8], GridState.CellType.EXIT, "E en (0,1)")
	assert_eq((level["agents"] as Array).size(), 2)
	assert_eq(level["objectives"], [{"type": "extraction", "percent": 100}])

func test_agent_ids_follow_reading_order() -> void:
	# Convention n°1 (déterminisme) : ligne par ligne, gauche à droite.
	var result := _parse({}, {6: ". . . . . o . .", 7: ". o . . . . . .", 8: ". . . o . . . ."})
	var agents: Array = result["level"]["agents"]
	assert_eq(agents[0]["pos"], [5, 6], "id 0 : première ligne lue")
	assert_eq(agents[1]["pos"], [1, 7])
	assert_eq(agents[2]["pos"], [3, 8], "id 2 : dernière ligne lue")

func test_spacing_between_symbols_is_ignored() -> void:
	var compact := _parse({}, {7: "..o..o.."})
	assert_eq((compact["errors"] as PackedStringArray).size(), 0, "symboles collés acceptés")
	assert_eq((compact["level"]["agents"] as Array).size(), 2)

func test_json_round_trip_preserves_the_level() -> void:
	var level: Dictionary = _parse({}, {}, "objective: extraction 60\n")["level"]
	var back: Variant = JSON.parse_string(JSON.stringify(level))
	assert_eq(back["grid"]["cells"], Array(level["grid"]["cells"]).map(func(v: Variant) -> float: return float(v)),
		"les cases survivent à l'aller-retour JSON (en nombres, tous < 2^53)")
	assert_eq(int(back["max_ticks"]), int(level["max_ticks"]))
	assert_eq((back["agents"] as Array).size(), (level["agents"] as Array).size())

func test_cyclic_danger_wires_cycle_and_index() -> void:
	var result := _parse({}, {4: ". . C . . . . ."}, "cycle: period=6 active=3\n")
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))
	var grid: Dictionary = result["level"]["grid"]
	assert_eq(grid["cycles"], [{"period": 6, "active_ticks": 3}])
	assert_eq(grid["cycle_index"][4 * 8 + 2], 0, "la case C pointe le cycle 0")

# --- rejets ------------------------------------------------------------------

func test_rejects_missing_separator() -> void:
	var result := LvlParser.parse("id: x\n. . .\n", FLOOR)
	assert_string_contains(_errors_joined(result), "---")

func test_rejects_grid_without_agents() -> void:
	var result := _parse({}, {7: ". . . . . . . ."})
	assert_string_contains(_errors_joined(result), "aucun agent")

func test_rejects_extraction_without_exit() -> void:
	var result := _parse({}, {1: ". . . . . . . ."}, "objective: extraction 100\n")
	assert_string_contains(_errors_joined(result), "sans aucune sortie")

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
	var text := _header() + "---\n" + "\n".join(PackedStringArray([
		". . . . . . .", ". . . . . . .", ". . . . . . .", ". . . . . . .",
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

func test_rejects_cycle_below_the_floor() -> void:
	var result := _parse({}, {4: ". . C . . . . ."}, "cycle: period=4 active=2\n")
	assert_string_contains(_errors_joined(result), "plancher")

func test_rejects_cyclic_cell_without_cycle_declaration() -> void:
	var result := _parse({}, {4: ". . C . . . . ."})
	assert_string_contains(_errors_joined(result), "aucune ligne `cycle:")

func test_rejects_unimplemented_rule() -> void:
	var result := _parse({"allowed_rules": "[R01, R07]"})
	assert_string_contains(_errors_joined(result), "non implémentée")

func test_rejects_invalid_slots() -> void:
	var result := _parse({"slots": "5"})
	assert_string_contains(_errors_joined(result), "slots=5")

# --- critère de fin du lot : ch1_01 de bout en bout ---------------------------

func test_ch1_01_converts_and_validates_at_exactly_one_win() -> void:
	# Le croquis N1 corrigé (bande de sortie, largeur 8) : converti, validé,
	# N_win == 1 — le critère de fin du prompt §9, verrouillé en permanence.
	var text := FileAccess.get_file_as_string("res://data/levels/ch1_01.lvl")
	var result := LvlParser.parse(text, FLOOR)
	assert_eq((result["errors"] as PackedStringArray).size(), 0, _errors_joined(result))

	var level: Dictionary = result["level"]
	assert_eq((level["agents"] as Array).size(), 20)
	assert_true(bool(level["tutorial"]))

	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]
	assert_eq(int(summary["n_stacks"]), 2, "1 règle, 1 emplacement : pile vide + [1]")
	assert_eq(int(summary["n_win"]), 1, "expected_wins de la fiche")
	assert_string_contains(String(summary["qn01_verdict"]), "attendu 1, constaté 1")
