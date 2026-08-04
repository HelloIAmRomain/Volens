class_name AgentState
extends RefCounted
## État d'un agent de la nuée [DCT §4.1]. Anonyme, sans caractéristiques
## propres (RG-04) : uniquement position, direction et drapeaux.

## Champ de bits [DCT §4.1].
const PRESENT: int = 1 << 0  # encore en jeu (ni sorti, ni perdu)
const PORTEUR: int = 1 << 1  # porte une ressource (R11)
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
