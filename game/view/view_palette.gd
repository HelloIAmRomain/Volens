class_name ViewPalette
extends RefCounted
## Palette du rendu [DA-02] : fond très sombre, agents lumineux, hiérarchie
## visuelle stricte but > danger > nuée > décor. Aucune texture : toutes les
## couleurs sont procédurales (DT-13, ENF-11).
##
## Le danger est porté par la couleur ET des hachures, jamais par la seule
## couleur (ENF-20/22, DCT §6.3) : aucune information mono-canal.

const BACKGROUND := Color(0.027, 0.031, 0.047)
const GRID_LINE := Color(0.10, 0.11, 0.14)
const WALL := Color(0.13, 0.14, 0.19)

## Registre calme : un obstacle, pas une alarme (DS-03 étendu au visuel).
## Rouge profond et désaturé plutôt que vif — il doit se lire sans crier, et
## rester sous les buts dans la hiérarchie DA-02.
const DANGER := Color(0.74, 0.22, 0.24)
const DANGER_DORMANT := Color(0.34, 0.17, 0.20)  # cyclique en phase calme  # cyclique en phase calme
const EXIT := Color(0.16, 0.92, 0.62)
const LIGHT := Color(1.0, 0.90, 0.62)
const RESOURCE := Color(0.75, 0.55, 0.95)
const DROPOFF := Color(0.45, 0.60, 0.95)

## Couleur d'un agent selon l'EMPLACEMENT de pile qui a décidé pour lui à ce
## tick. C'est l'instrument qui répond de visu à la question des zones
## d'action : si deux règles ne décident jamais au même moment, leurs deux
## couleurs ne se mélangent jamais à l'écran.
const SLOT_COLORS := [
	Color(0.35, 0.85, 1.00),  # emplacement 1 — cyan
	Color(1.00, 0.72, 0.25),  # emplacement 2 — ambre
	Color(1.00, 0.40, 0.80),  # emplacement 3 — magenta
	Color(0.55, 1.00, 0.45),  # emplacement 4 — vert
]
## Aucune règle applicable : l'agent est immobile par défaut (RG-05).
const SLOT_NONE := Color(0.45, 0.47, 0.55)

## Nuée en couleur unie, quand le diagnostic par règle est désactivé.
const AGENT_PLAIN := Color(0.82, 0.93, 1.00)

static func slot_color(slot: int) -> Color:
	if slot < 0 or slot >= SLOT_COLORS.size():
		return SLOT_NONE
	return SLOT_COLORS[slot]

static func cell_color(cell_type: int, danger_active: bool) -> Color:
	match cell_type:
		GridState.CellType.WALL:
			return WALL
		GridState.CellType.EXIT:
			return EXIT
		GridState.CellType.LIGHT_SOURCE:
			return LIGHT
		GridState.CellType.STATIC_DANGER:
			return DANGER
		GridState.CellType.CYCLIC_DANGER:
			return DANGER if danger_active else DANGER_DORMANT
		GridState.CellType.RESOURCE:
			return RESOURCE
		GridState.CellType.DROPOFF:
			return DROPOFF
	return BACKGROUND
