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
| Défis RG-18 | rien | calculés dans `core/`, mesurés par le validateur, affichés au bilan |
| Niveaux | 5 (chapitre 1) | **22, six chapitres**, tous validés |
| Corpus d'or | 30 recettes | **60**, couvrant les seize règles et les deux genres |
| Tests | 346 | **379**, 5110 assertions |

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

## Ce qui reste, et qui ne dépend pas de moi

- **Le volume de contenu.** Le CDC vise 70 niveaux pour la v1.0 ; il y en a 22.
  Ce qui est complet, c'est le **vocabulaire** — chaque règle, chaque type de
  case et chaque type d'objectif est employé, enseigné et testé. Ajouter des
  niveaux est désormais une affaire de dessin, pas de moteur : la boucle
  d'écriture (`tools/dev/level.sh`) convertit, calibre, valide et résume en un
  geste.
- **P2, P3 et P4** du dossier des genres restent ouvertes, et l'hystérésis
  gelée. Deux résultats du chapitre 2 les confirment plutôt qu'ils ne les
  affaiblissent.
- **La chaîne Android** (S9), l'appareil de référence (T-003) et le recrutement
  des testeurs (T-008) : hors de portée d'ici.

## Ce qui n'a pas bougé

Les invariants 1 à 20 de `docs/ARCHITECTURE.md`, la pureté de `core/sim/` (entiers, aucun
aléatoire, aucune horloge), l'absence de toute dépendance externe, et le
protocole du corpus d'or — chaque régénération a été précédée d'une prédiction
écrite, et chacune l'a tenue au recipe près.
