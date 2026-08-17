extends GutTest
## CHAQUE RÈGLE DOIT ÊTRE UTILE QUELQUE PART — ET « UTILE » VEUT DIRE UTILISÉE.
##
## « Il faut que toutes les règles soient utiles à au moins un endroit. Attention
## je suis clair sur le utile, ça veut dire UTILISÉ. Si A,B fonctionne seul alors
## même si A,B,C fonctionne, le C ne compte pas. »
##
## LE CRITÈRE EST « PORTEUSE », PAS « PRÉSENTE ». Une règle porte dans une pile
## gagnante si, en la retirant, la pile cesse de gagner. Figurer dans une
## gagnante ne prouve rien : on peut rallonger n'importe quelle solution avec
## n'importe quelle règle inerte, et le compteur naïf s'en satisfait.
##
## EQ-04 demandait « apparaître dans une solution gagnante de trois niveaux ».
## La mesure du 15 août 2026 a montré que c'était trop faible : **R07
## « Attendre » était offerte dans quatorze niveaux et ne portait dans aucun.**
## Elle a été retirée, avec R10 qui n'était offerte nulle part.
##
## CE TEST EST COÛTEUX et il l'assume : il énumère l'espace de chaque niveau,
## puis retire chaque règle de chaque gagnante. C'est le prix d'une propriété
## qu'aucune relecture ne peut établir — et la seule qui garantisse qu'aucune
## règle ne redevienne un figurant.

const GUARD := 400

var _params: RuleParams

func before_all() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

func _outcome(data: Dictionary, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, _params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome

func test_every_rule_bears_a_winning_stack_somewhere() -> void:
	var bearing: Dictionary = {}
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var data := LevelCatalog.load_level_data(String(entry["id"]))
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
			var stack: Array[int] = []
			for v in stack_variant:
				stack.append(int(v))
			if stack.is_empty() or _outcome(data, stack) != SimState.Outcome.WON:
				continue
			for r in stack:
				var base := RuleRegistry.base_rule_id(r)
				if bearing.has(base):
					continue
				var shorter: Array[int] = []
				for v in stack:
					if v != r:
						shorter.append(v)
				# Elle PORTE si la pile perd sans elle. Une pile réduite à rien
				# ne gagne jamais : la règle unique d'une gagnante porte donc.
				if shorter.is_empty() or _outcome(data, shorter) != SimState.Outcome.WON:
					bearing[base] = true

	var idle := PackedStringArray()
	for rule_id in RuleRegistry.ALL:
		if not bearing.has(rule_id):
			idle.append("R%02d %s" % [rule_id, RuleCatalog.name_of(rule_id)])
	assert_gt(RuleRegistry.ALL.size(), 0, "aucune règle enregistrée : le balayage est cassé")
	assert_eq(idle, PackedStringArray(),
		("Ces règles ne PORTENT aucune pile gagnante du jeu : aucune solution n'en "
		+ "dépend, et les offrir revient à meubler la bibliothèque. Leur donner un "
		+ "niveau où elles décident, ou les retirer. %s") % ", ".join(idle))

func test_no_level_offers_a_retired_rule() -> void:
	# Les identifiants 7 et 10 restent RÉSERVÉS : ils figurent dans des fiches de
	# conception et dans le carnet. Les réattribuer rendrait ces traces
	# mensongères ; les réoffrir ramènerait les règles par la porte des données.
	var offenders := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		for v in LevelCatalog.load_level_data(String(entry["id"])).get("allowed_rules", []):
			var base := RuleRegistry.base_rule_id(int(v))
			if base == 7 or base == 10:
				offenders.append("%s → R%02d" % [String(entry["id"]), base])
	assert_eq(offenders, PackedStringArray(),
		"niveaux offrant une règle retirée : %s" % ", ".join(offenders))
