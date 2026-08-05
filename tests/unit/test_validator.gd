extends GutTest
## Tests unitaires du validateur v1 (T-024) : énumération de l'espace des
## piles et verdicts sur une fixture connue.

# --- énumération ---------------------------------------------------------------

func test_enumerate_counts_match_the_closed_formula() -> void:
	var three: Array[int] = [1, 2, 3]
	var stacks := StackEnumerator.enumerate(three)
	# P(3,0)+P(3,1)+P(3,2)+P(3,3) = 1+3+6+6 = 16
	assert_eq(stacks.size(), 16)
	assert_eq(stacks.size(), StackEnumerator.expected_count(3))

func test_enumerate_scales_like_the_dct_estimate() -> void:
	# DCT §8.3 : 12 règles -> 11 880 piles complètes, ~13 400 avec partielles.
	assert_eq(StackEnumerator.expected_count(12), 13345)

func test_enumerate_has_no_duplicate_and_no_repeated_rule() -> void:
	var three: Array[int] = [1, 2, 3]
	var stacks := StackEnumerator.enumerate(three)
	var seen: Dictionary = {}
	for stack in stacks:
		var key := str(stack)
		assert_false(seen.has(key), "pile en double : %s" % key)
		seen[key] = true
		var used: Dictionary = {}
		for rule_id in stack:
			assert_false(used.has(rule_id), "règle répétée dans %s" % key)
			used[rule_id] = true

func test_enumerate_respects_the_slots_cap() -> void:
	# CDC §12.2.1 : N_total dépend de allowed_rules ET de slots.
	var three: Array[int] = [1, 2, 3]
	assert_eq(StackEnumerator.enumerate(three, 2).size(), 10, "3 règles, 2 emplacements : 1+3+6")
	assert_eq(StackEnumerator.expected_count(3, 2), 10)
	var one: Array[int] = [1]
	assert_eq(StackEnumerator.enumerate(one, 1).size(), 2, "pile vide + [1]")
	assert_eq(StackEnumerator.expected_count(1, 1), 2)

func test_enumerate_is_deterministic() -> void:
	var three: Array[int] = [1, 2, 3]
	assert_eq(str(StackEnumerator.enumerate(three)), str(StackEnumerator.enumerate(three)))
	# Premier = pile vide, dernier = plus longue en ordre lexicographique inverse.
	var stacks := StackEnumerator.enumerate(three)
	assert_eq(stacks[0], [])
	assert_eq(stacks[stacks.size() - 1], [3, 2, 1])

# --- validation d'une fixture connue ----------------------------------------------

func _corridor_level() -> Dictionary:
	# Couloir 5x1 : agent, sortie, lumière derrière — R01 en tête gagne,
	# pile vide perd par limite de ticks.
	return {
		"max_ticks": 30,
		"allowed_rules": [1, 2, 3],
		"grid": {"size": [5, 1], "cells": [0, 0, 2, 0, 9]},
		"agents": [{"pos": [0, 0]}],
		"objectives": [{"type": "extraction", "percent": 100}],
	}

func test_validate_level_finds_wins_and_losses() -> void:
	var report := ValidateLib.validate_level(_corridor_level(), RuleParams.new())
	var summary: Dictionary = report["summary"]

	assert_eq(summary["n_stacks"], 16)
	assert_gt(int(summary["n_win"]), 0, "R01 en tête doit gagner")
	assert_lt(int(summary["n_win"]), 16, "la pile vide doit perdre")
	assert_eq(int(summary["min_ticks"]), 2, "2 pas jusqu'à la sortie")

func test_simulate_stack_win_row_is_coherent() -> void:
	var stack: Array[int] = [1]
	var row := ValidateLib.simulate_stack(_corridor_level(), RuleParams.new(), stack)

	assert_eq(row["outcome"], SimState.Outcome.WON)
	assert_eq(row["exited"], 1)
	assert_eq(row["ticks"], 2)
	assert_false(row["looped"])

func test_simulate_stack_empty_stack_loses_by_tick_limit() -> void:
	var stack: Array[int] = []
	var row := ValidateLib.simulate_stack(_corridor_level(), RuleParams.new(), stack)

	assert_eq(row["outcome"], SimState.Outcome.LOST)
	assert_eq(row["exited"], 0)

func test_loop_detection_cuts_a_static_simulation_short() -> void:
	# Sans limite basse de ticks (300 par défaut), un agent immobile boucle :
	# la coupe DT-16 doit trancher bien avant les 300 ticks.
	var level := _corridor_level()
	level["max_ticks"] = 300
	var stack: Array[int] = []
	var row := ValidateLib.simulate_stack(level, RuleParams.new(), stack)

	assert_true(row["looped"], "immobilité totale = boucle détectée")
	assert_eq(row["outcome"], SimState.Outcome.LOST)
	assert_lt(int(row["ticks"]), 10, "coupé en quelques ticks, pas 300")

