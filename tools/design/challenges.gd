extends SceneTree
## LES DÉFIS SONT-ILS DES DÉFIS ?
##
## POURQUOI CET OUTIL. Signalé par le concepteur : « niveau 1.3 : défi 3 règles
## inutile car on a 3 règles au max » et « défi bête : absence de vers la
## lumière alors qu'il n'y a pas de lumière ». Les deux sont vrais, et la mesure
## montre qu'ils ne sont pas isolés.
##
## LE CRITÈRE, ET IL EST LE MÊME POUR LES TROIS. **Un défi n'est un défi que
## s'il existe une pile gagnante qui l'obtient ET une pile gagnante qui ne
## l'obtient pas.**
##
##   · S'AUCUNE ne l'obtient, il est impossible : une fausse piste.
##   · Si TOUTES l'obtiennent, il est offert : le joueur le reçoit sans le
##     savoir, en même temps que la victoire, et il n'apprend rien.
##
## C'est aussi ce que demande le concepteur : « il faut que les défis ne soient
## pas réalisés en un coup, il faut plusieurs solutions car les défis ne sont
## pas compatibles ». Un défi qui se gagne avec la première pile venue ne
## demande pas de revenir, donc n'ajoute pas une seule minute de jeu.
##
## L'outil ne corrige rien : il énumère l'espace de chaque niveau, confronte les
## trois défis à ce critère, et propose le SEUIL qui les rendrait vivants.

const GUARD := 400

var _params: RuleParams

func _init() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

	# Sortie DIRECTEMENT COLLABLE dans un `.lvl` : l'outil ne se contente pas de
	# juger, il propose la ligne exacte. Un audit qu'il faut retraduire à la main
	# se retraduit mal.
	print("# niveau : ligne `challenge:` recommandée, mesurée sur l'espace réel")
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		_audit(String(entry["id"]))
	quit()

func _outcome(data: Dictionary, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, _params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome

func _audit(level_id: String) -> void:
	var data := LevelCatalog.load_level_data(level_id)
	var allowed: Array[int] = []
	for v in data.get("allowed_rules", []):
		allowed.append(int(v))
	var spec := LevelSpec.challenges(data)

	# Toutes les gagnantes, avec leur taille et leur durée.
	var sizes: Array[int] = []
	var ticks: Array[int] = []
	var stacks: Array = []
	for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		if stack.is_empty():
			continue
		var state := SimCore.load_level(data, _params)
		var guard := 0
		while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
			state = SimCore.step(state, stack)
			guard += 1
		if state.outcome != SimState.Outcome.WON:
			continue
		stacks.append(stack)
		sizes.append(stack.size())
		ticks.append(state.tick)

	if stacks.is_empty():
		print("%-9s AUCUNE GAGNANTE" % level_id)
		return

	# ÉCONOMIE — vivante si les gagnantes n'ont pas toutes la même taille.
	var min_size := 99
	var max_size := 0
	for s in sizes:
		min_size = mini(min_size, s)
		max_size = maxi(max_size, s)
	var economy := "OFFERT (toutes à %d règles)" % min_size if min_size == max_size \
		else "vivant : %d règles (sinon %d)" % [min_size, max_size]

	# ABSTINENCE — TROIS conditions, et la troisième est celle qui manquait.
	#
	#   1. une gagnante la contient — sinon le défi est déjà acquis d'office ;
	#   2. une gagnante s'en passe — sinon le défi est impossible ;
	#   3. **elle PORTE quelque part** : il existe une gagnante qui cesse de
	#      gagner si on l'en retire.
	#
	# Sans la troisième, « Attendre » ressortait comme candidate sur cinq
	# niveaux : elle figurait dans des gagnantes où elle ne servait à rien, et
	# s'en passer ne demandait donc aucune compréhension. Un défi qui consiste à
	# ne pas choisir une règle inutile n'est pas un défi.
	#
	# Le critère se mesure sans toucher au moteur : une règle porte si la retirer
	# de sa pile fait perdre celle-ci. C'est la même logique que les gagnantes
	# minimales, appliquée règle à règle.
	var alive: Array[int] = []
	for r in allowed:
		# Les jokers portent leur argument dans les bits hauts : leur identifiant
		# ne s'écrit pas « Rxx » et le schéma des défis ne sait pas les nommer.
		if r > 16:
			continue
		var with_it := false
		var without := false
		var load_bearing := false
		for stack in stacks:
			if not (stack as Array).has(r):
				without = true
				continue
			with_it = true
			if load_bearing:
				continue
			var shorter: Array[int] = []
			for v in (stack as Array):
				if int(v) != r:
					shorter.append(int(v))
			if shorter.is_empty() or _outcome(data, shorter) != SimState.Outcome.WON:
				load_bearing = true
		if with_it and without and load_bearing:
			alive.append(r)
	var declared_abs: int = int(spec.get("abstinence_rule", 0))
	var abstinence := "aucune possible"
	if not alive.is_empty():
		var names := PackedStringArray()
		for r in alive:
			names.append("R%02d" % r)
		abstinence = ", ".join(names)
	var abs_verdict := ""
	if declared_abs != 0 and not alive.has(declared_abs):
		abs_verdict = "  ⚠ R%02d DÉCLARÉE MAIS MORTE" % declared_abs

	# EFFICIENCE — vivante si les gagnantes n'ont pas toutes la même durée.
	var min_t := 9999
	var max_t := 0
	for t in ticks:
		min_t = mini(min_t, t)
		max_t = maxi(max_t, t)
	var efficiency := "OFFERT (toutes en %d ticks)" % min_t if min_t == max_t \
		else "vivant : %d ticks (sinon jusqu'à %d)" % [min_t, max_t]

	# LA LIGNE RECOMMANDÉE. Un défi n'est retenu que s'il existe une gagnante qui
	# l'obtient ET une gagnante qui ne l'obtient pas — sinon il est offert ou
	# impossible, et dans les deux cas il n'ajoute rien.
	var tokens := PackedStringArray()
	if min_size < max_size:
		tokens.append("economy=%d" % min_size)
	if not alive.is_empty():
		# La règle la plus HAUTE de la bibliothèque parmi les vivantes : les
		# règles tardives sont celles que le chapitre enseigne, donc celles dont
		# se passer demande vraiment de comprendre.
		var best: int = alive[0]
		for r in alive:
			best = maxi(best, r)
		tokens.append("abstinence=R%02d" % best)
	if min_t < max_t:
		tokens.append("efficiency=%d" % min_t)
	var line := "challenge: " + " ".join(tokens) if not tokens.is_empty() \
		else "(aucun défi possible)"
	print("%-9s %-46s   [%s | %s | %s]%s" % [
		level_id, line, economy, abstinence, efficiency, abs_verdict])
