extends SceneTree
## GÉNÉRATEUR D'ICÔNE — procédural, déterministe, sans aucune dépendance.
##
## POURQUOI UN SCRIPT ET NON UNE IMAGE. Le projet interdit toute texture
## importée (DT-13 : « tout le visuel est procédural ») et toute dépendance
## externe. Une icône dessinée à la main dans un éditeur serait le seul pixel du
## jeu que personne ne pourrait ni reproduire ni corriger. Celle-ci se
## régénère d'une commande, à toutes les tailles, et son code EST sa
## documentation.
##
## CE QU'ELLE REPRÉSENTE : l'idiome du jeu, et rien d'autre.
##
##   « La nuée ne va pas vers la sortie : elle va vers la lumière, et le mur
##     l'oblige à passer par l'ouverture. » (docs/ARCHITECTURE.md)
##
## Une lumière chaude en haut, un mur en travers, une ouverture, et la nuée qui
## converge en coin vers ce passage — deux agents déjà franchis, les traînards
## encore dispersés en bas. C'est la seule image qui dise à la fois le sujet
## (une forme collective), le mécanisme (la contrainte qui ordonne) et la
## promesse (le passage).
##
## POURQUOI PAS L'ANCIENNE. C'était un amas de points pâles sur un fond presque
## noir : sans silhouette, sans contraste sur un lanceur sombre, et sans rapport
## lisible avec le jeu. Une icône doit tenir à 48 pixels — celle-ci s'y réduit à
## un point brillant, une barre entaillée, et un coin de points qui monte.
##
## OÙ ÉCRIT-ELLE ? LE CHEMIN EST UN PARAMÈTRE, ET C'EST UNE RÈGLE, PAS UN GOÛT.
## `tools/` n'importe ni ne référence `game/` (règle de dépendance n°3) — la
## première version écrivait `res://game/ui/icon.png` en dur et le test
## d'architecture l'a refusée, à raison. Un générateur d'actifs n'a pas à savoir
## où le jeu range ses icônes : il produit des fichiers nommés, l'appelant
## décide de leur destination. Le couplage vit dans la ligne de commande, qui
## est l'endroit exact où il doit être.
##
## Usage :
##   godot --headless --path . --script res://tools/art/make_icon.gd -- \
##       --out=game/ui --apercus=reports/art

## Rendu en haute définition puis réduit : l'anticrénelage vient de la
## réduction, jamais d'un calcul de couverture par pixel — plus simple, et le
## résultat est le même.
const BASE := 1024

# --- palette, reprise de ViewPalette et jamais réinventée ---------------------

const AGENT := Color(0.82, 0.93, 1.00)
const LIGHT := Color(1.00, 0.92, 0.68)
const EXIT := Color(0.20, 0.78, 0.56)
const WALL := Color(0.16, 0.17, 0.23)

## LE FOND EST PLUS CLAIR QUE CELUI DU JEU, et c'est délibéré. `ViewPalette`
## descend à (0.027, 0.031, 0.047) — juste ce qu'il faut pour que la nuée
## domine un écran de jeu. Sur la grille d'un lanceur, ce même noir fait
## disparaître l'icône dans le fond d'écran : elle n'a plus de corps. Le fond
## est donc remonté vers un indigo profond, qui garde la famille de teintes
## sans se dissoudre.
const BG_CORE := Color(0.078, 0.086, 0.145)
const BG_EDGE := Color(0.027, 0.031, 0.055)

