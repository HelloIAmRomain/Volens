# Environnement de développement

## Poste Ubuntu (orque) — développement et export

| Outil | Emplacement | Note |
|---|---|---|
| Godot 4.7.1-stable | `~/bin/godot` | version standard, pas .NET |
| JDK 17 (Temurin) | `~/opt/jdk17` | **jamais dans le PATH** — le `java` système reste en 21 |
| Android SDK | `~/Android/Sdk` | outils en ligne de commande seuls ; **pas besoin d'Android Studio** |
| Modèles d'export Godot | `~/.local/share/godot/export_templates/4.7.1.stable/` | 35 fichiers, dont `android_source.zip` |
| Clé de **débogage** | `~/.local/share/godot/keystores/debug.keystore` | ⚠ **ce n'est PAS la clé de release de T-006** |

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

## Poste Windows — vérifications de comportement Android

- Android Studio, AVD API 36, AVD petit écran (~5,8").
- JDK 17 et chemins à reconfigurer : les paramètres d'éditeur Godot ne sont
  pas versionnés.
- Sert aux comportements Android 15/16 (bord à bord, retour prédictif) que
  le S23 sous Android 13 ne peut pas montrer. **L'export lui-même se fait
  très bien depuis Ubuntu** — le poste Windows n'est pas nécessaire pour
  produire un APK.
