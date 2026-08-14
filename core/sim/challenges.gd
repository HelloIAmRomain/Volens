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

## RG-18 : « résoudre avec trois emplacements au plus ». Le nombre est fixé par
## le CDC, pas par le niveau — c'est ce qui rend le défi comparable d'un niveau
## à l'autre, et donc lisible comme une compétence plutôt que comme un réglage.
const ECONOMY_MAX_SLOTS: int = 3

## Résultat d'un niveau résolu. Les trois clés sont toujours présentes ; une
## valeur `false` signifie « pas encore obtenu », jamais « raté ».
##
## `applicable_*` distingue « le défi n'a pas été obtenu » de « ce niveau ne
## propose pas ce défi » — sans quoi l'interface afficherait un défi éteint que
## rien ne permet d'allumer, ce qui est la définition d'une fausse piste.
static func evaluate(stack: Array, final_state: SimState, spec: Dictionary) -> Dictionary:
	var abstinence_rule: int = int(spec.get("abstinence_rule", 0))
	var efficiency_ticks: int = int(spec.get("efficiency_ticks", 0))
	return {
		"economy": _used_rules(stack).size() <= ECONOMY_MAX_SLOTS,
		"abstinence": abstinence_rule != 0 and not _used_rules(stack).has(abstinence_rule),
		"efficiency": efficiency_ticks > 0 and final_state.tick <= efficiency_ticks,
		"applicable_abstinence": abstinence_rule != 0,
		"applicable_efficiency": efficiency_ticks > 0,
	}

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
