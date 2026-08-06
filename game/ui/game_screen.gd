class_name GameScreen
extends Control
## Écran de jeu (T-032, DCT §9.2). Bandeau d'objectif d'une ligne en haut
## (RG-17), grille au centre, **pile de 4 emplacements et transport dans la
## moitié basse** (ENF-01, zone du pouce), tiroir de bibliothèque coulissant
## — jamais un écran plein (P3).
##
## Modifier la pile réinitialise l'essai : la recette est (niveau, pile), et
## `ReplaySession` fige la pile pour la durée d'une session (RG-10).
##
## EF-05 : en pause, toucher un agent affiche quelle règle a dicté son
## dernier mouvement et pourquoi les précédentes ne s'appliquaient pas.

signal finished(level_id: String, won: bool, ticks: int, lost: int, stack: Array)
signal quit_requested
signal state_changed

const SPEEDS: Array[float] = [1.0, 2.0, 4.0, 8.0]

var _view: SimView
var _view_host: SubViewportContainer
var _viewport: SubViewport
var _objective_label: Label
var _slots: Array[RuleSlot] = []
var _chips: Array[RuleChip] = []
var _drawer: PanelContainer
var _explain_panel: PanelContainer
var _explain_label: Label
var _play_button: Button
var _speed_button: Button

var _level_data: Dictionary = {}
var _level_id: String = ""
var _params: RuleParams
var _allowed: Array[int] = []
var _stack: Array[int] = []
var _selected_rule: int = RuleRegistry.EMPTY
var _playing: bool = false
var _speed_index: int = 1
var _finished: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	get_viewport().size_changed.connect(_layout)

func load_level(level_data: Dictionary, params: RuleParams, level_id: String = "") -> void:
	_level_data = level_data
	_level_id = level_id
	_params = params
	_finished = false
	_allowed = []
	for v in level_data.get("allowed_rules", [1]):
		_allowed.append(int(v))
	_stack = []
	for i in range(UiMetrics.SLOT_COUNT):
		_stack.append(RuleRegistry.EMPTY)
	_build_chips()
	_apply_stack()

# --- reprise (EF-20/21) ---------------------------------------------------------

func store_session(session: Session) -> void:
	session.level_id = _level_id
	session.stack = _compact_stack()
	session.tick = _view.current_state().tick if _view != null and _view.current_state() != null else 0
	session.speed_index = _speed_index

## Restaure l'essai exact : la pile, puis le tick, par re-simulation
## déterministe. **Toujours en pause** — on ne reprend jamais une simulation
## en marche dans la main de quelqu'un qui vient d'ouvrir l'application.
func restore_session(session: Session) -> void:
	# Le tick et la vitesse sont LUS D'ABORD : `_apply_stack()` émet
	# `state_changed`, que l'application relaie vers la sauvegarde de
	# session — laquelle réécrirait `session.tick` avec le tick courant
	# (zéro) avant qu'on ait eu le temps de s'en servir.
	var target_tick: int = session.tick
	var target_speed: int = session.speed_index

	for i in range(mini(session.stack.size(), UiMetrics.SLOT_COUNT)):
		_stack[i] = session.stack[i]
	_apply_stack()
	if target_tick > 0:
		_view.seek(target_tick)
	_speed_index = clampi(target_speed, 0, SPEEDS.size() - 1)
	_playing = false
	_refresh_transport()

func set_speed_index(index: int) -> void:
	_speed_index = clampi(index, 0, SPEEDS.size() - 1)
	_refresh_transport()

# --- construction -----------------------------------------------------------------

func _build() -> void:
	_objective_label = Label.new()
	_objective_label.add_theme_font_size_override("font_size", 28)
	_objective_label.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_objective_label)

	_view_host = SubViewportContainer.new()
	_view_host.stretch = true
	_view_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_view_host.gui_input.connect(_on_view_input)
	add_child(_view_host)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view_host.add_child(_viewport)
	_viewport.size_changed.connect(func() -> void: if _view != null: _view._on_viewport_resized())
	_view = SimView.new()
	_viewport.add_child(_view)

	_build_stack_bar()
	_build_transport()
	_build_drawer()
	_build_explain_panel()
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
	back.pressed.connect(func() -> void: _pause(); _view.step_backward(); _notify_state())
	row.add_child(back)

	var forward := _make_button("|▶", "Un tick en avant")
	forward.pressed.connect(func() -> void: _pause(); _view.step_forward(); _notify_state())
	row.add_child(forward)

	_speed_button = _make_button("×2", "Vitesse de lecture")
	_speed_button.pressed.connect(_cycle_speed)
	row.add_child(_speed_button)

	var reset := _make_button("↺", "Réinitialiser l'essai")
	reset.pressed.connect(func() -> void: _pause(); _view.reset(); _hide_explain(); _notify_state())
	row.add_child(reset)

	var library := _make_button("＋", "Bibliothèque de règles")
	library.pressed.connect(_toggle_drawer)
	row.add_child(library)

	var quit := _make_button("✕", "Retour aux niveaux")
	quit.pressed.connect(func() -> void: quit_requested.emit())
	row.add_child(quit)

func _make_button(text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 30)
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

