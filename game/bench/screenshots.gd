extends Node
## Captures automatiques de chaque écran — JETABLE, outil de revue.
##
## Le concepteur ne peut pas commenter précisément ce qu'il n'a pas vu, et
## « c'est bizarre » n'est pas une information exploitable. Cet outil produit
## une image par écran, pour qu'il puisse répondre par « la pile est trop
## basse » plutôt que par une impression.
##
##   godot --path . game/bench/screenshots.tscn -- --out=res://reports/screens
##   godot --path . game/bench/screenshots.tscn -- --out=… --size=480x1067
##
## Ouvre une fenêtre quelques secondes, écrit les images, se ferme seul.
##
## DEUX PIÈGES DÉJÀ TOMBÉS DEDANS, tous deux corrigés ici :
##  · un Control enfant d'un simple Node reste à taille zéro — d'où l'ancrage
##    explicite de `App`, sans quoi le harnais mesure une interface effondrée
##    et fait croire à un défaut qui n'existe pas ;
##  · chercher « le premier GameScreen enfant » ramenait l'écran PRÉCÉDENT,
##    encore vivant le temps de son `queue_free()`. Les gestes partaient dans
##    l'écran mort et la capture montrait le nouveau, intact — une image qui
##    ne montrait pas ce qu'elle annonçait. `_open_game` renvoie désormais
##    l'écran, et l'on ne devine plus rien.

