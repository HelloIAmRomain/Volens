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

func test_settings_screen_fills_its_parent() -> void:
	var host := _host()
	var screen := SettingsScreen.new()
	host.add_child(screen)
	screen.setup(Settings.new())
	await _settle()
	_assert_fills(screen, "SettingsScreen")

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
##
## LA LISTE N'EST PLUS ÉCRITE À LA MAIN. Elle l'était, et c'était la même
## faiblesse que celle qui avait laissé passer l'écran de bilan : un garde-fou
## qu'il faut penser à mettre à jour ne garde rien. Les écrans sont maintenant
## DÉCOUVERTS dans `game/ui/`, et tout écran non déclaré ici fait échouer le
## test — impossible d'en ajouter un en silence.
const CAPTURE_MARKERS := {
	"MenuScreen": ["01-menu"],
	"LevelSelectScreen": ["02-selecteur"],
	"GameScreen": ["05-nuee"],
	"SummaryScreen": ["08-bilan", "09-bilan"],
	"SettingsScreen": ["10-reglages"],
	"TrialSelectScreen": ["18a-epreuve-choix-chapitre"],
}

func _declared_screens() -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open("res://game/ui")
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.ends_with(".gd"):
			var text := FileAccess.get_file_as_string("res://game/ui/" + entry)
			for line in text.split("\n"):
				if line.begins_with("class_name ") and line.strip_edges().ends_with("Screen"):
					found.append(line.substr(11).strip_edges())
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found

func test_every_screen_of_the_game_is_declared_here() -> void:
	var declared := _declared_screens()
	assert_gt(declared.size(), 0, "aucun écran découvert — le balayage est cassé")
	for screen_name in declared:
		assert_true(CAPTURE_MARKERS.has(screen_name),
			"%s existe dans game/ui/ mais n'est ni capturé ni déclaré ici" % screen_name)

func test_the_screenshot_harness_covers_every_screen() -> void:
	var source := FileAccess.get_file_as_string("res://game/bench/screenshots.gd")
	for screen_name in CAPTURE_MARKERS:
		for marker in CAPTURE_MARKERS[screen_name]:
			assert_true(source.contains(String(marker)),
				"%s n'est pas capturé par le harnais (marqueur « %s » absent)" % [screen_name, marker])

## LA NUÉE NE PASSE JAMAIS SOUS L'INTERFACE.
##
## Depuis que la vue occupe tout l'écran — le jeu est le fond, l'interface se
## pose dessus — plus rien ne DÉCOUPE le rectangle de jeu : c'est un calcul de
## marges qui tient la grille à l'écart des barres. Un calcul se perd sans
## bruit ; c'est déjà arrivé, un correctif textuel ayant manqué son ancre et
## laissé le cadrage plein écran. Ce test le refuse.
func _fitted_screen(size: Vector2i) -> GameScreen:
	var sub := SubViewport.new()
	sub.size = size
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(sub)
	var screen := GameScreen.new()
	sub.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var level: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/ch1_02.json"))
	screen.load_level(level, RuleParams.new(), "ch1_02")
	return screen

func _assert_grid_clears_the_bars(size: Vector2i) -> void:
	var screen := _fitted_screen(size)
	await _settle()
	await _settle()
	var view: SimView = screen._view
	var grid: Vector2i = view.current_state().grid.size
	var top: float = view._grid_origin.y
	var bottom: float = top + float(grid.y) * view._cell_size
	assert_gt(view._cell_size, 1.0, "%s : la grille n'a pas été cadrée" % str(size))
	assert_gte(top, screen._field_top() - 1.0,
		"%s : la grille remonte sous la barre haute (%.0f < %.0f)" % [str(size), top, screen._field_top()])
	assert_lte(bottom, screen._field_bottom() + 1.0,
		"%s : la grille descend sous la pile (%.0f > %.0f)" % [str(size), bottom, screen._field_bottom()])

func test_the_swarm_never_slides_under_the_bars_on_a_tall_screen() -> void:
	await _assert_grid_clears_the_bars(Vector2i(1080, 2400))

func test_the_swarm_never_slides_under_the_bars_on_a_short_screen() -> void:
	# Le ratio court est le cas qui casse : la grille y est limitée en HAUTEUR,
	# donc c'est là que le cadrage doit vraiment travailler.
	await _assert_grid_clears_the_bars(Vector2i(1080, 1920))
