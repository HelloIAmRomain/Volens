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

## EMPREINTE DE GÉOMÉTRIE [invariant n°15]. Résume tout ce dont dépendent les
## temps de parcours : dimensions, contenu de la grille, positions initiales.
##
## POURQUOI ELLE EXISTE. Les paramètres calibrés d'un niveau — échéance de
## célérité, seuil de préservation, pourcentage d'extraction, limite de ticks —
## sont MESURÉS sur une géométrie donnée. Un mur déplacé d'une case change des
## temps de parcours, donc des marges, donc des verdicts : le niveau cesse de
## valider ce qu'il prétend valider, sans que rien dans son en-tête n'ait
## bougé. C'est arrivé — l'échéance de ch1_04, calibrée à 19 sur une bande
## pleine largeur, ne laissait plus qu'un tick de marge après le passage à
## l'entonnoir.
##
## Le `.lvl` archive donc l'empreinte sous laquelle il a été calibré, et le
## convertisseur refuse le niveau si elle ne correspond plus. Même dispositif
## que le `rules_hash` des recettes d'or, et pour la même raison : distinguer
## « le code a régressé » de « l'entrée a changé ».
##
## N'entrent PAS dans l'empreinte : les objectifs, `max_ticks`, `slots`,
## `allowed_rules`. Ce sont les paramètres eux-mêmes — les inclure rendrait
## l'empreinte circulaire, et changer une échéance invaliderait sa propre
## calibration.
static func geometry_hash(level_data: Dictionary) -> String:
	var grid: Dictionary = level_data.get("grid", {})
	var size: Array = grid.get("size", [0, 0])
	var h: int = StateHash.OFFSET_BASIS
	h = StateHash.feed_int(h, int(size[0]) if size.size() > 0 else 0)
	h = StateHash.feed_int(h, int(size[1]) if size.size() > 1 else 0)
	for c in grid.get("cells", []):
		h = StateHash.feed_int(h, int(c))
	for ci in grid.get("cycle_index", []):
		h = StateHash.feed_int(h, int(ci))
	for cycle in grid.get("cycles", []):
		var d: Dictionary = cycle
		h = StateHash.feed_int(h, int(d.get("period", 0)))
		h = StateHash.feed_int(h, int(d.get("active_ticks", 0)))
	var agents: Array = level_data.get("agents", [])
	h = StateHash.feed_int(h, agents.size())
	for a in agents:
		var pos: Array = (a as Dictionary).get("pos", [0, 0])
		h = StateHash.feed_int(h, int(pos[0]))
		h = StateHash.feed_int(h, int(pos[1]))
	return StateHash.to_hex(h)

# --- Champs DÉCLARATIFS d'un niveau ------------------------------------------
#
# Ces valeurs ne pilotent pas la simulation : elles décrivent ce que le niveau
# prétend être. Elles sont donc recopiées partout — fiche de conception, écran
# de bilan, rapports du validateur, assertions de tests — et **c'est
# exactement ce qui les fait diverger**.
#
# LE MOTIF, CONSTATÉ TROIS FOIS. `slots` était lu à deux endroits, et
# l'interface a fini par en offrir quatre là où le validateur en énumérait deux
# (invariant n°11). Une table en dur dans `test_chapter1_arc` recopiait les
# `expected_wins` des trois derniers niveaux, et a dérivé dès la première
# refonte. Une assertion recopiait le `slots` de ch1_02.
#
# **Toute valeur de niveau recopiée hors de son fichier source finit par
# diverger.** La parade est la même que pour `slots` : un accesseur unique, et
# un contrôle lexical qui refuse toute autre lecture de la clé
# (`tests/arch/test_level_field_access.gd`).

## Nombre de piles gagnantes annoncé par la fiche, ou -1 s'il n'est pas déclaré.
## Contrat entre la conception et le moteur : le validateur le confronte à la
## mesure, et l'écran de bilan l'affiche sur les niveaux ouverts (CDC §8.5).
static func expected_wins(level_data: Dictionary) -> int:
	return int(level_data.get("expected_wins", -1))

## Nombre de classes structurelles annoncé, ou -1.
static func expected_classes(level_data: Dictionary) -> int:
	return int(level_data.get("expected_classes", -1))

## Un niveau tutoriel est exempté de QN-01 et porte à la place un contrat
## exact : `N_win` doit valoir `expected_wins`, ni plus ni moins (CDC §12.2.1).
static func is_tutorial(level_data: Dictionary) -> bool:
	return bool(level_data.get("tutorial", false))

## Empreinte de la géométrie sous laquelle les paramètres ont été mesurés
## (invariant n°15), ou "" si le niveau n'en déclare pas.
## DÉFIS RG-18. Bloc déclaratif, donc lu ici et nulle part ailleurs
## (invariant n°16). `efficiency_ticks` est un paramètre de la CARTE — mesuré
## sur une géométrie donnée, faux dès qu'un mur bouge — et se trouve donc sous
## la protection de `calibrated_on`, exactement comme l'échéance de célérité.
static func challenges(level_data: Dictionary) -> Dictionary:
	var raw: Variant = level_data.get("challenges", {})
	return raw if raw is Dictionary else {}

static func calibrated_on(level_data: Dictionary) -> String:
	return String(level_data.get("calibrated_on", ""))
