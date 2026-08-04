# Volens — Cahier des charges fonctionnel

**Version 2.1 — 4 août 2026**
*Document de spécification — jeu mobile de puzzle systémique*

---

## Avertissement de lecture

Ce document décrit **ce que le produit doit faire et à quel niveau de qualité**, jamais comment le réaliser. Les choix de moteur, de langage, d'architecture logicielle et d'outillage relèvent du dossier de conception technique, qui répondra à ce cahier des charges.

Conventions utilisées :

- **EF-xx** : exigence fonctionnelle. **ENF-xx** : exigence non fonctionnelle. **RG-xx** : règle de gestion (règle du jeu, invariante).
- Priorités : **[O]** obligatoire pour la v1.0 · **[S]** souhaitable · **[E]** évolution envisagée après v1.0.
- Les valeurs numériques suivies de `⚙️` sont des cibles d'équilibrage à valider en test, non des engagements contractuels.
- Chaque exigence obligatoire est associée à un critère d'acceptation vérifiable (§13).

---

# PARTIE I — LE PROJET

## 1. Contexte et genèse

### 1.1 Origine

Le projet naît d'une étude comparative de concepts de jeux mobiles conçus pour les trajets quotidiens (bus, métro), croisant game design, psychologie cognitive et neurosciences de la motivation. Le concept Volens en est ressorti comme le candidat au meilleur rapport originalité / risque : son principe d'émergence repose sur un modèle scientifique éprouvé (les *boids* de Reynolds, 1986), son besoin en contenu est faible, et sa qualité est mesurable objectivement (§12).

### 1.2 Le problème adressé

L'offre mobile pour les trajets se partage entre deux extrêmes également insatisfaisants pour le public visé :

- des jeux free-to-play construits sur des mécaniques de pression (timers, énergie, publicités, notifications) qui ajoutent du stress à un contexte déjà chargé ;
- des portages de jeux PC/console mal adaptés au format court, à l'usage à une main et aux interruptions imprévisibles.

Il manque une expérience **profonde mais interruptible**, exigeante intellectuellement mais indulgente pratiquement, conçue nativement pour dix minutes de bus.

### 1.3 Objectifs du projet

| # | Objectif | Indicateur de succès |
|---|---|---|
| O1 | Livrer un jeu premium complet et fini, sans mécanique d'engagement prédatrice | Liste de contrôle de livraison (§16) validée à 100 % |
| O2 | Faire exister une émergence réelle, pas un puzzle déguisé | Critère d'émergence (§12.2) satisfait sur 100 % des niveaux |
| O3 | Offrir la meilleure expérience d'interruption/reprise du marché mobile | Reprise utile en moins de 3 secondes, zéro perte d'état |
| O4 | Rester réalisable par une seule personne en environ 7 mois à temps partiel | Respect des jalons (§15) avec marge de 30 % |
| O5 | Atteindre l'équilibre financier sur les coûts directs | Revenus ≥ coûts de publication et d'outillage la première année |

### 1.4 Porteur du projet et parties prenantes

| Rôle | Titulaire |
|---|---|
| Porteur, concepteur, réalisateur | Développeur solo (maîtrise d'œuvre et d'ouvrage confondues) |
| Testeurs | Panel de 5 à 8 personnes pour les campagnes 1 et 2 ; **15 à 18** pour la campagne 3, fusionnée avec le test fermé Google Play *(v2.1, §13.3)* |
| Plateformes de distribution | **Google Play (Android uniquement en v1.0)** *(v2.1)* ; portage iOS envisagé en évolution post-v1.0 (§17) |

Le cumul maîtrise d'ouvrage / maîtrise d'œuvre est un risque identifié (perte de recul) : ce document sert précisément de garde-fou, et les décisions d'arbitrage devront pouvoir être justifiées par référence à ses principes (§4).

---

## 2. Périmètre

### 2.1 Inclus dans la v1.0

- Le jeu complet solo hors ligne : 6 chapitres, 70 niveaux minimum, 16 règles de comportement.
- L'interface portrait une main, l'accessibilité de base, la localisation français et anglais.
- La distribution sur **Android** en modèle *free-to-try* avec déblocage unique *(v2.1 : iOS retiré de la v1.0, voir §2.2 et §17)*.
- L'outillage interne de validation des niveaux (exigence de qualité, voir §12.3).

### 2.2 Exclu de la v1.0

Exclusions **fermes**, destinées à protéger le calendrier et la cohérence du produit :

| Exclusion | Motif |
|---|---|
| **Version iOS** *(v2.1, nouveau)* | Cohérence avec le choix technique du DCT (Android uniquement en v1.0) : concentrer le calendrier de 30 semaines sur une seule chaîne de publication (compte, signature, conformité). Portage envisagé en évolution si la trajectoire commerciale le justifie (§17) — Godot exporte nativement vers iOS, aucun choix technique actuel ne le condamne |
| Multijoueur, classements en ligne, comptes utilisateur | Contredit le principe hors ligne et explose la charge |
| Éditeur de niveaux accessible aux joueurs | Reporté en évolution (§17), candidat prioritaire |
| Narration, personnages, dialogues, univers scénarisé | Contredit la direction artistique abstraite |
| Version PC ou tablette optimisée | Le design est portrait une main ; un portage serait un autre produit |
| Télémétrie, mesure d'audience, tests A/B, notifications | Contredit les principes P1/P2 et le positionnement vie privée |
| Publicité, monnaie virtuelle, achats consommables | Contredit la contrainte fondatrice C6 |

---

## 3. Public, personas et contexte d'usage

### 3.1 Personas

**Persona primaire — « Karim », 34 ans, ingénieur qualité.**
45 minutes de trajet quotidien en bus, téléphone en main droite, sac sur les genoux. A désinstallé trois jeux F2P en un an, exaspéré par les publicités. Joue à des jeux de réflexion, a fini Mini Metro, a abandonné un Zach-like sur PC faute de temps. Attend : de la profondeur sans engagement contraint, une interruption sans pénalité, aucun bruit s'il a oublié ses écouteurs. Redoute : devoir « rattraper » quoi que ce soit après trois jours sans jouer.

**Persona secondaire — « Léa », 27 ans, doctorante.**
Joueuse de puzzles exigeants (Baba Is You, Opus Magnum). Cherche l'élégance des solutions plus que la complétion. Fera les défis optionnels, comparera ses solutions, sera la première à trouver les stratégies non prévues. C'est elle qui écrira l'avis détaillé sur le store — en bien ou en mal.

**Contre-persona — joueur casual de gratification immédiate.**
Volens lui demandera une minute d'observation avant sa première récompense. Il décrochera, et **le produit ne doit pas être déformé pour le retenir**. Ce renoncement est une décision de conception, opposable à toute demande future de simplification.

**Conséquence de `minSdk` 33 *(v2.1, B4)*.** Le jeu ne sera pas installable sur les appareils antérieurs à Android 13 (sortie fin 2022) — choix cohérent avec un public équipé récent comme Karim et Léa, mais qui réduit mécaniquement le parc adressable par rapport à un `minSdk` plus bas ; l'ampleur de cette réduction est à quantifier avant J-4 (DCT §13.1).

