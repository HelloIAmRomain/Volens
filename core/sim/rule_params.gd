class_name RuleParams
extends RefCounted
## Paramètres d'équilibrage des règles [DT-10] : jamais codés en dur, chargés
## depuis `data/rules.json` par l'appelant (tools/, game/) et transmis ici
## comme un objet déjà analysé. `core/sim/` ne lit aucun fichier lui-même.
##
## Portées de perception exprimées en carré de distance euclidienne
## (dx*dx + dy*dy) pour éviter tout sqrt (DT-04).

var flee_perception_range_sq: int = 25   # R02 — fuir le rouge
var group_perception_range_sq: int = 16  # R03 — rester groupé

## R03 v2 — prédicat de maintien. « Rester groupé » est une CONDITION
## satisfaite ou non, pas une convergence sans fin : l'agent qui compte au
## moins `group_min_neighbours` congénères dans un rayon rapproché
## `group_close_range_sq` se considère groupé et laisse la main.
## Valeurs mesurées, jamais devinées — voir carnet de bord.
## Valeurs MESURÉES le 6 août 2026 (voir carnet) : ce sont les seules qui
## donnent à la fois quatre archétypes distincts (EQ-05), aucun gel, et un
## tremblement négligeable (8 demi-tours pour 20 agents sur 20 ticks).
## Sémantique en une phrase : « je suis groupé si j'ai au moins un congénère
## à portée de main » — adjacence orthogonale ou diagonale.
##
## LE RAYON 2 EST IMPOSÉ PAR LA PARITÉ, pas trouvé par tâtonnement. Un pas
## cardinal inverse la parité de (x + y), et un agent qui bouge à chaque tick
## la conserve : deux agents de même parité ne peuvent donc JAMAIS être
## orthogonalement adjacents (d² = 1), seulement diagonaux (d² = 2). Une
## valeur de 1 serait structurellement insatisfiable pour une moitié de la
## nuée. Ne pas « ajuster » ce 2 vers le bas sans refaire ce raisonnement.
var group_close_range_sq: int = 2        # rayon rapproché ⚙️ : adjacence
var group_min_neighbours: int = 1        # n_min ⚙️ : un seul voisin suffit

## Construit des paramètres à partir d'un Dictionary déjà chargé (JSON parsé
## en amont, hors de core/sim/). Accès par clé nommée uniquement — jamais
## d'itération sur le Dictionary (invariant n°8, docs/ARCHITECTURE.md).
static func from_dict(d: Dictionary) -> RuleParams:
	var params := RuleParams.new()
	var flee: Dictionary = d.get("fuir_le_rouge", {})
	var group: Dictionary = d.get("rester_groupe", {})
	params.flee_perception_range_sq = int(flee.get("perception_range_sq", params.flee_perception_range_sq))
	params.group_perception_range_sq = int(group.get("perception_range_sq", params.group_perception_range_sq))
	params.group_close_range_sq = int(group.get("close_range_sq", params.group_close_range_sq))
	params.group_min_neighbours = int(group.get("min_neighbours", params.group_min_neighbours))
	return params
