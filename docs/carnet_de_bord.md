# Carnet de bord — Volens

Fichier unique de suivi (T-007) : décisions prises, écarts au plan, mesures.
Mis à jour à chaque session de travail significative. Ce qui est écrit ici
fait foi sur l'avancement réel, en complément du plan de production.

---

## État d'avancement au 4 août 2026 (fin de séance S2)

### Fait — Étape 0 : mise à jour documentaire (fusionnée dans `main`)

- CDC → **v2.1**, DCT → **v1.1**, Plan → **v1.1**, chacun avec historique des
  révisions. Amendements A1-A7, B1-B4, C1-C5 appliqués.
- Contradiction relevée et tranchée (avec accord explicite) : le CDC v2.0
  spécifiait encore une v1.0 Android+iOS ; aligné sur le DCT (Android
  uniquement), iOS déplacé en évolution §17.

### Fait — Lot S2 : socle de simulation (branche `feat/sim-core`)

| Tâche | Contenu livré | Tests |
|---|---|---|
| T-005 | Arborescence `core/`·`game/`·`data/`·`tools/`·`tests/` (DCT §2.2 v1.1), `project.godot` (gl_compatibility, portrait, canvas_items/expand, 1080×2400), `.gitignore`, `README.md`, GUT 9.6.1 dans `addons/` | — |
| T-010 | `SimState`, `AgentState` (drapeaux bits), `GridState` (9 types de case, `PackedInt32Array`), `CycleDef`, `Counters`, `RuleParams`, copie profonde `clone()` partout | 10 |
| T-011 | `SimCore.step()` pur : les 7 étapes du DCT §4.4, double tampon, conflits de case (plus petit id + défense de case occupée), effets Sortie/Danger, évaporation, issue LOST sur limite de ticks | 16 |
| T-012 | Interface `Rule.evaluate() -> Vector2i \| ABSTAIN` ; R01 vers-la-lumière, R02 fuir-le-rouge, R03 rester-groupé (barycentre en sommes entières, zéro division) ; cascade « première règle non-ABSTAIN » ; paramètres dans `data/rules.json` | 27 |
| T-013 | `StateHash` FNV-1a 64 bits entier pur, ordre de parcours documenté, `to_hex()`, vecteur de contrôle FNV public validé | 8 |
| §1.6 | `tools/run_sim.gd` (headless, `--level --ticks --stack --verbose`), `data/levels/test_smoke.json` | — |

**Total : 61 tests unitaires, 121 assertions, tous verts.**

**Critère de fin S2 constaté** : deux exécutions de
`run_sim.gd --level=test_smoke --ticks=200` → empreinte identique
`c8a7cc2c73394949`, sans erreur ni avertissement. Déterminisme re-vérifié
sur trois piles distinctes à 300 ticks (trois empreintes distinctes entre
piles, chacune stable entre exécutions).

### Décisions prises en cours de route (à connaître pour la suite)

1. **Règles conscientes des murs.** Une direction bloquée (mur/bordure) est
   ignorée par la règle ; toutes bloquées → ABSTAIN et la cascade continue.
   Déduit du DCT §4.2 (`explain` : « non applicable — mouvement bloqué »).
   Sans cela, un agent fuyant dans un couloir resterait collé au danger.
2. **R02 fuit aussi les dangers cycliques inactifs** (visibles et prévisibles,
   RG-08). Le CDC ne tranchait pas ; documenté dans la règle.
3. **Conflit de case précisé** : un agent qui ne bouge pas défend sa case quel
   que soit son id (sinon violation de RG-01) ; « plus petit id gagne » ne
   s'applique qu'entre agents visant la même case libre. Résolution itérative,
   convergence bornée, échanges directs autorisés.
4. **`Directions.delta()` renommé `offset()`** : « delta » est un interdit
   lexical de `core/` (invariant n°7) et aurait déclenché le futur test
   d'architecture T-022.
5. **`ABSTAIN = Vector2i(-2,-2)`** : sentinelle hors espace des sorties
   légitimes ; `Vector2i.ZERO` reste réservé au choix explicite d'immobilité
   (future R07 « Attendre »).
6. **L'empreinte exclut `rule_params`** : configuration, pas état simulé —
   son empreinte propre relèvera des rapports du validateur (EQ-03).
7. **Résolution de base 1080×2400 (9:20)** dans `project.godot` : proche des
   flagships récents, redimensionnement entier vers les densités courantes.

