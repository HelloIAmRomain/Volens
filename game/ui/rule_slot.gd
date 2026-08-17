class_name RuleSlot
extends RuleTouchTarget
## Un emplacement de la pile [RG-05, DCT §9.2].
##
## L'EMPLACEMENT N'A PAS DE TEINTE PROPRE (charte des couleurs, `ViewPalette`).
## Il en portait une — 1 cyan, 2 ambre, 3 magenta, 4 vert — et c'était une
## erreur de fond : ambre est la teinte de la lumière, vert celle de la
## sortie. La couleur de l'emplacement 2 était donc celle du but. Tenable au
## chapitre 1, ingérable au chapitre 4 avec neuf éléments à l'écran.
##
## Un emplacement est un RANG. Il s'identifie par sa position et son numéro —
## ce qui est d'ailleurs plus juste, puisque tout le jeu tient à l'ordre et
## qu'un ordre ne se lit pas dans un arc-en-ciel.

signal rule_dropped(slot_index: int, rule_id: int, from_slot: int)
signal remove_requested(slot_index: int)

var slot_index: int = 0
var rule_id: int = RuleRegistry.EMPTY
## Le niveau déclare moins de rangs que la pile n'en comptera (`slots`).
## L'emplacement est montré — le joueur doit savoir que la pile grandira —
## mais il n'est ni utilisable ni de la même nature qu'un rang ouvert.
var locked: bool = false
var selected: bool = false:
	set(value):
		selected = value
		_refresh()

var _label: Label
var _glyph: Label
var _rank: Label
var _style: StyleBoxFlat
var _remove: _RemoveButton
var _content: VBoxContainer
var _next_available: bool = false

func _init(index: int = 0) -> void:
	slot_index = index
	custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	super()
	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(12)
	_style.set_border_width_all(3)
	add_theme_stylebox_override("panel", _style)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_content = box

	# Le RANG est écrit en permanence, occupé ou non : c'est lui, et non une
	# couleur, qui identifie l'emplacement (charte des couleurs).
	_rank = Label.new()
	_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rank.add_theme_font_size_override("font_size", UiMetrics.font_size(18))
	_rank.text = str(slot_index + 1)
	box.add_child(_rank)

	_glyph = Label.new()
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph.add_theme_font_size_override("font_size", UiMetrics.font_size(38))
	box.add_child(_glyph)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", UiMetrics.font_size(20))
	box.add_child(_label)

	# Retrait : petit à l'œil, ≥ 48 dp au doigt (ENF-01). La forme est
	# DESSINÉE, pas tirée d'une police : tout notre visuel est procédural, et
	# rien ne doit dépendre de la couverture d'une fonte.
	_remove = _RemoveButton.new()
	_remove.pressed_remove.connect(func() -> void: remove_requested.emit(slot_index))
	add_child(_remove)

	_refresh()

## Glisse le contenu depuis la droite : une compaction instantanée se lit
## comme un bug, une glissade se lit comme une intention.
func set_next_available(value: bool) -> void:
	if _next_available == value:
		return
	_next_available = value
	_refresh()

func set_rule(new_rule_id: int, slide: bool = false) -> void:
	var changed: bool = rule_id != new_rule_id
	rule_id = new_rule_id
	_refresh()
	if slide and changed and _content != null:
		_content.position.x = size.x * 0.5
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_content, "position:x", 0.0, 0.20)

## Verrouille ou ouvre le rang. Un rang verrouillé ne reçoit aucun geste.
func set_locked(value: bool) -> void:
	if locked == value:
		return
	locked = value
	mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
	# UN RANG VERROUILLÉ NE SE MONTRE PAS, ET GARDE SA PLACE.
	#
	# Il se montrait, plus étroit que les autres, pour « indiquer ce qui vient ».
	# Verdict de l'essai : « inutile, moche — pas la même taille — et ça perturbe
	# le joueur ». C'est juste sur les trois points, et le troisième est le pire :
	# un rang visible mais inerte se lit comme un rang cassé, pas comme un rang
	# à venir. Le joueur essaie d'y poser une règle et rien ne répond.
	#
	# IL GARDE POURTANT SON QUART DE LARGEUR. Sans cela, les rangs ouverts
	# s'étireraient pour occuper la barre : un niveau à un rang montrerait une
	# tuile pleine largeur, un niveau à trois des tuiles étroites, et la même
	# règle changerait de taille d'un niveau à l'autre. Une cible tactile qui
	# bouge se rate.
	# TRANSPARENT, PAS CACHÉ : un enfant invisible est ignoré par le conteneur,
	# et les rangs restants s'étireraient pour occuper la barre — exactement la
	# largeur variable qu'on veut supprimer. On le rend donc INVISIBLE À L'ŒIL
	# tout en le laissant occuper sa part.
	modulate = Color(1.0, 1.0, 1.0, 0.0 if locked else 1.0)
	size_flags_stretch_ratio = 1.0
	_refresh()

