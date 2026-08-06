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

# --- contention : le critère opérationnel de RG-13 -----------------------------

func test_contention_is_zero_when_action_zones_never_overlap() -> void:
	# Un niveau SANS danger : R02 ne veut jamais agir, donc jamais en même
	# temps que R01. Leur ordre relatif ne peut rien changer — c'est
	# exactement ce que la métrique doit dire.
	var level := _oscillation_level([{"pos": [0, 13]}])
	level["grid"]["cells"][10 * 10 + 4] = GridState.CellType.EMPTY  # retire le danger
	var stack: Array[int] = [1, 2]
	var row := ValidateLib.simulate_stack(level, RuleParams.new(), stack, true)

	assert_eq(int(row["contention"]), 0, "sans danger, R02 ne dispute jamais un agent à R01")

func test_contention_is_positive_when_both_rules_want_the_same_agent() -> void:
	# Avec un danger sur le trajet, l'agent est à la fois attiré par la
	# lumière et repoussé par le danger : les deux règles veulent agir.
	var stack: Array[int] = [1, 2]
	var row := ValidateLib.simulate_stack(_oscillation_level([{"pos": [0, 13]}]), RuleParams.new(), stack, true)

	assert_gt(int(row["contention"]), 0, "R01 et R02 se disputent le même agent")

func test_blind_pairs_are_named_in_the_verdict() -> void:
	# Sans danger, la paire R01/R02 est aveugle : le rapport doit le dire
	# plutôt que de laisser croire à un conflit de priorité (RG-13).
	var level := _oscillation_level([{"pos": [0, 13]}])
	level["grid"]["cells"][10 * 10 + 4] = GridState.CellType.EMPTY
	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]

	assert_true(PackedStringArray(summary["blind_pairs"]).has("1-2"),
		"la paire R01/R02 doit être signalée aveugle : %s" % str(summary["blind_pairs"]))
	assert_string_contains(String(summary["qn01_verdict"]), "INOBSERVABLE")

func test_contention_is_only_measured_on_two_rule_stacks() -> void:
	# Coût maîtrisé : la mesure n'a de sens que là où la paire est seule à
	# décider, et c'est aussi là qu'elle est bon marché.
	var stack: Array[int] = [1]
	var row := ValidateLib.simulate_stack(_oscillation_level([{"pos": [0, 13]}]), RuleParams.new(), stack, true)

	assert_eq(int(row["contention"]), 0, "une pile d'une seule règle ne dispute rien")

# --- sur-place perpétuel (cycle limite de portée) ------------------------------

## Reproduit le cycle mesuré le 6 août 2026, aux coordonnées exactes de la
## trace : lumière (4,0), bande de sortie rangée 1, danger (4,10).
## Un agent en (0,13) est à d² = 25 — pile à la portée de R02, qui le
## repousse au sud ; en (0,14) il est à d² = 32, hors de portée, et R01 le
## ramène au nord. Répulseur à seuil + attracteur = cycle de période 2.
func _oscillation_level(agents: Array) -> Dictionary:
	var cells: Array = []
	cells.resize(10 * 18)
	cells.fill(0)
	cells[4] = GridState.CellType.LIGHT_SOURCE             # (4,0)
	for x in range(10):
		cells[10 + x] = GridState.CellType.EXIT            # rangée 1
	cells[10 * 10 + 4] = GridState.CellType.STATIC_DANGER  # (4,10)
	return {
		"max_ticks": 120,
		"allowed_rules": [1, 2],
		"grid": {"size": [10, 18], "cells": cells},
		"agents": agents,
		"objectives": [{"type": "extraction", "percent": 100}],
	}

func test_range_boundary_limit_cycle_is_reported() -> void:
	var stack: Array[int] = [2, 1]
	var row := ValidateLib.simulate_stack(_oscillation_level([{"pos": [0, 13]}]), RuleParams.new(), stack)

	assert_eq(int(row["oscillating"]), 1, "l'agent fait du sur-place perpétuel")
	assert_eq(int(row["stuck"]), 0, "il bouge : ce n'est pas un agent figé")

func test_a_marching_swarm_reports_no_oscillation() -> void:
	# Contre-borne : sans R02 dans la pile, l'agent monte tout droit et sort.
	var stack: Array[int] = [1]
	var row := ValidateLib.simulate_stack(_oscillation_level([{"pos": [0, 13]}]), RuleParams.new(), stack)

	assert_eq(int(row["outcome"]), SimState.Outcome.WON)
	assert_eq(int(row["oscillating"]), 0)

