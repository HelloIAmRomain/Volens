class_name AgentState
extends RefCounted
## État d'un agent de la nuée [DCT §4.1]. Anonyme, sans caractéristiques
## propres (RG-04) : uniquement position, direction et drapeaux.

## Champ de bits [DCT §4.1].
const PRESENT: int = 1 << 0  # encore en jeu (ni sorti, ni perdu)
const PORTEUR: int = 1 << 1  # porte une ressource (R11)
## ÉQUIPÉ D'UN BOUCLIER — absorbe UN contact mortel, puis se brise.
##
## POURQUOI CE DRAPEAU ET PAS UNE RÈGLE. Un bouclier n'est pas un comportement :
## c'est un OBJET qu'on ramasse et qu'on porte. Le mettre dans la pile de règles
## aurait coûté un rang sur trois pour quelque chose qui ne décide de rien —
## et le joueur aurait cherché quand le « jouer », alors qu'il n'y a rien à
## jouer : il protège, un point c'est tout.
##
## IL NE DÉTRUIT RIEN. C'est ce qui le distingue de R13 « Boucher », qui est un
## SACRIFICE : l'agent s'y consume et emporte le danger avec lui. « Dans
## l'imaginaire collectif, un bouclier est un objet de défense, pas d'attaque »
## — il encaisse et se brise, le danger reste.
const PROTEGE: int = 1 << 2
const SORTI: int = 1 << 2    # a atteint une sortie (RG-14)
const PERDU: int = 1 << 3    # a été perdu sur un danger (RG-14)

## Identifiant stable : correspond à l'index de l'agent dans SimState.agents
## et à sa position dans le fichier de niveau [DT-07]. N'est jamais réattribué.
var id: int = 0
var pos: Vector2i = Vector2i.ZERO
var dir: int = Directions.NORTH  # dernière direction de déplacement effective
var flags: int = PRESENT

func is_present() -> bool:
	return (flags & PRESENT) != 0

func clone() -> AgentState:
	var copy := AgentState.new()
	copy.id = id
	copy.pos = pos
	copy.dir = dir
	copy.flags = flags
	return copy
