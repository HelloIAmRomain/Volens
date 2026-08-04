# VOLENS — Plan de production

**Version 1.1 — 4 août 2026**
*Planning détaillé du projet Volens (ESSAIM), en réponse au CDC v2.1 et au DCT v1.1*

---

## 0. Comment utiliser ce document

Ce plan est un **outil de pilotage hebdomadaire**, pas une prévision à respecter à la lettre. Il se lit à trois échelles :

- **§3 — Macro-planning** : la vue d'ensemble, à consulter une fois par mois.
- **§5 à §10 — Le détail semaine par semaine** : la vue de travail, à ouvrir chaque lundi.
- **§13 — Le rituel de pilotage** : ce qui garantit que le plan reste vivant plutôt que décoratif.

Chaque lot de travail porte un identifiant **L-xx**, chaque tâche un identifiant **T-xxx**, chaque jalon **J-x**. Les renvois `[DT-xx]` et `[EF-xx]` pointent vers le dossier technique et le cahier des charges.

---

## 1. Hypothèses de planification

| Paramètre | Valeur | Commentaire |
|---|---|---|
| Capacité nominale | **15 h/semaine** | Projet mené en parallèle d'une activité professionnelle à temps plein |
| Répartition type | 2 soirées (2 h) + 1 demi-journée week-end (4 h) + créneaux courts | La demi-journée sert au travail de fond ; les soirées aux tâches courtes |
| Capacité réelle retenue | **12 h/semaine** (80 %) | Abattement pour aléas ordinaires ; toutes les charges ci-dessous sont calculées sur cette base |
| Semaines travaillées | 26 sur 30 | 4 semaines à capacité nulle ou réduite, positionnées en §2 |
| Durée totale | **30 semaines calendaires**, du 3 août 2026 au 28 février 2027 | Publication visée : **début mars 2027** |
| Charge totale estimée | ≈ 330 h | Dont 45 h de réserve non affectée (§11) |

**Règle de conduite n°1 : une semaine perdue ne se rattrape pas en accélérant, elle décale.** Le seul levier d'ajustement autorisé est le **périmètre du contenu** (nombre de niveaux), jamais la qualité ni les jalons de décision.

---

## 2. Calendrier des contraintes de capacité

Ces créneaux sont intégrés au planning ; les jalons ont été positionnés pour ne jamais tomber juste après une semaine creuse.

| Semaine | Période | Capacité | Motif |
|---|---|---|---|
| S7 | 14-20 sept. 2026 | **6 h** | Déplacement de fin de semaine (départ possible dès le jeudi soir) |
| S8 | 21-27 sept. 2026 | **8 h** | Retour possible lundi ou mardi |
| S20-S21 | 14-27 déc. 2026 | **6 h/sem.** | Fêtes de fin d'année |
| Variable | À déterminer | **-10 à -20 h ponctuelles** | **Déménagement** — voir ci-dessous |

**Le déménagement est le principal aléa de ce plan.** Une recherche de logement en cours signifie qu'à un moment non maîtrisé des sept prochains mois, deux à trois semaines seront fortement amputées (visites, dossier, état des lieux, cartons, installation). Trois dispositions en découlent :

1. La réserve de 45 h (§11) est dimensionnée pour l'absorber en totalité.
2. Dès que la date de signature est connue, ce plan est **re-jalonné** dans la semaine (§13.3) — on décale, on ne compresse pas.
3. Les jalons J-1 et J-2, qui sont des points de décision, ne doivent jamais être évalués dans une période perturbée : si le déménagement tombe dessus, le jalon glisse.

---

## 3. Macro-planning

```
 2026                                          2027
 AOÛ   SEP   OCT   NOV   DÉC   JAN   FÉV   MAR
 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼──────
 █ J-0 Cadrage (S1)
  ████ L-1 Socle & simulation (S2-S3)
      ██ J-1 PROTOTYPE ▲ DÉCISION (S4-S5)
        ████████ L-2..L-6 Tranche verticale (S6-S12)
                ██ J-2 TRANCHE VERTICALE ▲ DÉCISION (S13)
                  ████████████ L-7..L-9 Production contenu (S14-S22)
                              ██ J-3 Contenu gelé (S23)
                                ██████ L-10..L-12 Finition (S24-S27)
                                      █ J-4 Version candidate (S28)
                                       ███ L-13 Publication (S29-S30)
                                          ▲ J-5 PUBLICATION
 ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬  L-14 Visibilité (continu, dès S6)
```