### Écarts au plan

- T-001, T-002 : clos avant S2 (voir Plan v1.1 §5).
- T-007 (carnet de bord) : ouvert avec ce fichier — en retard d'une semaine
  sur le plan (prévu S1), sans conséquence.
- T-003 (appareil de référence), T-004 (chaîne complète : Android SDK absent,
  prévu S9), T-006 (clé de signature), T-008 (recrutement testeurs) :
  **toujours ouverts**, à la charge du porteur — T-008 est le plus urgent,
  il bloque J-1.

---

## Fait — Lot S3 : verrouillage du déterminisme et validateur (4 août 2026, session autonome)

| ID | Contenu livré | Tests |
|---|---|---|
| T-020 | Déjà couvert en S2 (tests dans le même commit que les règles) | — |
| T-022 | `tests/arch/test_architecture.gd` : analyse statique avec retrait des commentaires — interdits lexicaux de `core/` (aléatoire, delta/horloge/OS, float/sqrt/sin/cos/pow, littéraux flottants, preload/load/res://, FileAccess/JSON, extends Node), `core/sim/` sans référence Replay*, `tools/` sans game/ ni addons/ ; auto-test du scanner | 5 |
| T-023 | `.github/workflows/ci.yml` : Godot 4.7.1 en cache, import, GUT sur `res://tests` avec sous-répertoires, double exécution de fumée avec comparaison d'empreintes | — |
| — | **Dispositif exercé réellement** : `randf()` injecté dans `agent_state.gd` → détecté à la ligne exacte par le test d'architecture → retiré, retour au vert. Définition de fini S3 satisfaite — premier passage CI en ligne **constaté vert le 5 août 2026**. **S3 clos.** | — |
| RG-15 | **Objectifs de niveau** (prérequis de T-024) : extraction/preservation/celerity/interdiction/collect ; accomplissements vs contraintes ; inatteignabilité mathématique (RG-09) ; arithmétique 100 % entière ; exclus de l'empreinte (configuration, comme rule_params) — empreinte de fumée inchangée ; `dynamics_hash` (sans tick) pour la détection de cycle | 17 |
| T-021 | Corpus de **10 recettes d'or** (`tests/golden/golden.json`), empreintes à t=50/150/300 ; 2 fixtures techniques (couloir cyclique, champ 8x8) ; `GoldenRunner` partagé entre test GUT et `tools/check_golden.gd` ; `--write` réservé aux gestes humains (création initiale faite ce jour, c'est le geste fondateur de T-021) | 1 (×30 assertions) |
| T-024 | **Validateur v1** : `StackEnumerator` (arrangements distincts 0-4, auto-contrôle P(12,·)=13 345), `ValidateLib` (même SimCore que le jeu — DT-15 ; coupes DT-16 : arrêt sur outcome + boucle détectée par (dynamics_hash, tick mod ppcm)), classes structurelles par empreinte finale, étalon min_ticks (QN-04), verdict QN-01 ; CLI `tools/validate/run.gd` → CSV + JSON dans `reports/validate/` (gitignoré) | 9 |

**Total après S3 : 92 tests, 268 assertions, tous verts.**

### Fait — pris d'avance sur S4 (pur, sans rendu) : T-033

`core/replay/replay_session.gd` [DT-11, DT-12] : clichés-clés tous les
25 ticks (⚙️ configurable), `seek(t)` par restauration du cliché ≤ t puis
re-simulation, `reset()` (EF-04), pile figée à la création (RG-10), copies
défensives. 11 tests — le contrat central est vérifié à l'empreinte près :
remonter le temps est indiscernable d'une avance directe. Aucun rendu,
aucune interface : la partie visuelle de S4 reste entièrement à faire.
**Total : 103 tests, 285 assertions, tous verts.**

Décisions supplémentaires (S3) :

8. **Sémantique des objectifs** — deux familles : accomplissements
   (extraction, collect — le niveau est gagné quand tous sont satisfaits) et
   contraintes (préservation, célérité, interdiction — violation
   irrémédiable = défaite immédiate). Ordre d'évaluation fixe : contraintes >
   inatteignabilité > victoire > limite de ticks. La contrainte prime au
   tick d'égalité. Un niveau sans accomplissement n'est jamais gagné.
9. **Objectifs exclus de l'empreinte** (configuration, même principe que
   rule_params) — c'est ce qui a permis d'ajouter RG-15 sans casser les
   empreintes S2.
