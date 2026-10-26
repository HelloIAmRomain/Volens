# Déclarations « Contenu de l'application » — Play Console

**Établi le 6 septembre 2026.** Ce document donne, pour chaque déclaration
exigée par la Play Console, **la réponse et le fait qui la justifie**. Il existe
parce qu'une déclaration recopiée sans sa raison devient invérifiable : le jour
où l'application change, plus personne ne sait laquelle est devenue fausse.

> **Chaque ligne « pourquoi » ci-dessous est vérifiable dans le dépôt.** Une
> déclaration dont le fondement a disparu doit être reprise **avant** la
> publication de la version concernée.

---

## 1. Sécurité des données

| Question | Réponse |
|---|---|
| Votre application collecte-t-elle ou partage-t-elle des types de données utilisateur ? | **Non** |
| Les données sont-elles chiffrées en transit ? | *sans objet* |
| Proposez-vous un moyen de demander la suppression des données ? | *sans objet* |

**POURQUOI, ET C'EST LE POINT LE PLUS FACILE À MAL RÉPONDRE.** Google définit
« collecter » comme **transmettre des données HORS de l'appareil**. Volens
enregistre bien trois fichiers — progression, réglages, session — mais dans le
stockage privé de l'application, sur l'appareil, et **rien ne les en fait
sortir**. Du stockage local n'est pas de la collecte au sens de ce formulaire.

Le fait qui rend la réponse solide : **l'application ne demande pas la
permission réseau**, donc Android lui interdit toute connexion, quoi que le code
tente. Vérifiable dans le paquet lui-même :

```bash
aapt2 dump permissions build/volens-release.apk
#  → android.permission.VIBRATE, et rien d'autre
```

## 2. Publicités

| Question | Réponse |
|---|---|
| Votre application contient-elle des annonces ? | **Non** |

**Pourquoi** : aucun kit publicitaire, aucun kit tiers d'aucune sorte. Le jeu ne
dépend d'aucune bibliothèque externe (exigence du dépôt, testée en intégration
continue).

## 2 bis. Identifiant publicitaire

| Question | Réponse |
|---|---|
| Votre appli utilise-t-elle un identifiant publicitaire ? *(y compris via un SDK importé)* | **Non** |

**LA QUESTION PORTE SUR LES SDK, PAS SUR VOS INTENTIONS**, et c'est pourquoi
elle se vérifie dans le paquet plutôt qu'en conscience — un SDK tiers peut
réclamer l'identifiant sans que personne l'ait décidé. Contrôlé sur l'APK de
release du 6 septembre 2026 :

```bash
aapt2 dump permissions build/volens-release.apk | grep -i AD_ID
#  → rien : la permission com.google.android.gms.permission.AD_ID est ABSENTE

unzip -l build/volens-release.apk | grep -icE "gms|admob|firebase|applovin|ironsource"
#  → 0
```

Le paquet ne contient que trois éléments de code : `classes.dex` (la couche
Java de Godot), `libc++_shared.so` et `libgodot_android.so`. **Ni Google Play
Services, ni Firebase, ni la moindre régie.**

**CE QUI REND LE « NON » OPPOSABLE PLUTÔT QUE DÉCLARATIF.** Depuis Android 13 —
et `targetSdk` vaut 36 — une application qui veut lire l'identifiant
publicitaire **doit** déclarer la permission `AD_ID`. Elle est absente : le
système ne le fournirait pas, même si le code le demandait. La réponse n'est
donc pas une promesse, elle est appliquée par la plateforme.

> **Google recoupe cette déclaration avec le manifeste du paquet envoyé.**
> Répondre « non » avec la permission `AD_ID` présente déclenche un signalement.
> Ici les deux concordent.

## 3. Classification du contenu (questionnaire IARC)

Le questionnaire est à remplir en ligne, mais la substance est connue :

| Thème | Réponse |
|---|---|
| Violence | aucune |
| Sexualité, nudité | aucune |
| Langage grossier | aucun |
| Substances contrôlées | aucune |
| Jeux d'argent, simulation de jeux d'argent | aucun |
| Contenu effrayant | aucun |
| Interaction entre utilisateurs, discussion | **aucune** — le jeu est hors ligne |
| Partage de position | aucun |
| Achats numériques | **oui**, si le déblocage est présent dans la version publiée |

**Le seul « oui » est celui des achats**, et seulement à partir du moment où
l'achat intégré existe réellement dans le paquet publié. Il n'est pas encore
implémenté.

## 4. Public cible et contenu

**C'EST LA SEULE DÉCLARATION QUI DEMANDE UNE VRAIE DÉCISION**, parce qu'elle a
des conséquences.

Inclure les moins de 13 ans fait entrer l'application dans le **programme
Familles** de Google Play, qui ajoute des exigences : contrôle du contenu
publicitaire, restrictions sur les SDK, revue plus stricte de la fiche.

- Volens satisfait déjà le fond de ces exigences — aucune publicité, aucun SDK,
  aucune collecte — donc **rien ne l'en écarte techniquement** ;
