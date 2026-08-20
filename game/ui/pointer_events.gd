class_name PointerEvents
extends RefCounted
## UN CONTACT, UN ÉVÈNEMENT — parce qu'Android en envoie deux.
##
## LE PIÈGE, ET IL A FRAPPÉ TROIS FOIS. Pour un seul geste physique, Android
## émet l'évènement tactile **et** son équivalent souris ÉMULÉ, à la même
## position et dans la même image. Tout code qui traite les deux agit donc en
## double, et le symptôme n'a rien à voir avec la cause selon l'endroit :
##
##   · **la légende** — la carte suivante était créée deux fois, l'une se
##     refermait aussitôt sur le même geste et ouvrait le panneau d'objectif
##     pendant que l'autre restait affichée ;
##   · **le défilement** — le doublon portait un déplacement NUL, donc écrasait
##     la vitesse par zéro : la liste s'arrêtait net au lever du doigt, « mais
##     seulement à certains moments », selon l'ordre d'arrivée ;
##   · **la mise en pause** — un contact dans le vide appelait `_toggle_play()`
##     deux fois, ce qui revient exactement à ne rien faire.
##
## Trois corrections locales auraient laissé passer la quatrième. Le verrou est
## donc ici, et tout code qui lit des évènements de pointage doit y passer.
##
## POURQUOI UN VERROU DÉFINITIF ET NON UN FILTRE PAR ÉVÈNEMENT. On ne peut pas
## reconnaître un évènement souris émulé à son contenu : il est en tout point
## semblable à un vrai. Ce qu'on sait, en revanche, c'est qu'un appareil qui a
## produit un évènement tactile n'a pas de souris. Une fois le doigt vu, la
## souris n'est plus qu'un écho.
##
## LE POSTE DE TRAVAIL N'EST PAS TOUCHÉ : il n'émet jamais d'évènement tactile,
## le verrou ne se ferme donc jamais, et les captures comme les tests d'interface
## continuent de fonctionner à la souris. C'est ce qui permet d'éprouver ces
## écrans ailleurs que sur le téléphone.

static var _touch_seen: bool = false

## Vrai si cet évènement est un doublon émulé qu'il faut ignorer.
static func is_emulated_duplicate(event: InputEvent) -> bool:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_touch_seen = true
		return false
	if not _touch_seen:
		return false
	return event is InputEventMouseButton or event is InputEventMouseMotion

## Uniquement pour les tests : le verrou est un état de processus, et un test qui
## le laisserait fermé ferait échouer le suivant sans rapport avec son objet.
static func reset_for_test() -> void:
	_touch_seen = false