10. **`collect` évalué mais inatteignable** tant que R11/R12 (chapitre 4)
    n'existent pas — documenté dans `ObjectiveDef`.
11. **Fixtures d'or ≠ niveaux jouables** : les deux fixtures d'or sont
    insolubles en tant que niveaux (verdict validateur « insoluble », attendu),
    elles archivent des dynamiques, pas du game design. L'IA ne conçoit pas
    les niveaux (DCT §12.4) : les 5 niveaux du chapitre 1 (T-040) relèvent
    du concepteur.

---

## Fait — Revue croisée des décisions S2/S3 (5 août 2026, branche `fix/semantique-s3`)

Relecture par le concepteur des 14 décisions S2/S3 : 7 validées, 4
modifiées, 3 précisées ou vérifiées. Chaque arbitrage ci-dessous fait foi,
y compris ceux qui renversent une décision antérieure — le raisonnement
doit rester relisible dans six mois.

### Décisions 12-15 — les renversements sémantiques du lot

12. **R02 : option C, évaluation à l'instant d'arrivée** (renverse la
    décision n°2). Un danger est menaçant s'il sera actif à t+1 ; un
    dormant qui le restera n'exerce aucune répulsion. Pourquoi : l'option A
    (fuir toute phase, ma décision initiale) faisait du danger cyclique un
    mur animé et neutralisait la famille des puzzles temporels (RG-14) ;
    l'option B (ne fuir que l'actif) produisait des morts non déductibles
    de la pile (P4). Cas limite SPÉCIFIÉ, pas émergent : agent sur case
    létale à t+1 → évacuation vers la première adjacente sûre, départage
    N>E>S>O ; jamais un pas vers une case létale à l'arrivée. La létalité
    effective reste l'affaire exclusive de l'étape 5 : un agent sans R02
    fonce et meurt (archétype CDC §7.3).
13. **Célérité : échéance, pas événement** (amende la décision n°8, dont la
    partition accomplissements/contraintes est confirmée). Préservation et
    interdiction sont des ÉVÉNEMENTS — violation irrémédiable, prime sur
    tout, y compris au tick d'égalité. La célérité est une ÉCHÉANCE
    (tick <= T) évaluée APRÈS la victoire : gagner au tick exact de la
    borne est GAGNÉ (« sur le fil », ENF-04 non punitif). Ordre d'issue
    complet et fixe : contraintes-événement > victoire > échéance de
    célérité > inatteignabilité (RG-09) > limite de ticks.
    L'inatteignabilité de la célérité EST son échéance, placée après la
    victoire pour ne pas recréer le bug un cran plus bas.
14. **Plancher de période cyclique ≥ 6 ⚙️** (`rules.json`,
    `validation.min_cycle_period` ; rejet structurel du validateur, avant
    toute énumération). L'oscillation d'une nuée doit se lire comme un
    avance/recul, pas un tremblement. Corollaire de conception : CASSER une
    oscillation devient un objectif de puzzle possible dès le chapitre 2,
    via une règle placée avant R02 dans la pile.
15. **« Bloqué » = mur ou bordure de grille, uniquement** (précise la
    décision n°1, que la revue valide comme IMPOSÉE par la règle d'or —
    « la première règle applicable l'emporte »). Une case occupée n'est
    jamais un blocage pour une règle, sinon sensibilité à la densité et
    comportements inexplicables. Documenté dans `Rule`, vérifié dans les
    trois règles.

### Ce que les tests de preuve ont établi (zéro changement de code)

- **Le point fixe existait déjà** (revue 1.1) : `_resolve_conflicts`
  raisonne en revendications de cases, pas en occupation. Libérations ET
  refus se propagent en cascade, indépendamment de l'ordre des ids —
  l'id ne départage que les prétendants à une même case libre (DT-07).
- **Tous les cycles fermés tournent** (revue 2.4) : échange à 2, rotations
  à 4 et 6, sans cas particulier. Le cycle IMPAIR est géométriquement
  impossible : un pas cardinal inverse la parité de (x+y), la grille est
  bipartie, tout cycle fermé est pair. L'incohérence redoutée (« 2 passe,
  3 bloque ») ne peut pas exister.
- **Empreintes en chaînes hexadécimales partout** (revue 1.2) : vérifié,
  puis verrouillé — assertion de type au chargement de `golden.json`
  (échec bruyant), aller-retour JSON strict testé, preuve exécutable
  qu'un nombre JSON tronque au-delà de 2^53.