| Jalon | Semaine | Date cible | Nature |
|---|---|---|---|
| **J-0** Cadrage clos | S1 | 9 août 2026 | Livraison |
| **J-1** Prototype évalué | S5 | 6 sept. 2026 | **DÉCISION : GO / PIVOT / STOP** |
| **J-2** Tranche verticale | S13 | 1er nov. 2026 | **DÉCISION : GO production / révision de périmètre** |
| **J-3** Contenu gelé | S23 | 10 janv. 2027 | Livraison |
| **J-4** Version candidate | S28 | 14 févr. 2027 | Gel de version |
| **J-5** Publication | S30 | 28 févr. 2027 | Mise en ligne |

---

## 4. Structure de découpage (lots de travail)

| Lot | Intitulé | Charge | Période | Dépend de |
|---|---|---|---|---|
| **L-0** | Cadrage et mise en place | 12 h | S1 | — |
| **L-1** | Socle : module de simulation + tests d'or | 30 h | S2-S3 | L-0 |
| **L-2** | Validateur headless | 18 h | S3-S4 | L-1 |
| **L-3** | Prototype jouable (rendu + UI brute) | 26 h | S4-S5 | L-1 |
| **L-4** | Campagne de test 1 et décision | 10 h | S5 | L-3 |
| **L-5** | Interface définitive | 34 h | S6-S9 | J-1 |
| **L-6** | Persistance, cycle de vie, reprise | 16 h | S8-S9 | L-3 |
| **L-7** | Rendu et direction artistique finalisés | 24 h | S10-S12 | L-5 |
| **L-8** | Audio | 12 h | S11-S12 | L-6 |
| **L-9** | Éditeur de niveaux interne | 14 h | S10-S11 | L-2 |
| **L-10** | Production du contenu (règles + niveaux) | 90 h | S14-S22 | J-2, L-9 |
| **L-11** | Progression, défis, encyclopédie, aide | 20 h | S15-S18 | L-5 |
| **L-12** | Accessibilité, localisation, optimisation | 26 h | S24-S27 | L-7 |
| **L-13** | Conformité et publication | 18 h | S28-S30 | L-12 |
| **L-14** | Visibilité et devlog | 30 h | S6-S30 (continu) | — |
| **L-15** | Campagnes de test 2 et 3, **test fermé fusionné** *(v1.1, C2)* | 18 h + ≈9 h | S13, S23-**S28** | L-6, L-10 |
| | **Total** | **≈ 368 h** *(à re-totaliser au prochain jalon, §13.3 — le test fermé ajoute ≈9 h non comptées ci-dessus)* | | |

*Écart avec la charge affectée (330 h) : la visibilité (L-14) déborde volontairement sur la période post-publication et n'est pas intégralement consommée avant J-5.*

---

## 5. Phase 0 — Cadrage (S1 : 3-9 août 2026)

**Objectif de la phase :** ne rien avoir à défaire plus tard. Toutes ces décisions sont bon marché aujourd'hui et coûteuses dans trois mois.

