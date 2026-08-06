class_name GameScreen
extends Control
## Écran de jeu (T-032, DCT §9.2). Assemble : bandeau d'objectif d'une ligne
## en haut (RG-17), grille au centre, **pile de 4 emplacements et transport
## dans la moitié basse** (ENF-01, zone du pouce), tiroir de bibliothèque
## coulissant depuis le bas — jamais un écran plein (P3).
##
## Modifier la pile réinitialise l'essai : la recette est (niveau, pile), et
## une pile figée pour la durée d'une session est ce que garantit
## `ReplaySession` (RG-10 — « modifier sa pile puis relancer »).
##
## HORS PÉRIMÈTRE de ce lot, signalé plutôt que bâclé :
## — EF-05 (appui sur un agent → cascade de décision) attend `SimCore.explain`
##   (T-065, semaine 8) ; l'ossature d'appui est là, l'affichage non ;
## — retour haptique (ENF-24), audio, sauvegarde, écrans d'accueil/bilan.

const SPEEDS: Array[float] = [1.0, 2.0, 4.0, 8.0]

var _view: SimView
var _view_host: SubViewportContainer
var _viewport: SubViewport
var _objective_label: Label
var _slots: Array[RuleSlot] = []
var _chips: Array[RuleChip] = []
var _drawer: PanelContainer
var _drawer_open: bool = false
var _play_button: Button
var _speed_button: Button

var _level_data: Dictionary = {}
var _params: RuleParams
var _allowed: Array[int] = []
var _stack: Array[int] = []
var _selected_rule: int = RuleRegistry.EMPTY
var _playing: bool = false
var _speed_index: int = 1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(ViewPalette.BACKGROUND)
	_build()
	get_viewport().size_changed.connect(_layout)

func load_level(level_data: Dictionary, params: RuleParams) -> void:
	_level_data = level_data
	_params = params
	_allowed = []
	for v in level_data.get("allowed_rules", [1]):
		_allowed.append(int(v))
	_stack = []
	for i in range(UiMetrics.SLOT_COUNT):
		_stack.append(RuleRegistry.EMPTY)
	_build_chips()
	_apply_stack()

# --- construction -------------------------------------------------------------

func _build() -> void:
	# Bandeau d'objectif — une ligne, toujours visible (RG-17).
	_objective_label = Label.new()
	_objective_label.add_theme_font_size_override("font_size", 30)
	_objective_label.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_objective_label)

	# La simulation vit dans un SubViewport : la vue garde ses coordonnées
	# propres et ne dépend pas de la taille de l'écran de jeu.
	_view_host = SubViewportContainer.new()
	_view_host.stretch = true
	_view_host.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_view_host)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view_host.add_child(_viewport)
	# Avec `stretch`, le conteneur dimensionne lui-même le sous-viewport :
	# on écoute son redimensionnement au lieu de le forcer.
	_viewport.size_changed.connect(_on_sim_viewport_resized)
	_view = SimView.new()
	_viewport.add_child(_view)

	_build_stack_bar()
	_build_transport()
	_build_drawer()
	_layout()

func _build_stack_bar() -> void:
	var row := HBoxContainer.new()
	row.name = "StackBar"
	row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(row)
	for i in range(UiMetrics.SLOT_COUNT):
		var slot := RuleSlot.new(i)
		slot.rule_dropped.connect(_on_rule_dropped)
		slot.slot_tapped.connect(_on_slot_tapped)
		row.add_child(slot)
		_slots.append(slot)

func _build_transport() -> void:
	var row := HBoxContainer.new()
	row.name = "TransportBar"
	row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(row)

	_play_button = _make_button("▶", "Marche / pause")
	_play_button.pressed.connect(_toggle_play)
	row.add_child(_play_button)

	var back := _make_button("◀|", "Un tick en arrière")
	back.pressed.connect(func() -> void: _playing = false; _view.step_backward(); _refresh_transport())
	row.add_child(back)

	var forward := _make_button("|▶", "Un tick en avant")
	forward.pressed.connect(func() -> void: _playing = false; _view.step_forward(); _refresh_transport())
	row.add_child(forward)

	_speed_button = _make_button("×2", "Vitesse de lecture")
	_speed_button.pressed.connect(_cycle_speed)
	row.add_child(_speed_button)

	var reset := _make_button("↺", "Réinitialiser l'essai (EF-04)")
	reset.pressed.connect(func() -> void: _playing = false; _view.reset(); _refresh_transport())
	row.add_child(reset)

	var library := _make_button("＋", "Bibliothèque de règles")
	library.pressed.connect(_toggle_drawer)
	row.add_child(library)

func _make_button(text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 34)
	return b

func _build_drawer() -> void:
	_drawer = PanelContainer.new()
	_drawer.name = "RuleDrawer"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.border_width_top = 2
	style.border_color = Color(0.25, 0.28, 0.36)
	_drawer.add_theme_stylebox_override("panel", style)
	_drawer.visible = false
	add_child(_drawer)

	var row := HBoxContainer.new()
	row.name = "ChipRow"
	row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_drawer.add_child(row)

func _build_chips() -> void:
	var row := _drawer.get_node("ChipRow") as HBoxContainer
	for child in row.get_children():
		child.queue_free()
	_chips = []
	for rule_id in _allowed:
		var chip := RuleChip.new(rule_id)
		chip.chip_tapped.connect(_on_chip_tapped)
		row.add_child(chip)
		_chips.append(chip)

