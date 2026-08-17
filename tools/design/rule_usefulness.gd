extends SceneTree
## CHAQUE RÈGLE EST-ELLE UTILE QUELQUE PART ?
##
## « Il faut que toutes les règles soient utiles à au moins un endroit. Attention
## je suis clair sur le utile, ça veut dire UTILISÉ. Si A,B fonctionne seul alors
## même si A,B,C fonctionne, le C ne compte pas. »
##
## LE CRITÈRE EST DONC « PORTEUSE », PAS « PRÉSENTE ». Une règle porte dans une
## pile gagnante si, en la retirant, la pile cesse de gagner. Figurer dans une
## gagnante ne prouve rien : on peut toujours rallonger une solution avec
## n'importe quelle règle inerte, et le compteur naïf s'en satisfait.
##
## C'est le même critère que celui qui a vidé treize défis d'abstinence sur
## dix-huit (carnet, décision 186) — appliqué cette fois à la bibliothèque
## entière plutôt qu'aux défis.
##
## EQ-04 DEMANDAIT « apparaître dans une solution gagnante de trois niveaux ».
## La mesure montre que c'est trop faible : apparaître n'est pas servir.

const GUARD := 400

var _params: RuleParams

func _init() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

	# rule_id -> liste des niveaux où elle PORTE
	var bearing: Dictionary = {}
	# rule_id -> liste des niveaux qui l'offrent
	var offered: Dictionary = {}

	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var data := LevelCatalog.load_level_data(level_id)
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			var base := RuleRegistry.base_rule_id(int(v))
			allowed.append(int(v))
			if not offered.has(base):
				offered[base] = PackedStringArray()
			var o: PackedStringArray = offered[base]
			if not o.has(level_id):
				o.append(level_id)
				offered[base] = o

		for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
			var stack: Array[int] = []
			for v in stack_variant:
				stack.append(int(v))
			if stack.is_empty() or _outcome(data, stack) != SimState.Outcome.WON:
				continue
			# Pour chaque règle de cette gagnante : la retirer fait-il perdre ?
			for r in stack:
				var base2 := RuleRegistry.base_rule_id(r)
				if bearing.has(base2) and (bearing[base2] as PackedStringArray).has(level_id):
					continue
				var shorter: Array[int] = []
				for v in stack:
					if v != r:
						shorter.append(v)
				if not shorter.is_empty() and _outcome(data, shorter) == SimState.Outcome.WON:
					continue   # la pile gagne sans elle : elle ne portait pas
				if not bearing.has(base2):
					bearing[base2] = PackedStringArray()
				var b: PackedStringArray = bearing[base2]
				b.append(level_id)
				bearing[base2] = b

	print("règle                        offerte  PORTEUSE  niveaux où elle porte")
	var dead := PackedStringArray()
	# On balaie les règles VIVANTES, pas une plage d'identifiants : R07 et R10 ont
	# été retirées et leurs numéros restent réservés, donc `range(1, 17)`
	# rapportait deux règles mortes à chaque exécution.
	for rid in RuleRegistry.ALL:
		var name := RuleCatalog.name_of(rid)
		var off: PackedStringArray = offered.get(rid, PackedStringArray())
		var bear: PackedStringArray = bearing.get(rid, PackedStringArray())
		if bear.is_empty():
			dead.append("R%02d %s" % [rid, name])
		print("R%02d %-24s %3d      %3d      %s" % [
			rid, name, off.size(), bear.size(),
			", ".join(bear) if bear.size() <= 6 else "%s…" % ", ".join(bear.slice(0, 6))])
	print("")
	print("RÈGLES QUI NE PORTENT NULLE PART : %s" % (
		", ".join(dead) if not dead.is_empty() else "aucune"))
	quit()

func _outcome(data: Dictionary, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, _params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome
