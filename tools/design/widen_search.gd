extends SceneTree
## QUELLE RÈGLE AJOUTER À QUEL NIVEAU — MESURÉ, JAMAIS DEVINÉ.
##
## `combinations.gd` a nommé le mal : vingt-deux niveaux sur trente-deux n'ont
## qu'UNE seule pile gagnante minimale, et six jeux de règles gagnent chacun
## trois niveaux. Le joueur ne compose pas : il récite.
##
## LE RÉFLEXE — « élargir la bibliothèque » — A DÉJÀ ÉCHOUÉ, et cher : sur
## ch5_04 il a produit une botte de foin où le joueur s'est bloqué, parce qu'un
## niveau à solution unique élargi reste un niveau à solution unique, avec plus
## de fausses pistes. Élargir n'aide QUE là où une seconde famille existe
## réellement. Cet outil cherche ces endroits-là.
##
## POUR CHAQUE COUPLE (niveau, règle absente), il rejoue tout l'espace des piles
## et classe le résultat en quatre verdicts :
##
##   · **ENRICHIT**  — la règle PORTE dans au moins une nouvelle gagnante
##     minimale, et le nombre de jeux de règles distincts augmente. C'est le seul
##     verdict qui vaut qu'on touche au niveau.
##   · **BANALISE**  — une gagnante plus COURTE apparaît. La leçon du niveau
##     tombe : on la résout désormais avec moins de règles qu'elle n'en enseigne.
##     Verdict fatal, quelle que soit la variété gagnée.
##   · **DOUBLONNE** — la règle porte, mais le jeu de règles obtenu existait
##     déjà. Plus de piles, pas plus d'idées.
##   · **INERTE**    — la règle ne porte nulle part. Une fausse piste de plus.
##
## LE VERDICT PORTE SUR LES GAGNANTES **MINIMALES** et sur la charge, jamais sur
## la présence : ajouter une règle à une bibliothèque allonge mécaniquement des
## piles gagnantes sans rien changer au jeu.
##
## Usage : godot --headless --path . --script res://tools/design/widen_search.gd
##         [-- --level=ch3_02]

const GUARD := 400

var _params: RuleParams
var _only := ""

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_only = arg.substr("--level=".length())
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		if not _only.is_empty() and level_id != _only:
			continue
		_study(level_id)
	quit()

func _study(level_id: String) -> void:
	var data := LevelCatalog.load_level_data(level_id)
	var slots := LevelSpec.open_slots(data)
	var base: Array[int] = []
	for v in data.get("allowed_rules", []):
		base.append(int(v))

	var base_minimal := _minimal_winners(data, base, slots)
	var base_sets := _rule_sets(base_minimal)
	var base_shortest := _shortest(base_minimal)
	print("\n%s — %d gagnantes minimales, %d jeux de règles, plus courte = %d règles"
		% [level_id, base_minimal.size(), base_sets.size(), base_shortest])
	if base_minimal.is_empty():
		return

	var found := false
	for candidate in RuleRegistry.ALL:
		if base.has(candidate):
			continue
		var widened := base.duplicate()
		widened.append(candidate)
		var minimal := _minimal_winners(data, widened, slots)
		if _shortest(minimal) < base_shortest:
			print("   R%02d %-20s BANALISE — gagne en %d règles au lieu de %d : %s"
				% [candidate, RuleCatalog.name_of(candidate), _shortest(minimal),
					base_shortest, str(_example(minimal, _shortest(minimal)))])
			continue
		# La règle PORTE-t-elle ? Elle porte si une gagnante minimale la contient
		# — une minimale ne contient, par construction, aucune règle superflue.
		var carrying: Array = []
		for stack in minimal:
			var bases := _bases(stack)
			if bases.has(candidate):
				carrying.append(bases)
		if carrying.is_empty():
			continue   # INERTE : silencieux, il y en a des dizaines
		var sets := _rule_sets(minimal)
		var fresh := PackedStringArray()
		for s in sets:
			if not base_sets.has(s):
				fresh.append(String(s))
		if fresh.is_empty():
			print("   R%02d %-20s DOUBLONNE — porte, mais aucun jeu de règles nouveau"
				% [candidate, RuleCatalog.name_of(candidate)])
			continue
		found = true
		print("   R%02d %-20s ENRICHIT — %d jeux (au lieu de %d), nouveaux : %s"
			% [candidate, RuleCatalog.name_of(candidate), sets.size(),
				base_sets.size(), " / ".join(fresh)])
	if not found:
		print("   (aucune règle n'enrichit ce niveau sans le banaliser)")

func _bases(stack: Array) -> Array:
	var out: Array = []
	for v in stack:
		out.append(RuleRegistry.base_rule_id(int(v)))
	return out

func _rule_sets(minimal: Array) -> Dictionary:
	var sets: Dictionary = {}
	for stack in minimal:
		var s := _bases(stack)
		s.sort()
		sets[str(s)] = true
	return sets

func _shortest(minimal: Array) -> int:
	var best := 99
	for stack in minimal:
		best = mini(best, (stack as Array).size())
	return best

func _example(minimal: Array, length: int) -> Array:
	for stack in minimal:
		if (stack as Array).size() == length:
			return _bases(stack)
	return []

func _minimal_winners(data: Dictionary, allowed: Array[int], slots: int) -> Array:
	var winners: Array = []
	for stack_variant in StackEnumerator.enumerate(allowed, slots):
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		if stack.is_empty() or _outcome(data, stack) != SimState.Outcome.WON:
			continue
		winners.append(stack)
	var minimal: Array = []
	for stack in winners:
		var redundant := false
		for other in winners:
			if (other as Array).size() < (stack as Array).size() \
					and _is_subsequence(other, stack):
				redundant = true
				break
		if not redundant:
			minimal.append(stack)
	return minimal

func _is_subsequence(small: Array, big: Array) -> bool:
	var j := 0
	for v in big:
		if j < small.size() and small[j] == v:
			j += 1
	return j == small.size()

func _outcome(data: Dictionary, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, _params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome
