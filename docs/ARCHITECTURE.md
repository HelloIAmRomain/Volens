# Architecture et invariants — Volens

Invariants d'architecture, conventions et commandes du dépôt. À relire avant toute contribution.

## Le jeu

Volens est un jeu mobile de puzzle systémique dans lequel le joueur ne contrôle jamais un individu : il compose une **pile ordonnée de 4 règles de comportement** qui gouvernent simultanément tous les agents d'une nuée, puis lance une simulation déterministe et observe le comportement collectif qui en émerge. La règle d'or, qui contient tout le jeu : **pour chaque agent, à chaque tick, la première règle de DÉPLACEMENT applicable de la pile l'emporte ; les règles d'EFFET s'appliquent au passage, sans consommer la décision.**

Le second membre a été ajouté le 14 août 2026, avec le genre `EFFET` (voir invariant n°17). Il ne relâche rien : un effet ne s'applique que si la cascade l'ATTEINT, donc sa position dans la pile reste décisive.

Un niveau est réussi quand la nuée satisfait un objectif (extraction, collecte, préservation, célérité, interdiction) ; l'échec n'entraîne jamais de perte, et le nombre d'essais est illimité.

## Documents de référence

- `docs/Volens_cahier_des_charges.md` — le **quoi** (exigences EF/ENF/RG/QN). Fait foi sur les besoins.
- `docs/Volens_dossier_conception_technique.md` — le **comment** (décisions DT). Fait foi sur l'architecture.
- `docs/Volens_plan_de_production.md` — le **quand** (jalons, lots, tâches T-xxx).

**En cas de contradiction entre ces documents, ou entre l'un d'eux et ce fichier : la signaler, ne pas la trancher seul.**

## Identité du projet — figée

| Élément | Valeur |
|---|---|
| Nom commercial | **Volens** |
| Nom de développeur Play | **Draille** |
| Identifiant d'application | **`com.volensgame.volens`** — irréversible après le premier envoi |
| Plateforme v1.0 | Android uniquement |
| `targetSdk` | **36** (Android 16) — obligatoire pour toute nouvelle application |
| `minSdk` | **33** (Android 13) — décision assumée : rien de plus ancien n'est supporté |

## Arborescence et invariants d'architecture — non négociables

```
res://
├── core/              # PUR : headless, déterministe, zéro dépendance au rendu
│   ├── sim/           #   état, transition de tick, règles, objectifs, empreinte
│   └── replay/        #   recette, clichés-clés, remontée du temps
├── game/              # tout ce qui touche au runtime Godot (nœuds, scènes, ressources)
│   ├── view/  ui/  audio/  meta/  save/  platform/
├── data/              # données pures (JSON) : niveaux, règles, thèmes. Aucune logique.
├── tools/             # validateur, éditeur, scripts headless
└── tests/             # unit/  golden/  arch/
```

### Règles de dépendance — testées en CI

1. **`core/` n'importe jamais `game/`.** Aucune exception, jamais « temporairement ».
2. **`core/sim/` n'importe que `core/sim/`.** Pas même `core/replay/`.
3. **`tools/` n'importe que `core/` et `data/`.**
4. Sens autorisé, jamais remontant : `game/ui → game/view → core/replay → core/sim`.

### Pureté de `core/sim/`

5. **Entiers uniquement.** Aucun `float`. Positions en `Vector2i`. Distances en Manhattan ou en carré de distance (`dx*dx + dy*dy`). Jamais `sqrt`, `sin`, `cos`, `pow`, ni division non entière dans une décision.
6. **Aucun aléatoire.** Jamais `randi`, `randf`, `randomize`, `RandomNumberGenerator`, `shuffle`, `pick_random`. Toute variation nécessaire est pré-calculée dans le fichier de niveau.
7. **Aucun temps réel.** Jamais `delta`, `Time.get_ticks_msec()`, `Time.get_datetime_*`, `OS.get_*time*`. La simulation avance par ticks logiques pilotés depuis l'extérieur.
8. **Ordre d'évaluation total et fixe.** Agents par `id` croissant. Directions départagées **Nord > Est > Sud > Ouest**. Conflit de case : le plus petit `id` gagne. Jamais d'itération sur un `Dictionary` dans un chemin de décision.
9. **Décisions sur cliché immuable.** L'état `t` est en lecture seule pendant tout le tick ; l'état `t+1` est écrit ailleurs. Aucun agent ne voit un mouvement du même tick.
10. **`step()` est une fonction pure** : mêmes entrées → même sortie, toujours, partout.

