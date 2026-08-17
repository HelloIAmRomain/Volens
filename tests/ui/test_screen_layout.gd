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

## LE TIROIR DE RÈGLES NE DÉBORDE JAMAIS, ET C'EST UNE CONDITION DE JOUABILITÉ.
##
## Une règle posée hors de l'écran n'est pas seulement mal affichée : elle est
## **injouable, et invisible**. Le joueur ne peut ni la toucher ni deviner
## qu'elle existe — il cherche donc la solution dans une bibliothèque amputée,
## sans que rien ne le lui dise.
##
## Le test balaie de UNE à SIX règles sur l'écran le plus ÉTROIT du parc
## (720 de large), parce que la largeur est ce qui manque : c'est le cas où le
## mécanisme est sollicité, jamais le 1080 confortable (invariant n°12).
func _assert_chips_fit(width: int, rule_count: int) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(width, 1440)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(sub)
	var screen := GameScreen.new()
	sub.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var level: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/levels/ch1_02.json"))
	var data: Dictionary = level as Dictionary
	var wide: Array = []
	for i in range(rule_count):
		wide.append(i + 1)
	data["allowed_rules"] = wide
	screen.load_level(data, RuleParams.new(), "ch1_02")
	screen._on_slot_tapped(0)
	await _settle()
	await _settle()

	var panel: Control = screen._panel
	var row: Control = panel.get_node("ChipRow") as Control
	assert_eq(screen._chips.size(), rule_count,
		"%d règles attendues dans le tiroir" % rule_count)
	for chip in screen._chips:
		var right: float = panel.position.x + row.position.x \
			+ (chip as Control).position.x + (chip as Control).size.x
		var bottom: float = panel.position.y + row.position.y \
			+ (chip as Control).position.y + (chip as Control).size.y
		assert_lte(right, float(width) + 1.0,
			"%d règles sur %d px : une règle sort par la droite (%.0f > %d)" % [
				rule_count, width, right, width])
		assert_lte(bottom, panel.position.y + panel.size.y + 1.0,
			"%d règles sur %d px : une règle sort du tiroir par le bas" % [
				rule_count, width])

func test_the_rule_drawer_never_overflows_a_narrow_screen() -> void:
	# Assertion HORS boucle : sans elle, le jour où la plage se viderait, le
	# test cesserait d'asserter sans rien dire (hygiène de suite, décision 168).
	var counts: Array[int] = [1, 2, 3, 4, 5, 6]
	assert_eq(counts.size(), 6, "le balayage doit couvrir une à six règles")
	for n in counts:
		await _assert_chips_fit(720, n)

func test_the_swarm_never_slides_under_the_bars_on_a_tall_screen() -> void:
	await _assert_grid_clears_the_bars(Vector2i(1080, 2400))

func test_the_swarm_never_slides_under_the_bars_on_a_short_screen() -> void:
	# Le ratio court est le cas qui casse : la grille y est limitée en HAUTEUR,
	# donc c'est là que le cadrage doit vraiment travailler.
	await _assert_grid_clears_the_bars(Vector2i(1080, 1920))

## AUCUN ÉCRAN NE DÉBORDE DE L'ÉCRAN LE PLUS ÉTROIT.
##
## POURQUOI CE TEST GÉNÉRAL EXISTE. L'échelle typographique est passée à 1,35
## le 15 août 2026 — les textes étaient illisibles sur l'appareil. Le sélecteur
## de niveaux s'est alors mis à déborder par la droite : un libellé de tuile
## sans troncature impose sa largeur ENTIÈRE comme minimum, et pousse la colonne
## au-delà du viewport. Le bouton « Retour » se retrouvait décalé hors de l'axe,
## et les pastilles de défi coupées.
##
## Un test par écran aurait laissé passer le suivant. Celui-ci parcourt l'arbre
## de CHAQUE écran et refuse tout contrôle dont le bord droit dépasse — c'est la
## même leçon que la liste d'écrans découverte au lieu d'être écrite à la main.
const NARROW := Vector2i(720, 1440)

func _widest_offender(root: Control, limit: float) -> String:
	var worst := ""
	var worst_x := limit
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is Control) or node == root:
			continue
		var c := node as Control
		if not c.visible:
			continue
		var right: float = c.global_position.x + c.size.x
		if right > worst_x + 1.0:
			worst_x = right
			worst = "%s (%s) : bord droit %.0f > %.0f" % [
				c.name, c.get_class(), right, limit]
	return worst

func _assert_no_overflow(screen: Control, label: String) -> void:
	await _settle()
	await _settle()
	var offender := _widest_offender(screen, float(NARROW.x))
	assert_eq(offender, "",
		("%s déborde de l'écran étroit (%d de large) : %s. Un contrôle qui "
		+ "impose sa largeur entière comme minimum pousse toute la colonne, et "
		+ "ce qui sort de l'écran devient injouable ET invisible.")
		% [label, NARROW.x, offender])

func _narrow_host() -> SubViewport:
	var sub := SubViewport.new()
	sub.size = NARROW
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(sub)
	return sub

func test_no_screen_overflows_a_narrow_viewport() -> void:
	var progress := Progress.new()
	progress.record_win("ch1_01", 15, 0)
	progress.record_win("ch1_02", 29, 0)
	progress.record_challenges("ch1_02", PackedStringArray([
		"Économie — résolu avec 2 règles", "Efficience — 29 ticks, seuil 29"]))

	var checked := 0

	var menu := MenuScreen.new()
	_narrow_host().add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.setup(progress, Session.new())
	await _assert_no_overflow(menu, "MenuScreen")
	checked += 1

	var select := LevelSelectScreen.new()
	_narrow_host().add_child(select)
	select.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select.setup(progress)
	await _assert_no_overflow(select, "LevelSelectScreen")
	checked += 1

	var summary := SummaryScreen.new()
	_narrow_host().add_child(summary)
	summary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	summary.setup("ch1_02", true, 29, 0,
		[RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT],
		"La nuée a rempli l'objectif.")
	await _assert_no_overflow(summary, "SummaryScreen")
	checked += 1

	var settings := SettingsScreen.new()
	_narrow_host().add_child(settings)
	settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.setup(Settings.new())
	await _assert_no_overflow(settings, "SettingsScreen")
	checked += 1

	# Assertion HORS boucle : quatre écrans doivent avoir été examinés.
	assert_eq(checked, 4, "quatre écrans doivent être examinés")
