extends GutTest
## UN DÉFI DÉCLARÉ EST-IL UN VRAI DÉFI ?
##
## POURQUOI CE FICHIER EXISTE. Signalé à l'essai : « niveau 1.3, défi 3 règles
## inutile car on a 3 règles au max » et « défi bête : absence de vers la
## lumière alors qu'il n'y a pas de lumière ». Les deux étaient vrais, et la
## mesure du 15 août 2026 a montré qu'ils n'étaient pas isolés :
##
##   · le seuil d'économie valait « trois emplacements » pour TOUS les niveaux,
##     alors que vingt-huit sur vingt-neuf n'en ouvrent que trois : le défi
##     tombait avec la victoire, sur presque tout le jeu ;
##   · **treize des dix-huit défis d'abstinence** portaient sur une règle dont
##     AUCUNE pile gagnante ne dépendait — s'en passer ne demandait rien.
##
## LE CRITÈRE, ET IL VAUT POUR LES TROIS : un défi n'en est un que s'il existe
## une pile gagnante qui l'obtient ET une pile gagnante qui ne l'obtient pas.
## S'aucune ne l'obtient il est impossible ; si toutes l'obtiennent il est
## offert. Dans les deux cas le joueur n'apprend rien et n'a aucune raison de
## revenir — or c'est la seule chose qu'un défi doit produire.
##
## Ces tests sont volontairement DÉCLARATIFS : ils ne recalculent pas l'espace
## des solutions (`tools/design/challenges.gd` le fait, et c'est coûteux), ils
## vérifient les propriétés qu'aucun oubli ne doit pouvoir rétablir.

func _ready_levels() -> Array[String]:
	var out: Array[String] = []
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if bool(entry["ready"]):
			out.append(String(entry["id"]))
	return out

func test_no_economy_threshold_reaches_the_number_of_ranks() -> void:
	# UN SEUIL ÉGAL AU NOMBRE DE RANGS EST ACQUIS D'OFFICE : on ne peut pas
	# poser plus de règles qu'il n'y a de rangs. C'est exactement le défaut
	# d'origine, et il ne tenait qu'à une constante.
	var offenders := PackedStringArray()
	var examined := 0
	for level_id in _ready_levels():
		var data := LevelCatalog.load_level_data(level_id)
		var cap := int(LevelSpec.challenges(data).get("economy_max", 0))
		if cap <= 0:
			continue
		examined += 1
		if cap >= LevelSpec.open_slots(data):
			offenders.append("%s (seuil %d, %d rangs)" % [
				level_id, cap, LevelSpec.open_slots(data)])
	assert_gt(examined, 0, "aucun seuil d'économie déclaré : le balayage est cassé")
	assert_eq(offenders, PackedStringArray(),
		("Ces seuils d'économie sont acquis d'office : on ne peut pas poser plus "
		+ "de règles qu'il n'y a de rangs. %s") % ", ".join(offenders))

func test_every_abstinence_rule_is_in_the_level_library() -> void:
	# Un défi d'abstinence sur une règle que le niveau n'offre pas est gagné
	# sans rien faire. Le convertisseur le refuse déjà ; ce test garde le
	# catalogue converti, que personne ne relit.
	var offenders := PackedStringArray()
	for level_id in _ready_levels():
		var data := LevelCatalog.load_level_data(level_id)
		var rule := int(LevelSpec.challenges(data).get("abstinence_rule", 0))
		if rule == 0:
			continue
		var allowed: Array = data.get("allowed_rules", [])
		var found := false
		for v in allowed:
			if int(v) == rule:
				found = true
		if not found:
			offenders.append("%s → R%02d" % [level_id, rule])
	assert_eq(offenders, PackedStringArray(),
		"abstinence sur une règle absente de la bibliothèque : %s" % ", ".join(offenders))

func test_a_level_without_challenges_declares_none() -> void:
	# ZÉRO EST UNE RÉPONSE LÉGITIME, et c'est celle de plusieurs niveaux : leurs
	# gagnantes ont toutes la même taille et la même durée, et aucune règle n'y
	# porte. L'interface doit alors n'afficher AUCUNE pastille — trois pastilles
	# éteintes qu'on ne peut pas allumer sont une fausse piste, et la répéter à
	# chaque niveau en fait une leçon d'impuissance.
	var without := 0
	var with_some := 0
	for level_id in _ready_levels():
		var spec := LevelSpec.challenges(LevelCatalog.load_level_data(level_id))
		if Challenges.offered(spec) == 0:
			without += 1
		else:
			with_some += 1
	assert_gt(with_some, 0, "aucun niveau ne propose de défi : le balayage est cassé")
	assert_gt(without, 0,
		("Tous les niveaux proposent un défi : c'est suspect. La mesure du "
		+ "15 août 2026 en donnait neuf sans aucun défi possible, et forcer un "
		+ "défi là où il n'y en a pas est exactement ce qui les rendait vides."))

func test_the_summary_and_the_record_agree() -> void:
	# DEUX CALCULS SÉPARÉS DIVERGENT TOUJOURS. L'écran de bilan montre l'état de
	# chaque défi ; la progression enregistre ceux qui sont obtenus. Si les deux
	# se calculaient à part, le joueur verrait un défi qui ne se conserve pas —
	# ou l'inverse, plus insidieux encore.
	var stack: Array = [RuleRegistry.R03_STAY_GROUPED, RuleRegistry.R01_TOWARD_LIGHT]
	var states := SummaryScreen.challenge_states("ch1_05", stack, 20)
	var earned := SummaryScreen.challenges_earned("ch1_05", stack, 20)
	var expected := 0
	for entry in states:
		if bool(entry["earned"]):
			expected += 1
	assert_gt(states.size(), 0, "ch1_05 doit proposer des défis")
	assert_eq(earned.size(), expected,
		"le nombre de défis enregistrés doit égaler celui des défis marqués obtenus")
	for line in earned:
		var matched := false
		for entry in states:
			if line.begins_with(String(entry["key"])):
				matched = true
		assert_true(matched,
			("Le libellé enregistré « %s » ne commence par aucun nom de défi. La "
			+ "liste des niveaux les reconnaît par ce préfixe : tous les défis "
			+ "déjà obtenus deviendraient invisibles.") % line)
