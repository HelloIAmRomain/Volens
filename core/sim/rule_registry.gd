class_name RuleRegistry
extends RefCounted
## Registre des règles disponibles, indexées par l'identifiant entier stable
## utilisé dans la pile (Array[int], DT-10). 0 = emplacement vide.
##
## Seules R01-R03 (chapitre 1) sont enregistrées dans ce lot ; R04-R16
## viendront chapitre par chapitre sans changer cette interface.

const EMPTY: int = 0
const R01_TOWARD_LIGHT: int = 1
const R02_FLEE_DANGER: int = 2
const R03_STAY_GROUPED: int = 3

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
	if rule != null:
		_instances[rule_id] = rule
	return rule
