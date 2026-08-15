# Plan vdef — bilan de clôture

**Ouvert et clos le 14 août 2026.** Mandat : livrer une version définitive
jouable, testée, avec toutes les mécaniques.

## Ce qui est livré

| | au départ | à l'arrivée |
|---|---|---|
| Règles | R01-R06 (6/16) | **16/16**, chacune avec ses tests sur son cas d'épreuve |
| Genres de règles | proposeur seul | **proposeur + effet** — P1 close |
| Types de case | 5/9 actifs | **9/9**, tous dessinés à l'écran |
| Objectifs | 5 implémentés, 2 employés | **5/5 employés** par au moins un niveau |
| Niveaux | 5 (chapitre 1) | **29, six chapitres**, tous validés |
| Corpus d'or | 30 recettes | **74**, couvrant les seize règles et les deux genres |
| Tests | 346 | **396** |
| EQ-04 (règles vivantes) | jamais mesuré | **15 règles sur 16** à la cible du CDC |
| Défis RG-18 | rien | **17 niveaux**, mesurés, enregistrés, affichés |

## Les cinq résultats que la construction a établis

Aucun n'était prévisible sur le papier ; tous ont coûté une géométrie mesurée.

1. **Un effet ne s'applique que si la cascade l'ATTEINT** — donc il se place en
   tête, sans exception. Mesuré sur N14 : deux piles gagnantes sur soixante-cinq.
2. **R06 et R01 se contredisent structurellement.** Trois dispositifs essayés,
   trois oscillations. Sa seule carte propre est une carte sans lumière.
3. **Une piste est une pente, et une trace de passage** — pas un tapis, pas une
   trace d'occupation. Les deux erreurs figent la nuée exactement là où elle
   doit avancer.
4. **Le jeu est asymétrique gauche-droite.** Le miroir de N9 a été construit et
   mesuré : il ne se résout pas. La symétrie visuelle n'est pas une symétrie de
   jeu.
5. **Une géométrie invisible est une géométrie injuste.** Trois éléments du
   vocabulaire fonctionnaient parfaitement dans le moteur et n'étaient pas
   dessinés. Aucun test de simulation ne pouvait le dire ; il a fallu regarder.

## Le risque d'intérêt, nommé

**L'espace de piles est épuisable.** La moitié des niveaux offrent seize
piles : un joueur qui renonce à comprendre les essaie toutes en quelques
minutes. La difficulté du jeu n'est pas dans la recherche, elle est dans la
compréhension — et rien n'oblige à comprendre.

Agrandir l'espace ne répare rien : à quatre règles et quatre rangs on atteint
65 piles, et un niveau résolu par épuisement en 65 essais est pire qu'un
niveau résolu en 16. La réponse est ailleurs, et elle est posée : **les défis
RG-18 sont le jeu de celui qui a compris**, et ils ne se brutalisent pas — la
meilleure pile ne se trouve pas en les essayant toutes, elle se déduit.

**C'est la question à poser aux testeurs**, et aucune mesure d'outil ne la
remplacera : ont-ils essayé toutes les piles, ou raisonné ?

## Le rééquilibrage du 15 août 2026 — ce qui rendait le jeu creux

Trois défauts mesurés, tous invisibles au compteur naïf :

1. **Le compteur de gagnantes mentait.** Il comptait les RALLONGES : si `[R09]`
   gagne, `[R09,R01]` gagne aussi. ch6_04 annonçait dix-huit solutions ; il en
   avait trois. Le bon compte — *une gagnante ne compte que si aucune sous-suite
   d'elle ne gagne déjà* — révélait que **24 niveaux sur 29 n'avaient qu'une
   seule pile gagnante minimale**.
2. **21 niveaux sur 29 laissaient la pile contenir toute la bibliothèque.** Le
   joueur n'avait donc rien à choisir, seulement un ordre à trouver parmi six —
   alors que le mécanisme central du jeu est qu'une règle haute MASQUE ce qui la
   suit, ce qui ne se sent que si l'on doit renoncer à quelque chose.
3. **Chaque chapitre enseignait N règles, et la réponse à tous ses niveaux était
   « mets ces N règles ».** `[R08,R09]` répondait aux quatre niveaux du
   chapitre 3 ; `[R01,R11,R12]` aux quatre du chapitre 4, dont trois avaient
   exactement ces trois règles pour bibliothèque.

