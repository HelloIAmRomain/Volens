# Cérémonie du corpus d'or — chapitre 1 complet

**8 août 2026.** Objet : faire entrer les cinq niveaux définitifs du chapitre 1
au corpus d'or. **17 → 30 recettes.**

> Une première cérémonie avait été préparée le même jour sur les seuls N3-N5,
> puis **annulée** : les niveaux ont ensuite changé de géométrie (idiome
> lumière/sortie, harmonisation de N4-N5). Archiver les empreintes de niveaux
> sur le point de changer n'aurait rien prouvé. Le protocole et l'outil ont
> été conservés et rejoués ici sur les niveaux définitifs.

## 1. Nature de l'opération, et pourquoi `--write` n'est pas utilisé

**Treize ajouts, zéro modification.**

`--write` régénère les empreintes de **toutes** les recettes du fichier, les
existantes comprises. Sur un ajout, il absorberait donc en silence le seul
défaut que la cérémonie doit détecter : une empreinte existante qui bouge.

Chemin retenu :
1. calcul des candidates **en lecture seule** (`tools/dev/golden_candidates.gd`) ;
2. insertion sans toucher aux entrées existantes ;
3. `check_golden` **sans** `--write` comme confrontation.

Les 17 anciennes empreintes sont ainsi **revérifiées contre le moteur courant**,
jamais réécrites — pas même pour une valeur identique.

## 2. Prédictions, écrites avant mesure

- **P1** — aucune des 17 empreintes existantes ne bouge ; `rules_hash` reste
  `3d4b6b6f8a3e190f` ; le diff ne contient que des lignes ajoutées.
- **P2.a** — plus aucun agent présent à t = 50 sur les treize recettes.
- **P2.b** — `dynamics_hash` identique à 50, 150 et 300 : les trois empreintes
  d'une recette ne diffèrent que par le tick.
- **P2.c** — les treize empreintes à t = 50 sont deux à deux distinctes.

## 3. Confrontation

| Prédiction | Résultat |
|---|---|
| P1 | **vérifiée** — `git diff --numstat` : **165 ajoutées, 0 supprimée** ; `check_golden` : *concordent (30)* |
| P2.a | **vérifiée** — `present@50 = 0` sur les treize |
| P2.b | **vérifiée** — les treize triplets sont constants |
| P2.c | **vérifiée** — aucune collision |

## 4. Les treize recettes

Choisies pour couvrir les classes structurelles que le validateur distingue,
**défaites comprises** : l'arc du chapitre repose autant sur ce qui perd que
sur ce qui gagne.

| Niveau | Pile | Rôle | État à t = 50 |
|---|---|---|---|
| ch1_01 | `[1]` | la seule pile gagnante du premier niveau | 20 sortis |
| ch1_02 | `[1]` | **la nuée pressée se fait faucher** | 16 sortis, **4 perdus** |
| ch1_02 | `[2,1]` | la seule solution | 20 sortis |
| ch1_03 | `[1]` | famille directe | 21 sortis |
| ch1_03 | `[2,1]` | famille prudente | 21 sortis |
| ch1_03 | `[2,3,1]` | 3ᵉ classe, non prévue à la conception | 21 sortis |
| ch1_03 | `[3,1]` | **la cohésion tue le traînard** | 20 sortis, **1 perdu** |
| ch1_04 | `[1]` | famille directe, dans l'échéance | 21 sortis |
| ch1_04 | `[3,1]` | famille cohésion, dans l'échéance | 21 sortis |
| ch1_04 | `[2,1]` | **21 sortis et pourtant perdu** — après l'échéance | 21 sortis, LOST |
| ch1_05 | `[1]` | **la vitesse saigne** | 20 sortis, **1 perdu** |
| ch1_05 | `[2,1]` | prudence | 21 sortis |
| ch1_05 | `[3,1]` | **la cohésion sauve ce qu'elle tuait en N3** | 21 sortis |

## 5. Limite assumée

Les points de contrôle (50, 150, 300) sont tous **postérieurs à la
stabilisation** de ces niveaux, décidés avant le tick 40. Ces recettes pinnent
donc l'**état stabilisé** — outcome, positions finales, compteurs — et non le
chemin qui y mène.

Un point de contrôle précoce y remédierait, mais `checkpoints` est **global** :
les 17 archives gagneraient une clé absente et échoueraient toutes jusqu'à
régénération. Ce serait une **modification**, pas un ajout. Proposé comme
cérémonie distincte.
