extends GutTest
## ARC QN-02 DU CHAPITRE 1 — la propriété qui fait du chapitre autre chose
## qu'une suite de niveaux.
##
## Trois familles de piles, définies par la règle placée en tête :
##   A — R01 en tête : la vitesse. Va droit, ne regarde rien.
##   B — R02 en tête : la prudence. Contourne, même ce qui ne menace pas.
##   C — R03 en tête : la cohésion. Ramène les traînards, sans regarder où.
##
## **Chaque famille gagne exactement deux niveaux sur trois, et aucune pile ne
## les résout tous les trois.** C'est ce qui interdit au joueur de trouver une
## pile universelle et de traverser le chapitre sans jamais rien réordonner —
## la règle d'or resterait alors une mécanique sans conséquence.
##
## Ce test ne relit aucune prédiction écrite : il **simule** les trois niveaux,
## collecte les piles gagnantes, et vérifie la propriété sur les ensembles
## obtenus. Une retouche de grille qui casserait l'arc le dirait ici, pas six
## semaines plus tard sur un téléphone.

const LEVELS := ["ch1_03", "ch1_04", "ch1_05"]

## Représentant de chaque famille : la pile la plus courte qui l'exprime.
const FAMILY_A := [RuleRegistry.R01_TOWARD_LIGHT]
const FAMILY_B := [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]
const FAMILY_C := [RuleRegistry.R03_STAY_GROUPED, RuleRegistry.R01_TOWARD_LIGHT]

var _winners: Dictionary = {}   # level_id -> { clé de pile -> true }

func before_all() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	var params := RuleParams.from_dict(rules if rules is Dictionary else {})
	for level_id in LEVELS:
		var data := LevelCatalog.load_level_data(level_id)
		assert_false(data.is_empty(), "%s introuvable" % level_id)
		if data.is_empty():
			continue
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		var won := {}
		for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
			var stack: Array[int] = []
			for v in stack_variant:
				stack.append(int(v))
			if _simulate(data, params, stack) == SimState.Outcome.WON:
				won[str(stack)] = true
		_winners[level_id] = won

func _simulate(data: Dictionary, params: RuleParams, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < 400:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome

func _wins(level_id: String, stack: Array) -> bool:
	var typed: Array[int] = []
	for v in stack:
		typed.append(int(v))
	return (_winners.get(level_id, {}) as Dictionary).has(str(typed))

# --- l'arc, famille par famille -------------------------------------------

func test_the_direct_family_wins_only_the_third_level() -> void:
	# La vitesse paie tant que rien ne se met en travers. Elle bute sur
	# l'impasse de N4 — R01 s'y tait, et seule une règle placée AVANT elle en
	# sort — et elle saigne en N5, où un traînard suit sa route dans le feu.
	assert_true(_wins("ch1_03", FAMILY_A), "A doit gagner N3")
	assert_false(_wins("ch1_04", FAMILY_A), "A doit PERDRE N4 (impasse)")
	assert_false(_wins("ch1_05", FAMILY_A), "A doit PERDRE N5")

func test_the_prudent_family_pays_in_time() -> void:
	# La prudence ne perd jamais d'agent — elle perd des ticks, et N4 les compte.
	assert_true(_wins("ch1_03", FAMILY_B), "B doit gagner N3")
	assert_false(_wins("ch1_04", FAMILY_B), "B doit PERDRE N4 (échéance)")
	assert_true(_wins("ch1_05", FAMILY_B), "B doit gagner N5")

func test_the_cohesive_family_is_blind_before_it_is_useful() -> void:
	# Même règle, même portée : en N3 elle tire le traînard DANS le danger,
	# en N5 elle l'en écarte. Seule la géométrie a changé.
	assert_false(_wins("ch1_03", FAMILY_C), "C doit PERDRE N3")
	assert_true(_wins("ch1_04", FAMILY_C), "C doit gagner N4")
	assert_true(_wins("ch1_05", FAMILY_C), "C doit gagner N5")

# --- QN-02 : la propriété de chapitre --------------------------------------

func test_no_stack_solves_all_three_levels() -> void:
	var universal: Array[String] = []
	for key in _winners["ch1_03"]:
		if (_winners["ch1_04"] as Dictionary).has(key) and (_winners["ch1_05"] as Dictionary).has(key):
			universal.append(String(key))
	assert_eq(universal, [] as Array[String],
		"QN-02 rompu : ces piles résolvent les trois niveaux, le joueur peut traverser le chapitre sans jamais réordonner")

func test_every_level_is_winnable_and_none_is_a_formality() -> void:
	# Un niveau que tout résout n'enseigne rien ; un niveau que rien ne résout
	# est un défaut de conception (CDC §12.2 : zéro pile gagnante -> rejeté).
	for level_id in LEVELS:
		var won: Dictionary = _winners[level_id]
		var data := LevelCatalog.load_level_data(level_id)
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		var total: int = StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)).size()
		assert_gt(won.size(), 0, "%s : aucune pile gagnante" % level_id)
		assert_lt(won.size(), total, "%s : toutes les piles gagnent, le niveau ne départage rien" % level_id)

func test_the_declared_predictions_match_the_simulation() -> void:
	# `expected_wins` est écrit dans le fichier de niveau et sert de contrat
	# entre la fiche de conception et le moteur. S'il dérive, la fiche ment.
	#
	# La valeur attendue est lue DANS LE NIVEAU, jamais recopiée ici : une
	# table en dur dans le test devient une troisième vérité, qu'il faut
	# penser à mettre à jour — et qui a effectivement dérivé lors de la
	# refonte de ch1_04.
	for level_id in LEVELS:
		var data := LevelCatalog.load_level_data(level_id)
		var declared: int = int(data.get("expected_wins", -1))
		assert_gt(declared, 0, "%s : aucun expected_wins déclaré" % level_id)
		assert_eq((_winners[level_id] as Dictionary).size(), declared,
			"%s : piles gagnantes mesurées vs déclarées" % level_id)
