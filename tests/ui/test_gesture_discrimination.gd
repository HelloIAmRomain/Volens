extends GutTest
## Discrimination des gestes sur un même appui maintenu — c'est là que ce
## genre d'interface casse.
##
##   appui bref sans mouvement      → sélection
##   appui maintenu sans mouvement  → explication
##   appui puis mouvement           → glissement (le mouvement l'emporte)

var _target: RuleChip
var _taps: int = 0
var _longs: int = 0

func before_each() -> void:
	_target = RuleChip.new(RuleRegistry.R01_TOWARD_LIGHT)
	_target.size = Vector2(300, 150)
	add_child_autofree(_target)
	_taps = 0
	_longs = 0
	_target.tapped.connect(func() -> void: _taps += 1)
	_target.long_pressed.connect(func() -> void: _longs += 1)

func _press(at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	_target._gui_input(e)

func _release(at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = at
	_target._gui_input(e)

func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	_target._gui_input(e)

func test_a_short_press_without_movement_selects() -> void:
	_press(Vector2(10, 10))
	_target._process(0.1)
	_release(Vector2(10, 10))

	assert_eq(_taps, 1, "appui bref = sélection")
	assert_eq(_longs, 0)

func test_holding_without_movement_explains() -> void:
	_press(Vector2(10, 10))
	_target._process(UiMetrics.LONG_PRESS_SECONDS + 0.01)

	assert_eq(_longs, 1, "appui maintenu = explication")
	assert_eq(_taps, 0)

func test_the_long_press_does_not_also_select_on_release() -> void:
	# Sinon relâcher après une explication poserait la règle par surprise.
	_press(Vector2(10, 10))
	_target._process(UiMetrics.LONG_PRESS_SECONDS + 0.01)
	_release(Vector2(10, 10))

	assert_eq(_longs, 1)
	assert_eq(_taps, 0)

func test_movement_beyond_the_threshold_cancels_both() -> void:
	# Le mouvement l'emporte TOUJOURS : un glissement commencé lentement ne
	# doit pas déclencher une explication en cours de route.
	_press(Vector2(10, 10))
	_move(Vector2(10 + UiMetrics.DRAG_THRESHOLD + 2.0, 10))
	_target._process(UiMetrics.LONG_PRESS_SECONDS + 0.01)
	_release(Vector2(60, 10))

	assert_eq(_taps, 0, "un glissement ne sélectionne pas")
	assert_eq(_longs, 0, "un glissement n'explique pas")

func test_a_small_tremble_below_the_threshold_still_selects() -> void:
	# Une main dans un bus tremble : le seuil doit l'absorber.
	_press(Vector2(10, 10))
	_move(Vector2(10 + UiMetrics.DRAG_THRESHOLD - 4.0, 12))
	_target._process(0.1)
	_release(Vector2(10, 12))

	assert_eq(_taps, 1, "le tremblement sous le seuil reste une sélection")

func test_starting_a_drag_cancels_the_pending_press() -> void:
	_press(Vector2(10, 10))
	var payload: Variant = _target._get_drag_data(Vector2(10, 10))
	assert_not_null(payload, "une pastille de règle est glissable")
	_release(Vector2(80, 40))

	assert_eq(_taps, 0, "le glissement a consommé l'appui")

func test_the_remove_chip_is_not_draggable() -> void:
	var remover := RuleChip.new(RuleRegistry.EMPTY)
	add_child_autofree(remover)
	assert_null(remover._get_drag_data(Vector2.ZERO), "on ne traîne pas un vide sur la grille")
