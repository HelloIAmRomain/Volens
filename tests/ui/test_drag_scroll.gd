extends GutTest
## LE DOIGT DÉFILE PARTOUT, Y COMPRIS POSÉ SUR UNE TUILE.
##
## POURQUOI CE FICHIER EXISTE. « Je ne peux pas scroller n'importe où. Si j'ai
## le doigt sur un niveau — la plupart de l'écran — alors le scroll ne
## fonctionne pas. Il fonctionne uniquement entre les niveaux ou sur le titre de
## chapitre. » (essai sur l'appareil, 15 août 2026)
##
## Les tuiles sont des `Button`, et un bouton CAPTE le doigt : il reçoit
## l'appui, puis les glissements, et les ignore. Le `ScrollContainer` ne voyait
## jamais rien. Les seules zones qui défilaient étaient les gouttières entre
## deux tuiles — l'espace vide, soit exactement ce que personne ne vise.
##
## LE TEST PORTE SUR LE GESTE, pas sur le composant : il simule un appui posé
## SUR une tuile, un glissement, puis un relâchement, et exige les deux
## propriétés qui font le comportement — **la liste défile**, et **le niveau
## sous le doigt ne s'ouvre pas**. La seconde est la moitié qu'on oublie : sans
## elle, faire défiler lancerait une partie au hasard.

const NARROW := Vector2i(1080, 1400)

func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _screen() -> LevelSelectScreen:
	var sub := SubViewport.new()
	sub.size = NARROW
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(sub)
	var screen := LevelSelectScreen.new()
	sub.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var progress := Progress.new()
	for i in range(LevelCatalog.count()):
		progress.record_win(String(LevelCatalog.entry(i)["id"]), 20, 0)
	screen.setup(progress)
	return screen

## Le centre d'une tuile VISIBLE, c'est-à-dire l'endroit que le pouce vise
## vraiment. Prendre la première tuile venue ne suffit pas : la liste déborde de
## l'écran, et une tuile défilée hors champ a un centre HORS du conteneur — le
## geste y serait ignoré à juste titre, et le test échouerait en accusant le
## composant d'un défaut qu'il n'a pas.
func _a_tile_centre(screen: Control, scroll: ScrollContainer) -> Vector2:
	var view := scroll.get_global_rect()
	var stack: Array[Node] = [screen]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is Button) or (node as Button).size.x <= 200.0:
			continue
		var centre: Vector2 = (node as Button).get_global_rect().get_center()
		if view.has_point(centre):
			return centre
	return Vector2.ZERO

