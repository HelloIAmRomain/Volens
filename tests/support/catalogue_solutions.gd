class_name CatalogueSolutions
extends RefCounted
## L'ESPACE DES SOLUTIONS DE TOUT LE JEU, calculé UNE FOIS par exécution.
##
## POURQUOI CE CACHE EXISTE. Deux tests ont besoin de la même chose — quelles
## piles gagnent quel niveau — et chacun la recalculait de son côté : énumérer
## et simuler l'intégralité du catalogue, deux fois. Mesuré le 15 août 2026 :
## 78 secondes chacun, soit **86 % du temps total de la suite** dépensés deux
## fois pour le même résultat.
##
## Le coût croît avec le catalogue. À vingt-cinq niveaux c'est déjà le poste
## dominant ; à soixante-dix, chaque test approcherait les quatre minutes et la
## suite cesserait d'être lancée à chaque modification — ce qui est la seule
## façon dont une suite de tests meurt vraiment.
##
## DÉTERMINISME : le calcul est pur (mêmes niveaux, mêmes règles, même
## résultat), donc le mettre en cache ne peut rien fausser. C'est exactement la
## propriété que le corpus d'or protège par ailleurs.

const GUARD_TICKS := 400

static var _winners: Dictionary = {}     # level_id -> Array[String] de clés de pile
static var _computed: bool = false

## `level_id` -> Array[String], chaque entrée étant `str(Array[int])`.
static func winners() -> Dictionary:
	if not _computed:
		_compute()
	return _winners

## Nombre de niveaux distincts où la règle apparaît dans au moins une gagnante.
## Les jokers comptent pour leur règle de base (R16), qui est ce qu'EQ-04 mesure.
static func levels_won_with(rule_id: int) -> int:
	var n := 0
	for level_id in winners():
		for key in (winners()[level_id] as Array):
			var stack: Variant = str_to_var(String(key))
			if not (stack is Array):
				continue
			var found := false
			for r in (stack as Array):
				if RuleRegistry.base_rule_id(int(r)) == rule_id:
					found = true
					break
			if found:
				n += 1
				break
	return n

static func _compute() -> void:
	_computed = true
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	var params := RuleParams.from_dict(rules if rules is Dictionary else {})
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var data := LevelCatalog.load_level_data(level_id)
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		var won: Array[String] = []
		for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
			var stack: Array[int] = []
			for v in stack_variant:
				stack.append(int(v))
			if _simulate(data, params, stack) == SimState.Outcome.WON:
				won.append(str(stack))
		_winners[level_id] = won

static func _simulate(data: Dictionary, params: RuleParams, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD_TICKS:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome
