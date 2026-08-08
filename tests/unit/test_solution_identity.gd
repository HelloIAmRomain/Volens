extends GutTest
## IDENTITÉ DES SOLUTIONS — un niveau ne se résout pas comme son voisin.
##
## QN-02 interdit qu'une pile résolve **tous** les niveaux d'un chapitre.
## C'est un plancher, pas une ambition : il est satisfait par un chapitre où
## la même pile en résout quatre sur cinq.
##
## Ce que le chapitre doit vraiment garantir, et que ces tests mesurent :
##
##   S1 — **Ensembles distincts.** Deux niveaux n'ont jamais exactement le
##        même ensemble de piles gagnantes. Sinon le second n'apprend rien :
##        il valide la réponse du premier.
##
##   S2 — **Philosophies distinctes.** L'ensemble des FAMILLES gagnantes
##        (définies par la règle qui décide en tête) diffère d'un niveau à
##        l'autre. C'est la version forte : ce n'est pas la pile qui doit
##        changer, c'est la *manière de penser* le niveau.
##
##   S3 — **Non-transposabilité.** Aucune pile ne résout plus de deux niveaux
##        du chapitre. Une pile qui en résout trois est une réponse qu'on
##        emporte, et le joueur cesse de lire les niveaux.
##
## Le chapitre 1 est la porte d'entrée : c'est là que le jeu prouve que
## l'ordre compte. Aux chapitres suivants, avec douze règles, ces propriétés
## deviennent la seule défense contre un espace de piles qui s'aplatit.

const LEVELS := ["ch1_01", "ch1_02", "ch1_03", "ch1_04", "ch1_05"]

var _winners: Dictionary = {}    # level_id -> Array[String] de clés de piles
var _families: Dictionary = {}   # level_id -> Dictionary de familles gagnantes

func before_all() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	var params := RuleParams.from_dict(rules if rules is Dictionary else {})
	for level_id in LEVELS:
		var data := LevelCatalog.load_level_data(level_id)
		if data.is_empty():
			continue
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		var won: Array[String] = []
		var families := {}
		for raw in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
			var stack: Array[int] = []
			for v in raw:
				stack.append(int(v))
			if _outcome(data, params, stack) != SimState.Outcome.WON:
				continue
			won.append(str(stack))
			if not stack.is_empty():
				families[stack[0]] = true
		won.sort()
		_winners[level_id] = won
		_families[level_id] = families

func _outcome(data: Dictionary, params: RuleParams, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < 400:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome

# --- S1 : ensembles distincts ---------------------------------------------

func test_no_two_levels_share_the_same_solution_set() -> void:
	for i in range(LEVELS.size()):
		for j in range(i + 1, LEVELS.size()):
			var a: Array = _winners[LEVELS[i]]
			var b: Array = _winners[LEVELS[j]]
			assert_ne(str(a), str(b),
				"%s et %s ont exactement les mêmes solutions : le second ne prouve rien" % [
					LEVELS[i], LEVELS[j]])

func test_every_level_is_solvable_and_none_is_a_formality() -> void:
	for level_id in LEVELS:
		var won: Array = _winners[level_id]
		assert_gt(won.size(), 0, "%s : aucune pile gagnante" % level_id)
		assert_false(won.has("[]"), "%s : la pile VIDE gagne — niveau dégénéré" % level_id)

# --- S2 : philosophies distinctes ------------------------------------------

func test_no_two_levels_are_won_by_the_same_set_of_families() -> void:
	# La règle en tête de pile détermine la manière de penser le niveau :
	# foncer (R01), contourner (R02), rassembler (R03). Deux niveaux gagnés
	# par les mêmes familles posent la même question.
	for i in range(LEVELS.size()):
		for j in range(i + 1, LEVELS.size()):
			var a: Array = (_families[LEVELS[i]] as Dictionary).keys()
			var b: Array = (_families[LEVELS[j]] as Dictionary).keys()
			a.sort()
			b.sort()
			assert_ne(str(a), str(b),
				"%s et %s se gagnent par les mêmes familles %s : même question posée deux fois" % [
					LEVELS[i], LEVELS[j], str(a)])

# --- S3 : non-transposabilité ----------------------------------------------

func _multiplicity() -> Dictionary:
	var count := {}
	for level_id in LEVELS:
		for key in _winners[level_id]:
			count[key] = int(count.get(key, 0)) + 1
	return count

func test_no_stack_solves_the_whole_chapter() -> void:
	# QN-02, le plancher opposable.
	for key in _multiplicity():
		assert_lt(int(_multiplicity()[key]), LEVELS.size(),
			"la pile %s résout TOUT le chapitre (QN-02)" % key)

## S3 — CLIQUET, et pourquoi ce n'est pas encore la cible.
##
## **La cible (aucune pile au-delà de DEUX niveaux) est aujourd'hui hors
## d'atteinte, et c'est démontrable.** Cinq niveaux, trois familles, des
## ensembles de familles gagnantes deux à deux distincts (S2) : les cinq plus
## petits sous-ensembles non vides distincts ont pour tailles 1+1+1+2+2 = 7.
## La somme des multiplicités de familles vaut donc **au moins 7** — donc au
## moins une famille gagne **trois** niveaux. S2 et « toute famille ≤ 2 » sont
## incompatibles à cinq niveaux.
##
## L'issue n'est pas de renoncer à S3 mais de **découpler la pile de sa
## famille** : une famille peut gagner un niveau sans que sa pile d'UNE SEULE
## RÈGLE y gagne. Il faut pour cela que `[1]` seule échoue là où `[1,3]`
## réussit — c'est-à-dire des niveaux où R01 **s'abstient** (cul-de-sac, mur),
## laissant la parole au reste de la pile. C'est la voie identifiée pour la
## suite du chapitre, et l'exigence naturelle des chapitres à douze règles.
##
## En attendant, ce test est un **cliquet** : il fige le pire cas mesuré et
## refuse toute aggravation. Un objectif qu'on efface parce qu'il n'est pas
## atteint cesse d'être un objectif ; un objectif sans cliquet se dégrade en
## silence.
const S3_TARGET := 2
const S3_CURRENT_CEILING := 3

func test_no_stack_solves_more_than_the_measured_ceiling() -> void:
	var count := _multiplicity()
	var worst := 0
	var offenders := PackedStringArray()
	for key in count:
		worst = maxi(worst, int(count[key]))
		if int(count[key]) > S3_TARGET:
			var where := PackedStringArray()
			for level_id in LEVELS:
				if (_winners[level_id] as Array).has(key):
					where.append(level_id)
			offenders.append("%s → %s" % [key, ", ".join(where)])
	offenders.sort()
	assert_lte(worst, S3_CURRENT_CEILING,
		"AGGRAVATION de la transposabilité : une pile résout %d niveaux (plafond mesuré %d). %s" % [
			worst, S3_CURRENT_CEILING, " · ".join(offenders)])
	# Le jour où la cible est atteinte, ce test le dit et demande qu'on abaisse
	# le cliquet — sans quoi il protégerait un plafond devenu faux.
	assert_gt(worst, S3_TARGET,
		"S3 est ATTEINTE (plus aucune pile au-delà de %d niveaux) : abaisser S3_CURRENT_CEILING à %d" % [
			S3_TARGET, S3_TARGET])