### Cohérence de l'espace des piles

11. **`slots` a une source de vérité unique : `LevelSpec.open_slots()`.** L'interface de jeu doit exposer **exactement** le nombre de rangs que le validateur énumère — ni plus, ni moins. Toute autre lecture de la clé `slots` est un défaut, et un test lexical le refuse.

    Ce n'est pas une question d'affichage. Le validateur énumère l'espace des piles jusqu'à `slots` et en tire `expected_wins`. Si le joueur atteint une pile qui n'a jamais été énumérée, **`expected_wins` devient faux** et `N_win` cesse d'être une propriété du niveau : la leçon que le niveau prétend enseigner ne tient plus. `expected_wins = 1` sur ch1_02 signifie « une seule pile gagne, et c'est l'ordre qui décide » — la phrase est fausse dès qu'une pile non comptée existe. Vérifié sur tout le catalogue par `tests/ui/test_slots_single_source.gd`.

16. **Un champ qui DÉCRIT un niveau se lit par `LevelSpec` ; un champ qui le FAIT TOURNER se lit par le moteur.** Généralisation de l'invariant n°11, après trois divergences sur trois champs différents. `expected_wins`, `expected_classes`, `tutorial`, `calibrated_on` et `slots` ne se lisent qu'à travers `LevelSpec` — un test lexical refuse toute autre lecture. `max_ticks`, `objectives`, `allowed_rules` et `agents` restent libres : ce sont des entrées de simulation.

    Motif : **toute valeur de niveau recopiée hors de sa source finit par diverger**, et chaque fois la divergence n'a été vue que par accident. Trois corrections au cas par cas auraient laissé passer le quatrième champ.

### Genres de règles et composition des piles

17. **Deux genres de règles, et deux seulement : PROPOSEUR et EFFET.** Un proposeur propose un déplacement ou s'abstient ; un effet agit sur le monde puis rend la main. Le genre `EFFET` a été introduit le 14 août 2026 pour R08/R11/R12, qui n'ont aucun déplacement à proposer — sous le seul genre proposeur elles devaient soit s'abstenir toujours (la règle n'existe pas), soit proposer l'immobilité (la règle masque toute la suite de la pile). C'est la pathologie P1 du dossier des genres, et c'était sa seule sortie.

    **La bibliothèque compte TREIZE règles, pas seize.** R07 et R10 retirées le 15 août 2026 (elles ne portaient nulle part) ; **R12 « Déposer au but » fusionnée dans R11 « Porter et déposer » le 21 août 2026** — leur ordre était inobservable par construction, un agent étant soit les mains vides sur une ressource, soit chargé près d'un dépôt, jamais les deux au même tick. Les identifiants restent réservés. Le CDC a été mis à jour en conséquence (**v2.6, RG-11 et §7.2 bis**) : il ne diverge plus.

    **Les trois autres genres du dossier — filtre général, condition de maintien, hystérésis — ne sont PAS introduits.** R04 a montré qu'une condition de maintien s'écrit très bien en proposeur qui s'abstient ; R16 est un filtre si étroit qu'il tient dans une lecture de la pile ; l'hystérésis reste gelée faute de joueurs. **Ne pas en ajouter un quatrième sans le même niveau de preuve** : une pathologie mesurée, et l'impossibilité démontrée de l'écrire autrement.

18. **Un effet se place en tête de pile, ou il ne s'applique jamais.** Une cascade s'arrête au premier proposeur qui décide ; il suffit donc d'une seule règle de déplacement au-dessus d'un effet pour que celui-ci ne parle plus jamais. Mesuré sur N14 : deux piles gagnantes sur soixante-cinq, toutes deux avec les deux effets aux rangs 1 et 2.

### Le cas d'épreuve

