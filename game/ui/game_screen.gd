class_name GameScreen
extends Control
## Écran de jeu [T-032, DCT §9.2].
##
## DISPOSITION, et l'arbitrage qui la décide. Le concepteur veut le transport
## en haut à droite et le bas réservé aux règles. ENF-01 exige que toute
## commande soit atteignable au pouce, et interdit les actions critiques dans
## le tiers supérieur. Les deux tiennent grâce à une mesure (UiMetrics) :
## sur 1080x2400, le tiers supérieur (y <= 720) est hors de portée en prise à
## une main sur un écran de 6,8 pouces. On y place donc les boutons de
## transport comme AFFORDANCE VISIBLE, et l'on garantit un **second chemin**
## dans la zone confortable : **un appui sur la grille bascule marche/pause**.
## Le bouton du haut n'est jamais requis — il montre l'état et sert à la
## souris ; le pouce, lui, touche la grille.
##
## Le bouton fermer va en HAUT À GAUCHE, à l'opposé du transport : fermer par
## erreur en cherchant pause serait le pire défaut de cet écran.
##
## Le rembobinage disparaît de l'interface, pas du code : `core/replay/`
## garde ses clichés-clés et sa remontée du temps (DT-11/12). C'est
## l'affordance qu'on retire, jamais la capacité.

signal finished(level_id: String, won: bool, ticks: int, lost: int, stack: Array)
signal quit_requested
signal state_changed

## ×1 → ×2 → ×3 → ×1 (RG-10 : « au moins trois vitesses »).
const SPEEDS: Array[float] = [1.0, 2.0, 3.0]
const SPEED_GLYPHS: Array[String] = ["▷", "▷▷", "▷▷▷"]

var _view: SimView
var _view_host: SubViewportContainer
var _viewport: SubViewport
var _objective_label: Label
var _slots: Array[RuleSlot] = []
var _chips: Array[RuleChip] = []
var _panel: PanelContainer
var _explain_panel: Panel
var _explain_label: Label
var _play_button: Button
var _speed_button: Button

var _level_data: Dictionary = {}
var _level_id: String = ""
var _params: RuleParams
var _allowed: Array[int] = []
var _stack: Array[int] = []
## Règle sélectionnée en attente de destination, et sa provenance :
## -1 = le panneau, >= 0 = l'emplacement d'où elle vient (pour l'échange).
var _selected_rule: int = RuleRegistry.EMPTY
var _selected_from: int = -1
var _has_selection: bool = false
var _playing: bool = false
var _speed_index: int = 0
var _finished: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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

# --- reprise (EF-20/21) ---------------------------------------------------

func store_session(session: Session) -> void:
	session.level_id = _level_id
	session.stack = _compact_stack()
	session.tick = _view.current_state().tick if _view != null and _view.current_state() != null else 0
	session.speed_index = _speed_index

func restore_session(session: Session) -> void:
	# Tick et vitesse lus D'ABORD : `_apply_stack()` émet `state_changed`,
	# que l'application relaie vers la sauvegarde — laquelle réécrirait
	# `session.tick` avec zéro avant qu'on s'en serve.
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

# --- construction ---------------------------------------------------------

func _build() -> void:
	# Barre haute gauche : quitter, puis réinitialiser (EF-04). Loin du
	# transport, exprès.
	var left_row := HBoxContainer.new()
	left_row.name = "LeftBar"
	left_row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(left_row)
	var quit := _make_button("✕", "Retour aux niveaux")
	quit.pressed.connect(func() -> void: quit_requested.emit())
	left_row.add_child(quit)
	var reset := _make_button("↺", "Réinitialiser l'essai")
	reset.pressed.connect(func() -> void: _pause(); _view.reset(); _hide_explain(); _notify_state())
	left_row.add_child(reset)

	# Barre haute droite : marche/pause et vitesse. Doublées par l'appui sur
	# la grille, donc jamais le seul chemin (ENF-01).
	var right_row := HBoxContainer.new()
	right_row.name = "RightBar"
	right_row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(right_row)
	_play_button = _make_button("▶", "Marche / pause — ou appui sur la grille")
	_play_button.pressed.connect(_toggle_play)
	right_row.add_child(_play_button)
	_speed_button = _make_button("▷", "Vitesse de lecture")
	_speed_button.pressed.connect(_cycle_speed)
	right_row.add_child(_speed_button)

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
	_build_panel()
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
		slot.tapped.connect(_on_slot_tapped.bind(i))
		slot.long_pressed.connect(_on_slot_long_pressed.bind(i))
		row.add_child(slot)
		_slots.append(slot)

