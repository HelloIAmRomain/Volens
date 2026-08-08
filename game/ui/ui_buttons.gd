class_name UiButtons
extends RefCounted
## Fabrique unique des boutons de l'interface.
##
## POURQUOI ELLE EXISTE. Cinq écrans construisaient leurs boutons chacun de
## son côté : trois `_make_button` de signatures différentes et des
## `Button.new()` bruts. Chacun redéclarait la taille minimale de cible
## tactile — la garantie ENF-01 tenait donc à cinq endroits qui pouvaient
## diverger, et un écran ajouté demain l'aurait oubliée sans que rien ne le
## dise.
##
## Ici, **aucun bouton ne peut naître sous la cible minimale** : c'est la
## fabrique qui la pose, pas l'appelant. C'est le même raisonnement que la
## source de vérité unique de `slots` (invariant n°11) appliqué à l'interface.
##
## LES QUATRE REGISTRES. La hiérarchie porte sur la **forme et la taille**,
## jamais sur la seule couleur (ENF-20) :
##   PRIMARY   — l'action principale d'un écran : plein, accentué, 1,24× plus
##               grand. Un seul par écran, sinon il n'y a plus de primaire.
##   SECONDARY — contour, taille normale.
##   QUIET     — sans fond, ton bas : ce qu'on ne veut pas déclencher par
##               erreur (fermer, réinitialiser).
##   PLAIN     — aucun habillage, le thème décide. C'est le registre des
##               menus, où tous les choix se valent (P2 : le jeu ne pousse
##               jamais à enchaîner).

enum Rank { PRIMARY, SECONDARY, QUIET, PLAIN }

## Agrandissement du registre primaire ⚙️ : assez pour se distinguer au pouce
## sans déséquilibrer la barre.
const PRIMARY_SCALE := 1.24
const DEFAULT_FONT_SIZE := 30

static func make(text: String, rank: int = Rank.PLAIN,
		font_size: int = DEFAULT_FONT_SIZE, tooltip: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if not tooltip.is_empty():
		b.tooltip_text = tooltip
	var scale: float = PRIMARY_SCALE if rank == Rank.PRIMARY else 1.0
	# ENF-01, posé ici et nulle part ailleurs.
	b.custom_minimum_size = Vector2(
		UiMetrics.MIN_TOUCH_TARGET * scale, UiMetrics.MIN_TOUCH_TARGET * scale)
	b.add_theme_font_size_override("font_size", int(font_size * scale))
	if rank != Rank.PLAIN:
		_apply_rank(b, rank)
	return b

static func _apply_rank(b: Button, rank: int) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(16)
	match rank:
		Rank.PRIMARY:
			normal.bg_color = Color(0.20, 0.42, 0.62, 0.95)
			normal.set_border_width_all(2)
			normal.border_color = Color(0.62, 0.86, 1.0, 0.9)
			b.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
		Rank.SECONDARY:
			normal.bg_color = Color(0.08, 0.10, 0.14, 0.85)
			normal.set_border_width_all(2)
			normal.border_color = Color(0.40, 0.48, 0.60, 0.75)
			b.add_theme_color_override("font_color", Color(0.80, 0.86, 0.95))
		_:
			normal.bg_color = Color(0.06, 0.07, 0.10, 0.55)
			normal.set_border_width_all(1)
			normal.border_color = Color(0.28, 0.32, 0.40, 0.45)
			b.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
	var hovered := normal.duplicate() as StyleBoxFlat
	hovered.bg_color = normal.bg_color.lightened(0.10)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hovered)
	b.add_theme_stylebox_override("pressed", hovered)
	b.add_theme_stylebox_override("focus", normal)
