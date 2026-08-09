# Dossier — révision des genres de règles

**Ouvert le 6 août 2026 · réécrit en diagnostic le 9 août 2026 · GELÉ jusqu'aux testeurs**

> Ce document ne recense plus des motifs épars. Il porte un **diagnostic
> unique** : la cascade de règles, telle qu'elle est spécifiée, produit quatre
> pathologies distinctes qui ont toutes la même cause. Trois chantiers du
> chapitre 1 en dépendent et resteront ouverts tant qu'elle n'est pas tranchée.
>
> **Il ne s'ouvre pas maintenant.** Voir §5.

---

## 1. La cause

La règle d'or du jeu — *pour chaque agent, à chaque tick, la première règle
applicable de la pile l'emporte* — se traduit par une cascade avec exactement
deux propriétés structurantes :

1. **Un seul genre de règle : le proposeur.** Une règle propose un déplacement,
   ou s'abstient. Il n'existe aucun autre mode d'expression.
2. **Aucune hystérésis.** La décision d'un tick ne connaît rien de celle du
   tick précédent. Il n'y a pas d'état de décision, pas de mémoire, pas
   d'inertie.

Ces deux propriétés sont la cause commune de tout ce qui suit. Aucune des
quatre pathologies n'est un défaut de paramétrage, de géométrie ou de
rédaction d'une règle particulière : chacune se déduit de la cascade.

## 2. Les quatre pathologies

### P1 — Une force dans un système qui n'accepte que des conditions

**R03 « Rester groupé »**, première version, convergeait vers le barycentre des
voisins. Mesuré sur un bloc compact : **0 agent sur 20 s'abstenait, 20
proposaient un pas refusé par leurs voisins**, et R03 masquait la suite de la
pile pour toujours.

La cause n'est pas le réglage : c'est qu'une force n'a **pas de terminal**. R01
en a un (la lumière), R02 une abstention naturelle (hors de portée) ; « converger
vers le barycentre » n'en a aucun, puisque le barycentre recule avec la nuée.

*Contournement en place* : R03 v2 est un **prédicat de maintien** — l'agent qui
compte un congénère à portée de main s'abstient. Le contournement fonctionne,
mais il a fallu **réécrire la règle pour la faire entrer dans le genre**, et non
l'inverse.

**Genre manquant : condition de maintien.**

### P2 — Une contrainte que la cascade ne sait pas exprimer

**R02 « Fuir le danger »** devrait *éviter* : « ne va pas là ». La cascade ne
sait qu'exprimer « va là ». On a donc écrit une **répulsion** — un déplacement
proposé qui s'éloigne — faute de pouvoir écrire une **contrainte sur les
propositions d'autrui**.

L'évitement pur est inexprimable : ce n'est pas une proposition, c'est un
filtre appliqué aux propositions des règles suivantes.

**Genre manquant : filtre.**

### P3 — Deux gradients opposés oscillent à leur frontière

Un attracteur et un répulseur à seuil dur se renvoient l'agent indéfiniment de
part et d'autre du seuil. Trace mesurée (danger en (4,10), portée² = 25) :

| tick | position | d² | R02 | R01 | décide |
|---|---|---|---|---|---|
| 0 | (0,14) | 32 | abstient | Nord | R01 → Nord |
| 1 | (0,13) | **25** | **Sud** | Nord | R02 → Sud |
| 2 | (0,14) | 32 | abstient | Nord | R01 → Nord |

**Ce n'est pas propre à R02.** La même trace a été relevée entre R01 et **R03**
lors de la conception d'une impasse : entrée t=4, sortie t=5, entrée t=6,
sortie t=7. L'énoncé général :

> **Deux règles qui se contredisent de part et d'autre d'un seuil produisent un
> cycle, quelles qu'elles soient.** Aucune géométrie ne l'empêche partout,
> puisque le seuil se déplace avec les agents.

Les échappatoires ont été instruites et ne tiennent pas : une hystérésis sur la
*portée* ne fait qu'élargir le cycle ; « préférer la direction qui éloigne le
plus » ne change rien, car au point critique une seule direction éloigne.

**Ce qui manque : un état de décision — de l'hystérésis, au bon endroit.**

