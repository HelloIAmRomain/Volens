# `game/selfcheck/` — n'existe pas en production

Ce dossier contient **DT-22**, l'écran d'auto-vérification d'empreinte, et il
est **exclu de l'export de production**.

## Ce n'est pas un masquage, c'est une variante de build

Un écran caché derrière un geste secret finirait par être trouvé par un
testeur, et un écran de diagnostic dans un jeu qui se veut épuré est un défaut,
pas une fonctionnalité discrète. La garantie est donc structurelle : **les
fichiers ne sont pas dans le paquet**.

Trois verrous, dont deux mécaniques :

1. **`exclude_filter` de la préréglage de production** exclut `game/selfcheck/*`
   — les fichiers ne sont pas exportés ;
2. **`tests/*` est exclu aussi**, donc `golden.json` non plus : même en
   recompilant l'écran, il n'aurait rien à vérifier en production ;
3. **aucun fichier hors de ce dossier ne nomme `SelfCheckScreen`** autrement
   que par chargement dynamique gardé par le drapeau `test_build` — vérifié par
   `tests/arch/test_selfcheck_isolation.gd`.

## Composer une build de test

Le préréglage `Android (test)` diffère de la production sur deux points :

```
custom_features="test_build"
exclude_filter="reports/*, docs/*, tools/*, addons/gut/*, *.lvl, *.md"
```

C'est-à-dire : `tests/*` **n'est pas** exclu (le corpus d'or doit être
embarqué), `game/selfcheck/*` non plus, et le drapeau `test_build` est déclaré.

```bash
~/bin/godot --headless --path . --export-debug "Android (test)" build/volens-test.apk
```

L'entrée se trouve alors dans l'écran de réglages. En production, le bouton
n'est pas construit : `OS.has_feature("test_build")` est faux et la classe
n'existe pas dans le paquet.

## Ce que le testeur fait

Il ouvre l'écran, attend la fin du rejeu, et **recopie à la main** trois
lignes : le verdict, le code court, et la ligne de contexte (modèle,
architecture, version d'Android).

**Aucune transmission automatique** — c'est la condition d'ENF-30, et c'est
elle qui a fait retenir ce dispositif plutôt qu'une télémétrie.
