# data/

Données pures (JSON) : aucune logique. `core/sim/` ne lit jamais de fichier
lui-même (DT-10, DT-15) — c'est l'appelant (`tools/`, plus tard `game/`) qui
charge ces fichiers et transmet des `Dictionary` déjà analysés.

## rules.json

Paramètres d'équilibrage des règles de comportement, jamais codés en dur
[DT-10]. Portées de perception exprimées en **carré de distance euclidienne**
(dx*dx + dy*dy), pour éviter tout `sqrt` (DT-04).

| Clé | Règle | Signification | Valeur de départ |
|---|---|---|---|
| `fuir_le_rouge.perception_range_sq` | R02 | rayon² au-delà duquel un danger n'est plus perçu | 25 (rayon ≈ 5 cases) |
| `rester_groupe.perception_range_sq` | R03 | rayon² au-delà duquel un congénère n'est plus perçu | 16 (rayon ≈ 4 cases) |
| `validation.min_cycle_period` | (validateur) | plancher ⚙️ de période des dangers cycliques — en dessous, l'oscillation d'une nuée se lit comme un tremblement | 6 |

R02 évalue les dangers **à l'instant d'arrivée** (revue S3, option C) : un
danger est menaçant s'il sera actif au tick t+1 ; un danger dormant qui le
restera n'exerce aucune répulsion — la traversée en phase calme est un
puzzle voulu.

R01 (vers la lumière) n'a pas de portée de perception : la lumière la plus
proche est toujours perçue, quelle que soit la distance (aucun `⚙️` sur R01
au CDC §7.2).

Toute modification de ces valeurs déclenche la revalidation des niveaux qui
utilisent la règle concernée (EQ-03) — hors périmètre tant que le validateur
(`tools/validate/`) n'existe pas encore.

## levels/

Fichiers de niveau. `test_smoke.json` est un niveau minimal de test
technique, pas un niveau de jeu.

### Format `.lvl` (source d'écriture, convertie en JSON)

Les niveaux se rédigent en `.lvl` (en-tête + grille ASCII) et se
convertissent via `tools/lvl/run.gd` (voir docs/ARCHITECTURE.md). Symboles : `.` vide,
`#` mur, `o` agent, `L` lumière, `E` sortie, `X` danger statique, `C`
danger cyclique (une ligne `cycle: period=N active=M` en en-tête, plancher
de période ⚙️), `r` ressource, `D` dépôt, `P` porte à pression. Les
espaces entre symboles sont ignorés.

**Conventions figées (elles affectent le déterminisme)** : les ids
d'agents suivent l'**ordre de lecture** (ligne par ligne, gauche à
droite) ; l'origine est **en haut à gauche**, y vers le bas.

**Limitations v1** : pas de « phase » de cycle (CycleDef n'a pas de
décalage — en ajouter un toucherait le parcours de hachage) ; sens
uniques `^ > v <` rejetés (orientation non représentable dans core/sim,
chapitre 2+) ; une seule définition de cycle par niveau.

En-tête : `id`, `name`, `tutorial`, `allowed_rules` (`[R01, R02]`),
`slots` (1-4, borne l'espace validé — CDC §12.2.1), `max_ticks`,
`lesson`, `expected_wins` (rapporté par le validateur : « attendu N,
constaté M », sans verdict), `objective:` répétable
(`extraction 60`, `preservation 2`, `celerity 120`, `collect 3`,
`interdiction (x,y) …`).

### Format d'un niveau (état S3 — évoluera)

```json
{
  "max_ticks": 300,
  "stack": [1, 2, 3, 0],
  "allowed_rules": [1, 2, 3],
  "grid": {
    "size": [largeur, hauteur],
    "cells": [ types de case, ligne par ligne — voir GridState.CellType ],
    "cycle_index": [ index de cycle par case, -1 sinon ],
    "cycles": [ {"period": 4, "active_ticks": 2} ]
  },
  "agents": [ {"pos": [x, y]} ],
  "objectives": [
    {"type": "extraction", "percent": 60},
    {"type": "preservation", "max_lost": 2},
    {"type": "celerity", "max_ticks": 120},
    {"type": "interdiction", "cells": [[x, y]]},
    {"type": "collect", "count": 3}
  ]
}
```

- `stack` : pile par défaut pour `run_sim.gd` (outillage seulement).
- `allowed_rules` : sous-ensemble de la bibliothèque offert au joueur
  (RG-14) ; c'est l'espace qu'énumère le validateur.
- `objectives` : voir `core/sim/objective_def.gd` — accomplissements
  (extraction, collect) et contraintes ; `preservation` et `interdiction`
  sont des **événements** (violation = défaite immédiate, prime sur tout),
  `celerity` est une **échéance** : réussir en au plus T ticks
  (`tick <= T`), évaluée après la victoire — gagner au tick exact de la
  borne est gagné (revue S3, 2.2). `collect` restera inatteignable
  jusqu'aux règles R11/R12 (chapitre 4) ; le validateur signale ce cas
  comme « hors chapitre », distinct d'un niveau cassé.