## Position du dispositif, en coordonnées normalisées (0..1).
##
## L'OUVERTURE EST DÉCENTRÉE, ET C'EST LE POINT. Une première version plaçait
## tout sur l'axe : la nuée y formait une pyramide parfaite sous une lumière
## centrée, et l'ensemble se lisait comme un **sapin de Noël**. Une symétrie
## parfaite ne dit ni le mouvement ni la direction — et elle contredit le jeu
## lui-même, qui est asymétrique gauche-droite (invariant n°19 : à égalité,
## toute règle préfère le Nord puis l'Est).
##
## La nuée arrive donc du bas-gauche et remonte vers une ouverture posée à
## droite de l'axe. On lit un FLUX, pas un tas.
const LIGHT_POS := Vector2(0.560, 0.163)
const LIGHT_R := 0.068
const WALL_TOP := 0.372
const WALL_BOTTOM := 0.452
const GAP_LEFT := 0.470
const GAP_RIGHT := 0.612

## LA NUÉE, POSÉE À LA MAIN. Un placement calculé (grille, bruit, spirale)
## donne une forme régulière ou aléatoire ; ni l'une ni l'autre ne ressemble à
## une nuée qui converge. Ces positions sont un DESSIN : chaque rangée est plus
## étroite que la précédente, et la base s'effiloche — c'est ce que fait une
## nuée devant un goulot, et c'est ce que le jeu montre à chaque partie.
const SWARM: Array = [
	# FRANCHIS — deux agents, entre l'ouverture et la lumière. Ils disent que le
	# passage MÈNE quelque part ; sans eux le mur n'est qu'une barre.
	# Ils ne TOUCHENT pas la lumiere : un agent colle au disque chaud se lit
	# comme une bavure, pas comme un agent qui monte vers elle.
	[0.548, 0.330, 1.00, 1.00],
	[0.520, 0.268, 0.90, 0.86],

	# LE GOULOT — serrés, brillants, alignés sur l'ouverture. C'est la
	# congestion, et c'est la plus belle chose que le jeu produise.
	[0.512, 0.502, 1.00, 1.05],
	[0.578, 0.516, 0.96, 1.00],
	[0.452, 0.528, 0.94, 0.98],

	# LE CORPS DU FLUX, qui monte de la gauche en s'inclinant vers l'ouverture.
	[0.396, 0.596, 0.92, 1.02],
	[0.478, 0.590, 0.96, 1.06],
	[0.560, 0.602, 0.92, 1.00],
	[0.638, 0.636, 0.82, 0.94],
	[0.330, 0.664, 0.86, 0.98],
	[0.414, 0.668, 0.92, 1.04],
	[0.498, 0.678, 0.90, 1.02],
	[0.582, 0.700, 0.80, 0.94],
	[0.268, 0.738, 0.78, 0.94],
	[0.352, 0.746, 0.84, 1.00],
	[0.438, 0.760, 0.82, 0.98],
	[0.524, 0.782, 0.72, 0.90],

	# LA QUEUE — dispersée, pâle, en retard. Une nuée n'a jamais de bord net, et
	# les traînards sont la moitié du sujet du jeu.
	[0.196, 0.812, 0.62, 0.88],
	[0.290, 0.826, 0.66, 0.92],
	[0.382, 0.848, 0.58, 0.86],
	[0.148, 0.888, 0.44, 0.80],
	[0.244, 0.902, 0.48, 0.82],
]
const DOT_R := 0.0300