### 3.2 Contexte d'usage nominal

Le produit est spécifié pour son pire contexte, pas pour le meilleur :

| Dimension | Situation de référence |
|---|---|
| Lieu | Bus ou métro en mouvement, secousses, foule possible |
| Posture | Debout ou assis, **une seule main disponible**, l'autre tenant une barre ou un sac |
| Attention | Fragmentée : surveillance de l'arrêt, annonces, interpellations |
| Audio | Indisponible par défaut (pas d'écouteurs, environnement bruyant) |
| Connectivité | Intermittente ou absente (tunnels, zones blanches) |
| Durée | 5 à 20 minutes, **fin de session imprévisible et parfois immédiate** |
| Luminosité | Du plein soleil à la pénombre |

Toute fonctionnalité doit être validée dans ce contexte de référence (protocole §13.4), pas seulement au calme sur un bureau.

---

## 4. Principes directeurs

Ces principes sont l'arbitre du projet : **toute demande d'évolution, toute idée de fonctionnalité, tout arbitrage de conception se juge d'abord à leur aune.** Une proposition qui contredit un principe est rejetée par défaut ; l'inverser exige de réviser ce document.

Chaque principe s'appuie sur l'état actuel de la recherche, dont le détail figure en annexe A.

### P1 — Concevoir pour la reprise, pas pour la mémoire

La recherche récente invalide l'idée reçue selon laquelle on se souvient mieux des tâches inachevées ; ce qui est confirmé, c'est la **tendance à vouloir reprendre** une tâche interrompue (effet Ovsiankina). Le produit doit donc rendre la reprise **immédiate et sans effort de mémoire** : l'intégralité de l'état utile est toujours visible à l'écran, et rouvrir l'application restitue exactement la situation quittée. Le joueur ne doit jamais avoir à se souvenir de quoi que ce soit.

### P2 — Clôtures propres, tension à l'échelle supérieure

Formuler un plan crédible suffit à décharger la tension mentale d'un but non atteint (Masicampo & Baumeister, 2011). Le produit doit donc offrir des **points d'arrêt propres** (chaque niveau résolu clôt un cycle complet, sans incitation à enchaîner) tout en maintenant une tension légitime à l'échelle du chapitre : ce qui reste à explorer est montré, jamais rappelé de force. Toute mécanique de harcèlement (notification, série quotidienne, compteur culpabilisant) est proscrite.

### P3 — Plafond de charge cognitive : quatre éléments

La mémoire de travail traite environ quatre unités d'information simultanées — et le contexte d'usage (§3.2) en consomme déjà une partie. Le produit ne doit **jamais** exiger de garder à l'esprit plus de quatre éléments actifs. Cette limite est élevée au rang de mécanique centrale : la pile de règles compte exactement quatre emplacements.

### P4 — Déterminisme et lisibilité de l'échec

L'état de *flow* exige un but clair et un retour immédiat et non ambigu ; le sentiment de compétence exige que l'échec soit attribuable au joueur et à lui seul. Le produit doit donc être **rigoureusement déterministe** : mêmes choix, même déroulement, toujours, sur tout appareil. Aucun hasard ne doit jamais pouvoir servir d'excuse — ni de cause réelle — à un échec.

### P5 — L'autonomie avant l'optimisation

La motivation durable repose autant sur l'autonomie (choisir sa voie) que sur la compétence (réussir). Un niveau qui n'admet qu'une seule solution nie l'autonomie : c'est un défaut de conception, pas un niveau difficile. Chaque niveau doit admettre **plusieurs solutions structurellement distinctes** (critère mesurable en §12.2), et les défis optionnels doivent contraindre après coup plutôt que restreindre a priori.

### P6 — Vocabulaire de conception honnête

Aucune décision ne sera justifiée par « ça libère de la dopamine » ou tout autre raccourci neuro-marketing. Les justifications admissibles s'expriment en termes de compétence, d'autonomie, de charge cognitive, de clarté du retour d'information, ou de respect du contexte d'usage.

---

# PARTIE II — LE PRODUIT

## 5. Concept de jeu

### 5.1 Énoncé

> Le joueur ne contrôle jamais un individu. Il compose une **pile de quatre règles de comportement**, ordonnées par priorité, qui gouvernent simultanément tous les agents d'une nuée. Il lance ensuite la simulation et observe le comportement collectif qui en émerge — puis ajuste, relance, et affine jusqu'à satisfaire l'objectif du niveau.

Le geste fondamental du jeu n'est pas de résoudre un problème, mais de **concevoir le système qui le résout**. Le plaisir visé est celui de voir un comportement collectif riche naître de quatre décisions simples — y compris quand il naît de travers.

### 5.2 La règle d'or

> **L'ordre, c'est la priorité : pour chaque agent, à chaque instant, la première règle applicable l'emporte.**

Cette phrase contient tout le jeu. Elle doit pouvoir être comprise par l'expérience seule, en moins de deux niveaux, sans un mot d'explication (EF-40).

### 5.3 Ce que le jeu n'est pas

Pour lever toute ambiguïté auprès de futurs contributeurs ou testeurs : Volens n'est ni un jeu de stratégie en temps réel (on ne donne pas d'ordres), ni un tower defense (on ne place pas d'objets pendant l'action), ni un jeu d'adresse (aucun réflexe requis), ni un jeu contemplatif pur (chaque observation nourrit une décision).

---

## 6. Règles de gestion — la simulation

Les règles de gestion décrivent le comportement observable de la simulation. Elles sont **invariantes** : aucune option, aucun mode ne les modifie.

**RG-01.** Le monde est une grille de cases discrètes. Les agents occupent chacun une case et se déplacent d'une case à la fois, dans les quatre directions cardinales.

**RG-02.** Le temps s'écoule par pas discrets (« ticks »). Entre deux ticks, rien ne change.

**RG-03.** La simulation est déterministe au sens strict : un même niveau et une même pile de règles produisent une évolution identique, tick par tick, quel que soit l'appareil, la session ou le nombre de rejeux.

**RG-04.** Tous les agents sont identiques et interchangeables. Ils ne possèdent ni nom, ni statistiques, ni points de vie. Un agent perdu est une donnée du problème, pas un événement dramatique.

**RG-05.** À chaque tick, chaque agent évalue la pile de règles du premier au quatrième emplacement et adopte le mouvement proposé par la **première règle applicable** à sa situation. Si aucune règle ne s'applique, il reste immobile.

**RG-06.** Lorsque deux agents visent la même case au même tick, un critère de départage fixe et invariant s'applique ; l'agent non retenu reste immobile. Le joueur n'a pas besoin de connaître ce critère, mais il doit produire un résultat stable et identique à chaque rejeu.

**RG-07.** Les agents décident tous sur la base de l'état du monde **en début de tick** : aucun agent ne réagit, dans le même tick, au mouvement d'un autre.

