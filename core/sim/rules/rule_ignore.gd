class_name RuleIgnore
extends Rule
## R16 — Ignorer (joker) [CDC §7.2] : neutralise, pour l'agent, l'effet d'un
## type de case choisi au placement de la règle.
##
## LA SEULE RÈGLE QUI PREND UN ARGUMENT, et la seule du chapitre 6 : le CDC
## appelle ce chapitre « l'exception », et c'en est une à tous les égards.
##
## ELLE NE DÉCIDE RIEN ET N'AGIT SUR RIEN — ni proposeur, ni effet au sens de
## R08. Elle **modifie la lecture du monde** pour l'agent qui la porte. C'est
## le genre « filtre » du dossier des genres, sous sa forme la plus simple :
## une contrainte sur ce que les autres règles perçoivent, sans rien proposer
## elle-même.
##
## POURQUOI ELLE N'A PAS DEMANDÉ D'OUVRIR LA RÉVISION DES GENRES. Un filtre
## général — « n'allez pas là » appliqué aux propositions d'autrui — exigerait
## de réécrire la cascade. R16 est infiniment plus étroite : elle ne filtre pas
## des propositions, elle éteint un TYPE DE CASE, et cela se lit dans
## `SimState.ignored_cell`, posé une fois par `step` à partir de la pile. La
## pile étant constante pendant toute une simulation, cette valeur l'est aussi
## — ce n'est donc pas un état, c'est une lecture de la pile.
##
## CE QU'ELLE PERMET, ET POURQUOI C'EST UN BON DERNIER CHAPITRE. Chaque type de
## case ignoré rouvre un niveau déjà résolu sous un autre jour :
##
##   · **danger ignoré** — la nuée traverse le feu sans perte. Le niveau qui
##     enseignait la prudence devient un niveau de vitesse ;
##   · **sens unique ignoré** — les chemins forcés redeviennent des allées et
##     venues, et les niveaux de transport se raccourcissent brutalement ;
##   · **porte à pression ignorée** — plus besoin de laisser personne derrière,
##     et le dilemme du chapitre 5 disparaît d'un coup.
##
## Le chapitre 6 ne présente donc **aucun mécanisme nouveau** : il donne au
## joueur le droit d'annuler l'un de ceux qu'il a appris, et lui demande lequel.
## C'est la seule fin possible pour un jeu dont le sujet est l'ordre des règles.
##
## SA POSITION DANS LA PILE EST INDIFFÉRENTE, et c'est la seule règle du jeu
## dans ce cas. Elle occupe un rang — donc elle en coûte un, ce qui est son
## vrai prix — mais elle agit sur tout le tick, pas à son tour. Le dire
## clairement au joueur est un travail d'interface, pas de simulation.

func kind() -> int:
	return Kind.PROPOSER

func evaluate(_agent: AgentState, _state: SimState, _params: RuleParams) -> Vector2i:
	return ABSTAIN  # elle ne propose jamais rien : son effet est dans la lecture
