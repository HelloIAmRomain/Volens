class_name MechanicCard
extends Control
## LA LÉGENDE D'UN ÉLÉMENT, MONTRÉE UNE FOIS, À SA PREMIÈRE RENCONTRE.
##
## POURQUOI CE N'EST PAS UN TUTORIEL. Le jeu n'en a pas, et n'en aura pas : on
## demande au joueur de découvrir ce qu'une pile produit, et le lui dire
## reviendrait à jouer à sa place. Mais **ce que fait une CASE n'est pas une
## découverte, c'est un fait** — une plaque et une bascule sont deux marques
## colorées dont rien, à l'écran, ne dit que l'une tient tant qu'on l'occupe et
## que l'autre s'enclenche définitivement. Sans légende, le joueur l'apprend en
## perdant et conclut que le jeu est capricieux.
##
## LA LIGNE DE PARTAGE EST NETTE : on dit ce que la case FAIT, jamais ce qu'il
## faut en faire. « La porte reste ouverte tant que des agents sont dessus »
## décrit ; « postez-y deux agents » jouerait à sa place.
##
## TROIS CONTRAINTES DE FORME, chacune contre un défaut connu :
##
##   · **elle ne bloque rien** — la simulation n'est pas suspendue derrière, et
##     un contact n'importe où la referme. Un panneau modal avant le premier
##     geste utile coûte un geste pour rien (EF-21, même raison que l'absence de
##     panneau à la reprise) ;
##   · **elle ne se répète jamais** — vue une fois, elle est enregistrée dans la
##     progression. Une légende revue n'apprend rien, elle interrompt ;
##   · **deux au plus à la fois** — trois cartes d'affilée devant un niveau
##     qu'on vient d'ouvrir se referment sans être lues, et l'on aurait dépensé
##     la seule occasion de les montrer.

signal dismissed

func setup(entries: Array) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# ELLE INTERCEPTE LE CONTACT, mais ne fige rien : c'est ce qui permet de la
	# refermer en touchant n'importe où plutôt qu'en visant un bouton — geste
	# qu'on fait sans regarder, donc sans quitter la grille des yeux.
	mouse_filter = Control.MOUSE_FILTER_STOP

	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.02, 0.03, 0.05, 0.55)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER,
		Control.PRESET_MODE_MINSIZE, int(UiMetrics.MARGIN))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	panel.add_child(column)

	for entry in entries:
		var name_label := Label.new()
		name_label.text = String((entry as Dictionary)["name"])
		name_label.add_theme_font_size_override("font_size", UiMetrics.font_size(34))
		name_label.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
		column.add_child(name_label)

		var line := Label.new()
		line.text = String((entry as Dictionary)["line"])
		# Sans enveloppe ni largeur minimale nulle, une phrase longue impose sa
		# largeur au panneau et déborde d'un écran étroit.
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size.x = 0
		line.add_theme_font_size_override("font_size", UiMetrics.font_size(26))
		line.add_theme_color_override("font_color", Color(0.78, 0.83, 0.93))
		column.add_child(line)

	var hint := Label.new()
	hint.text = "touchez pour continuer"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", UiMetrics.font_size(20))
	hint.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	column.add_child(hint)

func _gui_input(event: InputEvent) -> void:
	# UN RELÂCHEMENT, PAS UN APPUI. Fermer sur l'appui ferait passer le même
	# geste au travers : le relâchement atteindrait la grille en dessous et
	# lancerait la simulation sans que personne l'ait demandé.
	if event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
		dismissed.emit()
		queue_free()
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		dismissed.emit()
		queue_free()
