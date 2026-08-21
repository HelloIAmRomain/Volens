extends GutTest
## EQ-04 — « une règle que l'espace des solutions ignore est une règle morte,
## à retravailler ou retirer » (CDC §12.3).
##
## CE QUE CE TEST MESURE, et pourquoi il ne peut pas se relire : une règle peut
## être implémentée, testée unitairement, documentée, et n'apparaître dans
## AUCUNE pile gagnante du jeu. Elle est alors du code mort déguisé en contenu,
## et rien ne le dit — sauf en simulant tout le catalogue.
##
## Le seuil du CDC est de trois niveaux ⚙️. Ce test le tient comme CIBLE et
## fige l'écart mesuré comme cliquet : la liste des manquements ne peut que
## décroître, et chacun y est nommé avec sa cause.

const TARGET_LEVELS := 3

## MANQUEMENTS CONNUS, nommément, avec leur cause. Une règle qui n'y figure pas
## et qui tombe sous la cible fait échouer ce test.
##
## **R10 « Rebrousser si seul » est MORTE, et c'est une propriété de la règle,
## pas un oubli de contenu.** Elle ne fait qu'UN demi-tour, et se déplacer met à
## jour le cap de l'agent : si ce demi-tour ne suffit pas à retrouver un
## congénère, l'agent repart en sens inverse au tick suivant et fait la navette
## indéfiniment. Elle ne retient donc que celui qui s'écarte d'un pas — une
## fenêtre trop étroite pour fonder un niveau, essayée en N21 puis retirée.
##
## Pour la rendre vivante il faudrait qu'elle se SOUVIENNE qu'elle rebrousse,
## c'est-à-dire de l'hystérésis : le remède que le dossier des genres nomme et
## qui reste gelé jusqu'aux testeurs. Le CDC autorise deux issues — retravailler
## ou retirer — et les deux demandent une décision du concepteur, pas un niveau
## de plus.
## R10 N'EST PLUS UN MANQUEMENT CONNU : elle a été RETIRÉE du jeu, avec R07,
## le 15 août 2026. La liste est vide, et c'est le but qu'EQ-04 poursuivait —
## non pas tolérer des règles mortes en les inscrivant, mais ne plus en avoir.
const KNOWN_DEAD: Array[String] = []

## Règles vivantes mais sous-employées : présentes dans une ou deux solutions
## seulement. Cliquet — la liste doit décroître à mesure que le catalogue
## grandit, jamais s'allonger.
## VIDE depuis le 15 août 2026 : quinze règles sur seize atteignent la cible.
## Trois niveaux ont été ajoutés pour cela — N24 sert R05 et R06, N25 sert R13
## et R15, N26 sert R15 et R16 — et aucun n'a été écrit POUR le compteur : la
## contrainte a servi de cahier des charges, pas de quota. Un niveau écrit pour
## remplir une case aurait été un mauvais niveau, et EQ-04 n'aurait rien gagné.
const KNOWN_UNDER_USED: Array[String] = []

var _alive: Dictionary = {}   # id de règle -> nombre de niveaux où elle gagne

## L'espace des solutions est calculé UNE FOIS pour toute la suite : le simuler
## ici en propre coûtait 78 secondes, exactement les mêmes que celles déjà
## dépensées par `test_catalogue_identity`.
func before_all() -> void:
	for id in RuleRegistry.ALL:
		_alive[id] = CatalogueSolutions.levels_won_with(id)

func test_no_rule_is_dead_beyond_the_ones_named() -> void:
	# UNE RÈGLE MORTE EST DU CODE MORT DÉGUISÉ EN CONTENU. Elle occupe une place
	# dans la bibliothèque, une tuile dans l'interface et une ligne au CDC, sans
	# jamais rien résoudre.
	var dead := PackedStringArray()
	for id in RuleRegistry.ALL:
		if int(_alive[id]) == 0:
			dead.append("R%02d" % id)
	dead.sort()
	var known := PackedStringArray(KNOWN_DEAD)
	known.sort()
	assert_eq(dead, known,
		("EQ-04 — règles n'apparaissant dans AUCUNE pile gagnante du jeu. "
		+ "Écart aux manquements connus : constaté %s, connu %s.") % [str(dead), str(known)])

func test_the_named_dead_rules_are_still_dead() -> void:
	# Un manquement réparé sans être retiré de la liste laisserait le cliquet
	# protéger une exception qui n'existe plus.
	if KNOWN_DEAD.is_empty():
		assert_eq(PackedStringArray(), PackedStringArray(),
			"plus aucune règle morte : le test devient inconditionnel")  # VIDE-ATTENDU:
		return
	for name in KNOWN_DEAD:
		var id := int(String(name).substr(1))
		assert_eq(int(_alive[id]), 0,
			"%s n'est plus morte : la retirer de KNOWN_DEAD" % name)

func test_under_used_rules_do_not_multiply() -> void:
	# Le cliquet porte sur la LISTE, pas sur un compte : une règle qui passe
	# sous la cible sans y figurer fait échouer, une qui la franchit doit en
	# être retirée. C'est ce qui empêche le catalogue de grandir en laissant
	# des règles derrière lui.
	var under := PackedStringArray()
	for id in RuleRegistry.ALL:
		var n := int(_alive[id])
		if n > 0 and n < TARGET_LEVELS:
			under.append("R%02d" % id)
	under.sort()
	var known := PackedStringArray(KNOWN_UNDER_USED)
	known.sort()
	assert_eq(under, known,
		("EQ-04 — règles vivantes mais présentes dans moins de %d niveaux. "
		+ "Écart : constaté %s, connu %s. Une règle qui franchit la cible doit "
		+ "être RETIRÉE de KNOWN_UNDER_USED, sans quoi le cliquet protège du vide.")
		% [TARGET_LEVELS, str(under), str(known)])

func test_the_library_is_measured_in_full() -> void:
	# Garde du balayage : si l'énumération se cassait, tout paraîtrait mort et
	# les deux tests ci-dessus deviendraient des tautologies.
	assert_eq(_alive.size(), 13,
		("les treize règles doivent être mesurées — quatorze jusqu'à la fusion de "
		+ "R12 « Déposer au but » dans R11 « Porter et déposer » (carnet, 206)"))
	var total := 0
	for id in _alive:
		total += int(_alive[id])
	assert_gt(total, 40, "trop peu de règles vivantes : le balayage est cassé")
