# La page publique — ce qu'elle est, et comment elle est publiée

`index.html` est la **source de vérité** de la politique de confidentialité
publiée. Les fichiers `.md` du dossier parent en sont la version lisible dans le
dépôt ; c'est cette page-ci qui est mise en ligne.

## Pourquoi elle vit ici et pas dans le dépôt public

Le dépôt du jeu est **privé, et le reste** — décision du 6 septembre 2026, pour
trois raisons mesurées : 185 des 222 commits portent une adresse professionnelle,
les piles gagnantes de tous les niveaux figurent en clair dans les fiches de
conception, et le déblocage payant sera local donc contournable à la lecture du
code.

Le dépôt public ne reçoit donc **qu'une copie de cette page**. Il ne contient ni
code, ni fiches, ni historique. La source reste ici, versionnée avec le reste du
projet : on modifie ici, on republie là-bas.

> **MISE À JOUR — page retirée :** le dépôt `volens-legal` a été supprimé et l'URL ci-dessous ne répond plus. Cette procédure reste valable pour republier la page (ici ou ailleurs) ; la source `index.html` est conservée dans ce dossier.

## EN LIGNE depuis le 6 septembre 2026 (retirée depuis)

    https://helloiamromain.github.io/volens-legal/

Dépôt vitrine `HelloIAmRomain/volens-legal`, public, contenant **un seul
fichier**. Discussions, wiki et projets désactivés. Le commit est signé de
l'adresse GitHub anonyme, pas de l'adresse professionnelle.

## Republier après modification

Les étapes 1, 3 et 4 sont faites une fois pour toutes ; seule l'étape 2 se
rejoue à chaque modification de la page.

```bash
# 1. Créer le dépôt vitrine — FAIT.
gh repo create volens-legal --public \
    --description "Politique de confidentialité de Volens"

# 2. Copier la page et pousser — à REJOUER à chaque modification.
tmp=$(mktemp -d) && git -C "$tmp" clone "git@github.com:$(gh api user -q .login)/volens-legal.git" .
cp docs/legal/site/index.html "$tmp/index.html"
cd "$tmp"
#    L'IDENTITÉ EST FIXÉE LOCALEMENT, sinon le commit part sous l'adresse
#    professionnelle de la configuration globale — sur un dépôt PUBLIC.
git config --local user.email "39194295+HelloIAmRomain@users.noreply.github.com"
git add index.html && git commit -m "Politique de confidentialité de Volens" && git push

# 3. Verrouiller ce qui peut l'être — FAIT.
gh repo edit --enable-issues=false --enable-wiki=false --enable-projects=false

# 4. Activer GitHub Pages sur la racine de la branche par défaut — FAIT.
gh api -X POST "repos/$(gh api user -q .login)/volens-legal/pages" \
    -f "source[branch]=main" -f "source[path]=/"
```

**Le contrôle qui compte se fait sur la page SERVIE, pas sur le fichier
source** — c'est la même règle que pour les permissions de l'APK :

```bash
curl -s https://helloiamromain.github.io/volens-legal/ \
  | grep -cE '<(script src|link rel="stylesheet"|img|iframe)'
#  → doit rendre 0
```

Compter deux à trois minutes entre le `push` et la mise en ligne : GitHub
reconstruit le site, et l'URL rend 404 en attendant.

## Ce qui ne peut PAS être verrouillé, et il faut le savoir

**Un dépôt public est toujours forkable.** GitHub ne permet de l'interdire que
sur les comptes d'organisation avec une règle dédiée. Ce n'est pas grave ici :
le dépôt ne contient qu'une page HTML publique par destination. Il n'y a rien à
protéger — c'est précisément pourquoi on n'y met rien d'autre.

## Contraintes à ne pas oublier

- **L'URL doit rester accessible tant que l'application est publiée.** Si la
  page disparaît, Google peut suspendre la fiche. Ce n'est pas une formalité de
  lancement.
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
