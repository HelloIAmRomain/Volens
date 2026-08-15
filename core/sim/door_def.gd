class_name DoorDef
extends RefCounted
## Porte à pression [RG-14] : « s'ouvre tant qu'un nombre requis d'agents ⚙️
## occupe ses cases de commande ».
##
## IMMUABLE APRÈS CHARGEMENT. L'état ouvert/fermé n'est pas ici : il est
## recalculé à chaque tick dans `GridState.doors_open`, à partir des positions
## des agents. Une porte ne mémorise rien — elle est une lecture du présent, et
## c'est ce qui la rend prévisible pour le joueur.
##
## LES CASES DE COMMANDE NE SONT PAS UN DIXIÈME TYPE DE CASE. Le vocabulaire de
## RG-14 est **fermé à neuf éléments** pour la v1.0, et l'élargir pour un détail
## d'implémentation serait exactement l'inflation que cette clôture interdit.
## Une case de commande est donc une case ordinaire que `GridState.door_index`
## rattache à une porte ; on la distingue de la porte elle-même par son type.
##
## POURQUOI CE MÉCANISME EST INTÉRESSANT ICI, et pas seulement décoratif : il
## est le premier du jeu à demander qu'une PARTIE de la nuée renonce à
## progresser pour que le reste passe. Aucune règle ne sait « rester en
## arrière » ; il faut donc que la géométrie divise la nuée — un goulot, un
## danger, une piste — et que la pile choisie produise cette division. C'est le
## dilemme de RG-16 rendu spatial.

## Indices de cases (y * size.x + x) sur lesquelles un agent compte.
var plates: PackedInt32Array = PackedInt32Array()
## Indices des cases PRESSURE_DOOR que ces commandes ouvrent.
var panels: PackedInt32Array = PackedInt32Array()
## Nombre d'agents requis simultanément ⚙️.
var required: int = 1

static func from_dict(d: Dictionary, grid_size: Vector2i) -> DoorDef:
	var door := DoorDef.new()
	door.required = maxi(1, int(d.get("required", 1)))
	for pair in d.get("plates", []):
		door.plates.append(int(pair[1]) * grid_size.x + int(pair[0]))
	for pair in d.get("panels", []):
		door.panels.append(int(pair[1]) * grid_size.x + int(pair[0]))
	return door
