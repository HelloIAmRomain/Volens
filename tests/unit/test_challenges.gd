extends GutTest
## DÉFIS RG-18/RG-19, et la présentation des seize règles.
##
## CE QUI EST VÉRIFIÉ ICI, ET POURQUOI. Les défis sont la seule partie du jeu
## qui puisse récompenser sans conditionner. RG-19 est catégorique — « aucun
## défi ne conditionne jamais la progression » — et c'est une contrainte de
## code autant que de texte : un module qui saurait dire « raté » finirait par
## être branché quelque part.

var _params: RuleParams

func before_each() -> void:
	_params = RuleParams.new()

func _finished_at(tick: int) -> SimState:
	var s := SimState.new()
	s.tick = tick
	s.counters = Counters.new()
	s.rule_params = _params
	return s

# --- RG-19 : un défi ne peut pas être raté ---------------------------------

func test_evaluate_never_reports_a_failure_only_absences() -> void:
	# La seule forme que le module sait produire est « obtenu / pas encore ».
	# Il n'existe aucun chemin par lequel il dirait « raté », et c'est ce qui
	# rend RG-19 tenable dans le code plutôt que dans une note.
	var out := Challenges.evaluate([1, 2, 3, 4], _finished_at(99), {})
	for key in ["economy", "abstinence", "efficiency"]:
		assert_true(out.has(key), "clé %s absente" % key)
		assert_true(out[key] is bool, "un défi vaut vrai ou faux, jamais un score")
	assert_false(bool(out["economy"]), "quatre règles : l'économie n'est pas obtenue")

func test_a_level_that_offers_no_challenge_says_so() -> void:
	# Distinguer « pas obtenu » de « ce niveau ne le propose pas » : sans cette
	# distinction, l'interface afficherait un défi éteint que rien ne permet
	# d'allumer — la définition d'une fausse piste.
	var out := Challenges.evaluate([1], _finished_at(10), {})
	assert_false(bool(out["applicable_abstinence"]), "aucune règle désignée")
	assert_false(bool(out["applicable_efficiency"]), "aucun seuil mesuré")
	assert_false(bool(out["abstinence"]), "un défi non proposé n'est pas obtenu")

# --- économie ---------------------------------------------------------------

func test_economy_counts_rules_not_slots() -> void:
	# Un rang vide n'est pas une règle utilisée : le défi récompense la pile
	# COURTE, pas la pile tassée.
	assert_true(bool(Challenges.evaluate([1, 0, 2, 0], _finished_at(5), {})["economy"]),
		"deux règles et deux rangs vides : économie obtenue")
	assert_false(bool(Challenges.evaluate([1, 2, 3, 4], _finished_at(5), {})["economy"]),
		"quatre règles : au-delà du seuil du CDC")

func test_economy_ignores_a_rule_repeated_in_two_slots() -> void:
	# L'énumérateur interdit les doublons, mais une pile composée à la main
	# pourrait en porter. Compter deux fois la même règle ferait échouer un
	# défi que le joueur a en réalité obtenu.
	assert_true(bool(Challenges.evaluate([1, 1, 2, 2], _finished_at(5), {})["economy"]),
		"deux règles distinctes, quatre rangs : économie obtenue")

# --- abstinence -------------------------------------------------------------

func test_abstinence_is_earned_by_absence_and_lost_by_presence() -> void:
	var spec := {"abstinence_rule": RuleRegistry.R02_FLEE_DANGER}
	assert_true(bool(Challenges.evaluate([1, 3], _finished_at(5), spec)["abstinence"]),
		"R02 absente : obtenu")
	assert_false(bool(Challenges.evaluate([2, 1], _finished_at(5), spec)["abstinence"]),
		"R02 présente : pas encore obtenu")

# --- efficience -------------------------------------------------------------

