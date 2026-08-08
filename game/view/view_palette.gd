class_name ViewPalette
extends RefCounted
## CHARTE DES COULEURS [DA-02, ENF-20/22, carnet décision 74].
##
## Le problème qu'elle résout : sans teintes réservées, la couleur ne veut
## rien dire. Au chapitre 1 on s'en sort à l'œil ; au chapitre 4, avec
## ressources, dépôts, portes à pression et sens uniques à l'écran en même
## temps, une teinte qui sert à deux choses rend le plateau illisible.
##
## TROIS FAMILLES, ÉTANCHES ENTRE ELLES.
##
## 1. ÉLÉMENTS DE NIVEAU — une teinte réservée par entrée du vocabulaire
##    RG-14. Les neuf sont attribuées d'avance, y compris celles qu'aucun
##    niveau n'utilise encore : c'est le seul moment où l'attribution est
##    gratuite. Aucune autre famille n'a le droit d'emprunter ces teintes.
##
## 2. EMPLACEMENTS DE PILE — **aucune teinte propre**. Un emplacement est
##    identifié par sa POSITION et son NUMÉRO, pas par sa couleur. C'est
##    d'ailleurs plus juste : la pile est un ordre, et un ordre se lit par
##    des rangs, pas par un arc-en-ciel. La famille est un gris-ardoise
##    désaturé qui ne peut être confondu avec aucun élément.
##
## 3. DIAGNOSTIC — palette MODALE. Elle ne coexiste jamais avec la lecture
##    normale : quand le diagnostic s'allume, le terrain se désature
##    (`diagnostic_mode`), ce qui libère les teintes vives. Une nuée
##    multicolore détruirait la lecture de la forme collective, et DA-01 fait
##    de cette forme le personnage principal — le diagnostic est donc une
##    surcouche que l'on allume, jamais l'état par défaut.
##
## HIÉRARCHIE DE DOMINANCE (DA-02) : but > danger > nuée > décor. Elle ne
## tient pas à la saturation mais à la LUMINOSITÉ PAR UNITÉ DE SURFACE. La
## lumière domine sur une petite surface ; la sortie, large, doit donc rester
## sous elle — un seuil, pas un phare.

const BACKGROUND := Color(0.027, 0.031, 0.047)

## Maillage : présent mais presque muet. Le monde est discret, c'est une
## information de jeu — mais tracer 250 frontières ramène l'œil au niveau de
## la case et défait le travail de fusion en régions.
const GRID_LINE := Color(0.10, 0.11, 0.14, 0.30)
## Ni pourtour ni dalle : ensemble ils dessinaient une boîte, et le jeu se
## lisait comme une fenêtre encastrée dans l'interface. Le maillage s'arrête
## au bord du monde — c'est suffisant, et ça ne fabrique pas de cadre.

# --- famille 1 : éléments de niveau (teintes réservées) ----------------------
#
# Les teintes sont réparties sur la roue pour rester distinguables deux à deux,
# y compris côte à côte : ambre 45°, vert-sarcelle 150°, cyan 195°, bleu 215°,
# violet 280°, magenta 320°, rouge 358°. Le mur n'a pas de teinte — c'est du
# décor, et lui en donner une le ferait entrer dans le vocabulaire signifiant.

const WALL := Color(0.13, 0.14, 0.19)                    # décor, sans teinte
const EXIT := Color(0.20, 0.78, 0.56)                    # 150° — le seuil
const DANGER := Color(0.74, 0.22, 0.24)                  # 358° — registre calme
const DANGER_DORMANT := Color(0.34, 0.17, 0.20)          # même élément, autre phase
const RESOURCE := Color(0.72, 0.48, 0.95)                # 280°
const DROPOFF := Color(0.38, 0.56, 0.95)                 # 215°
const PRESSURE_DOOR := Color(0.95, 0.45, 0.78)           # 320° — réservé, inutilisé
const ONE_WAY := Color(0.30, 0.82, 0.90)                 # 195° — réservé, inutilisé
const LIGHT := Color(1.0, 0.92, 0.68)                    # 45° — la plus lumineuse

## Teinte réservée d'un élément du vocabulaire. Sert de point d'entrée unique :
## toute nouvelle couleur d'élément passe par ici, jamais en dur ailleurs.
static func element_color(cell_type: int, danger_active: bool = true) -> Color:
	match cell_type:
		GridState.CellType.WALL:
			return WALL
		GridState.CellType.EXIT:
			return EXIT
		GridState.CellType.STATIC_DANGER:
			return DANGER
		GridState.CellType.CYCLIC_DANGER:
			return DANGER if danger_active else DANGER_DORMANT
		GridState.CellType.RESOURCE:
			return RESOURCE
		GridState.CellType.DROPOFF:
			return DROPOFF
		GridState.CellType.PRESSURE_DOOR:
			return PRESSURE_DOOR
		GridState.CellType.ONE_WAY:
			return ONE_WAY
		GridState.CellType.LIGHT_SOURCE:
			return LIGHT
	return BACKGROUND

# --- famille 2 : emplacements de pile (aucune teinte) ------------------------

## Gris-ardoise. Le rang se lit au numéro et à la position ; l'emplacement
## occupé emprunte la LUMINOSITÉ, jamais une teinte propre.
const SLOT_IDLE := Color(0.42, 0.46, 0.56)
const SLOT_FILLED := Color(0.72, 0.78, 0.90)
## Emplacement verrouillé : le niveau déclare moins de rangs que la pile n'en
## comptera (RG-05). Il est montré — le joueur doit savoir que la pile
## grandira — mais il est visiblement d'une autre nature, pas un rang grisé.
const SLOT_LOCKED := Color(0.26, 0.28, 0.34)

# --- famille 3 : diagnostic (modale) -----------------------------------------

## Couleur d'un agent selon l'EMPLACEMENT qui a décidé pour lui à ce tick.
## MODALE : n'apparaît que `show_decision_colors` allumé, et le terrain est
## alors désaturé pour qu'aucune confusion avec un élément ne soit possible.
const SLOT_COLORS := [
	Color(0.35, 0.85, 1.00),  # rang 1
	Color(1.00, 0.72, 0.25),  # rang 2
	Color(1.00, 0.40, 0.80),  # rang 3
	Color(0.55, 1.00, 0.45),  # rang 4
]
## Aucune règle applicable : l'agent est immobile par défaut (RG-05).
const SLOT_NONE := Color(0.45, 0.47, 0.55)

## Nuée en couleur unie — l'état NORMAL du jeu. DA-01 : la nuée est le
## personnage, et un personnage n'a pas quatre couleurs.
const AGENT_PLAIN := Color(0.82, 0.93, 1.00)

static func slot_color(slot: int) -> Color:
	if slot < 0 or slot >= SLOT_COLORS.size():
		return SLOT_NONE
	return SLOT_COLORS[slot]
