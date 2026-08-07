extends Node
## Captures automatiques de chaque écran — JETABLE, outil de revue.
##
## Le concepteur ne peut pas commenter précisément ce qu'il n'a pas vu, et
## « c'est bizarre » n'est pas une information exploitable. Cet outil produit
## une image par écran dans `reports/screens/`, pour qu'il puisse répondre
## par « la pile est trop basse » plutôt que par une impression.
##
##   godot --path . game/bench/screenshots.tscn
##
## Ouvre une fenêtre quelques secondes, écrit les images, se ferme seul.

const OUT_DIR := "res://reports/screens"

var _app: App
var _index := 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_app = App.new()
	add_child(_app)
	# Un Control enfant d'un simple Node reste à taille zéro : dans le vrai
	# jeu, App est la RACINE de la scène et Godot lui donne le viewport.
	# Sans ça, le harnais mesurerait une interface effondrée sur sa taille
	# minimale et ferait croire à un défaut qui n'existe pas.
	_app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await _capture_all()
	print("\nCaptures écrites dans %s" % ProjectSettings.globalize_path(OUT_DIR))
	get_tree().quit(0)

func _capture_all() -> void:
	await _shot("01-menu")

	_app._open_select()
	await _shot("02-selecteur")

	_app._open_game("ch1_01", false)
	var game := _game()
	await _shot("03-niveau-pile-vide")

	# Tiroir de bibliothèque ouvert : c'est là que se compose la pile.
	game._toggle_drawer()
	await _shot("04-tiroir-ouvert")

	# Une règle posée, quelques ticks joués : l'état nominal du jeu.
	game._toggle_drawer()
	game._place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	for i in range(6):
		game._view.step_forward()
	await _shot("05-nuee-en-mouvement")

	# EF-05 : le diagnostic sur un agent, en pause. LA capture à regarder.
	var target := game._view.agent_pixel(0)
	game._show_explain_at(target)
	await _shot("06-diagnostic-ef05")

	# Le niveau 2, celui de la leçon d'ordonnancement.
	_app._open_game("ch1_02", false)
	game = _game()
	game._place(RuleRegistry.R02_FLEE_DANGER, 0)
	game._place(RuleRegistry.R01_TOWARD_LIGHT, 1)
	for i in range(14):
		game._view.step_forward()
	await _shot("07-ch1-02-detour")

	# Les deux bilans, gagné puis perdu.
	_app._on_level_finished("ch1_01", true, 14, 0, [RuleRegistry.R01_TOWARD_LIGHT])
	await _shot("08-bilan-gagne")

	_app._on_level_finished("ch1_02", false, 6, 1, [RuleRegistry.R01_TOWARD_LIGHT])
	await _shot("09-bilan-perdu")

func _game() -> GameScreen:
	for child in _app.get_children():
		if child is GameScreen:
			return child
	return null

func _shot(name: String) -> void:
	# Deux images d'attente : la première laisse les conteneurs se disposer,
	# la seconde garantit que le dessin est terminé avant la lecture.
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_index += 1
	var path := "%s/%s.png" % [OUT_DIR, name]
	image.save_png(path)
	print("  %d. %s (%d×%d)" % [_index, name, image.get_width(), image.get_height()])