- **Détection de boucle du validateur** (revue 3.4) : les compteurs SONT
  dans la clé (`dynamics_hash` couvre `counters`) ; la coupe vit
  exclusivement dans `tools/validate/` — garanti par le test
  d'architecture T-022 (`preload`/`load`/`res://` interdits dans `core/`,
  qui ne peut donc référencer aucun outil), pas par simple inspection.

### Parité et compaction (à suivre visuellement en S4)

Un agent qui bouge à chaque tick conserve la parité de (x+y) : en TRANSIT,
une nuée sous R03 ne peut pas se compacter en bloc. Constat de la fixture
`sensi_damier` : à l'ÉQUILIBRE, R03 s'abstient, et l'abstention casse la
parité — l'agrégat final est un escalier compact stable (dès t=150), pas
un damier permanent. L'effet damier est donc un phénomène de mouvement :
signature esthétique ou artefact perçu comme bug ? À trancher dès S4.

### Protocole permanent de régénération du corpus d'or

Appliqué pour la première fois ce jour ; désormais OBLIGATOIRE — plus
jamais de `--write` sans prédiction écrite préalable :
1. prédiction ÉCRITE, recette par recette (change / ne change pas, et
   pourquoi), rédigée avant toute vérification post-changement ;
2. `check_golden` en mode vérification, sans écriture ;
3. confrontation liste d'échecs ↔ prédiction — tout écart non prédit
   s'investigue avant toute écriture ;
4. feu vert humain, puis `--write` ; commit isolé citant les causes ;
5. l'archivage initial de nouvelles fixtures se fait dans un commit
   SÉPARÉ, après confrontation à leurs attendus qualitatifs.

Résultat du jour : 10 recettes prédites une à une, 9 inchangées, seule
corridor [2,1] change (danger cyclique + R02) — zéro écart non prédit.
Sur le champ 8×8, (3,4) est l'unique case de décision divergente du
plateau et elle est inatteignable dans les trois piles, pour trois raisons
distinctes (détaillées dans la PR du lot).

### Appartenance des règles aux chapitres (référence rapide, CDC §7.2)

| Chapitre | Règles |
|---|---|
| 1 — mouvement élémentaire | R01 Vers la lumière · R02 Fuir le rouge · R03 Rester groupé |
| 2 — coordination | R04 S'écarter · R05 Suivre les voisins · R06 Longer le mur |
| 3 — stigmergie | R07 Attendre · R08 Marquer la piste · R09 Suivre la piste |
| 4 — transport | R10 Rebrousser si seul · R11 Porter · R12 Déposer au but |
| 5 — sacrifice et régulation | R13 Boucher · R14 Disperser si dense · R15 Suivre le plus lent (+ R16 Ignorer, joker) |

### Autres ajouts du lot

- `rules_hash` archivé à côté de chaque recette d'or : distingue
  « régression du code » de « rééquilibrage voulu » (revue 3.1).
- Garde-fou de débogage : toute sortie de règle non-ABSTAIN doit être ZERO
  ou un pas cardinal — assert dans la cascade (revue 3.2).
- Validateur : « collecte sans R11/R12 autorisées » signalée hors
  chapitre, distincte d'un niveau cassé (revue 3.6).
- CI : nombre de tests exécutés = nombre déclaré, auto-ajustant ; tout
  écart futur (tests paramétrés) devra être explicite, jamais absorbé
  (revue 3.8).
- Exigence notée pour T-074 (éditeur) : refuser d'enregistrer un niveau
  sans accomplissement.
- Corpus d'or : **17 recettes** (10 régénérées + 7 fixtures de
  sensibilité : face-à-face, cadence ×2, célérité sur le fil, damier,
  chaîne A/B).
- docs/ARCHITECTURE.md : interdit n°4 reformulé par fonctionnalité (« le rendu suit
  toujours la simulation ») — condition satisfaite pour le chapitre 1.

---

## Fait — Convertisseur .lvl et CDC v2.2 (5 août 2026, branches `docs/qn01-tutoriels` et `feat/lvl-converter`)

