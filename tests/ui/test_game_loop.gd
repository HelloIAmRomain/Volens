extends GutTest
## La boucle complète : menu → sélecteur → niveau → bilan → retour.
## Ce que ces tests protègent : qu'un testeur puisse traverser le jeu du
## début à la fin sans rencontrer d'écran mort.

var _app: App

func before_each() -> void:
	# On part d'une progression et d'une session vierges : le test ne doit
	# pas dépendre de ce qu'une exécution précédente a laissé sur le disque.
	SaveStore.erase(Progress.PATH)
	SaveStore.erase(Session.PATH)
	_app = App.new()
	add_child_autofree(_app)

func after_each() -> void:
	SaveStore.erase(Progress.PATH)
	SaveStore.erase(Session.PATH)

func _screen_of(type_name: String) -> Node:
	for child in _app.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == type_name:
			return child
	return null

func test_a_fresh_launch_opens_the_menu() -> void:
	assert_not_null(_screen_of("MenuScreen"), "sans session, on arrive au menu")

func test_play_opens_the_first_unsolved_level() -> void:
	_app._on_play_requested()
	var game := _screen_of("GameScreen") as GameScreen
	assert_not_null(game, "« Jouer » doit ouvrir un niveau")
	assert_eq(game._level_id, "ch1_01")

func test_play_skips_a_level_already_solved() -> void:
	_app.progress.record_win("ch1_01", 14, 0)
	_app._on_play_requested()
	assert_eq((_screen_of("GameScreen") as GameScreen)._level_id, "ch1_02")

func test_winning_records_progress_and_opens_the_summary() -> void:
	_app._on_level_finished("ch1_01", true, 14, 0, [1], "gagné")

	assert_not_null(_screen_of("SummaryScreen"), "une partie finie mène au bilan")
	assert_true(_app.progress.is_solved("ch1_01"))
	assert_eq(_app.progress.best_ticks("ch1_01"), 14)

func test_losing_records_nothing() -> void:
	_app._on_level_finished("ch1_01", false, 60, 3, [1], "perdu")

	assert_not_null(_screen_of("SummaryScreen"))
	assert_false(_app.progress.is_solved("ch1_01"), "un échec ne marque rien — le jeu n'est pas punitif")

func test_finishing_a_level_clears_the_resume_point() -> void:
	# Rien à reprendre dans un niveau terminé : sinon la réouverture
	# ramènerait le joueur dans un essai déjà joué.
	_app.session.level_id = "ch1_01"
	_app.session.tick = 9
	_app._on_level_finished("ch1_01", true, 14, 0, [1], "gagné")

	assert_false(_app.session.is_valid())

func test_reset_erases_progress_and_returns_to_the_menu() -> void:
	_app.progress.record_win("ch1_01", 14, 0)
	_app._on_reset_requested()

	assert_false(_app.progress.is_solved("ch1_01"))
	assert_not_null(_screen_of("MenuScreen"))

# --- reprise après fermeture (EF-20/21) ------------------------------------

func test_the_session_is_written_when_the_system_pauses_the_app() -> void:
	# NOTIFICATION_APPLICATION_PAUSED est le dernier instant garanti avant
	# qu'Android puisse tuer le processus : la session doit y être écrite.
	_app._on_play_requested()
	var game := _screen_of("GameScreen") as GameScreen
	game._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	game._on_slot_tapped(0)
	for i in range(4):
		game._view.step_forward()

	_app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)

	var stored := Session.load_from_disk()
	assert_eq(stored.level_id, "ch1_01")
	assert_eq(stored.tick, 4, "le tick exact est conservé")
	assert_eq(stored.stack, [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])

func test_a_stored_session_reopens_the_level_paused_at_the_same_tick() -> void:
	var session := Session.new()
	session.level_id = "ch1_02"
	session.stack = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]
	session.tick = 7
	session.save_to_disk()

	var app := App.new()
	add_child_autofree(app)

	var game: GameScreen = null
	for child in app.get_children():
		if child is GameScreen:
			game = child
	assert_not_null(game, "une session valide rouvre le niveau sans écran intermédiaire")
	assert_eq(game._view.current_state().tick, 7, "au tick exact, par re-simulation déterministe")
	assert_false(game._playing, "et TOUJOURS en pause : on ne reprend jamais une simulation en marche")

func test_a_session_on_an_unknown_level_falls_back_to_the_menu() -> void:
	# Le chapitre 1 est complet : le cas à couvrir n'est plus « niveau non
	# conçu » mais « identifiant inconnu », par exemple une sauvegarde écrite
	# par une version antérieure ou postérieure.
	var session := Session.new()
	session.level_id = "ch2_01"  # inexistant, aucun fichier
	session.stack = [1]
	session.save_to_disk()

	var app := App.new()
	add_child_autofree(app)

	var has_menu := false
	for child in app.get_children():
		if child is MenuScreen:
			has_menu = true
	assert_true(has_menu, "repli propre plutôt qu'écran noir")