**RG-08.** Les éléments dangereux de l'environnement sont soit statiques, soit cycliques à période fixe et visible. **Aucun élément du monde n'a de comportement aléatoire.**

**RG-09.** Un niveau se termine en succès dès que son objectif est atteint, et en échec si la limite de ticks du niveau est dépassée sans succès, ou si l'objectif devient mathématiquement inatteignable (par exemple : trop d'agents perdus pour un objectif de préservation). L'échec est un constat, jamais une punition : il n'entraîne aucune perte, aucun coût, aucun délai.

**RG-10.** Le joueur peut, à tout moment : mettre en pause, changer la vitesse de la simulation, avancer tick par tick, **revenir en arrière dans le temps** jusqu'au début de l'essai, et modifier sa pile puis relancer. Le nombre d'essais est illimité et n'est ni compté ni affiché comme un score.

---

## 7. Le système de règles de comportement

### 7.1 Principes de constitution de la bibliothèque

**RG-11.** La bibliothèque complète compte **16 règles** en v1.0, introduites progressivement (2 à 3 par chapitre). La progression du joueur est exclusivement l'expansion de cette bibliothèque : il n'existe ni points d'expérience, ni monnaie, ni objets.

**RG-12.** Chaque règle est exprimable par une icône et une phrase de **six mots au plus**, et son effet doit être observable et compréhensible en une seule simulation de démonstration.

**RG-13. Critère d'admission d'une règle** : une règle n'entre dans la bibliothèque que si elle crée un **conflit de priorité intéressant** avec au moins deux règles déjà présentes — c'est-à-dire si son placement avant ou après elles produit des comportements collectifs visiblement différents. Une règle qui n'engendre aucun dilemme d'ordonnancement est refusée, quelle que soit son élégance isolée.

### 7.2 Bibliothèque de règles (spécification comportementale)

Les descriptions ci-dessous définissent l'effet observable ; les paramètres chiffrés (portées, seuils, durées) sont des valeurs d'équilibrage `⚙️`.

**Chapitre 1 — le mouvement élémentaire.**

| Réf. | Nom de travail | Effet observable |
|---|---|---|
| R01 | Vers la lumière | L'agent se rapproche d'une case de la source de lumière la plus proche. |
| R02 | Fuir le rouge | L'agent s'éloigne du danger le plus proche s'il est à portée de perception `⚙️`. |
| R03 | Rester groupé | L'agent se rapproche du centre de gravité de ses voisins perçus `⚙️`. |

**Chapitre 2 — la coordination.**

| Réf. | Nom de travail | Effet observable |
|---|---|---|
| R04 | S'écarter | L'agent s'éloigne si sa case compte trop de voisins adjacents `⚙️`. |
| R05 | Suivre les voisins | L'agent adopte la direction majoritaire de ses voisins perçus. |
| R06 | Longer le mur | L'agent suit l'obstacle qu'il a à main droite. |

**Chapitre 3 — la mémoire du monde (stigmergie).**
C'est le tournant du jeu : l'environnement devient une mémoire partagée, et la nuée passe du réflexe à l'organisation.

| Réf. | Nom de travail | Effet observable |
|---|---|---|
| R07 | Attendre | L'agent reste immobile. (Sert de plancher volontaire ou de bouchon.) |
| R08 | Marquer la piste | L'agent dépose sur sa case un marqueur qui s'estompe après un délai fixe `⚙️`. |
| R09 | Suivre la piste | L'agent se dirige vers le marqueur voisin le plus intense. |

**Chapitre 4 — le transport.**

| Réf. | Nom de travail | Effet observable |
|---|---|---|
| R10 | Rebrousser si seul | L'agent fait demi-tour s'il ne perçoit aucun congénère. |
| R11 | Porter | L'agent ramasse la ressource présente sur sa case s'il n'en porte pas déjà. |
| R12 | Déposer au but | L'agent porteur dépose sa ressource sur une case de dépôt adjacente. |

**Chapitre 5 — le sacrifice et la régulation.**

| Réf. | Nom de travail | Effet observable |
|---|---|---|
| R13 | Boucher | L'agent occupe une case de danger et s'y consume, la neutralisant définitivement. |
| R14 | Disperser si dense | L'agent quitte les zones où la densité locale dépasse un seuil `⚙️`. |
| R15 | Suivre le plus lent | L'agent règle son avance sur le congénère le plus en retard qu'il perçoit. |

**Chapitre 6 — l'exception.**

| Réf. | Nom de travail | Effet observable |
|---|---|---|
| R16 | Ignorer (joker) | Neutralise, pour l'agent, l'effet d'un type de case choisi au placement de la règle. |

### 7.3 Dilemmes attendus

La profondeur du jeu naît de l'ordonnancement, pas du nombre de règles. À titre de spécification du comportement attendu, les quatre ordonnancements suivants des seules règles du chapitre 1 doivent produire quatre nuées **visiblement et stratégiquement différentes** :

| Pile | Caractère émergent attendu |
|---|---|
| Fuir > Grouper > Lumière | Nuée prudente : se disperse au danger, se reforme, progresse lentement. |
| Grouper > Fuir > Lumière | Nuée grégaire : soudée, traverse les dangers en bloc, rapide mais coûteuse. |
| Lumière > Fuir > Grouper | Nuée pressée : fonce, se fait faucher au premier piège. Erreur instructive. |
| Fuir > Lumière > (vide) | Nuée individualiste : chacun pour soi, arrivées dispersées. |

Si ces quatre piles ne produisent pas quatre comportements nettement distincts, le paramétrage des règles est à revoir : c'est un **critère d'acceptation du chapitre 1** (§13.1).

Le dilemme archétypal que le level design doit constamment mettre en scène : **sacrifier la marge (des agents, du temps) pour la performance, ou protéger tout le monde au risque de manquer l'objectif.**

---

## 8. Les niveaux

### 8.1 Composition d'un niveau

**RG-14.** Un niveau se compose de : une grille (plus haute que large, format portrait), une nuée de 20 à 50 agents `⚙️` en position initiale fixe, un ou plusieurs objectifs, une limite de ticks, un sous-ensemble de la bibliothèque de règles disponible, et des éléments d'environnement parmi le vocabulaire suivant :

| Élément | Comportement |
|---|---|
| Mur | Infranchissable. |
| Sortie | Un agent qui l'atteint quitte le niveau (compté « sorti »). |
| Danger statique | Un agent qui y entre est perdu. |
| Danger cyclique | Actif/inactif selon un cycle fixe, **visible et prévisible** à l'écran. |
| Ressource | Peut être portée (R11) et déposée (R12). |
| Case de dépôt | Destination des ressources. |
| Porte à pression | S'ouvre tant qu'un nombre requis d'agents `⚙️` occupe ses cases de commande. |
| Sens unique | Franchissable dans une seule direction. |
| Source de lumière | Cible de la règle R01 ; certains niveaux en comptent plusieurs. |

