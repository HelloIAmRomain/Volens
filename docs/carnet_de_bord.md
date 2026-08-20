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

    ~~**Le filet devient décisif sans devenir une vague**~~ — **FORMULE
    CORRIGÉE le 9 août 2026, voir décision 132.** L'effet d'issue est bien
    un filet (2 agents sur 19), mais l'effet VISIBLE est une vague : mesuré,
    `[3,1]` et `[2,1]` divergent de 30 ticks et 33 cases sur ch1_05. Prendre
    l'ampleur d'un effet mesuré pour l'ampleur de sa visibilité est l'erreur
    de la décision 123 ; elle est ici sous sa première forme, et elle a
    orienté deux lots. Ce qui reste vrai : sans qu'aucun
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

## N4 corrige, hygiene de la suite, et le controle generique (9 aout 2026)

147. **N4 SE GAGNAIT AVEC UNE SEULE REGLE — defaut signale par le concepteur,
     corrige.** `[Lumiere]` seule y gagnait alors que N4 n'introduit pas R01 :
     le joueur pouvait reporter la reponse de N1 sans jamais rien ordonner,
     dans un chapitre entierement bati sur l'idee que l'ordre compte (S4).
     **Correction par une impasse**, seul levier qui fait taire R01. N4 porte
     desormais deux pieges independants : la famille directe bute sur
     l'impasse, la prudente sur l'echeance, **seule la cohesion en tete passe
     les deux** — l'arbitrage que le CDC §8.5 attend du premier objectif
     compose.
     Mesures : la directe echoue de **4 %** (un agent sur 21, visible et
     localisable a l'ecran), la prudente de **25 %**. Echeance 24, cohesion 18,
     prudence 30 : six ticks de marge de chaque cote.
     **Manquement S4 restant : ch1_03.** Non corrige — le meme remede y ferait
     de `[3,1]` une cle universelle (decision 113).

148. **12 % DE PILES GAGNANTES EN N4 : LA CIBLE, PAS UNE TOLERANCE.**
     Arbitrage du concepteur, et il renverse la charge de la preuve. La bande
     indicative 20-50 % (CDC §12.2.1) a ete ecrite **avant qu'un seul niveau
     existe**, et le CDC la declare lui-meme non opposable.
     Douze pour cent est la consequence directe de deux pieges independants
     dans un meme niveau, et c'est ce qui fait de N4 **le seul niveau du
     chapitre qu'aucune pile de deux regles ne resout par hasard**. Un niveau a
     40 % de gagnantes se traverse en essayant ; celui-ci demande de comprendre
     pourquoi la vitesse reste coincee et pourquoi la prudence arrive trop
     tard. Consigne comme voulu dans l'en-tete du niveau et dans sa fiche.

149. **`pending()` EST BANNI DES TESTS, par controle lexical.** Deuxieme
     occurrence a deux semaines d'intervalle, toutes deux sur un objectif non
     atteint qu'on voulait garder visible. GUT sort en **code 1** dessus : la
     CI passe au rouge, et **un rouge permanent cesse d'etre un signal** — on
     apprend a le lire comme du bruit, et la vraie regression suivante passe
     inapercue. La bonne forme existait deja dans la suite : le **cliquet**.

150. **CINQUIEME FORME DU PIEGE DE L'INVARIANT n.12 : UN TEST DONT L'OBJET
     N'EST PAS VERSIONNE N'EST PAS UN TEST.** Vert sur le poste qui possede le
     fichier, absent partout ailleurs : il ne prouve rien tout en donnant
     l'apparence d'une couverture.
     La serie prise d'un bloc, et elle est plus instructive qu'aucune de ses
     entrees isolee :
     - paraitre correct clot l'examen (dec. 12) ;
     - paraitre casse clot l'examen (dec. 127) ;
     - un zero se verifie comme un chiffre inattendu (dec. 137) ;
     - une note ne protege de rien (dec. 103) ;
     - **un test qui ne s'execute nulle part ressemble a un test.**
     Cas rencontre : un controle du prereglage d'export ecrit sur
     `export_presets.cfg`, hors depot. **Le nouveau controle a attrape ma
     propre reference residuelle des sa premiere execution** — un bloc
     conditionnel « si le fichier existe », vert quand il est absent.
     Correction de fond : la garantie qui compte porte sur l'**ARTEFACT**, pas
     sur la configuration. Apres export, `unzip -l | grep -c` doit valoir zero.

151. **TOUTE VALEUR DE NIVEAU RECOPIEE HORS DE SA SOURCE FINIT PAR DIVERGER.**
     Constat, pas prudence — le motif s'est produit **trois fois**, sur trois
     champs, et chaque fois la divergence n'a ete vue que par accident :
     - `slots` : l'interface offrait quatre rangs la ou le validateur en
       enumerait deux ; `expected_wins` devenait faux, et la lecon du niveau
       avec lui (invariant n.11) ;
     - `expected_wins` : une table en dur dans `test_chapter1_arc` recopiait
       les valeurs des trois derniers niveaux. Elle a derive **des la premiere
       refonte**, et le test a echoue en annoncant « 2 attendu 7 » alors que la
       verite etait l'inverse ;
     - `slots` de nouveau : une assertion recopiait « ch1_02 declare slots: 2 ».
     **Trois corrections au cas par cas auraient laisse passer le quatrieme
     champ.** D'ou un controle GENERIQUE (invariant n.16) : les champs
     declaratifs ne se lisent que par `LevelSpec`, et un test lexical refuse
     toute autre lecture. Il a attrape une lecture residuelle des sa premiere
     execution.

152. **LA LIGNE DE PARTAGE : DECRIRE contre FAIRE TOURNER.** `max_ticks`,
     `objectives`, `allowed_rules` et `agents` restent libres — ce sont des
     **entrees de la simulation**, lues par `SimCore` la ou c'est son travail ;
     les proteger interdirait au moteur de fonctionner. `expected_wins`,
     `expected_classes`, `tutorial`, `calibrated_on` et `slots` DECRIVENT le
     niveau, ne pilotent rien, et sont donc recopies partout : ce sont eux qui
     divergent.

153. **LIRE UN RAPPORT N'EST PAS LIRE UN NIVEAU.** Les rapports du validateur
     et les blocs de releve des fiches portent leur propre copie de ces
     champs — et les confronter au niveau est justement leur raison d'etre. On
     les distingue par l'**indexation directe** (`x["cle"]`), qui ne ressemble
     pas a une lecture de niveau. Meme convention que pour `slots` : la garde
     lexicale reste utilisable **sans liste d'exceptions a rallonge**, et c'est
     ce qui la rend tenable.

154. **UNE CHAINE `&&` A AVALE UNE CONSIGNATION.** Les decisions 147 a 150 ont
     ete ecrites une premiere fois dans la meme commande qu'un `patch.py` qui a
     echoue : le `&&` a empeche le script suivant de s'executer, et rien ne
     l'a signale — la commande a rendu la main sans erreur visible.
     Retrouve par hasard, en cherchant une autre ancre. **Une consignation ne
     se chaine pas derriere une operation qui peut echouer** : elle part seule,
     et l'on verifie qu'elle est arrivee.

---

## DT-22 construit — le parc de testeurs devient un instrument (9 aout 2026)

141. **DT-22 EXISTE. C'ETAIT LE DERNIER ELEMENT DU CHEMIN CRITIQUE DE LA
     CAMPAGNE ENCORE DE MON RESSORT.** Sans lui, la moitie **arm64** de la
     verification de determinisme reposait sur le seul appareil de reference,
     et le parc de testeurs — recrute de toute facon pour l'obligation de test
     ferme — ne servait a rien de ce cote.

142. **COMPILATION CONDITIONNELLE, PAS MASQUAGE — et c'est verifie, pas
     promis.** Un ecran cache derriere un geste secret finit par etre trouve,
     et un ecran de diagnostic dans un jeu epure est un defaut, pas une
     discretion. La garantie est structurelle : **les fichiers ne sont pas
     dans le paquet.**
     Trois verrous, dont deux mecaniques :
     - le prereglage de production exclut `game/selfcheck/*` **et** `tests/*`
       (sans corpus, l'ecran n'aurait rien a verifier) ;
     - aucun fichier hors du dossier ne nomme `SelfCheckScreen` : l'entree
       passe par un chargement dynamique garde par `OS.has_feature("test_build")`
       ET par la presence reelle du fichier. Une reference statique empecherait
       la build de production de **demarrer** ;
     - `tests/arch/test_selfcheck_isolation.gd` verifie les trois.
     **Preuve a l'export** : l'APK de production reconstruit ne contient ni
     `selfcheck` ni `golden` — zero occurrence dans l'archive.

143. **L'ECRAN TRANCHE, LE TESTEUR RECOPIE.** Le testeur ne connait pas la
     valeur attendue : lui demander de comparer un code a rien serait lui
     demander l'impossible. Les empreintes de reference etant dans la build,
     l'ecran affiche lui-meme **CONFORME** ou **ECART DETECTE**, et nomme les
     recettes divergentes. Le code recopie ne sert plus qu'au diagnostic —
     il n'est vraiment utile qu'en cas d'ecart.

144. **LE CODE PORTE SON CONTEXTE, SANS QUOI C'EST UNE DONNEE ORPHELINE.**
     « Le hash correspond » sans savoir sur quel modele, quelle architecture et
     quelle version d'Android ne prouve rien — or c'est precisement
     l'architecture qu'on cherche a etablir (DCT §11.2, A6). Modele,
     architecture et version sont affiches sous le code et recopies avec lui :
     deux mots de plus pour le testeur.
     **Alphabet sans caractere ambigu** (ni O/0, ni I/1, ni S/5) et tiret au
     milieu : le code est transcrit A LA MAIN par quelqu'un qui ne sait pas ce
     qu'il transcrit. Une paire ambigue produirait de **faux ecarts**, c'est-a-
     dire exactement le contraire de ce que l'instrument cherche.

145. **UNE SOURCE UNIQUE POUR LE REJEU, IMPOSEE PAR L'EXPORT.** `tools/` est
     exclu du paquet : l'ecran ne peut pas appeler `GoldenRunner`.
     Reimplementer la boucle donnerait **deux verites**, et une divergence
     entre elles rendrait toute comparaison d'empreintes muette — precisement
     la ou l'on cherche a en tirer une preuve.
     La boucle est donc descendue dans `core/replay/recipe_runner.gd`, seul
     endroit que `tools/` et `game/` ont le droit d'importer tous les deux
     (regles 3 et 4). Elle est PURE : elle recoit des dictionnaires deja
     charges, chaque appelant fait sa propre lecture de fichiers (DT-15).

146. **UN REJEU ETALE SUR PLUSIEURS IMAGES.** Trente recettes de trois cents
     ticks bloqueraient l'interface plusieurs secondes ; sur Android, un gel
     de cette duree declenche le dialogue « l'application ne repond plus ».
     Une recette par image, avec progression visible. Ce n'est pas du confort :
     un testeur qui voit son telephone se figer ferme l'application et ne
     recopie rien.

---

## Dossier central, dette d'outillage, et gel (9 aout 2026)

138. **LE DOSSIER DES GENRES DE REGLES DEVIENT LE DOCUMENT CENTRAL DU PROJET.**
     Extrait du carnet, ou il vivait en morceaux, et ecrit comme un
     DIAGNOSTIC : `docs/Volens_dossier_genres_de_regles.md`.
     Une cause unique — la cascade « premier match gagnant, **sans
     hysteresis** », avec un seul genre de regle — et quatre pathologies :
     P1 une force dans un systeme qui n'accepte que des conditions ;
     P2 l'evitement pur, contrainte inexprimable ;
     P3 deux gradients opposes oscillent a leur frontiere ;
     P4 divergence et oscillation ont la meme cause, donc **on ne peut pas
     enseigner l'ordre de deux regles contradictoires**.
     Trois chantiers en dependent, **tous au chapitre 1** : la lecon de N5
     (P4), S4 (P3), la stigmergie de R08 (P1). Le dossier ne prepare donc pas
     le chapitre 3 : il repare l'existant. Les nommer explicitement evite
     qu'ils soient repris un par un comme des defauts isoles.

139. **DETTE D'OUTILLAGE : LA CONTENTION EST ECHANTILLONNEE AU MAUVAIS
     ENDROIT — a traiter AVANT le chapitre 3.**
     Le validateur mesure la contention sur les piles de **deux** regles, ou
     la paire concernee est seule a decider. On raisonne ensuite sur des piles
     de **trois**. Les deux ne visitent jamais les memes etats : sans R01, la
     nuee n'avance pas pareil, donc les situations de contention ne sont pas
     les memes. **On mesure sur une trajectoire et l'on conclut sur une
     autre.**
     Constate sur N5 : contention R2/R3 = 5, et pourtant `[2,3,1]` et
     `[3,2,1]` rigoureusement identiques. Le chiffre n'etait pas faux, il ne
     portait pas sur ce qu'on lui faisait dire.
     **Aux chapitres a douze regles, l'ecart devient la regle** : les piles de
     quatre seront la norme, et une mesure faite sur des paires isolees n'en
     dira plus rien. Correction attendue : **mesurer la contention sur les
     piles COMPLETES**, en attribuant chaque agent-tick a la paire de regles
     qui s'y disputent reellement la decision. Echeance : avant le premier
     code du chapitre 3.

140. **LE CHAPITRE 1 EST CLOS, ET LA REVISION EST GELEE.** Deux decisions du
     concepteur, prises ensemble et pour la meme raison.
     La revision des genres est **mure techniquement et prematuree
     pedagogiquement** : toutes ses mesures viennent du validateur et de
     sondes, aucune d'un joueur. Refondre le systeme de regles la-dessus
     reproduirait, a plus grande echelle, l'erreur de l'arc QN-02 — optimiser
     une propriete mesurable avant de savoir si elle correspond a quelque
     chose de percu.
     Argument decisif, et il est dans les chiffres de ce carnet : **trois des
     quatre pathologies ont ete mal diagnostiquees au moins une fois** avant
     d'etre comprises, et une quatrieme — « deux archetypes indiscernables » —
     s'est revelee **inexistante**. Un dossier dont un quart des motifs
     initiaux etait faux ne se tranche pas sans confrontation exterieure.
     **Ce qui reste a savoir ne se mesure pas ici.**

---

## N5 dessine, et le mur qu'il revele (9 aout 2026)

132. **RESERVE DE LA « TROISIEME FAMILLE PERCEPTIBLE EN FILET, JAMAIS EN
     VAGUE » : CORRIGEE.** Elle reposait sur la meme erreur que ma decision
     123 — prendre la contention pour une jauge d'intensite. Un effet mesure
     faible n'est pas un effet peu visible : **une seule decision divergente
     cascade**. Cette reserve a oriente deux lots ; elle est retiree.

133. **N5 EST DESSINE, DEUX CONDITIONS TENUES AVANT LE PREMIER TRAIT.**
     Contention R2/R3 = **5** (elle valait 0), et **aucune pile gagnante ne
     boucle**. La premiere leve la reserve que je portais depuis trois lots :
     **les trois paires du chapitre ont desormais un ordre observable**.
     Six piles gagnantes en deux classes, conformes a la prediction.

134. **LE MUR, ET IL EST STRUCTUREL.** `[2,3,1]` et `[3,2,1]` gagnent toutes
     deux — mais suivent la **meme trajectoire**, zero tick d'ecart.
     Ce n'est pas faute d'avoir cherche : dix-huit geometries balayees, deux
     dessinees et mesurees. Le resultat est net et vaut plus que le niveau :

     > **Ce qui separe `[2,3,1]` de `[3,2,1]` est une contradiction entre R02
     > et R03 sur le meme agent — et une telle contradiction produit un cycle
     > limite.** La geometrie qui les separait le mieux (39 ticks d'ecart)
     > laissait trois piles GAGNANTES avec un agent oscillant a perpetuite.

     Divergence et oscillation ont la meme cause : deux regles qui se
     contredisent a une frontiere, sans hysteresis pour trancher. **On ne peut
     pas avoir l'une sans l'autre** tant que la cascade reste « premier match
     gagnant sans hysteresis ». C'est une **quatrieme manifestation** de la
     cause commune de la decision 117, et la plus couteuse : elle ne casse pas
     un niveau, elle **interdit une lecon**.
     Verse au dossier des genres de regles. Le level design n'y peut rien.

135. **LA CONTENTION SE MESURE SUR LES PILES DE DEUX, ET C'EST UNE LIMITE
     REELLE DE L'INSTRUMENT.** Contention R2/R3 = 5 sur N5, et pourtant
     `[2,3,1]` et `[3,2,1]` sont identiques. Ce n'est pas contradictoire : la
     contention est mesuree sur `[2,3]` et `[3,2]`, qui n'atteignent jamais les
     memes etats que les piles de trois — sans R01, la nuee n'avance pas
     pareil. **L'instrument mesure sur une trajectoire, et l'on raisonne sur
     une autre.**
     A retenir pour les chapitres a douze regles, ou les piles de quatre seront
     la norme : la contention par paire restera un detecteur binaire utile
     (« l'ordre peut-il compter ? »), et jamais une prediction de ce que fera
     une pile plus longue.

136. **QN-03 : PAS DE SEUIL, ET LA DISTRIBUTION DIT POURQUOI** (arbitrage du
     concepteur). Les chiffres ne sont pas a calibrer, ils revelent un fait :
     **seuls les objectifs de PRESERVATION produisent de la frustration
     productive.** Perdre de peu n'existe qu'en comptant des agents ; une
     extraction ratee l'est de 20 a 25 %, ce qui n'est pas « proche ».
     Un plancher opposable rendrait donc la preservation **obligatoire
     partout** et appauvrirait le vocabulaire d'objectifs. Le seuil reste
     **vide**, a reprendre avec de vrais joueurs.
     **Effet de bord a rendre deliberatif** : N5 est le seul niveau ou l'on
     echoue de peu, donc le seul ou l'on veut reessayer tout de suite. Bien
     place pour une cloture — mais c'est un **accident**, pas une intention.
     Aux chapitres suivants, placer sciemment les niveaux a forte densite
     d'echecs proches.

137. **UN ZERO SE VERIFIE COMME UN CHIFFRE INATTENDU — troisieme forme du meme
     piege.** Apres « paraitre correct clot l'examen » et « paraitre casse clot
     l'examen » (invariant n.12), voici la plus insidieuse : **un instrument
     qui mesure la mauvaise quantite produit un zero parfaitement credible.**
     Les deux faux zeros de QN-03 :
     - le manque « tous objectifs confondus » masquait la preservation — une
       partie perdue au tick 6 a forcement zero agent sorti ;
     - la simulation coupee A l'echeance rendait le depassement de celerite
       structurellement nul.
     Aucun des deux ne ressemblait a un bug. Zero echec proche sur cinq
     niveaux est une conclusion plausible, presque elegante — et fausse.

---

## Arbitrages de chef de projet (9 aout 2026)

126. **DOSSIER DE LA REVISION DES GENRES : L'ARGUMENT DE L'ARCHETYPE MANQUANT
     EST RETIRE.** Les decisions 33 et 34 justifiaient le genre « filtre » par
     deux motifs : le cycle de frontiere, et le fait que deux des quatre
     archetypes du CDC §7.3 soient indiscernables. **Le second n'existe pas** —
     c'etait une erreur de mesure, pas un symptome d'architecture (decision
     122). Il est retire du dossier.
     **Les deux motifs qui restent, et ils sont reels :**
     - **le cycle de frontiere** — propriete de la cascade elle-meme, premier
       match gagnant SANS HYSTERESIS. Constate entre R01/R02 (dec. 31) et
       entre R01/R03 (dec. 112) : ce n'est pas une affaire de regle
       particuliere ;
     - **la stigmergie de R08** — deposer un marqueur n'est pas proposer un
       deplacement. Sous le genre « proposeur », soit la regle s'abstient et
       n'est pas dans la pile, soit elle propose l'immobilite et masque tout
       ce qui suit. Le chapitre 3 est entierement bati dessus.
     Entamer la revision avec l'argument de l'archetype serait entamer avec un
     **argument fantome** — et c'est le genre d'erreur qui fait trancher une
     question structurante dans la mauvaise direction.

127. **L'INVARIANT n.12 FONCTIONNE DANS LES DEUX SENS, ET C'EST LA MOITIE QUE
     J'AVAIS MANQUEE.** Je l'avais ecrit ainsi : « un mecanisme observe la ou
     il n'a rien a faire parait toujours correct ». Le symetrique est tout
     aussi vrai et bien plus couteux : **un mecanisme juge casse la ou il n'a
     rien a faire parait casse.** Les deux cloturent l'examen.
     **Un constat d'echec doit etre etabli sur le terrain qui SOLLICITE le
     mecanisme, exactement comme un constat de succes.** Trois semaines de
     carnet ont porte « EQ-05 definitivement viole, fait acquis » parce que la
     mesure avait ete faite sur des blocs compacts, ou les archetypes n'ont
     rien a exprimer. Une affirmation fausse consignee coute plus cher qu'une
     absence de consignation : elle est relue comme un fait.

128. **N3 RESTE CHARGE, ET C'EST LA RAISON QUI COMPTE.** Le niveau porte trois
     choses a la fois : l'apparition de la cohesion, le compromis
     vitesse/securite du CDC §8.5, et la lecon « la cohesion est aveugle ».
     C'est aussi le seul niveau ou les quatre archetypes se separent.
     **Les deux faits sont le meme fait.** Une geometrie qui sollicite trois
     regles simultanement est une geometrie riche, et la richesse produit a la
     fois la separation ET la surcharge. Alleger N3 reviendrait tres
     probablement a perdre la separation — donc a reperdre EQ-05, qui vient
     tout juste d'etre etabli.
     Le lien est consigne plutot que corrige. **L'arbitrage se tranchera avec
     de vrais joueurs, pas avant** : « trop charge » est un jugement qui
     demande quelqu'un qui decouvre, et personne dans ce projet ne decouvre.

129. **QN-03 EST MESUREE. Chiffres du chapitre, seuil toujours non fixe.**

     | Niveau | Echecs proches | Perdantes | Ratio |
     |---|---|---|---|
     | ch1_01 | 0 | 1 | 0 % |
     | ch1_02 | 0 | 4 | 0 % |
     | ch1_03 | 0 | 8 | 0 % |
     | ch1_04 | 0 | 9 | 0 % |
     | ch1_05 | **5** | 10 | **50 %** |

     Un seul niveau produit de la frustration productive, et c'est celui ou
     l'on perd **par un agent sur vingt et un** — 4 % de manque. Ailleurs on
     echoue de loin : 20 a 25 % en N2 et N4, 95-100 % pour les piles sans
     moteur.
     **Deux faux zeros corriges en route**, et ils valent d'etre notes :
     - mesurer le PIRE manque tous objectifs confondus donnait zero partout :
       une partie perdue au tick 6 sur une preservation a forcement zero agent
       sorti, donc 95 % de manque d'extraction — qui masquait la vraie cause,
       un seul agent perdu. On mesure desormais **l'objectif qui a
       reellement fait perdre**, dans l'ordre du moteur ;
     - pour la celerite, la simulation s'arrete A l'echeance, donc le
       depassement valait toujours zero. On **rejoue la pile sans l'echeance**
       pour savoir quand elle aurait gagne. ch1_04 passe ainsi d'un faux 0 % a
       un vrai 25 % de manque pour la famille prudente.
     Le seuil plancher reste au concepteur : l'outil mesure, il ne juge pas.

130. **LA CONTENTION N'EST PAS UNE MESURE DE VISIBILITE — correction de ma
     propre decision 123.** J'avais pose comme condition prealable a N5 que la
     contention R2/R3 y soit « strictement positive », en laissant entendre
     qu'une contention faible donnerait une separation faible.
     **Balayage de dix-huit geometries candidates : c'est faux.** Toutes
     separent `[2,3,1]` de `[3,2,1]`, de 11 a 39 ticks d'ecart et jusqu'a 35
     cases — **y compris celles dont la contention vaut 1 ou 2**.
     La raison est evidente apres coup : **une seule decision divergente
     cascade**. Un agent qui part a gauche plutot qu'a droite change sa
     position, donc celles de ses voisins au tick suivant, donc tout l'aval.
     Un agent-tick de contention suffit a produire deux nuees differentes.
     **Ce que la contention mesure vraiment : SI l'ordre compte, jamais
     COMBIEN.** Zero = l'ordre est inobservable ; tout ce qui est au-dessus de
     zero se mesure a la trajectoire, pas au compteur. C'est la trajectoire
     qui doit entrer dans les fiches, et la contention qui doit rester un
     detecteur binaire.

131. **N5 EST DONC FAISABLE, et la condition est bien plus facile que je ne le
     croyais.** Il suffit d'un trainard isole dont la route croise un danger —
     la recette de ch1_03. Meilleure candidate mesuree : **deux trainards,
     danger au niveau du bloc, contention R2/R3 = 12, separation 39 ticks /
     35 cases, 8 piles gagnantes**.
     Reserve a lever au dessin : ces candidates laissent 3 a 8 piles en
     boucle. C'est acceptable pour des piles perdantes, inacceptable pour une
     gagnante (le joueur y verrait un bug) — le validateur le signale deja
     pile par pile.

---

## Audit du chapitre 1 : ce que la mesure des ORDRES revele (9 aout 2026)

122. **EQ-05 N'EST PLUS VIOLE — la decision 34 est PERIMEE et se corrige ici.**
     Le 6 aout, constat a l'oeil et a l'empreinte : « Fuir > Grouper > Lumiere »
     et « Grouper > Fuir > Lumiere » sont indiscernables, deux des quatre
     archetypes du CDC §7.3 sont le meme comportement, « fait acquis qui
     attend la revision d'architecture ».
     **C'etait vrai de la geometrie d'alors, pas des regles.** Mesure du jour
     sur ch1_03, trajectoire par trajectoire (nombre de ticks ou les positions
     different, ecart maximal d'un meme agent) :

     | Paire | Ticks differents | Ecart max |
     |---|---|---|
     | `[2,3,1]` vs `[3,2,1]` | 13 | 27 cases |
     | `[2,3,1]` vs `[1,2,3]` | 24 | 33 cases |
     | `[2,3,1]` vs `[2,1]` | 5 | 25 cases |
     | `[3,2,1]` vs `[1,2,3]` | 24 | 33 cases |
     | `[3,2,1]` vs `[2,1]` | 12 | 27 cases |
     | `[1,2,3]` vs `[2,1]` | 24 | 33 cases |

     Les six paires different, et les issues aussi : `[3,2,1]` PERD la ou les
     trois autres gagnent. **Les quatre archetypes du CDC §7.3 sont donc
     visiblement et strategiquement distincts sur ch1_03.**
     Ce n'etait pas un probleme de parametrage : c'etait un probleme de
     TERRAIN. Un archetype ne se manifeste que sur une geometrie qui le
     sollicite — invariant n.12, encore lui.

123. **MAIS `[2,3,1]` ET `[3,2,1]` SONT IDENTIQUES SUR N4 ET N5 — zero tick
     d'ecart.** Et cela invalide le plan de la decision 118 tel quel.
     Faire gagner les deux sur N5 devait demontrer que « deux ordres
     differents reussissent ». Or aujourd'hui, sur N5, **ce ne sont pas deux
     ordres : c'est deux noms de la meme trajectoire.** Le niveau
     enseignerait une pluralite qui n'existe pas — un pluralisme creux, pire
     qu'une solution unique parce qu'il ment.
     **Condition prealable, mesurable, a inscrire dans la fiche de N5 : la
     contention R2/R3 doit y etre STRICTEMENT POSITIVE.** Elle vaut 0
     aujourd'hui. Tant qu'elle vaut 0, les deux piles ne peuvent pas differer,
     quelle que soit l'issue qu'on leur donne. C'est ch1_03 qui montre la
     recette : contention R2/R3 = 6 y suffit a produire 13 ticks d'ecart.

124. **`[1,x]` est invisible partout, et c'est structurel, pas un defaut.**
     `[1,2,3]` vs `[1,3,2]` : zero tick d'ecart sur les trois niveaux. R01 ne
     s'abstient jamais en terrain ouvert, donc tout ce qui la suit est mort.
     Deja documente depuis S2 ; la mesure le confirme sur les cinq niveaux.
     A ne pas confondre avec 123 : ici l'invisibilite est une propriete de la
     cascade, la-bas c'est un manque de terrain.

125. **DEUX EXIGENCES DU CDC N'ETAIENT PAS TENUES.**
     - **§8.5 — « l'ecran de bilan mentionne N solutions connues »** : absent.
       Corrige. Le chiffre vient de `expected_wins`, donc du validateur, jamais
       d'une estimation — annoncer une pluralite non mesuree ferait de P5 une
       affirmation gratuite. Les niveaux TUTORIELS se taisent : annoncer
       « 1 solution connue » suggererait qu'on en cherche d'autres.
     - **QN-03 — densite d'echecs proches** (piles echouant a moins de 10 % de
       l'objectif) : **jamais mesuree**. Le CDC lui donne un seuil plancher
       ⚙️ non fixe. Ni implementee dans le validateur, ni chiffree dans le
       CDC : signale, non corrige — fixer un seuil est un arbitrage de
       conception.

---

## Cause commune, et quatre arbitrages (9 aout 2026)

116. **UN CHANGEMENT NE SE LIVRE PAS PARCE QU'IL A COUTE CHER.** Enonce du
     concepteur, verse ici tel quel. Le cout deja engage n'est pas un
     argument : il ne dit rien de la valeur de ce qu'on livre. L'impasse de
     N3 a demande une journee, elle fonctionnait, et elle rendait le chapitre
     pire sur la propriete qui compte le plus. Elle n'est pas livree.

117. **LE CYCLE DE FRONTIERE EST ARCHITECTURAL, PAS UNE AFFAIRE DE LEVEL
     DESIGN — amendement a la decision 30.** J'avais formule la loi comme une
     contrainte de dessin : « une impasse ne se franchit que si la regle qui
     en sort decide avant celle qui y mene ». C'est vrai, mais c'est un
     symptome. La cause est **la cascade elle-meme** : premier match gagnant,
     **sans hysteresis**. Deux regles qui se contredisent de part et d'autre
     d'un seuil se renvoient l'agent indefiniment, et **aucune geometrie ne
     peut l'empecher partout**.

     Le dossier de la decision 30 recense trois besoins que le genre
     « proposeur » n'exprime pas. Ils ont tous les trois **la meme cause** :

     | Pathologie | Manifestation | Ce qui manque |
     |---|---|---|
     | R03 forcait sans condition | gel de la nuee (dec. 20-24) | genre **condition de maintien** |
     | L'evitement pur est inexprimable | R02 repousse au lieu d'eviter (dec. 33) | genre **filtre** |
     | **Cycle de frontiere** | R01/R02 (dec. 31), **R01/R03 (dec. 112)** | **hysteresis / etat de decision** |

     Ce n'est plus une necessite pour R08 seulement : c'est la **cause commune
     de trois pathologies deja rencontrees**, dont deux dans le chapitre 1.
     La revision des genres de regles cesse d'etre une preparation du
     chapitre 3 ; elle repare le chapitre 1. Echeance inchangee — apres J-1,
     la question est structurante et ne se tranche pas sous calendrier.

118. **N5 EST LE NIVEAU DE LA PAIRE INSEPARABLE — arbitrage du concepteur, et
     il corrige mon plan.** Mon plan a cinq solutions minimales distinctes
     assignait une pile par niveau, N5 compris. Cela **contredisait le CDC
     §8.5**, qui lui assigne « il n'y a pas UNE bonne reponse » : une solution
     minimale unique enseigne exactement l'inverse.
     N5 accueille donc `[2,3,1]` **et** `[3,2,1]`, toutes deux gagnantes.
     L'inversion est elegante : au lieu de separer une paire quasi
     inseparable, le niveau **demontre que deux ordres differents reussissent**
     — ce qui est litteralement sa lecon.
     **Mesure prealable (invariant n.12), faite avant de dessiner** : la
     contention R2/R3 vaut **6 en N3, 3 en N4, 0 en N5**. Sous dix agents-ticks
     partout : la distinction entre ces deux ordres est **imperceptible**, et
     N5 est le seul endroit du chapitre ou cela n'a aucune importance.
     N1 a N4 portent les quatre autres piles minimales : `[1]`, `[2,1]`,
     `[3,1]`, et l'une des deux mixtes.

119. **INTERDICTION : oui, et c'est un choix assume.** Aucune regle ne repond
     a une zone interdite — R02 fuit ce qui TUE, pas ce qui est DEFENDU. Un
     niveau a interdiction se resout donc **par la geometrie et l'ordre
     seuls** : c'est le premier objectif auquel aucune regle ne reagit, un
     puzzle de routage pur.
     Ce n'est pas un defaut a corriger, c'est la propriete du type. Elle rend
     **R06 « Longer le mur » nettement plus utile** : contourner une zone
     defendue sans qu'aucune regle ne la percoive, c'est exactement ce qu'un
     suiveur de mur sait faire.

120. **PORTE A PRESSION : MUR, JAMAIS MORT.** Une porte qui tue est un danger
     de plus, et R02 y repondrait — cela **brouille le vocabulaire au lieu de
     l'etendre**. Une porte qui bloque introduit un **obstacle conditionnel**,
     categorie qui n'existe pas encore dans le jeu : c'est la qu'est la
     valeur. Une case qui change d'etat sans jamais changer de nature.

121. **VERIFICATION DEMANDEE : le corpus decrit bien le ch1_03 REVENU EN
     ARRIERE.** Une ceremonie suivie d'un revert est exactement l'enchainement
     ou une empreinte se retrouve a decrire un niveau disparu. Confronte
     explicitement plutot que deduit du test vert :

     | Pile | Archive | Attendu (revert) | A ne pas voir (impasse) |
     |---|---|---|---|
     | `[1]` | `1cf5bf4b…` | `1cf5bf4b…` | `8e42f972…` |
     | `[2,1]` | `d3b694c9…` | `d3b694c9…` | `4f8c7b8f…` |
     | `[2,3,1]` | `ed6ba9a0…` | `ed6ba9a0…` | `329491c5…` |
     | `[3,1]` | `8047c635…` | `8047c635…` | `fcacd92f…` |

     Et le niveau lui-meme : 21 agents (22 avec l'impasse), 8 murs (12),
     `expected_wins: 8` (2), `calibrated_on: 418a5244…` (`941c31ad…`).
     Aucune empreinte orpheline.

---

## L'impasse : un mecanisme qui marche et qu'on ne livre pas (9 aout 2026)

111. **L'ABSTENTION DE R01 EST LE SEUL LEVIER DE PROFONDEUR DU CHAPITRE 1, ET
     IL FONCTIONNE.** R01 ne se tait que si aucune direction franchissable ne
     rapproche. Une impasse muree au Nord, a l'Est et a l'Ouest la fait taire :
     c'est la premiere fois du chapitre que la suite de la pile a la parole.
     Mesure : avec une impasse en (2,4) et un eclaireur seul dans la colonne 2,
     **la pile [Lumiere] seule ne resout plus N3**. Le mecanisme n'est pas une
     hypothese.

112. **LA LOI DU CYCLE LIMITE EST PLUS GENERALE QUE SA PREMIERE FORMULATION.**
     Sonde tick par tick sur l'impasse : R03 sort bien l'eclaireur par le Sud
     (t=5, t=7), mais R01 l'y renvoie a la case suivante (t=4, t=6, t=8), puis
     le bloc passe au Nord, R03 s'abstient a son tour et l'agent reste coince.
     L'invariant n.14 parlait d'un repulseur a seuil et d'un attracteur. Le
     vrai enonce est plus large : **deux regles qui se contredisent a une
     frontiere produisent un cycle, quelles qu'elles soient** — ici un
     attracteur et la COHESION.
     Consequence de level design, opposable : **une impasse ne se franchit que
     si la regle qui en sort decide AVANT celle qui y mene.** R03 derriere R01
     ne parle qu'une case sur deux ; devant elle, elle sort l'agent et le
     garde dehors.

113. **ET C'EST POURQUOI JE NE L'AI PAS LIVRE.** Le corollaire de 112 est que
     **[3,1] devient la seule pile capable de franchir une impasse**. En
     ajoutant l'impasse a N3, [1] cessait de gagner N3 — mais [3,1] se mettait
     a gagner N3, N4 **et** N5. Le plafond de transposabilite restait a trois,
     l'offenseur changeait seulement d'identite, et le chapitre devenait pire
     sur la propriete que le concepteur juge la plus importante.
     **Un changement qui corrige un defaut en aggravant un autre ne se livre
     pas parce qu'il a coute cher.** Le niveau est revenu a son etat anterieur ;
     le savoir reste ici.

114. **LA FORME QUE DOIT PRENDRE LE CHAPITRE, ET ELLE EST CALCULABLE.** Avec
     trois regles, les comportements distincts atteignables sont exactement
     cinq : `[1]`, `[2,1]`, `[3,1]`, `[2,3,1]`, `[3,2,1]`. Cinq niveaux, cinq
     solutions minimales : **une par niveau, aucune transposable**, et le
     plafond tombe a un.
     Les deux dernieres exigent une pile de TROIS regles, donc **deux pieges
     independants dans le meme niveau**, chacun demandant un sauveteur
     different. C'est possible sans violer l'invariant n.13, qui n'interdit que
     deux DANGERS : un piege peut etre une impasse (des murs, aucun danger) et
     l'autre un danger. L'ordre relatif des deux sauveteurs departage alors
     `[2,3,1]` de `[3,2,1]`.
     C'est le plan du prochain lot, et il satisfait d'un coup S1, S2, S3 et la
     regle S4 du concepteur.

115. **REGLE S4, posee par le concepteur : une pile d'UNE SEULE REGLE ne peut
     gagner que le niveau qui INTRODUIT cette regle.** Partout ailleurs il
     faut au moins deux regles, donc un ordre, donc la regle d'or.
     Transcrite en test avec ses manquements nommes — `ch1_03:1` et
     `ch1_04:1` — et un second test qui verifie que ces manquements sont
     **encore reels** : une exception qu'on repare sans mettre a jour la liste
     laisserait le test proteger un trou qui n'existe plus.

---

## Deux regles portees par des outils (8 aout 2026)

109. **UN PARAMETRE CALIBRE EST UN PARAMETRE DE LA CARTE, PAS DU NIVEAU.**
     Generalisation de ce que l'echeance de N4 a montre : calibree a 19 sur
     une bande pleine largeur, elle ne laissait plus qu'UN tick de marge apres
     le passage a l'entonnoir. Le niveau ne validait plus la meme chose sans
     que rien dans son en-tete n'ait bouge.
     Cela vaut pour **tout** parametre mesure : echeance de celerite, seuil de
     preservation, pourcentage d'extraction, limite de ticks. Un mur deplace
     d'une case change des temps de parcours, donc des marges, donc des
     verdicts.
     **Rendu mecanique** (decision 103 : une note ne protege de rien) : chaque
     `.lvl` porte `calibrated_on`, l'empreinte de sa geometrie — grille et
     positions initiales. Le convertisseur la recalcule et REFUSE le niveau si
     elle differe. C'est le dispositif du `rules_hash` des recettes d'or,
     transpose : distinguer « le code a regresse » de « l'entree a change ».

110. **LA CONSIGNATION NE VIT QUE SUR `main`.** Regle elargie apres le
     quatrieme incident du meme genre : une perte silencieuse decouverte par
     hasard. Ma formulation precedente — « une consignation ne voyage pas dans
     une branche au sort incertain » — etait trop etroite : TOUTE branche de
     travail peut etre abandonnee, reecrite ou fermee.
     Carnet, invariants et decisions se poussent sur `main` **des qu'ils sont
     ecrits**, par une PR dediee fusionnee immediatement, jamais en passager
     d'un lot technique dont l'issue n'est pas acquise. Une lecon perdue coute
     plus cher que la lecon elle-meme : elle sera reapprise au meme prix.

---

## Idiome de niveau et garde-fous de geometrie (8 aout 2026)

104. **IDIOME DE NIVEAU PAR DEFAUT, tous chapitres : la lumiere est derriere
     le mur, la sortie est l'ouverture.** *La nuee ne va pas vers la sortie :
     elle va vers la lumiere, et le mur l'oblige a passer par l'ouverture.*
     Ce que ca resout, et pourquoi ce n'est pas cosmetique :
     - la lumiere posee sur la bande de sortie faisait dire **la meme chose au
       meme endroit** a deux marques distinctes. Le concepteur l'a vu tout de
       suite : « c'est soit la lumiere soit le vert, mais pas les deux » ;
     - pire, ca transformait R01 en **moteur qui va seul au but**. La
       profondeur annoncee par la regle d'or devenait decorative, et plusieurs
       niveaux se resolvaient avec une seule regle ;
     - l'idiome produit **gratuitement un entonnoir** : R01 teste le Nord, le
       mur le bloque, il glisse vers l'ouverture. Congestion, forme collective
       lisible, dispositif compris sans un mot.
     Applique aux cinq niveaux. Inscrit dans docs/ARCHITECTURE.md comme point de depart
     de toute carte : s'en ecarter demande une raison ecrite dans la fiche.

105. **LE DANGER CYCLIQUE NE TIENT PAS SA PROMESSE, ET LA MESURE LE DIT.**
     L'hypothese etait forte : une seule piece punissant trois familles
     differemment parce qu'elle agit sur le QUAND — R03 changerait l'heure
     d'arrivee en regroupant, R02 en detournant, R01 foncerait. Elle
     contournerait ainsi l'invariant n°13, qui interdit deux dangers statiques.
     **Balayage complet (periode 6 a 12, toutes phases actives) : aucun calage
     ne fait gagner [3,1] pendant que [1] perd.** La raison est structurelle :
     **R03 est un predicat de MAINTIEN — elle ne ralentit jamais une nuee deja
     compacte.** Elle deplace un trainard vers le groupe ; elle ne fait pas
     attendre le groupe. Le cyclique separe donc la prudence des deux autres,
     jamais la vitesse de la cohesion.
     **Ce qui reste vrai et vaut d'etre garde** : un danger cyclique peut se
     placer plein nord dans l'entonnoir, la ou un danger statique est interdit
     par l'invariant n°14 — ses phases dormantes relachent R02 et brisent le
     cycle limite. Outil reel, mais pour un autre usage que celui qu'on lui
     pretait. N5 conserve donc son danger statique et l'arc du chapitre
     intact, plutot que d'echanger l'arc contre un mecanisme qui ne separe
     qu'en deux.

106. **QUATRIEME RECIDIVE, ET FIN DU MOTIF : LES TROIS CONTRAINTES DE
     GEOMETRIE PASSENT DANS LE CONVERTISSEUR.** L'invariant n°14 a ete viole
     dix minutes apres son ecriture, sur le premier niveau redessine. La
     decision 103 s'applique a elle-meme : une note ne protege de rien.
     - **G1** — danger plein nord d'un agent, a portee de fuite :
       AVERTISSEMENT. Pas un refus, parce que la configuration reste jouable
       si la fuite laterale mene quelque part (cas de N2).
     - **G2** — fuite et entonnoir tirant en sens opposes : AVERTISSEMENT.
     - **G3** — deux dangers statiques encadrant un meme agent : **REFUS**.
       Aucune geometrie ne rattrape ca : insoluble par construction.
     Chacun a rendu un niveau insoluble au moins une fois pendant ce lot, et
     le diagnostic coutait alors une simulation de seize piles ; il coute
     maintenant une lecture de grille. Les trois sont eprouves par des tests
     sur la geometrie fautive, plus un test qui verifie qu'une geometrie saine
     **ne declenche rien** — un controle qui crie tout le temps ne vaut pas
     mieux qu'un controle muet.

107. **Limite assumee des trois controles** : ils raisonnent sur les positions
     INITIALES. Le cycle limite peut naitre d'une position atteinte en cours
     de partie, et G1 ne le verra pas — N2 en est l'exemple, son danger est
     hors de portee au depart. Le detecteur empirique du validateur (boucles,
     oscillations) reste la seconde ligne. L'un nomme la cause avant de
     simuler, l'autre attrape ce que la statique ignore.

108. **UNE BRANCHE SUPPRIMEE EMPORTE CE QU'ELLE PORTAIT.** En fermant la PR
     de la ceremonie d'or et en supprimant sa branche, j'ai efface du meme
     geste les decisions 102 et 103 et les invariants 13-14 de docs/ARCHITECTURE.md —
     qui n'avaient rien a voir avec le corpus d'or et que le concepteur avait
     explicitement demande de consigner. Recuperes depuis le commit orphelin.
     **Regle : une consignation ne voyage jamais dans une branche dont le
     sort depend d'une decision en attente.** Ce qui doit survivre a un refus
     se commite separement, sur une branche qui sera fusionnee quoi qu'il
     arrive.

---

## Deux faits de conception, écrits pour servir (8 août 2026)

102. **LE RAPPORT DES PORTÉES BORNE LES GÉOMÉTRIES POSSIBLES.** Fait de
     conception réutilisable, pas anecdote de N3.

     **Énoncé.** Un danger assez proche pour border un traînard lui-même perçu
     par le bloc est **nécessairement perçu par le bloc**. La raison est
     arithmétique et ne dépend d'aucun niveau : la portée de R02 (d² ≤ 25) est
     plus large que celle de R03 (d² ≤ 16). Pour que R03 tire un traînard, il
     faut qu'il perçoive le groupe — donc qu'il en soit à d² ≤ 16. Un danger
     collé à ce traînard est alors à d² ≲ 25 du groupe, c'est-à-dire **dans**
     la portée de R02. On ne peut pas isoler l'un sans exposer l'autre.

     **Conséquence de dessin.** Toute géométrie qui met un répulseur au
     service d'un seul agent agit aussi sur la nuée entière. Deux répulseurs
     en vis-à-vis créent donc un bassin dont la famille prudente ne sort
     jamais — mesuré sur N3 : 10 agents sur 22 en boucle au tick 12.

     **Portée générale.** Cela vaudra pour tout couple (règle à portée large,
     règle à portée étroite) des chapitres suivants, et pas seulement pour
     R02/R03. La question à se poser avant de dessiner : *quelle est la plus
     large des portées en jeu, et qui d'autre entre dedans ?*

     **Cela explique rétrospectivement pourquoi les premières fiches ne
     pouvaient pas fonctionner.** Elles plaçaient des dangers pour punir une
     famille en supposant que les autres ne les verraient pas. Aucune n'a
     échoué par manque de soin : elles échouaient parce que la géométrie
     qu'elles supposaient n'existe pas.

103. **UNE NOTE NE PROTÈGE DE RIEN ; SEULE UNE CONTRAINTE DE DESSIN PROTÈGE.**
     À écrire au-dessus des trois occurrences, parce que le motif est plus
     instructif qu'aucune d'elles.

     | Leçon consignée | Récidive | Ce qui a manqué |
     |---|---|---|
     | Décision 67 — le patch textuel muet | 2 fois après | une note |
     | Décision 12 — le cas d'épreuve confortable | 3 fois | une note |
     | **Décision 31 — le cycle limite de portée** | **reprise ici, sur N4** | une note |

     Trois leçons différentes, un seul motif : **la leçon était écrite au
     bon endroit, elle a été relue, et elle n'a pas servi.** Une note décrit un
     accident passé ; elle ne se présente pas au moment où l'on est sur le
     point de le refaire. C'est le moment qui compte, pas le classement.

     **La forme qu'une leçon doit prendre pour servir.** Comparer les deux
     rédactions de la même chose :

     - *décrit* (décision 31, telle qu'elle était) : « un répulseur à seuil dur
       combiné à un attracteur oscille à la frontière de portée ». Vraie,
       complète, inutile au moment de placer une case.
     - **opératoire** : « **un répulseur à seuil dur ne se place jamais là où
       fuir ramène dans le seuil** ». Même contenu, mais formulé comme un
       INTERDIT DE GESTE : elle se déclenche à l'instant où l'on pose le
       danger, pas quand on relit le carnet.

     Le critère : une leçon sert si elle est rédigée comme une **contrainte
     sur l'acte** — ce qu'on n'a pas le droit de dessiner, d'écrire ou
     d'appeler — et non comme la description du phénomène qui l'a motivée.
     Quand la contrainte peut être portée par un outil plutôt que par une
     phrase, c'est encore mieux : le crochet de la décision 96 vaut mieux que
     les deux notes qui l'ont précédé. **Une leçon qui reste une phrase doit
     au moins être une phrase à l'impératif.**

---

## Chapitre 1 terminé — N3, N4, N5 conçus et validés (8 août 2026)

97. **L'ARC QN-02 TIENT, ET IL EST PROUVÉ PAR SIMULATION.** Trois familles,
    chacune gagnante sur exactement deux niveaux, aucune pile sur les trois.

    | Famille | N3 | N4 | N5 | Ce qu'elle apprend |
    |---|---|---|---|---|
    | A — R01 en tête | **G** | **G** | P | la vitesse saigne dès qu'un traînard suit sa route dans le feu |
    | B — R02 en tête | **G** | P | **G** | la prudence ne perd pas d'agent, elle perd des ticks |
    | C — R03 en tête | P | **G** | **G** | la cohésion est aveugle avant d'être utile |

    Intersection des trois ensembles gagnants : **vide**. Ce n'est pas une
    affirmation de fiche — `tests/unit/test_chapter1_arc.gd` simule les 16
    piles sur les 3 niveaux à chaque exécution et le vérifie. Une retouche de
    grille qui casserait l'arc le dirait là, pas six semaines plus tard sur un
    téléphone.

98. **LE RETOURNEMENT DE R03 EST LE SUJET DU CHAPITRE.** En N3 la cohésion
    TUE le traînard : elle le tire vers le groupe, le feu est sur le chemin.
    En N5 elle le SAUVE : le feu est sur sa route naturelle vers la lumière,
    et rejoindre le groupe l'en écarte. **Même règle, même portée, même
    prédicat de maintien — seule la géométrie a changé.** Le joueur qui a
    appris « R03 est dangereuse » doit désapprendre. C'est l'application
    directe de la décision 54 : l'effet de R03 est invisible sous une
    extraction, décisif sous une préservation. Les deux niveaux portent donc
    `preservation 0` avec une extraction volontairement atteignable (90 % et
    95 %) : **c'est la préservation qui tranche, jamais le compte de sortis.**

99. **DEUX CONTRAINTES DE GÉOMÉTRIE DÉCOUVERTES À LA MESURE**, et aucune des
    deux n'était devinable sur le papier :
    - **Le rapport des portées interdit les dangers en vis-à-vis.** R02 perçoit
      à d² ≤ 25, R03 à d² ≤ 16 : un danger assez proche pour border un
      traînard lui-même perçu par le bloc est *nécessairement* perçu par le
      bloc. Deux dangers symétriques ont donc mis 10 agents sur 22 dans un
      bassin dont la famille prudente ne sortait jamais. Un seul suffit.
    - **Le cycle limite de portée (décision 31) m'a repris.** Traînard en
      (0,10) sur N4 : R02 y fuit vers le sud, l'agent sort de portée, R01 le
      renvoie au nord, il rentre en portée. Boucle infinie, mesurée. Règle qui
      en sort : **un répulseur à seuil dur ne doit jamais être placé là où
      fuir ramène dans le seuil.** En (3,9) la fuite part à l'est, dx croît à
      chaque pas, l'agent quitte la portée pour de bon.

100. **LE VALIDATEUR A CORRIGÉ MES PRÉDICTIONS TROIS FOIS SUR TROIS NIVEAUX,
     ET C'EST SON MÉTIER.** N3 prédit 8 gagnantes en 2 classes, mesuré 8 et
     **3** — `[2,3,1]` se sépare de `[2,1]` parce que R03 reprend la main sur
     le traînard une fois R02 hors de portée. N4 prédit 11, mesuré 9 puis 11
     après correction de la boucle. L'échéance de N4 (**celerity 19**) est
     posée APRÈS mesure, entre 13 ticks (direct) et 26 (prudent) : 6 ticks de
     marge d'un côté, 7 de manque de l'autre, aucune famille sur le fil.
     **Aucun chiffre de ces trois niveaux n'a été choisi avant d'être mesuré.**

101. **UN NIVEAU N'A PAS À RENDRE TOUS LES ORDRES OBSERVABLES ; LE CHAPITRE
     SI.** Le validateur signale les paires à contention nulle (RG-13/EQ-06).
     N5 laisse R2/R3 à zéro — leurs zones d'action ne s'y recouvrent jamais.
     Accepté, parce que la paire est observable en N3 (6) et N4 (3). En
     revanche j'ai **ajouté un traînard à N4** uniquement pour cette raison :
     sans lui, R1/R3 et R2/R3 valaient tous deux zéro, et le niveau ne disait
     rien de la place de R03 dans la pile.

---

## Parades mécaniques et critère du cas d'épreuve (8 août 2026)

95. **LE CAS D'ÉPREUVE EST CELUI OÙ LE MÉCANISME EST SOLLICITÉ, JAMAIS CELUI
    OÙ IL EST CONFORTABLE.** Formulé ici comme **critère de conception**, pas
    de test — c'est là qu'il sert, et c'est là qu'il a manqué.
    Trois fois le même piège, dans trois domaines sans rapport :
    - **R03** : trois semaines à la juger sur des nuées compactes, où elle n'a
      rien à maintenir. Les archétypes ne se séparent que sur une nuée
      **dispersée près d'un danger**.
    - **Contention R2/R3** : nulle sur un bloc compact, 15 à 23 sur une nuée
      dispersée. Mesurée sur le cas confortable, elle affirmait « ces deux
      règles ne se disputent jamais » — faux.
    - **Cadrage plein écran** : juste par accident sur le ratio haut, où la
      grille est limitée en largeur. Faux uniquement sur le **ratio court**,
      le seul où le calcul de hauteur travaille.
    Le point commun n'est pas la négligence : c'est qu'un mécanisme observé là
    où il n'a rien à faire **paraît toujours correct**. Paraître correct est
    exactement ce qui coûte cher, parce que ça clôt l'examen.
    **Application directe à N3-N5** : un niveau censé départager des familles
    de piles se dessine sur la géométrie où elles divergent, et se vérifie là.
    Une grille où les trois familles se comportent pareil ne prouve rien, même
    si elle se joue bien — et c'est précisément ce qui rendait les fiches
    invalidées séduisantes. Inscrit en invariant n°12 (docs/ARCHITECTURE.md).

96. **UNE ENTRÉE AU CARNET N'A PAS EMPÊCHÉ SA PROPRE RÉCIDIVE.** Le
    remplacement textuel muet a frappé trois fois, la dernière **après** que
    la leçon ait été écrite (décision 67). Ce qui est seulement déconseillé
    finit par être fait : la parade devait cesser d'être documentaire.
    Elle est désormais **mécanique**, à deux niveaux :
    - `tools/dev/patch.py`, crochet `PreToolUse` sur Bash :
      il refuse `sed -i`, `perl -i` et tout script Python combinant
      `.replace()`/`re.sub()` avec une écriture de fichier, dès lors qu'une
      source du dépôt est visée. Aucun chemin d'édition ne le contourne — il
      s'exécute avant la commande, pas après une décision.
    - `tools/dev/patch.py` pour les lots d'éditions : chaque ancre doit
      correspondre à un nombre EXACT d'occurrences ; si une seule manque,
      **rien n'est écrit** et le code de sortie est 1.
    Les deux ont été éprouvés sur le cas réel — l'ancre `var title` absente de
    `summary_screen.gd` — et non sur un cas d'école. C'est l'invariant n°12
    appliqué à sa propre parade.

---

## Le jeu au premier plan (8 août 2026)

89. **L'ÉCRAN DE JEU RESSEMBLAIT À UN ÉCRAN DANS UN ÉCRAN.** La vue occupait
    un rectangle découpé entre les barres, et le plateau portait une dalle
    plus claire cerclée d'un pourtour net. Les deux ensemble dessinaient une
    BOÎTE : le jeu se lisait comme une fenêtre encastrée dans l'interface,
    alors que c'est lui qui compte et l'interface qui se pose dessus.
    Trois changements solidaires : la vue **couvre tout l'écran** et devient
    le PREMIER enfant — donc le plus bas au dessin comme à l'entrée, tout le
    reste flotte au-dessus ; ni dalle ni pourtour, le maillage dit où le monde
    s'arrête **en s'arrêtant** ; et le cadrage de la grille passe par des
    MARGES DE CONTENU (`SimView.content_margin`) au lieu d'un découpage.
    Corollaire à ne pas perdre : l'interface posée sur le jeu doit rester
    lisible sur n'importe quel fond. Le bandeau d'objectif prend un contour
    sombre — un bandeau opaque recréerait le cadre qu'on vient d'enlever.

90. **LE MÊME MODE DE PANNE QUE LA DÉCISION 67, TROIS SEMAINES PLUS TARD.**
    Mon correctif de `_fit_to_viewport` était un remplacement textuel dont
    l'ancre ne correspondait pas : `replace` n'a rien remplacé et **n'a rien
    dit**. La propriété `content_margin` existait, était correctement
    calculée, et n'était lue nulle part. Le défaut ne s'est vu que sur le
    ratio court — le seul où la grille est limitée en hauteur, donc le seul
    où le cadrage travaille vraiment.
    **Deux règles qui en sortent, et elles sont définitives.**
    a) Pour modifier du code existant, utiliser un outil qui **échoue
    bruyamment** quand l'ancre manque, jamais un `replace` silencieux.
    b) Un calcul qui remplace une structure (ici : des marges au lieu d'un
    découpage) doit être **testé sur le cas où il travaille**, pas sur le cas
    confortable. D'où les deux tests de cadrage : ratio haut ET ratio court.

91. **La vitesse cesse d'être un triangle.** Elle en portait un, creux, à côté
    du triangle plein de la lecture : deux formes identiques au pouce, qui
    obligeaient à comparer un REMPLISSAGE pour savoir sur quoi on appuie.
    Tout glyphe fléché rouvrirait la confusion — chevrons, doubles pointes :
    ce sont tous des triangles. Le multiplicateur écrit (`×1 ×2 ×3`) est la
    seule forme qui ne ressemble à rien d'autre à l'écran, se lit sans
    apprentissage, et ne dépend d'aucun caractère exotique.

92. **La sortie et la lumière se distinguent par la FORME.** Deux zones
    colorées côte à côte ne disent pas ce qu'elles font. La sortie porte
    désormais des chevrons pointant **hors du plateau** : c'est un passage, et
    un passage a un sens. La lumière rayonne et respire sans direction — on la
    vise, on ne la traverse pas. Les deux se distinguent en silhouette, écran
    en noir et blanc compris (ENF-20).
    Piège tombé dedans : la direction de sortie ne peut pas être « le bord le
    plus proche ». Une bande **pleine largeur** touche les bords gauche ET
    droit à distance nulle, et sortait de côté. Les axes que la région
    traverse entièrement sont exclus du calcul.

93. **L'énoncé d'ouverture tient au moins 2 s ⚙️ et au plus 10 s ⚙️.**
    Sans plancher, le geste qui ouvre le niveau chasse l'énoncé avant qu'il
    soit lu, et le joueur découvre qu'il a raté quelque chose sans savoir
    quoi. Sans plafond, il reste en travers du plateau. Dix secondes valent
    trois fois le temps de lecture de l'énoncé le plus long du chapitre.
    Détail qui n'en est pas un : l'invite « toucher pour fermer » n'apparaît
    **qu'une fois vraie**. L'afficher pendant les deux secondes où le toucher
    ne fait rien apprendrait au joueur que l'interface ne répond pas.

94. **L'effacement de la progression quitte le menu pour les réglages.**
    Le menu sert à ENTRER dans le jeu, et il offrait, à un geste du bouton
    « Jouer », la seule action irréversible de toute l'application. Les
    réglages sont l'endroit où l'on va délibérément. La double confirmation
    part avec lui.

---

## Source de vérité unique et réglages (8 août 2026)

86. **INVARIANT N°11 — `slots` a une source de vérité unique** (`LevelSpec.open_slots()`,
    dans `core/sim/`). Fermer les rangs excédentaires réglait le CAS de
    ch1_02 ; l'invariant règle la CLASSE.
    **La brèche était plus grave que je ne l'avais dit.** Je l'avais présentée
    comme « le joueur pourrait gagner par une pile non validée ». C'est
    l'inverse qu'il faut lire : si le joueur atteint un espace non énuméré,
    **`expected_wins` devient faux**, et `N_win` cesse d'être une propriété du
    NIVEAU pour devenir celle d'un sous-ensemble arbitraire de ce que le
    joueur peut faire. `expected_wins = 1` sur ch1_02 veut dire « une seule
    pile gagne, et c'est l'ordre qui décide » : toute la leçon du niveau
    s'effondre avec le chiffre. QN-01 et QN-02, qui raisonnent sur des classes
    de piles, perdent leur objet en même temps.
    **Où vit la fonction, et pourquoi.** Le validateur est dans `tools/`, le
    jeu dans `game/` : leur seul ancêtre commun autorisé est `core/` (règles
    de dépendance 3 et 4). `core/sim/` porte déjà le schéma des données de
    niveau, `SimCore.load_level` en consomme le même dictionnaire ; la pureté
    tient (aucun import, aucun fichier, aucun flottant).
    **Trois tests, dont un lexical.** Pour chaque niveau du catalogue : les
    rangs ouverts par l'écran égalent la longueur maximale réellement
    énumérée ; toute pile que l'interface peut produire appartient à l'espace
    énuméré (vérifié en saturant l'écran par le chemin sans glissement) ; et
    la clé `slots` ne se lit nulle part ailleurs. Les rapports du validateur
    PORTENT une clé `slots` — les lire n'est pas lire un niveau, d'où
    l'indexation directe qui les distingue lexicalement.

87. **HAPTIQUE : j'ai tranché pour l'écran de réglages minimal**, contre
    l'option « désactivée par défaut jusqu'à ce que l'écran existe ».
    Raison : couper le retour par défaut prive les testeurs de la seule chose
    qu'on veut leur faire juger, et un réglage qu'on n'a jamais senti ne se
    règle pas. On rend donc le réglage, pas le silence.
    Le constat qui a forcé la décision est juste et vaut d'être gardé :
    **livrer une vibration qu'un testeur ne peut pas couper est un défaut,
    pas un manque.** ENF-24 dit « présent mais désactivable » — je n'avais
    rendu que la première moitié et je l'avais rapporté comme un reste.
    L'écran ne contient QUE ce réglage. Le mouvement réduit (ENF-23) est déjà
    porté par `Settings` et honoré par les shaders, mais reste non exposé : un
    écran de réglages qui grossit tout seul est la porte d'entrée habituelle
    du sentiment de configuration obligatoire (P2). L'état se lit dans le
    TEXTE (« activées » / « coupées »), pas dans une nuance de fond (ENF-20),
    et basculer sur « activé » déclenche une impulsion — c'est la seule façon
    de vérifier un retour haptique sans notice.

88. **Le test de couverture du harnais n'énumérait plus rien.** Il listait les
    écrans à la main : exactement la faiblesse qui avait laissé passer
    l'écran de bilan. Un garde-fou qu'il faut penser à mettre à jour ne garde
    rien. Les écrans sont désormais **découverts** dans `game/ui/` par leur
    `class_name *Screen`, et tout écran non déclaré dans la table des
    marqueurs fait échouer le test — on ne peut plus en ajouter un en silence.
    C'est la troisième fois que la même leçon se paie : **la preuve ne doit
    jamais dépendre de la mémoire de celui qui l'écrit.**

---

## Charte des couleurs et hiérarchie visuelle (8 août 2026)

74. **CHARTE DES COULEURS — trois familles étanches.** Le langage des couleurs
    n'avait aucune sémantique réservée : les emplacements de pile étaient
    cyan, ambre, magenta, vert, alors qu'**ambre est la teinte de la lumière
    et vert celle de la sortie**. La couleur de l'emplacement 2 était donc
    celle du but. Tenable au chapitre 1, ingérable au chapitre 4 avec
    ressources, dépôts, portes à pression et sens uniques à l'écran.
    - **1. Éléments de niveau** — une teinte réservée par entrée du
      vocabulaire RG-14. **Les neuf sont attribuées d'avance**, y compris
      celles qu'aucun niveau n'utilise : c'est le seul moment où
      l'attribution est gratuite. Réparties sur la roue pour rester
      distinguables deux à deux : ambre 45° (lumière), vert-sarcelle 150°
      (sortie), cyan 195° (sens unique), bleu 215° (dépôt), violet 280°
      (ressource), magenta 320° (porte à pression), rouge 358° (danger). Le
      mur n'a **pas** de teinte — lui en donner le ferait entrer dans le
      vocabulaire signifiant.
    - **2. Emplacements de pile** — **aucune teinte propre**. Un emplacement
      est un RANG : il s'identifie par sa position et son numéro, sur une
      famille gris-ardoise désaturée. C'est plus juste que ce qu'il
      remplace — tout le jeu tient à l'ordre, et un ordre ne se lit pas dans
      un arc-en-ciel. Le numéro est écrit en permanence, occupé ou non.
    - **3. Diagnostic** — palette **MODALE**. Quand elle s'allume, le terrain
      se désature ; les deux palettes ne se disputent jamais l'écran.

75. **La coloration des agents par règle est un DIAGNOSTIC, jamais le jeu
    normal.** Vérifié : `show_decision_colors` n'est allumée que depuis le
    banc jetable, l'écran de jeu ne l'expose pas. C'est structurel, pas un
    oubli — DA-01 fait de la forme collective le personnage principal, et une
    nuée à quatre couleurs détruit cette lecture.

76. **LA LUMIÈRE EST UNE SOURCE, PAS UNE CASE REMPLIE.** J'avais surcorrigé :
    écarter la dalle lumineuse écrasante était juste, mais la rendre
    translucide l'a rendue **inerte** — un bloc kaki, donc un obstacle, alors
    que c'est ce que R01 poursuit. Une source a un noyau clair surexposé vers
    le blanc, une décroissance qui déborde de 1,35 case ⚙️ sur les voisines,
    et une respiration lente à **0,5 Hz** ⚙️ — à la limite basse du
    perceptible, car une source qui bat vite devient une alarme.
    **La hiérarchie DA-02 ne tient pas à la saturation mais à la LUMINOSITÉ
    PAR UNITÉ DE SURFACE.** La lumière domine sur une petite surface : c'est
    ce qui la rend attirante sans qu'elle écrase.

77. **LA SORTIE EST UN SEUIL, PAS UN PHARE.** L'aplat saturé en faisait
    l'élément le plus lumineux de l'écran, ce qui inversait DA-02 : elle
    dominait la lumière et la nuée. Une sortie n'a pas à attirer l'œil, elle
    a à **se laisser reconnaître quand on la cherche**. On la dessine donc
    comme une ouverture — liseré net qu'on franchit, intérieur presque vide,
    extinction douce vers le dehors. **Changement de matière, pas
    d'intensité.** Elle n'est plus jamais l'élément le plus lumineux.

78. **Test opposable de la hiérarchie : plisser les yeux sur la capture.**
    Ce qui reste visible en premier doit être la lumière, puis le danger,
    puis la nuée. Si c'est la sortie, ce n'est pas fini. C'est ce test qui a
    imposé deux réglages de plus après la première correction : liseré de
    sortie descendu à 0,40 ⚙️, densité du danger remontée — le danger tient
    souvent en **une case**, sa densité doit compenser sa surface.

79. **LE MAILLAGE DÉFAISAIT LE TRAVAIL SUR LES RÉGIONS.** Fusionner les cases
    contiguës en formes uniques ne sert à rien si l'on retrace ensuite chaque
    frontière : l'œil redescend au niveau de la case et le plateau se couvre
    d'un bruit constant. Le monde reste discret — c'est une information de
    jeu, pas du décor — mais elle se porte désormais à deux niveaux : le
    **pourtour** du plateau, net, qui dit où le monde s'arrête ; les
    frontières intérieures, **fortement atténuées**, présentes sans être lues.

80. **POURQUOI LA CAPTURE `07-ch1-02-detour` NE MONTRAIT PAS UN DÉTOUR.**
    Le harnais cherchait « le premier `GameScreen` enfant » pour agir dessus.
    Après un changement de niveau, l'écran précédent est encore vivant le
    temps de son `queue_free()` : les gestes partaient donc dans l'écran
    **mort**, et la capture montrait le nouveau, intact, à tick zéro avec une
    pile vide. **Une image qui ne montre pas ce qu'elle annonce est pire
    qu'une image absente** — on en tire des conclusions. `_open_game` renvoie
    désormais l'écran ouvert : on ne devine plus.

81. **LE FLOU DES CAPTURES ÉTAIT L'INSTRUMENT, PAS LE RENDU.** La fenêtre
    était bornée par la dalle de la machine : demander 1080×2400 rendait
    1080×1131, donc un cadrage faux et une image molle. Le harnais rend
    maintenant dans un **SubViewport dimensionné à la main** — la capture ne
    dépend plus de l'écran qui la produit.
    **Corollaire à ne pas oublier** : simuler un petit écran ne consiste pas
    à réduire la largeur. L'étirement `canvas_items` conserve la base 1080 et
    n'ajuste que la hauteur ; un SubViewport de 480 de large mesure une
    interface qui n'existe sur aucun appareil. Le petit écran, c'est
    **1080×1920**, pas 480×1067.

82. **Les rangs de pile sont ceux que le NIVEAU déclare.** L'interface
    affichait quatre rangs utilisables sur un niveau qui en déclare deux —
    et le validateur n'énumère les piles que jusqu'à `slots`. Un joueur
    pouvait donc gagner par une pile que **personne n'a validée**, et le
    niveau ne prouvait plus rien. Les rangs fermés restent visibles — il faut
    savoir que la pile grandira — mais ils sont **plus étroits** et non
    seulement plus sombres : l'indisponibilité ne peut pas tenir au seul ton
    (ENF-20). Deux tests d'interface changent de rang cible en conséquence :
    ce n'est pas le contrat de compaction qui bouge, c'est le rang 3 qui
    n'existe pas sur ch1_02.

83. **Le panneau d'objectif masquait le niveau qu'il décrit.** Il occupait le
    centre du plateau, opaque, et cachait le danger de ch1_02 — précisément
    l'élément que l'énoncé donne à comprendre. Trois corrections cumulées :
    il descend au bas de la vue, il se dimensionne **sur son contenu** au
    lieu d'une hauteur fixe de 300, et il devient translucide.

84. **Quatre boutons identiques, c'est quatre fois rien.** Lecture est
    l'action la plus fréquente de l'écran, fermer la plus coûteuse à
    déclencher par erreur : les donner à voir de la même façon oblige à LIRE
    un glyphe avant chaque geste, et le glyphe est justement ce que le pouce
    recouvre. Trois registres — primaire (plein, accentué, **1,24× plus
    grand** ⚙️), secondaire (contour), discret (sans fond). La hiérarchie
    porte sur la forme et la taille, pas sur la seule couleur (ENF-20).

85. **RETOUR HAPTIQUE (ENF-24) — quatre événements, pas un de plus.**
    Sélection 12 ms, dépôt 22 ms, refus 2×14 ms, sortie d'agent 9 ms ⚙️.
    Il existe parce que la discrimination appui/glissement se joue **sur une
    cible que le doigt lui-même cache** : sans retour, il faut REGARDER la
    pile pour savoir ce qui a été compris — donc quitter la grille des yeux
    au moment où la nuée bouge. Deux règles non négociables : **jamais
    porteur d'information exclusive** (tout ce qu'une vibration annonce est
    aussi visible, ENF-22), et **désactivable** avec état persistant. Le refus
    est le seul motif double, parce qu'un refus doit se remarquer.
    Nouveau fichier de sauvegarde `settings.json`, avec son propre
    `schema_version` : on n'ajoute pas un champ à `progress.json`, qui porte
    des données que le joueur ne veut pas perdre.

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

## Fait — N3 refondu : S4 fermée, et ce que l'impasse a appris (9 août 2026)

### 155. Une impasse ne peut être ouverte que par R03

Établi en construisant N3, après trois géométries mesurées, dont une où
`[2,3,1]` **et** `[3,2,1]` laissaient un agent immobile avec R01, R02 **et**
R03 abstenues — 20 sortis sur 21, niveau insoluble.

> R02 ne peut pas ouvrir une impasse. Son seuil se déclenche **avant**
> l'impasse — l'agent oscille de part et d'autre de la portée (P3) — ou, s'il
> ne se déclenche qu'à l'intérieur, la direction de fuite est justement celle
> qui est murée : **la seule case libre d'une impasse pointe vers le danger,
> sinon R01 l'aurait déjà prise.**
>
> R03 y échappe parce que sa condition n'est pas un seuil sur un point fixe :
> elle dépend des congénères, qui sont **derrière**. Barycentre au Sud, sortie
> d'impasse au Sud — ils tirent dans le même sens.

C'est la démonstration constructive du chantier « S4 » du dossier des genres de
règles, qui n'était jusqu'ici qu'un argument.

### 156. Le premier correctif de N3 fermait S4 en cassant QN-02

Battre `[1]` par une impasse fait de tout niveau anti-`[1]` un niveau de
cohésion — et N4 l'était déjà. `[3,1]` gagnait alors N3, N4 et N5 : le joueur
traversait le chapitre sans jamais réordonner. **QN-02 est une exigence du CDC,
S4 une règle de conception interne : c'est S4 qui devait céder le pas, pas
l'inverse.** Consigné parce que le premier réflexe fut le contraire.

Résolu sans toucher à N4 : N3 porte désormais **deux pièges opposés** — une
impasse à l'est que seule R03 ouvre, un feu à l'ouest où seule R03 pousse. Ni
`[2,1]` ni `[3,1]` n'en sortent. Solution unique : `[2,3,1]`, 22/22 en 30 ticks.

Conséquences mesurées : S4 **fermée** (`S4_KNOWN_BREACHES` vide), S3 **atteinte**
(plafond abaissé de 3 à 2, cliquet refermé des deux côtés), QN-02 rétabli, et
la paire R02/R03 enfin **observable** (RG-13) — aucun niveau antérieur ne la
montrait.

### 157. La famille par tête de pile est un indicateur trop grossier pour S2

S2 déclarait « ch1_02 et ch1_03 posent la même question » parce que leurs
gagnantes commencent toutes deux par la Fuite. C'est faux : ch1_02 offre
`[R01, R02]` sur 2 rangs — il ne peut pas **énoncer** la question de l'ordre
R02/R03, R03 n'y étant pas proposée.

**Deux niveaux ne posent la même question que s'ils offrent le même espace de
réponses** (mêmes règles disponibles, même nombre de rangs). S2 ne compare plus
que des niveaux comparables. Sixième forme du piège de l'invariant 12 : *un
indicateur qui agrège plus que la propriété qu'il mesure signale des défauts
qui n'existent pas* — et un faux positif use la confiance dans le test aussi
sûrement qu'un faux négatif la trompe.

### Cérémonie d'or ch1_03 — PRÉDICTION ÉCRITE, en attente d'accord

Vérification sans écriture faite le 9 août 2026 : **12 divergences, toutes sur
ch1_03**.

**Compte exact du corpus — et correction d'une erreur de dénombrement.** Le
corpus tient **30 recettes × 3 relevés = 90 empreintes**. Sur ce total :
**26 recettes concordent, 4 divergent** (les quatre de ch1_03), soit 12
empreintes sur 90.

J'avais d'abord annoncé « 13 concordantes sur 17 », deux chiffres faux tous les
deux. Le « 17 » venait d'une ligne périmée du tableau des mesures, datée du
5 août ; le « 13 » d'un `grep` dont le motif ne couvrait ni `golden_corridor`,
ni `golden_field`, ni les six fixtures `sensi_*` — il a compté 13 lignes
concordantes sur 26. **Une prédiction ne vaut que si l'on sait sur quel ensemble
elle porte** : un dénombrement fait avec un motif qui ne couvre pas l'ensemble
mesuré est la même faute que l'échantillonnage de contention, sous une autre
forme. Le tableau des mesures est corrigé en bas de ce carnet.

| recette | prédiction | pourquoi |
|---|---|---|
| `ch1_03 [1]` | **change** aux 3 relevés | effectif 21 → 22, grille 15 → 16 rangs, danger déplacé |
| `ch1_03 [2,1]` | **change** aux 3 relevés | idem |
| `ch1_03 [2,3,1]` | **change** aux 3 relevés | idem |
| `ch1_03 [3,1]` | **change** aux 3 relevés | idem, et l'agent meurt désormais au tick 1 |
| les 13 autres | **inchangées** | aucune ne touche ch1_03 |

Le confinement est donc **exactement** celui que prédit un changement de
géométrie limité à un seul niveau. Rien d'autre n'a bougé, ce qui distingue
« l'entrée a changé » de « le code a régressé ».

`--write` n'a **pas** été exécuté et ne le sera pas sans accord explicite.

## Fait — Cérémonies d'or, et le moteur du chapitre 2 (10 août 2026)

### 158. Cérémonie 1 — ch1_03, cause unique, prédiction tenue

Autorisée explicitement. Confrontation faite sur le fichier avant/après :
**4 recettes déplacées, toutes ch1_03 ; 26 inchangées** — exactement la
prédiction écrite la veille. Aucune modification de `core/sim/` ne
l'accompagne : l'entrée a changé, le code n'a pas bougé.

### 159. `AgentState.dir` existait déjà — et je ne l'avais pas cherché

L'analyse du chapitre 2 concluait qu'il fallait **ajouter** un champ à l'état,
et en tirait une cérémonie sur les 30 recettes. Faux sur la prémisse : `dir`
est au DCT §4.1 depuis le premier jour, peuplé par `SimCore._apply_movements`
(ligne 207), initialisé au Nord au chargement (ligne 68), et déjà parcouru par
`StateHash` (ligne 46).

> **Vérifier qu'un champ manque se fait en le cherchant, pas en raisonnant sur
> ce qu'il faudrait.** Septième forme du piège de l'invariant 12 : après
> « paraître correct », « paraître cassé », « un zéro se vérifie comme un
> chiffre inattendu », « une note ne protège de rien », « un test dont l'objet
> n'est pas versionné » et « une liste vide n'asserte rien », voici **« paraître
> absent clôt l'examen »**.

Coût : une journée d'analyse sur un champ à lire. Gain : aucune cérémonie
d'état, aucun DCT à amender.

### 160. Cérémonie 2 — réduite à un tampon de provenance

R04, R05 et R06 écrites, `data/rules.json` enrichi de deux blocs de
paramètres. Mesure : **0 empreinte d'état déplacée sur 30**, 30 tampons
`rules_hash` rafraîchis, aucune clé de premier niveau ajoutée ni retirée.

La neutralité est donc **démontrée par la fonction d'empreinte elle-même** —
meilleur témoin que la comparaison de positions finales envisagée d'abord, qui
peuvent coïncider alors que les trajectoires diffèrent. Le dispositif proposé
— conserver temporairement l'ancienne fonction d'empreinte — reste la bonne
réponse le jour où un champ sera réellement ajouté ; le chapitre 3 en aura
besoin pour la stigmergie.

### 161 bis. La sixième forme est la PIRE de la série, et voici pourquoi

Les cinq premières formes du piège de l'invariant 12 se déclenchent sur un
**incident** : une mesure surprenante, un test rouge, un zéro inattendu. On
regarde, parce qu'il s'est passé quelque chose.

La sixième se déclenche sur un **succès**.

> **Un test dont l'objet se vide cesse d'asserter au moment exact où
> l'objectif est atteint.** Le déclencheur est une bonne nouvelle — la liste
> des manquements s'est vidée, le défaut a été réparé — donc personne ne
> cherche un défaut à ce moment-là. La garantie disparaît le jour où l'on
> relit le moins attentivement, et sans qu'une seule ligne ait changé.

La règle, telle qu'elle est désormais tenue :

> **Un test qui itère une liste doit échouer si la liste est vide, ou déclarer
> explicitement que le vide est le succès attendu.**

Mécanique, pas documentaire : `tests/arch/test_suite_hygiene.gd` refuse toute
fonction `test_` dont **toutes** les assertions sont imbriquées dans une
boucle, sauf marqueur `# VIDE-ATTENDU:` explicite.

**Résultat de l'audit — et c'est le plus utile de la journée : 28 fonctions,
dans onze fichiers sans rapport.** Ce n'était pas un test à corriger, c'était
une habitude d'écriture. Deux classes, et la distinction gouverne l'ordre des
réparations :

- **collection filtrée** dans la boucle (`continue` sur `ready`, sur
  `tutorial`…) : elle peut se vider sans qu'une ligne change — il suffit qu'un
  niveau cesse d'être prêt. **Six cas, tous réparés** par un compteur
  d'éléments examinés asserté hors boucle ;
- **constante littérale** parcourue : elle ne se videra que si quelqu'un vide
  la constante, geste visible en relecture. **Vingt-deux cas, gelés au
  cliquet**, qui refuse toute aggravation et exige que la liste décroisse.

### 161. Un test « risky » est un test qui ne prouve rien

`test_the_known_breaches_are_still_real` bouclait sur la liste des manquements
S4 connus. La liste s'étant **vidée** — S4 fermée — la boucle n'a plus rien
parcouru, et GUT a signalé le test « risky ». Sixième forme du même piège, et
la plus sournoise : **elle n'apparaît qu'au moment où l'objectif est ATTEINT**,
exactement quand on relit le moins attentivement.

La liste vide doit désormais s'affirmer plutôt que se taire. Le garde-fou
mécanique existait déjà et a tenu : la CI exige le verdict plein
« All tests passed! », que GUT remplace par « N pending/risky tests » — la
ligne est maintenant commentée pour qu'on ne l'assouplisse jamais en tolérant
« risky ».

### 162. Deux de mes propres tests du chapitre 2 étaient faux, pas le code

- **« R04 est le miroir exact de R03 »** : faux. Minimiser la distance au
  barycentre a ici un optimum unique, la maximiser en a deux à égalité, et
  N>E>S>O tranche. Un « exact opposé » n'existe que si les deux optimisations
  sont uniques, ce que rien ne garantit sur une grille. Remplacé par la
  propriété réellement vraie : **elles ne proposent jamais le même pas**.
- **« ce voisin n'a pas pu bouger »** : le cas construit était incohérent — un
  agent en (1,1) de cap Ouest vient de (2,1), case libre. C'est le cap **Est**
  qui est impossible là.

Et c'est en corrigeant le second qu'un vrai défaut est apparu : **au tick 0,
personne n'a bougé mais tous portent `dir = Nord`**. R05 aurait imposé le Nord
à toute la nuée sur la foi d'une valeur par défaut. Elle se tait désormais au
premier tick. Le défaut n'a pas été trouvé en relisant la règle.

### 163. Les deux exigences du porteur, vérifiées sur le catalogue entier

- **Aucune pile ne gagne plus de 2 niveaux sur 5.** Les quatre paires
  concernées contiennent toutes ch1_05, dont la leçon *est* qu'il n'y a pas une
  seule bonne réponse.
- **`[Lumière]` seule ne gagne que ch1_01**, le niveau qui l'introduit.

### 164. Aucun niveau du chapitre 2 ne sera dessiné avant les testeurs

Douze niveaux bâtis avant qu'un joueur ait découvert le chapitre 1, ce serait
l'invariant 12 appliqué au jeu entier : concevoir sur un terrain qui ne
sollicite pas ce qu'on prétend mesurer. Le moteur est prêt ; les cartes
attendent. Les paramètres ⚙️ de R04 et R05 sont des **valeurs de départ, pas
des valeurs mesurées**, et le fichier le dit à l'endroit où elles sont écrites.

## Fait — Le jeu complet : seize règles, six chapitres (14 août 2026)

### 165. Le genre EFFET, et pourquoi un seul

R08 « marquer la piste » ne propose aucun déplacement. Sous le seul genre
proposeur, elle n'avait que deux formes, mauvaises toutes les deux : s'abstenir
toujours, ou proposer l'immobilité et masquer toute la suite de la pile. C'est
P1, et le chapitre 3 entier en dépendait.

**Un seul genre a été ajouté, pas quatre.** Le filtre général, la condition de
maintien et l'hystérésis restent hors du moteur : R04 a montré qu'une condition
de maintien s'écrit très bien en proposeur, R16 est un filtre assez étroit pour
tenir dans une lecture de la pile, et l'hystérésis attend toujours des joueurs.

La règle d'or a été reformulée une fois, et une seule : *la première règle de
DÉPLACEMENT applicable l'emporte ; les effets s'appliquent au passage.* Elle ne
relâche rien — **un effet ne s'applique que si la cascade l'ATTEINT**, donc sa
position reste décisive. C'est même la mécanique la plus tranchante du jeu :
sur N14, deux piles gagnent sur soixante-cinq, et les deux ont les effets aux
rangs 1 et 2.

Neutralité prouvée, pas argumentée : les 30 recettes d'or concordent après
l'extension.

### 166. Trois découvertes imposées par la stigmergie

1. **Une piste est une PENTE, pas un tapis.** R09 va vers plus intense que sa
   propre case ; une trace uniforme n'oriente personne — 25 agents immobiles
   mesurés sur une colonne marquée à plat.
2. **Une piste est une trace de PASSAGE, pas d'occupation.** Sans cette
   condition, un agent immobile renforce sa case à chaque tick pendant que la
   trace devant lui s'évapore : il creuse un puits sous ses pieds dont R09 ne
   peut plus le sortir. La nuée se fige exactement là où elle doit avancer.
3. **Le dépôt doit être plus faible que le pas de la pente.** À 12 contre 6, la
   case qu'on vient de quitter devient plus intense que celle devant : la nuée
   se marche dessus.

### 167. R06 n'a qu'une maison propre : une carte sans lumière

Trois dispositifs essayés, trois oscillations. R06 et R01 se contredisent de
part et d'autre de tout seuil (P3) : placée après R01 elle oscille, placée
avant elle détourne tout ce qui frôle une paroi. **La seule sortie n'est pas de
ruser avec la géométrie, c'est de retirer la contradiction** — sans lumière,
R01 s'abstient partout.

Trois conditions supplémentaires, toutes structurelles : tout agent doit
toucher un mur au départ ; les couloirs font une case (à deux, le suivi de main
droite décrit un carré de 2×2) ; le parcours n'a qu'un sens (deux agents face à
face gèlent toute la file). D'où l'escalier monotone de N7.

### 168. R04 prenait le premier écart, elle prend le plus grand

Pour une nuée qui monte, le Nord augmente presque toujours la distance au
barycentre : l'ordre N>E>S>O faisait donc de R04 une R01 affaiblie, qui
poussait vers l'avant au lieu d'écarter — et jetait la nuée dans le piège dont
elle devait la détourner. En retenant le maximum, le pas latéral l'emporte dès
que la nuée est devant ou derrière, seule situation où « s'écarter » veut dire
quelque chose.

### 169. Le jeu est asymétrique gauche-droite

Le miroir de N9 a été construit et mesuré : **il ne se résout pas.** À égalité,
toute règle préfère le Nord puis l'Est ; une nuée qui doit s'écarter s'écarte
plus volontiers vers l'Est, et un détour vers l'Ouest est structurellement plus
dur. La symétrie visuelle n'est pas une symétrie de jeu — à retenir avant de
dessiner, pas après.

### 170. Trois éléments du vocabulaire étaient invisibles à l'écran

Piste stigmergique jamais dessinée ; porte à pression sombre et ses **cases de
commande pas dessinées du tout** ; sens unique cherché par `cell_type_at`, qui
ne le trouve jamais puisqu'une case à sens unique reste de type EMPTY.

**Aucun test de simulation ne pouvait le dire** : les trois mécanismes
fonctionnaient parfaitement dans le moteur. Ils ont été trouvés en REGARDANT
les captures — septième fois que l'invariant 12 se vérifie, et la première où
le cas d'épreuve était l'œil plutôt qu'une mesure.

### 171. Corpus d'or étendu de 30 à 56 recettes

Les quatorze nouveaux niveaux n'avaient aucune protection de non-régression.
Deux recettes chacun — une pile gagnante, une perdante — couvrent désormais les
seize règles, les deux genres, la piste, le transport, la porte et le joker.
Prédiction écrite tenue exactement : 30 anciennes inchangées, 0 déplacée, 26
nouvelles renseignées.

## Fait — Jouabilité et intérêt : ce que la mesure du parcours a révélé (15 août 2026)

### 172. Le parcours de joueur ne se lit pas dans le rapport de validation

Ce que le validateur dit d'un niveau isolé ne dit rien de l'EXPÉRIENCE. On
mesure désormais, dans l'ordre du catalogue : la taille de l'espace de piles,
le nombre de gagnantes, et surtout le **rang de la première gagnante dans
l'ordre où un joueur méthodique les essaierait** — l'énumérateur va par
longueur croissante, ce qui est exactement l'ordre d'exploration naturel.

Trois défauts en sont sortis, invisibles autrement :

- **deux niveaux à 68 % de piles gagnantes** (ch2_02, ch3_01). Presque tout
  marchait, donc rien ne s'apprenait. Le troisième rang y était une règle
  INERTE — un rang gaspillé, sans conséquence. Remplacé par un piège RÉEL :
  68 % → 43 %, à espace constant ;
- **ch4_02 : première gagnante au rang 59 sur 65.** Cinquante-huit échecs avant
  de réussir — ce n'est plus de la compréhension, c'est de l'épuisement.
  Ramené à 16 piles, première au rang 14 ;
- **la courbe n'était pas monotone** : le deuxième niveau du chapitre 2 était
  un cadeau entre deux murs.

### 173. Deux objectifs se taisaient à l'échec

`collect` et `interdiction` n'avaient aucune phrase. Le joueur lisait « le
temps imparti s'est écoulé » alors que, sur une interdiction, la partie
s'arrête au troisième tick.

> **Un message faux vaut moins que pas de message.**

Et le contrôle générique qui l'accompagne a d'abord été FAUX lui-même : sa
sonde ne violait aucun objectif, si bien qu'elle accusait `extraction` et
`preservation` d'être muets alors qu'ils parlent très bien quand on les
enfreint. Une sonde qui ne sollicite pas le mécanisme — invariant n°12, encore.

### 174. Le diagnostic EF-05 mentait sur les règles d'effet

Il les faisait passer par `evaluate`, qui leur renvoie ABSTAIN par
construction : le panneau annonçait que « Marquer la piste » ne s'appliquait
pas, au tick même où elle marquait. **Un diagnostic qui ment est pire qu'un
diagnostic absent** — c'est le pilier P4 retourné contre le joueur, qui forme
une hypothèse fausse et la vérifie.

### 175. Les défis RG-18 étaient une promesse vide

Deux niveaux sur vingt-deux en déclaraient, et rien ne les conservait : un
défi gagné disparaissait avec l'écran de bilan. Ils sont désormais mesurés
(dix-sept niveaux peuvent en offrir un honnête), enregistrés, et affichés en
trois pastilles dans la liste.

La mesure a pris en défaut un défi posé à la main : abstinence sur R01 dans
ch4_02, alors qu'aucune des deux gagnantes ne s'en passe. **Une case qu'on ne
peut jamais cocher** — exactement ce que RG-19 interdit.

La persistance a demandé le schéma 2. C'est le seul changement du dépôt qui
puisse détruire quelque chose d'irremplaçable, et le repli propre l'aurait
fait : la migration 1 → 2 est donc ÉCRITE, purement additive, et tenue par
trois tests.

### 176. EQ-04 mesuré : R10 est morte, et c'est une propriété de la règle

« Une règle que l'espace des solutions ignore est une règle morte, à
retravailler ou retirer. » Le critère n'avait jamais été mesuré. Résultat sur
vingt-deux niveaux : dix règles à la cible, cinq sous-employées, **R10 offerte
par aucun niveau**.

R10 ne fait qu'UN demi-tour, et se déplacer met à jour le cap : si ce demi-tour
ne suffit pas à retrouver un congénère, l'agent repart en sens inverse au tick
suivant et fait la navette. Elle ne retient que celui qui s'écarte d'un pas.
La rendre vivante demanderait qu'elle se SOUVIENNE qu'elle rebrousse —
l'hystérésis, gelée. Le CDC autorise retravailler ou retirer ; les deux
demandent une décision du concepteur, pas un niveau de plus.

Trois niveaux ont porté les cinq autres à la cible. **Aucun n'a été écrit pour
le compteur** : la contrainte a servi de cahier des charges, pas de quota.

### 177. Le vrai risque d'intérêt : l'espace de piles est épuisable

Seize des vingt-cinq niveaux offrent seize piles. Un joueur qui renonce à
comprendre les essaie toutes en quelques minutes. **La difficulté du jeu n'est
pas dans la recherche — elle est dans la compréhension**, et rien n'oblige à
comprendre.

Ce n'est pas réparable en agrandissant l'espace : à quatre règles et quatre
rangs on atteint 65 piles, et un niveau qu'on résout par épuisement en 65
essais est pire qu'un niveau qu'on résout en 16. La réponse est ailleurs, et
elle est déjà posée : les défis RG-18 sont le jeu de celui qui a compris, et
ils ne se brutalisent pas — la meilleure pile ne se trouve pas en les essayant
toutes, elle se déduit.

**À vérifier auprès des testeurs, et c'est la question à leur poser :** ont-ils
essayé toutes les piles, ou raisonné ? Aucune mesure d'outil ne le dira.

### 178. Le mode Épreuve : un ingrédient sur trois tient, et c'est mesuré

La décision 177 nommait le risque — l'espace des piles est épuisable — sans y
répondre. Le mode **Épreuve** est la réponse : un chapitre entier joué d'un
bloc, avec un budget de lancements partagé. Il ne débloque rien, n'enregistre
aucun record et ne coche aucun défi : c'est une partie à côté, sans quoi il
deviendrait le chemin court vers la progression.

Trois leviers avaient été envisagés pour rendre la force brute coûteuse. **Un
seul mord, et je ne l'ai su qu'en le mesurant.**

**Le budget de lancements — il mord partout.** Somme des rangs de la première
pile gagnante dans l'ordre d'exploration naturel, contre le budget accordé à
5 lancements par niveau :

| Chapitre | Force brute | Budget | Rapport |
|---|---|---|---|
| 1 | 32 | 25 | 1,3× |
| 2 | 75 | 25 | 3,0× |
| 3 | 36 | 20 | 1,8× |
| 4 | 71 | 20 | 3,6× |
| 5 | 63 | 30 | 2,1× |
| 6 | 73 | 25 | 2,9× |

Un joueur qui raisonne consomme 2 à 3 lancements par niveau : le budget lui
laisse de la marge partout. C'est exactement la frontière qu'on voulait tracer,
et elle est désormais opposable — `tests/unit/test_trial_bite.gd` échoue si un
chapitre repasse sous son budget, **et** si le budget cesse d'accorder sa marge
au joueur qui raisonne. Les deux bords, pas un seul.

**Le tirage de règles — presque vide.** Il laisse la bibliothèque **intacte
dans 24 niveaux sur 29**. Conservé parce qu'il ne coûte rien et mord sur les
quatre niveaux à solutions alternatives, mais il n'est pas ce qui fait la
difficulté, et le code le dit maintenant en toutes lettres.

**Le quota par règle — vide pour la même raison, écarté avant d'être écrit.**
Le quota le plus serré qui reste satisfaisable vaut la taille du chapitre dans
quatre chapitres sur six : aucune contrainte. Ne pas l'implémenter est le
résultat le plus utile de la journée.

**La cause commune, et elle dépasse le mode.** Presque chaque niveau n'a
**qu'un seul ensemble suffisant minimal**, et cet ensemble contient la
règle-moteur du chapitre. Le jeu porte donc entièrement sur l'**ordre**, jamais
sur la **sélection**. On ne restreint pas le choix des règles quand il n'y a
rien à choisir — toute mécanique de restriction est condamnée d'avance sur ce
catalogue, quel que soit son habillage.

Ce n'est pas un défaut à corriger dans l'urgence : un jeu dont la leçon est
« la première règle applicable l'emporte » a de bonnes raisons de porter sur
l'ordre. Mais c'est une **borne connue** du potentiel d'intérêt, et elle
appartient aux questions des testeurs.

**Corollaire de conception, trouvé en branchant l'écran.** La première version
partait d'office du **dernier** chapitre entièrement résolu. Conséquence non vue
à l'écriture : un joueur ayant fini les six chapitres ne pouvait plus jamais
tenter les autres — et c'est le **chapitre 2** qui exige le plus (3,0× le
budget), pas le sixième (2,9×). Le mode se refermait sur son chapitre le moins
exigeant à mesure qu'on progressait. Le chapitre se choisit désormais, et le
coût de la force brute est affiché : une ressource dont on ignore l'ordre de
grandeur ne se choisit pas.

### 179. Huitième forme du piège de l'invariant 12 : vérifier qu'un mécanisme est SÛR n'est pas vérifier qu'il SERT

Le tirage de règles avait été soigné, testé sur cent graines par niveau, et sa
garantie était solide : *toute main contient une solution*. Neuf tests, tous
verts. Ce que personne n'avait demandé, c'est **l'autre question** : *la main
retire-t-elle jamais quelque chose ?* Réponse mesurée : non, dans 24 cas sur 29.

La question posée était celle du risque — « ce mécanisme peut-il nuire ? » —
et elle a une réponse rassurante. La question qui comptait était celle de
l'effet — « ce mécanisme fait-il quoi que ce soit ? » — et personne ne la pose
spontanément, parce qu'un mécanisme qu'on vient d'écrire a l'air de servir.

C'est le même piège que les sept précédentes formes, dans un domaine de plus :
le mécanisme avait été observé là où il était confortable. **Écrire ainsi :
tout mécanisme livré doit être mesuré sur ce qu'il RETIRE, pas seulement sur ce
qu'il préserve.** Un test de sûreté vert n'a jamais rien dit de l'utilité.

Deux captures ont d'ailleurs fait le même travail que les mesures, et plus vite :
la première montrait le compteur de lancements absent, la seconde la main
réduite à sa seule règle. **Une géométrie invisible est une géométrie injuste**,
et une main qui ne retire rien se voit à l'œil nu dès qu'on ouvre le tiroir.

### 180. Le compteur de gagnantes mentait, et il mentait toujours dans le sens rassurant

Signalé par le concepteur, et vérifié : **compter toutes les piles gagnantes
attribue à un niveau autant de « solutions » qu'il y a de façons de rallonger
la même.** Si `[R09]` gagne, alors `[R09,R01]`, `[R09,R05]`, `[R09,R01,R05]`…
gagnent aussi. ch6_04 annonçait dix-huit gagnantes ; il en avait **trois**.

Le bon compteur : **une gagnante ne compte que si aucune SOUS-SUITE d'elle ne
gagne déjà.** Sous-suite et non sous-ensemble — on retire des rangs sans
réordonner les autres, parce que l'ordre est le jeu. `tools/design/audit.gd`
l'implémente.

Ce que le compteur honnête a révélé, le 15 août 2026 :

- **24 niveaux sur 29 n'avaient qu'UNE seule pile gagnante minimale.**
- **21 niveaux sur 29 laissaient la pile contenir TOUTE la bibliothèque** —
  donc aucun choix à faire, seulement un ordre à trouver parmi six.
- **ch2_02 et ch3_01 se gagnaient avec UNE règle.**
- Les espaces faisaient **15 piles**. On les épuise en quelques minutes.

### 181. La maladie du catalogue : un chapitre enseignait N règles, et la réponse à tous ses niveaux était « mets ces N règles »

Le concepteur l'a nommé sur deux chapitres, et la mesure l'a confirmé sur les
deux : `[R08, R09]` répondait aux quatre niveaux du chapitre 3, `[R01, R11,
R12]` aux quatre du chapitre 4 — où trois niveaux sur quatre avaient
**exactement** ces trois règles pour bibliothèque. La réponse était la liste
elle-même. Une fois le premier niveau résolu, les suivants étaient la même
réponse sur une autre carte.

**Le correctif : plus de règles que de rangs, partout.** Cinq à six règles pour
trois rangs, les surnuméraires étant des leurres plausibles déjà rencontrés.
Le mécanisme central du jeu — une règle haute MASQUE tout ce qui est en
dessous — ne se sent que si l'on doit renoncer à quelque chose.

Coût de la force brute (rang de la première gagnante), avant → après :

| | avant | après | | | avant | après |
|---|---|---|---|---|---|---|
| ch3_02 | 7 | **21** | | ch4_04 | 13 | **133** |
| ch3_03 | 13 | **31** | | ch5_04 | 13 | **59** |
| ch3_04 | 13 | **31** | | ch5_06 | 15 | **125** |
| ch4_01 | 13 | **71** | | ch6_05 | 49 | **357** |
| ch4_03 | 32 | **124** | | espaces | 15 | **85 à 516** |

**Aucune géométrie n'a bougé** : seules `allowed_rules` et les fiches ont
changé. `calibrated_on` tient donc, et les 74 recettes d'or concordent sans
cérémonie — la distinction « le code a régressé » / « l'entrée a changé » a
fait exactement son travail.

**Un leurre peut être un moteur, et c'est le piège de l'opération.** R05
« Suivre les voisins » ajoutée au chapitre 3 gagnait SEULE en 17 ticks : les
agents portent une direction initiale, R05 la propage, et sur ces cartes plates
la sortie est plein nord. Remplacée par R02 et R04, qui ne peuvent pas
démarrer un mouvement. **Vérifier chaque leurre à la mesure, jamais au bon
sens.**

### 182. Ce que la refonte du chapitre 3 a coûté, et ce qu'elle a appris

Trois géométries construites et mesurées avant d'abandonner la voie, et les
trois échecs valent mieux que le niveau :

1. **Carte à idiome** : la piste devint totalement INERTE. La contention
   mesurait 0 sur les paires 1-8, 1-9 et 8-9. **Une règle qui propose toujours
   rend muette toute la pile** — c'est l'invariant n°18 vu de l'autre côté :
   pour que la couche du dessous parle, celle du dessus doit S'ABSTENIR.
2. **Piste posée loin de la nuée** : un seul agent la touchait, R01 emmenait
   tous les autres au nord. Une mémoire ne s'amorce pas toute seule.
3. **Détour de trente-six cases en file indienne** : structurellement juste,
   mais vingt-cinq agents n'avaient pas le temps. La longueur d'un couloir
   d'une case se paie en ticks, pas en difficulté.

**Conclusion, et elle appartient au concepteur :** R01 est le seul moteur
général du jeu. Tant qu'elle est dans une bibliothèque, elle masque tout ce qui
la suit sauf aux rares endroits où elle s'abstient. Rendre la piste vraiment
porteuse demande une décision de RÈGLE — pas une carte de plus.

### 183. Neuvième forme de l'invariant 12 : le jeu s'affichait EN PAYSAGE sur le téléphone

Signalé par le concepteur après un essai sur son appareil. Cause :

```
window/handheld/orientation="portrait"     ← syntaxe Godot 3
window/handheld/orientation=1              ← Godot 4 attend un ENTIER
```

Godot 4 n'a pas compris la chaîne, a retenu **0 — paysage**, et l'a écrit dans
le manifeste Android. Un catalogue entier dessiné en portrait, une grille
cadrée en portrait, vingt-trois captures en portrait, un test qui refuse que la
nuée passe sous les barres sur deux ratios portrait — **et la seule valeur qui
décidait vraiment était fausse**.

Le réglage n'a AUCUN effet sur le poste de développement : la fenêtre y est
portrait par sa seule taille. Le mécanisme n'était donc sollicité que sur
l'appareil, c'est-à-dire nulle part dans la boucle de vérification.

Deux garde-fous posés :
- `tests/arch/test_project_settings.gd` exige un entier ET la valeur portrait,
  et vérifie que résolution de base et orientation ne se contredisent pas ;
- vérification faite **dans l'APK**, pas dans un intermédiaire de build :
  `aapt2 dump xmltree` rend `screenOrientation=1`, soit
  `SCREEN_ORIENTATION_PORTRAIT`.

**À retenir : tout réglage dont l'effet est invisible en développement doit
avoir son test.** Il n'y a pas d'autre endroit où il sera vu.

**Note de mise à jour :** `docs/ARCHITECTURE.md` annonce la chaîne d'export Android comme
« PAS ENCORE CONFIGURÉE (prévue S9) ». Elle l'est : `export_presets.cfg`,
modèles 4.7.1, SDK Android 36, Java 21, et un APK de débogage produit. La note
du fichier est périmée — signalé, non tranché.

### 184. Premier essai sur l'appareil : cinq défauts, tous invisibles au poste de travail

L'appareil est branché en débogage sans fil ; l'aller-retour est devenu direct.
Cinq retours du concepteur, cinq défauts réels — **et pas un seul n'était
détectable sur le poste de développement.**

**1. Le jeu s'affichait en PAYSAGE.** Voir décision 183.

**2. Le lancement sautait le menu.** L'application rouvrait le niveau en cours
sans détour : on ne voyait jamais ni les chapitres, ni les réglages, ni
l'Épreuve, et le jeu avait l'air de n'avoir pas de menu. Il ouvre désormais
toujours le menu ; la reprise vit derrière « Continuer », qui remplace
« Jouer » quand une partie est en cours.

**3. Tout était trop petit, les textes surtout.** Vingt-cinq tailles posées en
dur, une par une. Elles passent toutes par `UiMetrics.font_size()`, gouvernées
par un seul `FONT_SCALE` (1,35). **Et l'agrandissement a immédiatement fait
déborder deux écrans** — le sélecteur de niveaux et le bilan : un `Label` non
contraint prend pour largeur minimale celle de son texte ENTIER et pousse toute
la colonne. Un test général parcourt maintenant l'arbre de chaque écran sur
720 de large et refuse tout contrôle qui dépasse.

**4. Le jeu était trop lent.** `SPEEDS` valait `[1, 2, 3]` **ticks par
seconde** : un niveau de quarante ticks demandait quarante secondes d'attente.
Porté à `[4, 8, 16]`. Le problème n'était pas le nombre de vitesses (RG-10 en
exige trois) mais leur échelle — personne ne l'avait mesurée en secondes
d'attente réelles.

**5. Toucher le vide ne faisait « rien ».** Le diagnostic s'ouvrait dès qu'on
touchait à UNE CASE d'un agent : autour d'une nuée de vingt, presque tout
comptait comme « sur un agent ». Rayon ramené à zéro — le vide rend la main à
marche/pause, qui est le geste principal de l'écran.

### 185. Dixième « géométrie invisible » : les marques de mort n'étaient jamais créées

« Les échecs sont incompris : on ne comprend pas ce qui fait perdre, l'écran de
défaite arrive avant le moment fatidique. »

Cause trouvée en lisant : `_death_marks` était **remis à zéro, filtré par âge et
dessiné** — et **rien n'y ajoutait jamais rien**. La « croix lumineuse sur la
case fatale », écrite, commentée et rendue, n'a pas été affichée une seule fois
depuis qu'elle existe. Un agent mourait, le bilan tombait, et le joueur n'avait
vu ni où ni pourquoi.

C'est la dixième fois qu'un élément du vocabulaire vit dans le moteur et pas à
l'écran — après le porteur, la piste, les portes, les sens uniques et la
cargaison. **Une géométrie invisible est une géométrie injuste ; un ÉVÉNEMENT
invisible l'est davantage, car il ne laisse même pas de trace à examiner.**

Ce qui a été posé :
- un **écho** — trois anneaux concentriques qui s'ouvrent depuis la case, plus
  un cœur plein le premier tiers du temps. Rouge pour une mort, vert pour le
  **dernier** agent sorti (un anneau par sortie ferait vingt anneaux : du bruit,
  pas de l'information) ;
- un **halo de bord d'écran**, rouge ou vert, qui s'élargit et s'éteint une
  fois. Il ne clignote pas : une alarme punit, un écho informe. La périphérie
  capte un changement de luminosité bien avant qu'un détail central ne soit vu ;
- le délai avant bilan porté de 1,1 s à **2,2 s** — l'écho dure 1,6 s, et il
  faut une demi-seconde de plus pour comprendre ce qu'on vient de voir ;
- sous ENF-21 (animations réduites), l'écho devient un halo fixe : l'information
  ne dépend jamais du mouvement.

**Deux défauts de plus trouvés à la capture, et pas au raisonnement :** l'écho
sortait VERT sur une mort, et décalé d'une case. Un agent meurt en ENTRANT sur
le danger ; marquer sa position d'avant dessinait l'anneau à côté de la case
rouge, et le contrôle de létalité y répondait « pas de danger ici ». Deux
erreurs d'un coup, dans quatre lignes, invisibles autrement qu'en regardant.

### 186. Onzième « géométrie invisible », et la plus injuste : la zone interdite

Cherchée exprès après la dixième, en balayant ce que le moteur reconnaît et que
le rendu ignore. Trouvée du premier coup.

L'objectif `interdiction` déclare une liste de cases ; y entrer fait perdre le
niveau **à l'instant même**. Ces cases n'étaient **pas dessinées du tout**. Le
joueur perdait donc sur une zone qui n'existait nulle part à l'écran — les dix
précédentes rendaient le jeu incompréhensible, celle-ci le rendait
**arbitraire**.

**La cause est structurelle et vaut avertissement :** une case interdite reste
une case **VIDE** pour le moteur. L'interdiction vit dans l'OBJECTIF, pas dans
la grille. Le rendu, qui parcourt les types de case, ne pouvait pas la trouver.

> **Tout ce qui décrit le terrain sans être un type de case est candidat au même
> oubli.** C'était déjà vrai du sens unique (une couche à part) et de la porte à
> pression. Le balayage « quels types de case sont dessinés ? » ne suffit pas :
> il faut demander « quelles DONNÉES changent ce qui arrive à un agent ? ».

Rendue en hachures **ambre**, jamais en rouge : le rouge appartient au danger,
qui TUE l'agent qui y entre ; l'interdiction ne tue personne, elle disqualifie
la tentative. Deux conséquences différentes ne portent pas la même teinte
(RG-14). Contour tracé par frontière — une zone se lit par son bord, pas par son
remplissage.

### 187. CONTRADICTION À TRANCHER — l'haptique ne peut pas fonctionner sans une permission

**Signalée, non tranchée** (docs/ARCHITECTURE.md : « Trancher une contradiction entre les
documents et ce fichier » figure parmi les choses à ne jamais faire seul).

Le concepteur demande le retour haptique, « discret, pas une source de
perturbation ». Il est **déjà entièrement implémenté** : `game/platform/haptics.gd`,
quatre événements (sélection 12 ms, dépôt 22 ms, refus 2×14 ms, sortie 9 ms),
jamais porteur d'information exclusive (ENF-22), désactivable et persistant.
Il est branché en neuf endroits.

**Et il est totalement inerte sur l'appareil.** Vérifié dans l'APK :
`aapt2 dump permissions` ne rend aucune permission. Or Android exige
`android.permission.VIBRATE` pour accéder au vibreur — sans elle,
`Input.vibrate_handheld()` ne fait rien et ne signale rien.

Le commentaire du module l'avait même anticipé : « Godot n'ajoute VIBRATE au
manifeste que si l'export l'active, ce que nous ne faisons pas (le jeu reste
sans permission, ENF-31) ». La conséquence — que le retour haptique n'existe
alors pas — n'en avait pas été tirée.

**Les deux exigences en présence :**

| | |
|---|---|
| ENF-24 | le jeu offre un retour haptique |
| ENF-31 / docs/ARCHITECTURE.md | « le jeu est hors ligne, **sans permission** et sans collecte de données — c'est une exigence, pas une préférence » |

**Fait technique utile à la décision :** `VIBRATE` est une permission de type
*normal* au sens d'Android. Elle ne déclenche aucune demande à l'exécution,
n'apparaît dans aucune boîte de dialogue, ne donne accès à aucune donnée, et
n'est pas listée comme sensible sur la fiche Play. Elle reste néanmoins une
ligne dans le manifeste.

**Trois issues, toutes légitimes, aucune prise :**

1. Ajouter `VIBRATE` et considérer qu'une permission normale ne contredit pas
   l'esprit d'ENF-31 — qui vise la vie privée et la collecte.
2. Retirer l'haptique et la mention d'ENF-24, en assumant qu'un jeu sans
   aucune permission n'en a pas.
3. Garder le code inerte, avec un réglage grisé disant pourquoi — le pire des
   trois : il promet ce qu'il ne peut pas tenir.

### 187 bis. RÉSOLUE — l'haptique fonctionne, et l'interdiction ne servait pas son objet

Arbitrage du concepteur : « le projet s'interdit VIBRATE, mais cherche si c'est
justifié ». Vérifié **sur l'appareil**, pas de mémoire :

| question | réponse mesurée |
|---|---|
| est-elle dangereuse ? | **non** — absente de `pm list permissions -d` |
| demande-t-elle un consentement ? | **non** — `granted=true` dès l'installation, aucune boîte de dialogue |
| donne-t-elle accès à des données ? | **non** — ni capteur, ni stockage, ni réseau |
| le vibreur répond-il, une fois déclarée ? | **oui** — `VibratorManagerService: Vibration 37448 on vibrator 0 complete` |

**L'interdiction protégeait la vie privée en n'empêchant aucune collecte, et
coûtait une exigence du CDC.** Elle est levée pour cette permission-là, et pour
elle seule.

CE QUI LA REMPLACE EST PLUS STRICT. Une **liste close et versionnée** —
`data/android_permissions.json` — tenue par `tests/arch/test_permissions.gd`.
Toute permission réseau y est explicitement interdite, et une permission ne
s'ajoute qu'avec sa justification écrite. L'interdiction générale, elle, ne
tenait que par la discipline de qui relisait un fichier **hors dépôt**.

**DEUX FOIS LE GARDE-FOU DE LA SUITE A EU RAISON CONTRE MOI.** Mon premier test
lisait `export_presets.cfg` : « un test dont l'objet n'est pas versionné n'est
pas un test — vert ici, absent ailleurs ». J'ai déplacé la liste dans un fichier
versionné, puis gardé un contre-contrôle sur le preset ; il l'a refusé encore,
et il avait raison encore. La conformité d'un fichier de build se vérifie **dans
le paquet produit**, comme l'orientation — la commande est au docs/ARCHITECTURE.md.

> **Un code qui ne peut pas s'exécuter coûte plus cher qu'un code absent :** il
> occupe la place et donne l'illusion que la fonctionnalité existe. Neuf appels,
> un module réglé au millième de seconde, et pas une vibration en des mois.

### 192. Toutes les combinaisons de tous les niveaux — le jeu ne se compose pas, il se récite

« Teste toutes les combinaisons pour chaque niveau, puis analyse le résultat. Je
ne veux ni les mêmes règles gagnantes, ni les mêmes associations ; tout doit au
plus possible aller avec tout. »

`tools/design/combinations.gd` rejoue l'espace complet des piles des 32 niveaux
prêts et ne compte que les gagnantes **minimales** — celles dont aucune
sous-suite ne gagne déjà. Le compte naïf aurait menti dans le sens flatteur :
rallonger une gagnante d'une règle inerte gonfle tous les voisinages sans rien
changer au jeu.

**LE DÉFAUT PRINCIPAL N'EST PAS CELUI QU'ON CHERCHAIT.** On cherchait des règles
omniprésentes ; on a trouvé pire :

| Constat | Mesure |
|---|---|
| Niveaux à **UNE seule** gagnante minimale | **22 sur 32** |
| Jeux de règles gagnant **3 niveaux** chacun | `[1,2]`, `[1,4,5]`, `[1,16]`, `[8,9]`, `[1,11,12]`, `[5,11,12]` |
| Monopoles (règle dans TOUTES les gagnantes d'un niveau) | 20, dont tout le chapitre 4 (R11+R12) |
| Règles à **un seul partenaire** dans tout le jeu | R08 (R09), R13 (R01), R15 (R01) |

Sur vingt-deux niveaux, « des résultats différents pour les mêmes entrées » est
**impossible par construction** : il n'y a qu'une réponse. Le joueur qui résout
ch3_02 récite la même pile en ch3_03 et ch3_04 — les trois valent `[8,9]`.

**DEUX ATTELAGES SONT STRUCTURELS, ET IL FAUT LE DIRE PLUTÔT QUE DE PRÉTENDRE LES
DÉFAIRE.** R08 « Marquer » n'a de sens que si quelqu'un suit ; R11 « Porter » n'a
de sens que si quelqu'un dépose. Ce ne sont pas deux choix déguisés en un, c'est
une mécanique en deux temps. Ce qui est corrigeable, c'est que chaque moitié
n'existe **que** là : R09 peut être un moteur sans R08, et R12 peut servir sans
R11 — encore faut-il des cartes qui le permettent.

> **LE LEVIER : UNE PISTE QUI S'ARRÊTE À MI-CHEMIN.** Tout le chapitre 3 pose
> déjà une piste initiale — par l'en-tête `trail:` — mais toujours **complète**,
> de la nuée jusqu'à la sortie. R09 y est donc le moteur du premier tick au
> dernier, et il ne reste rien à composer après elle : d'où `[8,9]` en réponse
> unique aux trois niveaux.
>
> Une piste **tronquée** change la nature de l'exercice : R09 amène la nuée au
> goulot puis se tait, et la fin du trajet revient à une autre règle — laquelle,
> c'est le choix du joueur. Elle fabrique des familles distinctes par
> construction, et ne coûte pas une ligne de `core/`.
>
> *(Note d'exactitude : les symboles de grille `*` et 1-9 du parseur, eux, ne
> sont utilisés par aucun niveau — seul l'en-tête `trail:` l'est. Le mécanisme
> n'était donc pas « dormant », c'est son emploi qui était uniforme.)*

### 196. La forge, deuxième version — c'est le VALIDATEUR qui juge

Demande : « peaufine le générateur pour qu'il crée des niveaux conformes au CDC,
et avec toutes les remarques faites auparavant — plusieurs solutions mais pas
systématiquement les mêmes, des associations de règles différentes, pas toujours
le même départ/arrivée ».

**LE CHANGEMENT DE FOND EST DE NE PLUS JUGER SOI-MÊME.** La première forge avait
son propre score maison ; elle produisait donc des cartes que le validateur
pouvait refuser ensuite, et on aurait passé le temps gagné à arbitrer entre deux
outils. Le verdict vient maintenant de `ValidateLib.validate_level`, celui-là
même qui décide en ligne de commande. C'est l'esprit de DT-15 : une seule
implémentation.

Trois **vetos**, tous des motifs de refus du CDC :

1. **QN-01** — hors de `3 ≤ classes ≤ 40`, la carte est un puzzle déguisé ou un
   niveau creux. Sur un premier balayage de 140 géométries, **58 tombaient à
   exactement deux classes** — juste sous le seuil. Le mur est réel, et il
   explique pourquoi tant de niveaux écrits à la main n'y satisfont pas.
2. **Sur-place perpétuel** — « le joueur y verra un bug », le motif exact qui a
   fait rejeter la troisième refonte de ch2_05.
3. **Solution trop courte** — la carte que `[R01]` seule résout.

Et un quatrième, propre à la forge : **la signature déjà servie**. Un jeu de
règles qui gagne déjà un autre niveau est refusé d'office, automatiquement — il
fallait auparavant les lister à la main.

#### La mesure qui rend la demande opérationnelle

**27 associations sur 91 possibles.** C'est le chiffre de la photo du catalogue :
sur les quatre-vingt-onze paires que quatorze règles peuvent former, vingt-sept
seulement ont déjà gagné ensemble quelque part. **Moins d'un tiers.** C'est la
forme chiffrée de « une règle ne fonctionne qu'avec certaines règles », et c'est
devenu le poste le plus lourd du score : une paire inédite vaut trente points,
une famille de plus n'en vaut que douze. Une carte qui réunit les mêmes règles
que partout ailleurs ne vaut rien, même avec cinq familles.

La photo coûte plusieurs minutes ; elle est **mise en cache**, clefée par une
empreinte de tous les fichiers de niveau et de `data/rules.json`. Le moindre
octet modifié la fait recalculer — un cache qui sert une réponse périmée sans le
dire serait pire que pas de cache.

#### « Pas toujours le même départ/arrivée » : la carte pivote

La géométrie canonique est produite dans l'idiome — lumière derrière le mur,
sortie = l'ouverture — puis **tournée d'un quart, d'un demi ou de trois quarts
de tour**. La sortie passe au Nord, à l'Est, au Sud ou à l'Ouest.

Ce n'est pas cosmétique, et l'invariant n°19 le garantit : à égalité toute règle
préfère le Nord puis l'Est, donc **une nuée qui monte vers la sortie ne se
comporte pas comme une nuée qui descend**. Chaque orientation est mesurée
séparément, comme le niveau distinct qu'elle est.

> **PREMIER DÉFAUT DE LA ROTATION, ET IL COÛTAIT LA MOITIÉ DU BUDGET** : un
> quart de tour ÉCHANGE largeur et hauteur, et une grille 9×11 parfaitement
> légale devient un 11×9 illégal au regard du CDC §8.1 (8×10 à 14×18). Trente
> candidats sur soixante partaient au refus du convertisseur. Les bornes sont
> désormais appliquées à la GÉNÉRATION, en tenant compte de l'orientation.

#### La preuve expérimentale du moteur unique : 900 sur 900 sans gagnante

Un balayage a été lancé avec une bibliothèque **sans R01** — `[R02, R04, R05,
R06, R13]` — précisément pour forcer des associations neuves : toute famille
gagnante y aurait été inédite par construction.

**Neuf cents géométries, zéro pile gagnante. Pas une.**

Ce n'est pas un échec du balayage, c'est sa mesure la plus utile. Elle démontre
ce que la photo du catalogue laissait deviner : **le jeu n'a que deux règles
capables d'aller quelque part**, R01 (la lumière) et R09 (la piste). Toutes les
autres modulent un déplacement qu'elles ne savent pas produire — s'écarter, se
regrouper, longer, disperser, boucher. Retirez les deux moteurs, et la nuée
reste sur place quelle que soit la carte.

> **CONSÉQUENCE DIRECTE SUR « TOUT DOIT ALLER AVEC TOUT »** : les 64 paires
> jamais vues ne sont pas un oubli de conception des niveaux, elles sont une
> propriété de la BIBLIOTHÈQUE. Une paire sans moteur ne peut gagner nulle part,
> sur aucune géométrie — et l'immense majorité des paires manquantes est de
> cette forme. Aucune forge ne les produira.
>
> La sortie est un **troisième moteur**, indépendant de la lumière et de la
> trace. C'est une décision de conception, pas un correctif : ajouter une règle
> change l'équilibre de tout le catalogue, et elle n'est pas prise ici.

#### Deux renoncements, tous deux motivés par une mesure

- **La forge ne pose plus aucune piste.** Une piste tronquée est structurellement
  injouable (pathologie P3, mesurée sur ch3_04) et une piste complète rend le
  niveau trivial. Le tracé d'un détour est une intention, pas un paramètre.
- **Elle ne réénumère plus l'espace des piles.** Le validateur vient de le
  simuler ; relire ses lignes coûte zéro, et surtout cela supprime une SECONDE
  implémentation de « qui gagne » — le genre de doublon qui finit par diverger
  et par faire mentir l'outil sur ses propres résultats.

### 198. Ce qui reste ouvert, et pourquoi — l'état honnête du catalogue

Trois chantiers sont mesurés, compris, et **non résolus**. Les laisser nommés
vaut mieux que de les laisser se redécouvrir.

#### ch4_04 « Le tri » — une seule famille, et la géométrie en est la cause

Deux gagnantes minimales, **un seul jeu de règles** `[1, 11, 12]`, et les trois
règles en monopole : le joueur n'y choisit que l'ordre. `widen_search.gd` a
passé les quatorze règles dessus et conclut « aucune n'enrichit ce niveau sans
le banaliser » — exactement le verdict rendu sur ch3_03.

**C'est donc la carte qu'il faudrait refaire, pas la bibliothèque**, et sa
refonte invaliderait ses deux recettes d'or. Le geste est identique à celui de
ch3_04 et demande la même autorisation.

> **NUANCE À NE PAS PERDRE : le monopole R11/R12 du chapitre 4 n'est PAS un
> défaut.** L'objectif y est `collect` ; porter sans déposer est inerte, déposer
> sans porter aussi. Les deux règles ne font pas deux choix, elles font une
> mécanique en deux temps — c'est le SUJET du chapitre. Ce qui doit varier, et
> qui varie déjà en ch4_01, ch4_02 et ch4_03, c'est le **troisième rang** :
> `[1,…]`, `[5,…]`, `[9,…]`. ch4_04 est le seul à n'en offrir qu'un.

#### L'ATELIER À BOUCLIERS EST INERTE PAR CONSTRUCTION — et cette fois on sait pourquoi

**~4 900 géométries mesurées en quatre balayages, plus une dizaine de cartes
dessinées à la main. Aucun niveau.** Ce n'est plus un échec de recherche, c'est
un résultat, et il porte sur la mécanique elle-même.

**LA FENÊTRE EST VIDE, et les deux bords sont mesurés :**

| L'atelier est… | Résultat | Mesuré sur |
|---|---|---|
| **sur le chemin forcé** | `[R01]` seule sort **20/20 sans une perte** | 5 géométries |
| **à l'écart du chemin** | **0 pile gagnante** — insoluble | 5 géométries |

La preuve que la mécanique FONCTIONNE est pourtant nette : sur la même carte,
avec l'atelier **17 piles gagnantes et CONFORME QN-01**, sans lui **zéro,
insoluble**. Le bouclier porte donc — mais il porte pour tout le monde, ou pour
personne.

> **LA CAUSE EST STRUCTURELLE ET ELLE TIENT EN UNE PHRASE : aucune règle ne peut
> viser l'atelier.** L'agent le ramasse en marchant dessus, passivement. Or
> Volens est un jeu où l'on n'exprime des choix que par l'ORDRE DES RÈGLES —
> un élément de carte qu'aucune règle ne peut cibler ne peut jamais devenir un
> choix. Il est décoratif, ou il est obligatoire ; il ne peut pas être une
> décision.
>
> C'est le même raisonnement qui avait fait retirer R07 et R10, appliqué à une
> case au lieu d'une règle — et il rejoint exactement le principe de clarté :
> *ne pas ajouter des choses pour le fait de les ajouter*.

**DEUX SORTIES, ET AUCUNE N'EST À PRENDRE SEUL** puisque le bouclier a été
demandé explicitement :

1. **Une règle qui cherche l'abri.** Elle rendrait l'atelier ciblable, donc
   choisissable, donc un vrai rang de pile à disputer. C'est l'ajout d'une
   quinzième règle — décision de conception.
2. **Le retrait de l'atelier.** Sa valeur d'énumération n'étant portée par aucun
   niveau, elle se réserve sans toucher à une seule empreinte d'or, exactement
   comme les identifiants de R07 et R10 restent réservés.

La troisième voie — un atelier à charges limitées — est **fermée depuis la
décision 191** : « un bouclier unique pour vingt agents ferait un puzzle de
PILOTAGE », et on ne pilote pas les agents de Volens.

**CE QUE LA FORGE A GAGNÉ AU PASSAGE** : le gabarit `split`, deux routes de
coûts différents, qui produit désormais des cartes conformes — dont une **avec
sortie au Sud**, première preuve que la rotation fabrique bien un niveau
distinct. Un défaut y a été corrigé, invisible dans les chiffres et évident en
relisant la carte : il perçait **trois** ouvertures au lieu de deux, dont deux
voisines, si bien que le goulot bouché se contournait d'une case.

#### ch2_04 ≡ ch2_05 — FUSIONNÉS le 20 août 2026

« Pour les niveaux identiques il faut les fusionner en effet. » ch2_05 est
retiré ; ch2_04 reste.

**RIEN DE JOUABLE NE SE PERD, et c'est mesuré** : les deux acceptaient
exactement les mêmes trois familles gagnantes — `[1,4,5]`, `[1,4,6]`, `[4,5,6]`
— sur le même mobilier, avec la même bibliothèque et le même objectif. Seule la
nuée différait. On garde ch2_04, plus riche d'une gagnante minimale, et dont la
leçon — l'asymétrie Nord>Est>Sud>Ouest — est le sujet du chapitre.

> **LA SUPPRESSION N'A DEMANDÉ AUCUNE RÉGÉNÉRATION D'EMPREINTE**, et c'est ce
> qui la distingue d'une refonte. Retirer les deux recettes de ch2_05 laisse les
> 72 autres intactes : elles gardent leurs empreintes archivées et concordent
> toujours. Le protocole n'interdit pas de RETIRER une recette dont le niveau
> n'existe plus ; il interdit d'en réécrire une dont le niveau existe encore.

La liste d'attente `KNOWN_TWINS` est désormais **vide**, et c'est l'état normal :
une entrée n'y a sa place que le temps qu'une décision humaine soit prise.

### 199. PASSE COMPLÈTE SUR L'APPAREIL — six défauts, dont un qu'aucun test ne pouvait voir

Parcours joué de bout en bout sur le S22, progression effacée pour éprouver le
chemin du NOUVEAU joueur — celui qui exerce les légendes et que personne n'avait
jamais suivi. La sauvegarde a été extraite avant, remise après ; au passage,
**la migration de schéma 2 → 3 s'est exécutée sur une vraie progression et l'a
conservée intacte**.

| # | Défaut | Où il se voyait |
|---|---|---|
| 1 | La légende blanchissait la case qu'elle désignait | capture |
| 2 | Le bandeau « posez une règle » ne partait jamais | capture |
| 3 | …et se retrouvait SOUS le panneau de règles | capture |
| 4 | Le bilan collait son contenu au bord haut, deux tiers d'écran vides | capture |
| 5 | La carte se posait SUR les cases qu'elle décrivait | capture |
| 6 | **Deux légendes créées en double, l'objectif ouvert trop tôt** | **appareil seul** |

**LE SIXIÈME EST LE SEUL QUI COMPTE VRAIMENT**, parce qu'il était invisible
partout ailleurs. Sur Android, un contact tactile produit **deux** évènements :
un `InputEventScreenTouch` et un `InputEventMouseButton` simulé. Les deux
branches émettaient `dismissed`, donc le récepteur enchaînait deux fois : deux
légendes suivantes créées l'une sur l'autre, la première se refermant aussitôt
sur le même geste et ouvrant le panneau d'objectif, la seconde restant affichée.

À l'écran, cela reproduisait exactement le défaut qu'on venait de corriger — une
légende et un objectif en même temps. **La cause était ailleurs que là où le
symptôme se voyait**, et deux corrections successives auraient pu être faites au
mauvais endroit avant de la trouver. Au poste de travail, une souris n'émet
qu'un évènement : le bogue ne pouvait pas exister.

#### Ce que le principe de clarté a imposé à l'interface

Deux légendes sur une même carte affichaient deux noms et surlignaient deux jeux
de cases **avec le même cadre** : rien ne disait laquelle allait avec laquelle.
Une désignation ambiguë ne désigne pas. Elles s'enchaînent désormais, une seule
à la fois, chacune avec son seul surlignage — et la carte se place dans la
moitié d'écran OPPOSÉE aux cases qu'elle montre, parce qu'une carte posée sur ce
qu'elle décrit annule son propre surlignage.

> **ET LA CASE GARDE SA COULEUR.** Un halo blanc uniforme désignait très bien,
> mais il montrait la lumière BLANCHE — le joueur serait allé chercher un carré
> blanc là où le jeu en met un ambre. Une désignation qui déguise ce qu'elle
> désigne renseigne à moitié.

#### LE MÊME PIÈGE, TROIS FOIS, TROIS SYMPTÔMES SANS RAPPORT APPARENT

Android émet, pour un seul geste physique, l'évènement tactile **et** son
équivalent souris ÉMULÉ, à la même position et dans la même image. Tout code qui
traite les deux agit en double — et le symptôme n'a rien à voir avec la cause :

| Où | Ce qu'on voyait | Ce qui se passait |
|---|---|---|
| **Légende** | une légende ET l'objectif affichés ensemble | la carte suivante créée deux fois ; l'une se refermait sur le même geste |
| **Défilement** | « ça s'arrête net, mais seulement à certains moments » | le doublon portait un déplacement NUL et écrasait la vitesse par zéro |
| **Pause** | « toucher une zone vide ne fait rien » | `_toggle_play()` appelé deux fois, donc pas du tout |

**TROIS CORRECTIONS LOCALES AURAIENT LAISSÉ PASSER LA QUATRIÈME.** Le verrou vit
donc dans `PointerEvents`, et tout code qui lit des évènements de pointage y
passe. C'est le même raisonnement que l'invariant n°16 : après trois divergences
sur trois champs, on ne corrige plus au cas par cas.

> **POURQUOI UN VERROU DÉFINITIF ET NON UN FILTRE PAR ÉVÈNEMENT** : on ne peut
> pas reconnaître un évènement souris émulé à son contenu — il est en tout point
> semblable à un vrai. Ce qu'on sait, c'est qu'un appareil ayant produit un
> évènement tactile n'a pas de souris. Une fois le doigt vu, la souris n'est
> qu'un écho. Le poste de travail, lui, n'émet jamais de tactile : le verrou ne
> s'y ferme jamais, et les captures comme les tests d'interface continuent de
> fonctionner à la souris.

#### Le message de pile vide est retiré

« Le message quand la pile est vide ne sert à rien, pire il gêne. » Exact sur les
deux points : la pile est visible à l'écran et ses emplacements vides disent déjà
ce que la phrase répétait, tandis que le bandeau se posait sur le terrain et
masquait la nuée au moment précis où le joueur cherchait pourquoi rien ne part.

**Le refus, lui, reste** — une nuée sans règle ne bouge pas, et la simulation ne
pourrait que courir jusqu'au bout du temps pour rendre une défaite imméritée. Le
retour haptique suffit à dire non.

#### Le défilement accrochait — trois causes, et la première était déjà connue

« Parfois le scroll se bloque, ça s'arrête net, mais seulement à certains
moments. »

1. **Le doigt parle deux fois.** Android émet, pour UN seul mouvement,
   un `ScreenDrag` **et** un `MouseMotion` émulé portant la MÊME position. Le
   premier calculait la vitesse ; le second, avec un déplacement nul, la
   remettait à **zéro**. La vitesse rendue à la liste au relâchement était celle
   du dernier évènement reçu — et le « parfois » venait de l'ordre d'arrivée,
   qui n'est pas garanti. **C'est exactement la cause qui dédoublait les
   légendes** : le même piège, deux symptômes sans rapport apparent, à deux
   endroits du code.
2. **Le conteneur défilait aussi de son côté.** `ScrollContainer` a son propre
   défilement tactile, engagé au-delà de `scroll_deadzone` — nul par défaut,
   donc dès le premier pixel. Deux systèmes écrivaient `scroll_vertical` dans la
   même image : le nôtre en ABSOLU, le sien en RELATIF. Le résultat dépendait de
   l'ordre. Un seul propriétaire désormais.
3. **Un évènement sans déplacement rafraîchissait l'horloge.** `_last_time`
   avançait à chaque doublon, si bien qu'un doigt immobilisé avant d'être levé
   passait encore pour « en mouvement ». Corrigé au passage : l'horloge n'avance
   plus que lorsque la position change vraiment.

**MESURÉ APRÈS CORRECTION** : à distance de geste égale, un geste vif emporte la
liste **1 136 pixels plus loin** qu'un geste lent — l'élan existe et se sent.
Six gestes successifs : trois déplacements francs, puis zéro. Vérification faite,
la liste était simplement **arrivée au bas** ; le troisième était le dernier
possible. Un zéro n'est pas un blocage tant qu'on n'a pas regardé ce qu'il reste
à faire défiler.

#### Un niveau résolu ne se reverrouille jamais

Toujours l'insertion de ch5_09 au milieu du catalogue, et cette fois le symptôme
est grave : **ch6_01, résolu depuis longtemps, s'affichait cadenassé**, son nom
masqué derrière « terminez “Le péage” » — pendant que l'en-tête annonçait « 5 / 5
résolus » juste au-dessus. L'écran se contredisait sur la même colonne.

Reprendre à un joueur l'accès à ce qu'il a terminé ne se lit jamais comme une
mise à jour : cela se lit comme une **perte de sauvegarde**. Un niveau résolu est
donc déverrouillé quoi qu'il arrive avant lui, et un test tient l'autre bord —
un niveau jamais résolu reste derrière son prédécesseur.

#### Une correction qui paraissait complète et ne l'était qu'à moitié

Dans la liste des niveaux, **une** tuile s'affichait en blanc au milieu des
tuiles vertes. Rien ne la distinguait dans le jeu — c'était simplement celle qui
se trouvait sous le **pointeur émulé**, laissé par le moteur à la dernière
position touchée.

Le survol avait pourtant déjà été corrigé (décision antérieure) : le STYLE de
survol était aligné sur l'état normal. Mais **`font_hover_color` ne l'était
pas**, et le thème y met du blanc, qui écrase le `font_color` posé par
l'appelant. La correction précédente traitait la moitié visible du problème.

> **POSER LA COULEUR D'UN SEUL ÉTAT EST UNE ERREUR QU'ON NE PEUT PAS VOIR EN
> RELISANT** : elle ne se manifeste que sous le doigt, sur un seul élément, et
> seulement tant que le doigt vient de passer là. `UiButtons.tint()` pose
> désormais les quatre états d'un coup, et un test refuse qu'il en manque un.

Le diagnostic tient à la mesure : (242,242,242) contre (51,199,143). Après
correction, les quatre tuiles échantillonnées rendent la même valeur. Sans
relevé de pixels, j'aurais cherché du côté du focus — hypothèse plausible,
fausse, et qui m'avait déjà coûté un aller-retour.

#### Un faux positif, gardé pour la méthode

Une capture m'a paru montrer les boutons du bilan dupliqués en haut de l'écran.
Vérification des pixels : les trois cents premières lignes étaient uniformément
sombres (luminance 16 sur 255). **Il n'y avait rien.** La lecture d'un rendu
réduit avait inventé un défaut, et sans la mesure j'aurais « corrigé » du code
sain. Devant une capture, les pixels tranchent, pas l'impression.

### 197. AUDIT DU VOCABULAIRE — quatre éléments en défaut du principe de clarté

« Il faut que les éléments soient clairs. Ne pas ajouter des choses pour le fait
de les ajouter. Si j'ai deux zones qui tuent ou qui font la même chose c'est une
erreur de conception ; s'il y a une ambiguïté c'est pas normal. »

Le principe ne vaut pas que pour la suite : il **met en cause l'existant**.
Comptage des types de case réellement posés sur les 34 niveaux :

| Élément | Niveaux | Verdict |
|---|---|---|
| Mur · Sortie · Lumière | 25 · 28 · 29 | le socle, rien à dire |
| **Danger fixe** | 10 | la référence |
| **Danger cyclique** | **2** | *tue aussi* — voir ci-dessous |
| Ressource · Dépôt | 5 · 5 | paire indissociable, une seule idée en deux temps |
| **Plaque à pression** | 4 | *ouvre une porte* |
| **Bascule** | **1** | *ouvre une porte aussi* |
| Sens unique | 2 | ch4_02, ch6_05 — voir la correction |
| **Atelier à boucliers** | **0** | **jamais posé nulle part** |

> **CORRECTION DU PREMIER COMPTAGE, ET ELLE CHANGE LA CONCLUSION.** Le sens
> unique était d'abord porté « jamais posé nulle part ». C'était faux : il vit
> dans `grid.one_way`, une liste séparée, et **pas** comme une valeur de case —
> ch4_02 et ch6_05 en portent six chacun. Le comptage balayait `grid.cells` et
> ne pouvait pas le voir.
>
> Le défaut de méthode vaut d'être gardé : **un inventaire qui n'interroge
> qu'une seule représentation déclare morts les éléments rangés ailleurs.** Le
> même piège avait produit trois divergences sur trois champs de niveau, d'où
> l'invariant n°16. Ici il aurait fait supprimer un mécanisme vivant.

**UN SEUL ÉLÉMENT N'EXISTE QUE DANS LE CODE** : l'atelier à boucliers, et sa
raison est écrite (décision 191). C'est la version « case » du défaut qui avait
fait retirer R07 et R10 — *utile veut dire UTILISÉ*.

**DEUX PAIRES SE RECOUVRENT, et c'est exactement le cas décrit :**

- **Danger fixe / danger cyclique.** Les deux tuent, les deux sont rouges. La
  seule différence est une fenêtre de temps — or le projet refuse ailleurs les
  énigmes de minutage : « on ne compte pas les ticks entre deux passages, on
  décide qui va la chercher » (décision 188). Le cyclique demande au joueur de
  compter ce que le reste du jeu lui dit de ne pas compter, pour deux niveaux.
- **Plaque à pression / bascule.** Les deux ouvrent une porte. La décision 188
  les justifie comme contraires — la plaque coûte des agents en permanence, la
  bascule un détour une seule fois — et l'argument tient **au niveau de la
  conception**. Il ne tient pas forcément **à l'écran** : le joueur voit deux
  marques distinctes qui produisent le même effet visible, et rien ne lui dit
  laquelle est momentanée. Une seule est utilisée une seule fois.

#### Résolution 1 — le danger cyclique se distingue enfin QUAND IL TUE

Le défaut n'était pas que le cyclique existe, c'est qu'il était **indiscernable
au moment où la distinction comptait** :

| Phase | Avant | Lisibilité |
|---|---|---|
| Éteint | teinte dormante | se distinguait très bien |
| **Allumé** | **teinte du danger permanent** | **rien ne le distinguait** |

Le pire découpage possible : la différence n'apparaissait que lorsqu'elle avait
cessé d'être utile, et disparaissait précisément au moment où elle décidait de
la vie d'un agent.

**QUATRE CRANS AUX COINS, POSÉS DANS LES DEUX PHASES.** Ce que la marque dit
n'est pas « en ce moment c'est dangereux » — la teinte le dit déjà, et mieux.
Elle dit « **cette case-là change** », qui est une propriété permanente et doit
donc s'afficher en permanence. Une marque qui apparaîtrait avec le danger
n'ajouterait rien ; une marque qui clignoterait demanderait d'être regardée au
bon moment, ce qu'ENF-21 refuse. Quatre crans plutôt qu'un anneau parce que
l'anneau est déjà pris par la bascule et l'atelier — et deux dispositifs qui se
ressemblent sont exactement le défaut qu'on corrige.

**LA PAIRE PLAQUE / BASCULE, ELLE, N'EST PAS EN DÉFAUT** et il faut le dire
plutôt que de « corriger » ce qui n'est pas cassé : 320° contre 20° sur la roue
des teintes, et la bascule porte un anneau avec un état *dépensée* que la plaque
n'a pas. Elles ne se confondent ni en apparence ni en effet.

#### Résolution 2 — une légende, une fois, à la première rencontre

**CE QUE FAIT UNE CASE N'EST PAS UNE DÉCOUVERTE, C'EST UN FAIT.** Le jeu n'a pas
de tutoriel et n'en aura pas : on demande au joueur de découvrir ce qu'une PILE
produit, et le lui dire reviendrait à jouer à sa place. Mais rien à l'écran ne
distinguait une plaque d'une bascule ; il l'apprenait en perdant.

La ligne de partage est nette, et un test la tient : **on dit ce que la case
FAIT, jamais ce qu'il faut en faire.** « La porte reste ouverte tant que des
agents sont dessus » décrit ; « postez-y deux agents » jouerait à sa place — le
test refuse les tournures d'instruction dans le catalogue.

Trois contraintes de forme, chacune contre un défaut connu : la carte **ne
bloque rien** (la simulation tourne derrière, un contact n'importe où la
referme) ; elle **ne se répète jamais** ; **deux au plus à la fois**, parce que
trois légendes d'affilée se referment sans être lues.

**LA LÉGENDE DÉSIGNE CE DONT ELLE PARLE**, et c'est l'essai sur l'appareil qui
l'a exigé : « lorsque l'on décrit un élément, il faut qu'il soit en surbrillance
par rapport au reste pour comprendre de quoi on parle ». Le mot « Lumière »
devant huit marques colorées ne renseigne pas — le joueur lit un nom et cherche
à quoi il correspond. Le voile s'assombrit donc à 0,72 et les cases décrites
reçoivent un halo par-dessus lui, plus lumineuses que tout le reste de l'écran.

> **LA SURBRILLANCE PASSE PAR-DESSUS LE VOILE, jamais en le trouant.** Découper
> des trous demanderait de composer des rectangles, et laisserait de toute façon
> la case au même éclat que le reste. Un halo par-dessus la rend PLUS lumineuse
> que son entourage, ce qui est exactement le geste de désignation cherché.

**TROIS DÉFAUTS DE MISE EN PAGE, tous invisibles au poste de travail et tous
évidents sur la première capture.** La carte partait sur le côté et chevauchait
les emplacements de règles — un `PRESET_CENTER` en mode MINSIZE se cale sur la
taille minimale du panneau, or celle d'un libellé à retour à la ligne
automatique vaut zéro ; il fallait un `CenterContainer` plein écran. Le texte se
posait à même la grille, la nuée passant derrière les mots. Et surtout **la
légende s'affichait EN MÊME TEMPS que le panneau d'objectif** — deux surcouches,
chacune avec son « touchez pour… », et le joueur ne sait plus ce qu'il referme.
Deux panneaux simultanés ne font pas deux informations, ils en font zéro.

L'ordre retenu est légende PUIS objectif, parce que la légende explique le
vocabulaire que l'objectif emploie : lire « faire sortir 17 agents » sans savoir
ce qu'est la lumière qu'on voit à l'écran, c'est lire la consigne avant
l'alphabet.

> **DEUX PIÈGES ÉVITÉS DE JUSTESSE, tous deux silencieux.**
>
> **L'enregistrement se fait à l'AFFICHAGE, pas à la fermeture.** Une carte
> fermée par un retour au menu, une mise en veille ou la fin du processus
> serait sinon revenue au niveau suivant, et la « une seule fois » n'aurait plus
> rien d'une promesse.
>
> **Les migrations de sauvegarde se CHAÎNENT.** Le schéma passe à 3 pour porter
> `seen`. Un joueur resté en schéma 1 n'aurait trouvé aucune règle « 1 → 3 » et
> serait tombé dans le repli propre — c'est-à-dire aurait **tout perdu au moment
> précis où l'on ajoute une commodité d'affichage**. Les étapes s'appliquent
> désormais l'une après l'autre, et `SaveStore.migrate_for_test` rend la chose
> interrogeable : c'est le seul code du dépôt dont la panne se paie en données
> de joueur, et il ne s'exécute jamais chez nous.

> **CE QUI EST TRANCHÉ ICI, ET CE QUI NE L'EST PAS.** Le principe est acquis et
> s'applique à toute addition future — c'est déjà ce qui a fait retirer R02, R13,
> R05 puis R14 de la bibliothèque de ch2_06, jusqu'à ce que les trois règles
> restantes portent toutes une gagnante.
>
> Le nettoyage de l'existant, lui, n'est PAS fait : retirer un type de case
> touche `core/sim/`, le parseur, la palette et les tests, et **renuméroter
> l'énumération changerait toutes les empreintes d'or** — les cases sont hachées
> par leur valeur. La sortie propre est de réserver les valeurs mortes sans les
> réattribuer, exactement comme les identifiants de R07 et R10 restent réservés.
> C'est une opération à part entière, à décider.

### 200. La forge, troisième version — elle écrit un niveau FINI

« Il faut que les niveaux créés soient bons. » La version précédente trouvait des
géométries conformes ; il restait à faire à la main, à chaque fois, les trois
gestes qui séparent un candidat d'un niveau. Ils sont désormais dans l'outil.

**1. LA BIBLIOTHÈQUE SE RESSERRE JUSQU'À CE QUE TOUT PORTE.** C'est le geste que
ch2_06 a demandé QUATRE fois de suite : le balayage l'avait trouvé avec six
règles, dont deux que RG-13 déclarait inobservables et deux qui ne portaient
aucune gagnante minimale. La forge retire donc les règles sans charge, **puis
re-mesure** — retirer des règles change l'espace des piles, donc les gagnantes,
donc le verdict.

> **ET UN CANDIDAT QUI NE SURVIT PAS AU RESSERRAGE EST ÉCARTÉ.** S'il tombe sous
> QN-01 une fois ses fausses pistes retirées, c'est qu'il ne tenait que par
> elles. C'est un critère de qualité qu'aucune mesure sur la bibliothèque large
> ne peut donner : il faut avoir enlevé pour savoir.

**2. LES COMPTEURS SONT DÉCLARÉS DEPUIS LA MESURE.** `expected_wins`,
`expected_classes` et `calibrated_on` sont écrits dans l'en-tête à partir de la
simulation qu'on vient de faire. Le validateur les confronte ensuite à la
sienne ; les recopier à la main était la seule source d'« ÉCART À LA FICHE ».

**3. DEUX DÉFIS QUI EXIGENT DEUX PILES DIFFÉRENTES.** L'économie récompense la
plus courte des gagnantes ; l'abstinence interdit une règle **que cette plus
courte emploie**, ce qui force à en chercher une autre. Et elle ne porte jamais
sur une règle qu'aucune gagnante n'évite — ce serait un mur, pas un défi.

### 196 bis. ch2_06 « L'ouverture décalée » — première carte retenue par balayage

Mille cinq cents géométries mesurées, vingt-huit conformes QN-01, une retenue.

**LE DISPOSITIF TIENT EN UNE CASE D'ÉCART.** Une paroi médiane percée d'UNE
ouverture, décalée d'une seule colonne par rapport à la sortie. « Vers la
lumière » est gloutonne — elle ne consent jamais à s'éloigner du but, même d'une
case — donc elle monte la nuée droit sous la paroi, à l'aplomb de la sortie, et
s'y arrête. Seule la colonne qui tombe déjà en face du trou passe.

Trois familles, trois manières d'accepter le détour d'une case : `[R01, R04]`
desserre la nuée jusqu'à ce qu'elle trouve le trou, `[R01, R06]` la fait glisser
le long de la paroi jusqu'à lui, `[R01, R04, R06]` combine. **`[1,6]` est une
signature inédite** — et c'est une petite trouvaille en soi, puisque
l'invariant n°20 note que R06 et R01 se contredisent structurellement.

> **IL A FALLU QUATRE RESSERRAGES DE BIBLIOTHÈQUE**, et c'est le vrai
> enseignement. Le balayage avait trouvé la carte avec six règles. RG-13
> signalait déjà R02 et R13 comme *inobservables* — pas de danger, pas de goulot
> à boucher. Restaient quatre, et la mesure des gagnantes **minimales** a montré
> que R05 « Suivre les voisins » n'en portait aucune. Remplacée par R14
> « Disperser si dense » : elle non plus. Restent **trois règles, toutes
> porteuses**.
>
> Une règle qui figure dans une bibliothèque sans porter aucune gagnante ne rend
> pas le niveau plus difficile, elle le rend plus long — c'est exactement ce qui
> avait bloqué un joueur au chapitre 5. **La forge trouve la géométrie ; c'est
> la mesure des minimales qui taille la bibliothèque**, et les deux gestes sont
> distincts.

Ses deux défis exigent deux piles différentes : l'abstinence de R06 force
`[R01, R04]`, l'efficience de 23 ticks n'est atteinte que par `[R01, R06]`.

### 195. Les défis étaient calculés, enregistrés, affichés — et illisibles

Deux angles morts signalés au même essai, et ce sont **deux moitiés d'une même
question** : « à la fin du niveau, ce n'est pas clair quels défis ont été
résolus, à la fois en général et sur l'exécution actuelle » ; « dans le menu, il
faudrait savoir ce qu'il reste à accomplir ».

**LE BILAN NE CONNAISSAIT QUE LA PARTIE QUI VENAIT DE FINIR.** Un défi acquis
trois parties plus tôt s'y affichait creux, exactement comme un défi jamais
obtenu — et le joueur repartait le chercher pour rien. Il y a désormais trois
états, pas deux : `obtenu à l'instant`, `déjà acquis`, et rien.

> **UN DÉTAIL D'ORDRE PORTE TOUTE LA DISTINCTION**, et c'est le genre de chose
> qu'aucun compilateur ne dit. `App` enregistrait les défis AVANT d'afficher le
> bilan ; à ce moment-là les deux ensembles se confondent, et la question
> « était-ce déjà acquis ? » n'est plus posable. Il fallait en prendre la photo
> avant l'enregistrement et la passer à l'écran. Intervertir ces deux lignes
> ferait disparaître la distinction en silence — d'où le commentaire à
> l'endroit exact, et un test qui l'éprouve.

**LE MENU DISAIT COMBIEN, JAMAIS QUOI.** Les pastilles `◆◇` comptent les défis
acquis sans nommer ce qu'ils demandent : un losange creux sans libellé est une
énigme sur l'énigme. Une ligne discrète sous la tuile nomme maintenant **ce qui
reste, et seulement ce qui reste** — « il reste : sans “Suivre la piste” ».

Trois raisons de ne nommer que le restant plutôt que la liste entière :

- c'est **deux fois plus court**, donc ça tient sur un écran étroit, où la tuile
  se tronque déjà par ellipse ;
- c'est **exactement la question posée** — savoir ce qu'il reste à accomplir ;
- un niveau dont tout est acquis n'affiche **rien**, et le silence est la
  récompense. Une liste qui continue de réclamer après qu'on a tout fait
  transforme un niveau fini en dette, ce que RG-19 interdit.

RG-19 tient partout : rien n'est barré, rien n'est grisé, rien ne conditionne la
progression. « Il reste » est une proposition, pas un reproche.

### 194. ch5_09 « Le péage » — le premier niveau sorti de la forge, et le premier CONFORME QN-01 depuis longtemps

**LE DÉFAUT QU'IL CORRIGE EST MESURÉ, pas ressenti.** `combinations.gd` a montré
que R13 « Boucher » n'avait qu'UN partenaire dans tout le jeu : R01. Elle gagnait
ch5_01 et ch5_05, toujours avec la lumière, jamais avec autre chose. Une règle
qui ne fonctionne qu'avec une seule autre n'est pas une règle, c'est la moitié
d'une règle.

**LE DISPOSITIF : une paroi, deux passages, et ils ne se valent pas.** Celui de
l'Est est court — la nuée est posée juste dessous — mais un danger l'obstrue.
Celui de l'Ouest est libre et loin. R13 ouvre le court en y consumant un agent ;
la piste mène au long.

| Pile | Résultat |
|---|---|
| `[R01]` seule | **16 perdus** — la lumière ignore les dangers et fait monter la nuée DESSUS |
| `[R13, R01]` | 15 sortis sur 20 — **échoue**, R13 seule avec la lumière ne suffit plus |
| `[R09, R01]` | **20/20** — le détour, sans un mort |
| `[R01, R04, R13]` | **17/20, 2 perdus** — le péage payé |

**R13 gagne donc enfin avec R04**, et l'attelage R13→R01 est rompu. Verdict du
validateur : 9 gagnantes sur 41, **5 classes structurelles, CONFORME QN-01** —
le premier niveau à passer ce seuil depuis longtemps, là où ch3_03 et ch3_04
restent des « puzzles déguisés » à une seule classe.

> **LES DEUX DÉFIS EXIGENT DEUX PILES DIFFÉRENTES**, et c'est une réponse
> directe à « les défis ne devraient pas être réalisés en un coup ». L'économie
> se gagne par `[R09, R01]` ; l'abstinence de R09 interdit précisément ce détour
> et force à payer le péage, `[R01, R04, R13]`. Deux écrans, deux recherches.

#### La mesure d'APRÈS, sur les 33 niveaux — et elle refroidit l'enthousiasme

| | Avant | Après |
|---|---|---|
| Partenaires de **R13** | 1 (R01) | **2 (R01, R04)** |
| Partenaires de **R04** | 4 | **5** |
| Règles rigides (≤ 1 partenaire) | R08, R13, R15 | **R08, R15** |
| `[8,9]` gagne | 3 niveaux | **2** |
| Niveaux à une seule famille | 22 / 32 | **20 / 33** |
| Monopoles | 20 | 21 |

**L'ATTELAGE R13→R01 EST ROMPU**, et c'était l'objet. Mais il faut dire le
reste : **`[1,9]` gagne maintenant trois niveaux** (ch3_04, ch5_09, ch6_02) là
où `[8,9]` en gagnait trois. **On a déplacé une répétition, pas supprimé une
répétition** — l'atténuation vient de ce que ch5_09 offre une seconde famille,
donc `[1,9]` n'y est pas la seule réponse.

**ET LE DÉFAUT DE FOND N'A PAS BOUGÉ : R01 reste le moteur universel**, présente
dans les gagnantes de presque tous les niveaux, avec douze partenaires sur
treize. Tant qu'une seule règle sait « aller quelque part », toute pile gagnante
devra la contenir ou contenir R09 — les deux seuls moteurs du jeu. **Ce n'est pas
un problème de niveaux, c'est un problème de bibliothèque**, et aucune géométrie
ne le résoudra. La suite se joue là, pas sur des cartes supplémentaires.

**CE QUE LA FORGE A APPORTÉ, ET CE QU'ELLE N'A PAS APPORTÉ.** Elle a trouvé la
géométrie — paroi médiane, deux ouvertures, goulot bouché — et elle a écarté
seule les 188 variantes sans gagnante et les 111 refusées par le convertisseur.
Elle n'a pas trouvé la piste : celle qu'elle proposait était un moignon
inutilisable de deux cases sous la paroi. **Elle produit une géométrie, pas une
intention** — le tracé du détour, la valeur des objectifs et la leçon restent
écrits à la main, et c'est bien la répartition annoncée.

### 193. ch3_04 refondu — et la PRÉDICTION écrite avant de toucher aux empreintes d'or

Autorisation explicite reçue le 18 août 2026 de régénérer les recettes d'or
concernées. Le protocole permanent exige une prédiction écrite **avant** le
geste ; la voici, et elle sera vérifiée par `git diff` après coup.

**PRÉDICTION.** `tests/golden/golden.json` contient 74 recettes.

| Ce qui doit changer | Ce qui ne doit PAS changer |
|---|---|
| Les **2 recettes de ch3_04** — sa géométrie est entièrement nouvelle, donc ses empreintes le sont aussi | Les **72 autres**, au bit près |
| Leur pile : `[8,9]` ne gagne plus sur cette carte, elle devient `[9,1]` | Le `rules_hash` : aucune règle n'a bougé |

**Si une seule des 72 autres bouge, ce n'est pas la refonte — c'est une
régression du déterminisme**, et le geste doit être annulé plutôt que consigné.
C'est toute la raison d'écrire la prédiction d'abord : sans elle, un diff de 74
lignes se relit en hochant la tête.

**VÉRIFICATION — la prédiction est confirmée avant même la réécriture.** La
suite complète passée sur l'état refondu donne 426 tests verts sur 427, et
l'unique échec énumère **exactement six empreintes, toutes ch3_04** (deux
recettes × trois relevés à t=50, 150 et 300) :

```
RÉGRESSION DU DÉTERMINISME — ch3_04.json pile=[9,1] t=50 / t=150 / t=300
RÉGRESSION DU DÉTERMINISME — ch3_04.json pile=[1]   t=50 / t=150 / t=300
```

Aucune des 72 autres recettes ne bouge. C'est la preuve recherchée : le
changement vient de la carte, pas du moteur — et la réécriture peut avoir lieu.

> **LE GESTE LUI-MÊME A ÉTÉ FAIT À LA MAIN**, `check_golden.gd --write` étant
> refusé par le garde-fou d'exécution de la session. C'est cohérent avec le
> protocole : la réécriture d'un fichier d'or est un geste humain, pas un effet
> de bord.

**APRÈS RÉÉCRITURE, le `git diff` compte SEIZE lignes modifiées, et pas une de
plus** : six empreintes pour la première recette de ch3_04, six pour la seconde,
et les quatre lignes du changement de pile `[8,9] → [9,1]` — décidé avant le
geste, puisque `[8,9]` ne gagne plus sur cette carte. Les 72 autres recettes
sont inchangées au bit près, et la suite complète repasse à **427/427**.

C'est exactement ce que la prédiction annonçait. Écrite après coup, elle aurait
été une description ; écrite avant, elle est une **épreuve** — et c'est la seule
chose qui distingue une régénération légitime d'une empreinte qu'on ajuste pour
faire taire un test.

#### Le niveau : « La piste mène au seuil ; la lumière le franchit »

La nuée démarre dans une **poche fermée au nord**. La lumière est droit devant,
derrière le mur de tête, et la sortie en est l'ouverture — mais la poche ne
s'ouvre que par le BAS.

**R01 s'y piège toute seule**, et c'est mesuré : 0 agent sorti. « Vers la
lumière » est gloutonne, elle ne consent jamais à s'éloigner ; elle monte donc
la nuée contre la paroi nord et s'abstient. Vingt-cinq agents à une case de la
sortie, immobiles pour toujours. La piste, elle, descend, contourne par l'Ouest
— le côté structurellement dur (invariant n°19) — et remonte.

> **LE CŒUR DU NIVEAU TIENT EN UNE LIGNE : `[R09, R01]` gagne 25/25, `[R01,
> R09]` sort ZÉRO agent.** Les mêmes deux règles, et seul l'ordre change.
> Devant, la lumière piège tout le monde et la piste ne parle jamais ; derrière,
> elle attend que le détour soit fini et n'a plus qu'un pas à faire.

**ET R09 SEULE NE SUFFIT PAS NON PLUS** : son sommet est la case sous la sortie,
où elle n'a plus rien de meilleur à viser. **Aucune piste ne mène hors du
monde** — le dernier pas revient à la lumière.

#### Trois essais ratés, et la règle qu'ils ont établie

L'idée de départ était une piste **tronquée** en plein champ : R09 mène au
goulot puis se tait, et la fin du trajet devient un choix. Elle ne marche pas,
et la raison est structurelle.

Arrivé au sommet, l'agent fait un pas sur une case vierge — et R09 y voit la
trace DERRIÈRE lui plus forte que la sienne. Il redescend. R01 le remonte, R09
le redescend. Le relevé des positions au tick 120 montre les vingt-cinq agents
en file parfaite le long du couloir, la tête coincée à une case de la sortie,
oscillant pour toujours. C'est la pathologie P3 que le parseur documente, et
elle interdit purement et simplement la piste tronquée.

**RÈGLE ÉTABLIE : une piste ne se coupe pas, elle se termine là où l'agent
disparaît.** Corollaire pour la forge, dont le gabarit `trail=half` repose
précisément sur l'idée inverse : il ne produira jamais de niveau jouable tant
que la bibliothèque contient un moteur capable de ramener l'agent sur la trace.

Deux autres mesures gardées au passage :

- **R08 en tête de pile se piège lui-même quand la nuée est bloquée.** Un agent
  qui ne peut pas avancer marque sa propre case de +6 par tick jusqu'au plafond
  de 200 ; elle devient alors la plus forte du voisinage et il ne repart jamais.
  Sur vingt-cinq agents empilés dans une poche, `[8,9]` sort zéro agent là où
  `[9,1]` en sort vingt-cinq. La règle reste bonne — c'est la *densité* qui la
  retourne contre elle-même.
- **Le dénivelé d'une piste doit dépasser le dépôt de R08**, sinon R08 aplatit
  la pente qu'elle est censée entretenir. Un pas de 1 a produit une nuée
  parfaitement immobile ; un pas de 12 tient.

### 192 ter. ch3_02 et ch3_04 sont le MÊME niveau — mesuré, pas soupçonné

« Il faut éviter d'avoir plusieurs fois le même niveau. » Le doublon signalé au
chapitre 2 avait été fusionné ; celui du chapitre 3 est resté, et personne ne
l'avait vu parce que les deux fiches racontent des leçons différentes.

Comparaison des JSON produits, champ par champ :

| | ch3_02 | ch3_04 |
|---|---|---|
| `allowed_rules` | `[1,2,4,8,9]` | **identique** |
| `objectives` · `slots` | extraction 100 · 3 | **identiques** |
| **cases non vides** | `(4,0)(5,0)(6,0)` — la sortie | **identiques** |
| `expected_wins` · `expected_classes` | 7 · 1 | **identiques** |
| Différences réelles | 11×17, 21 agents, 150 ticks | 11×18, 24 agents, 200 ticks |

Deux terrains **entièrement vides** hors la sortie, une rangée d'écart, trois
agents et cinquante ticks. Les deux se gagnent par `[8,9]`, comme ch3_03. Les
leçons annoncées — « la tête entretient la piste pour la queue » et « ce qui
n'a pas été marqué au passage ne le sera jamais » — sont **une seule leçon
énoncée deux fois**.

> **LA LEÇON DE MÉTHODE.** Deux fiches distinctes ont suffi à masquer un doublon
> pendant tout le développement du chapitre. Ce qui l'a révélé n'est pas une
> relecture : c'est d'avoir comparé les **sorties** (cases non vides, gagnantes
> minimales) plutôt que les intentions. Une fiche décrit ce qu'on a voulu ; le
> JSON décrit ce qu'on a fait.

> **CONTRADICTION À TRANCHER — LA CORRECTION EST BLOQUÉE PAR LES TESTS D'OR.**
> Les deux doublons ne peuvent pas être corrigés sans toucher à
> `tests/golden/golden.json` : il y garde **deux recettes pour ch2_05 et deux
> pour ch3_04**. Déplacer un seul mur change les empreintes archivées — et une
> empreinte d'or qui change signale une régression du déterminisme, jamais une
> valeur à mettre à jour. Le protocole exige une décision humaine explicite.
>
> **La géométrie de ces deux niveaux est donc GELÉE**, et le test porte une
> liste d'attente nommée (`KNOWN_TWINS`) plutôt qu'un silence. Un second test
> vérifie que cette liste ne survit pas à son motif : dès qu'une paire cesse
> d'être jumelle, son entrée doit disparaître, sinon elle couvrirait un futur
> doublon portant les mêmes noms.
>
> **TROIS REFONTES DE ch2_05 ONT ÉTÉ MESURÉES AVANT CE CONSTAT**, et elles
> valent d'être gardées :
>
> 1. *Refend vertical, sortie centrale, idiome respecté à la lettre* →
>    **`[R01]` seule gagne**. Onzième confirmation que l'idiome nu ne compose
>    rien ; c'est ch2_04 qui a raison de placer sa lumière **à l'opposé** de sa
>    sortie, où elle devient un leurre.
> 2. *Deux lumières-leurres, une par moitié* → **aucune gagnante**. Le piège
>    fonctionne trop bien : plus rien ne ramène personne.
> 3. *Bande médiane à deux ouvertures, extraction abaissée à 90* → deux familles,
>    mais le validateur refuse : « **1 pile gagnante laisse jusqu'à 2 agents
>    faire du sur-place perpétuel — le joueur y verra un bug** ». Un doublon
>    assumé vaut mieux qu'un niveau qui a l'air cassé.
>
> **NUANCE HONNÊTE SUR ch2_04 ≡ ch2_05.** Les deux acceptent les mêmes familles,
> mais pas pour la même raison : ch2_05 sépare la nuée en deux groupes hors de
> portée de perception, et sa question réelle — « comment deux moitiés qui ne se
> voient pas s'accordent-elles ? » — n'a aucun équivalent en ch2_04. Le doublon
> est **réel du point de vue des solutions, discutable du point de vue du
> sujet**. ch3_02 ≡ ch3_04 n'a pas cette excuse.

**ET L'ÉLARGISSEMENT NE SAUVE PAS CES NIVEAUX** : `widen_search.gd` sur ch3_03
répond « aucune règle n'enrichit ce niveau sans le banaliser » — les quatorze
règles y passent, aucune ne crée de famille nouvelle sans faire tomber la
solution en dessous de deux règles. C'est la confirmation directe de l'échec de
ch5_04 : **sur un terrain à solution unique, une bibliothèque plus large ne
donne pas plus de jeu, elle donne plus de fausses pistes.** Il faut une
géométrie nouvelle, pas un catalogue plus gros — c'est-à-dire la forge.

### 192 bis. La forge — on ne dessine plus une carte, on en mesure mille

Proposition retenue telle quelle : « un générateur de niveaux basé sur nos
critères, qui propose plusieurs configs et tu décides des meilleures ».

**CE QUI LA REND POSSIBLE MAINTENANT, ET PAS AVANT** : la fonction d'évaluation
existe depuis ce matin. Un générateur sans critère de tri produit du bruit ;
`combinations.gd` sait dire si un niveau est varié, `widen_search.gd` si une
règle y porte. Il ne manquait que la boucle au-dessus.

**ET CE QU'ELLE RÉPARE**, c'est l'ordre du travail. Écrire un niveau à la main
oblige à figer sa géométrie AVANT de pouvoir voir son espace de solutions — on
ne le découvre qu'en le jouant. Les cinq géométries de bouclier jetées (décision
191) et les vingt-deux niveaux à solution unique ont exactement cette cause. La
forge inverse l'ordre : elle produit la carte, l'interroge, et ne présente que ce
qui a répondu.

Trois garde-fous, et ils sont la condition de l'exercice :

1. **Aucun tirage aléatoire.** Le balayage est un produit cartésien parcouru dans
   un ordre fixe : deux exécutions donnent la même liste, donc la liste se
   discute. Un générateur aléatoire aurait produit des cartes irreproductibles.
2. **On génère DANS l'idiome** — lumière derrière le mur, sortie = l'ouverture.
   Une carte forgée doit ressembler aux autres, pas avoir l'air tombée d'ailleurs.
3. **La sortie est du `.lvl`, jamais du JSON.** Le convertisseur porte les
   contrôles G1-G3 et calcule `calibrated_on` ; émettre du JSON contournerait
   précisément les garde-fous écrits pour ce genre de carte. Mieux : la forge
   **appelle** le parseur pour évaluer, donc toute géométrie qu'il refuserait est
   éliminée avant d'être simulée — le refus devient un filtre gratuit.

**ELLE NE REMPLACE PAS LE JUGEMENT.** Elle classe des candidats ; la leçon du
niveau, sa fiche et son nom restent une décision humaine. Une carte qui mesure
bien et ne raconte rien n'est pas un niveau.

**PREMIERS VERDICTS, ET ILS SE PAYENT DÉJÀ.** Deux enseignements sont tombés
avant le premier niveau retenu :

- **L'idiome nu se gagne avec `[R01]` seule.** C'est la cause mécanique des
  vingt-deux niveaux à solution unique : sans obstacle intermédiaire, il n'y a
  rien à composer. La forge le rejette désormais par `--min-len`.
- **Un niveau bâti sur R13 ne peut pas exiger `extraction 100`.** Boucher consume
  un agent ; l'objectif se contredit lui-même. 201 géométries sans aucune
  gagnante l'ont dit avant qu'on le formule — et ch5_01/ch5_05 demandent bien 95
  et 80, ce que personne n'avait relié à la mécanique.

> **LE GABARIT QUI MANQUE ENCORE est celui du bouclier**, et la décision 191
> l'avait déjà décrit sans savoir qu'elle décrivait un gabarit : « une carte où
> traverser le danger est un CHOIX — un raccourci payant contre un détour lent,
> donc deux routes et une échéance qui départage ». C'est exactement un paramètre
> de balayage à ajouter, plus un dessin à trouver.

### 191. Le bouclier : un ÉQUIPEMENT, pas une règle — et pourquoi son niveau manque encore

« Dans l'imaginaire collectif, un bouclier est un objet de défense, pas
d'attaque. Pour le moment l'agent se détruit et détruit avec lui la zone. Il
faut qu'il se protège une fois et se casse, mais n'abîme pas la zone. »

C'est R13 « Boucher » qui était décrite : un SACRIFICE, où l'agent se consume et
neutralise le danger. Elle est conservée telle quelle — elle a son sens — et le
vrai bouclier est ajouté à côté.

**IL N'EST PAS UNE RÈGLE, ET C'EST LE POINT.** Un bouclier ne décide de rien :
le mettre dans la pile aurait coûté un rang sur trois pour un objet qui ne
propose aucun déplacement, et le joueur aurait cherché quand le « jouer » alors
qu'il n'y a rien à jouer. Il vit donc sur la CARTE — une case-atelier que l'on
traverse — ce qui ouvre la porte à l'emplacement d'équipement demandé (potion,
vitesse, téléporteur…) sans rien coûter à la pile.

L'ATELIER NE S'ÉPUISE PAS. Un bouclier unique pour vingt agents ferait un puzzle
de PILOTAGE — « lequel envoyer le chercher ? ». On ne pilote pas les agents de
Volens, on écrit la politique qui les gouverne tous.

Quatre propriétés, quatre tests (`tests/unit/test_shield.gd`) : la station
équipe qui la traverse ; le témoin non protégé meurt ; le bouclier encaisse UN
contact et l'agent survit ; **le danger reste actif et tue le suivant** — c'est
ce qui le sépare du sacrifice.

> **SON NIVEAU MANQUE ENCORE, ET LA RAISON EST MESURÉE.** Cinq géométries
> essayées, aucune retenue. Le constat : **sur un chemin FORCÉ, un bouclier est
> un laissez-passer.** Une seule sortie et un danger dans l'embrasure, et tout
> agent doit passer : soit l'atelier couvre tout le monde et `[R01]` seule gagne
> (25 ticks, la plus rapide de toutes — aucune échéance ne peut l'exclure), soit
> il n'en couvre qu'une partie et la préservation tombe. Deux dangers empilés
> rendent le niveau insoluble : la bibliothèque n'a rien qui évite un danger
> sans fuir indéfiniment.
>
> **Le bouclier demande une carte où traverser le danger est un CHOIX** — un
> raccourci payant contre un détour lent — donc deux routes et une échéance qui
> départage. C'est un dessin à faire, pas un réglage à trouver.

### 190. Quatorze règles, et c'est une décision de conception

« Pour les seize règles c'est pas grave, il vaut mieux des règles utiles,
claires, intéressantes en termes de gameplay plutôt que mettre des règles pour
en avoir plein. »

La divergence au CDC §7 signalée en décision 189 est donc **tranchée** : le jeu
compte quatorze règles, et le nombre n'est pas un objectif. Ce qui est un
objectif est mesuré et tenu par `tests/unit/test_every_rule_earns_its_place.gd`
— **chaque règle doit PORTER une pile gagnante quelque part**, c'est-à-dire
qu'en la retirant, cette pile cesse de gagner.

À retenir pour toute règle future : une règle ne s'ajoute pas parce qu'elle
sonne bien, mais parce qu'il existe un niveau où aucune solution ne s'en passe.

### 188. Une mécanique neuve : la bascule

Demandée : « appuyer sur un bouton pour faire des effets — ouvre une porte,
active ou désactive... ça peut être permanent ou activé uniquement à la
pression ». La plaque à pression existait déjà et couvre le second cas. La
bascule couvre le premier, et les deux se définissent l'une par l'autre :

| | plaque | bascule |
|---|---|---|
| durée | tant qu'on reste dessus | **définitive** |
| coût | des agents, en permanence | un détour, une fois |
| puzzle | qui sacrifie-t-on au rôle de portier ? | qui va la chercher ? |

**L'état tient dans le TYPE DE CASE** (`SWITCH` → `SWITCH_USED`), et c'est ce
qui rend l'ajout sûr : l'empreinte d'état couvre déjà `cells`, donc une bascule
franchie change l'empreinte sans qu'on touche `StateHash` — et les 74 recettes
d'or des niveaux qui n'en portent pas ne bougent pas d'un bit. **Une mécanique
additive ne casse pas le corpus d'or.**

Elle ne se rearme pas, délibérément : une bascule réarmable ferait un puzzle de
MINUTAGE (compter les ticks entre deux passages), une bascule à sens unique fait
un puzzle de PLANIFICATION (décider qui va la chercher). Le second est le jeu
que Volens propose — on compose une politique, on ne pilote pas des agents.

**Deux défauts trouvés en construisant le niveau, et le second est un piège
général.** La bascule posée à l'OUEST n'était jamais atteinte : à égalité toute
règle préfère le Nord puis l'Est (invariant 19), et la nuée dérivait du mauvais
côté. Posée à l'est, elle est franchie — mais six agents restaient piégés en
(9,4), une case d'où **aucun voisin ne rapproche de la lumière** : R01 s'y
abstient, et rien d'autre ne les en sortait.

> **Toute case dont tous les voisins accessibles éloignent de la lumière est un
> cul-de-sac pour R01.** Elle ne se voit pas sur le dessin — elle se voit en
> traçant la nuée. C'est le pendant, côté géométrie, de l'invariant n°14.

### 189. R07 et R10 retirées — « utile » veut dire UTILISÉE

Instruction du concepteur : « il faut que toutes les règles soient utiles à au
moins un endroit. Attention je suis clair sur le utile, ça veut dire UTILISÉ.
Si A,B fonctionne seul alors même si A,B,C fonctionne, le C ne compte pas. »

**Le critère est donc PORTEUSE, pas PRÉSENTE.** Une règle porte dans une pile
gagnante si, en la retirant, la pile cesse de gagner. Figurer dans une gagnante
ne prouve rien : on peut rallonger n'importe quelle solution avec n'importe
quelle règle inerte.

Mesure (`tools/design/rule_usefulness.gd`), sur les vingt-neuf niveaux :

| règle | offerte | **porteuse** |
|---|---|---|
| R01 Vers la lumière | 31 | 25 |
| R02 Fuir le danger | 8 | 4 |
| R03 Rester groupé | 20 | 3 |
| R04 S'écarter | 14 | 7 |
| R05 Suivre les voisins | 10 | 7 |
| R06 Longer le mur | 3 | 3 |
| **R07 Attendre** | **14** | **0** |
| R08 Marquer la piste | 5 | 3 |
| R09 Suivre la piste | 8 | 6 |
| **R10 Rebrousser si seul** | **0** | **0** |
| R11 Porter | 5 | 5 |
| R12 Déposer au but | 5 | 5 |
| R13 Boucher | 3 | 2 |
| R14 Disperser si dense | 7 | 3 |
| R15 Suivre le plus lent | 4 | 2 |
| R16 Ignorer | 4 | 4 |

**R07 était offerte dans quatorze niveaux et ne portait dans aucun.** Elle est
retirée, avec R10 dont le remède demandait l'hystérésis (gelée). Les quatorze
autres portent toutes quelque part.

Retirées du registre, du catalogue, de l'explication EF-05, des quinze
bibliothèques qui les offraient, et leurs implémentations supprimées. **Leurs
identifiants restent réservés** : ils figurent dans des fiches et dans ce
carnet, et les réattribuer rendrait ces traces mensongères.

**AUCUNE RECETTE D'OR NE LES RÉFÉRENÇAIT** — vérifié avant de commencer. Les
soixante-quatorze concordent toujours.

> **DIVERGENCE AU CDC, À ARBITRER.** Le CDC §7 annonce seize règles ; le jeu en
> compte quatorze. C'est une décision du concepteur, prise sur mesure, mais elle
> n'est pas reportée au CDC — je ne tranche pas les documents.

EQ-04 demandait « apparaître dans une solution gagnante de trois niveaux ». La
mesure montre que c'était trop faible : **apparaître n'est pas servir.** Le
critère est désormais figé par `tests/unit/test_every_rule_earns_its_place.gd`,
qui refuse toute règle qui ne porterait nulle part — la liste des manquements
connus d'EQ-04 est vide, et c'est le but qu'elle poursuivait.

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
| Recettes d'or | **30 recettes × 3 relevés = 90 empreintes**, 30/30 concordantes après la cérémonie ch1_03 | 10 août 2026 |
| Mode Épreuve — force brute / budget, par chapitre | 32/25 · 75/25 · 36/20 · 71/20 · 63/30 · 73/25 — **mord partout**, de 1,3× à 3,6× | 15 août 2026 |
| Mode Épreuve — ce que le tirage retire | **rien dans 24 niveaux sur 29** (bibliothèques de 3 à 4 règles) | 15 août 2026 |
| Niveaux à ensemble suffisant minimal UNIQUE | 25 sur 29 — le jeu porte sur l'ordre, pas sur la sélection | 15 août 2026 |
| Coupe de boucle du validateur | simulation statique tranchée en ~7 ticks au lieu de 300 | 4 août 2026 |
| Godot | 4.7.1-stable, standard (pas .NET), Linux x86_64 | 4 août 2026 |
| GUT | 9.6.1 | 4 août 2026 |
| CI GitHub Actions (premier passage en ligne) | vert | 5 août 2026 |
