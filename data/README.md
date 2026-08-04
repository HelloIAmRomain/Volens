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

R01 (vers la lumière) n'a pas de portée de perception : la lumière la plus
proche est toujours perçue, quelle que soit la distance (aucun `⚙️` sur R01
au CDC §7.2).

Toute modification de ces valeurs déclenche la revalidation des niveaux qui
utilisent la règle concernée (EQ-03) — hors périmètre tant que le validateur
(`tools/validate/`) n'existe pas encore.

## levels/

Fichiers de niveau. `test_smoke.json` est un niveau minimal de test
technique, pas un niveau de jeu.
