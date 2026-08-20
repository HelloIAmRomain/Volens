extends GutTest
## CE QUE FAIT UNE CASE N'EST PAS UNE DÉCOUVERTE, C'EST UN FAIT.
##
## POURQUOI CE FICHIER EXISTE. Volens n'a pas de tutoriel, et c'est délibéré : on
## demande au joueur de découvrir ce qu'une PILE produit. Mais rien à l'écran ne
## distingue une plaque à pression d'une bascule — deux marques colorées dont
## l'une tient tant qu'on l'occupe et l'autre s'enclenche définitivement. Le
## joueur l'apprenait en perdant, et concluait que le jeu était capricieux.
##
## LA LIGNE DE PARTAGE, et c'est elle que ces tests protègent : on dit ce que la
## case FAIT, jamais ce qu'il faut en faire. Une légende qui conseillerait
## jouerait à la place du joueur, ce qui est exactement le reproche fait aux
## tutoriels.
##
## ET LA MIGRATION DE SAUVEGARDE EST TESTÉE ICI AUSSI, parce que c'est elle qui
## coûterait le plus cher : ajouter une commodité d'affichage ne doit effacer la
## progression de personne.

func test_the_catalogue_never_tells_the_player_what_to_do() -> void:
	# UNE LÉGENDE DÉCRIT, ELLE NE CONSEILLE PAS. Les tournures d'instruction sont
	# refusées : « postez deux agents dessus » retirerait au joueur le travail
	# qu'on lui demande, et une seule phrase suffit à faire basculer la légende
	# en tutoriel.
	var bossy := PackedStringArray()
	for key in MechanicPrimer.ENTRIES:
		var line := String((MechanicPrimer.ENTRIES[key] as Dictionary)["line"])
		for verb in ["posez", "placez", "mettez", "utilisez", "il faut", "vous devez"]:
			if line.to_lower().contains(verb):
				bossy.append("%s : « %s »" % [key, line])
	assert_eq(bossy, PackedStringArray(),
		"légendes qui conseillent au lieu de décrire : %s" % ", ".join(bossy))

func test_every_entry_has_a_name_and_a_single_line() -> void:
	assert_gt(MechanicPrimer.ENTRIES.size(), 0, "le catalogue ne doit pas être vide")
	var faulty := PackedStringArray()
	for key in MechanicPrimer.ENTRIES:
		var e: Dictionary = MechanicPrimer.ENTRIES[key]
		if String(e.get("name", "")).is_empty() or String(e.get("line", "")).is_empty():
			faulty.append(str(key))
		elif String(e["line"]).contains("\n"):
			faulty.append("%s (plusieurs lignes)" % key)
	assert_eq(faulty, PackedStringArray(), "entrées incomplètes : %s" % ", ".join(faulty))

func test_a_level_without_novelty_shows_nothing() -> void:
	# LE SILENCE EST LE CAS NORMAL. Une carte qui s'ouvrirait à chaque niveau
	# deviendrait un geste à faire avant le premier geste utile — le défaut
	# qu'EF-21 nomme, et la raison pour laquelle la reprise n'affiche aucun
	# panneau.
	var data := LevelCatalog.load_level_data("ch1_01")
	var all_keys := PackedStringArray()
	for entry in MechanicPrimer.present_in(data):
		all_keys.append(String((entry as Dictionary)["key"]))
	assert_gt(all_keys.size(), 0, "ch1_01 doit porter au moins la lumière")
	assert_eq(MechanicPrimer.unseen_in(data, all_keys), [],
		"tout est déjà vu : aucune légende ne doit s'afficher")

func test_at_most_two_cards_at_once() -> void:
	# TROIS LÉGENDES D'AFFILÉE SE REFERMENT SANS ÊTRE LUES, et l'on aurait
	# dépensé la seule occasion de les montrer. Le plafond est vérifié sur le
	# niveau le plus chargé du catalogue, pas sur un cas choisi.
	var worst := 0
	var worst_id := ""
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var data := LevelCatalog.load_level_data(String(entry["id"]))
		var n: int = MechanicPrimer.unseen_in(data, PackedStringArray()).size()
		if n > worst:
			worst = n
			worst_id = String(entry["id"])
	assert_between(worst, 1, 2,
		"le plus chargé (%s) propose %d légendes d'un coup" % [worst_id, worst])

