class_name TrialSelectScreen
extends Control
## Choix du chapitre pour le mode Épreuve.
##
## POURQUOI CET ÉCRAN EXISTE. La première version partait d'office du DERNIER
## chapitre entièrement résolu. Conséquence non vue à l'écriture : un joueur
## ayant fini les six chapitres ne pouvait plus jamais tenter les autres — et
## c'est le chapitre 2 qui exige le plus (force brute 3,0× le budget), pas le
## sixième. Le mode se refermait sur son chapitre le moins intéressant à mesure
## qu'on progressait.
##
## LE COÛT DE LA FORCE BRUTE EST AFFICHÉ, chapitre par chapitre. Ce n'est pas
## une coquetterie de concepteur : le budget est la seule ressource du mode, et
## une ressource dont on ignore l'ordre de grandeur ne se choisit pas. Le joueur
## doit pouvoir viser un chapitre parce qu'il est exigeant, pas le découvrir.
##
## SEULS LES CHAPITRES ENTIÈREMENT RÉSOLUS sont proposés. Une épreuve sur un
## chapitre qu'on n'a pas fini échouerait sur des niveaux qu'on n'a pas encore
## compris : le mode punit la recherche, jamais l'ignorance.

signal chapter_chosen(chapter: int)
signal back_requested

func setup(progress: Progress) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE, int(UiMetrics.MARGIN))

	var title := Label.new()
	title.text = "Épreuve"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiMetrics.font_size(48))
	title.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
	column.add_child(title)

	var rule := Label.new()
	rule.text = ("Un chapitre entier d'un seul tenant.\n"
		+ "Les lancements sont comptés et partagés par tous ses niveaux.")
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.add_theme_font_size_override("font_size", UiMetrics.font_size(24))
	rule.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	column.add_child(rule)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", int(UiMetrics.GAP))
	scroll.add_child(list)

	var offered := 0
	for chapter in cleared_chapters(progress):
		list.add_child(_make_tile(chapter))
		offered += 1
	if offered == 0:
		# Le menu n'ouvre cet écran que si un chapitre est terminé, mais un écran
		# qui peut s'afficher vide doit le dire plutôt que de paraître cassé.
		var empty := Label.new()
		empty.text = "Terminez un chapitre pour ouvrir une épreuve."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", UiMetrics.font_size(26))
		empty.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
		list.add_child(empty)

	var back := UiButtons.make("Retour")
	back.pressed.connect(func() -> void: back_requested.emit())
	column.add_child(back)

## Les chapitres entièrement résolus, dans l'ordre. Source unique : le menu,
## cet écran et `App` posent tous la même question et doivent lire la même
## réponse — trois lectures d'une même condition finissent par diverger
## (invariant n°16, et il vaut aussi pour la progression).
static func cleared_chapters(progress: Progress) -> Array[int]:
	var out: Array[int] = []
	if progress == null:
		return out
	for chapter in LevelCatalog.chapters():
		var done := LevelCatalog.chapter_progress(chapter, progress)
		if done.y > 0 and done.x >= done.y:
			out.append(chapter)
	return out

func _make_tile(chapter: int) -> Control:
	var levels := _level_count(chapter)
	var budget := levels * TrialRun.LAUNCHES_PER_LEVEL
	var button := UiButtons.make("Chapitre %d — %s" % [
		chapter, LevelCatalog.chapter_title(chapter)], UiButtons.Rank.PLAIN, 30)
	button.pressed.connect(func() -> void: chapter_chosen.emit(chapter))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(button)

	var detail := Label.new()
	detail.text = "%d niveaux · %d lancements" % [levels, budget]
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", UiMetrics.font_size(22))
	detail.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	box.add_child(detail)
	return box

static func _level_count(chapter: int) -> int:
	var n := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		if LevelCatalog.chapter_of(String(entry["id"])) == chapter:
			n += 1
	return n
