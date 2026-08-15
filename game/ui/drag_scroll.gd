class_name DragScroll
extends Node
## DÉFILEMENT AU DOIGT, N'IMPORTE OÙ DANS LA LISTE.
##
## LE DÉFAUT QU'IL CORRIGE, signalé à l'essai sur l'appareil : « je ne peux pas
## scroller n'importe où. Si j'ai le doigt sur un niveau — la plupart de
## l'écran — alors le scroll ne fonctionne pas. Il fonctionne uniquement entre
## les niveaux ou sur le titre de chapitre. »
##
## CAUSE. Les tuiles sont des `Button`, et un bouton CAPTE le doigt : il reçoit
## l'appui, puis les glissements, et les ignore. Le `ScrollContainer` ne voit
## jamais rien. Les seules zones qui défilaient étaient les quelques pixels de
## gouttière entre deux tuiles — c'est-à-dire l'espace vide, soit exactement ce
## que personne ne vise.
##
## POURQUOI PAS `mouse_filter = PASS` SUR LES BOUTONS. Parce que le
## comportement dépend alors de qui, dans la chaîne des parents, accepte quel
## type d'événement — un détail d'implémentation du moteur qu'aucun test du
## projet ne fixe, et qui peut changer d'une version à l'autre. Ici la règle est
## écrite : au-delà d'un seuil de mouvement, c'est un défilement ; en deçà,
## c'est un appui.
##
## COMMENT. Le composant écoute dans `_input`, qui passe AVANT l'interface : il
## voit donc le geste même quand un bouton s'apprête à le manger. Il ne
## consomme jamais l'appui initial — sans quoi plus aucun bouton ne
## fonctionnerait — et se contente de faire défiler dès que le doigt bouge assez.
##
## L'APPUI EST ANNULÉ PAR LE GLISSEMENT, et c'est la moitié du travail : sans
## cela, relâcher après avoir fait défiler ouvrirait le niveau sous le doigt.
## Les écrans interrogent `consumed_drag()` avant d'agir sur un `pressed`.

## Distance au-delà de laquelle un geste cesse d'être un appui.
##
## CALIBRÉ SUR LA CIBLE TACTILE, jamais en pixels absolus : un seuil fixe est
## trop lâche sur un écran dense et trop serré sur un petit. Un huitième de la
## cible minimale (ENF-01) laisse passer le tremblement d'un pouce posé, et
## réagit dès que le geste est une intention de faire défiler.
const DRAG_THRESHOLD := UiMetrics.MIN_TOUCH_TARGET * 0.125

## Durée pendant laquelle un `pressed` reste refusé après un glissement. Le
## relâchement arrive dans la même image, mais un appui légitime ne peut pas
## suivre un défilement d'aussi près.
const GUARD_SECONDS := 0.25

var _scroll: ScrollContainer
var _touching := false
var _dragged := false
var _from := Vector2.ZERO
var _scroll_at_start := 0
var _guard_until := 0.0

## Branche le défilement au doigt sur un conteneur. Le composant vit comme
## enfant du conteneur : il disparaît avec lui, et rien à défaire.
static func attach(scroll: ScrollContainer) -> DragScroll:
	var node := DragScroll.new()
	node.name = "DragScroll"
	node._scroll = scroll
	scroll.add_child(node)
	return node

## Le dernier geste était-il un défilement ? Les écrans s'en servent pour
## ignorer un `pressed` qui n'est que la fin d'un glissement.
func consumed_drag() -> bool:
	return _dragged or _now() < _guard_until

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _input(event: InputEvent) -> void:
	if _scroll == null or not _scroll.is_visible_in_tree():
		return

	# Le poste de travail n'emet pas d'evenement tactile : le geste s'y ouvre et
	# s'y ferme au bouton gauche. Un defilement qui ne marcherait que sur
	# l'appareil ne serait verifiable nulle part ailleurs — or c'est au poste de
	# travail que se font les captures et les tests d'interface.
	if event is InputEventMouseButton \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var click := event as InputEventMouseButton
		if click.pressed:
			_touching = _scroll.get_global_rect().has_point(click.position)
			_dragged = false
			_from = click.position
			_scroll_at_start = _scroll.scroll_vertical
		else:
			if _dragged:
				_guard_until = _now() + GUARD_SECONDS
			_touching = false
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# LE GESTE DOIT COMMENCER DANS LA LISTE. Sans ce contrôle, un
			# glissement n'importe où sur l'écran — y compris sur le bouton
			# « Retour » — ferait défiler une liste que le doigt ne touche pas.
			_touching = _scroll.get_global_rect().has_point(touch.position)
			_dragged = false
			_from = touch.position
			_scroll_at_start = _scroll.scroll_vertical
		else:
			if _dragged:
				_guard_until = _now() + GUARD_SECONDS
			_touching = false
		return

	if not _touching:
		return

	# Souris ET tactile : le banc de visualisation et les captures tournent sur
	# un poste de travail, où le geste est un glissement de souris. Un
	# défilement qui ne marcherait que sur l'appareil ne serait vérifiable
	# nulle part ailleurs.
	var pos := Vector2.ZERO
	if event is InputEventScreenDrag:
		pos = (event as InputEventScreenDrag).position
	elif event is InputEventMouseMotion \
			and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pos = (event as InputEventMouseMotion).position
	else:
		return

	var moved: float = pos.y - _from.y
	if not _dragged and absf(moved) < DRAG_THRESHOLD:
		return
	_dragged = true
	_scroll.scroll_vertical = _scroll_at_start - int(moved)

