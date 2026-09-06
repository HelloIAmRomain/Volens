# Environnement de développement

## Poste Ubuntu (orque) — développement et export

| Outil | Emplacement | Note |
|---|---|---|
| Godot 4.7.1-stable | `~/bin/godot` | version standard, pas .NET |
| JDK 17 (Temurin) | `~/opt/jdk17` | **jamais dans le PATH** — le `java` système reste en 21 |
| Android SDK | `~/Android/Sdk` | outils en ligne de commande seuls ; **pas besoin d'Android Studio** |
| Modèles d'export Godot | `~/.local/share/godot/export_templates/4.7.1.stable/` | 35 fichiers, dont `android_source.zip` |
| Clé de **débogage** | `~/.local/share/godot/keystores/debug.keystore` | ⚠ **ce n'est PAS la clé de release** |
| Clé de **release** *(T-006, 6 sept. 2026)* | `~/.local/share/volens/keystore/volens-release.keystore` | copie d'archive dans `~/Documents/Volens-cle-de-signature/` — voir §« Clé de signature » |

Pas de sudo : tout vit dans `$HOME`.

---

## Export Android — OPÉRATIONNEL depuis le 6 août 2026

**`targetSdk 36` est confirmé sur un APK réel.** Le modèle de compilation
Gradle de Godot 4.7.1 embarque `compileSdk: 36`, `targetSdk: 36`,
`javaVersion: 17`. Constaté sur l'artefact produit :

```
package: name='com.volensgame.volens' versionCode='1' versionName='0.1.0'
minSdkVersion:'33'   targetSdkVersion:'36'   compileSdkVersion='36'
aucune uses-permission · signé CN=Android Debug · 81 Mo
```

### La procédure hebdomadaire

```bash
cd ~/Documents/Volens
~/bin/godot --headless --path . --export-debug "Android" build/volens-debug.apk

export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
adb pair <ip>:<port>       # code affiché par le téléphone
adb connect <ip>:<port>    # Options développeur → Débogage sans fil
adb install -r build/volens-debug.apk
```

Le **premier** export lance une compilation Gradle qui télécharge ses propres
dépendances : plusieurs minutes. Les suivants sont rapides. **APK, jamais
AAB** — l'AAB ne sert qu'au magasin et ne s'installe pas directement.

### Décisions d'empaquetage, et pourquoi

- **arm64-v8a seule** — l'APK passe de 166 à 81 Mo. Le S23 est arm64 et
  l'APK se réinstalle chaque semaine par wifi. Pour l'AVD x86_64
  (vérifications Android 15/16), remettre `architectures/x86_64=true`.
- **`addons/gut/`, `tools/`, `tests/`, `docs/`, `reports/`, `*.lvl`, `*.md`
  exclus** — vérifié : l'APK ne contient aucun fichier de GUT. Les `.lvl`
  sont des sources d'écriture ; seuls les `.json` convertis embarquent.
- **Icône procédurale** (`game/ui/icon.png`, 1,1 ko, générée par script) :
  fond très sombre, nuée de points clairs, conforme à DA-02. Android exige
  une icône de lanceur — c'est un actif de plateforme, pas un visuel de jeu,
  donc DT-13 (« aucune texture pour le jeu lui-même ») reste respecté.
- **`reports/.gdignore`** — sans lui, Godot importe les CSV du validateur
  comme fichiers de traduction et pollue l'export.
- **`import_etc2_astc=true`** dans `project.godot` — exigé par l'export
  Android, qui échoue avant de commencer sans lui.
- **`android/.gdignore`** — **indispensable**. Sans lui, Godot importe les
  ressources du modèle Gradle et sème des `.import` dans `android/build/res/`,
  que Gradle refuse (« The file name must end with .xml or .png »). Le build
  échoue alors *après* plusieurs minutes de compilation. Si l'erreur
  réapparaît : `find android -name "*.import" -delete` puis recréer le
  `.gdignore`.

### Sur une machine neuve — les trois pièces hors dépôt

```bash
# 1. Clé de DÉBOGAGE (locale, sans réseau)
mkdir -p ~/.local/share/godot/keystores
~/opt/jdk17/bin/keytool -keyalg RSA -genkeypair -alias androiddebugkey \
  -keypass android -keystore ~/.local/share/godot/keystores/debug.keystore \
  -storepass android -dname "CN=Android Debug,O=Android,C=US" \
  -validity 9999 -deststoretype pkcs12

# 2. Modèle de compilation Gradle dans le projet
mkdir -p android/build
unzip -q ~/.local/share/godot/export_templates/4.7.1.stable/android_source.zip -d android/build
cp ~/.local/share/godot/export_templates/4.7.1.stable/version.txt android/.build_version

# 3. Preset d'export — une copie fidèle est versionnée
cp docs/export_presets.cfg.exemple export_presets.cfg
```

