class_name LevelSelectScreen
extends Control
## Sélecteur des cinq niveaux du chapitre 1 : état résolu / non résolu d'un
## coup d'œil, sans compteur culpabilisant (P2, EF-10).
##
## Les niveaux 3 à 5 sont **en attente de conception** : ils s'affichent en
## grisé avec la mention explicite, plutôt que d'être cachés — le joueur voit
## la forme du chapitre, et le testeur comprend qu'il n'a pas raté une porte.

signal level_chosen(level_id: String)
signal back_requested

func setup(progress: Progress) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(column)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = UiMetrics.MARGIN
	column.offset_right = -UiMetrics.MARGIN
	column.offset_top = UiMetrics.MARGIN
	column.offset_bottom = -UiMetrics.MARGIN

	var title := Label.new()
	title.text = "Chapitre 1"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
	column.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, UiMetrics.GAP)
	column.add_child(spacer)

	for i in range(LevelCatalog.count()):
		column.add_child(_make_tile(LevelCatalog.entry(i), i, progress))

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grow)

	var back := Button.new()
	back.text = "Retour"
	back.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	back.add_theme_font_size_override("font_size", 30)
	back.pressed.connect(func() -> void: back_requested.emit())
	column.add_child(back)

func _make_tile(entry: Dictionary, index: int, progress: Progress) -> Control:
	var level_id := String(entry["id"])
	var ready_to_play := bool(entry["ready"])
	var solved: bool = progress.is_solved(level_id)

	var button := Button.new()
	button.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 30)
	button.disabled = not ready_to_play

	var mark := "✓" if solved else "·"
	button.text = "  %s   %d.  %s" % [mark, index + 1, String(entry["name"])]
	if not ready_to_play:
		button.text = "  ⋯   %d.  en attente de conception" % [index + 1]
		button.tooltip_text = "Ce niveau sera conçu après la révision du système de règles."
	elif solved:
		var best: int = progress.best_ticks(level_id)
		button.text += "      %d ticks" % best
		button.add_theme_color_override("font_color", ViewPalette.EXIT)

	if ready_to_play:
		button.pressed.connect(func() -> void: level_chosen.emit(level_id))
	return button
