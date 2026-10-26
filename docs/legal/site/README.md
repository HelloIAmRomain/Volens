# La page publique — ce qu'elle est, et comment elle est publiée

`index.html` est la **source de vérité** de la politique de confidentialité
publiée. Les fichiers `.md` du dossier parent en sont la version lisible dans le
dépôt ; c'est cette page-ci qui est mise en ligne.

## En ligne

    https://helloiamromain.github.io/Volens/

C'est l'URL à déclarer dans la Play Console. Elle est servie par **GitHub Pages
depuis ce dépôt**, par le workflow `.github/workflows/pages.yml`. Seul le dossier
`docs/legal/site/` est publié : ni le code, ni le reste de `docs/`.

*Historique.* Jusqu'au 26 octobre 2026, la page vivait dans un second dépôt
public, `volens-legal`, parce que le dépôt du jeu était alors privé (Pages y est
payant). Le dépôt du jeu étant devenu public, ce second dépôt n'avait plus de
raison d'être ; il a été supprimé et l'ancienne URL ne répond plus.

## Republier après modification

Modifier `docs/legal/site/index.html`, puis fusionner dans `main` : le workflow
se déclenche tout seul sur tout changement de ce dossier. Pour forcer une
republication sans modification :

```bash
gh workflow run pages.yml
```

**Le contrôle qui compte se fait sur la page SERVIE, pas sur le fichier
source** — c'est la même règle que pour les permissions de l'APK :

```bash
curl -s https://helloiamromain.github.io/Volens/ \
  | grep -cE '<(script src|link rel="stylesheet"|img|iframe)'
#  → doit rendre 0
```

Le workflow refuse déjà de publier une page qui contiendrait une telle
ressource. Compter une à deux minutes entre la fusion et la mise en ligne.

## Contraintes à ne pas oublier

- **L'URL doit rester accessible tant que l'application est publiée.** Si la
  page disparaît, Google peut suspendre la fiche. Ce n'est pas une formalité de
  lancement. Ne pas renommer le dépôt ni désactiver Pages sans republier ailleurs
  et mettre à jour la Play Console.
- **La date en tête de page** se met à jour à chaque modification de fond, et la
  page se republie **avant** la version d'application concernée.
- **Aucune ressource externe** ne doit être ajoutée à cette page : ni police
  distante, ni script d'analyse, ni image hébergée ailleurs. Une politique de
  confidentialité qui transmettrait l'adresse IP du lecteur à un tiers pour lui
  expliquer qu'on ne collecte rien se contredirait à la première ligne. Le
  contrôle tient en une commande :

  ```bash
  grep -cE '<(script src|link rel="stylesheet"|img|iframe)' docs/legal/site/index.html
  #  → doit rendre 0
  ```