var _out := "game/ui"
var _previews := "reports/art"

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--apercus="):
			_previews = arg.substr(10)

	var full := _render(BASE, 1.0, true)

	# ICÔNE PRINCIPALE ET LANCEUR HÉRITÉ.
	_write(full, 512, _out.path_join("icon.png"))
	# PLAY STORE : 512×512 exactement, c'est la seule taille acceptée.
	_write(full, 512, _previews.path_join("icon_play_512.png"))

	# ICÔNE ADAPTATIVE ANDROID — deux couches, et c'est la bonne façon de faire
	# depuis Android 8. Le lanceur découpe la forme lui-même (cercle, écusson,
	# goutte…) : une icône carrée unique s'y fait rogner n'importe comment.
	#
	# LE PREMIER PLAN NE PEUT PAS OCCUPER TOUTE SA SURFACE : le système n'en
	# garantit que les 66 % centraux, le reste sert au relief et au mouvement.
	# Le dispositif y est donc réduit d'autant, sur du transparent.
	var fg := _render(BASE, 0.66, false)
	var bg := _render(BASE, 1.0, true, true)
	_write(fg, 432, _out.path_join("icon_foreground.png"))
	_write(bg, 432, _out.path_join("icon_background.png"))
	# APERÇU COMPOSÉ — la seule image qui montre ce que le lanceur affichera.
	# Regarder le premier plan seul induit en erreur : il est fait de teintes
	# pâles sur du transparent, donc invisible sur le fond blanc d'une visionneuse
	# et parfaitement lisible sur le fond sombre auquel il est destiné.
	var composed := bg.duplicate() as Image
	composed.blend_rect(fg, Rect2i(Vector2i.ZERO, fg.get_size()), Vector2i.ZERO)
	_write(composed, 432, _previews.path_join("apercu_adaptatif.png"))
	_write(composed, 96, _previews.path_join("apercu_adaptatif_96.png"))

	# COUCHE MONOCHROME — icônes thématiques d'Android 13, et `minSdk` vaut 33 :
	# tous nos appareils la prennent. Le système la recolore d'après le fond
	# d'écran ; elle ne doit donc porter QUE des formes et de l'alpha, aucune
	# teinte. C'est le meilleur test de la silhouette : ce qui ne se lit pas en
	# aplat blanc ne se lira pas non plus une fois recoloré en vert pastel.
	_write(_render_mono(BASE, 0.66), 432, _out.path_join("icon_monochrome.png"))
	# Aperçu de la monochrome RECOLORÉE, comme le fait le système : la juger sur
	# du transparent ne dit rien — une visionneuse à fond blanc n'en montre que
	# les contours.
	var mono := _render_mono(BASE, 0.66)
	var tinted := Image.create(BASE, BASE, false, Image.FORMAT_RGBA8)
	tinted.fill(Color(0.16, 0.30, 0.24))
	for y in range(BASE):
		for x in range(BASE):
			var a: float = mono.get_pixel(x, y).a
			if a > 0.0:
				tinted.set_pixel(x, y,
					tinted.get_pixel(x, y).lerp(Color(0.78, 0.95, 0.86), a))
	_write(tinted, 192, _previews.path_join("apercu_mono_192.png"))

	_write(full, 192, _previews.path_join("apercu_192.png"))
	_write(full, 96, _previews.path_join("apercu_96.png"))
	_write(full, 48, _previews.path_join("apercu_48.png"))
	print("Icônes écrites dans %s ; aperçus dans %s." % [_out, _previews])
	quit()

## Rendu monochrome : les mêmes formes, en blanc, avec l'alpha pour seul relief.
func _render_mono(size: int, scale: float) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var centre := Vector2(0.5, 0.5)
	var at := func(p: Vector2) -> Vector2: return centre + (p - centre) * scale
	var white := Color(1, 1, 1)

	# LE MUR EST PLEIN ICI, sans dégradé de bord : en monochrome il n'y a pas de
	# fond pour le détacher, et un mur estompé disparaît purement et simplement.
	var y0: int = int(at.call(Vector2(0.0, WALL_TOP)).y * float(size))
	var y1: int = int(at.call(Vector2(0.0, WALL_BOTTOM)).y * float(size))
	var bl: float = at.call(Vector2(0.035, 0.0)).x
	var br: float = at.call(Vector2(0.965, 0.0)).x
	var gl: float = at.call(Vector2(GAP_LEFT, 0.0)).x
	var gr: float = at.call(Vector2(GAP_RIGHT, 0.0)).x
	for y in range(maxi(y0, 0), mini(y1, size)):
		for x in range(size):
			var u: float = float(x) / float(size)
			if u < bl or u > br or (u > gl and u < gr):
				continue
			_blend(img, x, y, white, 0.85)

	_disc(img, at.call(LIGHT_POS), LIGHT_R * scale, white, 1.0)
	for entry in SWARM:
		var p: Vector2 = at.call(Vector2(float(entry[0]), float(entry[1])))
		# L'alpha suit la brillance d'origine, mais relevé : le système peut
		# recolorer en teinte sombre, où les valeurs basses s'effondrent.
		var a: float = 0.45 + 0.55 * float(entry[2])
		_disc(img, p, DOT_R * scale * float(entry[3]), white, a)
	return img