Le `export_presets.cfg` réel reste hors dépôt (il porte les chemins de
signature) ; l'exemple garantit qu'aucun réglage ne se perde — `min_sdk 33`,
`target_sdk 36`, `use_gradle_build`, la liste d'exclusions, l'absence de
permission.

### Chemins à déclarer dans Godot (non versionnés)

Paramètres de l'éditeur → Export → Android :

| Réglage | Valeur |
|---|---|
| Java SDK Path | `~/opt/jdk17` |
| Android SDK Path | `~/Android/Sdk` |
| Debug Keystore | `~/.local/share/godot/keystores/debug.keystore` |

*(Ces réglages vivent dans `~/.config/godot/editor_settings-4.7.tres` et ne
suivent pas le dépôt : à refaire sur chaque poste.)*

---

## Clé de signature de release — T-006, faite le 6 septembre 2026

**Une clé de signature perdue interdit DÉFINITIVEMENT toute mise à jour de
l'application.** Android identifie une application par son nom de paquet *et* sa
signature ; resignée avec une autre clé, c'est une autre application. Aucun
recours, aucun support à contacter. Tout ce qui suit découle de cette phrase.

| | |
|---|---|
| Copie de travail | `~/.local/share/volens/keystore/volens-release.keystore` |
| Copie d'archive | `~/Documents/Volens-cle-de-signature/` (avec son `LISEZ-MOI.md`) |
| Mot de passe | `~/.local/share/volens/keystore-password.txt`, permissions `600` |
| Alias | `volens` |
| Format | PKCS#12, RSA 2048 bits, signature SHA-384 |
| Validité | 10 950 jours — jusqu'en 2056 |
| Titulaire | `CN=Volens, O=Draille, C=FR` |
| Empreinte SHA-256 | `3B:42:1E:FE:77:BA:C8:80:E4:62:82:F7:16:4E:04:A6:82:24:D1:E8:E0:76:80:0C:06:03:99:F4:88:40:4E:30` |

L'empreinte est **publique** — elle figure dans chaque APK signé — et sert à
vérifier qu'un paquet vient bien de nous. Le mot de passe, lui, a été tiré
aléatoirement et n'a jamais été affiché.

> **DEUX CHOSES RESTENT À FAIRE À LA MAIN, et elles ne peuvent pas être
> automatisées :**
>
> 1. **Recopier le mot de passe dans un gestionnaire de mots de passe, puis
>    supprimer le fichier.** Un mot de passe en clair posé à côté de la clé
>    qu'il protège annule l'essentiel de son intérêt.
> 2. **Faire une troisième copie HORS MACHINE.** Les deux copies actuelles sont
>    sur le même disque : elles protègent de l'effacement accidentel, pas d'une
>    panne, d'un vol ou d'un incendie.

### Signer un export sans écrire un chemin personnel dans le dépôt

Godot lit la clé de release dans **trois variables d'environnement**. C'est la
voie retenue : `export_presets.cfg` n'est pas versionné, mais y inscrire le
chemin le figerait quand même sur ce poste, et le mot de passe s'y retrouverait
en clair.

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/.local/share/volens/keystore/volens-release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="volens"

# Le mot de passe se SAISIT, il ne se lit plus dans un fichier.
# `read -rs` n'affiche rien, ne laisse rien dans l'historique du shell, et ne
# passe pas par la ligne de commande (donc invisible dans `ps`).
read -rs -p "Mot de passe de la clé : " GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD; echo

