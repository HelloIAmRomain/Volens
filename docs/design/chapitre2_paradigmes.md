# Chapitre 2 — paradigmes candidats

> **Statut : PROPOSITIONS À ARBITRER.** Rien de ce document n'est implémenté.
> Chaque entrée touche `core/sim/` et donc le corpus d'or ; aucune ne peut
> être ajoutée sans décision explicite.

## Ce que le chapitre 2 est déjà censé être

Le CDC §7.2 fixe ses trois règles : **R04 S'écarter**, **R05 Suivre les
voisins**, **R06 Longer le mur**. Son thème est *la coordination*.

## Le problème que le chapitre 1 a révélé, et qui vaut d'abord

Avec trois règles dont **une seule est un moteur** (R01), tout le reste est
modulation. Trois conséquences mesurées :

1. En terrain ouvert, **tout ce qui suit R01 est mort** : elle ne s'abstient
   jamais. La profondeur n'existe que là où elle se tait — d'où l'impasse de
   N3, et l'importance des murs.
2. **Invariant n°13** : deux répulseurs statiques encadrant la nuée
   l'enferment. On ne peut donc pas empiler les pièges dans un même niveau.
3. **La loi du cycle limite est générale** : deux règles qui se contredisent à
   une frontière produisent un cycle — attracteur/répulseur (N4), et aussi
   attracteur/cohésion (N3).

**R06 « Longer le mur » change la donne**, et c'est la vraie nouveauté du
chapitre 2 : c'est le **deuxième moteur** du jeu. Une règle qui produit du
mouvement soutenu sans cible, donc qui reste pertinente là où R01 s'abstient.
Les impasses cessent d'être des pièges pour devenir des couloirs.

**Recommandation : bâtir le chapitre 2 sur R06 d'abord**, et n'ajouter du
vocabulaire de terrain qu'ensuite. Un second moteur double l'espace des
comportements sans ajouter une seule case au format de niveau.

---

## Vocabulaire de terrain — candidats classés par coût

### Déjà dans l'énumération, inertes

`PRESSURE_DOOR` et `ONE_WAY` existent dans `GridState.CellType` mais ne font
rien. Les activer coûte moins qu'inventer autre chose.

#### A. Porte à pression — **le meilleur rapport intérêt / risque**

*Une porte reste ouverte tant qu'au moins N agents occupent la plaque.*

- **Ce que ça force** : la nuée doit **se scinder**, et accepter d'abandonner
  des agents en arrière. C'est le contraire exact de R03 et le premier vrai
  dilemme collectif du jeu — une partie du groupe se sacrifie en position pour
  que l'autre passe.
- **Pourquoi ça marche ici** : le déterminisme est trivial (compter des agents
  sur des cases, entiers, ordre fixe), et ça donne enfin un usage à **R04
  S'écarter**, qui sans cela n'est qu'un anti-R03.
- **Coût** : un champ « ouverte » recalculé à l'étape 1 du tick, une entrée
  dans l'empreinte d'état. Aucune donnée par agent.
- **TRANCHÉ (9 août) : mur, jamais mort.** Une porte qui tue est un danger de
  plus, et R02 y répondrait — cela **brouille le vocabulaire au lieu de
  l'étendre**. Une porte qui bloque introduit un **obstacle conditionnel**,
  catégorie qui n'existe pas encore dans le jeu : une case qui change d'état
  sans jamais changer de nature. C'est là qu'est la valeur.

#### B. Sens unique — **bloqué par un manque identifié**

Le convertisseur le **refuse explicitement** aujourd'hui : *« l'orientation
n'est pas représentable dans `core/sim` »*. La grille ne stocke qu'un type par
case, sans direction.

- **Ce que ça force** : des circuits, des retours impossibles, une vraie
  topologie plutôt qu'un champ de distance.
- **Coût réel** : un tableau d'orientations parallèle à `cells`, entrant dans
  l'empreinte. Ce n'est pas difficile, c'est juste **non fait**.
- **Verdict** : à faire *si* le chapitre 2 en a besoin, pas avant.

### Nouveaux — par ordre décroissant d'intérêt

#### C. Courant — *l'eau, sans nage*

*Une case pousse l'agent d'une case dans une direction fixe, après son
mouvement.*

