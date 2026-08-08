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
## RIEN D'AUTRE N'ENTRE ICI sans demande explicite. Le mouvement réduit
## (ENF-23) est déjà porté par `Settings` et honoré par les shaders, mais il
## n'est pas exposé : un écran de réglages qui grossit tout seul est la porte
## d'entrée habituelle du sentiment de configuration obligatoire (P2).

signal back_requested

var _settings: Settings
var _toggle: Button

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

	_toggle = Button.new()
	_toggle.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	_toggle.add_theme_font_size_override("font_size", 32)
	_toggle.pressed.connect(_on_toggle)
	column.add_child(_toggle)

	var note := Label.new()
	note.text = "Une vibration brève confirme les gestes de composition\net les sorties d'agents. Aucune information n'en dépend."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 22)
	note.add_theme_color_override("font_color", Color(0.48, 0.53, 0.64))
	column.add_child(note)

	column.add_child(_spacer(UiMetrics.GAP * 3))

	var back := Button.new()
	back.text = "Retour"
	back.custom_minimum_size = Vector2(UiMetrics.MIN_TOUCH_TARGET, UiMetrics.MIN_TOUCH_TARGET)
	back.add_theme_font_size_override("font_size", 30)
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

func _refresh() -> void:
	if _toggle == null:
		return
	# L'état se lit dans le TEXTE, pas dans une nuance de fond : ENF-20
	# interdit qu'une information tienne à la seule couleur.
	_toggle.text = "Vibrations : activées" if _settings.haptics else "Vibrations : coupées"
	_toggle.add_theme_color_override("font_color",
		ViewPalette.AGENT_PLAIN if _settings.haptics else Color(0.55, 0.59, 0.68))

func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