func _refresh() -> void:
	if _label == null:
		return
	if locked:
		# Invisible : rien à peindre. On vide tout de même le contenu, pour
		# qu'un rang rendu visible plus tard ne réapparaisse pas garni.
		_glyph.text = ""
		_label.text = ""
		if _remove != null:
			_remove.visible = false
		return
	var color := ViewPalette.SLOT_IDLE
	if rule_id == RuleRegistry.EMPTY:
		_glyph.text = ""
		_label.text = ""
		_style.bg_color = Color(0.09, 0.10, 0.13, 0.85)
		# Le PROCHAIN rang libre invite ; les suivants sont du décor.
		_style.border_color = Color(color, 0.55 if _next_available else 0.20)
		_rank.add_theme_color_override("font_color", Color(color, 0.85 if _next_available else 0.40))
	else:
		# Rang occupé : le GLYPHE de la règle porte l'identité, l'emplacement
		# n'apporte que sa luminosité. Aucune teinte n'est empruntée.
		color = ViewPalette.SLOT_FILLED
		_glyph.text = RuleCatalog.glyph_of(rule_id)
		_glyph.add_theme_color_override("font_color", color)
		_label.text = RuleCatalog.name_of(rule_id)
		_label.add_theme_color_override("font_color", Color(0.90, 0.93, 1.0))
		_style.bg_color = Color(0.16, 0.18, 0.23, 0.95)
		_style.border_color = color
		_rank.add_theme_color_override("font_color", Color(color, 0.65))
	_apply_selection(color)
	if _remove != null:
		# Visible seulement quand un emplacement OCCUPÉ est sélectionné :
		# rien à retirer d'un emplacement vide.
		_remove.visible = selected and rule_id != RuleRegistry.EMPTY
		_remove.position = Vector2(size.x - _remove.size.x, 0.0)

## La sélection doit se voir sans ambiguïté : bordure épaissie, fond éclairci,
## halo clair. C'est le seul retour dont dispose le joueur entre le geste qui
## sélectionne et celui qui destine.
func _apply_selection(color: Color) -> void:
	if selected:
		_style.set_border_width_all(6)
		_style.border_color = Color(1.0, 1.0, 1.0, 0.95)
		_style.bg_color = Color(color.r, color.g, color.b, 0.34)
		_style.shadow_color = Color(1.0, 1.0, 1.0, 0.30)
		_style.shadow_size = 10
	else:
		_style.set_border_width_all(3)
		_style.shadow_size = 0

func _drag_payload() -> Variant:
	if rule_id == RuleRegistry.EMPTY:
		return null
	return {"rule_id": rule_id, "from_slot": slot_index}

func _drag_preview() -> Control:
	return RuleTouchTarget.make_preview(rule_id)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("rule_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d := data as Dictionary
	rule_dropped.emit(slot_index, int(d["rule_id"]), int(d.get("from_slot", -1)))


## Zone tactile pleine (ENF-01), icône dessinée petite au coin.
class _RemoveButton extends Control:
	signal pressed_remove

	func _init() -> void:
		custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		visible = false

	func _draw() -> void:
		# Corbeille : un couvercle, une cuve, deux rainures. Dessinée en
		# primitives, jamais un glyphe de police.
		var c := Color(1.0, 0.62, 0.60, 0.95)
		var cx: float = size.x - 30.0
		var cy: float = 30.0
		var w := 16.0
		var h := 18.0
		draw_line(Vector2(cx - w * 0.7, cy - h * 0.5), Vector2(cx + w * 0.7, cy - h * 0.5), c, 3.0)
		draw_line(Vector2(cx - 4.0, cy - h * 0.5 - 4.0), Vector2(cx + 4.0, cy - h * 0.5 - 4.0), c, 3.0)
		draw_rect(Rect2(cx - w * 0.5, cy - h * 0.5, w, h), c, false, 3.0)
		draw_line(Vector2(cx - 3.0, cy - 4.0), Vector2(cx - 3.0, cy + 5.0), c, 2.0)
		draw_line(Vector2(cx + 3.0, cy - 4.0), Vector2(cx + 3.0, cy + 5.0), c, 2.0)

	func _gui_input(event: InputEvent) -> void:
		var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
			or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
		if pressed:
			pressed_remove.emit()
			accept_event()