func _write(img: Image, size: int, path: String) -> void:
	var out := img.duplicate() as Image
	if out.get_width() != size:
		out.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var full_path: String = path if path.begins_with("res://") else "res://" + path
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(full_path.get_base_dir()))
	out.save_png(ProjectSettings.globalize_path(full_path))

## `scale` réduit le dispositif autour du centre (couche de premier plan).
## `opaque` remplit le fond ; sinon l'image reste transparente.
## `background_only` ne dessine que le fond, sans le dispositif.
func _render(size: int, scale: float, opaque: bool,
		background_only: bool = false) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if opaque:
		_paint_background(img)
	if background_only:
		return img

	var centre := Vector2(0.5, 0.5)
	var at := func(p: Vector2) -> Vector2: return centre + (p - centre) * scale

	# LE HALO DE LUMIÈRE D'ABORD, sous tout le reste : c'est ce qui donne son
	# assise à l'image, et ce qui la rend reconnaissable en petit.
	_glow(img, at.call(LIGHT_POS), LIGHT_R * scale * 6.2, LIGHT, 0.40)
	_glow(img, at.call(LIGHT_POS), LIGHT_R * scale * 2.6, LIGHT, 0.55)

	_paint_wall(img, scale, at)

	# La lumière elle-même PAR-DESSUS le mur : elle est derrière lui dans la
	# fiction, mais un carré chaud à moitié mangé par une barre sombre ne se
	# lit plus. C'est une icône, pas une capture d'écran.
	_disc(img, at.call(LIGHT_POS), LIGHT_R * scale, LIGHT, 1.0)

	for entry in SWARM:
		var p: Vector2 = at.call(Vector2(float(entry[0]), float(entry[1])))
		var alpha: float = float(entry[2])
		# Le rayon varie légèrement d'un agent à l'autre : des pastilles
		# rigoureusement identiques se lisent comme une TRAME, pas comme une nuée.
		var r: float = DOT_R * scale * float(entry[3])
		# Chaque agent porte son propre halo : c'est ce qui fait qu'une nuée se
		# lit comme une masse lumineuse et non comme une grille de pastilles.
		_glow(img, p, r * 3.4, AGENT, 0.24 * alpha)
		_disc(img, p, r, AGENT, alpha)
	return img

func _paint_background(img: Image) -> void:
	var size: int = img.get_width()
	var centre := Vector2(0.5, 0.34)   # décentré vers le haut, sous la lumière
	for y in range(size):
		for x in range(size):
			var p := Vector2(float(x) / float(size), float(y) / float(size))
			var d: float = clampf(p.distance_to(centre) / 0.92, 0.0, 1.0)
			img.set_pixel(x, y, BG_CORE.lerp(BG_EDGE, d * d))

