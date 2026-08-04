# VOLENS — Dossier de conception technique

**Version 1.1 — 4 août 2026**
*Réponse technique au cahier des charges fonctionnel v2.1 du projet nom commercial : Volens*

---

## 0. Objet, portée et lecture

### 0.1 Objet

Ce document définit **comment** réaliser ce que le cahier des charges (CDC v2.0) exige. Il fixe les choix de technologies, l'architecture, les algorithmes structurants, les formats de données, l'outillage et l'environnement de production. Chaque exigence du CDC trouve ici sa solution ; la matrice de traçabilité (§14) le vérifie exhaustivement.

### 0.2 Décisions de cadrage entérinées

| Décision | Valeur | Conséquence technique |
|---|---|---|
| Nom commercial | **Volens** | Identifiant d'application : `com.<éditeur>.volens` — à figer avant le premier export signé, car ineffaçable ensuite |
| Plateforme v1.0 | **Android uniquement** | iOS sort du périmètre ; aucune dépendance Apple ; les choix restent néanmoins portables (voir §1.6) |
| Dépenses | **Zéro paiement tant que non indispensable** | Toute la chaîne retenue est gratuite ; le seul coût incompressible (compte Google Play, 25 $) est **différé au jalon J5** (§13) |

### 0.3 Convention

Les identifiants **DT-xx** désignent les décisions techniques de ce document. Chaque décision indique les exigences du CDC qu'elle satisfait. Les mentions [CDC …] renvoient au cahier des charges.

---

## 1. Étude technologique : choix de la pile

### 1.1 Critères d'évaluation

Pondération issue du CDC et du contexte (développeur solo, assisté par IA) :

| Critère | Poids | Origine |
|---|---|---|
| A. Aptitude 2D mobile (perf, poids, batterie) | ★★★ | ENF-10 à ENF-14 |
| B. Capacité à garantir le **déterminisme strict** | ★★★ | RG-03, ENF-05 |
| C. Exécution **headless** de la logique de jeu (outil de validation) | ★★★ | EQ-01 |
| D. Maturité, pérennité, licence | ★★ | O4, budget zéro |
| E. Qualité de l'assistance IA sur la pile (corpus d'entraînement, fiabilité du code généré) | ★★ | Contexte solo-dev assisté |
| F. Coût | ★★ | Décision de cadrage |
| G. Courbe d'apprentissage pour un ingénieur logiciel non-spécialiste jeu | ★★ | Profil du porteur |
| H. Réversibilité / portabilité future (iOS, PC) | ★ | §1.6 |

### 1.2 Candidats évalués

**Godot 4.7 (GDScript)** — moteur libre (MIT), rendu 2D dédié, export Android mûr, exécution headless native (`--headless`), langage proche de Python. Corpus IA abondant ; risque connu : les assistants mélangent les syntaxes Godot 3/4, ce qui se neutralise par une consigne systématique (§12). Coût : 0 €.

