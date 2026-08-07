class_name RuleChip
extends RuleTouchTarget
## Règle dans le panneau de bibliothèque : source de glissement, et cible
## d'appui pour le chemin sans glissement (ENF-25).
##
## Une pastille spéciale porte `RuleRegistry.EMPTY` : c'est **« Retirer »**.
## Sans elle, vider un emplacement exigerait un glissement — or ENF-25
## interdit qu'une action ait le glissement pour seul chemin.

var rule_id: int = RuleRegistry.EMPTY
var selected: bool = false:
	set(value):
		selected = value
		_refresh()

var _style: StyleBoxFlat

func _init(id: int = RuleRegistry.EMPTY) -> void:
	rule_id = id
	custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET * 2.0, UiMetrics.MIN_TOUCH_TARGET)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	super()
	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(12)
	_style.set_border_width_all(3)
	add_theme_stylebox_override("panel", _style)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	var glyph := Label.new()
	glyph.text = "⌫" if rule_id == RuleRegistry.EMPTY else RuleCatalog.glyph_of(rule_id)
	glyph.add_theme_font_size_override("font_size", 34)
	glyph.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)

	var label := Label.new()
	label.text = "Retirer" if rule_id == RuleRegistry.EMPTY else RuleCatalog.name_of(rule_id)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	_refresh()

func _refresh() -> void:
	if _style == null:
		return
	if selected:
		_style.bg_color = Color(0.20, 0.24, 0.32, 0.97)
		_style.border_color = Color(1.0, 1.0, 1.0, 0.95)
		_style.set_border_width_all(6)
		_style.shadow_color = Color(1.0, 1.0, 1.0, 0.28)
		_style.shadow_size = 10
	else:
		_style.bg_color = Color(0.09, 0.10, 0.13, 0.92)
		_style.border_color = Color(0.30, 0.34, 0.42, 0.9)
		_style.set_border_width_all(3)
		_style.shadow_size = 0

func _drag_payload() -> Variant:
	# « Retirer » ne se glisse pas : on ne traîne pas un vide sur la grille.
	if rule_id == RuleRegistry.EMPTY:
		return null
	return {"rule_id": rule_id, "from_slot": -1}

func _drag_preview() -> Control:
	return RuleTouchTarget.make_preview(rule_id)