func test_efficiency_tolerates_the_exact_threshold() -> void:
	# « Sur le fil » est réussi, comme pour l'échéance de célérité (ENF-04) : le
	# seuil est un maximum admis, pas un maximum interdit. La cohérence entre
	# les deux compte plus que le choix lui-même — deux conventions opposées
	# dans le même jeu seraient impossibles à retenir.
	var spec := {"efficiency_ticks": 20}
	assert_true(bool(Challenges.evaluate([1], _finished_at(20), spec)["efficiency"]),
		"exactement au seuil : obtenu")
	assert_false(bool(Challenges.evaluate([1], _finished_at(21), spec)["efficiency"]),
		"un tick au-dessus : pas obtenu")

# --- catalogue de présentation ---------------------------------------------

func test_every_registered_rule_has_a_name_a_glyph_and_a_sentence() -> void:
	# Une règle sans libellé s'afficherait « règle 14 » dans la pile du joueur.
	assert_eq(RuleRegistry.ALL.size(), 16, "la bibliothèque du CDC compte seize règles")
	for id in RuleRegistry.ALL:
		assert_ne(RuleCatalog.name_of(id), "règle %d" % id, "R%02d sans nom" % id)
		assert_ne(RuleCatalog.glyph_of(id), "?", "R%02d sans glyphe" % id)
		assert_gt(RuleCatalog.line_of(id).length(), 20, "R%02d sans phrase utile" % id)

func test_two_rules_never_share_a_glyph() -> void:
	# Les glyphes sont le seul repère sur une tuile de pile : deux règles
	# identiques à l'œil rendraient l'ordre illisible, qui est tout le jeu.
	var seen := PackedStringArray()
	for id in RuleRegistry.ALL:
		var g := RuleCatalog.glyph_of(id)
		assert_false(seen.has(g), "glyphe « %s » partagé par deux règles" % g)
		seen.append(g)
	assert_eq(seen.size(), 16, "seize glyphes attendus")

func test_a_joker_announces_what_it_neutralises() -> void:
	# « Ignorer » tout court ne dit pas quoi, et deux jokers de cibles
	# différentes seraient indiscernables dans la pile.
	var fire := RuleRegistry.make_joker(GridState.CellType.STATIC_DANGER)
	var doors := RuleRegistry.make_joker(GridState.CellType.PRESSURE_DOOR)
	assert_ne(RuleCatalog.name_of(fire), RuleCatalog.name_of(doors),
		"deux jokers de cibles différentes doivent se lire différemment")
	assert_true(RuleCatalog.name_of(fire).contains("feu"), "le joker doit nommer sa cible")
	assert_eq(RuleCatalog.glyph_of(fire), RuleCatalog.glyph_of(RuleRegistry.R16_IGNORE),
		"un joker garde le glyphe de R16")

# --- chapitres --------------------------------------------------------------

func test_the_chapter_is_deduced_from_the_identifier_never_declared_twice() -> void:
	assert_eq(LevelCatalog.chapter_of("ch3_02"), 3)
	assert_eq(LevelCatalog.chapter_of("ch1_01"), 1)
	assert_eq(LevelCatalog.chapter_of("inconnu"), 0, "repli propre sur un identifiant hors format")

func test_every_catalogued_chapter_has_a_title_and_at_least_one_level() -> void:
	var chapters := LevelCatalog.chapters()
	assert_gt(chapters.size(), 0, "aucun chapitre : le catalogue est vide ou mal formé")
	var progress := Progress.new()
	for c in chapters:
		assert_ne(LevelCatalog.chapter_title(c), "Chapitre %d" % c,
			"chapitre %d sans titre — il en faut un, le numéro ne dit rien" % c)
		assert_gt(LevelCatalog.chapter_progress(c, progress).y, 0,
			"chapitre %d annoncé sans niveau" % c)

func test_a_fresh_player_has_only_the_first_chapter_open() -> void:
	var progress := Progress.new()
	progress.solved = {}
	var chapters := LevelCatalog.chapters()
	assert_true(LevelCatalog.is_chapter_unlocked(chapters[0], progress),
		"le premier chapitre est toujours ouvert")
	assert_gt(chapters.size(), 1, "prémisse : il faut au moins deux chapitres pour tester le verrou")
	assert_false(LevelCatalog.is_chapter_unlocked(chapters[1], progress),
		"le second chapitre reste verrouillé tant que rien n'est résolu")