| ID | Tâche | Charge | Détail |
|---|---|---|---|
| T-001 | ~~Recherche d'antériorité « Volens »~~ **Clos** *(v1.1, C1)* | 2 h | Bases INPI et EUIPO (classes 9 et 41), recherche Google Play / App Store / Steam / itch.io, disponibilité du domaine et des pseudonymes (Mastodon, Bluesky, Reddit, YouTube). **Verdict :** aucune mention de « Volens » à l'INPI ni à l'EUIPO en classes 9 et 41 ; risque de référencement accepté vis-à-vis de l'éditeur Steam « Volens Nolens Games » ; aucun dépôt de marque engagé |
| T-002 | ~~Figer l'identifiant d'application~~ **Clos** *(v1.1, C1)* | 30 min | Identifiant figé : **`com.volensgame.volens`** — irréversible après le premier envoi sur Play |
| T-003 | Désigner l'appareil de référence | 1 h | Android milieu de gamme ~2022 ; noter modèle, version d'Android, définition, densité, fréquence d'écran. Toutes les cibles ENF-10→14 s'y rapportent |
| T-004 | Installer la chaîne de développement | 3 h | Godot 4.7.x, OpenJDK 17, Android SDK command-line tools + plateforme API 36, débogage USB. **Critère de fin : un projet vide s'exécute sur l'appareil de référence** |
| T-005 | Créer le dépôt Git et son squelette | 2 h | Arborescence du DCT §2.2 *(v1.1 : deux étages `core/`·`game/`)*, `.gitignore` Godot, branche `main` protégée, modèle de message de commit |
| T-006 | Générer et sécuriser la clé de signature | 1 h | Clé de release auto-générée `[DT-21]`, **sauvegardée en deux emplacements distincts hors du dépôt**. Une clé perdue interdit toute mise à jour ultérieure de l'application |
| T-007 | Ouvrir le carnet de bord du projet | 30 min | Un fichier unique : décisions prises, écarts au plan, mesures. C'est la mémoire du projet et la matière première du devlog |
| T-008 | Pré-recruter les testeurs | 2 h | Solliciter 10-12 personnes pour en retenir 5-8 pour la campagne 1 `[CDC §13.1]`. **À faire maintenant : le recrutement est le poste le plus souvent sous-estimé et il bloque J-1.** *(v1.1, C5)* Un second recrutement, distinct et plus large (**15 à 18 personnes**), sera nécessaire avant S25 pour la campagne 3 / test fermé `[CDC §13.3]` — à anticiper mais pas à lancer maintenant |

**Livrables J-0 :** verdict d'antériorité écrit · dépôt initialisé avec CI vide qui passe · APK vide installé sur l'appareil de référence · liste de testeurs pré-engagés.

**Point d'arrêt *(v1.1 : franchi, T-001 clos sans réserve)*.** Le risque était : si « Volens » s'avérait déposé en classe 9 ou 41, la question du nom se rouvrait **avant** tout travail d'identité visuelle — coût alors : une demi-journée, contre l'identité visuelle, la page de store et le référencement déjà construits si la découverte était venue en janvier. Le verdict T-001 lève ce risque : aucun dépôt trouvé, seul le risque de référencement mineur vis-à-vis de « Volens Nolens Games » (Steam) est accepté.

---

## 6. Phase 1 — Prototype (S2-S5 : 10 août - 6 sept. 2026)

**Objectif de la phase :** obtenir le plus tôt possible la réponse à la seule question qui compte — *l'émergence est-elle réelle et amusante ?* Tout ce qui n'y contribue pas est reporté.

### S2 — Le cœur de simulation (12 h)

| ID | Tâche | Charge |
|---|---|---|
| T-010 | Structures d'état : `SimState`, `AgentState`, `GridState` `[DCT §4.1]` | 3 h |
| T-011 | Pipeline de tick complet, à vide (sans règles) `[DCT §4.4]` | 3 h |
| T-012 | Interface de règle + les 3 règles du chapitre 1 (vers la lumière, fuir le rouge, rester groupé) `[DT-10]` | 4 h |
| T-013 | Empreinte d'état FNV-1a en arithmétique entière `[DT-09]` | 2 h |

**Définition de fini S2 :** le module tourne en headless, sans rendu ; 200 ticks s'exécutent sans erreur ; deux exécutions successives produisent la même empreinte.

### S3 — Verrouillage du déterminisme et validateur (12 h)

| ID | Tâche | Charge |
|---|---|---|
| T-020 | Tests unitaires des 3 règles (cas nominaux, bords, conflits, abstention) | 3 h |
| T-021 | **Tests d'or** : corpus de 10 recettes, empreintes archivées à t=50/150/300 `[DCT §11.2]` | 2 h |
| T-022 | Tests d'architecture : interdits de dépendance + interdits lexicaux (flottants, aléatoire dans `sim/`) `[DT-04]` | 3 h |
| T-023 | CI GitHub Actions : Godot headless en cache, exécution des trois familles de tests `[DT-19]` | 2 h |
| T-024 | Validateur v1 : énumération des piles, verdict de victoire, rapport CSV `[DT-15]` | 2 h |

**Définition de fini S3 :** un commit introduisant volontairement un `randf()` dans `sim/` **fait échouer la CI**. C'est le test du dispositif, à exécuter réellement, pas à supposer.

> ⚠️ **Ne pas sauter T-021/T-022.** Ces 5 heures paraissent du luxe en semaine 3 et deviennent le filet qui rattrape toutes les régressions des semaines 4 à 30. C'est le meilleur rapport coût/bénéfice de tout le plan.

