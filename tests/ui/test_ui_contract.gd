extends GutTest
## Contrat de l'écran de jeu : cibles tactiles, composition de la pile par
## les DEUX chemins, et discrimination des gestes.
##
## Ces tests existent parce qu'une cible trop petite ou un geste ambigu ne se
## voient pas sur un écran d'ordinateur — ils se découvrent dans le bus, une
## main occupée.

const LEVEL_PATH := "res://data/levels/ch1_02.json"

var _screen: GameScreen

func before_each() -> void:
	var level: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEVEL_PATH))
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_screen = GameScreen.new()
	add_child_autofree(_screen)
	_screen.load_level(level, RuleParams.from_dict(rules), "ch1_02")

## Chemin sans glissement, en deux gestes : c'est le chemin PRINCIPAL.
func _pick_then_place(rule_id: int, slot: int) -> void:
	_screen._on_chip_tapped(rule_id)
	_screen._on_slot_tapped(slot)

func _collect(node: Node, wanted: String, out: Array) -> void:
	for child in node.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == wanted:
			out.append(child)
		_collect(child, wanted, out)

# --- ENF-01 : cibles tactiles ---------------------------------------------

func test_every_touch_target_meets_the_minimum_size() -> void:
	var controls: Array = []
	_all_targets(_screen, controls)
	assert_gt(controls.size(), 0)
	for c in controls:
		var target: Control = c
		assert_gte(target.custom_minimum_size.x, UiMetrics.MIN_TOUCH_TARGET,
			"%s : largeur sous le minimum ENF-01" % target.get_class())
		assert_gte(target.custom_minimum_size.y, UiMetrics.MIN_TOUCH_TARGET,
			"%s : hauteur sous le minimum ENF-01" % target.get_class())

func _all_targets(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			if (c is Button or c is RuleSlot or c is RuleChip) and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				out.append(c)
		_all_targets(child, out)

func test_the_stack_has_exactly_four_slots() -> void:
	var slots: Array = []
	_collect(_screen, "RuleSlot", slots)
	assert_eq(slots.size(), UiMetrics.SLOT_COUNT, "RG-05 : quatre emplacements, ni plus ni moins")

# --- le chemin sans glissement, dans ses quatre usages --------------------

func test_pick_then_place_puts_a_rule_in_a_slot() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	assert_eq(_screen._stack[0], RuleRegistry.R01_TOWARD_LIGHT)
	assert_eq(_screen._compact_stack(), [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])

func test_pick_then_place_swaps_two_occupied_slots() -> void:
	# L'ÉCHANGE est l'action la plus fréquente après poser : tout le jeu
	# tient à l'ordre de la pile.
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)

	_screen._on_slot_tapped(0)   # sélectionne la règle de l'emplacement 0
	_screen._on_slot_tapped(1)   # la destine à l'emplacement 1 -> échange

	assert_eq(_screen._stack[0], RuleRegistry.R02_FLEE_DANGER)
	assert_eq(_screen._stack[1], RuleRegistry.R01_TOWARD_LIGHT)

func test_pick_then_place_moves_a_rule_to_an_empty_slot() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_screen._on_slot_tapped(0)
	_screen._on_slot_tapped(2)

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)
	assert_eq(_screen._stack[2], RuleRegistry.R01_TOWARD_LIGHT)

func test_the_remove_chip_empties_a_slot_without_dragging() -> void:
	# ENF-25 : aucune action ne doit avoir le glissement pour seul chemin.
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.EMPTY, 0)

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)

func test_a_rule_never_occupies_two_slots() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 2)

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)
	assert_eq(_screen._stack[2], RuleRegistry.R01_TOWARD_LIGHT)
	assert_eq(_screen._compact_stack().size(), 1)

# --- la sélection : visible, et annulable ---------------------------------

func test_selection_is_marked_on_the_chip_and_cancellable() -> void:
	_screen._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	assert_true(_screen._has_selection)
	var marked := 0
	for chip in _screen._chips:
		if chip.selected:
			marked += 1
	assert_eq(marked, 1, "une sélection, et une seule, doit être marquée")

	_screen._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)  # re-appui = annule
	assert_false(_screen._has_selection)

func test_selecting_from_a_slot_marks_that_slot() -> void:
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	_screen._on_slot_tapped(1)

	assert_true(_screen._has_selection)
	assert_eq(_screen._selected_from, 1)
	assert_true(_screen._slots[1].selected)

# --- le glissement -------------------------------------------------------

func test_dragging_from_the_panel_places_a_rule() -> void:
	_screen._on_rule_dropped(2, RuleRegistry.R01_TOWARD_LIGHT, -1)
	assert_eq(_screen._stack[2], RuleRegistry.R01_TOWARD_LIGHT)

func test_dragging_between_slots_swaps_them() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	_screen._on_rule_dropped(1, RuleRegistry.R01_TOWARD_LIGHT, 0)

	assert_eq(_screen._stack[0], RuleRegistry.R02_FLEE_DANGER)
	assert_eq(_screen._stack[1], RuleRegistry.R01_TOWARD_LIGHT)

func test_dropping_a_slot_outside_removes_the_rule() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	assert_true(_screen._can_drop_data(Vector2.ZERO, {"rule_id": RuleRegistry.R01_TOWARD_LIGHT, "from_slot": 0}))
	_screen._drop_data(Vector2.ZERO, {"rule_id": RuleRegistry.R01_TOWARD_LIGHT, "from_slot": 0})

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)

func test_a_drop_coming_from_the_panel_is_not_a_removal() -> void:
	# Sinon lâcher une règle à côté d'un emplacement viderait la pile.
	assert_false(_screen._can_drop_data(Vector2.ZERO, {"rule_id": RuleRegistry.R01_TOWARD_LIGHT, "from_slot": -1}))

# --- RG-10 et RG-17 -------------------------------------------------------

func test_changing_the_stack_restarts_the_trial() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	for i in range(5):
		_screen._view.step_forward()
	assert_gt(_screen._view.current_state().tick, 0)

	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	assert_eq(_screen._view.current_state().tick, 0, "l'essai repart de zéro")

func test_objective_line_reports_live_progress() -> void:
	var line := RuleCatalog.objective_line(
		[{"type": "extraction", "percent": 100}], _screen._view.current_state())
	assert_string_contains(line, "sortis")
