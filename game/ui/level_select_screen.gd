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

	# DIX-HUIT NIVEAUX EN LISTE PLATE SONT ILLISIBLES, et le titre « Chapitre 1 »
	# ecrit en dur mentait des le deuxieme chapitre. L'ecran est donc DEFILANT et
	# groupe par chapitre ; les chapitres et leur contenu sont deduits du
	# catalogue, jamais redeclares ici.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", int(UiMetrics.GAP))
	scroll.add_child(list)

	var index := 0
	for chapter in LevelCatalog.chapters():
		list.add_child(_chapter_header(chapter, progress))
		for i in range(LevelCatalog.count()):
			var entry: Dictionary = LevelCatalog.entry(i)
			if LevelCatalog.chapter_of(String(entry["id"])) != chapter:
				continue
			list.add_child(_make_tile(entry, i, progress))
			index += 1

	var back := UiButtons.make("Retour")
	back.pressed.connect(func() -> void: back_requested.emit())
	column.add_child(back)

## En-tete de chapitre : son numero, son titre, et l'avancement chiffre. Un
## chapitre verrouille le dit — sans quoi le joueur croit a un defaut
## d'affichage devant une liste de tuiles grises.
func _chapter_header(chapter: int, progress: Progress) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, UiMetrics.GAP)
	box.add_child(spacer)

	var heading := Label.new()
	heading.text = "Chapitre %d — %s" % [chapter, LevelCatalog.chapter_title(chapter)]
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
	box.add_child(heading)

	var done := LevelCatalog.chapter_progress(chapter, progress)
	var status := Label.new()
	status.text = ("%d / %d résolus" % [done.x, done.y]) if \
		LevelCatalog.is_chapter_unlocked(chapter, progress) else "verrouillé"
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	box.add_child(status)
	return box

## Un défi est enregistré sous son libellé complet (« Économie — résolu avec 2
## règles ») : on le reconnaît par son préfixe, seule partie stable.
static func _has_challenge(earned: PackedStringArray, label: String) -> bool:
	for line in earned:
		if line.begins_with(label):
			return true
	return false

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
		# LE NOM RESTE CACHÉ — le découvrir fait partie du niveau — mais la
		# CONDITION est écrite, sinon le verrou se lit comme une panne.
		#
		# LE PRÉREQUIS N'EST NOMMÉ QUE S'IL EST DÉJÀ CONNU du joueur. Sur cinq
		# niveaux, citer le précédent renseignait ; sur dix-huit, cela révélait
		# en cascade le titre de tous les niveaux à venir — un joueur au
		# chapitre 1 lisait les neuf titres suivants sans en avoir joué un seul.
		# Au-delà du prochain verrou, on ne dit plus que le rang.
		var previous_id := String(LevelCatalog.entry(index - 1)["id"])
		if progress.is_solved(previous_id) or LevelCatalog.is_unlocked(previous_id, progress):
			button.text = "  🔒   %d.  terminez « %s »" % [
				index + 1, String(LevelCatalog.entry(index - 1)["name"])]
		else:
			button.text = "  🔒   %d." % [index + 1]
	else:
		var mark := "✓" if solved else "·"
		button.text = "  %s   %d.  %s" % [mark, index + 1, String(entry["name"])]
		if solved:
			button.text += "      %d ticks" % progress.best_ticks(level_id)
			# DÉFIS OBTENUS, en trois pastilles. Sans trace dans la liste, un défi
			# gagné disparaît avec l'écran de bilan : la couche de rejouabilité
			# n'existerait que le temps d'une phrase. Ce qui est obtenu est marqué,
			# ce qui ne l'est pas reste vide — jamais barré ni grisé, RG-19
			# interdit de transformer une victoire en échec partiel.
			var earned := progress.earned_challenges(level_id)
			if not earned.is_empty():
				var marks := ""
				for label in ["Économie", "Abstinence", "Efficience"]:
					marks += "◆" if _has_challenge(earned, label) else "◇"
				button.text += "   %s" % marks
			button.add_theme_color_override("font_color", ViewPalette.EXIT)
		button.pressed.connect(func() -> void: level_chosen.emit(level_id))
	return button