### S4 — Prototype jouable (12 h)

| ID | Tâche | Charge |
|---|---|---|
| T-030 | Rendu minimal : grille, agents en MultiMesh, éléments — **sans aucune recherche esthétique** | 4 h |
| T-031 | Pilotage : lecture/pause, vitesses, tick par tick, réinitialisation `[EF-02/04]` | 3 h |
| T-032 | Pile de règles : 4 emplacements, sélection, réordonnancement (version rustique acceptée) | 3 h |
| T-033 | Clichés-clés et remontée du temps `[DT-12]` | 2 h |

### S5 — Niveaux, test et décision (12 h)

| ID | Tâche | Charge |
|---|---|---|
| T-040 | Concevoir les 5 niveaux du chapitre 1 selon la rampe pédagogique `[CDC §8.5]` | 4 h |
| T-041 | **Valider les 5 niveaux au validateur avant tout test humain** — retravailler ceux qui sortent de `3 ≤ N_win ≤ 40` | 2 h |
| T-042 | Vérifier le test des quatre piles `[CDC §7.3, EQ-05]` : les 4 ordonnancements donnent-ils 4 comportements visiblement distincts ? | 1 h |
| T-043 | Sauvegarde minimale de session (pour tester la reprise) | 1 h |
| T-044 | **Campagne de test 1** : 5-8 testeurs, protocole `[CDC §13.1]` | 3 h |
| T-045 | Test en transport réel `[CDC §13.4]` | 1 h |

### ▲ J-1 — Point de décision (fin S5, 6 septembre 2026)

| Critère | Seuil | Résultat si échec |
|---|---|---|
| **Émergence** : testeurs trouvant ≥ 2 solutions distinctes à un même niveau | **≥ 60 %** | **PIVOT ou STOP** |
| Règle d'or comprise sans explication après le niveau 2 | ≥ 70 % | Retravailler N1-N2, re-tester (+1 semaine) |
| Relance spontanée après échec | ≥ 80 % | Renforcer le diagnostic `[EF-05]` avant de continuer |
| Reprise utile en < 10 s après interruption de 2 min | 100 % | Corriger avant J-2 |

**Cette décision est réelle.** Elle est prise sur les chiffres, écrite au carnet de bord, et engage. En cas d'échec du premier critère, la conduite prévue est : *soit* pivot vers un concept alternatif (le travail sur le socle déterministe et la CI reste réutilisable), *soit* arrêt. Le seul comportement interdit est de continuer « pour voir ».

---

## 7. Phase 2 — Tranche verticale (S6-S13 : 7 sept. - 1er nov. 2026)

**Objectif :** obtenir deux chapitres **finis**, pas six chapitres ébauchés. Tout ce qui est livré ici est de qualité définitive et ne sera plus retouché.

### S6-S7 — Interface définitive, première moitié (12 h + 6 h)

*(S7 à capacité réduite — déplacement de fin de semaine)*

| ID | Tâche | Charge |
|---|---|---|
| T-050 | Machine à états d'écrans : Accueil, Carte, Jeu, Bilan, Réglages `[DCT §9.1]` | 4 h |
| T-051 | Disposition de l'écran de jeu : zones sûres Android, bandeau d'objectif, zone pouce `[ENF-01]` | 4 h |
| T-052 | Thème contraignant : cibles ≥ 48 dp, échelle de police système | 3 h |
| T-053 | Ouverture du devlog (L-14) : premier billet, capture d'une nuée en mouvement | 3 h |
| T-054 | Bilan de niveau : objectif, ticks, pertes, pile utilisée `[EF-07]` | 4 h |

### S8-S9 — Interaction, persistance, reprise (8 h + 12 h)

*(S8 à capacité réduite — retour de déplacement)*

| ID | Tâche | Charge |
|---|---|---|
| T-060 | Glisser-déposer de la pile + équivalent sans glissement `[ENF-25]` | 5 h |
| T-061 | Tiroir de bibliothèque coulissant | 3 h |
| T-062 | Persistance : recette, écriture atomique, schémas versionnés `[DT-14]` | 5 h |
| T-063 | Cycle de vie Android : pause/reprise/processus tué `[DCT §13.2]` | 3 h |
| T-064 | **Mesure de la chaîne de reprise** : objectif < 3 s sur l'appareil de référence `[EF-21]` | 2 h |
| T-065 | Diagnostic `explain` : appui sur un agent → cascade de décision `[EF-05]` | 2 h |

