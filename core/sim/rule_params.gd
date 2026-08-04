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

## Construit des paramètres à partir d'un Dictionary déjà chargé (JSON parsé
## en amont, hors de core/sim/). Accès par clé nommée uniquement — jamais
## d'itération sur le Dictionary (invariant n°8, docs/ARCHITECTURE.md).
static func from_dict(d: Dictionary) -> RuleParams:
	var params := RuleParams.new()
	var flee: Dictionary = d.get("fuir_le_rouge", {})
	var group: Dictionary = d.get("rester_groupe", {})
	params.flee_perception_range_sq = int(flee.get("perception_range_sq", params.flee_perception_range_sq))
	params.group_perception_range_sq = int(group.get("perception_range_sq", params.group_perception_range_sq))
	return params
