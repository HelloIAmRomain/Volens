class_name RuleTouchTarget
extends PanelContainer
## Base commune des cibles tactiles portant une règle : emplacement de pile
## et pastille de bibliothèque. Elle ne fait qu'une chose, mais c'est celle
## où ce genre d'interface casse : **discriminer trois gestes sur un même
## appui maintenu**.
##
##   appui bref, sans mouvement      → SÉLECTION       (chemin sans glissement)
##   appui maintenu, sans mouvement  → EXPLICATION     (appui long)
##   appui puis mouvement            → GLISSEMENT      (pris en charge par Godot)
##
## Ordre de décision : le mouvement l'emporte toujours. Dès que le doigt
## dépasse le seuil, l'appui est annulé — sans quoi un glissement commencé
## lentement déclencherait une explication en cours de route.
##
## La sélection est émise au RELÂCHEMENT, jamais à l'appui : sinon un
## glissement sélectionnerait au passage ce qu'il s'apprête à déplacer.

signal tapped
signal long_pressed

var _press_elapsed: float = -1.0
var _press_origin: Vector2 = Vector2.ZERO
var _drag_started: bool = false

func _ready() -> void:
	set_process(true)

## À redéfinir : la charge utile du glissement, ou null si rien à glisser.
func _drag_payload() -> Variant:
	return null

## À redéfinir : l'aperçu affiché sous le doigt pendant le glissement.
func _drag_preview() -> Control:
	return null

func _process(delta: float) -> void:
	if _press_elapsed < 0.0:
		return
	_press_elapsed += delta
	if _press_elapsed >= UiMetrics.LONG_PRESS_SECONDS:
		_press_elapsed = -1.0
		long_pressed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_handle_press(mb.pressed, mb.position)
		accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_handle_press(st.pressed, st.position)
		accept_event()
	elif event is InputEventMouseMotion:
		_handle_motion((event as InputEventMouseMotion).position)
	elif event is InputEventScreenDrag:
		_handle_motion((event as InputEventScreenDrag).position)

func _handle_press(pressed: bool, position: Vector2) -> void:
	if pressed:
		_press_origin = position
		_press_elapsed = 0.0
		_drag_started = false
		return
	# Relâchement : sélection seulement si ni glissement ni appui long.
	if not _drag_started and _press_elapsed >= 0.0:
		tapped.emit()
	_press_elapsed = -1.0

func _handle_motion(position: Vector2) -> void:
	if _press_elapsed < 0.0:
		return
	if position.distance_to(_press_origin) > UiMetrics.DRAG_THRESHOLD:
		# Le mouvement l'emporte : ni sélection, ni explication.
		_press_elapsed = -1.0

func _get_drag_data(_at_position: Vector2) -> Variant:
	var payload: Variant = _drag_payload()
	if payload == null:
		return null
	_drag_started = true
	_press_elapsed = -1.0
	# `set_drag_preview` exige un glissement réellement en cours côté moteur.
	# La garde rend la méthode appelable hors glissement — ce que font les
	# tests, et ce que ferait tout appel programmatique.
	var preview := _drag_preview()
	if preview != null and get_viewport() != null and get_viewport().gui_is_dragging():
		set_drag_preview(preview)
	return payload

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_drag_started = false
		_press_elapsed = -1.0

## Aperçu partagé : une pastille sobre sous le doigt.
static func make_preview(rule_id: int) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color(0.55, 0.75, 0.95, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "  %s  %s  " % [RuleCatalog.glyph_of(rule_id), RuleCatalog.name_of(rule_id)]
	label.add_theme_font_size_override("font_size", 24)
	panel.add_child(label)
	return panel
