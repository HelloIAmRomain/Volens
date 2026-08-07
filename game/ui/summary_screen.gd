class_name SummaryScreen
extends Control
## Écran de bilan [EF-07] : ce qui s'est passé, pourquoi, et une reprise en
## un geste. **Aucune incitation à enchaîner** (P2) : deux boutons de même
## poids visuel, aucun texte qui pousse à continuer.

signal retry_requested
signal select_requested

func setup(level_id: String, won: bool, ticks: int, lost: int, stack: Array) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Liseré d'état : reconnaissable en une demi-seconde, sans lire (DA-03).
	var banner := ColorRect.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.color = Color(0.16, 0.92, 0.62, 0.09) if won else Color(0.90, 0.16, 0.22, 0.09)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	column.offset_left = UiMetrics.MARGIN
	column.offset_right = -UiMetrics.MARGIN
	column.offset_top = UiMetrics.MARGIN
	column.offset_bottom = -UiMetrics.MARGIN
	add_child(column)

	var verdict := Label.new()
	verdict.text = "Objectif atteint" if won else "Objectif manqué"
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict.add_theme_font_size_override("font_size", 52)
	verdict.add_theme_color_override("font_color", ViewPalette.EXIT if won else ViewPalette.DANGER)
	column.add_child(verdict)

	var why := Label.new()
	why.text = _reason(won, lost)
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.add_theme_font_size_override("font_size", 28)
	why.add_theme_color_override("font_color", Color(0.78, 0.83, 0.93))
	column.add_child(why)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, UiMetrics.GAP)
	column.add_child(spacer)

	column.add_child(_stat("Ticks consommés", str(ticks)))
	column.add_child(_stat("Agents perdus", str(lost)))
	column.add_child(_stat("Pile utilisée", _stack_label(stack)))

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grow)

	# Deux boutons de même poids : le jeu ne pousse pas à enchaîner (P2).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	column.add_child(row)
	row.add_child(_make_button("Rejouer", func() -> void: retry_requested.emit()))
	row.add_child(_make_button("Niveaux", func() -> void: select_requested.emit()))

func _reason(won: bool, lost: int) -> String:
	if won:
		return "La nuée a rempli l'objectif." if lost == 0 else "Objectif rempli, malgré des pertes."
	if lost > 0:
		return "Trop d'agents perdus : l'objectif est devenu hors d'atteinte."
	return "Le temps imparti s'est écoulé avant l'objectif."

func _stat(label: String, value: String) -> Control:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	row.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 26)
	v.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	row.add_child(v)
	return row

func _make_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(action)
	return b

static func _stack_label(stack: Array) -> String:
	if stack.is_empty():
		return "vide"
	var parts := PackedStringArray()
	for rule_id in stack:
		parts.append(RuleCatalog.name_of(int(rule_id)))
	return " > ".join(parts)
