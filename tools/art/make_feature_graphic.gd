extends SceneTree
## BANNIÈRE DU PLAY STORE — 1024×500, procédurale, régénérable d'une commande.
##
##   godot --headless --path . --script res://tools/art/make_feature_graphic.gd -- \
##       --out=reports/art
##
## POURQUOI ELLE EXISTE. La fiche du Play Store EXIGE une bannière ; sans elle,
## la fiche ne se publie pas. C'était le seul visuel obligatoire que rien ne
## produisait — l'icône, elle, est générée depuis le premier jour.
##
## LE FORMAT EST IMPOSÉ ET SANS INDULGENCE : exactement 1024×500, et **sans
## couche alpha**. Une PNG transparente est refusée à l'envoi. On compose donc
## en RGBA et l'on convertit avant d'écrire.
##
## AUCUN TEXTE, ET C'EST UN CHOIX. Google recadre la bannière selon les
## contextes — vignette, en-tête, bandeau de recommandation — et ce qui touche
## les bords disparaît. Un titre incrusté serait rogné une fois sur deux, et il
## ne se traduirait pas : le magasin affiche déjà le nom du jeu à côté. Une
## bannière qui répète le titre gaspille sa seule surface.
##
## CE QU'ELLE MONTRE, ET C'EST LE MÊME SUJET QUE L'ICÔNE VU AUTREMENT. L'icône
## est carrée : la nuée y monte vers une ouverture. La bannière est large, donc
## le flux devient HORIZONTAL — la nuée entre par la gauche, s'étire, se resserre
## devant l'ouverture d'un mur vertical, et quelques agents ont déjà franchi,
## vers la lumière posée à droite.
##
## C'est l'idiome du jeu, tourné d'un quart de tour : *la nuée ne va pas vers la
## sortie, elle va vers la lumière, et le mur l'oblige à passer par l'ouverture.*
## Le sens de lecture y aide — de gauche à droite, comme le regard.
##
## LA PALETTE VIENT D'`ArtKit`, partagée avec l'icône. Les deux images se
## regardent côte à côte sur la fiche : deux jeux de couleurs recopiés auraient
## dérivé au premier ajustement.

## Rendu au double, puis réduit : l'anticrénelage vient de la réduction.
const OUT_SIZE := Vector2i(1024, 500)
const SUPERSAMPLE := 2

## Repères de composition, en fractions de la bannière (0..1).
##
## LE MUR EST À DROITE DU CENTRE, PAS AU MILIEU. Centré, il coupe l'image en
## deux moitiés égales et l'œil s'arrête dessus ; décalé, il laisse la place au
## flux — qui est le sujet — et fait de la lumière une récompense au bout.
const WALL_X := 0.615
const WALL_HALF := 0.030          # demi-épaisseur, en fraction de LARGEUR
const GAP_TOP := 0.418            # ouverture, en fraction de HAUTEUR
const GAP_BOTTOM := 0.548

## PREMIER RENDU REGARDÉ, PREMIER RENDU REFUSÉ. Le mur y faisait 0.021 de
## demi-épaisseur, s'éteignait sur un cinquième de la hauteur et ouvrait sur
## 18 % — résultat : une barre fantôme, un passage qu'on ne distinguait pas, et
## une image qui racontait « des points dérivent vers une lune » au lieu de
## « une nuée est forcée par une ouverture ».
##
## C'est le défaut contre lequel les commentaires de l'icône mettent en garde,
## mot pour mot : *un mur qu'on ne voit pas ne dit pas pourquoi la nuée se
## resserre.* Il fallait le voir pour le croire — d'où la règle : on REGARDE
## l'image produite, on ne se fie pas au code qui la produit.
const LIGHT_POS := Vector2(0.822, 0.470)
const LIGHT_R := 0.052            # en fraction de HAUTEUR

## LA NUÉE EST POSÉE À LA MAIN, comme celle de l'icône, et pour la même raison :
## un placement calculé donne une forme régulière ou un nuage aléatoire, et
## aucun des deux ne ressemble à une nuée qui converge.
##
## Colonnes : x, y (fractions), brillance, facteur de rayon.
const SWARM: Array = [
	# FRANCHIS — trois agents entre l'ouverture et la lumière. Ils disent que le
	# passage MÈNE quelque part ; sans eux, le mur n'est qu'une barre.
	[0.686, 0.454, 1.00, 1.00],
	[0.722, 0.508, 0.92, 0.92],
	[0.744, 0.418, 0.84, 0.86],

	# LE GOULOT — serrés, brillants, alignés sur l'ouverture. C'est la
	# congestion, et c'est la plus belle chose que le jeu produise.
	[0.588, 0.470, 1.00, 1.06],
	[0.556, 0.418, 0.96, 1.00],
	[0.556, 0.528, 0.96, 1.00],
	[0.524, 0.470, 0.94, 1.02],
	[0.520, 0.372, 0.86, 0.94],
	[0.522, 0.578, 0.88, 0.96],

	# LE CORPS DU FLUX, qui vient de la gauche en s'inclinant vers l'ouverture.
	[0.470, 0.424, 0.92, 1.02],
	[0.468, 0.520, 0.92, 1.02],
	[0.462, 0.330, 0.80, 0.92],
	[0.464, 0.636, 0.80, 0.92],
	[0.408, 0.386, 0.88, 1.00],
	[0.404, 0.486, 0.90, 1.04],
	[0.410, 0.582, 0.86, 0.98],
	[0.352, 0.330, 0.76, 0.92],
	[0.348, 0.446, 0.84, 1.00],
	[0.344, 0.552, 0.82, 0.96],
	[0.356, 0.660, 0.72, 0.88],

	# LA QUEUE — dispersée, pâle, en retard. Une nuée n'a jamais de bord net, et
	# les traînards sont la moitié du sujet du jeu.
	[0.286, 0.392, 0.68, 0.90],
	[0.282, 0.512, 0.72, 0.94],
	[0.290, 0.616, 0.64, 0.88],
	[0.224, 0.336, 0.54, 0.84],
	[0.220, 0.464, 0.58, 0.86],
	[0.228, 0.578, 0.52, 0.82],
	[0.166, 0.418, 0.42, 0.78],
	[0.158, 0.542, 0.38, 0.76],
	[0.104, 0.478, 0.28, 0.72],
]
const DOT_R := 0.030              # rayon de base, en fraction de HAUTEUR

