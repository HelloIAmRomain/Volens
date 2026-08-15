class_name RuleWait
extends Rule
## R07 — Attendre [CDC §7.2] : l'agent reste immobile.
##
## LA RÈGLE LA PLUS COURTE DU JEU, ET LA PLUS TRANCHANTE. Elle ne s'abstient
## jamais : posée au rang n, elle rend muettes toutes les règles des rangs
## suivants, définitivement. C'est le seul terminal absolu de la cascade.
##
## POURQUOI C'EST UTILE PLUTÔT QUE DESTRUCTEUR. Deux usages, tous deux au CDC :
##
##   · **plancher volontaire** — au dernier rang, elle ne change rien (un agent
##     sans règle applicable est déjà immobile) mais elle rend le silence
##     EXPLICITE : le joueur qui la place déclare « et sinon, ne fais rien »,
##     au lieu de le subir ;
##   · **bouchon** — placée haut derrière une condition géométrique, elle fige
##     une partie de la nuée. C'est le seul moyen dont dispose le joueur pour
##     qu'un groupe reste sur des cases de commande pendant que le reste passe
##     une porte à pression. Sans elle, la porte à pression serait insoluble.
##
## ELLE NE CONNAÎT NI L'ÉTAT NI LES PARAMÈTRES, et c'est ce qui la rend
## prévisible. `Vector2i.ZERO` est le choix EXPLICITE de rester sur place,
## distinct de `ABSTAIN` — la distinction était réservée à cette règle depuis
## l'écriture de `Rule` (voir son en-tête), elle sert enfin.

func evaluate(_agent: AgentState, _state: SimState, _params: RuleParams) -> Vector2i:
	return Vector2i.ZERO