var _out_dir := "res://reports/screens"
var _size := Vector2i(1080, 2400)
var _app: App
var _sub: SubViewport
var _index := 0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
		elif arg.begins_with("--size="):
			var parts := arg.substr(7).split("x")
			if parts.size() == 2:
				_size = Vector2i(int(parts[0]), int(parts[1]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	# ON NE CAPTURE PLUS LA FENÊTRE. Elle est bornée par la dalle de la
	# machine : demander 1080x2400 rendait 1080x1131, donc un cadrage faux et
	# une image molle — et c'est ce flou qui a été pris pour un halo trop
	# diffus. Le rendu part dans un SubViewport dimensionné à la main : la
	# capture ne dépend plus de l'écran qui la produit.
	_sub = SubViewport.new()
	_sub.size = _size
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub.transparent_bg = false
	add_child(_sub)
	_app = App.new()
	_sub.add_child(_app)
	_app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await _capture_all()
	print("\nCaptures écrites dans %s" % ProjectSettings.globalize_path(_out_dir))
	get_tree().quit(0)

func _capture_all() -> void:
	await _shot("01-menu")

	_app._open_select()
	await _shot("02-selecteur")

	# Réglages : un seul réglage, et il doit se lire dans le TEXTE (ENF-20).
	_app._open_menu()
	_app._open_settings()
	await _shot("10-reglages")

	var game := _app._open_game("ch1_01", false)
	await _shot("03-objectif-ouverture")
	game._hide_objective_panel()
	await _shot("03b-niveau-pile-vide")

	# Tiroir de bibliothèque ouvert : c'est là que se compose la pile.
	game._on_slot_tapped(0)
	await _shot("04-panneau-ouvert")

	# Une règle sélectionnée : le retour visuel du chemin sans glissement.
	game._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	await _shot("04b-regle-selectionnee")

	# Une règle posée, quelques ticks joués : l'état nominal du jeu.
	game._on_slot_tapped(0)
	for i in range(6):
		game._view.step_forward()
	await _shot("05-nuee-en-mouvement")

	# EF-05 : le diagnostic sur un agent, en pause. LA capture à regarder.
	game._show_explain_at(game._view.agent_pixel(0))
	await _shot("06-diagnostic-ef05")

	# Le niveau 2, celui de la leçon d'ordonnancement. D'abord l'énoncé
	# par-dessus le terrain — c'est la capture qui dit si le panneau masque
	# encore le niveau qu'il décrit.
	game = _app._open_game("ch1_02", false)
	await _shot("07a-ch1-02-objectif")
	game._hide_objective_panel()
	# Puis le terrain SEUL, à tick zéro : danger, sortie et lumière visibles,
	# rien par-dessus. C'est sur celle-ci que se juge la hiérarchie DA-02.
	await _shot("07b-ch1-02-terrain")

	game._on_chip_tapped(RuleRegistry.R02_FLEE_DANGER)
	game._on_slot_tapped(0)
	game._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	game._on_slot_tapped(1)
	for i in range(14):
		game._view.step_forward()
	await _shot("07c-ch1-02-detour")

	# La cloture du chapitre : le niveau ou la cohesion sauve ce qu'elle tuait
	# en N3. C'est la capture a regarder pour juger l'arc, pas une regle isolee.
	game = _app._open_game("ch1_05", false)
	game._hide_objective_panel()
	await _shot("11-ch1-05-terrain")

	# LES ELEMENTS DES CHAPITRES 3 A 6 ONT LEUR CAPTURE, et c'est le seul moyen
	# de verifier qu'ils sont DESSINES. Le moteur les reconnaissait depuis le
	# premier lot alors que l'ecran les ignorait : une geometrie invisible est
	# une geometrie injuste, et aucun test de simulation ne l'aurait dit.
	game = _app._open_game("ch3_02", false)
	game._hide_objective_panel()
	for i in range(6):
		game._view.step_forward()
	await _shot("12-ch3-02-piste")

	game = _app._open_game("ch4_02", false)
	game._hide_objective_panel()
	# LES PORTEURS DOIVENT SE VOIR. Sans cette capture, on ne saurait pas si la
	# marque de charge est lisible sur une nuee en mouvement — et tout le
	# chapitre 4 se joue sur cette information.
	# La pile est posee par la voie de reprise de session — trois gestes
	# simules s'arretaient au deuxieme rang, et ce n'est pas l'interface qu'on
	# veut eprouver ici mais le RENDU des porteurs.
	var carry := Session.new()
	carry.level_id = "ch4_02"
	carry.stack = [RuleRegistry.R11_CARRY, RuleRegistry.R12_DROP_AT_GOAL,
		RuleRegistry.R01_TOWARD_LIGHT]
	game.restore_session(carry)
	for i in range(3):
		game._view.step_forward()
	await _shot("13-ch4-02-ressources-sens-unique")

	game = _app._open_game("ch5_02", false)
	game._hide_objective_panel()
	await _shot("14-ch5-02-porte-a-pression")

	# LE JOKER A L'ECRAN. Son identifiant porte son argument dans ses bits hauts
	# et vaut 784, pas 16 : toute la chaine d'interface doit le traverser sans
	# broncher — catalogue, tuile, pile, explication. C'est le seul endroit du
	# jeu ou un identifiant de regle n'est pas un petit entier.
	game = _app._open_game("ch6_01", false)
	game._hide_objective_panel()
	game._on_slot_tapped(0)
	game._on_chip_tapped(RuleRegistry.make_joker(GridState.CellType.STATIC_DANGER))
	game._on_slot_tapped(1)
	game._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	for i in range(9):
		game._view.step_forward()
	await _shot("16-ch6-01-joker")

	# BIBLIOTHEQUE LARGE, TIROIR OUVERT. Les niveaux offrent desormais cinq a six
	# regles pour trois rangs ; sur un ecran etroit un rang unique les mettait
	# hors de l'ecran, donc injouables ET invisibles. La capture est la preuve
	# que l'enveloppe tient — un test mesure les positions, l'oeil verifie que
	# le resultat se lit encore.
	var wide := _app._open_game("ch4_04", false)
	wide._hide_objective_panel()
	wide._on_slot_tapped(0)
	await _shot("19-bibliotheque-large")

	# ECHO DE MORT. C'est LA capture a regarder pour juger le retour d'echec :
	# un agent meurt sur une case rouge, et l'ecran doit le dire — sur la case
	# (anneau rouge) ET a la peripherie (halo de bord). Avant, rien ne le disait,
	# et le bilan tombait sur une scene ou il ne s'etait visiblement rien passe.
	var doomed := _app._open_game("ch1_02", false)
	doomed._hide_objective_panel()
	var suicide := Session.new()
	suicide.level_id = "ch1_02"
	suicide.stack = [RuleRegistry.R01_TOWARD_LIGHT]
	doomed.restore_session(suicide)
	for i in range(12):
		doomed._view.step_forward()
	doomed._edge_echo.play(false)
	await _shot("20-echo-de-mort")

	# ZONE INTERDITE. Entrer sur une de ses cases fait perdre A L'INSTANT, et
	# elle n'etait pas dessinee du tout : le joueur perdait sur une zone qui
	# n'existait nulle part a l'ecran.
	var banned := _app._open_game("ch6_02", false)
	banned._hide_objective_panel()
	await _shot("21-zone-interdite")

	# ECHO DE VICTOIRE. Le pendant du precedent, et il n'avait ete verifie que
	# par un test : le DERNIER agent sorti porte un anneau vert, et le bord de
	# l'ecran s'allume. Gagner et perdre ne doivent pas se ressembler.
	var winner := _app._open_game("ch1_01", false)
	winner._hide_objective_panel()
	var solution := Session.new()
	solution.level_id = "ch1_01"
	solution.stack = [RuleRegistry.R01_TOWARD_LIGHT]
	winner.restore_session(solution)
	# Jusqu'au tick ou le dernier franchit : c'est l'instant qu'on veut voir.
	for i in range(60):
		winner._view.step_forward()
		if winner._view.current_state().outcome != SimState.Outcome.RUNNING:
			break
	winner._edge_echo.play(true)
	await _shot("22-echo-de-victoire")

	# LA BASCULE, armee puis depensee. Son ETAT est le mecanisme : une fois
	# franchie elle ouvre les portes pour de bon, et un joueur qui ne peut pas
	# voir qu'elle a servi ne comprend pas pourquoi la porte reste ouverte.
	var latch := _app._open_game("ch5_07", false)
	latch._hide_objective_panel()
	await _shot("23a-bascule-armee")
	var plan := Session.new()
	plan.level_id = "ch5_07"
	plan.stack = [RuleRegistry.R04_SPREAD_OUT, RuleRegistry.R01_TOWARD_LIGHT]
	latch.restore_session(plan)
	for i in range(26):
		latch._view.step_forward()
	await _shot("23b-bascule-depensee")

	# Selection : vingt-deux niveaux groupes par chapitre, ecran defilant, avec
	# les defis CONSERVES en pastilles. Sans trace dans la liste, un defi gagne
	# disparaitrait avec l'ecran de bilan.
	_app.progress.record_win("ch1_01", 15, 0)
	_app.progress.record_win("ch1_02", 29, 0)
	_app.progress.record_challenges("ch1_01",
		PackedStringArray(["Économie — résolu avec 1 règle"]))
	_app.progress.record_challenges("ch1_02", PackedStringArray([
		"Économie — résolu avec 2 règles", "Efficience — 29 ticks, seuil 29"]))
	_app._open_select()
	await _shot("15-selection-chapitres")



	# Les deux bilans, gagné puis perdu.
	_app._on_level_finished("ch1_01", true, 14, 0, [RuleRegistry.R01_TOWARD_LIGHT], "La nuée a rempli l'objectif.")
	await _shot("08-bilan-gagne")

	_app._on_level_finished("ch1_02", false, 6, 1, [RuleRegistry.R01_TOWARD_LIGHT], "1 agent perdu — l'objectif de 20 sur 20 est devenu inatteignable.")
	await _shot("09-bilan-perdu")

	# LES TROIS DEFIS RG-18 OBTENUS D'UN COUP. C'est la seule capture qui montre
	# la couche de rejouabilite : sans elle, on ne saurait pas si un defi calibre
	# se voit reellement. [Cohesion, Lumiere] sur N5 gagne en 20 ticks — deux
	# regles (economie), sans la Fuite (abstinence), pile au seuil (efficience).
	_app._on_level_finished("ch1_05", true, 20, 0,
		[RuleRegistry.R03_STAY_GROUPED, RuleRegistry.R01_TOWARD_LIGHT],
		"La nuée a rempli l'objectif.")
	await _shot("17-bilan-defis")

func _shot(name: String) -> void:
	# Attendre que les transitions soient FINIES : saisir un panneau à
	# mi-course fait croire à un défaut de disposition qui n'existe pas.
	await get_tree().create_timer(0.35).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := _sub.get_texture().get_image()
	_index += 1
	var path := "%s/%s.png" % [_out_dir, name]
	image.save_png(path)
	print("  %d. %s (%d×%d)" % [_index, name, image.get_width(), image.get_height()])