func _make_button(text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	b.add_theme_font_size_override("font_size", 30)
	return b

func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "RulePanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.border_width_top = 2
	style.border_color = Color(0.25, 0.28, 0.36)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	add_child(_panel)

	var row := HBoxContainer.new()
	row.name = "ChipRow"
	row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(row)

func _build_chips() -> void:
	var row := _panel.get_node("ChipRow") as HBoxContainer
	for child in row.get_children():
		child.queue_free()
	_chips = []
	# « Retirer » en tête : c'est le chemin sans glissement pour vider un
	# emplacement (ENF-25).
	var ids: Array[int] = [RuleRegistry.EMPTY]
	ids.append_array(_allowed)
	for rule_id in ids:
		var chip := RuleChip.new(rule_id)
		chip.tapped.connect(_on_chip_tapped.bind(rule_id))
		chip.long_pressed.connect(_on_chip_long_pressed.bind(rule_id))
		row.add_child(chip)
		_chips.append(chip)

func _build_explain_panel() -> void:
	_explain_panel = Panel.new()
	_explain_panel.name = "ExplainPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.97)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = Color(0.35, 0.85, 1.0, 0.85)
	_explain_panel.add_theme_stylebox_override("panel", style)
	_explain_panel.visible = false
	_explain_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_explain_panel)

	_explain_label = Label.new()
	_explain_label.add_theme_font_size_override("font_size", 24)
	_explain_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	_explain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_explain_panel.add_child(_explain_label)

# --- composition de la pile : deux chemins équivalents ---------------------

## Glissement : panneau → emplacement (pose ou remplace), emplacement →
## emplacement (échange).
func _on_rule_dropped(slot_index: int, rule_id: int, from_slot: int) -> void:
	if from_slot >= 0:
		_swap_slots(from_slot, slot_index)
	else:
		_stack[slot_index] = rule_id
		_dedupe(slot_index)
		_apply_stack()
	_clear_selection()
	_close_panel()

## Glissement d'un emplacement vers l'extérieur : retire. C'est l'écran
## lui-même qui accueille la chute, à défaut d'une cible plus précise.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and int((data as Dictionary).get("from_slot", -1)) >= 0

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_slot := int((data as Dictionary)["from_slot"])
	_stack[from_slot] = RuleRegistry.EMPTY
	_apply_stack()
	_clear_selection()

## Chemin SANS GLISSEMENT (ENF-25), et chemin principal : un appui
## sélectionne, un appui destine. Il unifie poser, retirer, déplacer et
## échanger dans un seul geste — l'échange en particulier, qui est l'action
## la plus fréquente après poser, puisque tout le jeu tient à l'ordre.
func _on_slot_tapped(slot_index: int) -> void:
	if _has_selection:
		if _selected_from >= 0:
			_swap_slots(_selected_from, slot_index)
		else:
			_stack[slot_index] = _selected_rule
			if _selected_rule != RuleRegistry.EMPTY:
				_dedupe(slot_index)
			_apply_stack()
		_clear_selection()
		_close_panel()
		return
	if _stack[slot_index] != RuleRegistry.EMPTY:
		_select(_stack[slot_index], slot_index)
		_open_panel()
	else:
		_open_panel()

func _on_chip_tapped(rule_id: int) -> void:
	if _has_selection and _selected_from == -1 and _selected_rule == rule_id:
		_clear_selection()
		return
	_select(rule_id, -1)

func _select(rule_id: int, from_slot: int) -> void:
	_selected_rule = rule_id
	_selected_from = from_slot
	_has_selection = true
	_refresh_selection()

func _clear_selection() -> void:
	_has_selection = false
	_selected_rule = RuleRegistry.EMPTY
	_selected_from = -1
	_refresh_selection()

func _refresh_selection() -> void:
	for chip in _chips:
		chip.selected = _has_selection and _selected_from == -1 and chip.rule_id == _selected_rule
	for i in range(_slots.size()):
		_slots[i].selected = _has_selection and _selected_from == i

## Échange deux emplacements — y compris quand l'un est vide, ce qui revient
## à déplacer.
func _swap_slots(a: int, b: int) -> void:
	if a == b:
		return
	var tmp: int = _stack[a]
	_stack[a] = _stack[b]
	_stack[b] = tmp
	_apply_stack()

## Une règle n'occupe jamais deux emplacements : l'espace des piles est fait
## d'arrangements SANS répétition, l'interface doit rendre impossible ce que
## l'énumérateur ne compte pas.
func _dedupe(keep_slot: int) -> void:
	for i in range(_stack.size()):
		if i != keep_slot and _stack[i] == _stack[keep_slot]:
			_stack[i] = RuleRegistry.EMPTY

func _open_panel() -> void:
	if _panel.visible:
		return
	_panel.size = Vector2(_panel.size.x, _panel_height())
	_panel.position.y = _panel_resting_y() + _panel.size.y
	_panel.visible = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "position:y", _panel_resting_y(), 0.22)

func _close_panel() -> void:
	if not _panel.visible:
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "position:y", _panel_resting_y() + _panel.size.y, 0.18)
	tween.tween_callback(func() -> void: _panel.visible = false)

# --- appui long : explication courte (dérogation ENF-25, voir carnet) ------

func _on_chip_long_pressed(rule_id: int) -> void:
	if rule_id == RuleRegistry.EMPTY:
		_show_note("Retirer — vide l'emplacement choisi.")
	else:
		_show_note("%s — %s" % [RuleCatalog.name_of(rule_id), RuleCatalog.line_of(rule_id)])

