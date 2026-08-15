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
	_abandon_trial()
	var menu := MenuScreen.new()
	menu.play_requested.connect(_on_play_requested)
	menu.select_requested.connect(_open_select)
	menu.settings_requested.connect(_open_settings)
	menu.trial_requested.connect(_open_trial_select)
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
	_abandon_trial()
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
	# MODE ÉPREUVE : la main et le budget sont posés AVANT le chargement, qui
	# construit les tuiles à partir d'eux. Les poser après laisserait un écran
	# offrant la bibliothèque entière le temps d'une image — et un joueur qui
	# aurait vu la vraie liste ne jouerait plus la même partie.
	if trial != null and trial.current_level() == level_id:
		screen.drawn_rules = trial.draw_for(level_id,
			ArcadeData.sufficient_sets(level_id), level_data.get("allowed_rules", []))
		screen.on_launch = _on_trial_launch
		screen.launches_left = trial.launches_left
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
	trial = null
	_open_game(LevelCatalog.next_playable(progress), false)

# --- MODE ÉPREUVE ------------------------------------------------------------
#
# Une épreuve court sur un CHAPITRE entier, avec un budget de lancements partagé
# et des règles tirées à chaque niveau. Elle ne touche ni la progression normale
# ni la session : c'est une partie à côté, qu'on gagne ou qu'on perd d'un bloc.
#
# LE CHAPITRE SE CHOISIT PARMI CEUX ENTIÈREMENT RÉSOLUS (`TrialSelectScreen`).
# Proposer une épreuve sur un chapitre qu'on n'a pas fini, ce serait la faire
# échouer sur des niveaux qu'on n'a pas encore compris — et le mode punit la
# recherche, pas l'ignorance.
var trial: TrialRun = null

## QUITTER UN NIVEAU D'ÉPREUVE ABANDONNE L'ÉPREUVE, et il fallait l'écrire.
##
## Le défaut trouvé en relisant la navigation : `_on_quit_to_select` laissait
## `trial` vivant. Le joueur revenait au sélecteur, choisissait un niveau
## ordinaire, le gagnait — et `_on_level_finished` voyait `trial != null`, donc
## routait la victoire vers l'épreuve : **aucune progression enregistrée, aucun
## défi coché, et le bilan parlait d'un niveau qu'on n'avait pas joué.** Une
## partie perdue en silence, ce qui est la pire des façons.
##
## Le mode ne se met pas en pause : il se joue d'un bloc ou pas du tout. C'est
## cohérent avec sa ressource — un budget qu'on pourrait quitter et reprendre à
## volonté n'en serait plus une.
func _abandon_trial() -> void:
	trial = null

## LE CHAPITRE SE CHOISIT. La première version prenait d'office le dernier
## chapitre résolu, ce qui refermait le mode sur un seul chapitre à mesure qu'on
## progressait — et pas le plus exigeant : le chapitre 2 demande 3,0 fois son
## budget en force brute, le sixième 2,9. Un mode qu'on rejoue doit se viser.
func _open_trial_select() -> void:
	var screen := TrialSelectScreen.new()
	screen.chapter_chosen.connect(_start_trial)
	screen.back_requested.connect(_open_menu)
	_swap(screen, Screen.SELECT)
	screen.setup(progress)

func _start_trial(chapter_number: int) -> void:
	if not TrialSelectScreen.cleared_chapters(progress).has(chapter_number):
		_open_menu()
		return
	# La graine vient de l'horloge — hors de `core/`, donc sans effet sur le
	# déterminisme de la simulation (invariant n°7). Elle est conservée : une
	# épreuve se rejoue à l'identique, ce qui rend un échec analysable.
	trial = TrialRun.start(chapter_number, int(Time.get_unix_time_from_system()) & 0x7FFFFFFF)
	_open_game(trial.current_level(), false)

func _on_trial_launch() -> bool:
	if trial == null:
		return true
	return trial.spend_launch()

## Suite d'une épreuve après un niveau. Perdu ou budget épuisé : l'épreuve
## s'arrête. Gagné : on passe au suivant, ou l'on a fini le chapitre.
##
## UN ÉCHEC N'EST PAS UNE FIN DE PARTIE ORDINAIRE. Le bilan doit dire ce qui
## s'est passé au niveau de l'ÉPREUVE — combien de niveaux franchis, combien de
## lancements restaient — parce que c'est la seule échelle à laquelle ce mode se
## joue. Rejouer le niveau seul n'aurait aucun sens.
func _advance_trial(won: bool, reason: String) -> void:
	# Le chapitre est retenu AVANT que `trial` ne soit remis à zéro : « Réessayer »
	# doit relancer LA MÊME épreuve, pas rouvrir le choix. Le lire après aurait
	# planté sur une référence nulle.
	var chapter_played := trial.chapter
	if not won:
		var lost_at := trial.index
		var summary := SummaryScreen.new()
		summary.select_requested.connect(_open_menu)
		summary.retry_requested.connect(func() -> void: _start_trial(chapter_played))
		_swap(summary, Screen.SUMMARY)
		summary.setup(trial.current_level(), false, 0, 0, [],
			"Épreuve interrompue au niveau %d sur %d. %s" % [
				lost_at + 1, trial.level_ids.size(), reason])
		trial = null
		return
	trial.advance()
	if trial.is_won():
		var done := SummaryScreen.new()
		done.select_requested.connect(_open_menu)
		done.retry_requested.connect(func() -> void: _start_trial(chapter_played))
		_swap(done, Screen.SUMMARY)
		done.setup("", true, 0, 0, [],
			"Épreuve réussie : %d niveaux, %d lancement(s) restant(s)." % [
				trial.level_ids.size(), trial.launches_left])
		trial = null
		return
	_open_game(trial.current_level(), false)

func _on_quit_to_select() -> void:
	_persist_session()
	_open_select()

func _on_reset_requested() -> void:
	progress.reset()
	session.clear()
	_open_menu()

func _on_level_finished(level_id: String, won: bool, ticks: int, lost: int, stack: Array, reason: String) -> void:
	# MODE ÉPREUVE : la progression normale N'EST PAS TOUCHÉE. Une épreuve est
	# une partie à côté — elle ne débloque rien, n'enregistre aucun record et
	# ne coche aucun défi. Sans quoi elle deviendrait le chemin court vers la
	# progression, et un mode qui punit la recherche récompenserait de l'avoir
	# contournée.
	if trial != null:
		_advance_trial(won, reason)
		return
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
	summary.setup(level_id, won, ticks, lost, stack, reason)
	# Le niveau est terminé : plus rien à reprendre.
	session.clear()

