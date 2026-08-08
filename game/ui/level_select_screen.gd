class_name LevelSelectScreen
extends Control
## Sélecteur des cinq niveaux du chapitre 1 : état résolu / non résolu d'un
## coup d'œil, sans compteur culpabilisant (P2, EF-10).
##
## Un niveau non encore ouvert s'affiche **en grisé avec un cadenas**, jamais
## caché : le joueur voit la forme du chapitre et comprend qu'il n'a pas raté
## une porte. Il lit aussi ce qui l'ouvrira — « terminez le niveau N » — parce
## qu'un verrou sans condition affichée se lit comme une panne.

signal level_chosen(level_id: String)
signal back_requested

func setup(progress: Progress) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE, int(UiMetrics.MARGIN))

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

	var back := UiButtons.make("Retour")
	back.pressed.connect(func() -> void: back_requested.emit())
	column.add_child(back)

func _make_tile(entry: Dictionary, index: int, progress: Progress) -> Control:
	var level_id := String(entry["id"])
	var built := bool(entry["ready"])
	var unlocked: bool = LevelCatalog.is_unlocked(level_id, progress)
	var solved: bool = progress.is_solved(level_id)

	var button := UiButtons.make("", UiButtons.Rank.PLAIN, 30)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not unlocked

	if not built:
		button.text = "  ⋯   %d.  en attente de conception" % [index + 1]
	elif not unlocked:
		# Le nom du niveau reste caché : le découvrir fait partie du niveau.
		# En revanche la CONDITION est écrite, sinon le verrou se lit comme
		# une panne de l'application.
		var previous := String(LevelCatalog.entry(index - 1)["name"])
		button.text = "  🔒   %d.  terminez « %s »" % [index + 1, previous]
	else:
		var mark := "✓" if solved else "·"
		button.text = "  %s   %d.  %s" % [mark, index + 1, String(entry["name"])]
		if solved:
			button.text += "      %d ticks" % progress.best_ticks(level_id)
			button.add_theme_color_override("font_color", ViewPalette.EXIT)
		button.pressed.connect(func() -> void: level_chosen.emit(level_id))
	return button
