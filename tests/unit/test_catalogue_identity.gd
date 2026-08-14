extends GutTest
## LES RÈGLES D'IDENTITÉ, ÉTENDUES À TOUT LE CATALOGUE.
##
## `test_solution_identity.gd` les vérifie sur l'arc du chapitre 1, où elles
## ont été formulées. Elles n'ont de sens qu'appliquées à l'ENSEMBLE du jeu :
## un joueur ne s'arrête pas au chapitre 1, et une pile universelle découverte
## au chapitre 4 vide les trois chapitres suivants exactement de la même façon.
##
## CE FICHIER SIMULE TOUT LE CATALOGUE. C'est lent — plusieurs milliers de
## piles — et c'est le prix d'une propriété qu'aucune relecture ne peut donner.

var _winners: Dictionary = {}   # level_id -> Array[String] de clés de pile

func before_all() -> void:
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

func _simulate(data: Dictionary, params: RuleParams, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < 400:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome

# --- S1 : aucun niveau n'est une formalité ni une impasse ------------------

func test_every_level_of_the_game_is_solvable() -> void:
	# Un niveau insoluble bloque la progression pour toujours : c'est le seul
	# défaut qui rend le jeu injouable plutôt que décevant.
	assert_gt(_winners.size(), 0, "aucun niveau prêt : le catalogue est vide")
	var dead := PackedStringArray()
	for level_id in _winners:
		if (_winners[level_id] as Array).is_empty():
			dead.append(String(level_id))
	assert_eq(dead, PackedStringArray(), "niveaux insolubles : %s" % ", ".join(dead))

func test_no_level_is_won_by_the_empty_stack() -> void:
	var degenerate := PackedStringArray()
	for level_id in _winners:
		if (_winners[level_id] as Array).has("[]"):
			degenerate.append(String(level_id))
	assert_eq(degenerate, PackedStringArray(),
		"niveaux gagnés sans poser une seule règle : %s" % ", ".join(degenerate))

# --- S4 : une règle seule ne gagne que le niveau qui l'introduit -----------

func test_a_single_rule_only_wins_the_level_that_introduces_it() -> void:
	# LA RÈGLE LA PLUS EXIGEANTE DU LOT, et celle qui garantit que le jeu porte
	# sur l'ORDRE. Partout ailleurs qu'au niveau d'introduction, il faut au
	# moins deux règles — donc un ordre, donc la règle d'or.
	var breaches := PackedStringArray()
	var checked := 0
	for level_id in _winners:
		for key in (_winners[level_id] as Array):
			var stack: Array = str_to_var(String(key))
			if stack == null or stack.size() != 1:
				continue
			checked += 1
			if _introduces(String(level_id), int(stack[0])):
				continue
			breaches.append("%s:%s" % [level_id, key])
	breaches.sort()
	assert_eq(breaches, PackedStringArray(),
		("S4 — une pile d'une seule règle gagne un niveau qui ne l'introduit pas. "
		+ "Ces niveaux ne portent alors sur aucun ordre. Occurrences : %s")
		% ", ".join(breaches))
	assert_gt(checked, 0, "aucune pile d'une seule règle examinée : le filtre a tout écarté")

## Un niveau introduit une règle s'il est le PREMIER du catalogue à l'offrir.
## Déduit de `allowed_rules`, jamais déclaré à côté — une seconde liste des
## introductions divergerait au premier niveau réordonné (invariant n°16).
func _introduces(level_id: String, rule_id: int) -> bool:
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var data := LevelCatalog.load_level_data(String(entry["id"]))
		for v in data.get("allowed_rules", []):
			if int(v) == rule_id:
				return String(entry["id"]) == level_id
	return false

# --- S3 : non-transposabilité ----------------------------------------------

func test_no_stack_is_a_master_key_across_the_whole_game() -> void:
	# UNE PILE QUI RÉSOUT LA MOITIÉ DU JEU LE VIDE. Le cliquet fige le pire cas
	# mesuré et refuse toute aggravation : on ne découvre jamais un passe-partout
	# en relisant, seulement en simulant.
	var count := {}
	for level_id in _winners:
		for key in (_winners[level_id] as Array):
			if not count.has(key):
				count[key] = 0
			count[key] += 1
	var worst := 0
	var champion := ""
	var keys := count.keys()
	keys.sort()
	for key in keys:
		if int(count[key]) > worst:
			worst = int(count[key])
			champion = String(key)
	assert_lte(worst, MASTER_KEY_CEILING,
		("AGGRAVATION : la pile %s résout %d niveaux (plafond mesuré %d). "
		+ "Une pile qui traverse le jeu le vide de son sujet.") % [
			champion, worst, MASTER_KEY_CEILING])
	assert_gt(worst, 0, "aucune pile gagnante nulle part : le balayage est cassé")

## PIRE CAS MESURÉ le 14 août 2026 sur les dix-neuf niveaux : **[Marquer,
## Suivre] résout trois niveaux** — les trois du chapitre 3, ce qui est
## exactement ce qu'un chapitre est censé faire. Aucune pile ne traverse deux
## chapitres.
##
## Cliquet : il ne remonte jamais. L'abaisser demande de retoucher un niveau,
## pas ce chiffre.
const MASTER_KEY_CEILING := 3
