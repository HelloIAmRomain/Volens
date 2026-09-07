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

## 7. Politique de confidentialité

**Une URL publique est obligatoire.** Le texte est écrit et versionné :

- français — `docs/legal/politique-de-confidentialite.md`
- anglais — `docs/legal/privacy-policy.md`

**Il reste à l'héberger, et le plan initial ne tient pas.** Le DCT prévoyait
« hébergement gratuit (GitHub Pages) », mais **le dépôt est privé** et GitHub
Pages sur un dépôt privé est une fonctionnalité payante. Trois issues, par ordre
de préférence :

| Issue | Coût | Remarque |
|---|---|---|
| **Un second dépôt PUBLIC ne contenant que les pages légales** | gratuit | n'expose pas le code du jeu ; l'URL est stable et propre |
| Rendre public le dépôt du jeu | gratuit | expose tout le code et l'historique — décision de fond, pas d'hébergement |
| Nom de domaine propre | payant | envisagé au CDC §17 avec le devlog |

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
