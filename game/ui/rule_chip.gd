class_name RuleChip
extends PanelContainer
## Règle dans le tiroir de bibliothèque : source de glissement, et cible
## d'appui pour l'équivalent sans glissement (ENF-25).

signal chip_tapped(rule_id: int)

var rule_id: int = RuleRegistry.EMPTY
var selected: bool = false:
	set(value):
		selected = value
		_refresh()

var _style: StyleBoxFlat

func _init(id: int = RuleRegistry.EMPTY) -> void:
	rule_id = id
	custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET * 2.1, UiMetrics.MIN_TOUCH_TARGET)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.corner_radius_top_left = 12
	_style.corner_radius_top_right = 12
	_style.corner_radius_bottom_left = 12
	_style.corner_radius_bottom_right = 12
	_style.border_width_left = 3
	_style.border_width_right = 3
	_style.border_width_top = 3
	_style.border_width_bottom = 3
	add_theme_stylebox_override("panel", _style)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	var glyph := Label.new()
	glyph.text = RuleCatalog.glyph_of(rule_id)
	glyph.add_theme_font_size_override("font_size", 36)
	glyph.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)

	var label := Label.new()
	label.text = RuleCatalog.name_of(rule_id)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	# Pas de retour à la ligne : contraint en largeur, le libellé se
	# repliait en une colonne d'une lettre par ligne.
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	tooltip_text = RuleCatalog.line_of(rule_id)
	_refresh()

func _refresh() -> void:
	if _style == null:
		return
	_style.bg_color = Color(0.14, 0.16, 0.21, 0.95) if selected else Color(0.09, 0.10, 0.13, 0.9)
	_style.border_color = Color(0.85, 0.90, 1.0, 0.9) if selected else Color(0.30, 0.34, 0.42, 0.9)

func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(RuleSlot._make_preview(rule_id))
	return {"rule_id": rule_id, "from_slot": -1}

func _gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	else:
		return
	if pressed:
		chip_tapped.emit(rule_id)
		accept_event()
