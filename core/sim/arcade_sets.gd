class_name ArcadeSets
extends RefCounted
## Quels ENSEMBLES de règles suffisent à gagner un niveau — mode Contrainte.
##
## POURQUOI DANS `core/sim/`. Le calcul n'est que de la simulation : il énumère
## des piles et appelle `SimCore.step`. Il est pur, entier, sans aléatoire ni
## horloge — les invariants 5 à 10 tiennent. Le TIRAGE, lui, est aléatoire et
## vit dans `game/` : c'est la frontière, et elle est nette.
##
## Le calcul est lent (l'espace entier d'un niveau) et sert deux appelants :
## l'outil qui écrit `data/arcade.json`, et le test qui vérifie ce fichier.
## Le jeu, lui, lit le fichier — il ne recalcule jamais rien au démarrage.

## Ensembles minimaux de règles permettant au moins une pile gagnante.
##
## MINIMAUX : si {R01, R04} suffit, {R01, R04, R05} suffit aussi et n'apprend
## rien de plus. Ne garder que les minimaux donne exactement ce qu'il faut pour
## composer un tirage juste et serré.
##
## Chaque ensemble est TRIÉ, et la liste aussi : deux exécutions doivent
## produire le même fichier au caractère près, sans quoi le test qui le vérifie
## échouerait sur un simple réordonnancement.
static func minimal_sufficient_sets(level_data: Dictionary, params: RuleParams) -> Array:
	var allowed: Array[int] = []
	for v in level_data.get("allowed_rules", []):
		allowed.append(int(v))
	var slots := LevelSpec.open_slots(level_data)

	var found: Array = []
	for stack_variant in StackEnumerator.enumerate(allowed, slots):
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		if stack.is_empty():
			continue
		if _outcome(level_data, params, stack) != SimState.Outcome.WON:
			continue
		var as_set: Array = stack.duplicate()
		as_set.sort()
		if not found.has(as_set):
			found.append(as_set)

	# On retire tout ensemble qui en contient strictement un autre.
	var minimal: Array = []
	for candidate in found:
		var redundant := false
		for other in found:
			if other != candidate and _contains(candidate, other):
				redundant = true
				break
		if not redundant:
			minimal.append(candidate)
	minimal.sort_custom(func(a: Array, b: Array) -> bool: return str(a) < str(b))
	return minimal

static func _contains(big: Array, small: Array) -> bool:
	for v in small:
		if not big.has(v):
			return false
	return true

static func _outcome(level_data: Dictionary, params: RuleParams, stack: Array[int]) -> int:
	var state := SimCore.load_level(level_data, params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < 400:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome

## Le tirage `draw` permet-il de gagner ? Vrai s'il contient au moins un
## ensemble suffisant. C'est la seule question que le mode Contrainte pose à
## cette table, et elle doit rester bon marché : le jeu la pose à chaque tirage.
static func is_playable(draw: Array, sufficient: Array) -> bool:
	for s in sufficient:
		if _contains(draw, s as Array):
			return true
	return false