func _build_explain_panel() -> void:
	_explain_panel = PanelContainer.new()
	_explain_panel.name = "ExplainPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.96)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.85, 1.0, 0.8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_explain_panel.add_theme_stylebox_override("panel", style)
	_explain_panel.visible = false
	_explain_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_explain_panel)

	_explain_label = Label.new()
	_explain_label.add_theme_font_size_override("font_size", 24)
	_explain_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	_explain_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explain_panel.add_child(_explain_label)

# --- EF-05 : le diagnostic ---------------------------------------------------------

## En pause uniquement : en marche, le tableau change trop vite pour être lu,
## et l'agent touché n'est déjà plus là où le doigt s'est posé.
func _on_view_input(event: InputEvent) -> void:
	var pressed := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pressed = (event as InputEventMouseButton).pressed
		pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
		pos = (event as InputEventScreenTouch).position
	else:
		return
	if not pressed:
		return
	if _playing:
		_pause()
		return
	_show_explain_at(pos)

func _show_explain_at(local_pos: Vector2) -> void:
	if _view == null or _view.current_state() == null:
		return
	var cell := _view.cell_at_pixel(local_pos)
	if cell.x < 0:
		_hide_explain()
		return
	var index := _view.agent_near(cell, 1)
	if index < 0:
		_hide_explain()
		return

	# La décision du dernier mouvement s'est prise sur l'état PRÉCÉDENT
	# (RG-07 : décisions sur cliché immuable). C'est donc lui qu'on interroge.
	var decision_state := _view.previous_state()
	var agent: AgentState = decision_state.agents[index]
	var report := RuleExplainer.explain(agent, decision_state, _compact_stack())
	var lines: Array = report["lines"]
	var note := RuleExplainer.movement_note(report["proposed"], _view.last_granted(index))
	if not note.is_empty():
		lines.append(note)

	_explain_label.text = "\n".join(PackedStringArray(lines))
	_explain_panel.visible = true
	_position_explain_panel()

func _position_explain_panel() -> void:
	# Ancré sous la grille, jamais par-dessus la nuée : le joueur doit voir
	# l'agent dont on lui parle.
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	_explain_panel.reset_size()
	var width: float = vp.x - m.x - m.z
	_explain_panel.position = Vector2(m.x, _view_host.position.y + _view_host.size.y - _explain_panel.size.y - UiMetrics.GAP)
	_explain_panel.size = Vector2(width, _explain_panel.size.y)

func _hide_explain() -> void:
	if _explain_panel != null:
		_explain_panel.visible = false

# --- disposition ---------------------------------------------------------------------

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
		_objective_label.size = Vector2(width, 42)

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

	var view_top: float = top + 42 + UiMetrics.GAP
	var view_bottom: float = bottom - transport_h - UiMetrics.GAP - stack_h - UiMetrics.GAP
	if _view_host != null:
		_view_host.position = Vector2(left, view_top)
		_view_host.size = Vector2(width, maxf(view_bottom - view_top, 100.0))

	if _drawer != null:
		var drawer_h := UiMetrics.MIN_TOUCH_TARGET + UiMetrics.MARGIN * 2.0
		_drawer.position = Vector2(left, bottom - transport_h - UiMetrics.GAP - stack_h - UiMetrics.GAP - drawer_h)
		_drawer.size = Vector2(width, drawer_h)

	if _explain_panel != null and _explain_panel.visible:
		_position_explain_panel()

# --- pile -------------------------------------------------------------------------------

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
	_pause()
	_hide_explain()
	_finished = false
	_refresh_transport()
	_notify_state()

## Une règle n'occupe jamais deux emplacements : l'espace des piles est fait
## d'arrangements SANS répétition, l'interface doit rendre impossible ce que
## l'énumérateur ne compte pas.
func _place(rule_id: int, target_slot: int) -> void:
	if target_slot < 0 or target_slot >= _stack.size():
		return
	var previous: int = _stack[target_slot]
	for i in range(_stack.size()):
		if i != target_slot and _stack[i] == rule_id:
			_stack[i] = previous
			previous = RuleRegistry.EMPTY
	_stack[target_slot] = rule_id
	_apply_stack()

func _on_rule_dropped(slot_index: int, rule_id: int) -> void:
	_place(rule_id, slot_index)
	_clear_selection()

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
	_drawer.visible = not _drawer.visible
	if not _drawer.visible:
		_clear_selection()

# --- transport ------------------------------------------------------------------------------

func _pause() -> void:
	_playing = false
	_refresh_transport()

func _toggle_play() -> void:
	_playing = not _playing
	if _playing:
		_hide_explain()
	_refresh_transport()
	_notify_state()

func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_refresh_transport()
	_notify_state()

func _refresh_transport() -> void:
	if _play_button != null:
		_play_button.text = "❚❚" if _playing else "▶"
	if _speed_button != null:
		_speed_button.text = "×%d" % int(SPEEDS[_speed_index])

func _notify_state() -> void:
	state_changed.emit()

func _process(delta: float) -> void:
	if _view == null or _view.current_state() == null:
		return
	if _playing:
		_view.advance(delta, SPEEDS[_speed_index])
	var state := _view.current_state()
	if _objective_label != null:
		_objective_label.text = RuleCatalog.objective_line(_level_data.get("objectives", []), state)
	if not _finished and state.outcome != SimState.Outcome.RUNNING:
		_finished = true
		_playing = false
		finished.emit(_level_id, state.outcome == SimState.Outcome.WON,
			state.tick, state.counters.lost, _compact_stack())