> **Mesurer T-064 dès maintenant**, pas en phase de finition. Si le démarrage à froid dépasse le budget, la correction (chargement différé, suppression de ressources au boot) est structurelle et doit intervenir avant que l'application ne grossisse.

### S10-S12 — Rendu, audio, outillage de contenu (36 h)

| ID | Tâche | Charge |
|---|---|---|
| T-070 | Direction artistique appliquée : palette, shaders de halo, hachures de danger, traînées | 8 h |
| T-071 | Interpolation visuelle et calques de lisibilité `[DCT §6.2/6.3]` | 4 h |
| T-072 | Modes contraste élevé et animations réduites `[ENF-21/22]` | 4 h |
| T-073 | Moteur audio événementiel + génération hors ligne des échantillons `[DT-17]` | 8 h |
| T-074 | **Éditeur de niveaux interne** (scène `@tool`) avec bouton « Valider ce niveau » `[DT-20]` | 8 h |
| T-075 | Chapitre 2 : 3 règles supplémentaires + 13 niveaux, tous validés | 4 h |

> **T-074 est un investissement, pas un détour.** Quatorze heures d'outillage qui conditionnent les 90 heures de production de contenu de la phase 3. Sans lui, chaque niveau se conçoit à l'aveugle dans un éditeur de texte.

### S13 — Campagne de test 2 et jalon (12 h)

| ID | Tâche | Charge |
|---|---|---|
| T-080 | Campagne de test 2 : courbe de difficulté, lisibilité, défis, offre de déblocage `[CDC §13.2]` | 5 h |
| T-081 | Test en transport réel, version complète | 2 h |
| T-082 | Mesures : images/s, poids, démarrage à froid, consommation en pause | 2 h |
| T-083 | Bilan de jalon, re-jalonnement du plan | 3 h |

### ▲ J-2 — Point de décision (fin S13, 1er novembre 2026)

| Critère | Seuil |
|---|---|
| Chapitres 1-2 **finis** (18 niveaux, 6 règles, interface définitive, audio, sauvegarde) | Oui/Non |
| Tous les niveaux conformes `3 ≤ N_win ≤ 40`, sans stratégie dominante `[QN-01/02]` | 100 % |
| Reprise < 3 s constatée sur appareil ; 60 i/s ; poids sur trajectoire < 60 Mo | Oui/Non |
| Test transport concluant | Oui/Non |
| **Le concepteur prend-il encore du plaisir à équilibrer et rejouer son jeu ?** | Oui/Non |

**Le dernier critère n'est pas un ornement.** Après six semaines passées à régler les mêmes niveaux, la réponse honnête à cette question est le meilleur prédicteur disponible de l'intérêt du public. Une réponse négative justifie une révision de périmètre, voire un arrêt — et il vaut mieux la formuler en novembre qu'en février.

---

## 8. Phase 3 — Production du contenu (S14-S23 : 2 nov. 2026 - 10 janv. 2027)

**Objectif :** passer de 18 à 70+ niveaux et de 6 à 16 règles. C'est la phase la plus longue, la plus répétitive et la plus sous-estimée par les développeurs solo.

### Cadence de production

**Cycle par chapitre (≈ 2 semaines, 24 h) :**

1. **Conception des règles** (4 h) — 2 à 3 nouvelles règles ; vérifier le critère d'admission `[RG-13]` : conflit intéressant avec ≥ 2 règles existantes.
2. **Implémentation et tests unitaires** (6 h).
3. **Conception des niveaux** (8 h) — 10 à 12 niveaux dans l'éditeur interne.
4. **Validation et retouche** (4 h) — passer le validateur, retravailler tout ce qui sort des seuils QN.
5. **Auto-test** (2 h) — jouer le chapitre soi-même, dans un bus, sans regarder les solutions connues.

| Semaines | Contenu | Cible |
|---|---|---|
| S14-S15 | **Chapitre 3** — stigmergie (marquer/suivre la piste) | 12 niveaux, 3 règles |
| S16-S17 | **Chapitre 4** — transport (porter/déposer/rebrousser) | 12 niveaux, 3 règles |
| S18-S19 | **Chapitre 5** — sacrifice et régulation | 12 niveaux, 3 règles |
| S20-S21 | *Capacité réduite (fêtes)* — chapitre 6 entamé, tâches courtes, rattrapage | 6 niveaux |
| S22 | **Chapitre 6** achevé — règle joker + niveaux d'examen | 8 niveaux, 1 règle |
| S23 | Validation intégrale du catalogue, campagne de test 3 lancée | — |