func _press(drag: DragScroll, at: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.pressed = true
	e.position = at
	drag._input(e)

func _move(drag: DragScroll, to: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.position = to
	drag._input(e)

func _release(drag: DragScroll, at: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.pressed = false
	e.position = at
	drag._input(e)

func test_a_drag_started_on_a_tile_scrolls_the_list() -> void:
	var screen := _screen()
	await _settle()
	await _settle()
	var drag: DragScroll = screen._drag
	assert_not_null(drag, "le sélecteur doit porter un défilement au doigt")
	var scroll: ScrollContainer = drag._scroll
	assert_gt(scroll.get_v_scroll_bar().max_value, float(scroll.size.y),
		"la liste doit être plus haute que l'écran, sinon le test ne prouve rien")

	var tile := _a_tile_centre(screen, scroll)
	assert_gt(tile.length(), 0.0, "aucune tuile visible trouvée : le balayage est cassé")
	var before: int = scroll.scroll_vertical

	_press(drag, tile)
	_move(drag, tile - Vector2(0, 300))
	assert_gt(scroll.scroll_vertical, before,
		("Le doigt posé SUR une tuile ne fait pas défiler : c'est le défaut "
		+ "d'origine, et il rend la majorité de l'écran inerte."))
	_release(drag, tile - Vector2(0, 300))

func test_a_drag_does_not_open_the_level_under_the_finger() -> void:
	var screen := _screen()
	await _settle()
	await _settle()
	var drag: DragScroll = screen._drag
	var opened: Array[String] = []
	screen.level_chosen.connect(func(id: String) -> void: opened.append(id))

	var tile := _a_tile_centre(screen, drag._scroll)
	_press(drag, tile)
	_move(drag, tile - Vector2(0, 300))
	_release(drag, tile - Vector2(0, 300))
	assert_true(drag.consumed_drag(),
		"un glissement franc doit être reconnu comme tel")
	assert_eq(opened, ([] as Array[String]),
		("Faire défiler a ouvert un niveau : le relâchement qui termine un "
		+ "glissement ne doit jamais valoir un appui."))

func test_a_tap_without_movement_still_opens_the_level() -> void:
	# L'AUTRE BORD. Un seuil trop bas transformerait le moindre tremblement de
	# pouce en défilement, et le sélecteur cesserait de répondre aux appuis.
	var screen := _screen()
	await _settle()
	await _settle()
	var drag: DragScroll = screen._drag
	var tile := _a_tile_centre(screen, drag._scroll)
	_press(drag, tile)
	_move(drag, tile + Vector2(0, 2))
	_release(drag, tile + Vector2(0, 2))
	assert_false(drag.consumed_drag(),
		("Deux pixels de tremblement ont été pris pour un défilement : le "
		+ "seuil est trop bas, et plus aucun appui ne passerait."))

## --- Le doigt parle deux fois, et c'est ce qui cassait la fluidité -----------
##
## Signalé à l'essai : « parfois le scroll se bloque, ça s'arrête net, mais
## seulement à certains moments ». Trois causes, toutes trouvées sur l'appareil,
## et la principale est la même que celle qui dédoublait les légendes.
##
## ANDROID ÉMET DEUX ÉVÈNEMENTS POUR UN SEUL MOUVEMENT : un `ScreenDrag` et un
## `MouseMotion` émulé, portant la MÊME position. Le premier calculait la vitesse
## correctement ; le second, avec un déplacement nul, la remettait à ZÉRO. La
## vitesse rendue à la liste au relâchement était celle du dernier évènement
## reçu — et le « parfois » venait de l'ordre d'arrivée, qui n'est pas garanti.

func _drag_scroll() -> DragScroll:
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(400, 800)
	add_child_autofree(scroll)
	return DragScroll.attach(scroll)

func test_the_container_no_longer_scrolls_by_itself() -> void:
	# Sans cela, deux systèmes écrivent `scroll_vertical` dans la même image :
	# le nôtre en absolu, celui du conteneur en relatif.
	var d := _drag_scroll()
	assert_gt(d._scroll.scroll_deadzone, 10000,
		("le défilement propre du conteneur doit être neutralisé : un seul "
		+ "propriétaire du défilement, sinon l'ordre décide et il n'est pas garanti"))

func test_an_emulated_mouse_event_cannot_kill_the_inertia() -> void:
	var d := _drag_scroll()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(100, 400)
	d._input(touch)

	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(100, 300)
	d._input(drag)
	var after_real: float = d._velocity

	# LE DOUBLON ÉMULÉ, avec la MÊME position : il ne doit plus rien changer.
	var ghost := InputEventMouseMotion.new()
	ghost.position = Vector2(100, 300)
	ghost.button_mask = MOUSE_BUTTON_MASK_LEFT
	d._input(ghost)

	assert_eq(d._velocity, after_real,
		("un évènement souris ÉMULÉ ne doit plus toucher à la vitesse une fois "
		+ "le tactile vu — c'est lui qui remettait l'élan à zéro"))

func test_the_desktop_path_still_works() -> void:
	# L'AUTRE BORD : sans évènement tactile, la souris doit continuer de faire
	# défiler. C'est au poste de travail que se font les captures et les tests,
	# et un défilement qui n'y marcherait plus ne serait vérifiable nulle part.
	var d := _drag_scroll()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100, 400)
	d._input(press)
	assert_true(d._touching, "un appui souris doit ouvrir le geste hors appareil")
