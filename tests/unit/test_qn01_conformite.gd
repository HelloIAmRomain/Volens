extends GutTest
## LES VERDICTS DE QN-01 QUI SONT OPPOSABLES, et eux seuls.
##
## CE TEST A FAILLI ÊTRE ÉCRIT À L'ENVERS. Un audit du 15 août 2026 a d'abord
## conclu que quatorze niveaux étaient « sous le seuil QN-01 » — trois classes
## structurelles minimum. C'était faux à deux titres, et les deux méritent
## d'être écrits ici parce qu'ils se reproduiront :
##
## 1. **La classe structurelle n'est pas la règle de tête.** Le validateur
##    regroupe les piles gagnantes par ÉTAT FINAL (`equivalence_key`) : deux
##    piles sont la même solution si la nuée finit pareil. Mesurer autre chose
##    et l'appeler du même nom, c'est inventer un critère et l'attribuer au CDC.
##
## 2. **Le seuil de trois classes ne s'applique pas ici.** Le CDC §12.2.1 est
##    explicite : les bornes 3-40 « présupposent la bibliothèque complète », et
##    pour un chapitre à bibliothèque restreinte l'outil rapporte les chiffres
##    « sans rendre de verdict QN-01 ». La bande 20-50 % y est dite
##    « indicative » et « non opposable ».
##
## **Un critère qu'on durcit soi-même n'est plus le critère du CDC.** Ce test ne
## tient donc que ce que le CDC rend opposable — et le tient sur tout le
## catalogue.

var _winners: Dictionary = {}

func before_all() -> void:
	_winners = CatalogueSolutions.winners()

# --- garde-fou universel ---------------------------------------------------

func test_no_level_is_won_by_the_empty_stack() -> void:
	# « Un niveau où la pile vide gagne est dégénéré : rejet, quel que soit son
	# type » (§12.2.1). C'est le seul verdict que rien n'exempte.
	var degenerate := PackedStringArray()
	for level_id in _winners:
		if (_winners[level_id] as Array).has("[]"):
			degenerate.append(String(level_id))
	assert_eq(degenerate, PackedStringArray(),
		"niveaux gagnés sans poser une seule règle : %s" % ", ".join(degenerate))

# --- « une seule pile gagnante → puzzle déguisé » --------------------------

func test_no_open_level_has_a_single_solution() -> void:
	# Verdict associé de §12.2.1, opposable et universel SAUF pour les niveaux
	# tutoriels, qui portent un critère propre (test suivant). Un niveau ouvert
	# à réponse unique n'offre pas un choix, il offre une devinette.
	var single := PackedStringArray()
	for level_id in _winners:
		var data := LevelCatalog.load_level_data(String(level_id))
		if LevelSpec.is_tutorial(data):
			continue
		if (_winners[level_id] as Array).size() == 1:
			single.append(String(level_id))
	single.sort()
	assert_eq(single, PackedStringArray(),
		("« Une seule pile gagnante → puzzle déguisé, rejeté ou retravaillé » "
		+ "(CDC §12.2.1). Niveaux ouverts à réponse unique : %s") % ", ".join(single))

func test_no_level_is_hollow() -> void:
	# « Plus de 100 → niveau creux, contraintes à durcir. » Le catalogue en est
	# loin, mais le verdict est opposable et le contrôle coûte trois lignes.
	var hollow := PackedStringArray()
	for level_id in _winners:
		if (_winners[level_id] as Array).size() > 100:
			hollow.append(String(level_id))
	assert_eq(hollow, PackedStringArray(),
		"niveaux creux (plus de 100 solutions) : %s" % ", ".join(hollow))

# --- critère propre des niveaux tutoriels ----------------------------------

func test_every_tutorial_wins_exactly_what_its_sheet_announces() -> void:
	# « `N_win` doit valoir EXACTEMENT `expected_wins`, ni plus ni moins — une
	# leçon qui admet une solution imprévue n'enseigne plus ce qu'elle prétend
	# enseigner. » C'est le prix de l'exemption de QN-01 : la prédiction doit
	# être juste au niveau près.
	var offenders := PackedStringArray()
	var checked := 0
	for level_id in _winners:
		var data := LevelCatalog.load_level_data(String(level_id))
		if not LevelSpec.is_tutorial(data):
			continue
		checked += 1
		var announced := LevelSpec.expected_wins(data)
		var measured: int = (_winners[level_id] as Array).size()
		if announced != measured:
			offenders.append("%s : annoncé %d, mesuré %d" % [level_id, announced, measured])
	offenders.sort()
	assert_eq(offenders, PackedStringArray(),
		"tutoriels dont la prédiction est fausse : %s" % ", ".join(offenders))
	assert_gt(checked, 0, "aucun tutoriel examiné : le filtre a tout écarté")

# --- ce que le catalogue promet, tenu ---------------------------------------

func test_every_level_announces_a_measured_number_of_solutions() -> void:
	# Tutoriel ou non, un niveau qui déclare `expected_wins` doit dire vrai.
	# Le validateur le vérifie à la conversion ; ce test le vérifie sur le
	# catalogue livré, qui est ce que le joueur reçoit.
	var wrong := PackedStringArray()
	var checked := 0
	for level_id in _winners:
		var data := LevelCatalog.load_level_data(String(level_id))
		var announced := LevelSpec.expected_wins(data)
		if announced < 0:
			continue
		checked += 1
		var measured: int = (_winners[level_id] as Array).size()
		if announced != measured:
			wrong.append("%s : %d ≠ %d" % [level_id, announced, measured])
	wrong.sort()
	assert_eq(wrong, PackedStringArray(),
		"niveaux dont `expected_wins` ment : %s" % ", ".join(wrong))
	assert_gt(checked, 0, "aucun niveau ne déclare `expected_wins` : le balayage est cassé")