func _on_slot_long_pressed(slot_index: int) -> void:
	var rule_id: int = _stack[slot_index]
	if rule_id == RuleRegistry.EMPTY:
		_show_note("Emplacement %d — vide. Appuyez pour y poser une règle." % (slot_index + 1))
	else:
		_show_note("%d. %s — %s" % [slot_index + 1, RuleCatalog.name_of(rule_id), RuleCatalog.line_of(rule_id)])

func _show_note(text: String) -> void:
	_explain_label.text = text
	_explain_panel.visible = true
	_position_explain_panel()

# --- EF-05 : le diagnostic, et la bascule marche/pause --------------------

## Un appui sur la grille :
##   en marche              → met en pause (le second chemin d'ENF-01) ;
##   en pause, sur un agent → diagnostic EF-05 ;
##   en pause, à vide       → relance.
## C'est ce qui rend le bouton du haut redondant, donc jamais requis.
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
	# Un appui hors des règles annule la sélection et referme le panneau.
	if _has_selection or _panel.visible:
		_clear_selection()
		_close_panel()
		return
	if _playing:
		_pause()
		return
	if not _show_explain_at(pos):
		_hide_explain()
		_toggle_play()

func _show_explain_at(local_pos: Vector2) -> bool:
	if _view == null or _view.current_state() == null:
		return false
	var cell := _view.cell_at_pixel(local_pos)
	if cell.x < 0:
		return false
	var index := _view.agent_near(cell, 1)
	if index < 0:
		return false
	# La décision du dernier mouvement s'est prise sur l'état PRÉCÉDENT
	# (RG-07, décisions sur cliché immuable) : c'est lui qu'on interroge.
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
	return true

func _position_explain_panel() -> void:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	var pad := 18.0
	var width: float = vp.x - m.x - m.z
	var lines: int = maxi(_explain_label.text.split("\n").size(), 1)
	var height: float = pad * 2.0 + lines * 32.0
	_explain_panel.position = Vector2(
		m.x, _view_host.position.y + _view_host.size.y - height - UiMetrics.GAP)
	_explain_panel.size = Vector2(width, height)
	_explain_label.position = Vector2(pad, pad)
	_explain_label.size = Vector2(width - pad * 2.0, height - pad * 2.0)

func _hide_explain() -> void:
	if _explain_panel != null:
		_explain_panel.visible = false

# --- disposition ----------------------------------------------------------

func _panel_height() -> float:
	return UiMetrics.MIN_TOUCH_TARGET + UiMetrics.MARGIN * 2.0

func _panel_resting_y() -> float:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	return vp.y - m.w - UiMetrics.MIN_TOUCH_TARGET * 1.25 - UiMetrics.GAP - _panel_height()

func _layout() -> void:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	var left: float = m.x
	var top: float = m.y
	var right: float = vp.x - m.z
	var bottom: float = vp.y - m.w
	var width: float = right - left
	var bar_h := UiMetrics.MIN_TOUCH_TARGET

	var left_row := get_node_or_null("LeftBar") as HBoxContainer
	if left_row != null:
		left_row.position = Vector2(left, top)
		left_row.size = Vector2(bar_h * 2.0 + UiMetrics.GAP, bar_h)
	var right_row := get_node_or_null("RightBar") as HBoxContainer
	if right_row != null:
		var w := bar_h * 2.0 + UiMetrics.GAP
		right_row.position = Vector2(right - w, top)
		right_row.size = Vector2(w, bar_h)

	if _objective_label != null:
		_objective_label.position = Vector2(left, top + bar_h + UiMetrics.GAP * 0.5)
		_objective_label.size = Vector2(width, 40)

	# La pile occupe le bas — et rien d'autre : le concepteur y tient.
	var stack_h := bar_h * 1.25
	var stack_bar := get_node_or_null("StackBar") as HBoxContainer
	if stack_bar != null:
		stack_bar.position = Vector2(left, bottom - stack_h)
		stack_bar.size = Vector2(width, stack_h)

	var view_top: float = top + bar_h + UiMetrics.GAP * 0.5 + 40 + UiMetrics.GAP
	var view_bottom: float = bottom - stack_h - UiMetrics.GAP
	if _view_host != null:
		_view_host.position = Vector2(left, view_top)
		_view_host.size = Vector2(width, maxf(view_bottom - view_top, 100.0))

	if _panel != null:
		_panel.size = Vector2(width, _panel_height())
		_panel.position = Vector2(left,
			_panel_resting_y() if _panel.visible else bottom + _panel_height())

	if _explain_panel != null and _explain_panel.visible:
		_position_explain_panel()

# --- pile et transport ----------------------------------------------------

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
		_speed_button.text = SPEED_GLYPHS[_speed_index]
		_speed_button.tooltip_text = "Vitesse ×%d" % int(SPEEDS[_speed_index])

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
