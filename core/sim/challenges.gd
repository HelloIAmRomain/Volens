class_name Challenges
extends RefCounted
## RG-18 / RG-19 — les trois défis facultatifs d'un niveau résolu.
##
## POURQUOI ILS EXISTENT. Un niveau réussi ne dit qu'une chose : « une pile
## marche ». Les défis demandent la suite — la plus courte, celle qui se passe
## d'une règle, celle qui va vite — et c'est là que le joueur découvre que la
## règle d'or a des conséquences qu'il n'avait pas vues. **Un jeu trop facile
## est un jeu qui s'oublie**, et la progression seule ne peut pas porter cette
## exigence : RG-19 interdit qu'un défi conditionne quoi que ce soit.
##
## RG-19, ET C'EST UNE CONTRAINTE, PAS UNE PRÉFÉRENCE : **aucun défi ne
## conditionne jamais la progression.** Ce module ne renvoie donc jamais
## d'échec, seulement des accomplissements. Il n'y a rien à rater — seulement
## quelque chose à ne pas encore avoir obtenu. Un défi manqué ne doit produire
## aucun message, aucun compteur rouge, aucune relance.
##
## PURETÉ. Fonction de trois entrées immuables — la pile jouée, l'état final,
## le bloc de défis du niveau — vers trois booléens. Aucun aléatoire, aucune
## horloge, aucun flottant (invariants 5 à 10). Les défis sont **exclus de
## l'empreinte** au même titre que les objectifs : ils décrivent le résultat,
## ils ne le produisent pas.
##
## INVARIANT N°15 — LE SEUIL D'EFFICIENCE EST UN PARAMÈTRE DE LA CARTE. Il est
## mesuré sur une géométrie donnée et devient faux dès qu'un mur bouge. Il vit
## donc dans le fichier de niveau, sous la protection de `calibrated_on`, et se
## lit par `LevelSpec.challenges()` — jamais recopié ailleurs (invariant n°16).

## L'ÉCONOMIE N'EST PLUS UNE CONSTANTE, ET C'EST LE CORRECTIF LE PLUS ÉTENDU DU
## LOT.
##
## Elle valait « trois emplacements au plus », fixé par le CDC pour être
## comparable d'un niveau à l'autre. L'intention était juste ; l'effet ne l'a
## jamais été : **vingt-huit niveaux sur vingt-neuf n'ouvrent que trois rangs**,
## donc le défi était acquis en même temps que la victoire, sans que le joueur
## sache qu'il existait. Signalé à l'essai : « niveau 1.3, défi 3 règles inutile
## car on a 3 règles au max ».
##
## Le seuil est désormais MESURÉ par niveau : c'est la taille de la plus courte
## pile gagnante, et le défi n'existe que si une gagnante plus longue existe
## aussi. On ne le gagne donc jamais du premier coup — il faut revenir avec une
## autre solution, ce qui est la définition d'un défi.
## Résultat d'un niveau résolu. Les trois clés sont toujours présentes ; une
## valeur `false` signifie « pas encore obtenu », jamais « raté ».
##
## `applicable_*` distingue « le défi n'a pas été obtenu » de « ce niveau ne
## propose pas ce défi » — sans quoi l'interface afficherait un défi éteint que
## rien ne permet d'allumer, ce qui est la définition d'une fausse piste.
static func evaluate(stack: Array, final_state: SimState, spec: Dictionary) -> Dictionary:
	var abstinence_rule: int = int(spec.get("abstinence_rule", 0))
	var efficiency_ticks: int = int(spec.get("efficiency_ticks", 0))
	var economy_max: int = int(spec.get("economy_max", 0))
	return {
		"economy": economy_max > 0 and _used_rules(stack).size() <= economy_max,
		"abstinence": abstinence_rule != 0 and not _used_rules(stack).has(abstinence_rule),
		"efficiency": efficiency_ticks > 0 and final_state.tick <= efficiency_ticks,
		"applicable_economy": economy_max > 0,
		"applicable_abstinence": abstinence_rule != 0,
		"applicable_efficiency": efficiency_ticks > 0,
	}

## Nombre de défis que ce niveau PROPOSE. Zéro est une réponse légitime, et
## c'est celle de neuf niveaux : l'interface doit alors n'afficher aucune
## pastille plutôt que trois éteintes qu'on ne peut pas allumer.
static func offered(spec: Dictionary) -> int:
	var n := 0
	if int(spec.get("economy_max", 0)) > 0:
		n += 1
	if int(spec.get("abstinence_rule", 0)) != 0:
		n += 1
	if int(spec.get("efficiency_ticks", 0)) > 0:
		n += 1
	return n

## Les règles réellement posées : les emplacements vides (0) ne comptent pas.
## Un joueur qui laisse un rang vide n'a pas « utilisé » une règle de plus, et
## le défi d'économie doit récompenser la pile courte, pas la pile tassée.
static func _used_rules(stack: Array) -> Array[int]:
	var used: Array[int] = []
	for raw in stack:
		var id := int(raw)
		if id != RuleRegistry.EMPTY and not used.has(id):
			used.append(id)
	return used
