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

var _drag: DragScroll

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
	# LE DOIGT DÉFILE PARTOUT, y compris posé sur une tuile. Sans cela, seules
	# les gouttières entre deux niveaux répondaient — c'est-à-dire l'espace vide,
	# soit exactement ce que personne ne vise.
	_drag = DragScroll.attach(scroll)

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
	# Sans enveloppe, le titre impose sa largeur a toute la colonne.
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.x = 0
	heading.add_theme_font_size_override("font_size", UiMetrics.font_size(34))
	heading.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
	box.add_child(heading)

	var done := LevelCatalog.chapter_progress(chapter, progress)
	var status := Label.new()
	status.text = ("%d / %d résolus" % [done.x, done.y]) if \
		LevelCatalog.is_chapter_unlocked(chapter, progress) else "verrouillé"
	status.add_theme_font_size_override("font_size", UiMetrics.font_size(22))
	status.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	box.add_child(status)
	return box

## Un défi est enregistré sous son libellé complet (« Économie — résolu avec 2
## règles ») : on le reconnaît par son préfixe, seule partie stable.
## Un défi est enregistré sous son libellé complet ; on le reconnaît par son
## PRÉFIXE, seule partie stable. Les libellés ont déjà changé une fois — quand
## les seuils sont devenus per-niveau — et un test de correspondance exacte
## aurait effacé silencieusement tous les défis déjà obtenus.
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

	var remaining := PackedStringArray()
	var button := UiButtons.make("", UiButtons.Rank.PLAIN, 30)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not unlocked
	# LA TUILE NE POUSSE JAMAIS LA COLONNE. Un bouton non contraint prend pour
	# largeur minimale celle de son texte ENTIER : sur un ecran de 720, « ✓ 2. Le
	# detour 29 ticks ◆◇◆ » debordait, et la colonne entiere avec lui — jusqu'au
	# bouton « Retour », decale hors de l'axe. Le texte se raccourcit plutot que
	# de deformer l'ecran.
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.custom_minimum_size.x = 0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
				index + 1, LevelCatalog.name_of(previous_id)]
		else:
			button.text = "  🔒   %d." % [index + 1]
	else:
		var mark := "✓" if solved else "·"
		button.text = "  %s   %d.  %s" % [mark, index + 1,
			LevelCatalog.name_of(level_id)]
		if solved:
			button.text += "      %d ticks" % progress.best_ticks(level_id)
			# DÉFIS : UNE PASTILLE PAR DÉFI QUE LE NIVEAU PROPOSE, jamais trois.
			#
			# Il y en avait trois partout, dont deux qu'aucune pile ne pouvait
			# allumer sur la plupart des niveaux : « pour le moment il y a trois
			# brins partout ; il faut que ce soit le nombre de défis ». Neuf
			# niveaux n'en proposent aucun et n'affichent donc plus rien — une
			# pastille éteinte qu'on ne peut pas allumer est une fausse piste, et
			# la répéter vingt-neuf fois en fait une leçon d'impuissance.
			#
			# Ce qui est obtenu est marqué, le reste reste creux — jamais barré ni
			# grisé : RG-19 interdit de transformer une victoire en échec partiel.
			var spec := LevelSpec.challenges(LevelCatalog.load_level_data(level_id))
			var earned := progress.earned_challenges(level_id)
			var marks := ""
			if int(spec.get("economy_max", 0)) > 0:
				marks += "◆" if _has_challenge(earned, "Économie") else "◇"
			if int(spec.get("abstinence_rule", 0)) != 0:
				marks += "◆" if _has_challenge(earned, "Abstinence") else "◇"
			if int(spec.get("efficiency_ticks", 0)) > 0:
				marks += "◆" if _has_challenge(earned, "Efficience") else "◇"
			if not marks.is_empty():
				button.text += "   %s" % marks
			# TOUS LES ÉTATS, pas seulement le normal : la tuile sous le pointeur
			# émulé se repeignait sinon en blanc, seule au milieu des vertes.
			UiButtons.tint(button, ViewPalette.EXIT)
			remaining = _remaining_challenges(spec, earned)
		# Un relâchement qui termine un GLISSEMENT n'ouvre pas le niveau sous le
		# doigt : sans ce contrôle, faire défiler lancerait une partie au hasard.
		button.pressed.connect(func() -> void:
			if _drag != null and _drag.consumed_drag():
				return
			level_chosen.emit(level_id))
	if remaining.is_empty():
		return button

	# CE QUI RESTE À FAIRE, NOMMÉ — et rien d'autre.
	#
	# Les pastilles ◆◇ disent COMBIEN de défis sont acquis, jamais LESQUELS ni
	# ce qu'ils demandent. Le joueur voyait un losange creux sans aucun moyen de
	# savoir ce qu'il fallait chercher, ce qui en fait une énigme sur l'énigme.
	#
	# ON NE NOMME QUE LE RESTANT, pas la liste entière. C'est deux fois plus
	# court — donc ça tient sur un écran étroit, où la tuile se tronque déjà par
	# ellipse — et c'est exactement la question posée : « savoir ce qu'il reste à
	# accomplir ». Un niveau dont tous les défis sont acquis n'affiche RIEN : le
	# silence est la récompense, et la liste ne s'allonge pas pour les joueurs
	# qui ont fini.
	#
	# RG-19 TIENT. La ligne est une PROPOSITION — « il reste » — jamais un
	# reproche : rien n'est barré, rien n'est rouge, et elle ne conditionne
	# aucune progression.
	var tile := VBoxContainer.new()
	tile.add_theme_constant_override("separation", 0)
	# L'ENVELOPPE NE CONSOMME RIEN. Un conteneur qui intercepte avalerait le
	# glissement du doigt dans l'interstice entre le bouton et sa ligne — le
	# défilement se bloquerait par endroits, ce qui se diagnostique très mal.
	# Les enfants continuent de recevoir leurs propres évènements.
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(button)

	var hint := Label.new()
	hint.text = "        il reste : %s" % ", ".join(remaining)
	# Sans enveloppe ni largeur minimale nulle, un libellé long imposerait sa
	# largeur à toute la colonne — le défaut qui avait déjà décalé le bouton
	# « Retour » hors de l'axe.
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 0
	hint.add_theme_font_size_override("font_size", UiMetrics.font_size(20))
	hint.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	# La ligne ne doit RIEN intercepter : posée sous le bouton, elle traverserait
	# autrement le glissement du doigt et bloquerait le défilement de la liste.
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(hint)
	return tile

## Les défis que le niveau propose et que le joueur n'a pas encore obtenus,
## nommés par ce qu'ils DEMANDENT — « sans “Suivre la piste” » renseigne, « défi
## d'abstinence » ne renseigne pas.
static func _remaining_challenges(spec: Dictionary, earned: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	var economy := int(spec.get("economy_max", 0))
	if economy > 0 and not _has_challenge(earned, "Économie"):
		out.append("%d règle%s au plus" % [economy, "s" if economy > 1 else ""])
	var abstinence := int(spec.get("abstinence_rule", 0))
	if abstinence != 0 and not _has_challenge(earned, "Abstinence"):
		out.append("sans « %s »" % RuleCatalog.name_of(abstinence))
	var deadline := int(spec.get("efficiency_ticks", 0))
	if deadline > 0 and not _has_challenge(earned, "Efficience"):
		out.append("%d ticks au plus" % deadline)
	return out
