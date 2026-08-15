class_name SummaryScreen
extends Control
## Écran de bilan [EF-07] : ce qui s'est passé, pourquoi, et une reprise en
## un geste. **Aucune incitation à enchaîner** (P2) : deux boutons de même
## poids visuel, aucun texte qui pousse à continuer.

signal retry_requested
signal select_requested
signal next_level_requested(level_id: String)

func setup(level_id: String, won: bool, ticks: int, lost: int, stack: Array, reason: String = "") -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Liseré d'état : reconnaissable en une demi-seconde, sans lire (DA-03).
	var banner := ColorRect.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.color = Color(0.16, 0.92, 0.62, 0.09) if won else Color(0.90, 0.16, 0.22, 0.09)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE, int(UiMetrics.MARGIN))

	var verdict := Label.new()
	verdict.text = "Objectif atteint" if won else "Objectif manqué"
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict.add_theme_font_size_override("font_size", UiMetrics.font_size(52))
	verdict.add_theme_color_override("font_color", ViewPalette.EXIT if won else ViewPalette.DANGER)
	column.add_child(verdict)

	var why := Label.new()
	why.text = reason if not reason.is_empty() else _reason(won, lost)
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.add_theme_font_size_override("font_size", UiMetrics.font_size(28))
	why.add_theme_color_override("font_color", Color(0.78, 0.83, 0.93))
	column.add_child(why)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, UiMetrics.GAP)
	column.add_child(spacer)

	column.add_child(_stat("Ticks consommés", str(ticks)))
	column.add_child(_stat("Agents perdus", str(lost)))
	column.add_child(_stat("Pile utilisée", _stack_label(stack)))

	# CDC §8.5 : le bilan d'un niveau OUVERT annonce le nombre de solutions
	# connues — « il n'y a pas UNE bonne réponse » (P5). Le chiffre vient du
	# validateur, jamais d'une estimation : c'est `expected_wins`, confronté à
	# la simulation par `tests/unit/test_design_sheets.gd`.
	#
	# Sur un niveau TUTORIEL, on se tait : ces niveaux n'ont qu'une leçon et
	# souvent qu'une réponse ; annoncer « 1 solution connue » suggérerait qu'on
	# en cherche d'autres.
	var known := _known_solutions(level_id)
	if won and known > 1:
		column.add_child(_stat("Solutions connues", str(known)))

	# DÉFIS RG-18 — et RG-19 gouverne leur affichage autant que leur calcul :
	# **aucun défi ne conditionne jamais la progression.** On ne montre donc que
	# ce qui est OBTENU, et rien du reste. Une liste de cases à cocher dont deux
	# sont vides transforme une victoire en échec partiel, et c'est exactement ce
	# que RG-19 interdit ; le joueur qui veut savoir ce qui existe le découvre en
	# rejouant, pas en lisant un reproche.
	#
	# Rien non plus sur un échec : féliciter pour un défi obtenu au cours d'une
	# partie perdue serait au mieux confus.
	if won:
		for line in challenges_earned(level_id, stack, ticks):
			column.add_child(_stat("Défi", line))

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grow)

	# « Niveau suivant » n'apparaît QUE sur une victoire, et seulement s'il
	# existe un niveau après celui-ci. Sur un échec, proposer d'avancer serait
	# absurde — et le niveau suivant est de toute façon verrouillé.
	#
	# P2 tient malgré tout : le bouton a le MÊME poids visuel que les autres,
	# et aucun texte ne pousse à enchaîner. On rend le geste disponible, on ne
	# le sollicite pas.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	column.add_child(row)
	row.add_child(_make_button("Rejouer", func() -> void: retry_requested.emit()))
	var next_id := LevelCatalog.level_after(level_id)
	if won and not next_id.is_empty():
		row.add_child(_make_button("Niveau suivant",
			func() -> void: next_level_requested.emit(next_id)))
	row.add_child(_make_button("Niveaux", func() -> void: select_requested.emit()))

## Nombre de piles gagnantes d'un niveau non tutoriel, ou 0 si le niveau est
## un tutoriel ou si le chiffre n'est pas connu.
## Libellés des défis obtenus, dans l'ordre de RG-18. Vide si aucun.
## Publique : `App` l'appelle pour ENREGISTRER les défis, l'écran pour les
## AFFICHER. Une seconde implémentation du calcul divergerait de la première —
## le joueur verrait un défi qui ne se conserve pas, ou l'inverse.
static func challenges_earned(level_id: String, stack: Array, ticks: int) -> PackedStringArray:
	var data := LevelCatalog.load_level_data(level_id)
	var spec := LevelSpec.challenges(data)
	var out := PackedStringArray()
	if data.is_empty():
		return out
	var used := 0
	for r in stack:
		if int(r) != RuleRegistry.EMPTY:
			used += 1
	if used <= Challenges.ECONOMY_MAX_SLOTS:
		out.append("Économie — résolu avec %d règles" % used)
	var abstinence := int(spec.get("abstinence_rule", 0))
	if abstinence != 0 and not stack.has(abstinence):
		out.append("Abstinence — sans « %s »" % RuleCatalog.name_of(abstinence))
	var deadline := int(spec.get("efficiency_ticks", 0))
	if deadline > 0 and ticks <= deadline:
		out.append("Efficience — %d ticks, seuil %d" % [ticks, deadline])
	return out

static func _known_solutions(level_id: String) -> int:
	var data := LevelCatalog.load_level_data(level_id)
	if data.is_empty() or LevelSpec.is_tutorial(data):
		return 0
	return maxi(LevelSpec.expected_wins(data), 0)

func _reason(won: bool, lost: int) -> String:
	if won:
		return "La nuée a rempli l'objectif." if lost == 0 else "Objectif rempli, malgré des pertes."
	if lost > 0:
		return "Trop d'agents perdus : l'objectif est devenu hors d'atteinte."
	return "Le temps imparti s'est écoulé avant l'objectif."

## UNE LIGNE DE BILAN NE POUSSE JAMAIS L'ECRAN.
##
## Un Label non contraint prend pour largeur MINIMALE celle de son texte
## entier : « Defi : Efficience — 29 ticks, seuil 29 » debordait de trente-sept
## pixels sur un ecran de 720 des que l'echelle typographique est passee a 1,35.
## Les deux libelles se raccourcissent donc par ellipse, et le libelle de gauche
## cede la place au chiffre — c'est lui qui porte l'information.
func _stat(label: String, value: String) -> Control:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_stretch_ratio = 0.6
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 0
	l.add_theme_font_size_override("font_size", UiMetrics.font_size(26))
	l.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	row.add_child(l)
	var v := Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 1.4
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.clip_text = true
	v.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.custom_minimum_size.x = 0
	v.add_theme_font_size_override("font_size", UiMetrics.font_size(26))
	v.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	row.add_child(v)
	return row

func _make_button(text: String, action: Callable) -> Button:
	var b := UiButtons.make(text, UiButtons.Rank.PLAIN, 32)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Trois boutons cote a cote sur un ecran etroit : ils se partagent la largeur
	# et raccourcissent leur texte, plutot que d'en pousser un hors de l'ecran.
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.custom_minimum_size.x = 0
	b.pressed.connect(action)
	return b

static func _stack_label(stack: Array) -> String:
	if stack.is_empty():
		return "vide"
	var parts := PackedStringArray()
	for rule_id in stack:
		parts.append(RuleCatalog.name_of(int(rule_id)))
	return " > ".join(parts)
