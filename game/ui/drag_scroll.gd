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

## INERTIE — la liste continue sur sa lancée, puis s'arrête.
##
## « Manque d'inertie lorsque je lève le doigt, ça s'arrête net. » Un défilement
## qui s'interrompt à l'instant où le doigt part ne se lit pas comme un objet
## qu'on pousse : il se lit comme une glissière qu'on tire. Le poids d'une liste
## vient entièrement de ce qu'elle fait APRÈS le geste.
##
## `FRICTION` est la fraction de vitesse conservée à chaque soixantième de
## seconde ; 0,93 donne environ une demi-seconde de course, assez pour sentir
## l'élan sans donner l'impression d'une liste qui échappe. `MIN_SPEED` coupe la
## queue asymptotique : sans elle, la liste dériverait d'un pixel toutes les
## secondes pendant une minute.
const FRICTION := 0.93
const MIN_SPEED := 24.0
## Au-delà, un geste vif deviendrait un saut incontrôlable.
const MAX_SPEED := 6000.0

var _scroll: ScrollContainer
var _touching := false
var _dragged := false
var _from := Vector2.ZERO
var _scroll_at_start := 0
var _guard_until := 0.0
## Vitesse du doigt à l'instant du relâchement, en pixels par seconde.
var _velocity := 0.0
var _last_pos := 0.0
var _last_time := 0.0
## Reste de défilement non appliqué : `scroll_vertical` est un ENTIER, et
## tronquer à chaque image perdrait toute la course lente d'une inertie qui
## s'éteint.
var _residue := 0.0
## Le doigt a-t-il déjà parlé ? Voir `_input` : dès qu'un évènement TACTILE
## arrive, les évènements souris deviennent des doublons émulés et sont ignorés.
var _touch_seen := false

## Branche le défilement au doigt sur un conteneur. Le composant vit comme
## enfant du conteneur : il disparaît avec lui, et rien à défaire.
## LE CONTENEUR CESSE DE DÉFILER TOUT SEUL, et c'est la condition pour que ce
## composant ait un sens.
##
## `ScrollContainer` possède SON PROPRE défilement tactile, qui s'engage au-delà
## de `scroll_deadzone` — nul par défaut, donc dès le premier pixel. Deux
## systèmes écrivaient alors `scroll_vertical` dans la même image : le nôtre en
## ABSOLU (position de départ moins déplacement), le sien en RELATIF (delta
## ajouté). Le résultat dépend de l'ordre, et l'ordre n'est pas garanti — d'où
## une liste qui accroche par moments sans qu'on puisse le reproduire.
##
## Une zone morte immense n'est pas un réglage de confort : c'est la façon
## d'annoncer que ce conteneur ne défile plus de lui-même. Un seul propriétaire
## du défilement, et il est ici.
const OWN_SCROLL_OFF := 1_000_000

static func attach(scroll: ScrollContainer) -> DragScroll:
	var node := DragScroll.new()
	node.name = "DragScroll"
	node._scroll = scroll
	scroll.scroll_deadzone = OWN_SCROLL_OFF
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
	# LE DOIGT PARLE DEUX FOIS, ET C'EST TOUT LE DÉFAUT DE FLUIDITÉ.
	#
	# Android émet, pour UN SEUL mouvement physique, un `InputEventScreenDrag`
	# **et** un `InputEventMouseMotion` émulé portant la MÊME position. Le
	# premier calculait la vitesse correctement ; le second, arrivant avec un
	# déplacement nul, la remettait à ZÉRO. Au relâchement, la vitesse rendue à
	# la liste était celle du dernier évènement reçu — souvent le doublon.
	#
	# D'où le symptôme exact rapporté à l'essai : « parfois le scroll se bloque,
	# ça s'arrête net, mais seulement à certains moments ». Le « parfois » venait
	# de l'ordre d'arrivée des deux évènements, qui n'est pas garanti.
	#
	# Dès qu'un évènement tactile est vu, la souris est donc ignorée pour de bon.
	# Le poste de travail, lui, n'en émet jamais : son chemin reste intact, et
	# c'est ce qui permet de continuer à éprouver le défilement hors appareil.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_touch_seen = true

	if not _touch_seen and event is InputEventMouseButton \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var click := event as InputEventMouseButton
		if click.pressed:
			_begin(click.position)
		else:
			_end()
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin(touch.position)
		else:
			_end()
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
	elif not _touch_seen and event is InputEventMouseMotion \
			and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pos = (event as InputEventMouseMotion).position
	else:
		return

	var moved: float = pos.y - _from.y
	if not _dragged and absf(moved) < DRAG_THRESHOLD:
		return
	_dragged = true
	_scroll.scroll_vertical = _scroll_at_start - int(moved)

	# Vitesse instantanée, relevée entre deux événements : c'est elle qui sera
	# rendue à la liste au relâchement.
	# UN ÉVÈNEMENT SANS DÉPLACEMENT NE DIT RIEN DE LA VITESSE, il dit seulement
	# que le système a reparlé. Le prendre en compte écrasait l'élan par un zéro.
	# Le verrou tactile ci-dessus supprime la cause ; ce contrôle garde le fond,
	# car un pilote peut toujours répéter une position sans que ce soit un arrêt.
	var t := _now()
	var dt: float = t - _last_time
	if dt > 0.0005 and not is_equal_approx(pos.y, _last_pos):
		_velocity = clampf((pos.y - _last_pos) / dt, -MAX_SPEED, MAX_SPEED)
		_last_pos = pos.y
		_last_time = t


## LE GESTE DOIT COMMENCER DANS LA LISTE. Sans ce contrôle, un glissement
## n'importe où sur l'écran — y compris sur le bouton « Retour » — ferait
## défiler une liste que le doigt ne touche pas.
##
## POSER LE DOIGT ARRÊTE L'INERTIE, comme sur n'importe quelle liste : c'est le
## geste qu'on fait quand la course va trop loin, et il doit répondre.
func _begin(at: Vector2) -> void:
	_touching = _scroll.get_global_rect().has_point(at)
	_dragged = false
	_from = at
	_scroll_at_start = _scroll.scroll_vertical
	_velocity = 0.0
	_residue = 0.0
	_last_pos = at.y
	_last_time = _now()

func _end() -> void:
	if _dragged:
		_guard_until = _now() + GUARD_SECONDS
		# L'inertie ne part que si le doigt bougeait ENCORE au moment de partir.
		# Un doigt posé, traîné, puis immobilisé une demi-seconde avant d'être
		# levé ne veut pas lancer la liste : il veut la poser là.
		if _now() - _last_time > 0.10:
			_velocity = 0.0
	else:
		_velocity = 0.0
	_touching = false

func _process(delta: float) -> void:
	if _scroll == null or _touching or absf(_velocity) < MIN_SPEED:
		_velocity = 0.0
		return
	# Le défilement suit le doigt : le doigt monte, la liste descend.
	_residue += -_velocity * delta
	var whole := int(_residue)
	if whole != 0:
		_scroll.scroll_vertical += whole
		_residue -= float(whole)
	# Amortissement rapporté au soixantième de seconde, pour que la course dure
	# le même temps quelle que soit la cadence d'images.
	_velocity *= pow(FRICTION, delta * 60.0)
	# Butée atteinte : inutile d'entretenir une vitesse qui ne déplace plus rien.
	var bar := _scroll.get_v_scroll_bar()
	if _scroll.scroll_vertical <= 0 \
			or float(_scroll.scroll_vertical) >= bar.max_value - bar.page:
		_velocity = 0.0