### P4 — On ne peut pas enseigner l'ordre de deux règles contradictoires

C'est la conséquence de P3, et la plus coûteuse, parce qu'elle n'abîme pas un
niveau : **elle interdit une leçon**.

Pour que deux ordres d'une même paire — `[2,3,1]` et `[3,2,1]` — produisent des
nuées différentes, il faut que R02 et R03 se disputent le même agent. Or cette
dispute *est* la contradiction de P3, donc elle produit un cycle.

Mesuré, dix-huit géométries balayées puis deux dessinées :

- la géométrie qui sépare le mieux les deux ordres (**39 ticks d'écart**)
  laisse **trois piles gagnantes** avec un agent oscillant à perpétuité ;
- la géométrie sans aucune oscillation rend les deux ordres **rigoureusement
  identiques**.

> **Divergence et oscillation ont la même cause. On ne peut pas avoir l'une
> sans l'autre.**

## 3. Les trois chantiers qui en dépendent

Tous trois sont au **chapitre 1**, ce qui déplace l'échéance du dossier : il ne
prépare pas le chapitre 3, il répare l'existant.

| Chantier | Ce qui bloque | Pathologie |
|---|---|---|
| **La leçon de N5** — « il n'y a pas UNE bonne réponse » | Les deux ordres gagnants sont la même trajectoire ; les rendre distincts impose un agent oscillant | **P4** |
| **S4** — une règle seule ne gagne que le niveau qui l'introduit | Faire perdre `[1]` demande que R01 s'abstienne, donc des impasses ; la seule échappée fait de `[3,1]` une clé universelle | **P3** |
| **Stigmergie R08/R09** (chapitre 3) | Déposer un marqueur n'est pas proposer un déplacement : sous le genre proposeur, la règle s'abstient et n'est pas dans la pile, ou propose l'immobilité et masque tout ce qui suit | **P1** (genre manquant : **effet**) |

## 4. Ce qu'une révision devrait fournir

Quatre genres, et une propriété transverse :

- **proposeur** — l'existant : « je propose ce déplacement » ;
- **filtre** — « n'allez pas là » : une contrainte sur les propositions des
  règles suivantes, sans proposer soi-même (P2) ;
- **condition de maintien** — un prédicat satisfait ou non, qui rend la main
  sans rien proposer (P1) ;
- **effet** — une action qui n'est pas un déplacement : déposer, marquer,
  consommer (P1, chapitre 3) ;
- **hystérésis** — un état de décision porté d'un tick au suivant, seul remède
  connu à P3 et donc à P4.

**Contrainte non négociable** : tout cela doit rester **entier, déterministe et
sans horloge** (invariants 5 à 10). Une hystérésis est un état de plus dans
l'empreinte — donc une cérémonie du corpus d'or, et une révision de `hash_state`.

## 5. Pourquoi il n'est PAS ouvert maintenant

**Il est mûr techniquement et prématuré pédagogiquement.**

Toutes les mesures ci-dessus proviennent du validateur et de sondes. Aucune ne
provient d'un joueur. Refondre le système de règles sur des mesures d'outil,
sans qu'une seule personne ait découvert le jeu, reproduirait — à une échelle
bien plus grande — l'erreur de l'arc QN-02 : optimiser une propriété mesurable
avant de savoir si elle correspond à quoi que ce soit de perçu.

Trois des quatre pathologies ont d'ailleurs été *mal diagnostiquées au moins
une fois* avant d'être comprises, et une quatrième — « deux archétypes
indiscernables » — s'est révélée **inexistante** : une erreur de mesure sur un
terrain qui ne sollicitait pas le mécanisme.

> **Le dossier attend les testeurs.** Ce qui reste à savoir ne se mesure pas
> ici.

## 6. Références

- Carnet de bord : décisions 20-24 (P1), 31-33 (P3), 111-117 (généralisation),
  122-123 (l'archétype inexistant), 132-135 (P4 et N5).
- docs/ARCHITECTURE.md : invariants 12 (le cas d'épreuve), 13 et 14 (géométrie).
- CDC §7.2 (bibliothèque), §7.3 (dilemmes attendus), §12.2 (QN-01/02).
