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
	#
	# À CONDITION QU'ILS PUISSENT POSER LA MÊME. La famille est un indicateur
	# GROSSIER : elle ne retient que la tête de pile. Comparer sur cette seule
	# base deux niveaux dont les ESPACES DE RÉPONSES diffèrent produit un faux
	# positif — c'est arrivé le 9 août 2026 entre ch1_02 (règles [R01, R02],
	# 2 rangs, 5 piles énumérées) et ch1_03 (trois règles, 3 rangs, 16 piles).
	# Les deux se gagnent par une pile menée par la Fuite, et l'indicateur en
	# concluait « même question ». Elle est fausse : ch1_03 demande de
	# départager R02 et R03, une question que ch1_03 est le SEUL à pouvoir
	# formuler et que ch1_02 ne peut pas même énoncer, R03 n'y étant pas offerte.
	#
	# Deux niveaux ne posent donc la même question que s'ils offrent le même
	# espace : mêmes règles disponibles, même nombre de rangs. `slots` se lit
	# par `LevelSpec` — invariants 11 et 16.
	for i in range(LEVELS.size()):
		for j in range(i + 1, LEVELS.size()):
			if _answer_space(LEVELS[i]) != _answer_space(LEVELS[j]):
				continue
			var a: Array = (_families[LEVELS[i]] as Dictionary).keys()
			var b: Array = (_families[LEVELS[j]] as Dictionary).keys()
			a.sort()
			b.sort()
			assert_ne(str(a), str(b),
				("%s et %s offrent le MÊME espace de réponses %s et se gagnent par "
				+ "les mêmes familles %s : même question posée deux fois") % [
					LEVELS[i], LEVELS[j], _answer_space(LEVELS[i]), str(a)])

## Signature de l'espace de réponses : ce que le joueur a le droit de composer.
## Deux niveaux qui ne la partagent pas ne sont pas comparables famille à famille.
func _answer_space(level_id: String) -> String:
	var data := LevelCatalog.load_level_data(level_id)
	var allowed: Array[int] = []
	for v in data.get("allowed_rules", []):
		allowed.append(int(v))
	allowed.sort()
	return "%s×%d" % [str(allowed), LevelSpec.open_slots(data)]

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
## CLIQUET ATTEINT — 9 août 2026, avec la refonte de N3. La voie décrite
## ci-dessus est exactement celle qui a été prise : N3 fait s'ABSTENIR R01
## dans une impasse, et `[1]` seule y perd. Le plafond mesuré rejoint la
## cible ; toute aggravation est désormais un défaut, plus une dette.
const S3_CURRENT_CEILING := S3_TARGET

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
	# La cible étant atteinte, le cliquet se referme des DEUX côtés : un pire
	# cas inférieur à la cible signifierait que la cible elle-même est trop
	# lâche, et qu'on protège un plafond devenu faux dans l'autre sens.
	assert_eq(worst, S3_TARGET,
		("S3 : le pire cas vaut %d pour une cible de %d. S'il est INFÉRIEUR, "
		+ "resserrer S3_TARGET ; le cliquet ne doit jamais protéger du vide.") % [
			worst, S3_TARGET])

# --- S4 : une seule règle ne gagne que le niveau qui l'introduit -----------
#
# Règle posée par le concepteur, et c'est la plus exigeante du lot : **une
# pile d'UNE SEULE RÈGLE ne peut gagner que le niveau qui introduit cette
# règle.** Partout ailleurs, il faut au moins deux règles — donc un ORDRE,
# donc la règle d'or du jeu.
#
# Sans elle, un chapitre peut se traverser sans jamais rien ordonner : c'est
# exactement ce qui se passait, `[Lumière]` seule résolvant trois niveaux sur
# cinq. Le niveau d'introduction est l'exception nécessaire — il faut bien un
# endroit où l'on découvre ce que la règle fait, seule.

## Premier niveau du chapitre où la règle apparaît dans `allowed_rules`.
func _introduction_level(rule_id: int) -> String:
	for level_id in LEVELS:
		var data := LevelCatalog.load_level_data(level_id)
		for v in data.get("allowed_rules", []):
			if int(v) == rule_id:
				return level_id
	return ""

func _single_rule_winners() -> Array:
	var out: Array = []
	for level_id in LEVELS:
		for key in _winners[level_id]:
			var stack: Variant = JSON.parse_string(String(key))
			if stack is Array and (stack as Array).size() == 1:
				out.append([level_id, int((stack as Array)[0])])
	return out

## Violations connues, nommément. **La liste est VIDE depuis le 9 août 2026**
## et le test est donc inconditionnel : plus aucune pile d'une seule règle ne
## gagne un niveau autre que celui qui l'introduit.
##
## Ce qui a fermé le dernier manquement — `ch1_03:1`, la Lumière seule — mérite
## d'être retenu, parce que ce n'était pas un réglage : il a fallu une IMPASSE,
## seul dispositif où R01 s'abstient, et donc où une deuxième règle devient
## nécessaire au lieu d'être utile. Rien de moins n'y suffisait.
const S4_KNOWN_BREACHES: Array[String] = []

func test_a_single_rule_only_wins_the_level_that_introduces_it() -> void:
	var breaches := PackedStringArray()
	for pair in _single_rule_winners():
		var level_id: String = pair[0]
		var rule_id: int = pair[1]
		if _introduction_level(rule_id) == level_id:
			continue   # l'exception nécessaire : on y découvre la règle
		breaches.append("%s:%d" % [level_id, rule_id])
	breaches.sort()

	var expected := PackedStringArray(S4_KNOWN_BREACHES)
	expected.sort()
	assert_eq(breaches, expected,
		("S4 — une seule règle ne gagne que le niveau qui l'introduit. "
		+ "Écart par rapport aux manquements connus : constaté %s, connu %s.") % [
			str(breaches), str(expected)])

func test_the_known_breaches_are_still_real() -> void:
	# Un manquement qu'on a réparé sans mettre à jour la liste laisserait le
	# test protéger une exception qui n'existe plus — et la prochaine
	# régression passerait inaperçue.
	var actual := PackedStringArray()
	for pair in _single_rule_winners():
		if _introduction_level(pair[1]) != pair[0]:
			actual.append("%s:%d" % [pair[0], pair[1]])

	# LA LISTE VIDE DOIT S'AFFIRMER, pas se taire. Tant qu'elle contenait une
	# entrée, la boucle ci-dessous assertait ; le jour où S4 s'est fermée, elle
	# n'a plus rien asserté du tout et GUT a signalé le test « risky ». Un test
	# qui ne prouve rien tout en ressemblant à un test : c'est la SIXIÈME forme
	# du piège de l'invariant 12, après « paraître correct », « paraître cassé »,
	# « un zéro se vérifie comme un chiffre inattendu », « une note ne protège
	# de rien » et « un test dont l'objet n'est pas versionné ».
	#
	# Et elle est plus sournoise que les cinq autres, parce qu'elle n'apparaît
	# qu'au moment où l'objectif est ATTEINT — exactement quand on relit le
	# moins attentivement.
	if S4_KNOWN_BREACHES.is_empty():
		assert_eq(actual, PackedStringArray(),
			("S4 n'a plus de manquement connu : ce test doit constater qu'il n'y "
			+ "en a effectivement aucun. Constaté : %s") % str(actual))
		return
	for known in S4_KNOWN_BREACHES:
		assert_true(actual.has(String(known)),
			"%s n'est plus un manquement : retirer l'entrée de S4_KNOWN_BREACHES" % known)
