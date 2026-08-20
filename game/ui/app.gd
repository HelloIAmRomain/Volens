class_name App
extends Control
## Machine à états d'écrans [DCT §9.1] : Menu → Sélecteur → Jeu → Bilan.
## Aucun empilement de fenêtres modales pendant le jeu (P3).
##
## Porte aussi la reprise (EF-20/21) : la session est écrite avant toute
## chance d'être tuée — à chaque geste significatif et à
## `NOTIFICATION_APPLICATION_PAUSED`, qui arrive AVANT que le système ne tue
## l'application.
##
## AU LANCEMENT, LE JEU OUVRE TOUJOURS LE MENU. Il rouvrait le niveau en cours
## sans détour ; l'application avait alors l'air de n'avoir pas de menu du tout,
## et l'on ne voyait jamais ni les chapitres, ni les réglages. La
## reprise vit derrière « Continuer », qui remplace « Jouer » quand une partie
## est en cours — elle rend le niveau **en pause**, au tick exact.

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
	# LE JEU S'OUVRE TOUJOURS SUR LE MENU. Il rouvrait le niveau en cours sans
	# detour, ce qui donnait a l'application l'air de n'avoir pas de menu du tout :
	# on relancait, on retombait au milieu d'une partie, sans jamais voir ni les
	# chapitres ni les reglages.
	#
	# La reprise n'est pas perdue pour autant : elle est derriere « Continuer »,
	# qui remplace « Jouer » quand une partie est en cours. Un geste de plus, mais
	# un geste CHOISI — et l'ecran d'accueil redevient un point de depart.
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
	screen.self_check_requested.connect(_open_self_check)
	_swap(screen, Screen.SETTINGS)
	screen.setup(settings)

## DT-22 : uniquement dans une build de test. Chargement dynamique — la
## classe n'est pas dans le paquet de production.
func _open_self_check() -> void:
	var script: Variant = load(SettingsScreen.SELF_CHECK_PATH)
	if script == null:
		return
	var screen: Control = (script as GDScript).new()
	screen.back_requested.connect(_open_settings)
	_swap(screen, Screen.SETTINGS)

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
	# La persistance n'est branchée qu'UNE FOIS l'écran en place : sinon le
	# chargement lui-même émet `state_changed` et réécrit la session avec le
	# tick zéro, effaçant précisément ce qu'on s'apprêtait à restaurer.
	screen.state_changed.connect(_persist_session)

	# UNE SEULE SURCOUCHE À LA FOIS, ET DANS CET ORDRE. Les deux s'affichaient
	# ensemble à l'essai sur l'appareil : la légende par-dessus le panneau
	# d'objectif, chacune avec son « touchez pour… », et le joueur ne savait plus
	# ce qu'il refermait. Deux panneaux simultanés ne font pas deux informations,
	# ils en font zéro.
	#
	# LA LÉGENDE PASSE D'ABORD parce qu'elle explique le vocabulaire que
	# l'objectif emploie. Lire « faire sortir 17 agents » sans savoir ce qu'est
	# la lumière qu'on voit à l'écran, c'est lire la consigne avant l'alphabet.
	var showing_resume: bool = resume and session.level_id == level_id
	var then := func() -> void:
		if not showing_resume and is_instance_valid(screen):
			screen.show_objective_panel()
	if not _present_new_mechanics(screen, level_data, then):
		then.call()
	return screen

## LA LÉGENDE DES ÉLÉMENTS JAMAIS RENCONTRÉS.
##
## Le jeu n'a pas de tutoriel, mais **ce que fait une case n'est pas une
## découverte, c'est un fait** : rien à l'écran ne distingue une plaque à
## pression d'une bascule, et le joueur l'apprenait en perdant.
##
## ON ENREGISTRE AU MOMENT DE MONTRER, pas au moment de refermer. Une carte
## fermée par un retour au menu, par une mise en veille ou par la fin du
## processus reviendrait sinon au niveau suivant — et la « une seule fois »
## n'aurait plus rien d'une promesse.
func _present_new_mechanics(screen: GameScreen, level_data: Dictionary,
		then: Callable) -> bool:
	var entries := MechanicPrimer.unseen_in(level_data, progress.seen)
	if entries.is_empty():
		return false
	var keys := PackedStringArray()
	for entry in entries:
		keys.append(String((entry as Dictionary)["key"]))
	progress.mark_seen(keys)
	_show_card(screen, entries, 0, then)
	return true