godot --headless --path . --export-release "Android" build/volens-release.apk
```

> **POURQUOI PAS `$(cat …)` SUR LE FICHIER DE MOT DE PASSE.** C'était la
> première version de cette procédure, et elle se contredisait : elle dépendait
> d'un fichier que la consigne juste au-dessus demande d'effacer une fois le
> mot de passe rangé dans le gestionnaire. Une procédure qui suppose vivant ce
> qu'on vient de lui dire de supprimer ne marche qu'une fois — et elle marche
> précisément tant que la mesure de sécurité n'a PAS été appliquée.
>
> Tant que le fichier existe encore, `$(cat …)` fonctionne ; la saisie
> ci-dessus, elle, fonctionne dans les deux cas.

### Vérifier que le paquet produit porte bien CETTE clé

Le contrôle qui compte : l'empreinte lue **dans l'APK**, pas dans le trousseau.

```bash
~/Android/Sdk/build-tools/36.0.0/apksigner verify --print-certs build/volens-release.apk
```

Le `SHA-256 digest` du certificat doit être celui du tableau ci-dessus, aux
deux-points près.

### Ce que Play App Signing change, et ce qu'il ne change pas

DT-21 prévoit que **la clé d'upload définitive soit gérée par Play App
Signing** : Google détient alors la clé de signature de l'application, et cette
clé-ci sert d'une part aux APK de test distribués hors store, d'autre part
d'éventuelle clé d'upload. Cela réduit la portée d'une perte — Google peut
réinitialiser une clé d'upload — mais **seulement une fois l'application créée
dans la Play Console**. D'ici là, cette clé est la seule qui existe, et elle se
traite comme irremplaçable.

---

## Lancer le jeu sur le poste Ubuntu — sans APK

Le jeu tourne en fenêtre portrait sur le poste de développement : inutile
d'attendre l'appareil pour regarder les écrans.

```bash
# Le jeu, en fenêtre portrait 540x1200
~/bin/godot --path .

# Captures automatiques de chaque écran (13 images, se ferme seule).
# La taille est celle du RENDU, pas de la fenêtre : le harnais dessine dans
# un SubViewport, donc la capture ne dépend plus de la dalle du poste.
~/bin/godot --path . game/bench/screenshots.tscn -- --out=res://reports/screens --size=1080x2400

# Petit écran (~5,8") : MÊME largeur de base, hauteur plus courte.
~/bin/godot --path . game/bench/screenshots.tscn -- --out=res://reports/screens-petit --size=1080x1920
```

La base de rendu reste 1080x2400 ; seule la fenêtre est réduite, à ratio
identique (`window_width_override` dans `project.godot`).

> **Ne jamais simuler un petit écran en réduisant la largeur.** L'étirement
> `canvas_items` conserve la base de 1080 et n'ajuste que la hauteur : un
> rendu de 480 de large mesure une interface qui n'existe sur aucun appareil,
> et fait apparaître des débordements imaginaires. Le petit écran, ici, c'est
> **1080x1920** — un ratio plus court, pas une largeur plus faible.

**Ce qui exige vraiment l'appareil**, et rien d'autre : la lisibilité au
soleil et à luminosité minimale (DA-02), le temps de reprise réel (EF-20/21,
< 1,5 s) et la jouabilité à une main.

## Build de test (DT-22) — auto-vérification d'empreinte

Une **variante d'export**, pas une option : l'écran de diagnostic n'existe pas
dans le paquet de production.

```bash
# Build de test : embarque l'écran ET le corpus d'or
~/bin/godot --headless --path . --export-debug "Android (test)" build/volens-test.apk
```

Le préréglage `Android (test)` diffère de la production sur deux points, et
deux seulement : il déclare `custom_features="test_build"`, et son
`exclude_filter` n'exclut ni `tests/*` ni `game/selfcheck/*`. Modèle de
préréglage commenté dans `docs/export_presets.cfg.exemple`.

**Vérification OBLIGATOIRE après chaque export de production.** Elle porte
sur l'artefact, pas sur la configuration : aucun test de la suite ne peut la
remplacer, puisque `export_presets.cfg` est hors dépôt et qu'un test portant
sur un fichier non versionné n'est pas un test.

```bash
unzip -l build/volens-debug.apk | grep -c "selfcheck\|golden"   # doit valoir 0
```

Un résultat non nul signifie que le préréglage local a dérivé du modèle, et
qu'une build de production embarque l'écran de diagnostic.

Ce que le testeur fait : ouvrir Réglages → Auto-vérification, attendre la fin
du rejeu, et **recopier à la main** le verdict, le code court et la ligne de
contexte. Aucune transmission automatique — c'est la condition d'ENF-30.

## Poste Windows — vérifications de comportement Android

- Android Studio, AVD API 36, AVD petit écran (~5,8").
- JDK 17 et chemins à reconfigurer : les paramètres d'éditeur Godot ne sont
  pas versionnés.
- Sert aux comportements Android 15/16 (bord à bord, retour prédictif) que
  le S23 sous Android 13 ne peut pas montrer. **L'export lui-même se fait
  très bien depuis Ubuntu** — le poste Windows n'est pas nécessaire pour
  produire un APK.
