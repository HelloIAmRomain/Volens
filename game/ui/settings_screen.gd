class_name SettingsScreen
extends Control
## Réglages — **un seul réglage pour l'instant**, et c'est délibéré.
##
## POURQUOI CET ÉCRAN EXISTE MAINTENANT. Le retour haptique était implémenté,
## persistant, et **impossible à couper depuis le jeu**. Livrer une vibration
## qu'un testeur ne peut pas arrêter n'est pas une fonctionnalité incomplète :
## c'est un défaut. ENF-24 exige « présent mais désactivable » — la seconde
## moitié n'était pas rendue.
##
## L'autre issue était de désactiver l'haptique par défaut jusqu'à ce qu'un
## écran existe. Écartée : elle prive les testeurs de la seule chose qu'on
## veut leur faire juger. On rend donc le réglage, pas le silence.
##
## Il porte aussi l'effacement de la progression, arrivé du menu : c'est la
## seule action irréversible du jeu, et elle n'avait rien à faire à un geste
## du bouton « Jouer ». Les réglages sont l'endroit où l'on va délibérément.
##
## RIEN D'AUTRE N'ENTRE ICI sans demande explicite. Le mouvement réduit
## (ENF-23) est déjà porté par `Settings` et honoré par les shaders, mais il
## n'est pas exposé : un écran de réglages qui grossit tout seul est la porte
## d'entrée habituelle du sentiment de configuration obligatoire (P2).

signal back_requested
signal reset_requested
signal self_check_requested

## Chemin de l'écran DT-22, chargé dynamiquement : en production le fichier
## n'est pas dans le paquet, et une référence statique empêcherait le
## démarrage.
const SELF_CHECK_PATH := "res://game/selfcheck/self_check_screen.gd"

var _settings: Settings
var _toggle: Button
var _reset_button: Button
var _confirming_reset: bool = false

func setup(settings: Settings) -> void:
	_settings = settings
	_build()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE, int(UiMetrics.MARGIN))

	var title := Label.new()
	title.text = "Réglages"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
	column.add_child(title)

	column.add_child(_spacer(UiMetrics.GAP * 2))

	_toggle = UiButtons.make("", UiButtons.Rank.PLAIN, 32)
	_toggle.pressed.connect(_on_toggle)
	column.add_child(_toggle)

	column.add_child(_spacer(UiMetrics.GAP * 3))

	# L'effacement vient du menu, où il était à un geste du bouton « Jouer ».
	# Il est ici parce que c'est la seule action irréversible du jeu, et que
	# les réglages sont l'endroit où l'on va délibérément.
	_reset_button = UiButtons.make("", UiButtons.Rank.PLAIN, 26)
	_reset_button.add_theme_color_override("font_color", Color(0.72, 0.45, 0.45))
	_reset_button.pressed.connect(_on_reset_pressed)
	column.add_child(_reset_button)

	column.add_child(_spacer(UiMetrics.GAP * 2))

	# DT-22 — n'existe QUE dans une build de test. Le drapeau `test_build` est
	# déclaré par le préréglage d'export correspondant ; en production il est
	# faux ET les fichiers sont absents du paquet, d'où le chargement
	# dynamique : nommer la classe statiquement empêcherait la build de
	# production de démarrer.
	if OS.has_feature("test_build") and ResourceLoader.exists(SELF_CHECK_PATH):
		var check := UiButtons.make("Auto-vérification", UiButtons.Rank.PLAIN, 26)
		check.pressed.connect(_on_self_check)
		column.add_child(check)
		column.add_child(_spacer(UiMetrics.GAP))

	var back := UiButtons.make("Retour")
	back.pressed.connect(func() -> void: back_requested.emit())
	column.add_child(back)

	_refresh()

func _on_toggle() -> void:
	_settings.set_haptics(not _settings.haptics)
	_refresh()
	# Le réglage se PROUVE au doigt : allumer déclenche une impulsion,
	# éteindre n'en déclenche aucune. C'est la seule façon de vérifier un
	# retour haptique sans notice.
	if _settings.haptics:
		Haptics.select()

## Deux appuis pour effacer : le premier avertit, le second exécute. Pas de
## fenêtre modale (P3), pas de perte accidentelle non plus.
func _on_reset_pressed() -> void:
	if not _confirming_reset:
		_confirming_reset = true
		_reset_button.text = "Confirmer l'effacement"
		_reset_button.add_theme_color_override("font_color", Color(0.95, 0.40, 0.40))
		return
	reset_requested.emit()

func _on_self_check() -> void:
	self_check_requested.emit()

func _refresh() -> void:
	if _toggle == null:
		return
	if _reset_button != null and not _confirming_reset:
		_reset_button.text = "Effacer la progression"
	# L'état se lit dans le TEXTE, pas dans une nuance de fond : ENF-20
	# interdit qu'une information tienne à la seule couleur.
	_toggle.text = "Vibrations : activées" if _settings.haptics else "Vibrations : coupées"
	_toggle.add_theme_color_override("font_color",
		ViewPalette.AGENT_PLAIN if _settings.haptics else Color(0.55, 0.59, 0.68))

func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
