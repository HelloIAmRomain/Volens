extends GutTest
## Test d'interface automatisé (DCT §9.2, ENF-01/ENF-25) : inspecte l'arbre
## de contrôles de l'écran de jeu. Ce test existe parce qu'une cible tactile
## trop petite ne se voit pas sur un écran d'ordinateur — elle se découvre
## dans le bus, une main occupée.

const LEVEL_PATH := "res://data/levels/ch1_01.json"

var _screen: GameScreen

func before_each() -> void:
	var level: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEVEL_PATH))
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_screen = GameScreen.new()
	add_child_autofree(_screen)
	_screen.load_level(level, RuleParams.from_dict(rules))

func _interactive_controls(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			# Un contrôle qui reçoit les appuis est une cible tactile.
			if (c is Button or c is RuleSlot or c is RuleChip) and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				out.append(c)
		_interactive_controls(child, out)

func test_every_touch_target_meets_the_minimum_size() -> void:
	var controls: Array = []
	_interactive_controls(_screen, controls)
	assert_gt(controls.size(), 0, "l'écran doit exposer des cibles tactiles")
	for c in controls:
		var target: Control = c
		assert_gte(target.custom_minimum_size.x, UiMetrics.MIN_TOUCH_TARGET,
			"%s : largeur sous le minimum ENF-01" % target.get_class())
		assert_gte(target.custom_minimum_size.y, UiMetrics.MIN_TOUCH_TARGET,
			"%s : hauteur sous le minimum ENF-01" % target.get_class())

func test_the_stack_has_exactly_four_slots() -> void:
	var slots: Array = []
	_collect(_screen, "RuleSlot", slots)
	assert_eq(slots.size(), UiMetrics.SLOT_COUNT, "RG-05 : quatre emplacements, ni plus ni moins")

func test_a_rule_can_be_placed_without_dragging() -> void:
	# ENF-25 : l'équivalent sans glissement est obligatoire, pas optionnel.
	_screen._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	_screen._on_slot_tapped(0)

	assert_eq(_screen._stack[0], RuleRegistry.R01_TOWARD_LIGHT)
	assert_eq(_screen._compact_stack(), [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])

func test_tapping_an_occupied_slot_empties_it() -> void:
	_screen._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	_screen._on_slot_tapped(0)
	_screen._on_slot_tapped(0)  # sans sélection : vide l'emplacement

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)

func test_a_rule_never_occupies_two_slots() -> void:
	# L'espace des piles est fait d'arrangements SANS répétition : placer
	# une règle déjà posée la DÉPLACE, elle ne la duplique jamais.
	_screen._place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_screen._place(RuleRegistry.R01_TOWARD_LIGHT, 2)

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)
	assert_eq(_screen._stack[2], RuleRegistry.R01_TOWARD_LIGHT)
	assert_eq(_screen._compact_stack().size(), 1)

func test_changing_the_stack_restarts_the_trial() -> void:
	# RG-10 : « modifier sa pile puis relancer ». La recette est
	# (niveau, pile) : une pile nouvelle est un essai nouveau.
	_screen._place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	for i in range(5):
		_screen._view.step_forward()
	assert_gt(_screen._view.current_state().tick, 0)

	_screen._place(RuleRegistry.R02_FLEE_DANGER, 1)
	assert_eq(_screen._view.current_state().tick, 0, "l'essai repart de zéro")

func test_objective_line_reports_live_progress() -> void:
	# RG-17 : l'avancement est visible en continu, pas seulement au bilan.
	var line := RuleCatalog.objective_line(
		[{"type": "extraction", "percent": 100}], _screen._view.current_state())
	assert_string_contains(line, "sortis")

func _collect(node: Node, class_wanted: String, out: Array) -> void:
	for child in node.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == class_wanted:
			out.append(child)
		_collect(child, class_wanted, out)
