class_name Haptics
extends RefCounted
## Retour haptique [ENF-24]. Quatre événements, pas un de plus.
##
## POURQUOI IL EXISTE. La discrimination appui bref / appui long / glissement
## se joue au doigt, sur une cible que le doigt lui-même cache. Sans retour,
## le joueur doit REGARDER pour savoir ce qui a été compris — et regarder la
## pile, c'est quitter la grille des yeux au moment précis où la nuée bouge.
## Une impulsion dit « compris » sans coûter un regard.
##
## DEUX RÈGLES QUI NE SE NÉGOCIENT PAS.
## 1. **Jamais porteur d'information exclusive** (ENF-22). Tout ce qu'une
##    vibration annonce est aussi visible à l'écran : sélection, dépôt, refus
##    et sortie ont tous leur retour visuel. Un appareil sans vibreur, ou un
##    joueur qui l'a coupé, ne perd aucune information.
## 2. **Désactivable**, et l'état est persistant (`Settings`).
##
## Les durées sont en millisecondes ⚙️, choisies pour être distinguables au
## doigt sans être ressenties comme un défaut : le refus est le seul motif
## double, parce qu'un refus doit se remarquer.

## Une pichenette : la règle est prise en main.
const SELECT_MS := 12
## Plus franc : quelque chose s'est posé, la pile a changé.
const DROP_MS := 22
## Deux temps courts : le geste n'a rien produit. Le seul motif qui se
## distingue à l'oreille du doigt, parce que c'est le seul qu'il faut relire.
const REFUSE_MS := 14
const REFUSE_GAP_MS := 70
## Très bref : un agent est sorti. Il peut y en avoir plusieurs par tick, on
## ne vibre qu'une fois — sinon une extraction de vingt agents devient une
## sonnerie.
const EXIT_MS := 9

static var enabled: bool = true

static func _pulse(duration_ms: int) -> void:
	if not enabled:
		return
	# `vibrate_handheld` est sans effet hors appareil mobile : aucune garde de
	# plateforme n'est nécessaire, et aucune permission non plus — Godot
	# n'ajoute VIBRATE au manifeste que si l'export l'active, ce que nous ne
	# faisons pas (le jeu reste sans permission, ENF-31).
	Input.vibrate_handheld(duration_ms)

static func select() -> void:
	_pulse(SELECT_MS)

static func drop() -> void:
	_pulse(DROP_MS)

static func exited() -> void:
	_pulse(EXIT_MS)

## Refus : deux impulsions courtes. La seconde est différée par un minuteur
## porté par le nœud appelant — une classe statique n'a pas d'arbre.
static func refuse(host: Node) -> void:
	if not enabled or host == null or not host.is_inside_tree():
		return
	_pulse(REFUSE_MS)
	var timer := host.get_tree().create_timer(REFUSE_GAP_MS / 1000.0)
	timer.timeout.connect(func() -> void: _pulse(REFUSE_MS))