Ce vocabulaire de neuf éléments est **fermé pour la v1.0** : la variété doit naître de la combinaison, pas de l'inflation.

### 8.2 Types d'objectifs

**RG-15.** Chaque niveau porte un ou deux objectifs parmi :

1. **Extraction** — faire sortir au moins X % de la nuée.
2. **Collecte** — livrer N ressources aux cases de dépôt.
3. **Préservation** — ne pas perdre plus de K agents.
4. **Célérité** — réussir en moins de T ticks (ticks de simulation, jamais de temps réel).
5. **Interdiction** — qu'aucun agent n'entre jamais dans une zone désignée.

**RG-16.** À partir du chapitre 2, la majorité des niveaux `⚙️` porte un **objectif composé** : deux objectifs dont la satisfaction simultanée exige un arbitrage (extraction rapide *vs* préservation, collecte *vs* interdiction…). L'objectif composé est le format de référence du jeu, car il garantit le dilemme.

**RG-17.** L'énoncé de l'objectif tient en une ligne, reste affiché en permanence pendant le jeu, et l'état d'avancement vers chaque objectif est visible en continu (« 26/32 sortis », « pertes : 2/5 max »).

### 8.3 Défis optionnels

**RG-18.** Chaque niveau résolu révèle trois défis facultatifs :
- **Économie** : résoudre avec trois emplacements au plus.
- **Abstinence** : résoudre sans une règle désignée.
- **Efficience** : résoudre sous un seuil de ticks proche de l'optimum connu.

**RG-19.** Aucun défi ne conditionne jamais la progression. Les défis n'existent que pour nourrir la maîtrise (P5) ; leur accomplissement est marqué sobrement, sans récompense matérielle.

### 8.4 Structure et volume du contenu

| Élément | Cible v1.0 |
|---|---|
| Chapitres | 6 |
| Niveaux | 70 minimum, dont un niveau final « examen » par chapitre |
| Règles | 16, introduites 2-3 par chapitre |
| Défis optionnels | 3 par niveau, soit 210+ |
| Durée de vie (parcours principal) | 8 à 12 heures |
| Durée de vie (avec défis) | 15 à 20 heures |

**RG-20.** Un chapitre se débloque en résolvant un pourcentage `⚙️` — et non la totalité — des niveaux du précédent : un joueur bloqué sur un niveau doit toujours avoir un autre front ouvert (P2, P5).

### 8.5 Rampe d'apprentissage (chapitre 1)

Le chapitre 1 est un tutoriel invisible. **Aucun texte pédagogique** n'est autorisé au-delà des libellés de règles et des énoncés d'objectifs ; tout s'enseigne par la structure des niveaux :

| Niveau | Dispositif | Leçon |
|---|---|---|
| 1 | Un seul emplacement, une seule règle disponible | « Une règle gouverne tout le monde à la fois. » |
| 2 | Deux emplacements, deux règles ; les deux ordres possibles donnent deux résultats opposés, testables en 20 secondes chacun | **« L'ordre change tout. »** — la leçon centrale |
| 3 | Trois emplacements, apparition de la cohésion | Le compromis vitesse / sécurité |
| 4 | Premier objectif composé | L'arbitrage |
| 5 | Niveau ouvert, plusieurs solutions ; l'écran de bilan mentionne « 7 solutions connues » | « Il n'y a pas LA bonne réponse. » (P5) |

---

## 9. Exigences fonctionnelles

### 9.1 Conduite de la simulation

**EF-01 [O]** Le joueur compose sa pile en plaçant, retirant et réordonnant des règles dans quatre emplacements, par manipulation directe (glisser-déposer), y compris pendant une pause en cours d'essai.

**EF-02 [O]** Le joueur lance, met en pause et relance la simulation à volonté. Trois vitesses de lecture au moins sont proposées `⚙️`.

**EF-03 [O]** Le joueur peut avancer tick par tick et **remonter le temps** jusqu'au début de l'essai en cours, par pas et en continu.

**EF-04 [O]** Le joueur peut réinitialiser l'essai (agents en position initiale, pile conservée) en une seule action.

**EF-05 [O]** En pause, toucher un agent affiche quelle règle de la pile a dicté son dernier mouvement, et pourquoi les règles précédentes ne s'appliquaient pas. C'est le principal outil de diagnostic (P4) : l'échec doit toujours être explicable.

**EF-06 [S]** En pause, le joueur peut afficher les zones de perception (portées des règles) en surimpression, pour comprendre ce que « voit » un agent.

**EF-07 [O]** L'écran de bilan d'un niveau résolu présente : l'objectif atteint, les ticks consommés, les agents perdus, la pile utilisée, les trois défis, et propose sans insistance de continuer ou de s'arrêter (P2).

### 9.2 Navigation et structure

**EF-10 [O]** L'écran d'accueil mène en un geste au niveau en cours ; la carte des chapitres montre d'un coup d'œil l'avancement, les niveaux ouverts et les défis restants — sans compteur culpabilisant ni badge d'appel (P2).

**EF-11 [O]** Chaque niveau déjà résolu reste rejouable librement, avec mémorisation de la meilleure performance par défi.

**EF-12 [O]** Une encyclopédie des règles débloquées est consultable hors partie : pour chaque règle, l'icône, la phrase, et une **démonstration animée** sur une vignette de simulation.

**EF-13 [S]** L'écran de bilan permet de nommer et d'archiver une pile réussie, pour la retrouver et la réessayer ailleurs.

### 9.3 Interruption et reprise — cœur de l'expérience

**EF-20 [O]** Toute fermeture de l'application — volontaire, système, ou brutale — préserve intégralement : le niveau en cours, la pile composée, l'avancement exact de l'essai (tick courant), l'état de pause et la vitesse choisie.

**EF-21 [O]** À la réouverture, l'application restitue **exactement** l'écran quitté, simulation **en pause**, en moins de 3 secondes entre le lancement et le premier geste utile possible. Aucun écran intermédiaire (logo prolongé, actualités, offre) ne s'interpose.

**EF-22 [O]** À la reprise, l'objectif du niveau est brièvement re-signalé par une mise en évidence discrète, sans dialogue à fermer.

**EF-23 [O]** Le produit n'émet **aucune notification**, de quelque nature que ce soit. Il ne demande jamais la permission de le faire.

**EF-24 [O]** Aucun élément du jeu ne dépend du temps réel : ni minuterie, ni événement daté, ni contenu quotidien, ni bonus de connexion. Trois semaines d'absence ne changent strictement rien à l'état du jeu.

### 9.4 Aide au joueur bloqué