12. **Le cas d'épreuve est celui où le mécanisme est SOLLICITÉ, jamais celui où il est confortable.** Ce n'est pas un critère de test : c'est un critère de **conception**. Un mécanisme observé là où il n'a rien à faire paraît toujours correct — et paraître correct est exactement ce qui coûte cher.

    Trois fois le même piège, dans trois domaines sans rapport :
    - **R03** — trois semaines perdues à la juger sur des nuées compactes, où elle n'a rien à maintenir. Les archétypes ne se séparent que sur une **nuée dispersée près d'un danger**.
    - **Contention R2/R3** — nulle sur un bloc compact, 15 à 23 sur une nuée dispersée. Mesurée sur le cas confortable, elle disait « ces deux règles ne se disputent jamais », ce qui était faux.
    - **Cadrage plein écran** — juste par accident sur le ratio haut, où la grille est limitée en largeur. Il n'était faux que sur le **ratio court**, le seul où le calcul de hauteur travaille.

    **Application directe à la conception de N3 à N5** : un niveau censé départager des familles de piles doit être dessiné sur la géométrie où elles divergent, et vérifié là. Une grille où les trois familles se comportent pareil ne prouve rien, même si elle se joue bien — et c'est précisément ce qui rendait les fiches invalidées séduisantes.

### Géométrie des niveaux

19. **Le jeu est asymétrique gauche-droite, et une carte n'équivaut jamais à son miroir.** À égalité, toute règle préfère le Nord puis l'Est (ordre N>E>S>O) : une nuée qui doit s'écarter s'écarte plus volontiers vers l'Est, et un détour vers l'Ouest est structurellement plus dur. Le miroir de N9 a été construit et mesuré — il ne se résout pas. **La symétrie visuelle n'est pas une symétrie de jeu.**

20. **Trois conditions de R06 « Longer le mur », toutes établies à la mesure.** (a) Tout agent doit toucher un mur au départ, sinon rien ne le met en marche ; (b) les couloirs font UNE case — à deux, le suivi de main droite décrit un carré de 2×2 sans rien longer ; (c) le parcours n'a qu'un sens — deux agents face à face dans un couloir d'une case gèlent toute la file par remontée du refus (RG-06). Corollaire : **R06 et R01 se contredisent structurellement (P3) ; la seule carte propre pour R06 est une carte SANS lumière.**

**IDIOME DE NIVEAU PAR DÉFAUT — tous chapitres.** *La nuée ne va pas vers la sortie : elle va vers la lumière, et le mur l'oblige à passer par l'ouverture.*

La lumière est **derrière** un mur ; la sortie est **l'ouverture** de ce mur. Les deux cessent d'être des doublons : la lumière est la **raison** du mouvement — c'est ce que R01 poursuit — et la sortie est le **passage**. Poser la lumière sur la bande de sortie faisait dire la même chose au même endroit à deux marques distinctes, et transformait R01 en moteur qui va seul au but, tout le reste de la pile devenant décoratif.

L'idiome produit gratuitement un **entonnoir** : R01 teste le Nord d'abord ; bloqué par le mur, il prend la première direction qui rapproche encore de la lumière. Les agents glissent le long du mur jusqu'à l'ouverture, puis passent. Congestion, forme collective lisible, dispositif compris sans un mot.

Toute nouvelle carte part de cet idiome. S'en écarter demande une raison écrite dans la fiche du niveau.

13. **Le rapport des portées de perception borne les géométries possibles.** Avant de dessiner, demander : *quelle est la plus large des portées en jeu, et qui d'autre entre dedans ?*

    Sous sa forme actuelle (R02 perçoit à d² ≤ 25, R03 à d² ≤ 16) : **un danger assez proche pour border un traînard lui-même perçu par le bloc est nécessairement perçu par le bloc.** On ne peut pas isoler l'un sans exposer l'autre. Conséquence : deux répulseurs statiques encadrant la nuée l'enferment — **un seul danger par niveau peut punir une famille de piles ; deux la piègent.** Vaut pour tout couple (portée large, portée étroite) des chapitres suivants.

14. **Un répulseur à seuil dur ne se place jamais là où fuir ramène dans le seuil.** Sinon l'agent sort de portée, l'attracteur l'y renvoie, il rentre : boucle infinie. Deux corollaires mesurés sur le chapitre 1 : un danger **plein nord** d'une nuée qui monte refuse toujours le Nord ; et **fuite et entonnoir doivent tirer dans le même sens**, faute de quoi la dérive latérale oblige à revenir dans la portée.

    Ces trois contraintes ne sont plus des notes : le convertisseur les **refuse ou les signale** (`tools/lvl/lvl_parser.gd`, contrôles G1 à G3), et les tests les éprouvent sur la géométrie fautive elle-même.

