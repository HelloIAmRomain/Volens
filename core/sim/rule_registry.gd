class_name RuleRegistry
extends RefCounted
## Registre des règles disponibles, indexées par l'identifiant entier stable
## utilisé dans la pile (Array[int], DT-10). 0 = emplacement vide.
##
## Les seize règles du CDC §7.2 sont enregistrées. L'interface n'a pas changé
## d'un caractère depuis le chapitre 1 : `Rule.evaluate` pour un déplacement,
## `Rule.apply_effect` pour un effet, et la cascade lit `Rule.kind()`.

const EMPTY: int = 0

# Chapitre 1 — le mouvement élémentaire
const R01_TOWARD_LIGHT: int = 1
const R02_FLEE_DANGER: int = 2
const R03_STAY_GROUPED: int = 3
# Chapitre 2 — la coordination
const R04_SPREAD_OUT: int = 4
const R05_FOLLOW_NEIGHBOURS: int = 5
const R06_HUG_WALL: int = 6
# Chapitre 3 — la mémoire du monde
## R07 « Attendre » et R10 « Rebrousser si seul » ONT ÉTÉ RETIRÉES du jeu le
## 15 août 2026. Leurs identifiants restent réservés — ils figurent dans des
## fiches de conception et dans le carnet, et les réattribuer rendrait ces
## traces mensongères.
##
## MESURE QUI A TRANCHÉ (`tools/design/rule_usefulness.gd`) : une règle est
## utile si elle PORTE, c'est-à-dire si la retirer d'une pile gagnante fait
## perdre cette pile. Figurer dans une gagnante ne prouve rien — on peut
## toujours rallonger une solution avec n'importe quelle règle inerte.
##
##   · R07 était offerte dans QUATORZE niveaux et ne portait dans AUCUN ;
##   · R10 n'était offerte nulle part, et son remède demandait l'hystérésis,
##     gelée faute de joueurs.
##
## Les quatorze autres portent toutes quelque part.
const _R07_WAIT_RETIRED: int = 7
const R08_MARK_TRAIL: int = 8
const R09_FOLLOW_TRAIL: int = 9
# Chapitre 4 — le transport
const _R10_TURN_BACK_IF_ALONE_RETIRED: int = 10
const R11_CARRY: int = 11
const R12_DROP_AT_GOAL: int = 12
# Chapitre 5 — le sacrifice et la régulation
const R13_PLUG: int = 13
const R14_SCATTER_IF_DENSE: int = 14
const R15_FOLLOW_THE_SLOWEST: int = 15
# Chapitre 6 — l'exception
const R16_IGNORE: int = 16

## LE JOKER R16 PORTE UN ARGUMENT — le type de case qu'il neutralise, « choisi
## au placement de la règle » (CDC §7.2). Une pile reste pourtant un
## `Array[int]` : c'est le type que lisent l'énumérateur, la sauvegarde,
## l'empreinte des recettes d'or et l'interface. Le changer pour un tableau de
## structures aurait touché ces cinq endroits, pour un seul cas particulier.
##
## L'argument est donc encodé dans les bits hauts de l'identifiant :
##
##     identifiant = R16_IGNORE | (type_de_case << 8)
##
## `base_rule_id` retire l'argument, `ignored_cell_of` le lit. Tout le reste du
## moteur continue de manipuler des entiers sans rien savoir de ce codage —
## c'est la propriété qui le rend acceptable.
const JOKER_SHIFT: int = 8
const RULE_MASK: int = 0xFF

static func base_rule_id(rule_id: int) -> int:
	return rule_id & RULE_MASK

## Type de case neutralisé par cet identifiant, ou -1 si ce n'est pas un joker.
static func ignored_cell_of(rule_id: int) -> int:
	if base_rule_id(rule_id) != R16_IGNORE:
		return -1
	return rule_id >> JOKER_SHIFT

static func make_joker(cell_type: int) -> int:
	return R16_IGNORE | (cell_type << JOKER_SHIFT)

## Instances mises en cache par id (les règles sont sans état) — évite de
## réallouer un objet Rule à chaque agent, à chaque tick. Accès par clé
## nommée uniquement (Dictionary.has/[]), jamais d'itération.
static var _instances: Dictionary = {}

static func get_rule(rule_id: int) -> Rule:
	var base := base_rule_id(rule_id)
	if _instances.has(base):
		return _instances[base]
	var rule: Rule = null
	match base:
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
		R08_MARK_TRAIL:
			rule = RuleMarkTrail.new()
		R09_FOLLOW_TRAIL:
			rule = RuleFollowTrail.new()
		R11_CARRY:
			rule = RuleCarry.new()
		R12_DROP_AT_GOAL:
			rule = RuleDropAtGoal.new()
		R13_PLUG:
			rule = RulePlug.new()
		R14_SCATTER_IF_DENSE:
			rule = RuleScatterIfDense.new()
		R15_FOLLOW_THE_SLOWEST:
			rule = RuleFollowTheSlowest.new()
		R16_IGNORE:
			rule = RuleIgnore.new()
	if rule != null:
		_instances[base] = rule
	return rule

## Nombre de règles réellement enregistrées — sert aux tests et au catalogue.
const ALL: Array[int] = [
	R01_TOWARD_LIGHT, R02_FLEE_DANGER, R03_STAY_GROUPED,
	R04_SPREAD_OUT, R05_FOLLOW_NEIGHBOURS, R06_HUG_WALL,
	R08_MARK_TRAIL, R09_FOLLOW_TRAIL,
	R11_CARRY, R12_DROP_AT_GOAL,
	R13_PLUG, R14_SCATTER_IF_DENSE, R15_FOLLOW_THE_SLOWEST,
	R16_IGNORE,
]
