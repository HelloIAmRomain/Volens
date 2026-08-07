extends GutTest
## Garde-fou de disposition : TOUS les écrans, sans exception.
##
## Ce test existe parce que j'ai livré un écran de bilan collé en haut à
## gauche après avoir déclaré « les écrans sont propres » — le harnais avait
## produit l'image, je ne l'avais pas regardée. Un contrôle visuel qui repose
## sur la discipline de qui regarde n'est pas un contrôle.
##
## Il attrape la cause exacte du défaut : `set_anchors_preset()` conserve les
## offsets, donc un contrôle configuré alors qu'il est de taille nulle reste
## de taille nulle à jamais. Ici, chaque écran est placé dans un parent
## dimensionné, puis on exige qu'il le remplisse — lui et son contenu.

const VIEWPORT := Vector2(1080, 2400)

func _host() -> Control:
	# Pas d'ancres sur l'hôte : un contrôle piloté par ancres refuse qu'on
	# lui impose une taille. Ici on veut justement un rectangle fixe qui
	# tienne lieu d'écran, et des enfants qui doivent le remplir.
	var host := Control.new()
	add_child_autofree(host)
	host.size = VIEWPORT
	return host

func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

## Chaque écran doit remplir son parent, et son contenu doit être large.
func _assert_fills(screen: Control, label: String) -> void:
	assert_almost_eq(screen.size.x, VIEWPORT.x, 2.0, "%s : largeur effondrée (%s)" % [label, screen.size])
	assert_almost_eq(screen.size.y, VIEWPORT.y, 2.0, "%s : hauteur effondrée (%s)" % [label, screen.size])
	var widest := 0.0
	for child in screen.get_children():
		if child is Control:
			widest = maxf(widest, (child as Control).size.x)
	assert_gt(widest, VIEWPORT.x * 0.5,
		"%s : aucun contenu ne dépasse la moitié de la largeur — la colonne est retombée sur sa taille minimale" % label)

func test_menu_screen_fills_its_parent() -> void:
	var host := _host()
	var screen := MenuScreen.new()
	host.add_child(screen)
	screen.setup(Progress.new(), Session.new())
	await _settle()
	_assert_fills(screen, "MenuScreen")

func test_level_select_screen_fills_its_parent() -> void:
	var host := _host()
	var screen := LevelSelectScreen.new()
	host.add_child(screen)
	screen.setup(Progress.new())
	await _settle()
	_assert_fills(screen, "LevelSelectScreen")

func test_summary_screen_fills_its_parent() -> void:
	# L'écran qui avait échappé à la revue. Il ne peut plus.
	var host := _host()
	var screen := SummaryScreen.new()
	host.add_child(screen)
	screen.setup("ch1_01", true, 14, 0, [RuleRegistry.R01_TOWARD_LIGHT], "La nuée a rempli l'objectif.")
	await _settle()
	_assert_fills(screen, "SummaryScreen (victoire)")

func test_summary_screen_on_defeat_fills_too() -> void:
	var host := _host()
	var screen := SummaryScreen.new()
	host.add_child(screen)
	screen.setup("ch1_02", false, 6, 1, [RuleRegistry.R01_TOWARD_LIGHT], "1 agent perdu — objectif inatteignable.")
	await _settle()
	_assert_fills(screen, "SummaryScreen (défaite)")

func test_game_screen_fills_its_parent() -> void:
	var host := _host()
	var screen := GameScreen.new()
	host.add_child(screen)
	var level: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/ch1_01.json"))
	screen.load_level(level, RuleParams.new(), "ch1_01")
	await _settle()
	_assert_fills(screen, "GameScreen")

## Le harnais de captures doit couvrir TOUS les écrans du jeu : c'est lui qui
## sert de preuve, il ne peut pas en oublier un.
func test_the_screenshot_harness_covers_every_screen() -> void:
	var source := FileAccess.get_file_as_string("res://game/bench/screenshots.gd")
	for screen_name in ["MenuScreen", "LevelSelectScreen", "GameScreen", "SummaryScreen"]:
		var covered := false
		match screen_name:
			"MenuScreen": covered = source.contains("01-menu")
			"LevelSelectScreen": covered = source.contains("02-selecteur")
			"GameScreen": covered = source.contains("05-nuee")
			"SummaryScreen": covered = source.contains("08-bilan") and source.contains("09-bilan")
		assert_true(covered, "%s n'est pas capturé par le harnais" % screen_name)