15. **Un paramètre calibré est un paramètre de la CARTE, pas du niveau.** Échéance de célérité, seuil de préservation, pourcentage d'extraction, limite de ticks : tous sont mesurés sur une géométrie donnée et deviennent **faux dès que la géométrie bouge**. Un mur déplacé d'une case change des temps de parcours, donc des marges, donc des verdicts.

    Mécanique, pas déclaratif : chaque `.lvl` porte `calibrated_on: <empreinte>`, l'empreinte de sa géométrie (grille + positions initiales). Le convertisseur recalcule l'empreinte et **refuse** le niveau si elle diffère — les paramètres ont alors été mesurés sur une autre carte. Même dispositif que le `rules_hash` des recettes d'or, et pour la même raison : distinguer « le code a régressé » de « l'entrée a changé ».

## Conventions

**Édition de code existant.** **Jamais de remplacement textuel silencieux.** Un outil qui peut ne rien remplacer et rapporter un succès n'est pas utilisable : le défaut survit à sa propre correction, sans un mot. `sed -i`, `perl -i` et les scripts Python qui combinent `.replace()` et une écriture de fichier sont à proscrire. Modifier un fichier existant passe par un éditeur qui échoue quand l'ancre manque, ou par `tools/dev/patch.py`, qui exige un nombre exact d'occurrences et n'écrit rien si une seule ancre est en défaut.

**Langage.** GDScript avec **typage statique partout** (`var x: int`, `func f(a: int) -> bool`). Godot **4.7.1-stable**, version standard (pas .NET). Ne jamais produire de syntaxe Godot 3 (`export var`, `onready`, `KinematicBody`, `yield`).

**Nommage.** Fichiers et dossiers en `snake_case.gd`. Classes en `PascalCase` via `class_name`. Constantes en `SCREAMING_SNAKE`. Membres privés préfixés `_`. Terminologie du glossaire (CDC §18) en français dans les commentaires, en anglais dans le code (`agents`, `stack`, `tick`).

**Branches.** `main` protégée, jamais de commit direct. Une branche par lot : `feat/sim-tick-pipeline`, `fix/hash-overflow`, `chore/ci-godot-cache`, `docs/…`, `test/…`.

**Commits.** Conventional Commits, impératif, sujet ≤ 72 caractères : `feat(sim): ajoute la règle fuir-le-rouge`. Portées : `sim`, `replay`, `view`, `ui`, `audio`, `meta`, `save`, `tools`, `ci`, `docs`.

**Tests.** Tout ajout dans `core/` s'accompagne de ses tests unitaires dans le même commit. Aucune exception.

## Commandes
GUT est autorisé — c'est une dépendance de développement prévue au DCT §11.2. Il vit dans `addons/` et est exclu des règles de dépendance de `core/`.

Environnement machine : voir docs/environnement_dev.md. Les chemins y sont personnels et ne sont jamais codés en dur dans le projet.