- **Ce que ça force** : la trajectoire cesse d'être la somme des décisions. Le
  joueur doit anticiper une dérive qu'aucune règle ne commande — et **R02
  devient inutilisable telle quelle** près d'un courant, puisque fuir peut
  vous y ramener. C'est le cycle limite rendu visible et intentionnel.
- **Pourquoi je le préfère à « nager »** : « nager » demande un compteur par
  agent (deux ticks pour traverser), donc un état par agent, donc une
  extension de l'empreinte et un risque de désynchronisation. Le courant est
  une **transformation du terrain**, pas un état d'agent : strictement moins
  cher, et plus lisible à l'écran.
- **Coût** : une étape 4 bis dans le pipeline, avec sa propre résolution de
  conflits (deux agents poussés sur la même case).
- **Risque sérieux** : le courant peut pousser un agent dans un danger. Cela
  doit être **voulu et lisible**, sinon la mort devient inexplicable (P4).

#### D. Clé et serrure — *l'objet porté, version minimale*

*Un agent qui traverse la clé la porte ; la porte s'ouvre quand un porteur
l'atteint.*

- **Ce que ça force** : la nuée n'est plus interchangeable. **Un agent devient
  particulier** — et c'est un basculement de fond, parce que DA-01 dit que le
  personnage est la nuée. À manier avec précaution : le jeu ne doit pas
  devenir « escorter l'élu ».
- **Coût** : un bit dans `AgentState.flags`, déjà dans l'empreinte. Faible.
- **Verdict** : intéressant mais **contre le pilier du jeu**. Je le rangerais
  au chapitre 4, avec ressources et dépôts, où porter est déjà le sujet.

#### E. Brouillard — *réduction locale de perception*

*Sur ces cases, les portées de R02 et R03 sont divisées.*

- **Ce que ça force** : les règles cessent d'avoir un comportement uniforme.
  Le joueur découvre que la portée est un paramètre, pas une loi.
- **Coût** : faible (une lecture de case dans l'évaluation).
- **Risque** : **invisible**. Une règle qui change de comportement sans que
  rien ne bouge à l'écran est exactement ce que P4 interdit. Il faudrait un
  rendu très fort, et je ne sais pas encore lequel.

---

## Ordre recommandé

1. **R06 Longer le mur** — le second moteur. Rien d'autre n'est nécessaire
   pour que le chapitre 2 existe.
2. **Porte à pression** — le dilemme collectif, et le seul emploi honnête de
   R04.
3. **Courant** — quand il faudra que le terrain agisse, et pas seulement qu'il
   bloque.
4. Sens unique, brouillard, clé — seulement si un niveau précis les réclame.

## Interdiction — le type d'objectif oublié, et le meilleur allié de R06

`interdiction` est **implémentée et utilisée nulle part**. C'est le type le
plus proche de « atteindre une zone », pris par l'autre bout : au lieu d'aller
quelque part, il s'agit de n'y aller jamais.

**Le fait à assumer : aucune règle ne répond à une zone interdite.** R02 fuit
ce qui **tue**, pas ce qui est **défendu**. Un niveau à interdiction se résout
donc par la **géométrie et l'ordre seuls** — c'est le premier objectif du jeu
auquel aucune règle ne réagit, un puzzle de routage pur.

Ce n'est pas un défaut à corriger : c'est la propriété du type, et elle rend
**R06 « Longer le mur » nettement plus utile**. Contourner une zone défendue
sans qu'aucune règle ne la perçoive est exactement ce qu'un suiveur de mur
sait faire — et rien d'autre ne le sait.

## Ce qu'il faut trancher avant d'écrire une ligne

- **Un courant qui pousse dans un danger : voulu ou interdit par le
  validateur ?**
- **La clé rompt-elle DA-01 ?** — si un agent devient particulier, la nuée
  cesse d'être le personnage.
- **Le cycle de frontière est architectural** (carnet, décision 117) : la
  cascade est « premier match gagnant, sans hystérésis », et deux règles qui
  se contredisent à un seuil se renvoient l'agent indéfiniment. Aucune
  géométrie ne l'empêche partout. Ajouter des règles au chapitre 2 **avant**
  la révision des genres, c'est ajouter des paires susceptibles de cycler.
- **Le corpus d'or** : chaque ajout au pipeline change l'empreinte de tous les
  états. Ce n'est pas une régression, c'est une cérémonie — et elle demande un
  accord explicite.