## LE MUR, ET SON OUVERTURE. Il est dessiné en deux segments plutôt qu'en un
## rectangle troué : l'ouverture est le SUJET, elle ne peut pas être un effet
## de bord du dessin.
func _paint_wall(img: Image, scale: float, at: Callable) -> void:
	var size: int = img.get_width()
	var top: Vector2 = at.call(Vector2(0.0, WALL_TOP))
	var bottom: Vector2 = at.call(Vector2(0.0, WALL_BOTTOM))
	var left_end: Vector2 = at.call(Vector2(GAP_LEFT, 0.0))
	var right_start: Vector2 = at.call(Vector2(GAP_RIGHT, 0.0))
	var band_left: Vector2 = at.call(Vector2(0.035, 0.0))
	var band_right: Vector2 = at.call(Vector2(0.965, 0.0))

	var y0: int = int(top.y * float(size))
	var y1: int = int(bottom.y * float(size))
	for y in range(maxi(y0, 0), mini(y1, size)):
		for x in range(size):
			var u: float = float(x) / float(size)
			if u < band_left.x or u > band_right.x:
				continue
			if u > left_end.x and u < right_start.x:
				continue
			# Les extrémités s'estompent, mais à peine : un mur trop fondu
			# disparaît à 48 pixels, et le dispositif entier avec lui — il ne
			# reste alors qu'une lumière au-dessus d'un tas de points.
			var fade: float = clampf(minf(u - band_left.x, band_right.x - u) / 0.035, 0.0, 1.0)
			_blend(img, x, y, WALL, fade)

	# LE SEUIL, EN VERT. C'est la marque du jeu — la sortie — et elle borde
	# l'ouverture des deux côtés, comme le fait le rendu du jeu.
	# Assez epais pour survivre a 48 pixels : deux traits d'un pixel y
	# disparaissent, et l'ouverture cesse d'etre une ouverture.
	var thickness: int = maxi(int(0.017 * float(size) * scale), 3)
	for y in range(maxi(y0, 0), mini(y1, size)):
		for k in range(thickness):
			var xl: int = int(left_end.x * float(size)) - k
			var xr: int = int(right_start.x * float(size)) + k
			var a: float = pow(1.0 - float(k) / float(thickness), 0.6)
			if xl >= 0 and xl < size:
				_blend(img, xl, y, EXIT, a)
			if xr >= 0 and xr < size:
				_blend(img, xr, y, EXIT, a)

# --- primitives --------------------------------------------------------------

func _disc(img: Image, centre: Vector2, radius: float, color: Color, alpha: float) -> void:
	var size: int = img.get_width()
	var r: float = radius * float(size)
	var c := centre * float(size)
	var x0: int = maxi(int(c.x - r) - 2, 0)
	var x1: int = mini(int(c.x + r) + 2, size)
	var y0: int = maxi(int(c.y - r) - 2, 0)
	var y1: int = mini(int(c.y + r) + 2, size)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			# Un pixel de transition : la réduction fera le reste, mais un bord
			# strictement dur ressort en escalier même après réduction.
			var a: float = clampf((r - d) / 1.5, 0.0, 1.0) * alpha
			if a > 0.0:
				_blend(img, x, y, color, a)

func _glow(img: Image, centre: Vector2, radius: float, color: Color, strength: float) -> void:
	var size: int = img.get_width()
	var r: float = radius * float(size)
	var c := centre * float(size)
	var x0: int = maxi(int(c.x - r), 0)
	var x1: int = mini(int(c.x + r) + 1, size)
	var y0: int = maxi(int(c.y - r), 0)
	var y1: int = mini(int(c.y + r) + 1, size)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c) / r
			if d >= 1.0:
				continue
			# Chute au cube : un halo linéaire fait un disque flou, pas une
			# lueur. C'est la même courbe que le shader de lumière du jeu.
			var f: float = (1.0 - d)
			_blend(img, x, y, color, f * f * f * strength)

func _blend(img: Image, x: int, y: int, color: Color, alpha: float) -> void:
	var a: float = clampf(alpha, 0.0, 1.0)
	if a <= 0.0:
		return
	var dst := img.get_pixel(x, y)
	var out_a: float = a + dst.a * (1.0 - a)
	if out_a <= 0.0:
		img.set_pixel(x, y, Color(0, 0, 0, 0))
		return
	var rgb: Vector3 = (Vector3(color.r, color.g, color.b) * a
		+ Vector3(dst.r, dst.g, dst.b) * dst.a * (1.0 - a)) / out_a
	img.set_pixel(x, y, Color(rgb.x, rgb.y, rgb.z, out_a))
