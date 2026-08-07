# Carnet de bord — Volens

Fichier unique de suivi (T-007) : décisions prises, écarts au plan, mesures.
Mis à jour à chaque session de travail significative. Ce qui est écrit ici
fait foi sur l'avancement réel, en complément du plan de production.

---

## Lot APK + boucle de jeu (6-7 août 2026) — décisions prises en autonomie

Lot mené sans arbitrage intermédiaire, sur mandat explicite du concepteur.
Frontière respectée : **les 17 recettes d'or sont restées concordantes de
bout en bout**, donc rien n'a touché la sémantique de jeu.

### Mesure demandée — contention R2/R3 maximale

| Géométrie | contention | pic simultané | la nuée sort ? |
|---|---|---|---|
| Dispersion pas 3, un danger au bord (référence) | 15-23 | 4 agents | oui, 20/20 |
| Deux murs de dangers latéraux | **303** (14 %) | 3-4 agents | **oui, 18/20** |
| Dangers intercalés dans la nuée | 1 364 (21 %) | 14 agents | non, 3/20 |
| Dangers intercalés + couloir libre | **1 820 (30 %)** | 13 agents | **non, 0/20** |
| Goulot bordé de dangers | 4 | 2 agents | non |

45. **La contention et la jouabilité s'opposent** *(en volume)*. Le maximum
    atteignable est **1 820 agents-ticks (30 %)** avec des dangers intercalés
    dans une nuée dispersée — mais la nuée ne sort plus. Le meilleur
    compromis jouable est **303 (14 %), pic de 3-4 agents**.

    ~~*« Un niveau qui veut rendre la troisième famille évidente doit
    accepter de perdre des agents. »*~~ **CONCLUSION FAUSSE, corrigée le
    7 août 2026 par la décision 54.**

54. **La visibilité de R03 dépend du TYPE D'OBJECTIF, pas de la géométrie**
    (correction du concepteur, vérifiée par la mesure). J'avais confondu le
    *volume* de contention avec la *conséquence* d'une contention : deux
    règles peuvent se disputer un agent 300 fois sans que l'issue change
    d'un iota. Mesuré sur la géométrie à contention maximale : R03 y change
    **zéro perte et zéro sortie**.

    Le bon dispositif n'est pas d'entasser les dangers, c'est un **traînard
    isolé dont la route naturelle croise un danger**. R03 le dévie vers le
    groupe, donc hors de la colonne fatale. Mesuré (19 agents, 3 isolés
    dans la colonne du danger) :

    | Pile | Sortis | Perdus |
    |---|---|---|
    | Lumière seule | 16 | **3** |
    | Grouper > Lumière | 18 | **1** |

    **R03 sauve 2 agents.** Sous une **préservation `max_lost = 1`**, les
    deux piles se séparent : l'une gagne, l'autre perd. Sous une
    **extraction**, les mêmes piles donnent 84 % et 94 % — tout seuil
    inférieur ou égal à 84 % les confond, et personne ne remarque rien.

    **Le filet devient décisif sans devenir une vague** — et sans qu'aucun
    niveau ait à sacrifier des agents pour être lisible. C'est cohérent avec
    ce que R03 v2 est devenue : elle récupère les traînards, et seul un
    objectif qui compte les pertes rend ce rôle visible.

    **Conséquence pour N3-N5** : le niveau qui doit exposer la troisième
    famille porte une **préservation**, pas une extraction — et sa
    géométrie place quelques traînards isolés sur une route dangereuse.

### ch1_02 « Le détour » — conforme du premier coup

`N_win = 1`, une classe, étalon 31 ticks avec [Fuir, Lumière]. **La
prédiction falsifiable de la fiche est vérifiée** : `[R01]` et `[R01,R02]`
produisent la même empreinte finale `19fdfed445951397` — preuve exécutable
du masquage. Sous `[R01]` seule, le premier agent de la colonne alignée
entre dans le danger au tick 6 et l'objectif devient inatteignable
immédiatement (RG-09) : l'échec est binaire, donc parfaitement lisible.

