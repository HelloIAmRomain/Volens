class_name Rule
extends RefCounted
## Interface commune des règles de comportement [DT-10].
##
## Chaque règle évalue un agent sur `state` (cliché du début de tick, lecture
## seule) et renvoie soit un vecteur de déplacement unitaire
## (Directions.offset(...)), soit ABSTAIN si elle ne s'applique pas — auquel
## cas la cascade (SimCore._decide_one) passe à la règle suivante de la pile
## (règle d'or : la première règle applicable l'emporte, RG-05).
##
## ABSTAIN est un vecteur hors de l'espace des sorties légitimes (les 4
## vecteurs unitaires cardinaux, plus Vector2i.ZERO réservé au choix
## explicite de rester sur place — ex. future règle R07 « Attendre ») :
## aucune règle correctement écrite ne peut légitimement le produire, il est
## donc sûr comme sentinelle de comparaison (`result != Rule.ABSTAIN`).
const ABSTAIN := Vector2i(-2, -2)

## Les règles sont conscientes des murs : une direction candidate menant hors
## grille ou dans un mur est ignorée, et une règle dont toutes les directions
## utiles sont bloquées s'abstient — la cascade continue. C'est la sémantique
## qu'implique le DCT §4.2 : `explain` documente « non applicable (…,
## mouvement bloqué) » comme raison d'inapplication.
##
## « Bloqué » signifie mur ou bordure de grille, UNIQUEMENT (revue S3, 2.3).
## Une case occupée par un autre agent n'est JAMAIS « bloquée » du point de
## vue d'une règle : sinon les règles deviendraient sensibles à la densité,
## entreraient en interaction avec la résolution de conflits, et plus aucun
## comportement ne serait explicable au joueur. Les conflits d'occupation se
## résolvent exclusivement à l'étape 3 du pipeline (RG-06/RG-07).

## GENRES DE RÈGLES [dossier des genres, §4 ; décision du 14 août 2026].
##
## Jusqu'ici il n'en existait qu'un — le PROPOSEUR — et c'était la cause commune
## des quatre pathologies du dossier. Un seul genre supplémentaire est
## introduit, le strict nécessaire :
##
##   · PROPOSER — « je propose ce déplacement, ou je m'abstiens ». L'existant,
##     et le genre de treize des seize règles ;
##   · EFFECT — « j'agis sur le monde, puis je rends la main ». Déposer un
##     marqueur, ramasser, déposer : aucune de ces actions n'est un
##     déplacement, et les écrire en proposeur obligeait soit à s'abstenir (la
##     règle n'existe pas) soit à proposer l'immobilité (la règle masque toute
##     la suite de la pile). C'est la pathologie P1, et c'est sa seule sortie.
##
## LA RÈGLE D'OR, REFORMULÉE — et c'est la seule reformulation qu'elle subit :
##
## > Pour chaque agent, à chaque tick, la première règle de DÉPLACEMENT
## > applicable de la pile l'emporte. Les règles d'EFFET s'appliquent au
## > passage, dans l'ordre de la pile, sans consommer la décision.
##
## LA POSITION D'UN EFFET RESTE DÉCISIVE, et c'est ce qui le sauve de
## l'insignifiance : **un effet ne s'applique que si la cascade l'ATTEINT.**
## R08 « marquer la piste » au rang 1 signifie « laisse toujours une trace » ;
## au rang 4, « ne marque que si tu ne savais pas quoi faire ». Deux jeux
## différents avec la même règle, et le joueur les découvre en déplaçant une
## tuile — exactement ce que le jeu prétend enseigner.
enum Kind { PROPOSER, EFFECT }

func kind() -> int:
	return Kind.PROPOSER

## À redéfinir par chaque règle de déplacement.
func evaluate(_agent: AgentState, _state: SimState, _params: RuleParams) -> Vector2i:
	return ABSTAIN

## À redéfinir par chaque règle d'EFFET. Renvoie `true` si l'effet a bien eu
## lieu — un effet inapplicable (rien à ramasser, aucun dépôt adjacent) répond
## `false`, ce qui ne change rien à la cascade mais permet à `explain` de dire
## la vérité au joueur plutôt que d'annoncer une action qui n'a pas eu lieu.
##
## PURETÉ : la méthode LIT `state` (le cliché du tick, en lecture seule) et
## ÉCRIT dans `next_state` — jamais l'inverse, jamais les deux dans le même
## sens. C'est l'invariant n°9 appliqué aux effets : aucun agent ne voit
## l'effet d'un autre agent du même tick.
##
## `moved` : l'agent a-t-il obtenu un déplacement à ce tick ? Certains effets
## en dépendent — une piste est une trace de PASSAGE, pas d'occupation — et
## d'autres non : ramasser et déposer se font aussi bien à l'arrêt.
func apply_effect(_agent_index: int, _state: SimState, _next_state: SimState,
		_params: RuleParams, _moved: bool) -> bool:
	return false
