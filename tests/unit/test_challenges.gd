extends GutTest

## LE CDC ANNONCE SEIZE RÈGLES ; LE JEU EN COMPTE TREIZE.
##
## R07 « Attendre » et R10 « Rebrousser si seul » ont été retirées le 15 août
## 2026 sur décision du concepteur, après mesure : une règle est utile si elle
## PORTE — si la retirer d'une pile gagnante fait perdre cette pile. R07 était
## offerte dans quatorze niveaux et ne portait dans aucun ; R10 n'était offerte
## nulle part. (carnet, décision 189).
##
## LA DIVERGENCE AU CDC EST CLOSE : le cahier des charges annonçait seize règles
## quand le jeu en offrait treize. Arbitrée par le concepteur le 21 août 2026 en
## faveur de la mesure — **CDC v2.6, RG-11 et §7.2 bis** portent désormais les
## trois retraits et leurs chiffres. Ce commentaire n'est plus un signalement,
## c'est un renvoi.
##
## R12 « Déposer au but » a été FUSIONNÉE dans R11 le 20 août 2026 : porter et
## déposer sont devenus « Porter et déposer ». La séparation n'était jamais
## décisive — mesurée sur les cinq niveaux qui les offraient, aucune pile
## gagnante ne demandait une règle INTERPOSÉE entre les deux (carnet, 206).
const RULE_COUNT_NOTE := "treize règles depuis le retrait de R07/R10 et la fusion R11+R12"
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
	var spec := {"economy_max": 3}
	assert_true(bool(Challenges.evaluate([1, 0, 2, 0], _finished_at(5), spec)["economy"]),
		"deux règles et deux rangs vides : économie obtenue")
	assert_false(bool(Challenges.evaluate([1, 2, 3, 4], _finished_at(5), spec)["economy"]),
		"quatre règles : au-delà du seuil du niveau")

func test_economy_is_not_offered_when_the_level_declares_no_threshold() -> void:
	# LE DÉFAUT LE PLUS RÉPANDU DU JEU, et il tenait à une constante : le seuil
	# valait « trois emplacements » pour tout le monde alors que vingt-huit
	# niveaux sur vingt-neuf n'ouvrent que trois rangs. Le défi tombait donc avec
	# la victoire, sans que le joueur sache qu'il existait.
	#
	# Sans seuil déclaré, il n'y a pas de défi — pas un défi acquis d'avance.
	var out := Challenges.evaluate([1], _finished_at(5), {})
	assert_false(bool(out["applicable_economy"]),
		"un niveau sans seuil mesuré ne propose pas l'économie")
	assert_false(bool(out["economy"]),
		"et un défi non proposé n'est jamais obtenu")

func test_offered_counts_only_what_the_level_declares() -> void:
	# L'interface affiche une pastille PAR DÉFI PROPOSÉ. Trois pastilles
	# partout, dont deux qu'aucune pile ne peut allumer, est une fausse piste
	# répétée vingt-neuf fois.
	assert_eq(Challenges.offered({}), 0, "aucun défi déclaré : aucune pastille")
	assert_eq(Challenges.offered({"economy_max": 2}), 1)
	assert_eq(Challenges.offered({
		"economy_max": 2, "abstinence_rule": 6, "efficiency_ticks": 29}), 3)