**Correctif : cinq à six règles pour trois rangs, partout hors chapitres 1 et 2**
(qui enseignent, et dont l'étroitesse est le moyen). Coût de la force brute,
avant → après : ch4_01 13→71, ch4_03 32→124, ch4_04 13→133, ch5_06 15→125,
ch6_05 49→357 ; espaces de 15 piles → 85 à 516.

**Aucune géométrie n'a bougé** : les 74 recettes d'or concordent sans cérémonie.
Et le tirage de l'Épreuve, qui ne retirait rien dans 24 niveaux sur 29, en
retire désormais 1 à 3 dans 20 sur 29 — le défaut était dans les niveaux, pas
dans le mode.

**Aucune pile ne traverse plus deux chapitres** : le pire passe-partout résout
trois niveaux, tous du même chapitre, ce qui est exactement le rôle d'un
chapitre.

## Le mode Épreuve — la réponse, et ce qu'elle ne couvre pas

Le second mode répond au risque ci-dessus en rendant la force brute **coûteuse**
plutôt qu'impossible : un chapitre entier joué d'un bloc, avec un budget de
lancements partagé (5 par niveau). Il ne débloque rien et ne coche aucun défi —
c'est une partie à côté, sans quoi il deviendrait le chemin court vers la
progression. **Le chapitre se choisit** parmi ceux entièrement résolus, et le
coût de la force brute est affiché en face : une ressource dont on ignore
l'ordre de grandeur ne se choisit pas. L'épreuve ne se met pas en pause — la
quitter l'abandonne, faute de quoi son budget n'en serait plus un.

**Mesuré, chapitre par chapitre :** la force brute coûte 32, 75, 36, 71, 63 et
73 lancements, contre des budgets de 25, 25, 20, 20, 30 et 25. Elle échoue
partout, de 1,3× à 3,6× ; un joueur qui raisonne (2 à 3 lancements par niveau)
garde de la marge partout. `tests/unit/test_trial_bite.gd` tient les deux bords.

**Ce que le mode ne fait PAS, et il faut le lire avant d'y croire.** Deux autres
leviers avaient été prévus, et la mesure les a vidés :

- le **tirage de règles** laisse la bibliothèque intacte dans 24 niveaux sur 29 ;
- le **quota par règle** aurait été plus vide encore — le quota le plus serré
  qui reste satisfaisable vaut la taille du chapitre dans quatre chapitres sur
  six. Il n'a pas été écrit.

**Cause commune, et c'est une borne du jeu, pas du mode :** 25 niveaux sur 29
n'ont **qu'un seul ensemble suffisant minimal**, contenant la règle-moteur de
leur chapitre. Le jeu porte sur l'**ordre**, jamais sur la **sélection** — ce
qui est cohérent avec sa leçon (« la première règle applicable l'emporte »),
mais interdit d'avance toute mécanique de restriction des règles. C'est une
seconde question pour les testeurs : cet unique axe suffit-il à tenir sur la
durée ?

## Ce qui reste, et qui ne dépend pas de moi

- **Le volume de contenu.** Le CDC vise 70 niveaux pour la v1.0 ; il y en a 29.
  Ce qui est complet, c'est le **vocabulaire** — chaque règle, chaque type de
  case et chaque type d'objectif est employé, enseigné et testé. Ajouter des
  niveaux est désormais une affaire de dessin, pas de moteur : la boucle
  d'écriture (`tools/dev/level.sh`) convertit, calibre, valide et résume en un
  geste.
- **P2, P3 et P4** du dossier des genres restent ouvertes, et l'hystérésis
  gelée. Deux résultats du chapitre 2 les confirment plutôt qu'ils ne les
  affaiblissent.
- **R10 « Rebrousser si seul » est morte au sens d'EQ-04**, et le CDC autorise
  deux issues : la retravailler — ce qui demande l'hystérésis, donc le dégel —
  ou la retirer de la bibliothèque. Les deux sont une décision de conception,
  pas un niveau de plus.
- **La localisation ENF-40** (français et anglais à parité) : les libellés sont
  en dur, avec des clés stables déjà prêtes dans `RuleCatalog`.
- **La chaîne Android** (S9), l'appareil de référence (T-003) et le recrutement
  des testeurs (T-008) : hors de portée d'ici.

## Ce qui n'a pas bougé

Les invariants 1 à 20 de `docs/ARCHITECTURE.md`, la pureté de `core/sim/` (entiers, aucun
aléatoire, aucune horloge), l'absence de toute dépendance externe, et le
protocole du corpus d'or — chaque régénération a été précédée d'une prédiction
écrite, et chacune l'a tenue au recipe près.