Préparation de T-040 (conception du chapitre 1), sur le guide du
concepteur revu et corrigé (6 points d'écart moteur/guide relevés et
acceptés : case unique par type et lumière au-delà de la sortie —
en **bande pleine largeur** sur consigne du concepteur —, largeur
minimale 8, espace = 16 piles avec la vide, `slots` absent du validateur,
« phase » de cycle inexistante dans core, contournement R02 unilatéral
vers l'Est).

- **CDC → v2.2** (§12.2.1) : N_total défini par la convention de l'outil
  (arrangements de règles distinctes, longueur 0 à `slots`, pile vide
  incluse) ; niveaux `tutorial: true` exemptés de QN-01 (critère propre :
  `N_win` == `expected_wins` exactement) ; pile vide gagnante = niveau
  dégénéré, rejet universel ; bandes proportionnelles 20-50 % INDICATIVES,
  à confirmer après T-040, non opposables.
- **Validateur** : `slots` borne l'énumération (N_total en dépend) ;
  garde-fou dégénérescence ; mode informatif quand `tutorial` ou
  `expected_wins` est présent (« attendu N, constaté M », sans verdict) ;
  ratio rapporté. Les bandes ne sont PAS câblées — décision du concepteur,
  elles seraient une métrique fabriquée avant d'avoir vu un seul niveau.
- **Convertisseur `tools/lvl/`** (avance sur T-074) : `.lvl` (en-tête +
  grille ASCII) → JSON, validations à l'entrée (dimensions CDC 8×10-14×18
  plus haute que large, agents, sortie si extraction, symboles, plancher
  de période, règles implémentées uniquement), `--validate` enchaîne le
  validateur. **Conventions figées, elles affectent le déterminisme** :
  ids d'agents en ordre de lecture ; origine en haut à gauche.
  Limitations v1 assumées : pas de phase de cycle (toucherait le parcours
  de hachage), sens uniques rejetés (orientation absente de core/sim),
  une seule définition de cycle.
- **Critère de fin constaté** : `ch1_01.lvl` (croquis N1 du concepteur,
  corrigé bande de sortie + largeur 8 — la conception reste sa propriété,
  DCT §12.4) converti et validé : espace de 2 piles, `N_win = 1`,
  « attendu 1, constaté 1 ». Verrouillé par test permanent.

## Reste à faire

**S3 : clos** — premier passage de la CI en ligne constaté vert le
5 août 2026 (dernier point en suspens).

**S4-S5 (plan §6) — nécessite des décisions du concepteur :**
- T-030→T-032 : prototype jouable — **premier rendu autorisé** (S4), pilotage,
  pile de règles UI. (T-033 `core/replay/` : **déjà fait**, voir ci-dessus —
  il ne reste que son branchement à l'interface.)
- T-040→T-045 : les 5 niveaux du chapitre 1 (conception humaine), validation,
  test des quatre piles (EQ-05), sauvegarde minimale, campagne 1, transport.
- Décision J-1 (6 sept. 2026) : GO / PIVOT / STOP.

**Toujours ouverts, à la charge du porteur :** T-003 (appareil de référence),
T-004 (chaîne complète — Android SDK prévu S9), T-006 (clé de signature,
deux sauvegardes hors dépôt), T-008 (recrutement testeurs — **bloque J-1**).

**Rappels d'invariants pour la suite** : les types de case RESOURCE, DROPOFF,
PRESSURE_DOOR, ONE_WAY sont reconnus mais inertes (chapitres 2/4).
`SimCore.explain` (EF-05) reste à écrire (T-065, S8). `export_presets.cfg`
(minSdk 33, targetSdk 36) sera créé avec la chaîne d'export en S9. Toute
divergence d'empreinte d'or est une régression à corriger, jamais une valeur
à mettre à jour (la commande `--write` de `check_golden.gd` exige une
décision humaine consignée ici).

---

## Mesures

| Mesure | Valeur | Date |
|---|---|---|
| Empreinte de fumée (test_smoke, 200 ticks, pile 1,2,3,0) | `c8a7cc2c73394949` — **inchangée à travers la revue S3** | 5 août 2026 |
| Tests (unitaires + architecture + or) | 125/125 (360 assertions), ~0,9 s | 5 août 2026 |
| Recettes d'or | 17/17 concordantes (10 régénérées sous protocole + 7 fixtures de sensibilité) | 5 août 2026 |
| Coupe de boucle du validateur | simulation statique tranchée en ~7 ticks au lieu de 300 | 4 août 2026 |
| Godot | 4.7.1-stable, standard (pas .NET), Linux x86_64 | 4 août 2026 |
| GUT | 9.6.1 | 4 août 2026 |
| CI GitHub Actions (premier passage en ligne) | vert | 5 août 2026 |
