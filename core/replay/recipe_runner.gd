class_name RecipeRunner
extends RefCounted
## Rejeu d'une recette aux points de contrôle [DT-09, DT-22] — **source unique**.
##
## POURQUOI ELLE EST ICI ET PAS DANS `tools/`. Deux appelants doivent rejouer
## exactement la même chose : le vérificateur de corpus d'or (`tools/`, jamais
## exporté) et l'écran d'auto-vérification embarqué dans les builds de test
## (`game/selfcheck/`). Or `tools/` est exclu de l'export : l'écran ne peut pas
## l'appeler. Réimplémenter la boucle donnerait **deux vérités** — et une
## divergence entre elles rendrait toute comparaison d'empreintes muette,
## précisément là où l'on cherche à en tirer une preuve.
##
## `core/replay/` est le seul endroit que les deux ont le droit d'importer
## (règles de dépendance 3 et 4). La fonction est PURE : elle reçoit des
## dictionnaires déjà chargés, elle ne lit aucun fichier — c'est l'appelant qui
## charge, conformément à DT-15.

## Rejoue `stack` sur `level_data` et renvoie les empreintes hexadécimales aux
## ticks demandés : { "50": "…", "150": "…" }. Les points de contrôle doivent
## être croissants.
##
## La simulation continue après un `outcome` décidé : l'état terminal reste
## stable, son empreinte aussi, et cette stabilité fait partie du contrat.
static func run(level_data: Dictionary, params: RuleParams,
		stack_raw: Array, checkpoints: Array) -> Dictionary:
	var stack: Array[int] = []
	for v in stack_raw:
		stack.append(int(v))

	var state := SimCore.load_level(level_data, params)
	var out: Dictionary = {}
	var last_tick: int = 0
	for cp in checkpoints:
		var target := int(cp)
		while last_tick < target:
			state = SimCore.step(state, stack)
			last_tick += 1
		out[str(target)] = StateHash.to_hex(SimCore.hash_state(state))
	return out
