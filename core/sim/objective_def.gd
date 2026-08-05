class_name ObjectiveDef
extends RefCounted
## Définition d'un objectif de niveau [CDC RG-15]. Configuration immuable
## chargée du fichier de niveau, jamais mutée pendant la simulation —
## partagée par référence dans SimState (comme RuleParams) et exclue de
## l'empreinte : ses effets s'observent dans counters et outcome.
##
## Deux familles :
## — accomplissements (EXTRACTION, COLLECT) : le niveau est gagné quand tous
##   sont satisfaits simultanément (RG-16 : objectif composé = arbitrage) ;
## — contraintes (PRESERVATION, INTERDICTION : ÉVÉNEMENTS — la perte a eu
##   lieu, violation irrémédiable, défaite immédiate qui prime sur tout ;
##   CELERITY : ÉCHÉANCE — rien ne s'est produit, voir ci-dessous).
##
## CELERITY (« réussir en AU PLUS T ticks », tick <= T — revue S3, 2.2)
## borne le temps plus court que la limite du niveau. C'est une échéance,
## pas un événement : elle est évaluée APRÈS la victoire — gagner au tick
## exact de la borne est un « sur le fil » GAGNÉ (ENF-04). Seule, elle ne
## définit aucune victoire — un niveau sans accomplissement n'est jamais
## gagné (défaut de conception que le validateur signale et que l'éditeur
## T-074 devra refuser d'enregistrer).
##
## COLLECT est analysé et évalué, mais restera inatteignable tant que R11
## (Porter) et R12 (Déposer) n'existent pas : `delivered` ne progresse pas.
## Prévu pour le chapitre 4.

enum Type { EXTRACTION, COLLECT, PRESERVATION, CELERITY, INTERDICTION }

var type: int = Type.EXTRACTION
var percent: int = 0        # EXTRACTION : % minimal de la nuée sortie
var count: int = 0          # COLLECT : ressources à livrer
var max_lost: int = 0       # PRESERVATION : pertes maximales tolérées
var max_ticks: int = 0      # CELERITY : borne de ticks propre à l'objectif
## INTERDICTION : indices de cases interdites (pré-calculés au chargement
## à partir des couples [x, y] du fichier de niveau).
var cells: PackedInt32Array = PackedInt32Array()

func is_achievement() -> bool:
	return type == Type.EXTRACTION or type == Type.COLLECT

## Analyse une entrée du tableau "objectives" du fichier de niveau. Le type
## y est une chaîne pour la lisibilité des fichiers ; inconnu -> null (le
## chargeur l'ignore et l'outillage le signalera).
static func from_dict(d: Dictionary, grid: GridState) -> ObjectiveDef:
	var obj := ObjectiveDef.new()
	match String(d.get("type", "")):
		"extraction":
			obj.type = Type.EXTRACTION
			obj.percent = int(d.get("percent", 100))
		"collect":
			obj.type = Type.COLLECT
			obj.count = int(d.get("count", 1))
		"preservation":
			obj.type = Type.PRESERVATION
			obj.max_lost = int(d.get("max_lost", 0))
		"celerity":
			obj.type = Type.CELERITY
			obj.max_ticks = int(d.get("max_ticks", 1))
		"interdiction":
			obj.type = Type.INTERDICTION
			var raw: Array = d.get("cells", [])
			for pair in raw:
				obj.cells.append(grid.index_of(Vector2i(int(pair[0]), int(pair[1]))))
		_:
			return null
	return obj
