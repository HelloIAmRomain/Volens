# Chapitre 2 — la coordination : ce qu'il exige avant le premier trait

> **Statut : ANALYSE, aucun niveau dessiné.** Ce document répond à une seule
> question — *le chapitre 2 tel que le CDC le spécifie est-il constructible
> avec le système de règles actuel ?* — et la réponse conditionne tout le reste.
>
> Source de vérité sur le contenu : CDC §7.2 (bibliothèque), RG-16 (objectif
> composé), RG-14 (vocabulaire de cases). Ce document ne décide rien contre eux.

## 1. Ce que le CDC demande

| Réf. | Nom de travail | Effet observable |
|---|---|---|
| R04 | S'écarter | L'agent s'éloigne si sa case compte trop de voisins adjacents ⚙️ |
| R05 | Suivre les voisins | L'agent adopte la **direction majoritaire** de ses voisins perçus |
| R06 | Longer le mur | L'agent suit l'obstacle qu'il a **à main droite** |

Et RG-16 : à partir du chapitre 2, la majorité des niveaux porte un **objectif
composé** — deux objectifs dont la satisfaction simultanée exige un arbitrage.

> **CORRECTION DU 10 AOÛT 2026.** La première rédaction de ce document
> concluait que le chapitre 2 exigeait d'**ajouter** un champ au modèle d'état,
> et en tirait une cérémonie d'or sur les 30 recettes. **C'était faux, et sur la
> prémisse.** `AgentState.dir` est spécifié au DCT §4.1 depuis le premier jour,
> **peuplé** par `SimCore._apply_movements` à chaque déplacement effectif, et
> **déjà parcouru** par `StateHash`. Je ne l'avais pas cherché.
>
> Conséquences : aucun ajout au modèle, aucune cérémonie d'état, aucun DCT à
> amender. R04, R05 et R06 sont implémentées et testées depuis, à empreintes
> d'état **inchangées** — les 30 recettes concordent. Le §2 ci-dessous est
> conservé dans sa conclusion (R05 et R06 ont besoin d'une direction) et
> corrigé dans sa conséquence (elle existe déjà).
>
> Ce que cela coûte : une journée d'analyse sur un champ à lire. **Vérifier
> qu'un champ manque se fait en le cherchant, pas en raisonnant sur ce qu'il
> faudrait.** Septième forme du piège de l'invariant 12 — cette fois, « paraître
> absent clôt l'examen ».

## 2. Le résultat : deux règles sur trois ont besoin d'une direction

C'est le point qui doit être tranché avant le premier niveau.

**R04 passe sans rien ajouter.** « Trop de voisins adjacents » se lit sur le
cliché du tick `t` ; « s'éloigner » propose un déplacement. C'est un proposeur
ordinaire, du même genre que R02 et R03. Rien de neuf.

**R05 ne passe pas.** « La direction majoritaire de ses voisins » suppose que
*direction* soit une propriété d'un agent. Or un agent n'a, aujourd'hui, qu'une
**position**. Sa direction au tick `t` est la différence entre sa position en
`t` et sa position en `t-1` — une information que l'état courant ne porte pas,
et que l'invariant 9 interdit d'aller chercher dans l'état suivant.

**R06 ne passe pas non plus.** « L'obstacle à main droite » suppose un **cap** :
sans orientation, « droite » n'existe pas. Deux agents au même endroit longeant
le même mur en sens inverse doivent voir des murs différents, ce qu'aucune
fonction de la seule position ne peut produire.

> **Le chapitre 2 exige d'ajouter au moins un entier par agent, conservé d'un
> tick au suivant : sa dernière direction.** R05 le lit chez ses voisins, R06
> s'en sert comme cap. Un seul champ suffit aux deux.

## 3. Est-ce la révision des genres de règles, qui est gelée ?

**Non, et la distinction est importante.**

Le dossier des genres (§4) réclame cinq choses : *proposeur*, *filtre*,
*condition de maintien*, *effet*, et *hystérésis*. Ce que le chapitre 2 demande
ressemble à la cinquième, mais n'en est pas :

| | hystérésis (gelée) | dernière direction (ici) |
|---|---|---|
| Ce que c'est | un **état de décision** : quelle règle a parlé, depuis combien de ticks | un **fait observable** : où l'agent est allé au tick précédent |
| Ce que ça change | la cascade elle-même — une règle peut « rester en place » | rien à la cascade : les règles restent des proposeurs |
| Ce que ça résout | P3, P4 — les oscillations à un seuil | rien de P1-P4 ; ça rend seulement R05 et R06 exprimables |

Les règles restent des **proposeurs**, elles gagnent seulement de quoi lire.
Le gel du dossier porte sur les **genres**, pas sur le contenu de l'état.

**Arbitrage : le chapitre 2 peut donc démarrer sans dégeler la révision.** Mais
il ne peut pas démarrer sans le champ, et le champ a un prix — §4.

## 4. Le prix — nul, et c'est mesuré

**Il n'y en a pas.** `dir` étant déjà peuplé et déjà haché, écrire R04, R05 et
R06 n'a déplacé aucune empreinte d'état : les **30 recettes concordent** après
l'ajout. Le seul élément périmé fut le tampon de provenance `rules_hash`, que
`data/rules.json` invalide dès qu'on y ajoute une clé — c'est son rôle, et il
a fonctionné.

La preuve est ainsi plus forte que toute parade argumentée : ce n'est pas une
comparaison de positions finales, qui peuvent coïncider alors que les
trajectoires diffèrent, c'est **la fonction d'empreinte elle-même** qui atteste
que la simulation n'a pas bougé.

### Ce que la première rédaction proposait, et pourquoi le noter

Elle prévoyait de conserver temporairement l'ancienne fonction d'empreinte pour
prouver la neutralité sous elle. Le dispositif était bon et reste la bonne
réponse le jour où un champ sera *réellement* ajouté à l'état — chapitre 3, la
stigmergie, en aura besoin. Il n'a simplement pas eu lieu d'être ici.

## 4 bis. Ce qui demandait une décision humaine, et qui n'en demande plus

Ajouter un champ à l'état de simulation le fait entrer dans `hash_state`. Donc :

- **les 17 recettes d'or changent**, toutes, y compris `test_smoke` ;
- c'est une **cérémonie complète**, avec prédiction écrite préalable ;
- et c'est le cas le plus délicat du protocole, parce que le confinement n'y
  prouve rien : quand *tout* bouge, on ne distingue plus « l'entrée a changé »
  de « le code a régressé » par la seule liste des divergences.

**La parade, et elle doit être posée avant l'écriture du champ** : rendre le
champ *neutre* sur les niveaux du chapitre 1. Si `last_direction` est initialisé
à une valeur fixe et n'est lu par aucune règle des chapitres 1, alors les
trajectoires du chapitre 1 sont inchangées — seule l'**empreinte** bouge, pas le
comportement. On le vérifie sans le corpus d'or, par un test qui compare les
**positions finales** avant et après, pile par pile, sur les cinq niveaux. Ce
test-là est la vraie preuve ; la cérémonie ne fait ensuite qu'enregistrer.

## 5. Ce que le chapitre 1 a établi et qui contraint déjà les niveaux

Trois résultats acquis, mesurés, et transposables tels quels :

1. **Seule une règle dont la condition dépend des congénères peut ouvrir une
   impasse.** R02 ne le peut pas (son seuil se déclenche avant, ou la direction
   de fuite est celle qui est murée). Au chapitre 2, **R05 le pourra** — sa
   condition dépend des voisins, comme R03 — et **R06 aussi**, qui est
   précisément faite pour sortir d'un cul-de-sac. R04 ne le pourra pas : son
   seuil est local, il retombe dans le cas de R02.
2. **Un niveau qui doit battre une pile d'une seule règle a besoin d'un
   dispositif où R01 s'abstient.** L'impasse est le seul connu. Le chapitre 2
   en hérite : chacun de ses niveaux doit en porter un, ou battre `[R01]` par
   la létalité — les deux seules voies mesurées.
3. **Le cas d'épreuve est celui où le mécanisme est sollicité** (invariant 12).
   R04 ne se juge pas sur une nuée dispersée, où elle n'a rien à écarter, mais
   sur un **goulot** ; R05 ne se juge pas sur une nuée qui va déjà toute dans le
   même sens ; R06 ne se juge pas sur un couloir droit.

## 6. Ce qui reste à décider, et par qui

| Question | Qui tranche | Bloque quoi |
|---|---|---|
| Ajouter `last_direction` à l'état, et accepter la cérémonie sur les 17 recettes | **le porteur** | R05, R06, donc le chapitre 2 entier |
| Portée de perception de R05, seuil de densité de R04 | à mesurer, comme au chapitre 1 | le dessin des niveaux |
| Sens de « main droite » pour R06 (horaire/antihoraire) | conception ; à figer comme l'ordre N>E>S>O | R06 |

**Rien n'est écrit tant que la première ligne n'est pas tranchée.** R04 seule
serait constructible immédiatement, mais un chapitre « coordination » réduit à
« s'écarter » n'enseigne pas la coordination : il refait le chapitre 1 avec une
règle de plus.