**Le chapitre 3 est le point de bascule du jeu.** La stigmergie fait passer la nuée du réflexe à l'organisation ; si ces niveaux ne produisent pas d'effet « ah, elles s'organisent toutes seules », c'est le signal d'alerte le plus sérieux de la phase.

### Travaux menés en parallèle (S15-S18, ≈ 20 h)

| ID | Tâche | Charge |
|---|---|---|
| T-090 | Progression, déblocages, seuil d'ouverture de chapitre `[RG-20]` | 5 h |
| T-091 | Défis optionnels : économie, abstinence, efficience `[RG-18/19]` | 5 h |
| T-092 | Encyclopédie des règles avec démonstrations animées `[EF-12]` | 5 h |
| T-093 | Aide graduée : indice structurel pré-tiré `[EF-30, DCT §9.4]` | 5 h |

### ▲ J-3 — Contenu gelé (fin S23, 10 janvier 2027)

- 70 niveaux minimum, 16 règles.
- **Rapport de validation conforme et à jour pour 100 % du catalogue** `[EQ-02]`.
- Aucune stratégie dominante détectée sur aucun chapitre `[QN-02]`.
- Aucune règle morte `[EQ-04]`.
- **À partir de ce point, plus aucun ajout de contenu.** Toute idée nouvelle est notée pour une version ultérieure.

---

## 9. Phase 4 — Finition (S24-S28 : 11 janv. - 14 févr. 2027)

*(v1.1, C2 — réorganisée autour de l'obligation de test fermé Google Play : le contenu est déjà gelé à J-3 [S23], un build fonctionnel de test fermé existe dès S24, les 14 jours consécutifs de test courent de S25 à S27, la demande d'accès production part en S28. `T-104` [§10] est fusionnée ici.)*

| Semaine | Travaux | Charge |
|---|---|---|
| S24 | Campagne de test 3 (bêta de contenu) : durée de vie réelle, pics de difficulté, usure du plaisir, usage des indices (10 h) ; création de l'application dans la Play Console et upload du premier AAB de test fermé — **build fonctionnel prêt en fin de semaine** `[DT-21]` (2 h) | 12 h |
| S25 | **Lancement du test fermé** *(v1.1)* : piste de test fermé Google Play (jamais interne), 15-18 testeurs inscrits, ouverture du compteur de 14 jours consécutifs `[CDC §14.4]` (2 h) ; accessibilité complète : vérification daltonisme (3 dyschromatopsies), contraste, animations réduites, taille de police, haptique désactivable `[ENF-20→25]` (10 h) | 12 h |
| S26 | Localisation français/anglais complète et relue ; corrections issues de la campagne 3 (10 h) ; **suivi du test fermé** — inscriptions, relances pour prévenir tout désistement `[C3]` (2 h) | 12 h |
| S27 | Optimisation : profilage, budget de poids, consommation en pause, démarrage à froid (8 h) ; **vérification du déterminisme sur deux architectures CPU distinctes — arm64 (appareil de référence) et x86_64 (émulateur + CI)** `[ENF-05]` (2 h) ; **clôture des 14 jours du test fermé** et dépouillement des codes courts d'auto-vérification d'empreinte remontés par les testeurs `[DT-22]` — aucun appareil supplémentaire acheté (2 h) | 12 h |
| S28 | Correction des derniers défauts, revue complète de la liste d'acceptation `[CDC §16]`, gel de version (11 h) ; **demande d'accès production** Google Play, une fois les 14 jours validés (1 h) | 12 h |

**Charge du test fermé *(v1.1, C2)* : ≈ 9 h réparties sur S24-S28**, pas les 3 h forfaitaires de l'ancien `T-104` — le suivi quotidien des inscriptions et les relances contre le désistement (§12) sont un travail réel, pas une formalité.

### ▲ J-4 — Version candidate (fin S28, 14 février 2027)

La liste d'acceptation v1.0 du CDC §16 est passée **point par point**, avec une preuve pour chacun (mesure, capture, rapport). Un point non prouvé est un point non acquis.

