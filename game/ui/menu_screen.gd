class_name MenuScreen
extends Control
## Menu principal : titre, Jouer / Continuer, Niveaux, Réglages, numéro de
## version. **Rien d'autre** — le périmètre est fermé (carnet, 6 août 2026).
##
## L'effacement de la progression est parti aux réglages. Sa place n'était
## pas ici : le menu sert à ENTRER dans le jeu, et il y offrait, à un geste
## du bouton « Jouer », la seule action irréversible de toute l'application.
##
## Aucun compteur culpabilisant, aucun badge d'appel (P2).

signal play_requested
signal select_requested
signal settings_requested

var _progress: Progress
var _session: Session

func setup(progress: Progress, session: Session) -> void:
	_progress = progress
	_session = session
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
	title.text = "VOLENS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiMetrics.font_size(96))
	title.add_theme_color_override("font_color", ViewPalette.AGENT_PLAIN)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "%d chapitres" % LevelCatalog.chapters().size()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", UiMetrics.font_size(28))
	subtitle.add_theme_color_override("font_color", Color(0.48, 0.53, 0.64))
	column.add_child(subtitle)

	column.add_child(_spacer(UiMetrics.GAP * 2))

	# « Continuer » quand une partie est en cours, « Jouer » sinon : un seul
	# bouton, jamais les deux — le menu ne pose pas de question inutile.
	var resuming: bool = _session != null and _session.is_valid()
	var primary := _make_button("Continuer" if resuming else "Jouer", 40)
	primary.pressed.connect(func() -> void: play_requested.emit())
	column.add_child(primary)

	var levels := _make_button("Niveaux", 32)
	levels.pressed.connect(func() -> void: select_requested.emit())
	column.add_child(levels)

	var settings := _make_button("Réglages", 32)
	settings.pressed.connect(func() -> void: settings_requested.emit())
	column.add_child(settings)

	column.add_child(_spacer(UiMetrics.GAP * 3))

	var version := Label.new()
	version.text = "version %s" % _version_string()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", UiMetrics.font_size(22))
	version.add_theme_color_override("font_color", Color(0.38, 0.42, 0.52))
	column.add_child(version)

func _make_button(text: String, font_size: int) -> Button:
	return UiButtons.make(text, UiButtons.Rank.PLAIN, font_size)

func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

## Numéro de build visible : le concepteur réinstalle souvent et doit savoir
## ce qui tourne sur le téléphone.
static func _version_string() -> String:
	var v: Variant = ProjectSettings.get_setting("application/config/version", "")
	return String(v) if String(v) != "" else "développement"