func test_insoluble_level_is_rejected() -> void:
	# Aucune lumière, extraction exigée : aucune pile ne peut gagner.
	var level := {
		"max_ticks": 20,
		"allowed_rules": [1, 2, 3],
		"grid": {"size": [3, 1], "cells": [0, 0, 0]},
		"agents": [{"pos": [0, 0]}],
		"objectives": [{"type": "extraction", "percent": 100}],
	}
	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]

	assert_eq(int(summary["n_win"]), 0)
	assert_string_contains(String(summary["qn01_verdict"]), "insoluble")

# --- contrôles structurels et hors-chapitre (revue S3) ------------------------

func test_cycle_period_below_the_floor_is_structurally_rejected() -> void:
	# Plancher ⚙️ de période (défaut 6) : l'oscillation doit se lire comme
	# un avance/recul, pas un tremblement. Rejet AVANT toute énumération.
	var level := {
		"max_ticks": 20,
		"allowed_rules": [1],
		"grid": {
			"size": [3, 1], "cells": [0, 4, 0],
			"cycle_index": [-1, 0, -1],
			"cycles": [{"period": 4, "active_ticks": 2}],
		},
		"agents": [{"pos": [0, 0]}],
		"objectives": [{"type": "extraction", "percent": 100}],
	}
	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]

	assert_string_contains(String(summary["qn01_verdict"]), "plancher")
	assert_eq(report["rows"].size(), 0, "rejet structurel : aucune simulation lancée")

func test_cycle_period_at_the_floor_passes_the_structural_check() -> void:
	var level := {
		"max_ticks": 20,
		"allowed_rules": [1],
		"grid": {
			"size": [3, 1], "cells": [0, 4, 0],
			"cycle_index": [-1, 0, -1],
			"cycles": [{"period": 6, "active_ticks": 3}],
		},
		"agents": [{"pos": [0, 0]}],
		"objectives": [{"type": "extraction", "percent": 100}],
	}
	var report := ValidateLib.validate_level(level, RuleParams.new())

	assert_gt(int(report["summary"]["n_stacks"]), 0, "période au plancher : énumération normale")

func test_collect_without_transport_rules_is_flagged_out_of_chapter() -> void:
	# 3.6 : « inatteignable faute de R11/R12 autorisées » n'est pas « niveau
	# cassé » — le rapport doit distinguer les deux pour l'authoring du ch. 4.
	var level := {
		"max_ticks": 20,
		"allowed_rules": [1, 2, 3],
		"grid": {"size": [3, 1], "cells": [5, 0, 2]},
		"agents": [{"pos": [1, 0]}],
		"objectives": [{"type": "collect", "count": 1}],
	}
	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]

	assert_true(bool(summary["collect_out_of_chapter"]))
	assert_string_contains(String(summary["qn01_verdict"]), "hors chapitre")

# --- CDC §12.2.1 : slots, dégénérescence, mode informatif ---------------------

func test_slots_key_caps_the_enumerated_space() -> void:
	var level := _corridor_level()
	level["slots"] = 2
	var report := ValidateLib.validate_level(level, RuleParams.new())

	assert_eq(int(report["summary"]["n_stacks"]), 10, "3 règles, 2 emplacements")
	assert_eq(int(report["summary"]["slots"]), 2)

func test_a_level_won_by_the_empty_stack_is_degenerate() -> void:
	# extraction 0 % : satisfaite sans poser une seule règle -> rejet.
	var level := _corridor_level()
	level["objectives"] = [{"type": "extraction", "percent": 0}]
	var report := ValidateLib.validate_level(level, RuleParams.new())

	assert_string_contains(String(report["summary"]["qn01_verdict"]), "dégénéré")

func test_expected_wins_switches_to_informational_mode() -> void:
	# Métadonnées tutorielles : rapportées sans verdict QN-01 (bandes à
	# figer après T-040).
	var level := _corridor_level()
	level["tutorial"] = true
	level["expected_wins"] = 4
	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]

	assert_string_contains(String(summary["qn01_verdict"]), "SANS VERDICT QN-01")
	assert_string_contains(String(summary["qn01_verdict"]), "attendu 4, constaté %d" % int(summary["n_win"]))
	assert_true(bool(summary["tutorial"]))
	assert_between(int(summary["win_ratio_percent"]), 1, 99, "ratio rapporté")