**Godot 4.7 (C#/.NET)** — écarté malgré l'attrait du langage : le support Android de C# dans Godot 4 est **officiellement expérimental et limité** (architectures restreintes, API manquantes pouvant planter à l'exécution). Inacceptable pour un produit dont la fiabilité de reprise (EF-20/21) est le cœur de la promesse.

**Unity 2D** — mûr et documenté, mais : runtime plus lourd (poids d'APK de base supérieur, ENF-11 sous tension), éditeur propriétaire avec historique récent de changements de licence unilatéraux (risque D), déterminisme flottant plus délicat à verrouiller, exécution headless de la seule logique de jeu moins naturelle. Aucun avantage décisif pour un jeu de cette simplicité graphique.

**Flutter + Flame** — excellent pour l'UI, corpus IA très riche ; mais Flame reste jeune pour du jeu à simulation, l'écosystème « jeu » est mince (pas d'éditeur de scène, tooling niveau/animation à construire soi-même), et le couple UI déclarative + boucle de simulation est moins éprouvé. Coût d'intégration supérieur pour un bénéfice nul ici.

**LibGDX (Java/Kotlin)** — robuste et véritablement headless par nature, mais framework bas niveau : tout l'outillage (scènes, UI tactile, thèmes, export) est à assembler à la main. Productivité solo nettement inférieure ; corpus IA vieillissant.

**Defold** — léger, orienté 2D mobile, gratuit ; mais communauté restreinte, corpus IA faible (le langage Lua y est très spécifique au moteur), et dépendance à un éditeur/écosystème étroit. Risque E et D.

**Natif Kotlin + Jetpack Compose** — maîtrise totale d'Android, poids minimal ; mais tout le moteur de jeu (boucle, rendu canvas performant, interpolation, particules, audio) serait à écrire. Pertinent pour une app, disproportionné pour un jeu, même minimaliste.

### 1.3 Synthèse comparative

| Critère (poids) | Godot/GDScript | Godot/C# | Unity | Flutter+Flame | LibGDX | Defold | Natif Kotlin |
|---|---|---|---|---|---|---|---|
| A. 2D mobile (×3) | ✔✔✔ | ✔✔✔ | ✔✔ | ✔✔ | ✔✔ | ✔✔✔ | ✔ |
| B. Déterminisme (×3) | ✔✔✔ | ✔✔✔ | ✔✔ | ✔✔ | ✔✔✔ | ✔✔ | ✔✔✔ |
| C. Headless (×3) | ✔✔✔ | ✔✔ | ✔ | ✔✔ | ✔✔✔ | ✔ | ✔✔✔ |
| D. Maturité/licence (×2) | ✔✔✔ | ✔ | ✔✔ | ✔✔ | ✔✔ | ✔ | ✔✔✔ |
| E. Assistance IA (×2) | ✔✔ | ✔✔ | ✔✔✔ | ✔✔✔ | ✔ | ✗ | ✔✔✔ |
| F. Coût (×2) | ✔✔✔ | ✔✔✔ | ✔✔ | ✔✔✔ | ✔✔✔ | ✔✔✔ | ✔✔✔ |
| G. Apprentissage (×2) | ✔✔✔ | ✔✔ | ✔✔ | ✔✔ | ✔ | ✔✔ | ✔ |
| H. Portabilité (×1) | ✔✔✔ | ✔ | ✔✔✔ | ✔✔ | ✔✔ | ✔✔ | ✗ |

### 1.4 Décision

> **DT-01.** Le projet est réalisé avec **Godot 4.7.x stable** et le langage **GDScript** (typage statique activé et exigé partout). Le langage C# est exclu tant que son support Android reste expérimental. *(Satisfait : A, B, C, D, F, G.)*

> **DT-02.** Une **porte de sortie performance** est réservée : si le budget de tick (§6.5) est dépassé, le cœur de simulation — et lui seul — est porté en **C++ via GDExtension**, en conservant l'interface décrite en §4. Décision prise sur profilage mesuré, jamais préventivement. *(ENF-10, ENF-14.)*

### 1.5 Versions figées

| Composant | Version | Politique de mise à jour |
|---|---|---|
| Godot | 4.7.x (dernière stable de la branche) | Correctifs 4.7.x acceptés ; **changement de branche (4.8+) interdit après J2** sauf faille de sécurité |
| JDK (build Android) | OpenJDK 17 | Requis par la chaîne d'export Godot 4 |
| Android SDK | Outils en ligne de commande, plateforme **API 36** | API cible figée par Google Play [CDC §14.4] |
| Contrôle de version | Git | — |

### 1.6 Portabilité future (information, hors périmètre)

Rien dans DT-01 ne condamne iOS ou PC : Godot exporte vers les deux, et l'isolation du cœur de simulation (§4) rend le portage du jeu indépendant du portage de la logique. Seuls resteraient à traiter : le compte Apple, les manifestes de confidentialité iOS, et l'adaptation d'écran. Aucun choix du présent document ne devra être défait.

---

## 2. Vue d'ensemble de l'architecture

### 2.1 Principe directeur

> **DT-03. Le cœur de simulation est un module pur, sans aucune dépendance au moteur de rendu ni à la scène.** Il ne connaît ni nœuds, ni écrans, ni temps réel. Il expose une unique fonction de transition d'état. Tout le reste du programme — rendu, interface, audio, sauvegarde — est un **consommateur** de ce module. *(RG-03, EQ-01, ENF-05 ; conditionne DT-02 et DT-20.)*
>
> Ce principe se traduit en **trois règles de dépendance testables** *(v1.1)* :
> 1. `core/` n'importe jamais `game/`. Aucune exception, jamais « temporairement ».
> 2. `core/sim/` n'importe que `core/sim/`. Pas même `core/replay/`.
> 3. `tools/` n'importe que `core/` et `data/`.

Ce principe a une conséquence vérifiable : le module doit s'exécuter tel quel en mode headless, sans fenêtre. C'est le **test d'architecture n°1**, automatisé en CI (§11.3) : tout import remontant vers `core/` depuis `game/` fait échouer l'intégration.

### 2.2 Découpage en modules

*(v1.1 — arborescence à deux étages, qui rend la règle de dépendance ci-dessus directement visible et testable.)*

```
res://
├── core/          # pur, headless, déterministe — zéro dépendance au rendu
│   ├── sim/       #   état, transition de tick, règles de comportement,
│   │              #   chargement de niveau, vérification d'objectifs,
│   │              #   empreinte d'état (hash)
│   └── replay/    #   recette, clichés-clés, remontée du temps
├── game/          # tout ce qui touche au runtime Godot (nœuds, scènes, ressources)
│   ├── view/      #   rendu de la grille et de la nuée, interpolation, effets
│   ├── ui/        #   écrans, pile de règles, HUD, bilan, réglages
│   ├── audio/     #   moteur sonore génératif
│   ├── meta/      #   progression, défis, déblocages
│   ├── save/      #   persistance atomique, schémas versionnés
│   └── platform/  #   cycle de vie Android, haptique, achat (J5)
├── data/          # niveaux, définitions de règles, thèmes (données pures)
├── tools/         # validateur headless, éditeur de niveaux, scripts CI
└── tests/         # unit/  golden/  arch/
```

Dépendances autorisées (sens unique, jamais remontant) :

```
game/ui → game/view → core/replay → core/sim
game/ui → game/meta → game/save
game/audio → core/replay (lecture seule des événements)
tools → core/ (exclusivement, + data/)
```

### 2.3 Flux principal d'une partie

1. `ui` charge un niveau (`data`) et la pile du joueur.
2. `replay` pilote `sim` tick par tick, mémorise les clichés-clés (§5.3).
3. `view` interpole visuellement entre le tick affiché et le suivant — **sans jamais influencer `sim`** (RG-02 : le rendu est un spectateur).
4. `sim` émet des événements datés (agent sorti, agent perdu, ressource déposée) ; `view` et `audio` les consomment.
5. À chaque action significative, `save` écrit la recette (§7.2).

---

## 3. Spécification du déterminisme

Section normative : elle traduit RG-03/ENF-05 en règles de code vérifiables.

> **DT-04. Arithmétique entière exclusive dans `sim/`.** Aucun `float` : positions `Vector2i`, distances en métrique de Manhattan ou en carré de distance euclidienne (`dx*dx + dy*dy`), seuils entiers. Les barycentres (règle R03) se calculent en sommes entières comparées en produits croisés, jamais en divisions flottantes. Un test statique de CI rejette tout littéral flottant et tout appel à `sqrt`, `sin`, `cos`, `randf`, `randi` dans `sim/`.

> **DT-05. Aucun aléatoire à l'exécution.** Si un niveau requiert de la variation (positions initiales), elle est **pré-calculée et inscrite dans le fichier de niveau**. `sim/` ne contient aucun générateur.

> **DT-06. Indépendance au temps réel.** `sim/` ignore `delta`, l'horloge et la fréquence d'affichage. La cadence des ticks est décidée par `replay` (4/8/16 ticks/s selon la vitesse choisie, EF-02) ; `view` interpole entre deux états pour la fluidité (ENF-10) sans jamais écrire dans l'état.

> **DT-07. Ordre d'évaluation total et documenté.**
> — Les agents sont évalués par identifiant croissant (RG-05), l'identifiant étant l'index de position initiale dans le fichier de niveau.
> — Les directions candidates d'une règle sont départagées dans l'ordre fixe **Nord > Est > Sud > Ouest**.
> — Les conflits de case (RG-06) se résolvent au profit de l'identifiant le plus faible.
> — Interdiction d'itérer sur toute structure à ordre non garanti (`Dictionary`) dans le chemin de décision ; les collections d'état sont des tableaux indexés.

> **DT-08. Sémantique de cliché (RG-07).** La transition de tick lit exclusivement l'état *t* (immuable pendant le tick) et écrit un état *t+1* neuf. Concrètement : double tampon d'état, échange en fin de tick. Aucune règle ne voit un mouvement du même tick.

> **DT-09. Empreinte d'état.** `sim/` sait produire une empreinte (hash 64 bits de type FNV-1a, implémentée en entier dans le module) de l'état complet à tout tick. Usages : tests de non-régression (§11.2), vérification multi-appareils (ENF-05), contrôle d'intégrité des recettes (§7.2).

**Ce que le déterminisme entier élimine par construction :** les écarts flottants entre architectures ARM, les différences d'optimisation du compilateur, les dépendances à la fréquence d'affichage (60/90/120 Hz selon l'appareil) — soit les trois causes classiques de non-reproductibilité sur Android.

---

## 4. Le cœur de simulation (`sim/`)

### 4.1 Modèle de données

```
SimState (RefCounted, pur)
  tick        : int
  agents      : Array[AgentState]     # ordre = identifiant
  grid        : GridState             # cases, éléments, marqueurs de piste
  counters    : Compteurs d'objectifs # sortis, perdus, livrés…
  outcome     : RUNNING | WON | LOST

AgentState
  id          : int
  pos         : Vector2i
  dir         : int (0..3)            # N, E, S, O
  flags       : int (champ de bits)   # PRESENT, PORTEUR, SORTI, PERDU

GridState
  size        : Vector2i
  cells       : PackedInt32Array      # type d'élément par case (§ CDC RG-14)
  pheromone   : PackedInt32Array      # intensité de piste par case (R08/R09)
  cycles      : Array[CycleDef]       # dangers cycliques : période, phase
```

Tout l'état est **sérialisable trivialement** (tableaux d'entiers) — condition des clichés-clés (§5.3) et de l'empreinte (DT-09).

### 4.2 Interface du module

```
SimCore.load_level(level_data: Dictionary) -> SimState        # état initial
SimCore.step(state: SimState, stack: Array[int]) -> SimState  # transition pure
SimCore.hash_state(state: SimState) -> int                    # empreinte
SimCore.explain(state, agent_id, stack) -> Explanation        # diagnostic EF-05
```

`explain` rejoue la cascade de décision d'un agent au dernier tick et retourne, pour chaque emplacement de la pile : appliqué / non applicable (et pourquoi : rien à percevoir, mouvement bloqué…). C'est la fondation directe de l'exigence EF-05 (« toucher un agent explique son mouvement ») et de EF-06 (zones de perception).

### 4.3 Les règles de comportement

> **DT-10.** Chaque règle du CDC (R01-R16) est une classe dérivant d'une interface unique :
> `evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i | ABSTAIN`
> Les **paramètres d'équilibrage** `⚙️` du CDC (portées de perception, seuils de densité, durée d'évaporation des pistes) ne sont **jamais codés en dur** : ils vivent dans `data/rules.json`, ce qui rend l'équilibrage modifiable sans toucher au code et déclenche automatiquement la revalidation du catalogue (EQ-03) via l'empreinte des paramètres incluse dans les rapports (§8).

### 4.4 Pipeline d'un tick

Implémentation directe de RG-05 à RG-09, dans cet ordre strict :

1. Mise à jour des éléments cycliques (phase = `tick mod période`).
2. Décision de chaque agent (id croissant) sur l'état *t* : première règle non-ABSTAIN de la pile.
3. Résolution des conflits de case (DT-07) ; les perdants restent sur place.
4. Application des mouvements → état *t+1*.
5. Effets d'environnement : sorties, dangers actifs, ramassage/dépôt, portes à pression.
6. Évaporation des marqueurs de piste (décrément entier).
7. Évaluation des objectifs → `outcome` (RG-09, y compris l'inatteignabilité mathématique : ex. `perdus > K` pour un objectif de préservation).

### 4.5 Budget de performance

Dimensionnement au pire cas du CDC (50 agents, grille 14×18, 4 règles) :

- Décision d'un agent : ≤ 4 évaluations de règle ; la plus coûteuse (barycentre, R03) parcourt un voisinage borné (≤ ~80 cases). Ordre de grandeur : **≤ 20 000 opérations entières par tick** — négligeable même en GDScript interprété (budget CDC : 2 ms/tick ; marge estimée > ×50).
- Conclusion : **la porte GDExtension (DT-02) ne sera vraisemblablement jamais franchie pour le jeu lui-même** ; elle n'a de pertinence potentielle que pour le validateur (§8.3).

---

## 5. Temps, relecture et remontée du temps (`replay/`)

### 5.1 Recette

> **DT-11.** L'unité de reproduction d'une partie est la **recette** : `(id de niveau, version des données, pile, tick cible)`. Grâce au déterminisme, une recette **est** la partie : la rejouer depuis le tick 0 reconstruit exactement tout état intermédiaire. C'est le fondement commun de la sauvegarde (EF-20), de la remontée du temps (EF-03) et du partage futur de solutions [CDC §17.1].

### 5.2 Remontée du temps (EF-03)

> **DT-12.** Le retour arrière est implémenté par **re-simulation depuis un cliché-clé**, jamais par une pile d'annulations :
> — `replay` conserve un cliché complet de `SimState` tous les **25 ticks** `⚙️` (coût mémoire : quelques Ko par cliché × ≤ 12 clichés pour un niveau de 300 ticks — négligeable).
> — Atteindre le tick *t* = restaurer le cliché ≤ *t* le plus proche, puis re-simuler (≤ 24 ticks, soit < 1 ms).
> Le rembobinage continu (appui maintenu) décrémente le tick affiché à cadence fixe par ce mécanisme.

### 5.3 Événements

`sim` produit à chaque tick une liste d'événements typés et datés (SORTIE, PERTE, DÉPÔT, PORTE_OUVERTE…). `view` les traduit en effets, `audio` en notes (§10). En remontée du temps, les événements re-simulés sont marqués « déjà vus » pour ne pas rejouer les sons.

---

## 6. Rendu (`view/`)

### 6.1 Technique de rendu de la nuée

> **DT-13.** Les agents et leurs traînées sont rendus par **MultiMesh 2D** (un seul appel de dessin pour toute la nuée), les cases par TileMapLayer, les halos (but, danger, pistes) par des shaders `canvas_item` sur des primitives. Aucune texture importée pour le jeu lui-même : tout le visuel est procédural, conformément à l'intention DA du CDC — et au budget de poids (ENF-11).

### 6.2 Interpolation

`view` affiche une position interpolée linéairement entre l'état du tick affiché et le suivant, au prorata du temps écoulé dans le tick courant. Fluidité à 60 i/s quel que soit le rythme de simulation (ENF-10), sans contact avec `sim` (DT-06).

### 6.3 Lisibilité et accessibilité (ENF-20 à ENF-22, DA-02/03)

- Hiérarchie visuelle par **calques** dans l'ordre : décor < pistes < dangers < nuée < buts < surimpressions de diagnostic.
- Le danger est porté par couleur **et** hachures (shader de motif), les pistes par couleur **et** intensité animée : aucune information mono-canal couleur.
- Modes contraste élevé et animations réduites : deux **thèmes de paramètres de shaders** commutables à chaud — pas deux jeux d'assets.
- L'état (marche/pause/succès/échec) est signalé par un liseré d'écran distinct en forme et en rythme (DA-03).

### 6.4 Sobriété (ENF-12)

En pause : arrêt du traitement par image (`set_process(false)` généralisé), rendu à la demande uniquement (mode bas rafraîchissement de Godot), shaders animés gelés. Cible mesurable : consommation en pause ≈ consommation de l'écran d'accueil du téléphone.

---

## 7. Persistance (`save/`)

### 7.1 Contenu et emplacement

| Fichier (`user://`) | Contenu | Écrit quand |
|---|---|---|
| `session.json` | Recette de la partie en cours + état d'interface (pause, vitesse, tick affiché) | À chaque modification de pile, pause, changement de vitesse, et à `NOTIFICATION_APPLICATION_PAUSED` |
| `progress.json` | Niveaux résolus, défis accomplis, meilleures performances, règles débloquées | À chaque bilan de niveau |
| `settings.json` | Accessibilité, audio, haptique, langue | À chaque changement |
| `stats.json` | Statistiques locales (essais, temps) — jamais transmises (ENF-30/31) | Fin de session |

### 7.2 Garanties

> **DT-14. Écriture atomique systématique** : écriture dans un fichier temporaire, `flush`, puis renommage — un arrêt brutal en pleine écriture laisse toujours la version précédente intacte. Chaque fichier porte un `schema_version` ; le chargeur applique des migrations ascendantes explicites. Toute recette embarque l'empreinte (DT-09) de l'état qu'elle prétend reproduire : au chargement, l'état re-simulé est vérifié contre l'empreinte — en cas d'écart (corruption, données modifiées), repli propre sur le début du niveau, jamais de plantage. *(EF-20/21, ENF-04.)*

### 7.3 Reprise en moins de 3 secondes (EF-21)

Chaîne de reprise mesurée : lancement Godot (< 1,5 s sur l'appareil de référence, projet léger) → lecture de `session.json` (< 10 ms) → re-simulation jusqu'au tick cible (≤ 300 ticks, < 50 ms) → affichage en pause. Budget tenu avec marge ; le démarrage à froid du moteur est le poste dominant, d'où : pas d'écran d'intro, chargement des thèmes différé, aucune police ni ressource lourde au boot (EF-21, ENF-13).

---

## 8. Le validateur (`tools/validate/`)

### 8.1 Décision structurante : une seule vérité

> **DT-15.** Le validateur exécute **le même code de simulation que le jeu** — le module `sim/` lancé par Godot en mode `--headless` — et non une réimplémentation dans un autre langage. Motif : une double implémentation (envisagée un temps en Python) crée un risque de **divergence silencieuse** entre ce que l'outil mesure et ce que le joueur vit — précisément le défaut que le projet ne peut pas se permettre (CDC §12.1). La lenteur relative de GDScript s'achète ; une divergence ne se rembourse pas.

### 8.2 Fonctionnement

Entrée : un fichier de niveau + `rules.json`. Le validateur énumère l'espace des piles (arrangements de 4 règles au plus parmi les règles autorisées du niveau, emplacements vides admis), simule chacune jusqu'à `outcome` ou à la limite de ticks, et produit un rapport JSON + CSV par niveau :

| Champ | Exigence CDC couverte |
|---|---|
| Piles gagnantes, regroupées par **classes structurelles** (piles équivalentes si elles produisent la même empreinte finale) | QN-01 |
| `min_ticks` et pile étalon d'efficience | QN-04, calibrage du défi Efficience |
| Échecs proches (< 10 % de l'objectif) | QN-03 |
| Empreinte des paramètres `rules.json` utilisés | EQ-03 (détection de rapport périmé) |
| Croisement chapitre : piles gagnant tous les niveaux | QN-02 (stratégie dominante) |
| Couverture des règles dans les solutions | EQ-04 (règle morte) |

### 8.3 Performance et stratégie d'exécution

Dimensionnement au pire (12 règles autorisées, 4 emplacements : 11 880 piles ; + piles partielles : ~13 400) : ~13 400 simulations × ≤ 300 ticks. En GDScript, estimation prudente : 15-40 minutes par niveau sur un poste de développement.

> **DT-16.** Stratégie en trois étages, engagés dans l'ordre et seulement si nécessaire :
> 1. **Parallélisation par processus** : N instances headless se partagent l'espace des piles (script d'orchestration shell/Python côté poste — hors périmètre du produit). Sur 8 cœurs : ~2-5 min/niveau. Suffisant pour une validation **nocturne du catalogue complet** (70 niveaux) — c'est le mode de fonctionnement nominal.
> 2. **Coupes sûres** : abandon d'une simulation dès `outcome` ≠ RUNNING ; détection de cycle par empreinte (si l'empreinte d'état se répète, la simulation boucle → échec anticipé).
> 3. **Portage GDExtension C++ du module `sim/`** (la porte DT-02), utilisé alors par le jeu **et** le validateur — l'unicité de la vérité (DT-15) est préservée. À n'engager que si le cycle nocturne devient réellement contraignant.

### 8.4 Intégration au flux de production

- Un niveau sans rapport **conforme et à jour** (empreintes concordantes) ne peut pas être marqué « livrable » dans `data/levels/` — verrou par la CI (§11.3), pas par la discipline. *(EQ-02.)*
- Le rapport agrégé du catalogue est un livrable des jalons J3/J4 [CDC §15].

---

## 9. Interface (`ui/`)

### 9.1 Structure d'écrans

Machine à états d'interface à cinq écrans : Accueil → Carte des chapitres → Jeu → Bilan → Réglages (+ Encyclopédie des règles accessible de partout). Aucun empilement de fenêtres modales pendant le jeu (P3).

### 9.2 Écran de jeu

- **Disposition** conforme à la maquette du CDC : objectif en bandeau une ligne (RG-17), grille au centre, **pile de 4 emplacements et transport dans la moitié basse** (ENF-01), ancrés via l'API de zone sûre d'Android (encoches, barres gestuelles).
- **Cibles tactiles** ≥ 48 dp imposées par le thème Godot (taille minimale des contrôles), vérifiées par un test d'interface automatisé qui inspecte l'arbre de contrôles (ENF-01, ENF-25).
- **Glisser-déposer** de la pile via le mécanisme natif de Godot (`_get_drag_data` / `_drop_data`) avec aimantation, retour haptique bref (ENF-24) et équivalent sans glissement : appui simple → sélection → appui sur l'emplacement cible (ENF-25).
- **Tiroir de bibliothèque** : panneau coulissant depuis le bas, jamais un écran plein (P3).
- **Diagnostic** : en pause, appui sur un agent → appel `SimCore.explain` → surimpression de la cascade de décision (EF-05) et, en option, des zones de perception (EF-06).

### 9.3 Textes et localisation

Tous les textes passent par le système de traduction de Godot (fichiers CSV/PO, clés stables). Volume structurellement minimal (ENF-41). Français et anglais livrés ensemble ; la taille de police système est respectée via l'échelle de contenu de Godot (ENF-23).

### 9.4 Aide graduée (EF-30/31)

L'indice structurel (« une règle présente dans au moins une solution ») est **extrait du rapport du validateur** embarqué en version réduite dans `data/levels/` : le jeu ne calcule rien, il lit une règle au hasard *pré-tirée à la génération du rapport* (le tirage à l'exécution violerait DT-05). Aucun marquage du niveau après usage.

---

## 10. Audio (`audio/`)

> **DT-17.** Moteur sonore par **échantillons courts synthétisés hors ligne** (générés une fois par script, embarqués en OGG légers) plutôt que par synthèse temps réel : plus simple, déterministe à l'oreille, et très en deçà du budget de 3 Mo. Composition :
> — une nappe de fond dont le volume/filtre suit la densité moyenne de la nuée (DS-01) ;
> — une note de gamme pentatonique par événement SORTIE, l'octave montant avec le pourcentage d'objectif atteint (DS-01) ;
> — un son mat discret par PERTE — jamais d'alarme (DS-03).
> Silence total en pause (DS-02). Bus audio unique coupé par le réglage « son » ; **aucune information n'est portée que par l'audio** (ENF-02) — garanti par revue : tout événement sonore a son homologue visuel dans `view`.

---

## 11. Qualité, tests et intégration continue

### 11.1 Gestion de sources

> **DT-18.** Dépôt **Git** privé hébergé sur GitHub (offre gratuite). Branche `main` protégée : on n'y fusionne que si la CI passe. Conventions : une branche par lot de travail, messages normalisés, étiquettes de version aux jalons.

### 11.2 Pyramide de tests

| Niveau | Contenu | Outil |
|---|---|---|
| Tests unitaires `sim/` | Chaque règle : cas nominaux, bords de grille, conflits, abstention | GUT (framework de test GDScript) en headless |
| **Tests d'or (non-régression du déterminisme)** | Un corpus de ~30 recettes de référence ; l'empreinte à ticks fixes (50/150/300) est comparée aux valeurs archivées. Toute divergence non intentionnelle bloque la fusion (DT-09) | GUT + fichiers d'or versionnés |
| Tests d'architecture | Interdits de dépendance (DT-03) et interdits lexicaux (DT-04 : flottants/aléatoire dans `sim/`) | Script d'analyse statique en CI |
| Tests de schéma | Migration des sauvegardes, recette corrompue → repli propre (DT-14) | GUT |
| Validation de contenu | Rapports QN-01→05 à jour pour tout niveau « livrable » (EQ-02) | Validateur §8 |
| Tests sur appareil *(v1.1, A6)* | Déterminisme réel vérifié sur **deux architectures CPU distinctes** — **arm64** (Galaxy S23 Ultra) et **x86_64** (AVD API 36 + CI) — complétées par la **collecte manuelle d'empreintes** (DT-22) auprès du parc de testeurs pendant le test fermé ; reprise après arrêt forcé ; performance. C'est un test plus sévère que deux téléphones ARM : deux appareils physiques peuvent partager le même jeu d'instructions et masquer un écart d'arrondi ou d'ordonnancement propre au compilateur, alors qu'arm64 et x86_64 divergent structurellement | Manuel scripté, à chaque jalon (ENF-05, §13.5 CDC) |

### 11.3 Intégration continue

> **DT-19.** **GitHub Actions** (gratuit à ce volume) : à chaque poussée — export headless Linux de Godot en cache, exécution des tests unitaires, tests d'or, tests d'architecture, tests de schéma ; chaque nuit — validation du catalogue complet (§8.3) et publication du rapport agrégé en artefact. La CI ne signe ni ne publie rien (aucun secret de production en ligne avant J5).

### 11.4 Éditeur de niveaux interne

> **DT-20.** L'éditeur de niveaux est **l'éditeur Godot lui-même**, outillé : scène `@tool` de peinture de grille (éléments du vocabulaire RG-14), panneau d'objectifs, bouton « Valider ce niveau » qui lance le validateur sur le fichier courant et affiche le verdict QN dans l'éditeur. Aucune application séparée à développer. *(Risque R6 du CDC.)*

---

## 12. Méthode de travail avec l'assistance IA

Règles d'usage, tirées des risques identifiés en amont du projet :

1. **Tout prompt de code commence par le contexte figé** : « Godot 4.7, GDScript typé statique — pas de syntaxe Godot 3 » + les invariants de la zone touchée (pour `sim/` : « entiers uniquement, pas d'aléatoire, itération par id croissant, décisions sur cliché immuable »).
2. **La CI est le juge, pas l'assistant** : aucun code généré n'atteint `main` sans passer tests unitaires, tests d'or et tests d'architecture. Les interdits lexicaux (DT-04) attrapent mécaniquement les fautes typiques des assistants (un `randf()` ou un `float` glissé dans une règle).
3. **Zones à relecture renforcée** (relecture humaine ligne à ligne obligatoire) : `sim/`, `save/`, tout ce qui touche au cycle de vie Android. Zones à relecture légère : `view/`, `ui/`, où un défaut est visible et sans conséquence sur l'intégrité.
4. **L'IA ne conçoit pas les niveaux** : elle peut proposer des candidats, mais seul le verdict du validateur (§8) et le jugement du concepteur les admettent.
5. Les textes du jeu (libellés, énoncés) sont écrits ou validés humainement — volume minimal, enjeu de ton maximal.

---

## 13. Plateforme Android et publication

### 13.1 Cibles

| Paramètre | Valeur | Justification |
|---|---|---|
| API cible | **36 (Android 16)** | Obligation Google Play au 31 août 2026 [CDC §14.4] |
| API minimale | **33 (Android 13)** *(v1.1, était 26)* | Décision assumée de ne pas supporter d'antérieur : l'appareil de développement est lui-même sous Android 13. Bénéfice : suppression d'une large surface de test et des branches de compatibilité héritées. Coût : perte d'une part du parc, **à quantifier avant J-4** via le tableau de distribution des versions d'Android Studio |
| Architectures | arm64-v8a (+ armeabi-v7a si le poids le permet) | arm64 requis par Play ; v7a optionnel, à arbitrer contre ENF-11 |
| Format | **AAB** (Android App Bundle) | Exigé par Google Play |
| Orientation | Portrait verrouillé | ENF-01 |
| Permissions | **Aucune** | ENF-30 ; l'absence de permission est vérifiée dans le manifeste en CI |
| Identifiant d'application *(v1.1)* | **`com.volensgame.volens`** | Irréversible après le premier envoi sur Play ; figé (remplace le gabarit `com.<éditeur>.volens` de §0.2) |
| Nom de développeur Play *(v1.1)* | **Draille** | Nom sous lequel l'application sera publiée sur la fiche Google Play |

> **Avertissement de couverture *(v1.1, A7)*.** L'appareil de référence (Galaxy S23 Ultra) tourne sous **Android 13** : viser l'API 36 n'y déclenche **aucun** des changements de comportement propres aux API 35/36 (bord à bord obligatoire, retour prédictif, nouvelles règles de notification). L'AVD API 36 n'est donc pas un complément de test mais **le seul moyen** d'observer ces comportements tant que l'appareil physique n'est pas mis à jour.

### 13.1 bis Obligation de test fermé *(v1.1, nouveau — A4)*

Les comptes développeur Google Play personnels créés après le **13 novembre 2023** sont soumis à une obligation de test préalable à l'accès production : une piste de **test fermé** (*closed testing*, jamais *internal testing*) avec **au moins 12 testeurs inscrits pendant 14 jours consécutifs**, revue de la demande annoncée à 7 jours ou moins par Google. Conséquence technique directe : les pistes Production et Préinscription de la Play Console **restent désactivées** jusqu'à l'issue de cette période. Voir DT-22 (§13.3 bis) pour le dispositif qui accompagne cette obligation sans dépendre d'un second appareil physique.

### 13.2 Cycle de vie

`NOTIFICATION_APPLICATION_PAUSED` → sauvegarde de session (DT-14) + coupure audio + gel du rendu. `NOTIFICATION_APPLICATION_RESUMED` → rechargement de session si le processus a été tué entre-temps. Le scénario « fermeture brutale » (EF-20) est couvert par le fait que la sauvegarde a lieu **à chaque action significative**, pas seulement à la mise en pause.

### 13.3 Signature et distribution — calendrier des paiements

> **DT-21 *(v1.1, réécrite — A3, caduque en l'état).*** Le compte développeur Google Play est **déjà créé et vérifié** (25 $ réglés) ; l'application, elle, n'est pas encore créée dans la console. Conséquence : le risque T8 (délai de vérification du compte, §15) est **éteint** — il n'y a plus de délai d'identité à absorber avant publication.
> — **Phases J0→J4 : coût zéro** pour tout le reste. Développement, tests sur appareils physiques par installation directe (APK signé en debug via USB), distribution aux testeurs par APK signé d'une **clé de release auto-générée et archivée de façon sécurisée dès J1** (la clé d'upload définitive, elle, sera gérée par Play App Signing).
> — **Reste à faire, sans paiement supplémentaire :** créer l'application dans la Play Console (avant l'ouverture du test fermé, §13.1 bis) et lancer la piste de test fermé.
> — Achat intégré (déblocage EF-41) : intégration de la facturation Google Play **en J4/J5 seulement**, derrière une interface interne `platform/purchase` neutralisée jusque-là (le chapitre 1 gratuit ne l'exige pas).
> — Dépenses non engagées et non nécessaires : domaine web (optionnel, à décider avec le devlog), compte Apple (hors périmètre v1.0, cf. CDC §2.2).

### 13.3 bis Auto-vérification d'empreinte *(v1.1, nouveau — A5)*

> **DT-22.** Les builds de test embarquent un **écran caché** qui rejoue les recettes d'or (§11.2) et affiche un **code court** dérivé des empreintes obtenues (DT-09). Le testeur **recopie manuellement** ce code dans le canal de retour convenu (formulaire, message) ; il n'existe **aucune transmission automatique**, condition nécessaire au respect d'ENF-30 (aucune collecte). C'est le dispositif qui remplace l'achat d'un second appareil physique pour la vérification multi-architecture (§11.2, A6) : le parc réel des testeurs, recruté pour le test fermé (§13.1 bis), joue ce rôle sans coût et sans compromettre le positionnement vie privée du produit.

### 13.4 Conformité (rappel d'implémentation)

Data Safety : déclaration « aucune donnée collectée » — rendue vraie par construction (aucune permission, aucun SDK tiers, DT-18/19 sans télémétrie). Déclaration de contenu IA de Google Play : à remplir selon l'état réel des contenus livrés à J5. Politique de confidentialité une page : hébergement gratuit (GitHub Pages) — zéro coût.

---

## 14. Matrice de traçabilité CDC → solutions techniques

Couverture exhaustive ; « — » signale un point de pure conduite de projet sans objet technique.

| Exigence CDC | Solution | Réf. |
|---|---|---|
| RG-01/02 (grille, ticks) | Modèle `SimState`/`GridState`, pipeline de tick | §4.1, §4.4 |
| RG-03 (déterminisme) | Arithmétique entière, zéro aléatoire, ordre total, cliché | DT-04→08 |
| RG-04 (agents anonymes) | `AgentState` minimal, aucune stat | §4.1 |
| RG-05 (première règle applicable) | Cascade `evaluate`/ABSTAIN | DT-10, §4.4 |
| RG-06 (départage) | Id le plus faible, ordre N>E>S>O | DT-07 |
| RG-07 (décision sur état t) | Double tampon | DT-08 |
| RG-08 (dangers cycliques fixes) | `CycleDef` (période, phase), phase = tick mod période | §4.1, §4.4 |
| RG-09 (fin de niveau, échec-constat) | `outcome` + détection d'inatteignabilité | §4.4 |
| RG-10 (pause, vitesses, remontée, essais illimités) | `replay` : cadences, clichés-clés, re-simulation | DT-12, §5 |
| RG-11→13 (bibliothèque, 6 mots, admission) | Classes de règles, paramètres en données ; admission = processus de conception outillé par le validateur (conflits mesurables) | DT-10, §8 |
| RG-14→17 (niveaux, objectifs, énoncé visible) | Format de niveau en données, HUD bandeau, compteurs en continu | §4.1, §9.2 |
| RG-18/19 (défis optionnels) | `meta/` + étalon d'efficience issu du validateur | §8.2 |
| RG-20 (déblocage partiel) | `meta/` : seuil paramétré en données | §2.2 |
| EF-01→04 (pile, vitesses, remontée, réinit.) | UI glisser-déposer + `replay` | §9.2, §5 |
| EF-05/06 (diagnostic, perception) | `SimCore.explain` + surimpressions | §4.2, §9.2 |
| EF-07 (bilan) | Écran Bilan alimenté par compteurs + rapport réduit | §9.1 |
| EF-10→13 (navigation, rejeu, encyclopédie, piles archivées) | Machine à états d'écrans ; démonstrations = recettes rejouées en vignette (réutilisation directe de DT-11) | §9.1, DT-11 |
| EF-20→22 (reprise intégrale < 3 s) | Recette + écriture atomique + chaîne de reprise budgétée | DT-11, DT-14, §7.3 |
| EF-23 (zéro notification) | Aucune permission, aucun canal de notification créé — vérifié en CI sur le manifeste | §13.1 |
| EF-24 (zéro temps réel) | DT-05/06 ; aucun code ne lit la date | §3 |
| EF-30/31 (aide graduée gratuite) | Indice pré-tiré issu du rapport embarqué | §9.4 |
| EF-40/41 (premier contact, offre unique) | Boot minimal (ENF-13) ; `platform/purchase` neutralisé avant J4 | §7.3, DT-21 |
| ENF-01 (une main, portrait, 48 dp) | Portrait verrouillé, zone sûre, thème contraignant, test d'arbre UI | §9.2, §13.1 |
| ENF-02 (son coupé) | Doublage visuel systématique, revue croisée `audio`/`view` | DT-17 |
| ENF-03 (hors ligne) | Aucune dépendance réseau ; achat seul en ligne (J5) | §13 |
| ENF-04 (interruptible) | Sauvegarde à chaque action + cycle de vie | §7.1, §13.2 |
| ENF-05 (déterminisme constaté) | Tests d'or + empreintes croisées multi-appareils | §11.2 |
| ENF-06 (zéro mécanique prédatrice) | Absence par construction ; aucun SDK tiers | §13.4 |
| ENF-10→14 (60 i/s, <60 Mo, sobriété, boot <3 s) | MultiMesh, procédural, pause gelée, boot minimal, budget §4.5 | §6, §7.3 |
| ENF-20→25 (accessibilité) | Double canal visuel, thèmes commutables, échelle système, haptique désactivable, équivalents sans gestes complexes | §6.3, §9.2 |
| ENF-30→33 (zéro collecte) | Aucune permission/SDK/télémétrie ; export/effacement local | §7.1, §13 |
| ENF-40/41 (FR/EN) | Système de traduction Godot, clés stables | §9.3 |
| QN-01→05, EQ-01→05 (qualité mesurée) | Validateur même-code, rapports, verrou CI, couverture des règles | §8, DT-15/16 |
| DA-01→04, DS-01→03 (directions artistique/sonore) | Rendu procédural par shaders ; moteur sonore événementiel | §6, DT-17 |
| CDC §13 (campagnes de test) | Builds de test APK hors store (coût zéro), scripts de scénarios | DT-21, §11.2 |
| CDC §14.4 (API 36, Data Safety, contenu IA) | Cibles §13.1, conformité §13.4 | §13 |
| CDC §15 (jalons) | Alignement des paiements et de la CI sur J1→J5 | DT-19, DT-21 |
| CDC §17.1 (partage de solutions, futur) | Déjà permis par la recette (DT-11) — aucun coût anticipé | §5.1 |

---

## 15. Risques techniques et parades

| # | Risque | Prob. | Parade |
|---|---|---|---|
| T1 | Divergence jeu/validateur | — | **Éliminé par construction** (DT-15 : même code) |
| T2 | Validateur trop lent en GDScript | Moyenne | Étages DT-16 ; le portage C++ partagé reste disponible sans refonte |
| T3 | Non-déterminisme introduit par inadvertance | Moyenne | Interdits lexicaux + tests d'or à chaque fusion (§11.2) — détection au commit fautif, pas en production |
| T4 | Assistants IA produisant du Godot 3 ou du code flottant | Élevée | Prompt-contexte figé (§12) + CI juge de paix |
| T5 | Démarrage à froid > 3 s sur l'appareil de référence | Faible | Boot minimal spécifié (§7.3) ; mesure dès J1, pas à J4 |
| T6 | Poids AAB > 60 Mo | Faible | Visuel/audio procéduraux ; arbitrage v7a (§13.1) en dernier recours |
| T7 | Godot 4.7.x : régression sur correctif | Faible | Version épinglée, montée de version testée sur branche dédiée |
| T8 | ~~Délai de vérification du compte Google Play~~ | — | **Éteint *(v1.1, A3)*** : compte créé et vérifié avant J0. Reste à créer : l'application dans la console (DT-21) |

---

## 16. Environnement de développement (récapitulatif, coût total : 0 €)

| Élément | Choix | Coût |
|---|---|---|
| Moteur + éditeur | Godot 4.7.x | 0 € |
| IDE d'appoint / assistance IA | Éditeur au choix + assistant existant | 0 € (abonnements déjà détenus) |
| Chaîne Android | OpenJDK 17 + Android SDK command-line tools | 0 € |
| Hébergement code + CI | GitHub privé + Actions | 0 € |
| Tests | GUT, scripts headless | 0 € |
| Appareil de référence | Android milieu de gamme ~2022 déjà possédé (à défaut : occasion, seule dépense éventuelle à arbitrer) | 0 € |
| Distribution testeurs | APK direct (USB / lien privé) | 0 € |
| Page de confidentialité + devlog | GitHub Pages | 0 € |
| Compte développeur Google Play *(v1.1)* | **Déjà réglé** — création et vérification effectuées avant J0 (DT-21) | **25 $ (déjà dépensés)** |

---

## Historique des révisions *(v1.1)*

| Version | Date | Changements | Motif |
|---|---|---|---|
| 1.0 | 3 août 2026 | Version initiale | Réponse au CDC v2.0 |
| 1.1 | 4 août 2026 | Arborescence à deux étages `core/`·`game/` et trois règles de dépendance testables (§2.2, remplace l'invariant DT-03) ; `minSdk` 26→33, identifiant `com.volensgame.volens` et nom Play « Draille » figés (§13.1) ; DT-21 réécrite (compte Google Play déjà créé et vérifié, risque T8 éteint) ; nouvelle obligation de test fermé documentée (§13.1 bis) ; nouveau DT-22, écran caché d'auto-vérification d'empreinte (§13.3 bis) ; vérification du déterminisme reformulée en deux architectures CPU (arm64/x86_64) plutôt qu'en nombre d'appareils physiques (§11.2, A6) ; avertissement sur l'écart de couverture Android 13/API 36 (§13.1, A7) | Série de décisions de cadrage prises entre J0 et le début de S2 ; les documents étaient périmés sur ces points |

*Fin du document — DCT v1.1. Toute décision DT ne peut être révisée qu'avec mise à jour de la matrice §14 ; les décisions DT-03, DT-04 et DT-15 sont structurantes et leur révision équivaut à une refonte.*