var _out := "reports/art"

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)

	var w: int = OUT_SIZE.x * SUPERSAMPLE
	var h: int = OUT_SIZE.y * SUPERSAMPLE
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	# LE POINT CHAUD DU FOND EST CELUI DE LA LUMIÈRE, pas le centre de l'image :
	# le dégradé travaille alors POUR la composition au lieu de la contredire.
	var light_px := Vector2(LIGHT_POS.x * float(w), LIGHT_POS.y * float(h))
	ArtKit.paint_background(img, light_px, float(w) * 0.92)

	var light_r: float = LIGHT_R * float(h)
	ArtKit.glow(img, light_px, light_r * 7.0, ArtKit.LIGHT, 0.34)
	ArtKit.glow(img, light_px, light_r * 2.8, ArtKit.LIGHT, 0.52)

	_paint_wall(img)

	# La lumière PAR-DESSUS le mur : elle est derrière lui dans la fiction, mais
	# un disque chaud à moitié mangé par une barre sombre ne se lit plus.
	ArtKit.disc(img, light_px, light_r, ArtKit.LIGHT, 1.0)

	for entry in SWARM:
		var p := Vector2(float(entry[0]) * float(w), float(entry[1]) * float(h))
		var brightness: float = float(entry[2])
		var radius: float = DOT_R * float(h) * float(entry[3])
		# Un halo par agent, faible : c'est ce qui fait qu'une nuée respire au
		# lieu de ressembler à des confettis posés sur un fond.
		ArtKit.glow(img, p, radius * 3.2, ArtKit.AGENT, 0.10 * brightness)
		ArtKit.disc(img, p, radius, ArtKit.AGENT, 0.30 + 0.70 * brightness)

	ArtKit.write(img, OUT_SIZE, _out.path_join("feature_graphic_1024x500.png"), true)
	print("Bannière écrite : %s/feature_graphic_1024x500.png (1024×500, sans alpha)"
		% _out)
	quit()

## LE MUR EST VERTICAL, PERCÉ D'UNE SEULE OUVERTURE, et ses bords s'estompent
## vers le haut et le bas de l'image. Un mur net qui touche les deux bords
## enferme la composition ; estompé, il se prolonge hors cadre — ce qui est
## exactement ce qu'un mur fait dans le jeu.
func _paint_wall(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var x0: int = int((WALL_X - WALL_HALF) * float(w))
	var x1: int = int((WALL_X + WALL_HALF) * float(w))
	var gap_top: float = GAP_TOP * float(h)
	var gap_bottom: float = GAP_BOTTOM * float(h)

	for y in range(h):
		var fy: float = float(y) + 0.5
		if fy > gap_top and fy < gap_bottom:
			continue
		# Extinction vers les bords hauts et bas. Courte, désormais : à un
		# cinquième de la hauteur, le mur n'existait plus qu'au milieu.
		var fade: float = 1.0
		var edge: float = float(h) * 0.10
		if fy < edge:
			fade = fy / edge
		elif fy > float(h) - edge:
			fade = (float(h) - fy) / edge
		# Adoucissement des deux lèvres de l'ouverture, pour que le passage ne
		# soit pas découpé à l'emporte-pièce.
		var lip: float = float(h) * 0.035
		if fy >= gap_top - lip and fy <= gap_top:
			fade *= (gap_top - fy) / lip
		elif fy >= gap_bottom and fy <= gap_bottom + lip:
			fade *= (fy - gap_bottom) / lip
		var f: float = clampf(fade, 0.0, 1.0)
		for x in range(x0, x1):
			ArtKit.blend(img, x, y, ArtKit.WALL, f)
		# LES DEUX ARÊTES SONT ÉCLAIRÉES, d'un filet plus clair d'un pixel :
		# c'est ce qui détache le mur du fond. Sans lui, deux teintes sombres
		# voisines se confondent dès que l'image est vue en vignette — et une
		# bannière est vue en vignette la plupart du temps.
		var rim := ArtKit.WALL.lightened(0.42)
		ArtKit.blend(img, x0, y, rim, 0.85 * f)
		ArtKit.blend(img, x1 - 1, y, rim, 0.85 * f)