> *(v1.1, C1)* Le compte développeur Google Play est **déjà créé et vérifié** depuis J0 — il n'y a plus d'action de paiement à engager ici. Ce qui reste à faire dès S24 : créer l'**application** dans la Play Console (voir tableau ci-dessus) pour tenir le calendrier du test fermé.

---

## 10. Phase 5 — Publication (S29-S30 : 15-28 févr. 2027)

| ID | Tâche | Charge |
|---|---|---|
| T-100 | Intégration de la facturation Play (déblocage unique) + tests d'achat en piste fermée `[EF-41]` | 5 h |
| T-101 | Politique de confidentialité (une page, GitHub Pages) `[ENF-33]` | 1 h |
| T-102 | Formulaire Data Safety (« aucune donnée collectée »), déclaration de contenu IA, classification d'âge | 2 h |
| T-103 | Fiche de store : titre, description courte et longue (FR/EN), icône, captures, **vidéo courte d'une nuée en mouvement** | 6 h |
| T-104 | ~~Test fermé (piste interne) avec les testeurs, sur AAB signé de production~~ — **fusionnée avec la campagne 3** *(v1.1, C2)*, voir §9 S24-S28 : lancement, suivi et clôture du test fermé, demande d'accès production | *(charge déplacée en §9)* |
| T-105 | Envoi, réponse aux retours de revue, publication — accès production déjà accordé (demande partie en S28) | 3 h |
| T-106 | Annonce : devlog, communautés de jeux de réflexion et de simulation | 4 h |

### ▲ J-5 — Publication (28 février 2027)

**Après la publication (hors périmètre de ce plan, à planifier en mars) :** surveillance des retours et des rapports d'incident les 15 premiers jours, correctif éventuel, puis décision sur les évolutions `[CDC §17]`.

---

## 11. Charge, réserve et chemin critique

### 11.1 Répartition de la charge

| Poste | Heures | Part |
|---|---|---|
| Contenu (règles + niveaux) | 90 h | 27 % |
| Interface et interaction | 54 h | 16 % |
| Rendu et audio | 36 h | 11 % |
| Socle, simulation, outillage | 62 h | 19 % |
| Tests et campagnes | 28 h | 8 % |
| Finition, conformité, publication | 44 h | 13 % |
| Visibilité (avant publication) | 20 h | 6 % |
| **Réserve non affectée** | **45 h** | — |

### 11.2 Chemin critique

```
Simulation (L-1) → Validateur (L-2) → Prototype (L-3) → J-1
   → Interface (L-5) → Éditeur de niveaux (L-9) → Contenu (L-10) → J-3
       → Finition (L-12) → Publication (L-13)
```

Trois maillons commandent tout le reste :

1. **Le module de simulation** — tout en dépend, y compris le validateur.
2. **L'éditeur de niveaux** — son retard retarde mécaniquement 90 heures de production.
3. **La production de contenu** — poste le plus lourd, le seul dont le périmètre soit ajustable.

**Hors chemin critique**, donc décalables sans dommage : audio, modes d'accessibilité, encyclopédie, devlog.

### 11.3 Politique d'ajustement

Si le retard cumulé atteint **3 semaines**, l'ajustement s'applique dans cet ordre strict :

1. Réduire le nombre de niveaux (70 → 60 minimum) ;
2. Reporter le chapitre 6 en extension post-lancement ;
3. Décaler la date de publication ;
4. **Jamais** : réduire les campagnes de test, sauter la validation des niveaux, rogner l'accessibilité.

---

## 12. Registre de suivi des risques

| # | Risque | Signal d'alerte | Action déclenchée |
|---|---|---|---|
| P1 | Échec du critère d'émergence à J-1 | < 60 % au test | Pivot ou arrêt — décision au jalon, sans délai |
| P2 | Déménagement en pleine phase 3 | Signature de bail | Re-jalonnement dans la semaine ; consommation de la réserve |
| P3 | Production de contenu plus lente que prévu | < 8 niveaux validés sur 2 semaines | Appliquer §11.3 dès le deuxième cycle en retard, pas au troisième |
| P4 | Lassitude du concepteur | Deux semaines sans ouvrir le projet | Pause franche d'une semaine, puis relecture du J-2 : la réponse a-t-elle changé ? |
| P5 | Validateur trop lent | Cycle nocturne > 8 h | Parallélisation renforcée, puis portage C++ `[DT-16]` |
| ~~P6~~ | ~~Compte Play retardé~~ | — | **Supprimé** *(v1.1, C3)* : compte déjà créé et vérifié avant J0 (DT-21) |
| P7 | Régression du déterminisme | Test d'or en échec | Correction immédiate, avant toute autre tâche — c'est bloquant |
| P8 | **Désistement de testeurs pendant les 14 jours** *(v1.1, nouveau — C3)* | Un testeur inscrit se désinscrit avant la fin de la période | Recruter 15-18 personnes (marge au-dessus du minimum de 12) ; rappeler explicitement de ne pas se désinscrire avant la fin des 14 jours |
| P9 | **Rejet de la demande d'accès production pour engagement insuffisant** *(v1.1, nouveau — C3)* | Retour Google Play signalant une activité de test jugée insuffisante | Recruter des testeurs réellement actifs (qui ouvrent et jouent), pas de simples installations passives |

