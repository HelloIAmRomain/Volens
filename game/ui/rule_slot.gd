class_name RuleSlot
extends PanelContainer
## Un des quatre emplacements de la pile [RG-05, DCT §9.2].
##
## Deux façons de le remplir, l'une et l'autre obligatoires :
## — **glisser-déposer** natif de Godot (`_get_drag_data` / `_drop_data`) ;
## — **équivalent sans glissement** (ENF-25) : appui sur une règle pour la
##   sélectionner, puis appui sur l'emplacement cible. Un joueur qui tient
##   son téléphone d'une main dans le bus ne peut pas toujours glisser.
##
## L'emplacement porte une COULEUR FIXE (1 cyan, 2 ambre, 3 magenta,
## 4 vert), la même que celle dont la vue teinte les agents décidés par cet
## emplacement. Le joueur lit donc directement « la plupart des agents sont
## cyan, donc c'est ma première règle qui gouverne » — la règle d'or rendue
## visible. ⚠ Choix de conception à confirmer par le concepteur.

signal rule_dropped(slot_index: int, rule_id: int)
signal slot_tapped(slot_index: int)

var slot_index: int = 0
var rule_id: int = RuleRegistry.EMPTY

var _label: Label
var _glyph: Label
var _style: StyleBoxFlat

func _init(index: int = 0) -> void:
	slot_index = index
	custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	_glyph = Label.new()
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph.add_theme_font_size_override("font_size", 40)
	box.add_child(_glyph)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 22)
	box.add_child(_label)

	_refresh()

func set_rule(new_rule_id: int) -> void:
	rule_id = new_rule_id
	_refresh()

func _refresh() -> void:
	if _label == null:
		return
	var color := ViewPalette.slot_color(slot_index)
	if rule_id == RuleRegistry.EMPTY:
		_glyph.text = str(slot_index + 1)
		_glyph.add_theme_color_override("font_color", Color(color, 0.20))
		_label.text = ""
		_style.bg_color = Color(0.09, 0.10, 0.13, 0.85)
		_style.border_color = Color(color, 0.28)
		tooltip_text = "Emplacement %d — vide" % (slot_index + 1)
	else:
		_glyph.text = RuleCatalog.glyph_of(rule_id)
		_glyph.add_theme_color_override("font_color", color)
		_label.text = RuleCatalog.name_of(rule_id)
		_label.add_theme_color_override("font_color", Color(0.90, 0.93, 1.0))
		_style.bg_color = Color(color.r, color.g, color.b, 0.16)
		_style.border_color = color
		tooltip_text = "%d. %s — %s" % [slot_index + 1, RuleCatalog.name_of(rule_id), RuleCatalog.line_of(rule_id)]

# --- glisser-déposer ------------------------------------------------------

func _get_drag_data(_at_position: Vector2) -> Variant:
	if rule_id == RuleRegistry.EMPTY:
		return null
	set_drag_preview(_make_preview(rule_id))
	# `from_slot` permet au dépôt de savoir qu'il s'agit d'un déplacement
	# interne (réordonnancement) et non d'un ajout depuis la bibliothèque.
	return {"rule_id": rule_id, "from_slot": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("rule_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	rule_dropped.emit(slot_index, int((data as Dictionary)["rule_id"]))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		slot_tapped.emit(slot_index)
		accept_event()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		slot_tapped.emit(slot_index)
		accept_event()

static func _make_preview(preview_rule_id: int) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "%s  %s" % [RuleCatalog.glyph_of(preview_rule_id), RuleCatalog.name_of(preview_rule_id)]
	label.add_theme_font_size_override("font_size", 24)
	panel.add_child(label)
	return panel
