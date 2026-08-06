# Banc de visualisation — jetable

Sert à répondre **de visu** aux questions perceptives qu'aucun compteur ne
tranche. Le rendu qu'il pilote (`game/view/`) est du vrai code gardé ; ce
répertoire ne l'est pas.

```bash
godot --path . game/bench/bench.tscn -- \
    --level=data/levels/diag/diag_archetypes.json \
    --stacks=2-3-1,3-2-1 --speed=4 --trail=6
```

| Option | Effet |
|---|---|
| `--level=<chemin>` | niveau JSON à charger (défaut `data/levels/ch1_01.json`) |
| `--stacks=a-b-c,d-e-f` | piles à comparer ; **Tab** passe à la suivante sans relancer |
| `--speed=1\|2\|4\|8` | ticks par seconde au démarrage |
| `--trail=<n>` | longueur de traînée, en **ticks** |
| `--autoquit=<n>` | quitte après n images — vérification headless, pas un usage |

| Touche | Effet | Tactile |
|---|---|---|
| Espace | marche / pause | toucher |
| → / D | un tick en avant | |
| ← / A | un tick en arrière (maintenu : rembobinage continu) | |
| 1 2 3 4 | 1, 2, 4, 8 ticks/s | |
| Tab | pile suivante | |
| C | couleurs par règle décisionnaire | |
| H | surcouche de diagnostic | appui long |
| M | animations réduites (ENF-21) | |
| R | réinitialiser | |

**La coloration par règle est l'instrument principal.** Chaque agent porte la
couleur de l'**emplacement de pile** qui a décidé pour lui à ce tick :
1 cyan, 2 ambre, 3 magenta, 4 vert, gris si aucune règle ne s'applique.
Deux règles dont les couleurs ne se mélangent jamais à l'écran sont deux
règles dont les zones d'action sont disjointes — donc dont l'ordre relatif
est inobservable.

## Géométries de diagnostic

Dans `data/levels/diag/` (`.lvl` lisible + `.json` converti) :

| Niveau | Question | Piles à comparer |
|---|---|---|
| `diag_archetypes` | les quatre archétypes du CDC §7.3 se séparent-ils ? | `2-3-1,3-2-1,1-2-3,2-1` |
| `diag_piege_ouest` | la zone piège Ouest : à quel point est-ce laid ? | `2-1` |
| `diag_parite` | l'escalier de parité : beau ou cassé ? | `3,3-1,1` |

## ⚠ Deux questions exigent le correctif R03 v2

Les chiffres « 439 demi-tours » et la comparaison `[2,3,1]` / `[3,2,1]`
proviennent de **R03 v2** (prédicat de maintien), qui n'est **pas** dans le
dépôt — décision du concepteur : les patches restent dehors tant que la
question R03 n'est pas tranchée.

Avec le code actuel, toute pile où R03 précède R01 **gèle** : c'est
visible immédiatement sur `diag_archetypes` avec `3-2-1`, et c'est en soi
une réponse (« voilà à quoi ressemble le gel »).

Pour voir v2, appliquer le patch temporairement — il touche `core/`, donc
les empreintes d'or divergeront tant qu'il est appliqué : **ne pas
committer**, et le retirer après.

```bash
git apply ~/volens-patches-r03/r03-v2-predicat.patch   # v2, prédicat de maintien
git checkout core/                                      # retour à l'état du dépôt
```

Les deux patches sont dans `~/volens-patches-r03/` (hors dépôt) :
`r03-tolerance.patch` (rayon satisfait, abandonné) et
`r03-v2-predicat.patch` (prédicat de maintien, en attente d'arbitrage).
