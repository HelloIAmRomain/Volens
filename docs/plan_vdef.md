# Plan vdef — de six règles à un jeu complet

**Ouvert le 14 août 2026.** Mandat : livrer une version définitive jouable,
testée, avec toutes les mécaniques. Aucun retour attendu en cours de route.

## L'état au départ

| | fait | reste |
|---|---|---|
| Règles | R01-R06 (6/16) | **R07-R16 (10)** |
| Types de case | Mur, Sortie, Danger statique, Danger cyclique, Lumière | **Ressource, Dépôt, Porte à pression, Sens unique** (reconnus, inertes) |
| Objectifs | 5 types implémentés et testés unitairement | `collect` inerte, `interdiction` employée par aucun niveau |
| Défis RG-18 | rien dans `core/` | **les trois** |
| Niveaux | 5 (chapitre 1) | **chapitres 2 à 6** |
| Écrans | menu, sélection, jeu, bilan, réglages, auto-vérification | catalogue à 16 règles, défis, progression par chapitre |

## Le verrou, et comment il saute

Le dossier des genres de règles nomme la cause de tout ce qui bloque : **un
seul genre de règle, le proposeur**. R08 « marquer la piste » ne propose aucun
déplacement — sous le genre proposeur, elle s'abstient (et n'existe pas) ou
propose l'immobilité (et masque toute la suite de la pile). Trois règles du
chapitre 4 ont le même problème.

**Décision : le genre `EFFET` est introduit, et lui seul.** Une règle d'effet
agit sur le monde puis **rend la main** — la cascade continue. Les trois autres
genres du dossier (filtre, condition de maintien, hystérésis) ne sont PAS
introduits : R04 a montré qu'une condition de maintien s'écrit très bien comme
un proposeur qui s'abstient, et l'hystérésis reste gelée faute de joueurs.

La règle d'or s'énonce désormais ainsi, et c'est la seule reformulation :

> **Pour chaque agent, à chaque tick, la première règle de DÉPLACEMENT
> applicable de la pile l'emporte. Les règles d'effet s'appliquent au passage,
> dans l'ordre de la pile, sans consommer la décision.**

**La position d'une règle d'effet reste décisive**, et c'est ce qui la sauve de
l'insignifiance : un effet ne s'applique que si la cascade *l'atteint*. R08 au
rang 1 = « laisse toujours une trace » ; au rang 4 = « ne marque que si tu ne
savais pas quoi faire ». Deux jeux différents avec la même règle.

## Les six lots

**A — Moteur.** Genre `EFFET` et cascade ; `decided_by` par agent (sert aussi
à EF-05) ; sens unique et portes à pression dans `GridState` ; joker R16 encodé
dans l'identifiant de règle, sans changer `Array[int]`.

**B — Les dix règles manquantes**, chacune avec ses tests sur son cas
d'épreuve, jamais sur un cas confortable (invariant n°12).

**C — Objectifs et défis.** `collect` rendu atteignable par R11/R12 ;
`interdiction` employée pour de vrai ; les trois défis RG-18 calculés dans
`core/`, lus par `LevelSpec`, mesurés par le validateur.

**D — Les niveaux des chapitres 2 à 6**, tous passés au validateur : solubles,
non triviaux, et respectant les règles d'identité S1-S4 et QN-01/02/03.

**E — Interface** : catalogue à seize règles, défis au bilan, progression par
chapitre.

**F — Vérification finale** : suite complète verte, corpus d'or concordant,
validateur vert sur tout le catalogue, documents à jour.

## Ce qui ne bouge pas

Les invariants 1 à 16 de `docs/ARCHITECTURE.md`, la pureté de `core/sim/` (entiers, aucun
aléatoire, aucune horloge), l'absence de dépendance externe, le protocole du
corpus d'or (prédiction écrite avant toute régénération).