55. **ENF-11 révisée 60 → 90 Mo (CDC v2.4), sur arbitrage du concepteur.**
    Le seuil d'origine était irréalisable dès le premier jour : le moteur
    standard impose ~75 Mo de plancher (`libgodot_android.so` release :
    67,8 Mo) quand **toutes les données du jeu pèsent 0,1 Mo**. Erreur de
    cadrage, pas défaut de réalisation. L'intention de sobriété reste servie
    par ce qui compte et n'a jamais dépendu du poids : aucun rendu en pause,
    aucune dépendance externe, aucune permission, aucune collecte.
    **L'optimisation n'est pas abandonnée mais tracée** : évolution §17 n°7
    (modèle d'export sur mesure, 35-50 Mo visés), à trancher explicitement
    au jalon J4 — `disable_3d=yes` est le gain principal et sans risque,
    le serveur de texte de repli ne rapporte que ~2 Mo, et le mode d'échec
    à connaître est qu'un module retiré à tort **compile puis plante au
    lancement**.

### Décisions tranchées seul

46. **`android/.gdignore` obligatoire.** Sans lui, Godot importe les
    ressources du modèle Gradle, sème des `.import` dans `android/build/res/`,
    et le build échoue *après* plusieurs minutes de compilation.
47. **arm64 seule dans l'APK** (166 → 80 Mo) : le S23 est arm64 et l'APK se
    réinstalle chaque semaine par wifi. `x86_64` reste réactivable en une
    ligne pour l'AVD.
48. **Icône de lanceur procédurale** générée par script (1,1 ko) : Android
    l'exige. C'est un actif de plateforme, pas un visuel de jeu — DT-13 tient.
49. **La session ne stocke que la RECETTE** (niveau, pile, tick), jamais
    l'état. Le déterminisme reconstruit le reste. Un fichier qui ne décrit
    pas d'état ne peut pas décrire un état impossible : la corruption devient
    structurellement impossible, pas seulement rattrapée.
50. **EF-05 vit dans `game/ui/`, pas dans `core/`.** `SimCore.explain`
    (T-065) est prévu en semaine 8 ; l'écrire maintenant aurait touché
    `core/` et risqué une empreinte. Le diagnostic interroge **les vraies
    règles** pour savoir laquelle a décidé (jamais de réimplémentation,
    DT-15) et ne déduit que la *formulation* du motif d'abstention.
    Vérifié par test : expliquer ne change pas l'empreinte de l'état.
51. **Effacement de progression en deux appuis**, sans fenêtre modale (P3) :
    le premier avertit, le second exécute.
52. **Les niveaux 3 à 5 s'affichent grisés** avec « en attente de
    conception » plutôt que d'être cachés : le testeur voit la forme du
    chapitre et comprend qu'il n'a pas raté une porte.
53. **Un repli sur sauvegarde corrompue n'est PAS un avertissement.** Sur
    mobile, le système tue le processus sans préavis, y compris en pleine
    écriture : c'est un chemin prévu, tracé par `print`, pas signalé comme
    une anomalie. (`JSON.parse` et non `parse_string`, qui pousse une erreur
    moteur sur entrée invalide.)

### Deux bogues que seuls les tests ont attrapés

- La persistance de session, branchée **avant** le chargement, écrasait le
  tick à restaurer : toute reprise serait revenue au tick 0.
- `restore_session` lisait la session **après** avoir déclenché sa
  réécriture. Les deux défauts se masquaient l'un l'autre.

Aucun n'était visible à l'œil : la reprise « fonctionnait », elle ramenait
simplement au début.

---

## PÉRIMÈTRE FERMÉ — définition de « prêt pour les testeurs » (6 août 2026)

**J-1 est reporté.** Décision du concepteur : les tests se feront sur une
version aboutie, installée sur son téléphone, jamais sur un prototype au
banc. *Une interface à moitié faite ferait échouer les testeurs pour des
raisons étrangères à la question posée* — on mesurerait leur patience au
lieu de l'émergence.

**Ce périmètre est FERMÉ.** Tout ce que le testeur touche pendant ses trente
minutes doit fonctionner ; le reste attend. **Une tâche qui n'est dans
aucune des deux colonnes se demande avant d'être faite.**

### Doit être fini

| # | Élément |
|---|---|
| 1 | **Chapitre 1 complet** : les 5 niveaux conçus, validés, conformes à leurs critères QN |
| 2 | **Menu principal** : titre, Jouer / Continuer. Rien d'autre |
| 3 | **Sélecteur des 5 niveaux** : état résolu / non résolu, progression sauvegardée |
| 4 | **Interface de jeu propre** : pile de 4 emplacements, glisser-déposer **et** équivalent sans glissement (ENF-25), tiroir de bibliothèque |
| 5 | **Objectif et avancement en continu** (RG-17) |
| 6 | **Écran de bilan** : gagné / perdu, pourquoi, reprise en un geste |
| 7 | **EF-05 — PRIORITÉ DE LA LISTE** : toucher un agent → quelle règle a décidé, et pourquoi les précédentes non. Sans lui, un testeur qui échoue ne peut former aucune hypothèse : il abandonne, et on mesure sa patience au lieu de l'émergence |
| 8 | **Lisibilité DA-02/03** : danger, lumière, sortie distinguables sans légende |
| 9 | **Reprise après fermeture** (EF-20/21) · **vitesse lente au premier niveau** (T-031) · portrait, une main |
| 10 | **APK installable sur le S23** (voir lot d'empaquetage) |

### Ne doit PAS être fait

Audio · chapitres 2-6 et carte des chapitres · défis optionnels, encyclopédie,
aide graduée · accessibilité complète · localisation anglaise · optimisation
fine et budget de poids · facturation, AAB de production, création de
l'application dans la Play Console.

### Lot d'empaquetage — à faire TÔT, pour ne pas le découvrir à la fin

- **APK signé en debug, pas AAB** : l'AAB ne sert qu'au magasin, il n'est
  pas installable directement.
- Preset d'export Android : `minSdk` 33, `targetSdk` 36, portrait verrouillé,
  **aucune permission**, `gl_compatibility`.
- JDK 17 en place (`~/opt/jdk17`), déclaré dans les paramètres
  d'éditeur. Export depuis Ubuntu, tout dans `$HOME`.
- Installation par `adb` en sans-fil (`adb pair` puis `adb connect`).
- **Numéro de version visible dans le menu** : le concepteur réinstallera
  souvent et doit savoir quel build est sur le téléphone.
- **Remise à zéro de la progression depuis le menu** : rejouer le premier
  contact autant de fois qu'il le faut.
- Procédure complète documentée dans `docs/environnement_dev.md` — elle sera
  refaite chaque semaine.

### Conséquence immédiate sur l'ordre de travail

**R03 redevient bloquant.** Le chapitre 1 complet suppose N3-N5, qui étaient
bâties sur la troisième famille de comportement. Reprise immédiate de R03 ;
si le deuxième archétype du §7.3 ne se produit toujours pas, on assume deux
familles et le concepteur réinvente N3-N5 sur cette base. L'empaquetage
avance en parallèle : il ne dépend de rien.

---

## R03 v2 : ça marche. EQ-05 est une propriété du NIVEAU (6 août 2026)

41. **Paramètres mesurés : `close_range_sq = 2`, `min_neighbours = 1`.**
    Sémantique en une phrase — *« je suis groupé si j'ai au moins un
    congénère à portée de main »*, adjacence orthogonale ou diagonale.
    C'est le seul couple testé qui donne à la fois quatre archétypes
    distincts, aucun gel, et un tremblement négligeable.

42. **EQ-05 n'est pas une propriété des règles, c'est une propriété du
    NIVEAU.** Pour que l'ordre entre R02 et R03 soit seulement observable,
    il faut un agent que les DEUX veulent gouverner au même tick : **proche
    d'un danger** (R02) **et isolé** (R03). Une nuée compacte ne produit
    jamais cette situation — d'où trois semaines d'impasse. Une nuée
    **dispersée près d'un danger** la produit.

    | Géométrie | agents-ticks R02∩R03 | comportements distincts |
    |---|---|---|
    | Compacte + danger | 0 | 2 sur 4 |
    | **Dispersée + danger** | **15-23** | **4 sur 4** ✓ |
    | Dispersée, sans danger | 0 | 2 sur 4 |
    | Compacte, sans danger | 0 | 1 sur 4 |

    **Conséquence directe pour T-040** : le niveau qui sert de test EQ-05
    doit avoir une nuée **dispersée au départ** ET un danger. C'est une
    contrainte de conception, pas un défaut de règle.

43. **Le gel de v1 est supprimé, sans tremblement.** Le bloc compact qui
    gelait en v1 sort maintenant en 12 ticks — exactement comme `[1]` seule
    — avec zéro demi-tour. Sur la géométrie dispersée : 20/20 sortis en
    20-21 ticks, **8 demi-tours** pour 20 agents (contre 573 avec
    `n_min = 2`). Ce n'est plus du tremblement, c'est de l'ajustement.

44. **Pourquoi `n_min = 1` et pas 2.** Avec 2, l'agent traverse sans cesse
    le seuil « groupé / pas groupé » et oscille contre R01 — le même cycle
    limite que la décision 31, à un autre seuil. Avec 1, le seuil est
    atteint dès qu'un voisin est là et ne se re-franchit plus : la
    condition de maintien est stable. Mesuré, pas déduit.

### Cérémonie du corpus d'or — faite le 6 août 2026

Protocole complet respecté : prédiction écrite, vérification sans écriture,
confrontation, accord du concepteur, puis `--write` en commit isolé.

**5 recettes sur 17 changent, exactement celles où R03 précède R01** :
`test_smoke [2,3,1]` · `test_smoke [3,1,2]` · `golden_field [2,3,1]` ·
`golden_field [3,2,1]` · `sensi_damier [3]`. 15 empreintes modifiées, ni
plus ni moins que ce que la vérification annonçait.

**L'empreinte de fumée `c8a7cc2c73394949` SURVIT.** Elle a désormais
traversé sans bouger d'un bit : la revue sémantique complète, l'option C de
R02, la célérité-échéance et R03 v2. `test_smoke [1,2,3]` est immune parce
que R01 en tête masque réellement la suite de la pile.

**Le dispositif `rules_hash` a fait ses preuves à son premier usage réel**
(ajout 3.1 de la revue du 5 août) : il a signalé que `data/rules.json` avait
changé, donc que la divergence pouvait être voulue. Sans lui, ces 15
divergences ressembleraient à une régression pure.

---

## Lisibilité, objectifs et direction visuelle (7 août 2026)

64. **R02 renommée « Fuir le danger »** (CDC v2.5, libellé seul). Deux
    raisons : on ne fuit pas une couleur, et surtout **nommer une règle par
    sa couleur contredit ENF-20** — un joueur daltonien ou en contraste élevé
    ne pourrait pas relier le libellé à ce qu'il voit. Vérifié : le libellé
    ne vit que dans la présentation, l'empreinte `c8a7cc2c73394949` est intacte.

65. **L'échec doit se VOIR avant d'être annoncé.** La simulation atteint LOST
    au tick où l'objectif devient inatteignable (RG-09) — souvent avant que
    rien de visible ne se soit produit. `core/` est correct ; c'était un
    défaut de présentation. Trois corrections dans `game/` : une **marque de
    mort** sur la case fatale (1,6 s ⚙️), un **temps mort de 1,1 s** ⚙️ avant
    le bilan, et une **raison écrite** — « 1 agent perdu — l'objectif de 20
    sur 20 est devenu inatteignable ». Sans cela l'échec était inexplicable,
    donc décourageant (pilier P4).

66. **RG-17 était satisfaite à la lettre et ratée en pratique.** Une ligne
    affichée ne fait pas un objectif compris. Panneau d'ouverture chiffré
    (« Faire sortir 21 agents sur 21 », jamais « extraction 100 % »), bandeau
    cliquable qui le rouvre, avancement chiffré en continu. **Garde-fous** :
    aucun panneau à la reprise (EF-21 — il coûterait un geste avant le
    premier geste utile), seulement un bandeau souligné ; et **aucun mot de
    tutoriel**.

67. **POURQUOI L'ÉCRAN DE VICTOIRE A ÉCHAPPÉ À LA REVUE — ce n'est pas
    l'instrument.** Le harnais avait produit `08-bilan-gagne.png`, et l'image
    montrait le défaut en clair. **J'ai lu cinq captures sur dix et rapporté
    « les écrans sont propres ».** J'ai présenté un échantillon comme un
    ensemble, sans le dire.
    Cause technique du défaut : mon correctif d'ancrage était un remplacement
    textuel ancré sur `var title`, qui n'existe pas dans
    `summary_screen.gd` — le patch a **silencieusement sauté ce fichier**.
    **Parade** : `tests/ui/test_screen_layout.gd` place chaque écran dans un
    parent dimensionné et exige qu'il le remplisse, plus un test qui vérifie
    que le harnais couvre **tous** les écrans. La preuve ne dépend plus de
    mon attention.

68. **DIRECTION VISUELLE : dessiner des RÉGIONS, pas des cases** (T-070
    anticipé). Le vocabulaire de niveau est fait de cases ; l'œil lit des
    formes. Décomposition gloutonne des cases contiguës en rectangles, **une
    instance par région**, taille en cases transmise au shader. La bande de
    sortie se lit comme **une** bande ; les hachures d'un danger sont
    **continues**, contour sur le seul pourtour.

69. **Le but est une zone lumineuse, pas une dalle.** Premier essai : la
    bande écrasait l'écran. Or DA-01 fait de la nuée le personnage, et DA-02
    range le but au-dessus du **danger**, pas au-dessus de tout. Noyau
    translucide (0,42), nuée agrandie.

70. **Le danger passe au registre calme** (DS-03 étendu au visuel) : rouge
    profond désaturé, remplissage sourd, hachures fines, aucune animation
    pour un danger statique. **Un obstacle, pas une alarme.** Le défilement
    reste aux dangers cycliques, dont il signale qu'ils changent.

71. **Compaction de la pile, animée.** Un trou n'a aucun sens : seule compte
    la position **relative** — `[_, A, B]` se comporte exactement comme
    `[A, B]`. Sans compaction le joueur croirait que la position absolue
    compte. Le contenu **glisse depuis la droite** en 0,20 s : un saut
    instantané se lit comme un bug, une glissade comme une intention. Le
    **premier emplacement libre** est marqué — c'est une invitation, les
    suivants ne sont que du décor.

72. **Reposer une règle déjà dans la pile la DÉPLACE**, elle n'écrase plus
    par surprise celle d'arrivée : les deux échangent.

73. **Retrait par icône dessinée** en primitives — aucune dépendance à la
    couverture d'une police — au coin de l'emplacement **sélectionné et
    occupé** seulement. Petite à l'œil, **zone tactile ≥ 48 dp** (ENF-01).

---

## Refonte de l'interface de jeu (7 août 2026) — décisions et mesures

56. **Cause des menus non centrés, mesurée** : `set_anchors_preset()`
    **conserve les offsets**. Appelé sur un contrôle de taille nulle — le
    parent n'étant pas encore disposé — il fige `offset_right = -largeur`,
    donc une largeur de zéro **définitive**. Mesuré :
    `MenuScreen anchors=0,0,1,1 offsets=0,-2400 size=(0,0)`.
    Correctif : `set_anchors_and_offsets_preset()` partout — cinq
    occurrences, dont celle du harnais de captures. **C'était bien la même
    cause que le faux défaut du 7 août au matin**, comme le concepteur l'avait
    supposé. `GameScreen` y échappait seulement parce qu'il positionne ses
    enfants à la main.

57. **Atteignabilité au pouce, mesurée avant de décider du placement.**
    S23 Ultra : dalle d'environ 156 × 73 mm. En prise à une main, le pouce
    pivote près du coin bas, rayon confortable ~90 mm, extension ~110 mm.
    En unités de la base 1080×2400 :

    | Zone | Bornes | Verdict |
    |---|---|---|
    | Confortable | y > 1080 | toute commande fréquente |
    | Extension | 720 < y ≤ 1080 | acceptable, pas pour le critique |
    | **Hors de portée** | **y ≤ 720** | **jamais un chemin unique** |

    Le coin haut droit est à ~156 mm du pivot : **inatteignable**, quel que
    soit le côté. Le transport y est donc placé comme **affordance visible**,
    et doublé d'un second chemin dans la zone confortable : **un appui sur la
    grille bascule marche/pause**. Le bouton du haut n'est jamais requis — il
    montre l'état et sert à la souris ; le pouce touche la grille.
    ENF-01 et le souhait du concepteur tiennent ensemble grâce à cette
    redondance, pas à un compromis.

58. **Fermer en haut à GAUCHE, à l'opposé du transport.** Fermer par erreur
    en cherchant pause serait le pire défaut de cet écran. Réinitialiser
    (EF-04) l'accompagne : même famille de gestes, loin des commandes de
    lecture.

59. **Deux boutons, deux formes.** Lecture = triangle **plein** (une action),
    vitesse = triangles **creux** empilés ▷ ▷▷ ▷▷▷ (un niveau). Deux « ▶ »
    côte à côte étaient indiscernables — vu sur capture, pas déduit.

60. **Seuils de discrimination des gestes** : mouvement > **24 unités**
    (~8 dp) = glissement ; maintien > **0,45 s** sans mouvement =
    explication ; relâchement avant, sans mouvement = sélection.
    **Le mouvement l'emporte toujours** — sans quoi un glissement commencé
    lentement déclencherait une explication en cours de route. Et la
    sélection est émise au **relâchement**, jamais à l'appui, sinon un
    glissement sélectionnerait au passage ce qu'il s'apprête à déplacer.
    Sept tests couvrent ces bascules, dont le tremblement sous le seuil —
    une main dans un bus tremble.

61. **DÉROGATION MOTIVÉE À ENF-25** (« aucune interaction n'exige un appui
    maintenu »). L'appui long sur une règle affiche son explication courte,
    dans le panneau comme dans un emplacement.
    **Condition de recevabilité vérifiée** : l'appui long n'est **jamais le
    seul chemin vers une information nécessaire pour jouer**. Le libellé de
    six mots est affiché en permanence sur la pastille et sur l'emplacement ;
    l'explication n'en est qu'un développement. Aucune règle, aucun objectif,
    aucun état de partie ne dépend de ce geste.
    **Cohabitation** : dans l'écran de jeu, l'appui maintenu ne porte que
    **deux** gestes — explication et glissement — départagés par le seuil de
    mouvement. La surcouche de diagnostic par appui long vit dans le **banc**
    (`game/bench/`), pas dans le jeu : la discrimination reste à deux voies.

62. **Le chemin sans glissement est le chemin PRINCIPAL**, pas un pis-aller.
    Un appui sélectionne (depuis le panneau ou depuis un emplacement), un
    appui destine. Il unifie **poser, retirer, déplacer et échanger** dans un
    seul geste — l'échange en particulier, qui est l'action la plus fréquente
    après poser, puisque tout le jeu tient à l'ordre de la pile. Une pastille
    **« Retirer »** en tête du panneau donne le chemin de suppression sans
    glissement, faute de quoi vider un emplacement l'aurait exigé.

63. **Le rembobinage quitte l'interface, pas le code.** `core/replay/` garde
    ses clichés-clés et sa remontée du temps (DT-11/12), et ses onze tests.
    C'est l'affordance qui est retirée, jamais la capacité.

---

## Règle de méthode — valider un instrument neuf sur un cas connu

**Un instrument neuf produit de faux défauts, et un faux défaut a l'air
vrai.** Avant de croire un instrument qu'on vient d'écrire, le passer sur un
cas dont on connaît déjà la réponse.

Le cas fondateur, 7 août 2026. L'outil de captures automatiques montrait un
menu effondré en haut à gauche, colonne étroite, contenu non centré. J'ai
cherché le défaut dans l'écran, modifié l'ordre d'ancrage, réordonné
l'initialisation — **et le jeu n'avait rien.** Le harnais ajoutait `App`
sous un simple `Node` : un `Control` enfant d'un `Node` reste à **taille
zéro**, et toute l'interface retombait sur sa taille minimale. Dans le vrai
jeu, `App` est la **racine** de la scène et Godot lui donne le viewport.

Il aura fallu mesurer les tailles réelles (`app.size = (0,0)`) pour voir que
l'instrument mentait. Sans cette mesure, je « corrigeais » un écran sain.

C'est le même piège que les raisonnements trop fins sur les conditions
d'abstention, mais **d'un cran au-dessus** : là, une hypothèse fausse
produisait une prédiction fausse ; ici, un outil faux produit une
**observation** fausse — et une observation ne se met pas spontanément en
doute.

**La règle : les captures automatiques auraient dû être vérifiées sur un
écran connu bon avant d'en tirer la moindre conclusion sur les autres.**

---

## Règle de méthode — sur une condition d'abstention, prédire GROSSIÈREMENT

**Un raisonnement d'un cran trop fin sur une condition d'abstention est
plausible et faux.** Le même piège a frappé trois fois :

| Occasion | Le raisonnement fin, plausible | Le fait |
|---|---|---|
| Le damier | « à l'équilibre, R03 s'abstient » | elle ne s'abstient **jamais** ; elle propose un pas éternellement refusé |
| L'arc QN-02 | « le barycentre est au centre, donc R03 mène aux dangers centraux » | le barycentre est **où est la nuée**, c'est-à-dire en bas |
| La cérémonie R03 v2 | « R02 masque R03 puisqu'elle perçoit le danger depuis toute la grille » | percevoir **ne suffit pas** : il faut aussi une direction franchissable qui éloigne strictement |

À chaque fois, le critère **syntaxique** a battu le critère **sémantique**.
« R03 est-elle avant R01 dans la pile ? » ne suppose rien sur ce que la
règle fait réellement, et a prédit juste 17 recettes sur 17 là où mon
raisonnement sur les zones d'action s'est trompé sur deux.

**La règle : sur une condition d'abstention, prédis grossièrement. La
finesse se gagne en mesurant, jamais en raisonnant.**

**Fait sur R02 à retenir** (il resservira) : R02 ne propose PAS dès qu'elle
perçoit un danger. Il lui faut en plus une direction **franchissable** qui
**éloigne strictement**. Contre un mur, dans un coin, ou quand toutes les
directions améliorantes sont bloquées, elle s'abstient — plus souvent qu'on
ne l'estime de tête.

---

## Règle de méthode — un observable inattendu se mesure, il ne se classe pas

**Un comportement inattendu qui trouve son explication du premier coup doit
être sondé, pas rangé.** Une explication plausible immédiate est le signal
qu'il faut mesurer, pas la permission de passer.

Le cas fondateur, 5-6 août 2026. La fixture `sensi_damier` montrait une
nuée qui s'immobilise sous R03. Il a été consigné « à l'équilibre, R03
s'abstient, et l'abstention casse la parité — l'agrégat final est un
escalier compact stable ». C'était faux. La sonde S8 a mesuré l'inverse :
**R03 ne s'abstient pratiquement jamais** ; elle propose éternellement un
pas vers le barycentre, que les voisins refusent. Deux mécanismes opposés,
un seul observable — la nuée s'arrête.

Le comportement réel était donc déjà visible, et il a été archivé au corpus
d'or sous une lecture erronée. La fixture reste juste (elle archive ce qui
se passe, pas ce qu'on en dit), mais l'explication ne l'était pas. C'est le
seul point du projet où quelque chose est passé sans preuve — dans une zone
à relecture renforcée, qui plus est.

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

---

## Fait — R03 : trois tentatives, un diagnostic, et l'arrêt (6 août 2026)

Trois semaines de décisions perceptives arbitrées avec des compteurs. Le
concepteur a tranché : on arrête R03 et on construit l'instrument (le
rendu) avant de reprendre.

### Ce que les sondes ont établi

20. **R03 v1 gèle la nuée, et ce n'est pas un défaut de code.** Sur un bloc
    compact, 0 agent sur 20 s'abstient, 20 proposent un pas vers le
    barycentre, tous refusés par leurs voisins ; et comme une règle ne voit
    jamais les autres agents (décision 15), R03 ne s'abstient pas et masque
    la suite de la pile pour toujours. R03 avant R01 = pile morte ; R03
    après R01 = poids mort strict ([1] ≡ [1,3] aux chiffres près).
21. **Cause racine** : R03 est une FORCE dans un système qui n'accepte que
    des CONDITIONS. Chez les boids la cohésion est un vecteur sommé et
    pondéré ; ici la cascade est « le premier qui décide l'emporte ». R01 a
    un terminal naturel (la lumière), R02 une abstention naturelle (hors de
    portée) ; « converger vers le barycentre » n'en a aucun — le barycentre
    recule avec la nuée.
22. **Tentative A — rayon satisfait (tolérance k)** : k=3 minimal pour
    débloquer, k=4 obligatoire (à k=3, [3,2,1] et [2,3,1] gèlent encore).
    Mais à k=4 R03 décide **0 %** du temps : famille cosmétique. Raison
    mathématique : la distance au barycentre des voisins perçus ne peut pas
    dépasser la portée de perception, donc k≈portée rend la règle inerte.
    Élargir la portée réactive R03 (27-50 %) mais **ramène le gel**.
23. **Tentative B — R03 saute les cases occupées** (mesurée, non
    implémentée) : échange le gel contre le tremblement (564 demi-tours,
    ne termine jamais). Pire.
24. **Tentative C — prédicat de maintien v2** (s'abstient si ≥ n_min voisins
    dans r_close) : supprime le gel proprement (r_close=2, n_min=2 : 0 %
    de déclenchement sur bloc compact, sortie en t=12 comme [1] seule).
    **Mais les archétypes 1 et 2 ne se séparent toujours pas** : [2,3,1] et
    [3,2,1] sont identiques dans les **huit** géométries testées, jusqu'au
    nombre de demi-tours. Raison structurelle : R02 pousse un agent hors de
    portée du danger, donc l'isolement (ce qui déclenche R03) est le
    PRODUIT de la poussée et n'apparaît qu'une fois R02 abstenue. **Les
    zones d'action des deux règles sont disjointes, donc leur ordre est
    inobservable** — aucune géométrie de niveau ne peut les séparer.
25. ~~**Zone piège Ouest**~~ — **DIAGNOSTIC ERRONÉ, corrigé le 6 août au
    soir par la décision 31.** J'avais attribué le va-et-vient perpétuel à
    la position du danger à l'est des agents. C'était le bon symptôme et la
    mauvaise cause. Trace conservée ici pour mémoire : les chiffres (1 494
    à 2 446 demi-tours, nuée qui ne termine jamais) sont exacts, leur
    explication ne l'était pas. Voir la décision 31 pour le mécanisme réel.
26. **Évitement pur de R02 : PARQUÉ.** L'idée (R02 refuse les pas létaux et
    s'abstient sinon, au lieu de repousser) réglerait la zone piège et
    rendrait les ordres observables — mais c'est une CONTRAINTE, et la
    cascade n'accepte que des PROPOSITIONS. C'est la pathologie de R03 sous
    un autre visage : le système de règles n'a qu'un genre (proposeur) là
    où il en faudrait trois — **proposeur, filtre, condition de maintien**.
    Question d'architecture, pas de paramètre ; ne se tranche pas à
    l'aveugle avant une échéance.

Les deux patches R03 (tolérance, prédicat v2) sont **hors dépôt**, dans
`~/volens-patches-r03/`. Aucune cérémonie d'or n'a été faite : les
empreintes archivées sont intactes.

### Correctif livré au passage

27. **Classes QN-01 sur l'ÉQUIVALENCE, jamais sur l'identité** (PR #6).
    Deux issues qui ne diffèrent que par l'attribution des identifiants
    d'agents sont la même solution (RG-04 ; QN-01 exclut les variantes
    triviales). Le validateur les comptait séparément et gonflait le chiffre
    servant de critère — et celui qu'affiche le bilan de niveau. Clé
    d'équivalence = multiensemble trié des (pos, dir, flags) + compteurs,
    dans `tools/` uniquement. `hash_state` garde les identifiants : identité
    (déterminisme, `core/`) et équivalence (rapport, `tools/`) sont deux
    notions distinctes — **aucune empreinte d'or touchée**.

## Fait — T-030/T-031 : premier rendu (6 août 2026, branche `feat/view-prototype`)

Motif : trois semaines de questions perceptives (« tremblement ou
hésitation », « beau ou cassé ») arbitrées avec des compteurs. Un compteur
de demi-tours est un substitut du regard. Le rendu est aussi sur le chemin
critique de J-1 (6 septembre) — sans lui, aucun testeur ne peut jouer.

- **`game/view/`** (gardé) : nuée et traînées en MultiMesh 2D, halos et
  hachures par shaders `canvas_item`, **zéro texture** (DT-13, ENF-11).
  Interpolation entre ticks (DCT §6.2) — sans elle, tout ressemblerait à du
  tremblement à 4 ticks/s. Calques dans l'ordre du DCT §6.3. Danger porté
  par couleur **et** hachures (ENF-20/22). Liseré d'état (DA-03).
  Traînées mesurées en **ticks**, pas en images : c'est la forme collective
  dans le temps qui est en question (DA-01).
- **`game/bench/`** (jetable) : transport (marche/pause, pas à pas,
  rembobinage continu, 1/2/4/8 ticks/s), **bascule de pile sans relancer**,
  surcouche par appui long (tick, sortis, perdus, demi-tours cumulés, i/s,
  temps d'image).
- **Coloration par règle décisionnaire** : chaque agent porte la couleur de
  l'emplacement de pile qui a décidé pour lui à ce tick. C'est l'instrument
  qui rend visible la disjonction des zones d'action de la décision 24 —
  deux couleurs qui ne se mélangent jamais.
- **`data/levels/diag/`** : les trois géométries des sondes, en `.lvl`
  lisible et `.json` converti.

28. **Écart à DT-13 signalé, non tranché** : les cases sont rendues en
    MultiMesh et non en TileMapLayer. Un TileMapLayer impose un atlas de
    texture, ce que « tout le visuel est procédural » interdit ; et une
    grille ne dépasse pas 14×18 = 252 cases. Un seul appel de dessin dans
    les deux cas. À confirmer ou infirmer par le concepteur.

### Arbitrages du 6 août (soir)

29. **DT-13 amendée → DCT v1.2** : cases en MultiMesh 2D avec données par
    instance, jamais de TileMapLayer (un atlas de texture contredirait
    « tout le visuel est procédural »). **Conséquence actée sur T-074** :
    l'éditeur de niveaux éditera le format `.lvl`, il ne sera pas un
    peintre de tuiles adossé à l'éditeur intégré de Godot. C'est déjà le
    flux réel depuis le 5 août, donc coût nul — mais c'est un choix, pas
    une découverte en semaine 10.

30. **RÉVISION DU SYSTÈME DE RÈGLES — à trancher AVANT LE CHAPITRE 3, pas
    avant J-1.** La cascade actuelle n'a qu'un seul genre de règle : le
    **proposeur** (« je propose un déplacement, ou je m'abstiens »). Trois
    besoins déjà identifiés n'y rentrent pas :
    - **condition de maintien** — R03 « Rester groupé » : un prédicat
      satisfait ou non, pas une convergence (décisions 20-24) ;
    - **filtre** — l'évitement pur de R02 : « ne va pas là », une
      contrainte sur les propositions d'autrui, pas une proposition ;
    - **effet** — R08 « Marquer la piste » (chapitre 3) : déposer un
      marqueur n'est pas un déplacement. Sous la cascade actuelle, soit
      elle s'abstient et n'est pas vraiment dans la pile, soit elle
      propose l'immobilité et masque tout ce qui suit. **La stigmergie ne
      rentre pas dans le genre proposeur** — et le chapitre 3 est
      entièrement bâti dessus (R07/R08/R09).

    Genres à instruire : proposeur, filtre, condition de maintien, effet.
    **Échéance : avant le premier code du chapitre 3.** Ne pas ouvrir avant
    J-1 (6 septembre) — la question est structurante et ne se tranche pas
    sous contrainte de calendrier.

## Fait — Première observation à l'œil, et ce qu'elle a corrigé (6 août 2026, soir)

Le concepteur a regardé le jeu tourner. **Ses trois observations confirment
les compteurs** — ce qui valide rétroactivement la méthode de mesure, mais
l'une d'elles a aussi renversé un diagnostic consigné.

31. **Le va-et-vient perpétuel est un CYCLE LIMITE À LA FRONTIÈRE DE PORTÉE,
    pas une affaire de géométrie est/ouest** (corrige la décision 25).
    Trace exacte d'un agent, danger en (4,10), portée² de R02 = 25 :

    | tick | pos | d² | R02 | R01 | décide |
    |---|---|---|---|---|---|
    | 0 | (0,14) | 32 | abstient | Nord | R01 → Nord |
    | 1 | (0,13) | **25** | **Sud** | Nord | R02 → Sud |
    | 2 | (0,14) | 32 | abstient | Nord | R01 → Nord |

    L'agent traverse la frontière de perception dans les deux sens, sans
    fin. **Un répulseur à seuil dur plus un attracteur produit toujours un
    cycle limite au seuil** : c'est structurel, pas un réglage. Vérifié que
    les échappatoires ne tiennent pas — une hystérésis sur la portée ne fait
    qu'élargir le cycle ; « préférer la direction qui éloigne le plus » ne
    change rien car au point critique le sud est la SEULE direction qui
    éloigne ; et l'ordre N>E>S>O choisit le sud avant l'ouest de toute façon,
    donc le bord de grille n'y est pour rien.

32. **Un seul défaut, deux visages.** Les deux agents qui traînaient sous
    R03 v2 relèvent du même mécanisme : R03 s'active sous un seuil de
    voisins, R01 pousse vers la lumière, l'agent traverse le seuil dans les
    deux sens. Le concepteur voyait deux problèmes ; c'en est un.

33. **L'échéance de la décision 30 est avancée de fait.** Le seul correctif
    robuste est que R02 **évite** au lieu de **repousser** — sans répulsion,
    pas de cycle. Or éviter est une CONTRAINTE : ça exige le genre
    « filtre ». La révision du système de règles était datée « avant le
    chapitre 3 » à cause de R08 ; elle touche en réalité le **chapitre 1**,
    et il y a désormais une preuve visuelle, pas seulement des compteurs.
    Elle reste néanmoins à n'ouvrir qu'après J-1.

34. **EQ-05 définitivement violé, confirmé à l'œil.** « Fuir > Grouper >
    Lumière » et « Grouper > Fuir > Lumière » sont indiscernables à l'écran,
    comme ils l'étaient à l'empreinte. Deux des quatre archétypes du CDC
    §7.3 sont le même comportement. Plus rien à mesurer : c'est un fait
    acquis qui attend la révision d'architecture.

### Livré : métrique de sur-place au validateur

Le validateur détectait déjà les boucles complètes (DT-16), mais **pas** le
cas qui compte : quelques agents oscillent pendant que les autres sortent —
le niveau est gagnable et paraît cassé. Il rapporte désormais, par pile,
les agents `oscillating` (cycle de période ≥ 2) et `stuck` (figés), et
signale dans le verdict toute **pile gagnante** qui laisse un agent en
sur-place. Sur la géométrie fautive : 2 piles gagnantes, jusqu'à 8 agents.
Sur `ch1_01` : rien.

**Critère de conception qui en découle, vérifiable à l'écriture :** *aucune
pile gagnante ne doit laisser un agent osciller.* C'est ce qui remplace la
fausse règle « pas d'agent à l'ouest d'un danger » de la décision 25.
Aucune cérémonie d'or : c'est du `tools/`, `core/` est intouché.

### Dette documentaire à traiter

- **Numérotation** : les décisions 16-19 vivent sur la branche
  `docs/fiches-ch1` (PR #4, brouillon) et manquent donc sur `main`.
- **PR #4 est périmée en partie** : les fiches N3/N4/N5 sont bâties sur
  l'arc à trois familles, que les décisions 20-24 ont invalidé ; sa
  décision 17 porte le diagnostic erroné corrigé ici. Les fiches N1/N2
  restent bonnes, ainsi que l'allongement de `ch1_01` en 8×16. **À
  retravailler après la révision d'architecture, pas à fusionner telle
  quelle.**

## Fait — T-032 : écran de jeu et composition de la pile (6 août 2026)

Le rendu montrait la nuée ; il manquait de quoi **jouer**. Sans composition
de pile, aucun testeur ne peut rien faire — c'est le chemin critique de J-1.

Conforme au DCT §9.2 : bandeau d'objectif d'une ligne avec avancement en
continu (RG-17), grille au centre dans un sous-viewport, **pile de 4
emplacements et transport dans la moitié basse** (ENF-01, zone du pouce),
tiroir de bibliothèque coulissant — jamais un écran plein (P3). Ancrage sur
la zone sûre d'Android (encoches, barre gestuelle).

35. **Cible tactile de 144 unités, dérivée et non choisie.** ENF-01 exige
    ≈ 48 dp. La base du projet est 1080×2400 en étirement `canvas_items`,
    donc les unités d'interface sont les pixels de cette base. Sur les
    appareils visés, 1080 px valent 360 dp (densité 3,0) à 411 dp (S23
    Ultra) : 48 dp valent donc entre 126 et 144 unités. On retient **144**,
    la borne haute — une cible trop grande ne viole rien, une trop petite si.
36. **Deux façons de poser une règle, l'une et l'autre obligatoires** :
    glisser-déposer natif (DCT §9.2) **et** équivalent sans glissement
    (ENF-25 : appui pour sélectionner, appui pour placer). Un joueur debout
    dans le bus, une main occupée, ne peut pas toujours glisser.
37. **Une règle n'occupe jamais deux emplacements** : la reposer ailleurs la
    DÉPLACE. L'espace des piles est fait d'arrangements sans répétition —
    l'interface doit rendre impossible ce que l'énumérateur ne compte pas.
38. **Les emplacements portent une couleur fixe** (1 cyan, 2 ambre,
    3 magenta, 4 vert), la même dont la vue teinte les agents décidés par
    cet emplacement. Le joueur lit alors directement « la plupart des agents
    sont cyan, donc c'est ma première règle qui gouverne » — la règle d'or
    rendue visible sans un mot. ⚠ **Choix de conception, à confirmer.**
39. **Modifier la pile réinitialise l'essai** (RG-10) : la recette est
    (niveau, pile), et `ReplaySession` fige la pile pour la durée d'une
    session. Vérifié par test.

**Test d'interface automatisé** (`tests/ui/`, exigé par le DCT §9.2) :
inspection de l'arbre de contrôles pour les cibles tactiles, les quatre
emplacements, l'équivalent sans glissement, l'unicité d'une règle dans la
pile, et la réinitialisation. Il existe parce qu'une cible trop petite ne se
voit pas sur un écran d'ordinateur — elle se découvre dans le bus.

**Hors périmètre, signalé plutôt que bâclé** : EF-05 (appui sur un agent →
cascade de décision) attend `SimCore.explain` (T-065, S8) ; retour haptique
(ENF-24), audio, sauvegarde, écrans d'accueil et de bilan.

40. **Incohérence documentaire relevée** : le DCT §9.2 renvoie à « la
    maquette du CDC », qui n'existe pas. La disposition a été déduite du
    texte du DCT lui-même (bandeau / grille / pile + transport en zone
    basse) et d'ENF-01. À trancher : produire la maquette, ou retirer la
    référence.

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