**EF-30 [O]** L'aide est graduée et à l'initiative exclusive du joueur — jamais proposée spontanément après des échecs :
1. revoir la démonstration d'une règle (EF-12) ;
2. demander un **indice structurel** : le jeu révèle une des règles présentes dans au moins une solution connue, sans indiquer sa position dans la pile ;
3. passer le niveau (RG-20 garantit qu'un autre front est ouvert).

**EF-31 [O]** L'usage d'un indice n'est ni pénalisé, ni marqué sur le niveau. Aucune aide n'est payante (C6).

### 9.5 Premier contact

**EF-40 [O]** Le premier lancement mène au niveau 1 en moins de 10 secondes, sans création de compte, sans demande de permission, sans écran de réglage préalable. La règle d'or (§5.2) doit être acquise par l'expérience des niveaux 1 et 2, sans texte pédagogique — critère vérifié en test (§13.1).

**EF-41 [O]** La partie gratuite (chapitre 1 complet) se joue sans aucune sollicitation d'achat. L'offre de déblocage n'apparaît qu'à la fin du chapitre 1, une fois, puis reste accessible passivement depuis l'accueil.

---

## 10. Exigences non fonctionnelles

### 10.1 Contraintes fondatrices

| Réf. | Exigence | Priorité |
|---|---|---|
| **ENF-01** | Jouable intégralement **d'une seule main, en orientation portrait** exclusive. Toute commande de jeu se situe dans la zone atteignable par le pouce (moitié basse de l'écran) ; les cibles tactiles respectent les minima des plateformes (≈ 48 dp / 44 pt). | [O] |
| **ENF-02** | Jouable intégralement **son coupé** : aucune information n'est portée par le seul canal audio. | [O] |
| **ENF-03** | Jouable intégralement **hors ligne**, sans compte, du premier lancement à la fin du jeu. Seul l'acte d'achat requiert une connexion. | [O] |
| **ENF-04** | **Interruptible sans coût** à tout instant (voir EF-20 à EF-24). | [O] |
| **ENF-05** | **Déterminisme total** (RG-03), vérifiable par reproduction à l'identique d'une même partie sur des appareils différents. | [O] |
| **ENF-06** | **Aucune publicité, aucun achat consommable, aucune mécanique d'engagement** (timers réels, énergie, séries, notifications, FOMO). | [O] |

### 10.2 Performance et sobriété

| Réf. | Exigence | Priorité |
|---|---|---|
| ENF-10 | Fluidité constante (60 images/s) sur un téléphone de milieu de gamme d'environ 4 ans d'âge, défini comme appareil de référence au démarrage du projet. | [O] |
| ENF-11 | Taille d'installation inférieure à 60 Mo. | [O] |
| ENF-12 | Consommation d'énergie minimale : aucun calcul ni rendu superflu lorsque la simulation est en pause ; palette sombre dominante (économie sur écrans OLED). | [O] |
| ENF-13 | Lancement à froid en moins de 3 secondes sur l'appareil de référence. | [O] |
| ENF-14 | Aucune dégradation perceptible avec la nuée maximale (50 agents) et tous les effets actifs. | [O] |

### 10.3 Accessibilité

| Réf. | Exigence | Priorité |
|---|---|---|
| ENF-20 | Aucune information portée par la seule couleur : le danger, les pistes et les états d'agents sont doublés par la forme, la texture ou le mouvement. Vérification pour les trois dyschromatopsies principales. | [O] |
| ENF-21 | Mode contraste élevé. | [O] |
| ENF-22 | Mode réduction des animations (traînées, particules, pulsations désactivables) sans perte d'information de jeu. | [O] |
| ENF-23 | Respect de la taille de police système pour tous les textes. | [O] |
| ENF-24 | Retour haptique présent mais désactivable ; jamais porteur d'information exclusive. | [O] |
| ENF-25 | Aucune interaction n'exige un appui maintenu précis, un double appui rapide ou un geste multipoint. | [O] |

### 10.4 Vie privée et données

| Réf. | Exigence | Priorité |
|---|---|---|
| ENF-30 | **Aucune collecte de données** : pas de mesure d'audience, pas de traceur, pas d'identifiant publicitaire, pas de rapport d'incident transmis sans action volontaire du joueur. | [O] |
| ENF-31 | Toutes les données (progression, réglages, statistiques personnelles) résident sur l'appareil et appartiennent au joueur. | [O] |
| ENF-32 | L'export et l'effacement complets des données locales sont accessibles depuis les réglages. | [S] |
| ENF-33 | La politique de confidentialité tient sur une page et est lisible par un non-juriste — le positionnement « zéro collecte » doit la rendre triviale. | [O] |

### 10.5 Localisation

| Réf. | Exigence | Priorité |
|---|---|---|
| ENF-40 | Français et anglais complets en v1.0, à parité de qualité. | [O] |
| ENF-41 | Le volume de texte est structurellement minimal (libellés ≤ 6 mots, énoncés ≤ 1 ligne) : l'ajout d'une langue ne doit représenter que quelques centaines de mots. | [O] |

---

## 11. Direction artistique et sonore (intentions)

Cette section fixe des intentions et des critères de jugement, pas des choix de production.

### 11.1 Registre visuel

**Intention : l'esthétique de la donnée vivante.** Abstrait, sobre, contemplatif — le beau doit naître du **mouvement collectif**, pas de l'ornement. Références de ton : Mini Metro, Osmos, la visualisation scientifique de qualité. Anti-références : le mignon, le gamifié, le chargé.

Critères de jugement :
- **DA-01.** Le personnage principal est la nuée : sa forme collective en mouvement doit être belle et **informative** à la fois — un joueur expérimenté doit pouvoir diagnostiquer sa pile d'un regard sur la silhouette de la nuée.
- **DA-02.** Fond très sombre, agents lumineux, hiérarchie visuelle stricte : but > danger > nuée > décor. En plein soleil, ces quatre plans restent discernables (testé en §13.4).
- **DA-03.** Chaque état de jeu (marche, pause, succès, échec) est identifiable en une demi-seconde sans lire aucun texte.
- **DA-04.** Une capture d'écran quelconque du jeu doit être identifiable comme Volens — la signature visuelle est un actif marketing (§14.3).

### 11.2 Registre sonore

**Intention : le son comme conséquence, jamais comme canal.** L'audio traduit l'état de la simulation (densité, réussites individuelles, tension) en une matière sonore générative et apaisante ; il récompense le joueur équipé d'écouteurs sans rien retirer aux autres (ENF-02).

- **DS-01.** Une nuée qui réussit doit *sonner* comme une réussite : la progression vers l'objectif s'entend.
- **DS-02.** Silence en pause. Aucune boucle musicale imposée.
- **DS-03.** Aucun son d'alarme, de compte à rebours ou de pression : le registre reste du côté du calme, y compris dans l'échec.

---

# PARTIE III — QUALITÉ, CADRE ET CONDUITE

## 12. Exigences de qualité du contenu

Cette section est la plus importante du document après les principes : elle définit **ce qui distingue un bon niveau d'Volens d'un mauvais**, de manière mesurable.

### 12.1 Le risque à conjurer

Le défaut fatal du concept est identifié dès l'origine : produire des niveaux à **solution unique**, c'est-à-dire des puzzles déguisés en systèmes émergents. Un tel niveau viole le principe P5, trompe la promesse du jeu et sera détecté par le public cible (persona Léa) dès les premiers avis. La qualité du contenu ne peut donc pas reposer sur le seul jugement du concepteur : elle doit être **mesurée**.

