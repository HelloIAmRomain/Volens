# Environnement de développement

## Poste Ubuntu (orque) — travail headless
- Godot : `~/bin/godot` → lien vers `Godot_v4.7.1-stable_linux.x86_64` (version standard, pas .NET)
- JDK export Android : `~/opt/jdk17` (Temurin 17.0.20)
  → **jamais dans le PATH** (le `java` système reste en 21)
- Pas de sudo : tout vit dans `$HOME`
- Appareil en sans-fil : `adb pair` puis `adb connect`

## Chaîne d'export Android — état constaté le 6 août 2026

Quatre pièces manquent, pas une seule. Vérifié pièce par pièce :

| Pièce | État | Emplacement attendu |
|---|---|---|
| JDK 17 | ✅ **installé** | `~/opt/jdk17` |
| JDK **déclaré dans Godot** | ❌ `java_sdk_path` est **vide** | Paramètres de l'éditeur → Export → Android |
| Android SDK | ❌ **absent** (le chemin configuré n'existe pas) | `~/Android/Sdk` |
| Modèles d'export Godot | ❌ **absents** | `~/.local/share/godot/export_templates/` |
| Clé de signature de débogage | ❌ **absente** (chemin configuré, fichier inexistant) | `~/.local/share/godot/keystores/debug.keystore` |

### Procédure d'installation (à faire une fois)

```bash
# 1. Clé de débogage — locale, sans réseau
mkdir -p ~/.local/share/godot/keystores
~/opt/jdk17/bin/keytool -keyalg RSA -genkeypair -alias androiddebugkey \
  -keypass android -keystore ~/.local/share/godot/keystores/debug.keystore \
  -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12

# 2. Outils en ligne de commande Android + plateforme 36 + build-tools
#    (téléchargement ~1 Go ; tout reste dans $HOME, aucun sudo)
#    puis : sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"

# 3. Modèles d'export Godot 4.7.1 (~1 Go)
#    Éditeur → Projet → Installer les modèles d'export, OU dépôt manuel dans
#    ~/.local/share/godot/export_templates/4.7.1.stable/

# 4. Déclarer les chemins dans Godot : Paramètres de l'éditeur → Export → Android
#    Java SDK Path    = ~/opt/jdk17
#    Android SDK Path = ~/Android/Sdk
```

### `targetSdk 36` — ce qui est vérifié et ce qui ne l'est pas

Le binaire Godot 4.7.1 **expose bien** les options d'export
`gradle_build/min_sdk` et `gradle_build/target_sdk` : la valeur 36 est donc
saisissable. **Mais** ces options ne prennent effet qu'avec la **compilation
Gradle** (« Use Gradle Build ») — le modèle APK préfabriqué embarque son
propre `targetSdk`. Utiliser 36 impose donc :
le modèle de compilation Android installé, `platforms;android-36` et des
build-tools correspondants dans le SDK. **Non vérifiable tant que le SDK et
les modèles ne sont pas installés** — à reconfirmer à ce moment-là.

### Export d'un APK de débogage (à refaire à chaque build)

```bash
# export_presets.cfg est hors dépôt (gitignoré : il porte les chemins et
# mots de passe de signature). À recréer depuis l'éditeur, une fois :
#   Projet → Exporter → Ajouter → Android
#   · Gradle Build activé          · Orientation : portrait
#   · min_sdk 33, target_sdk 36    · Aucune permission cochée
#   · Renderer : gl_compatibility  · Clé de débogage : celle générée ci-dessus

godot --headless --path . --export-debug "Android" build/volens-debug.apk

adb pair <ip>:<port>        # code affiché sur le téléphone
adb connect <ip>:<port>
adb install -r build/volens-debug.apk
```

**APK, jamais AAB** : l'AAB ne sert qu'au magasin, il n'est pas installable
directement sur l'appareil.

## Poste Windows — export et déploiement
- Android Studio, AVD API 36, AVD petit écran (~5,8")
- JDK 17 et Java SDK Path à reconfigurer : les paramètres d'éditeur Godot ne sont pas
  versionnés, ils ne suivent pas le dépôt
