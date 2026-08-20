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
##   · **UNE SEULE À LA FOIS** — et c'est un essai sur l'appareil qui l'a
##     imposé. Deux légendes sur la même carte affichaient deux noms et
##     surlignaient deux jeux de cases avec le MÊME cadre : rien ne disait
##     laquelle allait avec laquelle. Une désignation ambiguë ne désigne pas.
##     Elles s'enchaînent donc, deux au plus, chacune avec son seul surlignage.
##
## ET ELLE NE SE POSE JAMAIS SUR CE QU'ELLE MONTRE. Même essai : la carte
## couvrait les ressources qu'elle décrivait, et il ne restait visible que les
## dépôts. Elle se place maintenant dans la moitié d'écran OPPOSÉE aux cases
## désignées.

signal dismissed

## Rectangles à faire ressortir, en pixels d'écran.
var _spots: Array = []

## Ordonnée moyenne des cases désignées, en pixels d'écran.
func _spots_centre_y() -> float:
	var total := 0.0
	for s in _spots:
		var r: Rect2 = (s as Dictionary)["rect"]
		total += r.position.y + r.size.y * 0.5
	return total / float(_spots.size())

func setup(entry: Dictionary, spots: Array = []) -> void:
	_spots = spots
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# ELLE INTERCEPTE LE CONTACT, mais ne fige rien : c'est ce qui permet de la
	# refermer en touchant n'importe où plutôt qu'en visant un bouton — geste
	# qu'on fait sans regarder, donc sans quitter la grille des yeux.
	mouse_filter = Control.MOUSE_FILTER_STOP

	# LE VOILE EST PLUS SOMBRE QU'UN VOILE ORDINAIRE, parce qu'il ne sert pas à
	# atténuer : il sert à FAIRE RESSORTIR. C'est le contraste entre lui et les
	# cases désignées qui répond à la question « de quoi parle-t-on ? ».
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.02, 0.03, 0.05, 0.72)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	# LA SURBRILLANCE PASSE PAR-DESSUS LE VOILE, jamais en trouant le voile.
	# Découper des trous demanderait de composer des rectangles et laisserait la
	# case au même éclat que le reste de l'écran ; un halo par-dessus la rend
	# PLUS lumineuse que tout ce qui l'entoure, ce qui est exactement le geste
	# de désignation recherché.
	var spotlight := _Spotlight.new()
	spotlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spotlight.rects = _spots
	add_child(spotlight)

	# LE CENTRAGE PASSE PAR UN CONTENEUR PLEIN ÉCRAN, jamais par un preset posé
	# sur le panneau lui-même. Essayé, mesuré sur l'appareil : un `PRESET_CENTER`
	# en mode MINSIZE se cale sur la taille minimale du panneau, or celle d'un
	# libellé à retour à la ligne automatique vaut zéro — la carte partait sur le
	# côté et chevauchait les emplacements de règles.
	#
	# LA MOITIÉ CHOISIE EST CELLE QUE LES CASES N'OCCUPENT PAS. Une carte posée
	# sur ce qu'elle décrit annule son propre surlignage : à l'essai, elle
	# couvrait les ressources et ne laissait voir que les dépôts.
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen_h: float = get_viewport_rect().size.y
	if not _spots.is_empty() and _spots_centre_y() < screen_h * 0.5:
		# Les cases sont en haut : la carte descend dans le tiers bas.
		centre.offset_top = screen_h * 0.34
	else:
		centre.offset_bottom = -screen_h * 0.34
	add_child(centre)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# UN FOND OPAQUE, ET C'EST LA MOITIÉ DE LA LISIBILITÉ. Sans lui, le texte se
	# posait directement sur la grille : la nuée passait derrière les mots, et la
	# légende avait l'air d'un défaut d'affichage plutôt que d'un message.
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.10, 0.15, 0.98)
	box.border_color = Color(0.30, 0.38, 0.52)
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(UiMetrics.GAP))
	box.set_content_margin_all(UiMetrics.MARGIN)
	panel.add_theme_stylebox_override("panel", box)
	centre.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	# LARGEUR IMPOSÉE. Un libellé qui se replie tout seul choisit une largeur
	# absurde — trois mots par ligne sur une carte deux fois trop étroite, ce que
	# la capture d'essai montrait exactement.
	column.custom_minimum_size.x = 620.0
	panel.add_child(column)

	var name_label := Label.new()
	name_label.text = String(entry["name"])
	name_label.add_theme_font_size_override("font_size", UiMetrics.font_size(34))
	name_label.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
	column.add_child(name_label)

	var line := Label.new()
	line.text = String(entry["line"])
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

