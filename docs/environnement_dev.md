# Environnement de développement

## Poste Ubuntu (orque) — travail headless
- Godot : `~/bin/godot` → lien vers `Godot_v4.7.1-stable_linux.x86_64` (version standard, pas .NET)
- JDK export Android : `~/opt/jdk17` (Temurin 17.0.20)
  → déclaré uniquement dans Godot, **jamais dans le PATH** (le `java` système reste en 21)
  → à recoller dans Éditeur → Paramètres de l'éditeur → Export → Android → Java SDK Path
- Android SDK : à installer (semaine 9)
- Pas de sudo : tout vit dans `$HOME`
- Appareil en sans-fil : `adb pair` puis `adb connect`

## Poste Windows — export et déploiement
- Android Studio, AVD API 36, AVD petit écran (~5,8")
- JDK 17 et Java SDK Path à reconfigurer : les paramètres d'éditeur Godot ne sont pas
  versionnés, ils ne suivent pas le dépôt
