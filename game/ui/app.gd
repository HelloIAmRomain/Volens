class_name App
extends Control
## Machine à états d'écrans [DCT §9.1] : Menu → Sélecteur → Jeu → Bilan.
## Aucun empilement de fenêtres modales pendant le jeu (P3).
##
## Porte aussi la reprise (EF-20/21) : la session est écrite avant toute
## chance d'être tuée — à chaque geste significatif et à
## `NOTIFICATION_APPLICATION_PAUSED`, qui arrive AVANT que le système ne tue
## l'application. Au lancement, une session valide rouvre directement le
## niveau, **en pause**, au tick exact : aucun écran intermédiaire.

enum Screen { MENU, SELECT, GAME, SUMMARY, SETTINGS }

var progress: Progress
var session: Session
var settings: Settings

var _current: Control
var _screen: int = Screen.MENU

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(ViewPalette.BACKGROUND)
	progress = Progress.load_from_disk()
	session = Session.load_from_disk()
	# Les réglages s'appliquent AVANT le premier écran : le retour haptique
	# doit être coupé dès le premier geste si le joueur l'a coupé (ENF-24).
	settings = Settings.load_from_disk()
	# Reprise : si une session valide existe, on y retourne sans détour.
	if session.is_valid() and not LevelCatalog.path_of(session.level_id).is_empty():
		_open_game(session.level_id, true)
	else:
		_open_menu()

func _notification(what: int) -> void:
	# Dernier instant garanti avant que le système ne puisse tuer le
	# processus : c'est ici que la session doit être sur le disque.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_persist_session()

func _persist_session() -> void:
	if _screen == Screen.GAME and _current != null and is_instance_valid(_current) and _current is GameScreen:
		(_current as GameScreen).store_session(session)
		session.save_to_disk()

# --- navigation ----------------------------------------------------------------

func _swap(next_screen: Control, screen_id: int) -> void:
	if _current != null:
		_current.queue_free()
	_current = next_screen
	_screen = screen_id
	add_child(next_screen)

func _open_menu() -> void:
	var menu := MenuScreen.new()
	menu.play_requested.connect(_on_play_requested)
	menu.select_requested.connect(_open_select)
	menu.settings_requested.connect(_open_settings)
	# L'écran entre dans l'arbre AVANT d'être configuré : des ancres posées
	# hors de l'arbre sont perdues, et le contenu retombe sur sa taille
	# minimale — d'où une colonne collée en haut à gauche.
	_swap(menu, Screen.MENU)
	menu.setup(progress, session)

func _open_settings() -> void:
	var screen := SettingsScreen.new()
	screen.back_requested.connect(_open_menu)
	screen.reset_requested.connect(_on_reset_requested)
	_swap(screen, Screen.SETTINGS)
	screen.setup(settings)

func _open_select() -> void:
	var select := LevelSelectScreen.new()
	select.level_chosen.connect(func(level_id: String) -> void: _open_game(level_id, false))
	select.back_requested.connect(_open_menu)
	_swap(select, Screen.SELECT)
	select.setup(progress)

## Renvoie l'écran ouvert. Le harnais de captures en a besoin : chercher
## « le premier GameScreen enfant » ramenait l'écran PRÉCÉDENT, encore vivant
## le temps de son `queue_free()`, et produisait des captures qui ne montraient
## pas ce qu'elles annonçaient (carnet décision 80).
func _open_game(level_id: String, resume: bool) -> GameScreen:
	var level_data := LevelCatalog.load_level_data(level_id)
	if level_data.is_empty():
		_open_menu()
		return null
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	var screen := GameScreen.new()
	screen.finished.connect(_on_level_finished)
	screen.quit_requested.connect(_on_quit_to_select)
	_swap(screen, Screen.GAME)
	screen.load_level(level_data, RuleParams.from_dict(rules if rules is Dictionary else {}), level_id)
	if resume and session.level_id == level_id:
		screen.restore_session(session)
		# EF-21 : à la reprise, aucun panneau — il coûterait un geste avant le
		# premier geste utile. Le bandeau se souligne, c'est suffisant.
		screen.flash_banner()
	else:
		session.level_id = level_id
		session.stack = []
		session.tick = 0
		# T-031 : le tout premier niveau démarre à la vitesse la plus lente.
		# C'est la première chose qu'un joueur verra du jeu.
		session.speed_index = 0 if LevelCatalog.index_of(level_id) == 0 else 1
		screen.set_speed_index(session.speed_index)
		session.save_to_disk()
		screen.show_objective_panel()
	# La persistance n'est branchée qu'UNE FOIS l'écran en place : sinon le
	# chargement lui-même émet `state_changed` et réécrit la session avec le
	# tick zéro, effaçant précisément ce qu'on s'apprêtait à restaurer.
	screen.state_changed.connect(_persist_session)
	return screen

func _on_play_requested() -> void:
	_open_game(LevelCatalog.next_playable(progress), false)

func _on_quit_to_select() -> void:
	_persist_session()
	_open_select()

func _on_reset_requested() -> void:
	progress.reset()
	session.clear()
	_open_menu()

func _on_level_finished(level_id: String, won: bool, ticks: int, lost: int, stack: Array, reason: String) -> void:
	if won:
		progress.record_win(level_id, ticks, lost)
	var summary := SummaryScreen.new()
	summary.retry_requested.connect(func() -> void: _open_game(level_id, false))
	summary.select_requested.connect(_open_select)
	summary.next_level_requested.connect(func(next_id: String) -> void: _open_game(next_id, false))
	_swap(summary, Screen.SUMMARY)
	summary.setup(level_id, won, ticks, lost, stack, reason)
	# Le niveau est terminé : plus rien à reprendre.
	session.clear()