- mais cela ajoute une revue et des obligations à tenir sur la durée.

Un jeu de réflexion abstrait, sans texte lourd et sans contenu sensible, peut
raisonnablement viser un public large. **La décision revient au concepteur** :
ce document ne la prend pas.

## 5. Application gouvernementale · Finances · Santé

**Non** aux trois. Volens est un jeu.

## 6. Contenu généré par IA

| Question | Réponse |
|---|---|
| Votre application génère-t-elle du contenu par IA ? | **Non** |

**Attention au sens exact de la question** : elle porte sur ce que
l'**application** fait pour l'utilisateur — génération d'images, de texte, de
dialogue à l'exécution — et non sur les outils employés pour la développer.
Volens ne génère rien à l'exécution : sa simulation est déterministe, entière,
et sans le moindre tirage aléatoire.

**Transparence sur le développement.** Un assistant d'IA a été employé pendant
le développement pour aider à structurer le projet et à synthétiser les idées
du concepteur. Le code est vérifié par une suite de tests automatisés.
L'application livrée ne contient aucune fonctionnalité d'IA, ne
transmet rien à un service tiers et n'affiche aucun contenu produit à
l'exécution par un modèle : la réponse **Non** reste exacte. Si la console
formule un jour la question autrement — par exemple sur l'usage d'outils d'IA
pour produire des éléments livrés —, relire cette note avant de répondre.

## 7. Politique de confidentialité

**Une URL publique est obligatoire.** Le texte est écrit et versionné :

- français — `docs/legal/politique-de-confidentialite.md`
- anglais — `docs/legal/privacy-policy.md`

> **MISE À JOUR — la page en ligne a été retirée** (le dépôt `volens-legal` est supprimé). L'URL ci-dessous ne répond plus ; la politique doit être republiée avant la publication sur le Play Store. Le reste de cette section est l'historique de l'ancien hébergement.

**HÉBERGÉE ET EN LIGNE depuis le 6 septembre 2026 (retirée depuis) :**

    https://helloiamromain.github.io/volens-legal/

**L'URL À COLLER DANS LA PLAY CONSOLE, c'est celle-là.**

Le plan initial du DCT ne tenait pas : il prévoyait « hébergement gratuit
(GitHub Pages) » sans dire qu'il supposait un dépôt public, or celui du jeu est
**privé** et Pages y est payant. Retenu : un **second dépôt public**,
`volens-legal`, qui ne contient **que** `index.html` — ni code, ni fiches de
niveau, ni historique. Le dépôt du jeu reste privé.

Vérifié sur la page réellement servie, pas sur le fichier source : HTTP 200,
l'adresse de contact présente, **zéro ressource externe chargée**, un seul lien
sortant — celui, obligatoire, vers la politique de Google. Discussions, wiki et
projets désactivés sur le dépôt vitrine.

## 8. Coordonnées — ce qui devient public, et ce qui ne l'est pas

**Vérifié le 6 septembre 2026** à la page « Contact information requirements for
developer accounts » de l'aide Play Console, plutôt que supposé.

| Donnée | Sort |
|---|---|
| **Adresse e-mail de développeur** | **PUBLIQUE** — affichée sur le profil développeur de la fiche Play. Obligatoire |
| Numéro de téléphone | public **pour les comptes ORGANISATION uniquement**. Le compte de Volens est un compte personnel |
| Nom légal, adresse légale, e-mail et téléphone de contact | collectés par Google, **non indiqués comme affichés publiquement** |

**CONSÉQUENCE PRATIQUE, ET ELLE LÈVE L'INQUIÉTUDE : l'adresse publique
obligatoire est une adresse e-mail, et rien n'oblige à ce que ce soit une
adresse personnelle.** Une boîte dédiée, créée pour le jeu et ne servant qu'à
cela, satisfait l'exigence sans exposer quoi que ce soit de privé. C'est la
pratique courante, et elle a un second mérite : le jour où le projet change de
mains ou de nom, l'adresse suit le jeu et non la personne.

Le **nom** affiché publiquement est celui du développeur — **Draille** — déjà
choisi et figé au contexte du dépôt. Ce n'est pas un nom civil.

Cette même adresse dédiée sert alors aux deux endroits : le profil développeur
et le contact de la politique de confidentialité. Le marqueur
`CONTACT_À_COMPLÉTER` des deux fichiers de politique attend cette décision.

> **UN POINT RESTE OUVERT, ET IL NE SE POSE PAS ENCORE.** Le règlement européen
> sur les services numériques (DSA) impose aux « professionnels » — quiconque
> vend, y compris par achat intégré — de publier des coordonnées de contact plus
> complètes. Volens ne vend rien aujourd'hui : l'achat intégré n'est pas
> implémenté, et la publication visée est un test fermé gratuit. **La question
> se posera à l'activation de l'achat (J4/J5) et devra être revérifiée à ce
> moment-là** — elle n'a pas été tranchée ici, faute de source qui l'établisse
> clairement, et il vaut mieux le dire que le supposer.