---

## 13. Rituel de pilotage

### 13.1 Chaque semaine (20 minutes, le lundi)

1. Relire les tâches de la semaine dans ce plan.
2. Noter au carnet de bord les heures réellement effectuées la semaine passée.
3. Comparer à la capacité retenue (12 h) et **noter l'écart cumulé** — c'est l'indicateur unique de dérive.
4. Choisir la première tâche de la semaine.

### 13.2 Chaque mois (1 heure)

- Reporter l'avancement sur le macro-planning §3.
- Vérifier les signaux d'alerte du §12.
- Publier un billet de devlog (obligation L-14 — c'est ce qui rend le rituel utile hors de soi-même).

### 13.3 À chaque jalon

Bilan écrit : ce qui était prévu, ce qui a été fait, l'écart, la décision. **Le re-jalonnement du plan est une tâche du jalon**, pas une intention.

### 13.4 Indicateurs

| Indicateur | Fréquence | Seuil d'alerte |
|---|---|---|
| Écart de capacité cumulé | Hebdo | > 20 h |
| Niveaux validés / niveaux prévus | Bi-hebdo (phase 3) | < 80 % |
| CI au vert | Continu | Tout échec de test d'or |
| Démarrage à froid + reprise | À chaque jalon | > 3 s |
| Poids de l'AAB | Mensuel | > 50 Mo |

---

## 14. Ce qu'il faut faire cette semaine

*(v1.1, C1 — mis à jour : T-001 et T-002 sont clos, voir §5.)*

Par ordre, dès aujourd'hui :

1. ~~T-001 — vérifier « Volens »~~ **Fait** : aucun dépôt trouvé, risque de référencement accepté.
2. **T-008 — solliciter les testeurs.** Le recrutement met des semaines à aboutir et bloque J-1 ; l'engager maintenant, pas en septembre.
3. **T-004 + T-005 — chaîne de développement et dépôt.** Critère de fin non négociable : un projet Godot vide s'exécute sur l'appareil de référence, et la CI passe au vert sur un dépôt encore quasi vide.
4. **T-006 — générer et sauvegarder la clé de signature**, en deux endroits distincts.

Puis, semaine prochaine, la première ligne de `sim/` — et pas une ligne de rendu avant la semaine 4.

---

## Historique des révisions *(v1.1)*

| Version | Date | Changements | Motif |
|---|---|---|---|
| 1.0 | 3 août 2026 | Version initiale | Réponse au CDC v2.0 et au DCT v1.0 |
| 1.1 | 4 août 2026 | T-001 et T-002 clôturés avec verdict (§5, §14) ; phase 4 réorganisée autour de l'obligation de test fermé (§9) : build fonctionnel S24, lancement S25, 14 jours jusqu'à S27, demande d'accès production S28 ; `T-104` fusionnée avec la campagne 3, charge corrigée de 3 h à ≈9 h répartis ; `L-15` étendu à S28 (§4) ; risque `P6` supprimé, risques `P8` (désistement) et `P9` (rejet pour engagement insuffisant) ajoutés (§12) ; recrutement de testeurs différencié : 5-8 (campagne 1, maintenant) vs 15-18 (campagne 3/test fermé, avant S25) (§5, C5) | Compte Google Play déjà créé et vérifié avant J0 ; obligation de test fermé (12 testeurs, 14 jours) découverte après la v1.0 du plan |

*Fin du document — Plan de production v1.1. Ce plan se révise à chaque jalon ; les dates après J-2 sont indicatives et seront recalées le 1er novembre 2026.*
