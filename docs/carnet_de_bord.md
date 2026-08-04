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
| — | **Dispositif exercé réellement** : `randf()` injecté dans `agent_state.gd` → détecté à la ligne exacte par le test d'architecture → retiré, retour au vert. Définition de fini S3 satisfaite (localement ; le premier passage CI en ligne reste à observer) | — |
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

## Reste à faire

**S3 — reliquat :**
- Observer le **premier passage de la CI en ligne** (poussée du 4 août) et
  corriger le cas échéant — seul point S3 non constatable hors ligne.

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
| Empreinte de fumée (test_smoke, 200 ticks, pile 1,2,3,0) | `c8a7cc2c73394949` | 4 août 2026 |
| Tests (unitaires + architecture + or) | 92/92 (268 assertions), ~0,7 s | 4 août 2026 (S3) |
| Recettes d'or | 10/10 concordantes, doublement vérifiées | 4 août 2026 |
| Coupe de boucle du validateur | simulation statique tranchée en ~7 ticks au lieu de 300 | 4 août 2026 |
| Godot | 4.7.1-stable, standard (pas .NET), Linux x86_64 | 4 août 2026 |
| GUT | 9.6.1 | 4 août 2026 |