### 12.2 Critères de qualité d'un niveau

Le déterminisme (RG-03) et la finitude de l'espace des piles rendent ces critères objectivement vérifiables pour chaque niveau :

| Réf. | Critère | Seuil |
|---|---|---|
| **QN-01** | Nombre de piles gagnantes structurellement distinctes (hors variantes triviales : permutations d'emplacements sans effet, règles inertes) | **entre 3 et 40** `⚙️` |
| **QN-02** | Absence de stratégie dominante : aucune pile ne doit résoudre à elle seule tous les niveaux d'un même chapitre | obligatoire |
| **QN-03** | Densité d'« échecs proches » (piles échouant à moins de 10 % de l'objectif) — mesure la frustration productive : un niveau où l'on échoue de peu donne envie de réessayer, un niveau où tout échoue de loin décourage | seuil plancher `⚙️` |
| **QN-04** | Existence d'une solution notablement plus efficiente que la moyenne, servant d'étalon au défi Efficience | obligatoire |
| **QN-05** | Nombre d'essais attendus avant première résolution pour un joueur du niveau visé | 3 à 8 `⚙️` |

**Verdicts associés :** zéro pile gagnante → niveau insoluble, rejeté. Une seule → puzzle déguisé, rejeté ou retravaillé. Plus de 100 → niveau creux, contraintes à durcir. Stratégie dominante sur un chapitre → chapitre cassé, à rééquilibrer.

### 12.3 Exigence d'outillage

**EQ-01 [O]** Le projet doit se doter d'un **outil interne de validation** capable, pour tout niveau, d'explorer exhaustivement l'espace des piles possibles et de produire un rapport sur les critères QN-01 à QN-05. La faisabilité de cet outil découle directement des règles RG-03 (déterminisme) et RG-05 (espace fini de piles) — c'est l'une des raisons d'être de ces règles.

**EQ-02 [O]** Aucun niveau n'entre dans la version livrée sans un rapport de validation conforme. Le rapport de l'ensemble du catalogue fait partie des livrables de fin de production (§15).

**EQ-03 [O]** Toute modification d'une règle de comportement ou d'un paramètre d'équilibrage déclenche la revalidation de tous les niveaux utilisant cette règle.

### 12.4 Qualité de l'équilibrage des règles

**EQ-04 [O]** Chaque règle de la bibliothèque doit apparaître dans au moins une solution connue d'au moins trois niveaux `⚙️` de son chapitre d'introduction : une règle que l'espace des solutions ignore est une règle morte, à retravailler ou retirer.

**EQ-05 [O]** Le test des quatre piles du §7.3 (quatre comportements visiblement distincts avec les seules règles du chapitre 1) constitue le critère d'acceptation du paramétrage de base.

---

## 13. Validation et campagnes de test

### 13.1 Campagne 1 — la porte de décision (fin de prototype)

**Objet.** Décider de la poursuite du projet. **C'est un vrai point d'arrêt : un échec entraîne le pivot ou l'abandon, pas l'aménagement.**

**Protocole.** 5 à 8 testeurs correspondant aux personas, individuellement, sur les 5 niveaux du chapitre 1, en observation silencieuse, sans aucune aide verbale. Entretien après coup.

| Critère | Seuil de succès | Interprétation d'un échec |
|---|---|---|
| **Émergence** : part des testeurs trouvant au moins deux solutions distinctes à un même niveau | **≥ 60 %** | Le jeu est un puzzle déguisé → **pivot** |
| **Règle d'or** : part des testeurs formulant correctement « la première règle applicable gagne » après le niveau 2, sans qu'on la leur ait énoncée | ≥ 70 % | Retravailler les niveaux 1-2 — pas ajouter de texte |
| **Envie de reprise** : part des testeurs relançant spontanément après un échec | ≥ 80 % | Le retour d'échec est opaque (renforcer EF-05) |
| **Reprise après interruption** : après interruption forcée de 2 minutes, reprise utile en moins de 10 secondes | 100 % | L'état visible est insuffisant (P1) |

### 13.2 Campagne 2 — tranche verticale (chapitres 1-2 complets)

Vérifie : la courbe de difficulté (QN-05 mesuré sur de vrais joueurs), la lisibilité de la stigmergie (chapitre 3 en préversion), la tenue des défis optionnels, la compréhension de l'écran de bilan, et l'accueil de l'offre de déblocage (EF-41) — perçue comme légitime ou comme intrusive.

### 13.3 Campagne 3 — bêta de contenu (catalogue complet)

Vérifie : la durée de vie réelle, les pics de difficulté non détectés par l'outil de validation (l'outil mesure l'espace des solutions, pas la capacité humaine à les trouver — les deux doivent être confrontés), l'usure éventuelle du plaisir sur 8-12 heures, l'usage réel des indices (EF-30).

**Fusion avec le test fermé Google Play *(v2.1, B2).*** Cette campagne est confondue avec la piste de test fermé exigée par Google Play (§14.4) : elle requiert **15 à 18 testeurs recrutés**, une marge délibérée au-dessus du minimum de 12 imposé par la plateforme — un désistement en cours de période fait sinon repartir le compteur de 14 jours consécutifs à zéro.

### 13.4 Test en conditions réelles — obligatoire à chaque campagne

À mener **réellement en bus ou en métro**, pas en simulation :
- jouabilité à une main, main gauche puis main droite, debout ;
- lisibilité en plein soleil et à luminosité minimale ;
- fiabilité des gestes en environnement secoué ;
- fermeture brutale à un moment quelconque → réouverture → conformité EF-20/EF-21 constatée ;
- une session complète de trajet réel (15-20 min) sans frustration liée au contexte.

### 13.5 Vérifications de conformité continue

À chaque étape de production : reproduction déterministe d'un jeu de parties de référence sur **deux architectures CPU distinctes — arm64 (appareil physique) et x86_64 (émulateur, CI)** *(v2.1, reformulé — voir §16 et DCT §11.2, A6)* ; contrôle d'accessibilité (ENF-20 à ENF-25) ; contrôle du budget de poids et de performance (ENF-10 à ENF-14).

---

## 14. Cadre commercial et réglementaire

### 14.1 Modèle économique

**Modèle retenu : essai gratuit + déblocage unique.** Le chapitre 1 (5 niveaux) est gratuit et complet ; le déblocage de l'intégralité du jeu est un achat unique à **4,99 €** `⚙️`.

**Justification.** Le premium mobile est en croissance (+77 % de sorties en 2025) mais reste une niche face au free-to-play (96 % des téléchargements) ; sa principale faiblesse est la conversion sur la page du store. Un jeu abstrait sans notoriété préalable ne se vend pas sur des captures d'écran : il se vend en dix minutes de jeu. Le modèle essai-puis-déblocage est celui qu'ont adopté les éditeurs spécialistes du premium mobile pour cette raison exacte.

