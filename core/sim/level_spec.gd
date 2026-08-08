class_name LevelSpec
extends RefCounted
## SOURCE DE VÉRITÉ UNIQUE des contraintes qu'un niveau impose à la pile.
##
## POURQUOI CE FICHIER EXISTE, et pourquoi il est dans `core/`.
##
## `slots` était lu à deux endroits : le validateur, pour énumérer l'espace
## des piles, et l'écran de jeu, pour ouvrir des rangs. Deux lectures, donc
## deux vérités possibles — et c'est arrivé : l'écran offrait quatre rangs sur
## un niveau qui en déclare deux.
##
## LA BRÈCHE N'EST PAS COSMÉTIQUE. Si le joueur atteint une pile que le
## validateur n'a jamais énumérée, alors `expected_wins` ne décrit plus ce que
## le joueur peut faire : **N_win cesse d'être une propriété du niveau** pour
## devenir une propriété d'un sous-ensemble arbitraire. `expected_wins = 1`
## sur ch1_02 signifie « une seule pile gagne, et c'est la leçon » — la
## phrase devient fausse dès qu'une pile non comptée existe. Ce n'est pas un
## défaut d'affichage : c'est la leçon du niveau qui s'effondre.
##
## D'où l'unique lecture. Le validateur vit dans `tools/`, le jeu dans
## `game/`, et ces deux-là n'ont qu'un ancêtre commun autorisé : `core/`
## (règles de dépendance 3 et 4, docs/ARCHITECTURE.md). C'est donc ici, et nulle part
## ailleurs, que `slots` se lit.
##
## `core/sim/` porte déjà le schéma des données de niveau — `SimCore.load_level`
## en consomme le même dictionnaire. Le fichier n'importe rien, ne lit aucun
## fichier, ne contient ni flottant ni horloge : les invariants de pureté
## tiennent.

## Plafond absolu de la pile [RG-05]. Aucun niveau ne peut en offrir plus.
const MAX_SLOTS := 4

## Nombre de rangs qu'un niveau OUVRE réellement.
##
## Sans clé `slots`, on retombe sur le plafond — c'est le comportement
## historique, et il reste juste : un niveau qui ne déclare rien offre la pile
## entière, et le validateur énumère la pile entière.
static func open_slots(level_data: Dictionary) -> int:
	return clampi(int(level_data.get("slots", MAX_SLOTS)), 1, MAX_SLOTS)
