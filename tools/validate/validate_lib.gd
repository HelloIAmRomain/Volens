class_name ValidateLib
extends RefCounted
## Cœur du validateur v1 (T-024, DCT §8) : simule chaque pile de l'espace
## énuméré avec LE MÊME code que le jeu (DT-15 — SimCore, jamais une
## réimplémentation) et produit un rapport.
##
## Coupes sûres (DT-16 étage 2) :
## — arrêt dès que `outcome` quitte RUNNING ;
## — détection de cycle : si le couple (empreinte de dynamique, tick modulo
##   ppcm des périodes) se répète, la simulation boucle — les compteurs ne
##   progresseront plus jamais, l'issue est un échec anticipé.

## Simule une pile jusqu'à l'issue, la limite de ticks du niveau, ou une
## boucle détectée. Renvoie : outcome, ticks, exited, lost, final_hash,
## looped.
static func simulate_stack(level_data: Dictionary, params: RuleParams, stack: Array[int]) -> Dictionary:
	var state := SimCore.load_level(level_data, params)
	var tick_cap: int = state.max_ticks if state.max_ticks > 0 else 300
	var modulus: int = _cycle_modulus(state)
	var seen: Dictionary = {}

	var looped := false
	while state.outcome == SimState.Outcome.RUNNING and state.tick < tick_cap:
		state = SimCore.step(state, stack)
		if state.outcome != SimState.Outcome.RUNNING:
			break
		var key := "%d:%s" % [state.tick % modulus, StateHash.to_hex(StateHash.dynamics_hash(state))]
		if seen.has(key):
			looped = true
			break
		seen[key] = true

	var outcome: int = state.outcome
	if looped:
		outcome = SimState.Outcome.LOST  # boucle = objectif à jamais hors d'atteinte

	return {
		"stack": stack.duplicate(),
		"outcome": outcome,
		"ticks": state.tick,
		"exited": state.counters.exited,
		"lost": state.counters.lost,
		"final_hash": StateHash.to_hex(SimCore.hash_state(state)),
		"looped": looped,
	}

## Module de répétition temporelle : ppcm des périodes des dangers
## cycliques (1 sans cycle). Deux états de même dynamique ne sont vraiment
## équivalents que si les cycles sont dans la même phase — d'où la clé
## (tick mod ppcm, empreinte de dynamique).
static func _cycle_modulus(state: SimState) -> int:
	var m := 1
	for cycle in state.grid.cycles:
		if cycle.period > 0:
			@warning_ignore("integer_division")
			var reduced: int = m / _gcd(m, cycle.period)  # division exacte (par le pgcd)
			m = reduced * cycle.period
	return m

static func _gcd(a: int, b: int) -> int:
	var x := a
	var y := b
	while y != 0:
		var t := y
		y = x % y
		x = t
	return x

## Valide un niveau entier : énumère les piles autorisées, simule chacune,
## agrège. Renvoie { rows, summary }.
static func validate_level(level_data: Dictionary, params: RuleParams) -> Dictionary:
	var allowed: Array[int] = []
	for v in level_data.get("allowed_rules", []):
		allowed.append(int(v))

	var stacks := StackEnumerator.enumerate(allowed)
	var rows: Array = []
	var wins: Array = []
	for stack_variant in stacks:
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		var row := simulate_stack(level_data, params, stack)
		rows.append(row)
		if row["outcome"] == SimState.Outcome.WON:
			wins.append(row)

	# Classes structurelles : piles gagnantes regroupées par empreinte finale
	# (DCT §8.2 — même empreinte = même déroulement, variante triviale).
	var classes: Dictionary = {}
	for w in wins:
		var h: String = w["final_hash"]
		if not classes.has(h):
			classes[h] = 0
		classes[h] += 1

	var min_ticks := -1
	var best_stack: Array = []
	for w in wins:
		if min_ticks == -1 or int(w["ticks"]) < min_ticks:
			min_ticks = int(w["ticks"])
			best_stack = w["stack"]

	var n_classes: int = classes.size()
	var verdict: String
	if wins.is_empty():
		verdict = "REJETÉ : insoluble (zéro pile gagnante)"
	elif n_classes == 1:
		verdict = "REJETÉ : puzzle déguisé (une seule classe de solution)"
	elif n_classes < 3:
		verdict = "SOUS LE SEUIL QN-01 (classes < 3) : à retravailler"
	elif n_classes > 40:
		verdict = "AU-DESSUS DU SEUIL QN-01 (classes > 40) : niveau creux, à durcir"
	else:
		verdict = "CONFORME QN-01 (3 <= classes <= 40)"

	return {
		"rows": rows,
		"summary": {
			"n_stacks": rows.size(),
			"expected_stacks": StackEnumerator.expected_count(allowed.size()),
			"n_win": wins.size(),
			"n_win_classes": n_classes,
			"min_ticks": min_ticks,
			"best_stack": best_stack,
			"qn01_verdict": verdict,
		},
	}