# --- disposition ---------------------------------------------------------------

func _on_sim_viewport_resized() -> void:
	if _view != null:
		_view._on_viewport_resized()

func _layout() -> void:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	var left: float = m.x
	var top: float = m.y
	var right: float = vp.x - m.z
	var bottom: float = vp.y - m.w
	var width: float = right - left

	if _objective_label != null:
		_objective_label.position = Vector2(left, top)
		_objective_label.size = Vector2(width, 44)

	# Moitié basse : transport en bas, pile juste au-dessus (ENF-01).
	var transport := get_node_or_null("TransportBar") as HBoxContainer
	var stack_bar := get_node_or_null("StackBar") as HBoxContainer
	var transport_h := UiMetrics.MIN_TOUCH_TARGET
	var stack_h := UiMetrics.MIN_TOUCH_TARGET * 1.25
	if transport != null:
		transport.position = Vector2(left, bottom - transport_h)
		transport.size = Vector2(width, transport_h)
	if stack_bar != null:
		stack_bar.position = Vector2(left, bottom - transport_h - UiMetrics.GAP - stack_h)
		stack_bar.size = Vector2(width, stack_h)

	# La grille prend tout ce qui reste au-dessus de la zone du pouce.
	var view_top: float = top + 44 + UiMetrics.GAP
	var view_bottom: float = bottom - transport_h - UiMetrics.GAP - stack_h - UiMetrics.GAP
	if _view_host != null:
		_view_host.position = Vector2(left, view_top)
		_view_host.size = Vector2(width, maxf(view_bottom - view_top, 100.0))

	if _drawer != null:
		var drawer_h := UiMetrics.MIN_TOUCH_TARGET + UiMetrics.MARGIN * 2.0
		_drawer.position = Vector2(left, bottom - transport_h - UiMetrics.GAP - stack_h - UiMetrics.GAP - drawer_h)
		_drawer.size = Vector2(width, drawer_h)

# --- pile ------------------------------------------------------------------------

## Pile compacte : les emplacements vides sont retirés avant d'être transmis
## à la simulation (la cascade les saute de toute façon, mais la forme
## compacte est la forme canonique — cf. StackEnumerator).
func _compact_stack() -> Array[int]:
	var out: Array[int] = []
	for rule_id in _stack:
		if rule_id != RuleRegistry.EMPTY:
			out.append(rule_id)
	return out

func _apply_stack() -> void:
	for i in range(_slots.size()):
		_slots[i].set_rule(_stack[i])
	if _view != null and not _level_data.is_empty():
		_view.load_level(_level_data, _params, _compact_stack())
	_playing = false
	_refresh_transport()

## Une règle ne peut occuper qu'un seul emplacement : la placer ailleurs la
## déplace, elle ne la duplique pas (l'espace des piles est fait
## d'arrangements SANS répétition — cf. StackEnumerator).
func _place(rule_id: int, target_slot: int) -> void:
	if target_slot < 0 or target_slot >= _stack.size():
		return
	var previous: int = _stack[target_slot]
	for i in range(_stack.size()):
		if i != target_slot and _stack[i] == rule_id:
			_stack[i] = previous  # échange si la règle venait d'un autre emplacement
			previous = RuleRegistry.EMPTY
	_stack[target_slot] = rule_id
	_apply_stack()

func _on_rule_dropped(slot_index: int, rule_id: int) -> void:
	_place(rule_id, slot_index)
	_clear_selection()

## Équivalent sans glissement (ENF-25) : appui sur une règle, puis appui sur
## l'emplacement. Appuyer sur un emplacement occupé sans sélection le vide.
func _on_chip_tapped(rule_id: int) -> void:
	_selected_rule = RuleRegistry.EMPTY if _selected_rule == rule_id else rule_id
	for chip in _chips:
		chip.selected = chip.rule_id == _selected_rule

func _on_slot_tapped(slot_index: int) -> void:
	if _selected_rule != RuleRegistry.EMPTY:
		_place(_selected_rule, slot_index)
		_clear_selection()
	elif _stack[slot_index] != RuleRegistry.EMPTY:
		_stack[slot_index] = RuleRegistry.EMPTY
		_apply_stack()

func _clear_selection() -> void:
	_selected_rule = RuleRegistry.EMPTY
	for chip in _chips:
		chip.selected = false

func _toggle_drawer() -> void:
	_drawer_open = not _drawer_open
	_drawer.visible = _drawer_open
	if not _drawer_open:
		_clear_selection()

# --- transport --------------------------------------------------------------------

func _toggle_play() -> void:
	_playing = not _playing
	_refresh_transport()

func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_refresh_transport()

func _refresh_transport() -> void:
	if _play_button != null:
		_play_button.text = "❚❚" if _playing else "▶"
	if _speed_button != null:
		_speed_button.text = "×%d" % int(SPEEDS[_speed_index])

func _process(delta: float) -> void:
	if _view == null or _view.current_state() == null:
		return
	if _playing:
		_view.advance(delta, SPEEDS[_speed_index])
	if _objective_label != null:
		_objective_label.text = RuleCatalog.objective_line(
			_level_data.get("objectives", []), _view.current_state())