**Interdits absolus (rappel ENF-06)** : publicité, monnaie virtuelle, énergie, minuteries réelles, loot boxes, achat d'indices ou d'avantages. Toute recette future ne peut provenir que de **contenu** (packs de chapitres additionnels, cf. §17).

### 14.2 Objectifs commerciaux réalistes

Le marché impose la lucidité : plus de 1,4 million d'applications sont sorties en 2025 sur les deux stores et environ 10 % seulement ont attiré la moindre attention. Les succès premium visibles (Balatro, Dead Cells) s'appuient sur une notoriété PC préexistante et ne constituent pas une référence de prévision.

| Scénario | Déblocages année 1 | Lecture |
|---|---|---|
| Plancher | 500 | Équilibre des coûts directs (O5) non atteint — bilan et décision sur la suite |
| Nominal | 2 000 – 5 000 | Projet viable en activité annexe, extension justifiée |
| Haut | > 15 000 | Nécessite un relais de visibilité (presse, vidéaste, mise en avant store) non maîtrisable |

### 14.3 Visibilité

**20 % du temps de production** est réservé, dès la tranche verticale, à la visibilité : journal de développement public régulier, courtes vidéos de nuées en mouvement (le comportement émergent est intrinsèquement « capturable » — c'est le premier atout marketing du produit, cf. DA-04), présence sur les communautés de jeux de réflexion et de simulation. Ce budget de temps est protégé au même titre qu'un jalon de production.

### 14.4 Conformité réglementaire et plateformes

| Obligation | Contenu | Échéance |
|---|---|---|
| Exigence de niveau d'API Google Play | Toute nouvelle application doit cibler **Android 16 (API 36)**, `minSdk` **33** *(v2.1)* | **31 août 2026** — à intégrer dès le premier livrable technique |
| Compte développeur *(v2.1)* | Google (25 $ une fois) — **déjà réglé et vérifié**, avant l'engagement de la production. Apple hors périmètre v1.0 (§2.2) | — |
| Test fermé Google Play *(v2.1, nouveau — A4)* | **12 testeurs minimum, inscrits 14 jours consécutifs**, préalable obligatoire à la demande d'accès production (comptes personnels créés après le 13/11/2023) | Avant la demande d'accès production |
| Déclarations de confidentialité des stores | Data Safety (Google) — triviale ici grâce à ENF-30 | Avant soumission |
| Politique de confidentialité publique | Une page, conforme ENF-33 | Avant soumission |
| Déclaration de contenu généré par IA (Google Play) | Applicable si des contenus livrés sont générés par IA | Avant soumission |
| RGPD | Position « aucune collecte » (ENF-30) : pas de traitement de données personnelles hors achat, géré par les stores | Continu |
| Classification d'âge | Contenu abstrait sans violence figurative : classification tous publics attendue (PEGI 3 / Everyone) | À la soumission |

**Note de propriété intellectuelle.** Les productions purement générées par IA sur simple instruction ne sont pas protégeables par le droit d'auteur (position de l'US Copyright Office, janvier 2025). Les éléments identitaires du produit — nom, logo, iconographie des règles, identité visuelle — doivent donc comporter un apport créatif humain substantiel et documenté. Le nom « Volens » fera l'objet d'une recherche d'antériorité (marques, jeux existants, disponibilité des identifiants de stores) avant l'engagement de la production ; c'est un livrable du premier jalon.

---

## 15. Jalons, livrables et décisions

Calendrier indicatif pour une personne seule à temps partiel (~15 h/semaine). Les durées portent une marge implicite ; les jalons J1 et J2 sont des **points de décision**, pas des formalités.

| Jalon | Horizon | Livrables | Décision associée |
|---|---|---|---|
| **J0 — Cadrage** | Semaine 1 | Ce cahier des charges validé ; recherche d'antériorité du nom ; définition de l'appareil de référence | Engagement du prototype |
| **J1 — Prototype** | Semaine 3 | Chapitre 1 jouable (5 niveaux, 3 règles) ; outil de validation opérationnel sur ces niveaux ; campagne 1 réalisée | **GO / PIVOT / STOP** selon §13.1 — interdiction de continuer « pour voir » |
| **J2 — Tranche verticale** | Semaine 9 | Chapitres 1-2 complets et finis (interface définitive, audio, sauvegarde, accessibilité de base) ; campagne 2 ; test transport | GO production, ou révision du périmètre |
| **J3 — Contenu complet** | Semaine 20 | 70+ niveaux, 16 règles, rapports de validation conformes sur 100 % du catalogue ; campagne 3 engagée | Gel du contenu |
| **J4 — Candidate à la livraison** | Semaine 26 | Localisation, accessibilité complète, performance conforme, liste §16 tenue | Gel de la version |
| **J5 — Publication** | Semaine 30 | Conformité stores validée, pages de store, lancement | — |

**Règle de conduite J2 :** si, à la fin de la tranche verticale, le concepteur lui-même n'a plus de plaisir à équilibrer et rejouer son propre jeu, ce signal prime sur tout indicateur — c'est le prédicteur le plus fiable de l'intérêt du public.

---

## 16. Critères d'acceptation de la version 1.0

La version 1.0 est livrable quand **chacun** de ces points est constaté :

**Contenu et qualité**
- [ ] 70 niveaux minimum, chacun couvert par un rapport de validation conforme (QN-01 à QN-05)
- [ ] Aucune stratégie dominante sur aucun chapitre (QN-02)
- [ ] Chaque règle vivante au sens d'EQ-04 ; test des quatre piles (EQ-05) concluant
- [ ] Les trois campagnes de test réalisées, critères de la campagne 1 archivés

**Expérience**
- [ ] Reprise après fermeture brutale : état identique, en moins de 3 s (EF-20/21), constaté sur l'appareil de référence *(v2.1 : « les deux plateformes » retiré — Android uniquement en v1.0, §2.2)*
- [ ] Parcours complet réalisable : une main, portrait, son coupé, hors ligne, du premier lancement au dernier niveau
- [ ] Zéro notification, zéro minuterie réelle, zéro sollicitation d'achat hors EF-41
- [ ] Test en transport réel (§13.4) validé sur la version candidate

**Technique et conformité** *(v2.1, B1 — cibles avec marge : l'appareil de référence est un flagship, les seuils bruts n'y sont pas informatifs)*
- [ ] **60 i/s à 4× le nombre d'agents cible** ; temps d'image **< 4 ms** ; démarrage à froid **< 1,5 s** ; reprise **< 1,5 s** ; poids **< 60 Mo** (ENF-10/11/13)
- [ ] Sobriété (ENF-12) mesurée en **écart** de consommation simulation/pause, jamais en autonomie absolue
- [ ] Déterminisme constaté sur **deux architectures CPU distinctes** — arm64 (appareil de référence) et x86_64 (émulateur + CI) — complété par la collecte manuelle d'empreintes du parc de testeurs lors du test fermé (ENF-05, DCT §11.2/§13.3 bis)
- [ ] Accessibilité ENF-20 à ENF-25 vérifiée
- [ ] Français et anglais complets à parité (ENF-40)
- [ ] API 36, `minSdk` 33, déclaration de confidentialité Google Play, politique de confidentialité en ligne, classification d'âge obtenue