## UN SEUL CONGÉ, MÊME SI ANDROID EN ANNONCE DEUX.
##
## LE DÉFAUT, MESURÉ SUR L'APPAREIL, ne se voit pas au poste de travail : un
## contact tactile y produit **deux** évènements — un `InputEventScreenTouch` et
## un `InputEventMouseButton` simulé. Les deux branches tiraient `dismissed`, et
## le récepteur enchaînait donc DEUX fois : deux légendes suivantes créées l'une
## sur l'autre, dont la première se refermait aussitôt sur le même geste et
## ouvrait le panneau d'objectif — pendant que la seconde restait affichée.
##
## À l'écran, cela donnait exactement ce qu'on venait de corriger : une légende
## et un objectif en même temps. La cause était ailleurs que là où le symptôme
## se voyait, et c'est pourquoi le verrou est ici, à la source, plutôt qu'une
## rustine chez l'appelant.
var _done := false

func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	# UN RELÂCHEMENT, PAS UN APPUI. Fermer sur l'appui ferait passer le même
	# geste au travers : le relâchement atteindrait la grille en dessous et
	# lancerait la simulation sans que personne l'ait demandé.
	var released: bool = (event is InputEventMouseButton
			and not (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch
			and not (event as InputEventScreenTouch).pressed)
	if not released:
		return
	_done = true
	dismissed.emit()
	queue_free()

## LE HALO DE DÉSIGNATION — un cadre clair et un fond éclairci sur chaque case
## décrite, dessinés par-dessus le voile.
##
## POURQUOI UN NŒUD À PART. `_draw` d'un Control ne peint que sous ses enfants ;
## le halo doit passer AU-DESSUS du voile et EN DESSOUS du panneau, ce qui est
## exactement une position dans la liste des enfants — pas un réglage de couche.
##
## AUCUNE ANIMATION : le halo ne pulse pas, ne clignote pas. Un clignotement
## demanderait d'être regardé au bon moment (ENF-21), alors qu'ici tout est déjà
## à l'arrêt pour être lu.
class _Spotlight extends Control:
	var rects: Array = []

	func _draw() -> void:
		for spot in rects:
			var s: Dictionary = spot
			var rect: Rect2 = s["rect"]
			var thick: float = maxf(rect.size.x * 0.08, 2.0)
			# LA CASE REPREND SA PROPRE TEINTE, À PLEINE OPACITÉ, PAR-DESSUS LE
			# VOILE. C'est le point qui a demandé une seconde capture : un halo
			# blanc uniforme désignait très bien la case, mais il la MONTRAIT
			# BLANCHE — et le joueur allait ensuite chercher un carré blanc là où
			# le jeu en met un ambre. Une désignation qui déguise ce qu'elle
			# désigne renseigne à moitié.
			var own := ViewPalette.element_color(int(s.get("cell", -1)))
			own.a = 1.0
			draw_rect(rect, own, true)
			# Le cadre déborde d'un tiers de case : sur une grille dense, un
			# contour calé pile sur la case se confond avec le trait de grille.
			var pad: float = rect.size.x * 0.34
			var wide := Rect2(rect.position - Vector2(pad, pad),
				rect.size + Vector2(pad, pad) * 2.0)
			var edge := ViewPalette.AGENT_PLAIN
			edge.a = 0.95
			draw_rect(wide, edge, false, thick)