```bash
# Simulation headless — VÉRIFIÉE (S2). Options : --stack=1,2,3  --verbose
godot --headless --path . --script res://tools/run_sim.gd -- --level=test_smoke --ticks=200

# Tests unitaires — VÉRIFIÉE (S2, GUT 9.6.1 installé)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# Tests d'or (non-régression du déterminisme) — VÉRIFIÉE (S3)
# (--write réservé aux gestes humains explicites, jamais en CI, et JAMAIS
#  sans prédiction écrite préalable — protocole permanent au carnet de bord)
godot --headless --path . --script res://tools/check_golden.gd

# Validateur sur un niveau — VÉRIFIÉE (S3) ; accepte un nom (data/levels/)
# ou un chemin res:// ; rapports dans reports/validate/ (gitignoré)
godot --headless --path . --script res://tools/validate/run.gd -- --level=test_smoke

# Convertisseur .lvl → JSON — VÉRIFIÉE ; --validate enchaîne le validateur
godot --headless --path . --script res://tools/lvl/run.gd -- --in=data/levels/ch1_01.lvl --validate

# Outils de CONCEPTION (tools/design/) — ils mesurent, ils ne corrigent rien.
# Tous rejouent l'espace complet des piles : compter en MINUTES, pas en secondes.
#
#   combinations.gd  — toutes les combinaisons de tous les niveaux. Ne compte que
#                      les gagnantes MINIMALES (aucune sous-suite ne gagne déjà),
#                      et nomme les monopoles, les voisinages pauvres et les jeux
#                      de règles qui gagnent plusieurs niveaux. `--level=` pour un
#                      seul niveau, indispensable quand on retouche une carte.
#   widen_search.gd  — quelle règle ajouter à quel niveau : ENRICHIT / BANALISE /
#                      DOUBLONNE / INERTE. `--level=` fortement conseillé.
#   level_forge.gd   — balaie des géométries DANS L'IDIOME, les mesure, et n'émet
#                      que celles qui portent plusieurs familles gagnantes.
#                      Déterministe (aucun tirage) ; sort du .lvl, jamais du JSON.
#                      C'est le VALIDATEUR qui juge (QN-01, sur-place, longueur),
#                      pas un score maison. Elle RESSERRE seule la bibliothèque
#                      jusqu'à ce que chaque règle offerte porte une gagnante, et
#                      écarte le candidat qui ne survit pas au resserrage — il ne
#                      tenait que par ses fausses pistes. Le fichier écrit est
#                      COMPLET : expected_wins, expected_classes, calibrated_on
#                      et deux défis qui exigent deux piles différentes.
#                      Photo du catalogue mise en cache dans reports/forge/ ;
#                      la première exécution après un changement de niveau la
#                      recalcule (plusieurs minutes).
godot --headless --path . --script res://tools/design/combinations.gd -- --level=ch2_04
godot --headless --path . --script res://tools/design/level_forge.gd -- \
    --rules=R01,R04,R09,R13 --slots=3 --want=R13 "--objective=extraction:85;preservation:3" \
    --band=two_gaps --plug=true --max=300 --top=4

# Banc de visualisation (JETABLE, game/bench/) — ouvre une FENÊTRE.
# Tab bascule de pile sans relancer ; voir game/bench/README.md
godot --path . game/bench/bench.tscn -- --level=data/levels/diag/diag_archetypes.json --stacks=2-3-1,3-2-1

# Écran de jeu (T-032) — ouvre une FENÊTRE. Pile composable, transport.
godot --path . game/ui/game_screen.tscn -- --level=data/levels/ch1_01.json

# Icônes — PROCÉDURALES, régénérées d'une commande (aucune image dessinée à la
# main : DT-13 interdit toute texture importée). Écrit icon / foreground /
# background / monochrome. Le chemin est un PARAMÈTRE — tools/ ne connaît pas
# game/ (règle de dépendance n°3).
godot --headless --path . --script res://tools/art/make_icon.gd -- \
    --out=game/ui --apercus=reports/art

# Export Android — CONFIGURÉ ET VÉRIFIÉ (15 août 2026). SDK 36, Java 21,
# modèles 4.7.1, build Gradle. L'APK de débogage s'installe sur l'appareil.
export ANDROID_HOME="$HOME/Android/Sdk"
godot --headless --path . --export-debug "Android" build/volens-debug.apk
# Vérifier les PERMISSIONS dans le paquet produit — la liste close et versionnée
# est data/android_permissions.json, mais c'est l'APK qui fait foi :
#   ~/Android/Sdk/build-tools/36.0.0/aapt2 dump permissions build/volens-debug.apk
#   → android.permission.VIBRATE, et RIEN d'autre
# Vérifier l'orientation DANS le paquet, jamais dans un intermédiaire :
#   ~/Android/Sdk/build-tools/36.0.0/aapt2 dump xmltree \
#       --file AndroidManifest.xml build/volens-debug.apk | grep screenOrientation
#   → screenOrientation=1 (SCREEN_ORIENTATION_PORTRAIT)
godot --headless --path . --export-release "Android" build/volens.aab

# Appareil sans fil — OPÉRATIONNEL. `platform-tools/` est hors dépôt (gitignoré) :
# ce sont des binaires externes, le jeu n'en dépend pas.
./platform-tools/adb devices -l
./platform-tools/adb install -r build/volens-debug.apk
./platform-tools/adb shell am start -n com.volensgame.volens/com.godot.game.GodotAppLauncher
./platform-tools/adb exec-out screencap -p > reports/device/ecran.png
# Si le démon adb redémarre, la liaison sans fil se retrouve par mDNS :
#   ./platform-tools/adb mdns services
```

## Parc de test et cibles mesurées

