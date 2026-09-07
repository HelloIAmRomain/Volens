class_name ArtKit
extends RefCounted
## PALETTE ET PRIMITIVES DE DESSIN PARTAGÉES par les visuels procéduraux.
##
## POURQUOI CE FICHIER EXISTE. L'icône du lanceur et la bannière du Play Store
## sont deux images distinctes, mais elles se regardent COTE A COTE sur la fiche
## du magasin. Deux jeux de couleurs recopiés auraient dérivé au premier
## ajustement — et une fiche dont l'icône et la bannière ne sont pas de la même
## famille se lit comme un assemblage de pièces empruntées.
##
## C'est la même règle que partout ailleurs dans ce dépôt : une valeur qui
## compte à deux endroits a UNE source (invariant n°16).
##
## LES PRIMITIVES TRAVAILLENT EN PIXELS, PAS EN COORDONNÉES NORMALISÉES, et
## c'est délibéré. L'icône est carrée, la bannière fait 1024×500 : un rayon
## exprimé en fraction de largeur y devient un ovale. Chaque appelant convertit
## ses propres repères, une fois, et les primitives ne se posent plus la
## question.
##
## AUCUNE TEXTURE IMPORTÉE, jamais — DT-13. Tout ce que ce fichier sait faire,
## il le calcule.

# --- palette, reprise de ViewPalette et jamais réinventée ---------------------

const AGENT := Color(0.82, 0.93, 1.00)
const LIGHT := Color(1.00, 0.92, 0.68)
const EXIT := Color(0.20, 0.78, 0.56)

## LE MUR EST PLUS CLAIR QUE CELUI DU JEU. À (0.16, 0.17, 0.23) sur un fond à
## 0.078, l'écart était de sept pour cent : la barre existait sans se lire, et
## il ne restait qu'une lumière au-dessus d'un flux de points. Un mur qu'on ne
## voit pas ne dit pas pourquoi la nuée se resserre.
const WALL := Color(0.255, 0.275, 0.345)

## LE FOND EST PLUS CLAIR QUE CELUI DU JEU. `ViewPalette` descend à
## (0.027, 0.031, 0.047) — juste ce qu'il faut pour que la nuée domine un écran.
## Sur une vignette de magasin, ce même noir fait disparaître l'image dans la
## page : elle n'a plus de corps.
const BG_CORE := Color(0.078, 0.086, 0.145)
const BG_EDGE := Color(0.027, 0.031, 0.055)

## Mélange un pixel, en respectant ce qui s'y trouve déjà. Hors cadre : ignoré,
## pour que les appelants n'aient pas à border chaque boucle.
static func blend(img: Image, x: int, y: int, color: Color, alpha: float) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if alpha <= 0.0:
		return
	var under := img.get_pixel(x, y)
	var a: float = clampf(alpha, 0.0, 1.0)
	img.set_pixel(x, y, under.lerp(color, a))

## Disque plein, bord adouci sur un pixel. Centre et rayon en PIXELS.
static func disc(img: Image, centre: Vector2, radius: float,
		color: Color, alpha: float) -> void:
	if radius <= 0.0:
		return
	var x0: int = int(floorf(centre.x - radius)) - 1
	var x1: int = int(ceilf(centre.x + radius)) + 1
	var y0: int = int(floorf(centre.y - radius)) - 1
	var y1: int = int(ceilf(centre.y + radius)) + 1
	for y in range(y0, y1):
		for x in range(x0, x1):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(centre)
			if d > radius + 1.0:
				continue
			# Couverture approchée sur la dernière frange : le reste de
			# l'anticrénelage vient de la réduction finale.
			var cover: float = clampf(radius + 0.5 - d, 0.0, 1.0)
			blend(img, x, y, color, alpha * cover)

## Halo doux — une décroissance quadratique, pas un dégradé linéaire : le
## linéaire produit un bord visible là où l'œil attend une extinction.
static func glow(img: Image, centre: Vector2, radius: float,
		color: Color, strength: float) -> void:
	if radius <= 0.0:
		return
	var x0: int = maxi(int(centre.x - radius) - 1, 0)
	var x1: int = mini(int(centre.x + radius) + 1, img.get_width())
	var y0: int = maxi(int(centre.y - radius) - 1, 0)
	var y1: int = mini(int(centre.y + radius) + 1, img.get_height())
	for y in range(y0, y1):
		for x in range(x0, x1):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(centre)
			if d > radius:
				continue
			var t: float = 1.0 - (d / radius)
			blend(img, x, y, color, strength * t * t)

## Fond en dégradé radial, du cœur vers les bords. `focus` est le point chaud,
## en pixels ; `reach` la distance à laquelle on atteint la teinte de bord.
static func paint_background(img: Image, focus: Vector2, reach: float) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(focus)
			var t: float = clampf(d / maxf(reach, 1.0), 0.0, 1.0)
			img.set_pixel(x, y, BG_CORE.lerp(BG_EDGE, t * t))

## Écrit un PNG, en réduisant si demandé. `opaque` retire la couche alpha —
## exigence du Play Store pour la bannière, qui refuse la transparence.
static func write(img: Image, size: Vector2i, path: String,
		opaque: bool = false) -> void:
	var out := img.duplicate() as Image
	if out.get_size() != size:
		out.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	if opaque:
		out.convert(Image.FORMAT_RGB8)
	var full: String = path if path.begins_with("res://") else "res://" + path
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(full.get_base_dir()))
	out.save_png(ProjectSettings.globalize_path(full))
