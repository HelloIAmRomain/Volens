extends SceneTree
## TOUTES LES COMBINAISONS DE TOUS LES NIVEAUX, ET CE QU'ELLES DISENT DU JEU.
##
## LA QUESTION POSÉE, en trois formes qui sont la même : « je ne veux pas
## toujours les mêmes combinaisons gagnantes ; je veux des règles qui combinent
## bien avec certaines dans un niveau et avec d'autres ailleurs ; tout doit au
## plus possible aller avec tout ».
##
## TROIS DÉFAUTS SE MESURENT, et ils n'ont pas la même gravité :
##
##   1. **MONOPOLE** — une règle présente dans TOUTES les gagnantes minimales
##      d'un niveau. Elle n'est plus un choix : c'est un péage. Le joueur ne
##      décide que du reste, et l'espace annoncé est plus grand que l'espace
##      réel.
##
##   2. **ATTELAGE** — deux règles qui n'apparaissent jamais l'une sans l'autre
##      dans tout le jeu. Elles ne font pas deux choix mais un seul, déguisé en
##      deux, et le joueur qui a compris l'une a compris l'autre.
##
##   3. **PAUVRETÉ DE VOISINAGE** — une règle qui ne gagne jamais qu'avec un ou
##      deux partenaires. Elle est utile, mais rigide : on ne la découvre pas
##      dans un nouveau contexte, on la récite.
##
## L'outil ne corrige rien. Il énumère, compte, et nomme — le dessin est ensuite
## une décision de conception, pas un réglage à trouver.
##
## LE COMPTE PORTE SUR LES GAGNANTES **MINIMALES**, jamais sur les brutes. Une
## gagnante rallongée d'une règle inerte gonflerait tous les voisinages : R07
## semblait ainsi combiner avec tout le monde alors qu'elle ne portait rien.
##
## Usage : godot --headless --path . --script res://tools/design/combinations.gd

const GUARD := 400

var _params: RuleParams
## Restreint la mesure à un seul niveau. Le balayage complet dure des minutes ;
## quand on retouche UNE carte on veut la réponse en quelques secondes, sinon on
## cesse de mesurer entre deux essais — et c'est exactement là que les doublons
## se glissent.
var _only := ""

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_only = arg.substr("--level=".length())
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

	# rule -> ensemble des règles avec lesquelles elle a gagné, tous niveaux
	var partners: Dictionary = {}
	# rule -> nombre de niveaux où elle apparaît dans au moins une gagnante
	var seen_in: Dictionary = {}
	var monopolies := PackedStringArray()
	var signatures: Dictionary = {}   # str(set) -> liste de niveaux

	print("niveau    minimales  jeux-de-règles  monopole(s)              exemples")
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		if not _only.is_empty() and level_id != _only:
			continue
		var minimal := _minimal_winners(level_id)
		if minimal.is_empty():
			print("%-9s AUCUNE GAGNANTE" % level_id)
			continue

		# Jeux de règles distincts : deux ordres d'un même trio ne sont pas
		# deux idées, ce sont deux façons d'écrire la même.
		var sets: Dictionary = {}
		for stack in minimal:
			# R16 encode sa case ignorée dans les bits hauts : deux jokers
			# distincts sont la MÊME règle pour qui compte les voisinages.
			var s: Array = []
			for v in stack:
				s.append(RuleRegistry.base_rule_id(int(v)))
			s.sort()
			sets[str(s)] = true
			for r in s:
				seen_in[r] = true
				if not partners.has(r):
					partners[r] = {}
				for other in s:
					if other != r:
						(partners[r] as Dictionary)[other] = true
			if not signatures.has(str(s)):
				signatures[str(s)] = PackedStringArray()
			var lv: PackedStringArray = signatures[str(s)]
			if not lv.has(level_id):
				lv.append(level_id)
				signatures[str(s)] = lv

		# MONOPOLE : présente dans toutes les gagnantes minimales. Sur un niveau
		# à une seule gagnante la notion n'a pas de sens — tout y est monopole.
		var mono := PackedStringArray()
		if minimal.size() > 1:
			var candidates: Array = []
			for v in minimal[0]:
				candidates.append(RuleRegistry.base_rule_id(int(v)))
			for stack in minimal:
				var bases: Array = []
				for v in stack:
					bases.append(RuleRegistry.base_rule_id(int(v)))
				var kept: Array = []
				for r in candidates:
					if bases.has(r):
						kept.append(r)
				candidates = kept
			for r in candidates:
				mono.append("R%02d" % r)
				monopolies.append("%s:R%02d" % [level_id, r])

		var sample := PackedStringArray()
		for key in sets:
			sample.append(String(key))
			if sample.size() >= 3:
				break
		print("%-9s %6d  %10d      %-24s %s" % [
			level_id, minimal.size(), sets.size(),
			", ".join(mono) if not mono.is_empty() else "—",
			" / ".join(sample)])

	_report_partners(partners, seen_in)
	_report_signatures(signatures)
	print("\nMONOPOLES (règle dans TOUTES les gagnantes minimales d'un niveau) : %d\n  %s"
		% [monopolies.size(), ", ".join(monopolies)])
	quit()

## Le voisinage de chaque règle : avec qui a-t-elle déjà gagné ?
func _report_partners(partners: Dictionary, seen_in: Dictionary) -> void:
	print("\nVOISINAGE — avec qui chaque règle gagne, tous niveaux confondus")
	print("règle                    partenaires  liste")
	var rigid := PackedStringArray()
	for rid in RuleRegistry.ALL:
		var set: Dictionary = partners.get(rid, {})
		var names := PackedStringArray()
		var keys: Array = set.keys()
		keys.sort()
		for k in keys:
			names.append("R%02d" % k)
		if not seen_in.has(rid):
			rigid.append("R%02d (jamais gagnante)" % rid)
		elif set.size() <= 1:
			rigid.append("R%02d (%d partenaire)" % [rid, set.size()])
		print("R%02d %-20s %11d  %s" % [
			rid, RuleCatalog.name_of(rid), set.size(), ", ".join(names)])
	print("\nRÈGLES RIGIDES (zéro ou un seul partenaire dans tout le jeu) : %s"
		% (", ".join(rigid) if not rigid.is_empty() else "aucune"))

## Un même jeu de règles qui gagne plusieurs niveaux : la solution se récite.
func _report_signatures(signatures: Dictionary) -> void:
	print("\nJEUX DE RÈGLES GAGNANT PLUSIEURS NIVEAUX")
	var keys: Array = signatures.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool:
		return (signatures[a] as PackedStringArray).size() > (signatures[b] as PackedStringArray).size())
	var repeated := 0
	for k in keys:
		var levels: PackedStringArray = signatures[k]
		if levels.size() < 2:
			continue
		repeated += 1
		print("  %-22s %d niveaux : %s" % [k, levels.size(), ", ".join(levels)])
	if repeated == 0:
		print("  aucun — chaque niveau a ses propres jeux gagnants")

## Les gagnantes MINIMALES : celles dont aucune sous-suite ne gagne déjà.
func _minimal_winners(level_id: String) -> Array:
	var data := LevelCatalog.load_level_data(level_id)
	var allowed: Array[int] = []
	for v in data.get("allowed_rules", []):
		allowed.append(int(v))
	var winners: Array = []
	for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
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