func test_economy_ignores_a_rule_repeated_in_two_slots() -> void:
	# L'énumérateur interdit les doublons, mais une pile composée à la main
	# pourrait en porter. Compter deux fois la même règle ferait échouer un
	# défi que le joueur a en réalité obtenu.
	assert_true(bool(Challenges.evaluate([1, 1, 2, 2], _finished_at(5),
		{"economy_max": 3})["economy"]),
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
	assert_eq(RuleRegistry.ALL.size(), 13, RULE_COUNT_NOTE)
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
	assert_eq(seen.size(), 13, "un glyphe par règle vivante — " + RULE_COUNT_NOTE)

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

# --- pourquoi la partie s'est arrêtée --------------------------------------
#
# LE MESSAGE D'ÉCHEC EST LA MOITIÉ DE L'APPRENTISSAGE, et c'est le pilier P4 :
# une partie perdue sans qu'on sache pourquoi n'enseigne rien. Deux objectifs
# n'en avaient aucun jusqu'au 14 août 2026 — `collect` et `interdiction` — et
# le joueur lisait à leur place « le temps imparti s'est écoulé », ce qui était
# faux : sur une interdiction, la partie s'arrête au troisième tick.
#
# **Un message faux vaut moins que pas de message.**

func _lost_state(agents: Array, delivered: int = 0) -> SimState:
	var s := SimState.new()
	s.outcome = SimState.Outcome.LOST
	s.tick = 3
	s.counters = Counters.new()
	s.counters.delivered = delivered
	var list: Array[AgentState] = []
	for p in agents:
		var a := AgentState.new()
		a.pos = p
		a.flags = AgentState.PRESENT
		list.append(a)
	s.agents = list
	return s

func test_an_interdiction_says_so_rather_than_blaming_the_clock() -> void:
	var objectives := [{"type": "interdiction", "cells": [[4, 4], [5, 4]]}]
	var breached := RuleCatalog.outcome_reason(objectives, _lost_state([Vector2i(5, 4)]))
	assert_true(breached.contains("interdite"),
		"une interdiction violée doit se nommer, pas se lire « le temps s'est écoulé » : « %s »" % breached)

func test_an_untouched_interdiction_does_not_claim_a_breach() -> void:
	# Le symétrique compte autant : accuser d'une faute qui n'a pas eu lieu
	# envoie le joueur corriger ce qui marchait.
	var objectives := [{"type": "interdiction", "cells": [[4, 4]]}]
	var clean := RuleCatalog.outcome_reason(objectives, _lost_state([Vector2i(0, 0)]))
	assert_false(clean.contains("interdite"), "aucun agent sur la zone : ne pas l'accuser")

func test_a_collection_failure_is_counted_never_vague() -> void:
	# « 1 sur 3 » situe l'écart ; « objectif non rempli » ne dit rien de ce
	# qu'il faut corriger.
	var objectives := [{"type": "collect", "count": 3}]
	var none := RuleCatalog.outcome_reason(objectives, _lost_state([Vector2i(0, 0)], 0))
	assert_true(none.contains("Aucune"), "zéro livraison doit se dire ainsi : « %s »" % none)
	var partial := RuleCatalog.outcome_reason(objectives, _lost_state([Vector2i(0, 0)], 1))
	assert_true(partial.contains("1") and partial.contains("3"),
		"une livraison partielle doit donner les deux chiffres : « %s »" % partial)

func test_every_objective_type_of_the_catalogue_has_a_failure_sentence() -> void:
	# CONTRÔLE GÉNÉRIQUE : chaque type d'objectif réellement employé par un
	# niveau doit produire une phrase qui lui est propre. Sans lui, le prochain
	# type ajouté retomberait en silence sur le message générique — c'est
	# exactement ce qui est arrivé deux fois.
	var seen := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var data := LevelCatalog.load_level_data(String(entry["id"]))
		for o in data.get("objectives", []):
			var kind := String((o as Dictionary).get("type", ""))
			if not seen.has(kind):
				seen.append(kind)
	assert_gt(seen.size(), 0, "aucun objectif au catalogue : le balayage est cassé")
	# CHAQUE SONDE VIOLE RÉELLEMENT SON OBJECTIF, et c'est la seule façon de
	# rendre ce contrôle honnête. Une sonde qui ne viole rien retombe forcément
	# sur le message générique — et ce message est alors JUSTE : une partie
	# perdue sans qu'aucun objectif ne soit enfreint l'a été sur le temps.
	# Première rédaction : elle accusait `extraction` et `preservation` d'être
	# muets alors qu'ils parlent très bien quand on les enfreint.
	var generic := "Le temps imparti s'est écoulé avant l'objectif."
	var mute := PackedStringArray()
	for kind in seen:
		var probe: Dictionary = {"type": kind, "count": 3, "max_lost": 0,
			"percent": 100, "max_ticks": 1, "cells": [[0, 0]]}
		var state := _lost_state([Vector2i(0, 0)], 0)
		match kind:
			"preservation", "extraction":
				# Un agent perdu : l'extraction à 100 % devient inatteignable et la
				# limite de préservation à zéro est franchie.
				state.counters.lost = 1
				state.agents[0].flags = AgentState.PERDU
			"celerity":
				state.tick = 99
		if RuleCatalog.outcome_reason([probe], state) == generic:
			mute.append(kind)
	assert_eq(mute, PackedStringArray(),
		"types d'objectif employés par un niveau et sans phrase d'échec propre : %s"
		% ", ".join(mute))