func test_the_one_way_passage_is_found_where_it_actually_lives() -> void:
	# LE PIÈGE QUI A DÉJÀ FAIT UNE VICTIME. Le sens unique n'est PAS une valeur
	# de case : il vit dans `grid.one_way`, une liste à part. Un inventaire qui
	# n'interroge que `grid.cells` le déclare absent — c'est ce qui a failli le
	# faire supprimer comme « mécanique morte » lors de l'audit du vocabulaire.
	var data := LevelCatalog.load_level_data("ch4_02")
	assert_gt((data["grid"]["one_way"] as Array).size(), 0,
		"ch4_02 doit porter des sens uniques, sinon ce test est creux")
	var keys := PackedStringArray()
	for entry in MechanicPrimer.present_in(data):
		keys.append(String((entry as Dictionary)["key"]))
	assert_true(keys.has("sens_unique"),
		"le sens unique doit être trouvé alors qu'il n'est pas une valeur de case")

## --- La migration de sauvegarde ----------------------------------------------

func test_the_progress_schema_advanced_with_the_new_field() -> void:
	assert_eq(Progress.SCHEMA_VERSION, 3,
		"le champ `seen` est nouveau : le schéma doit avoir été incrémenté")

func test_a_schema_two_save_keeps_everything_it_had() -> void:
	# LE POINT QUI COÛTERAIT LE PLUS CHER. Ajouter une commodité d'affichage ne
	# doit effacer la progression de personne.
	var old := {"schema_version": 2,
		"solved": {"ch1_01": {"ticks": 12, "lost": 0}},
		"earned": {"ch1_01": ["Économie — 1 règle au plus"]}}
	var out := SaveStore.migrate_for_test(old, 2, 3)
	assert_eq(int(out.get("schema_version", 0)), 3, "la version doit avancer")
	assert_true((out.get("solved", {}) as Dictionary).has("ch1_01"),
		"les niveaux résolus doivent survivre")
	assert_true((out.get("earned", {}) as Dictionary).has("ch1_01"),
		"les défis obtenus doivent survivre")
	assert_eq((out.get("seen", []) as Array).size(), 0,
		"le nouveau champ naît vide")

func test_migrations_chain_across_more_than_one_version() -> void:
	# L'OUBLI SERAIT SILENCIEUX : un joueur resté en schéma 1 n'aurait trouvé
	# aucune règle « 1 -> 3 » et serait tombé dans le repli propre — tout perdu
	# au moment précis où l'on ajoute une commodité d'affichage.
	var ancient := {"schema_version": 1, "solved": {"ch1_02": {"ticks": 30, "lost": 1}}}
	var out := SaveStore.migrate_for_test(ancient, 1, 3)
	assert_eq(int(out.get("schema_version", 0)), 3, "1 -> 3 doit aboutir")
	assert_true((out.get("solved", {}) as Dictionary).has("ch1_02"),
		"une progression de schéma 1 doit traverser DEUX migrations intacte")

## --- Un chapitre déjà joué ne se dit pas verrouillé ---------------------------
##
## POURQUOI C'EST ICI. Le défaut vient de la même famille que les légendes : ce
## que l'écran RACONTE au joueur, et la contradiction qu'il y laisse passer.
##
## Constaté sur l'appareil après l'insertion de ch2_06 au milieu du catalogue.
## Le verrou étant en chaîne — chaque niveau demande le précédent — ajouter un
## niveau avant le chapitre 3 a reverrouillé son premier niveau pour une
## progression existante, et l'écran affichait « Chapitre 3 — verrouillé »
## au-dessus de trois niveaux marqués RÉSOLUS. Le joueur ne lit pas cela comme
## une conséquence de mise à jour : il se demande s'il a perdu sa progression.

func test_a_chapter_with_solved_levels_is_never_reported_locked() -> void:
	var progress := Progress.new()
	# On résout un niveau du chapitre 3 SANS rien du chapitre 2 : c'est
	# exactement l'état qu'une insertion en amont fabrique.
	var target := ""
	for i in range(LevelCatalog.count()):
		var id := String(LevelCatalog.entry(i)["id"])
		if LevelCatalog.chapter_of(id) == 3:
			target = id
			break
	assert_ne(target, "", "le chapitre 3 doit exister, sinon ce test est creux")
	progress.solved[target] = {"ticks": 20, "lost": 0}
	assert_true(LevelCatalog.is_chapter_unlocked(3, progress),
		("un chapitre dont un niveau est résolu ne peut pas s'annoncer verrouillé : "
		+ "l'écran se contredirait sous les yeux du joueur"))

func test_an_untouched_chapter_stays_locked() -> void:
	# L'AUTRE BORD, sans lequel le correctif ouvrirait tout le jeu : un chapitre
	# où l'on n'a jamais rien résolu reste verrouillé.
	var progress := Progress.new()
	assert_false(LevelCatalog.is_chapter_unlocked(6, progress),
		"une progression vierge ne doit pas déverrouiller le dernier chapitre")