func test_a_frozen_agent_counts_as_stuck_not_oscillating() -> void:
	# Pile vide : personne ne bouge — figé, pas oscillant. La distinction
	# compte : un agent figé peut être légitime, un oscillant jamais.
	var stack: Array[int] = []
	var row := ValidateLib.simulate_stack(_oscillation_level([{"pos": [0, 13]}]), RuleParams.new(), stack)

	assert_eq(int(row["oscillating"]), 0)
	assert_eq(int(row["stuck"]), 1)

func test_oscillation_in_a_winning_stack_is_flagged_in_the_verdict() -> void:
	# LE cas qui compte, et celui que la coupe de boucle ne voit pas : le
	# niveau est GAGNABLE et paraît cassé. L'agent de la colonne 9 traverse
	# librement et sort ; celui de la colonne 0 oscille pendant tout ce
	# temps. L'objectif à 50 % est atteint — le rapport doit quand même le
	# signaler.
	var level := _oscillation_level([{"pos": [9, 16]}, {"pos": [0, 13]}])
	level["objectives"] = [{"type": "extraction", "percent": 50}]
	var report := ValidateLib.validate_level(level, RuleParams.new())
	var summary: Dictionary = report["summary"]

	assert_gt(int(summary["n_win"]), 0, "le niveau est gagnable")
	assert_gt(int(summary["wins_with_oscillation"]), 0, "et laisse pourtant un agent osciller")
	assert_string_contains(String(summary["qn01_verdict"]), "sur-place perpétuel")

# --- RG-04 : identité vs équivalence (classes QN-01) --------------------------

func _state_with_agents(positions: Array, flags_list: Array = []) -> SimState:
	var level := {
		"max_ticks": 50,
		"grid": {"size": [5, 5], "cells": []},
		"agents": positions.map(func(p: Variant) -> Dictionary: return {"pos": p}),
	}
	var state := SimCore.load_level(level, RuleParams.new())
	for i in range(flags_list.size()):
		state.agents[i].flags = flags_list[i]
	return state

func test_equivalence_key_ignores_agent_identity() -> void:
	# RG-04 : les agents sont anonymes et interchangeables. Deux issues aux
	# mêmes cases occupées, seuls les identifiants permutés, sont LA MÊME
	# solution — QN-01 exclut les variantes triviales.
	var a := _state_with_agents([[1, 1], [3, 3]])
	var b := _state_with_agents([[3, 3], [1, 1]])

	assert_ne(SimCore.hash_state(a), SimCore.hash_state(b),
		"l'IDENTITÉ distingue les deux (les id sont hachés) — et doit continuer")
	assert_eq(ValidateLib.equivalence_key(a), ValidateLib.equivalence_key(b),
		"l'ÉQUIVALENCE ne les distingue pas : même nuée, identifiants permutés")

func test_equivalence_key_still_separates_different_shapes() -> void:
	var a := _state_with_agents([[1, 1], [3, 3]])
	var b := _state_with_agents([[1, 1], [3, 2]])

	assert_ne(ValidateLib.equivalence_key(a), ValidateLib.equivalence_key(b),
		"une case différente reste une solution différente")

func test_equivalence_key_separates_different_counters() -> void:
	var a := _state_with_agents([[1, 1], [3, 3]])
	var b := _state_with_agents([[1, 1], [3, 3]])
	b.counters.exited = 1

	assert_ne(ValidateLib.equivalence_key(a), ValidateLib.equivalence_key(b))

func test_equivalence_key_separates_different_flags() -> void:
	# Sortis et perdus ne se confondent pas, même à positions identiques.
	var a := _state_with_agents([[1, 1], [3, 3]], [AgentState.SORTI, AgentState.PRESENT])
	var b := _state_with_agents([[1, 1], [3, 3]], [AgentState.PERDU, AgentState.PRESENT])

	assert_ne(ValidateLib.equivalence_key(a), ValidateLib.equivalence_key(b))

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

func test_expected_classes_is_confronted_and_reported() -> void:
	# Arbitrage du 6 août : expected_wins = piles, expected_classes = classes
	# structurelles, les deux rapportés sans verdict.
	var level := _corridor_level()
	level["expected_wins"] = 4
	level["expected_classes"] = 2
	var report := ValidateLib.validate_level(level, RuleParams.new())
	var verdict := String(report["summary"]["qn01_verdict"])

	assert_string_contains(verdict, "classes : attendu 2, constaté %d" % int(report["summary"]["n_win_classes"]))
	assert_eq(int(report["summary"]["expected_classes"]), 2)