## UNE LEGENDE, PUIS LA SUIVANTE — jamais les deux ensemble.
##
## A l'essai sur l'appareil, une carte portant « Ressource » et « Depot »
## surlignait les deux jeux de cases avec le MEME cadre : le joueur lisait deux
## noms et voyait deux groupes, sans rien pour les apparier. Une designation
## ambigue ne designe pas — c'est le principe de clarte applique a l'interface
## plutot qu'aux mecaniques.
##
## LA CONTINUATION TRAVERSE TOUTE LA CHAINE. Un premier montage rebranchait le
## panneau d'objectif sur la PREMIERE carte : il s'ouvrait donc derriere la
## seconde legende, et l'on retrouvait les deux surcouches simultanees qu'on
## venait justement de separer. Elle est passee de carte en carte et n'est
## appelee qu'apres la derniere.
func _show_card(screen: GameScreen, entries: Array, index: int,
		then: Callable) -> void:
	var entry: Dictionary = entries[index]
	var spots: Array = []
	for r in screen.screen_rects_of(entry.get("cells", []) as Array):
		spots.append({"rect": r, "cell": int(entry.get("cell", -1))})
	var card := MechanicCard.new()
	screen.add_child(card)
	card.setup(entry, spots)
	card.dismissed.connect(func() -> void:
		if index + 1 < entries.size() and is_instance_valid(screen):
			_show_card(screen, entries, index + 1, then)
		else:
			then.call())

func _on_play_requested() -> void:
	# « Continuer » et « Jouer » sont le MEME bouton : c'est l'existence d'une
	# partie en cours qui decide, et le menu affiche le mot correspondant. Deux
	# boutons distincts poseraient au joueur une question dont il connait deja la
	# reponse.
	if session.is_valid() and not LevelCatalog.path_of(session.level_id).is_empty():
		_open_game(session.level_id, true)
		return
	_open_game(LevelCatalog.next_playable(progress), false)


func _on_quit_to_select() -> void:
	_persist_session()
	_open_select()

func _on_reset_requested() -> void:
	progress.reset()
	session.clear()
	_open_menu()

func _on_level_finished(level_id: String, won: bool, ticks: int, lost: int, stack: Array, reason: String) -> void:
	# PHOTO DES DÉFIS ACQUIS **AVANT** L'ENREGISTREMENT. L'écran de bilan doit
	# distinguer « obtenu à l'instant » de « déjà acquis », et une fois
	# `record_challenges` passé les deux ensembles se confondent — la question
	# ne serait plus posable. L'ordre de ces deux lignes porte donc une
	# information, et les intervertir ferait disparaître la distinction sans
	# qu'aucun test de compilation ne bronche.
	var already := progress.earned_challenges(level_id).duplicate()
	if won:
		progress.record_win(level_id, ticks, lost)
		# Les défis obtenus s'accumulent et ne se reprennent jamais (RG-19).
		progress.record_challenges(level_id,
			SummaryScreen.challenges_earned(level_id, stack, ticks))
	var summary := SummaryScreen.new()
	summary.retry_requested.connect(func() -> void: _open_game(level_id, false))
	summary.select_requested.connect(_open_select)
	summary.next_level_requested.connect(func(next_id: String) -> void: _open_game(next_id, false))
	_swap(summary, Screen.SUMMARY)
	summary.setup(level_id, won, ticks, lost, stack, reason, already)
	# Le niveau est terminé : plus rien à reprendre.
	session.clear()