Un seul appareil physique, et c'est un flagship : les seuils du CDC y sont donc mesurés **avec marge**, jamais au seuil. Aucun achat d'appareil supplémentaire n'est prévu.

| Moyen | Rôle | Cibles |
|---|---|---|
| **Galaxy S23 Ultra**, Android 13, écran **forcé en 60 Hz** | Appareil de référence, arm64 | 60 i/s à **4× le nombre d'agents cible** · temps d'image **< 4 ms** · démarrage à froid **< 1,5 s** · reprise **< 1,5 s** · sobriété mesurée en **écart** simulation/pause, jamais en autonomie absolue |
| **AVD API 36** (Android Studio, Windows), x86_64 | **Seul endroit** où observer les comportements Android 15/16 : bord à bord obligatoire, retour prédictif, notifications. Le S23 sous Android 13 y est aveugle | Conformité comportementale |
| **AVD petit écran** (~5,8") | Le S23 fait 6,8" : pire cas pour l'atteignabilité au pouce, meilleur cas pour la densité d'information | Vérifie qu'une disposition calée sur 6,8" ne gaspille pas l'espace |
| **CI GitHub Actions**, Linux x86_64 | Tests d'or à chaque fusion | Empreintes identiques à celles du S23 |
| **Parc des testeurs** (test fermé Play, ≥ 15 personnes) | Vérification multi-appareils réelle | Écran d'**auto-vérification** : rejoue les recettes d'or et affiche un code court que le testeur **recopie manuellement**. Aucune transmission automatique — ENF-30 tient |

**Le déterminisme se vérifie sur deux architectures CPU distinctes** — arm64 sur l'appareil, x86_64 sur l'émulateur et la CI. C'est un test plus sévère que deux téléphones ARM. La moitié x86_64 est **acquise** (CI verte depuis le 5 août 2026) ; la moitié arm64 attend l'appareil de référence (T-003).

## Décisions réservées au porteur du projet

1. **Toucher aux tests d'or** (`tests/golden/`) ou à leurs empreintes archivées. Une empreinte qui change signale une régression du déterminisme — c'est un défaut à corriger, jamais une valeur à mettre à jour.
2. **Modifier l'identifiant d'application** `com.volensgame.volens`, le nom du paquet, la configuration de signature ou le fichier de clé.
3. **Ajouter une dépendance externe** : greffon, bibliothèque, SDK, service, appel réseau. Le jeu est **hors ligne et sans collecte de données** — c'est une exigence, pas une préférence.

   **Les permissions Android suivent une LISTE CLOSE**, `data/android_permissions.json`, tenue par `tests/arch/test_permissions.gd`. Elle contient aujourd'hui `VIBRATE`, et elle seule. L'interdiction générale d'origine (« sans permission ») a été levée le 17 août 2026 après mesure sur l'appareil : `VIBRATE` est de niveau *normal*, accordée sans aucune boîte de dialogue, et ne donne accès à aucune donnée — elle ne servait donc pas l'objet de l'interdiction, tout en rendant ENF-24 inapplicable. **Toute permission réseau reste interdite sans exception.**
4. **Écrire du rendu avant la simulation.** Aucun rendu, aucune scène, aucun nœud visuel pour une fonctionnalité dont la contrepartie dans `core/` n'est pas implémentée et couverte par ses tests. Le rendu suit toujours la simulation, jamais l'inverse. Condition satisfaite pour le périmètre du chapitre 1 depuis la clôture de S3.
5. **Introduire un `float`, un appel aléatoire ou une lecture d'horloge dans `core/`** — même « temporairement », même « pour déboguer ».
6. **Changer le format de sauvegarde** sans migration explicite et sans incrémenter `schema_version`.
7. **Committer sur `main`** ou réécrire l'historique.
8. **Trancher une contradiction** entre les documents de `docs/` et ce fichier. La signaler et attendre une décision.

## Règles de travail

- Une exigence ambiguë se cite et se discute ; un silence ne se comble pas par une invention.
- Zones à relecture renforcée : `core/`, `game/save/`, cycle de vie Android.
- Ne jamais « simplifier » un invariant ci-dessus pour gagner du temps : ils existent pour tenir 30 semaines, pas une session.
- Le validateur et le jeu partagent **le même code de simulation** (DT-15). Toute idée de réimplémenter la simulation ailleurs est à rejeter.
