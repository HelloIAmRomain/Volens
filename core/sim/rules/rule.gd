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

## À redéfinir par chaque règle concrète.
func evaluate(_agent: AgentState, _state: SimState, _params: RuleParams) -> Vector2i:
	return ABSTAIN
