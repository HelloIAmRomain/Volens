class_name RuleRegistry
extends RefCounted
## Registre des règles disponibles, indexées par l'identifiant entier stable
## utilisé dans la pile (Array[int], DT-10). 0 = emplacement vide.
##
## R01-R03 (chapitre 1) et R04-R06 (chapitre 2, la coordination) sont
## enregistrées ; R07-R16 viendront chapitre par chapitre sans changer cette
## interface — c'est ce que ce lot vérifie au passage : ajouter trois règles
## n'a demandé aucune modification de `Rule`, de la cascade, ni de l'état.

const EMPTY: int = 0
const R01_TOWARD_LIGHT: int = 1
const R02_FLEE_DANGER: int = 2
const R03_STAY_GROUPED: int = 3
const R04_SPREAD_OUT: int = 4
const R05_FOLLOW_NEIGHBOURS: int = 5
const R06_HUG_WALL: int = 6

## Instances mises en cache par id (les règles sont sans état) — évite de
## réallouer un objet Rule à chaque agent, à chaque tick. Accès par clé
## nommée uniquement (Dictionary.has/[]), jamais d'itération.
static var _instances: Dictionary = {}

static func get_rule(rule_id: int) -> Rule:
	if _instances.has(rule_id):
		return _instances[rule_id]
	var rule: Rule = null
	match rule_id:
		R01_TOWARD_LIGHT:
			rule = RuleTowardLight.new()
		R02_FLEE_DANGER:
			rule = RuleFleeDanger.new()
		R03_STAY_GROUPED:
			rule = RuleStayGrouped.new()
		R04_SPREAD_OUT:
			rule = RuleSpreadOut.new()
		R05_FOLLOW_NEIGHBOURS:
			rule = RuleFollowNeighbours.new()
		R06_HUG_WALL:
			rule = RuleHugWall.new()
	if rule != null:
		_instances[rule_id] = rule
	return rule