---

## 17. Évolutions envisagées (après v1.0)

Par ordre de priorité pressenti, sans engagement :

1. **Partage de solutions par code court** — une pile + un niveau tiennent en quelques caractères ; le partage entre joueurs est le prolongement naturel de P5 et un vecteur de bouche-à-oreille quasi gratuit.
2. **Éditeur de niveaux joueur**, adossé à l'outil de validation (un niveau créé serait auto-évalué selon §12.2 avant partage).
3. **Pack de chapitres additionnels** (contenu payant, jamais d'avantage) — si le scénario commercial nominal est atteint.
4. **Défis hebdomadaires hors ligne** — un niveau commun préchargé, sans classement en ligne ni date limite réelle, pour ne pas contredire EF-24.
5. Langues supplémentaires (le coût est structurellement faible, ENF-41).
6. **Portage iOS** *(v2.1, nouveau)* — retiré de la v1.0 pour concentrer le calendrier sur une seule chaîne de publication (§2.2) ; aucun choix technique actuel ne le condamne (DCT §1.6), à réévaluer si le scénario commercial nominal est atteint.

---

## 18. Glossaire

| Terme | Définition |
|---|---|
| **Agent** | Individu de la nuée. Anonyme, sans caractéristiques propres. |
| **Nuée** | L'ensemble des agents d'un niveau ; le « personnage » réel du jeu. |
| **Règle (de comportement)** | Instruction élémentaire de la bibliothèque, plaçable dans la pile. |
| **Pile** | Les quatre emplacements ordonnés de règles composés par le joueur. |
| **Priorité** | Position dans la pile ; la première règle applicable l'emporte (règle d'or). |
| **Tick** | Unité de temps discrète de la simulation. |
| **Essai** | Une exécution de la simulation, du lancement à l'arrêt ou à la fin. |
| **Émergence** | Comportement collectif non explicitement programmé, né de l'interaction des règles. |
| **Stigmergie** | Coordination indirecte par traces laissées dans l'environnement (règles R08/R09). |
| **Micro-clôture** | Point d'arrêt propre en fin de niveau, sans tension résiduelle (P2). |
| **Solution structurellement distincte** | Pile gagnante qui n'est pas une variante triviale d'une autre (QN-01). |
| **Stratégie dominante** | Pile qui résout tous les niveaux d'un chapitre ; défaut disqualifiant (QN-02). |
| **Objectif composé** | Deux objectifs simultanés exigeant un arbitrage (RG-16). |
| **Puzzle déguisé** | Niveau à solution unique se faisant passer pour un système ouvert ; le défaut fatal du projet (§12.1). |

---

## Annexe A — Fondements scientifiques des principes

| Fondement | Statut | Principe(s) nourri(s) |
|---|---|---|
| **Effet Zeigarnik** (avantage mnésique des tâches inachevées) | **Non répliqué** — méta-analyse Ghibellini & Meier, 2025, *Humanities and Social Sciences Communications* : ratio de rappel ≈ 0,99 | Aucun. Explicitement écarté des justifications de conception |
| **Effet Ovsiankina** (tendance à reprendre les tâches interrompues) | Confirmé par la même méta-analyse | **P1** — faciliter la reprise plutôt que compter sur la mémoire |
| **Masicampo & Baumeister, 2011** (formuler un plan décharge la tension d'un but ouvert) | Solide | **P2** — clôtures propres, tension sans harcèlement |
| **Théorie de la charge cognitive** (Sweller) ; capacité de la mémoire de travail ≈ 4 unités (et non 7±2) | Solide | **P3** — quatre emplacements, zéro mémorisation exigée |
| **Flow** (Csikszentmihalyi) : but clair, retour immédiat, équilibre défi/compétence | Solide sur ses conditions | **P4** — déterminisme, diagnostic de l'échec (EF-05) |
| **Théorie de l'autodétermination / modèle PENS** (Deci & Ryan ; Ryan, Rigby & Przybylski, 2006) : compétence, autonomie, affiliation | Solide | **P4** (compétence) et **P5** (autonomie) ; l'affiliation, faible en v1.0, motive l'évolution n°1 du §17 |
| **Boids** (Reynolds, 1986) : trois règles locales suffisent à un comportement collectif riche | Modèle canonique de l'émergence | Garantie de faisabilité du concept lui-même |
| **« Dopamine »** : signal d'erreur de prédiction de récompense (Schultz), distinction wanting/liking (Berridge & Robinson) — pas un « shot de plaisir » | Consensus neuroscientifique | **P6** — bannie du vocabulaire de justification |

## Annexe B — Traçabilité principes → exigences

| Principe | Exigences principales qui l'incarnent |
|---|---|
| P1 (reprise) | EF-20 à EF-22, RG-17, ENF-04, critère « reprise » §13.1 |
| P2 (clôtures propres) | EF-07, EF-10, EF-23, EF-24, RG-20 |
| P3 (charge cognitive) | RG-05 (4 emplacements), RG-12 (6 mots), RG-17 (état visible), ENF-01 |
| P4 (déterminisme, échec lisible) | RG-03, RG-06 à RG-08, EF-03, EF-05, ENF-05, QN-03 |
| P5 (autonomie) | QN-01, QN-02, RG-18/19, RG-20, EF-30, niveau 1.5 (§8.5) |
| P6 (vocabulaire honnête) | S'applique à la conduite du projet et aux révisions de ce document |

---

## Historique des révisions *(v2.1)*

| Version | Date | Changements | Motif |
|---|---|---|---|
| 2.0 | 2 août 2026 | Version de référence | — |
| 2.1 | 4 août 2026 | Retrait d'iOS du périmètre v1.0 (§1.4, §2.1, §2.2, §14.4, §16, §17 — cohérence avec le choix technique déjà tranché par le DCT, Android uniquement) ; testeurs de la campagne 3 portés à 15-18 et fusion avec le test fermé Google Play (§1.4, §13.3, §14.4) ; obligation de test fermé documentée (§14.4) ; compte développeur Google Play déjà réglé (§14.4) ; `minSdk` 33 et conséquence sur le parc adressable (§3.1, §14.4) ; critères d'acceptation §16 réécrits avec marge (60 i/s à 4×, temps d'image < 4 ms, sobriété en écart) et critère de déterminisme reformulé en deux architectures CPU plutôt qu'en appareils physiques/plateformes (§13.5, §16) | Série de décisions de cadrage prises entre J0 et le début de S2 ; contradiction Android/iOS relevée et tranchée en faveur du DCT (déjà Android uniquement) plutôt que silencieusement ignorée |

*Fin du document — v2.1. Toute modification des principes (§4) ou des règles de gestion (§6) exige une révision de version majeure de ce cahier des charges.*
