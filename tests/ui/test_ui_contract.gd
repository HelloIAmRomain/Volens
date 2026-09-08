extends GutTest

## CE FICHIER VÉRIFIE DU TEXTE FRANÇAIS : IL FIXE DONC LA LANGUE (carnet, 211).
## Ce qui est éprouvé ici est le CONTENU, pas la langue — la parité des deux
## langues a son propre fichier, `test_traductions.gd`.
var _locale_avant := ""

func before_all() -> void:
	_locale_avant = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")

func after_all() -> void:
	TranslationServer.set_locale(_locale_avant)
## Contrat de l'écran de jeu : cibles tactiles, composition de la pile par
## les DEUX chemins, et discrimination des gestes.
##
## Ces tests existent parce qu'une cible trop petite ou un geste ambigu ne se
## voient pas sur un écran d'ordinateur — ils se découvrent dans le bus, une
## main occupée.

const LEVEL_PATH := "res://data/levels/ch1_02.json"

var _screen: GameScreen

func before_each() -> void:
	var level: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEVEL_PATH))
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_screen = GameScreen.new()
	add_child_autofree(_screen)
	_screen.load_level(level, RuleParams.from_dict(rules), "ch1_02")

## Chemin sans glissement, en deux gestes : c'est le chemin PRINCIPAL.
func _pick_then_place(rule_id: int, slot: int) -> void:
	_screen._on_chip_tapped(rule_id)
	_screen._on_slot_tapped(slot)

func _collect(node: Node, wanted: String, out: Array) -> void:
	for child in node.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == wanted:
			out.append(child)
		_collect(child, wanted, out)

# --- ENF-01 : cibles tactiles ---------------------------------------------

func test_every_touch_target_meets_the_minimum_size() -> void:
	var controls: Array = []
	_all_targets(_screen, controls)
	assert_gt(controls.size(), 0)
	for c in controls:
		var target: Control = c
		assert_gte(target.custom_minimum_size.x, UiMetrics.MIN_TOUCH_TARGET,
			"%s : largeur sous le minimum ENF-01" % target.get_class())
		assert_gte(target.custom_minimum_size.y, UiMetrics.MIN_TOUCH_TARGET,
			"%s : hauteur sous le minimum ENF-01" % target.get_class())

func _all_targets(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			if (c is Button or c is RuleSlot or c is RuleChip) and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				out.append(c)
		_all_targets(child, out)

func test_the_stack_has_exactly_four_slots() -> void:
	var slots: Array = []
	_collect(_screen, "RuleSlot", slots)
	assert_eq(slots.size(), UiMetrics.SLOT_COUNT, "RG-05 : quatre emplacements, ni plus ni moins")

# --- le chemin sans glissement, dans ses quatre usages --------------------

func test_pick_then_place_puts_a_rule_in_a_slot() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	assert_eq(_screen._stack[0], RuleRegistry.R01_TOWARD_LIGHT)
	assert_eq(_screen._compact_stack(), [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])

func test_pick_then_place_swaps_two_occupied_slots() -> void:
	# L'ÉCHANGE est l'action la plus fréquente après poser : tout le jeu
	# tient à l'ordre de la pile.
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)

	_screen._on_slot_tapped(0)   # sélectionne la règle de l'emplacement 0
	_screen._on_slot_tapped(1)   # la destine à l'emplacement 1 -> échange

	assert_eq(_screen._stack[0], RuleRegistry.R02_FLEE_DANGER)
	assert_eq(_screen._stack[1], RuleRegistry.R01_TOWARD_LIGHT)

func test_the_stack_is_always_compact() -> void:
	# Un trou dans la pile n'a aucun sens : seule compte la position
	# RELATIVE — [_, A, B] se comporte exactement comme [A, B]. Sans
	# compaction, le joueur croirait que la position absolue compte.
	# Le rang visé est le dernier OUVERT du niveau : ch1_02 en déclare deux.
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 1)

	assert_eq(_screen._stack[0], RuleRegistry.R01_TOWARD_LIGHT,
		"posée en 2 alors que 1 est libre, la règle va en 1")
	assert_eq(_screen._stack[1], RuleRegistry.EMPTY)

func test_removing_a_rule_shifts_the_following_ones_left() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	_screen._on_remove_requested(0)

	assert_eq(_screen._stack[0], RuleRegistry.R02_FLEE_DANGER, "la suivante remonte")
	assert_eq(_screen._stack[1], RuleRegistry.EMPTY)

func test_a_rule_can_be_removed_without_dragging() -> void:
	# ENF-25 : aucune action ne doit avoir le glissement pour seul chemin.
	# Le retrait passe par l'icône de l'emplacement sélectionné.
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_screen._on_remove_requested(0)

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)
	assert_eq(_screen._compact_stack().size(), 0)

func test_the_remove_icon_shows_only_on_a_selected_occupied_slot() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	assert_false(_screen._slots[0]._remove.visible, "rien à retirer sans sélection")
	_screen._on_slot_tapped(0)
	assert_true(_screen._slots[0]._remove.visible)
	assert_false(_screen._slots[1]._remove.visible, "un emplacement vide n'a rien à retirer")

func test_the_remove_icon_meets_the_touch_minimum() -> void:
	# Petit à l'œil, mais >= 48 dp au doigt (ENF-01).
	var button: Control = _screen._slots[0]._remove
	assert_gte(button.custom_minimum_size.x, UiMetrics.MIN_TOUCH_TARGET)
	assert_gte(button.custom_minimum_size.y, UiMetrics.MIN_TOUCH_TARGET)

func test_a_rule_never_occupies_two_slots() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 1)

	# Reposer une règle déjà présente la DÉPLACE : ici elle échange avec R02,
	# et la pile compte toujours deux règles, jamais trois.
	assert_eq(_screen._compact_stack().size(), 2, "trois poses, jamais trois règles")
	var seen := {}
	for rule_id in _screen._compact_stack():
		assert_false(seen.has(rule_id), "règle en double dans la pile")
		seen[rule_id] = true

# --- la sélection : visible, et annulable ---------------------------------

func test_selection_is_marked_on_the_chip_and_cancellable() -> void:
	_screen._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)
	assert_true(_screen._has_selection)
	var marked := 0
	for chip in _screen._chips:
		if chip.selected:
			marked += 1
	assert_eq(marked, 1, "une sélection, et une seule, doit être marquée")

	_screen._on_chip_tapped(RuleRegistry.R01_TOWARD_LIGHT)  # re-appui = annule
	assert_false(_screen._has_selection)

func test_selecting_from_a_slot_marks_that_slot() -> void:
	# La pile étant compacte, une règle posée « en 2 » atterrit en 1.
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	assert_eq(_screen._stack[0], RuleRegistry.R02_FLEE_DANGER)
	_screen._on_slot_tapped(0)

	assert_true(_screen._has_selection)
	assert_eq(_screen._selected_from, 0)
	assert_true(_screen._slots[0].selected)

# --- le glissement -------------------------------------------------------

func test_dragging_from_the_panel_places_a_rule() -> void:
	_screen._on_rule_dropped(1, RuleRegistry.R01_TOWARD_LIGHT, -1)
	assert_eq(_screen._compact_stack(), [RuleRegistry.R01_TOWARD_LIGHT] as Array[int],
		"lâchée en 2, la règle se compacte en 1")

func test_dragging_between_slots_swaps_them() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	_screen._on_rule_dropped(1, RuleRegistry.R01_TOWARD_LIGHT, 0)

	assert_eq(_screen._stack[0], RuleRegistry.R02_FLEE_DANGER)
	assert_eq(_screen._stack[1], RuleRegistry.R01_TOWARD_LIGHT)

func test_dropping_a_slot_outside_removes_the_rule() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	assert_true(_screen._can_drop_data(Vector2.ZERO, {"rule_id": RuleRegistry.R01_TOWARD_LIGHT, "from_slot": 0}))
	_screen._drop_data(Vector2.ZERO, {"rule_id": RuleRegistry.R01_TOWARD_LIGHT, "from_slot": 0})

	assert_eq(_screen._stack[0], RuleRegistry.EMPTY)

func test_a_drop_coming_from_the_panel_is_not_a_removal() -> void:
	# Sinon lâcher une règle à côté d'un emplacement viderait la pile.
	assert_false(_screen._can_drop_data(Vector2.ZERO, {"rule_id": RuleRegistry.R01_TOWARD_LIGHT, "from_slot": -1}))

# --- RG-10 et RG-17 -------------------------------------------------------

func test_changing_the_stack_restarts_the_trial() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	for i in range(5):
		_screen._view.step_forward()
	assert_gt(_screen._view.current_state().tick, 0)

	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	assert_eq(_screen._view.current_state().tick, 0, "l'essai repart de zéro")

func test_objective_line_reports_live_progress() -> void:
	var line := RuleCatalog.objective_line(
		[{"type": "extraction", "percent": 100}], _screen._view.current_state())
	assert_string_contains(line, "sortis")


func test_the_next_free_slot_is_marked_and_the_others_are_not() -> void:
	# Le premier emplacement libre est une invitation ; les suivants ne sont
	# que du décor. Sans cette distinction, quatre cases vides se valent.
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)

	assert_true(_screen._slots[1]._next_available, "le suivant est marqué")
	assert_false(_screen._slots[2]._next_available)
	assert_false(_screen._slots[0]._next_available, "un emplacement occupé n'invite rien")


# --- rangs déclarés par le niveau (`slots`) -------------------------------
#
# Le validateur n'énumère les piles que jusqu'à `slots`. Un joueur capable de
# remplir quatre rangs sur un niveau qui en déclare deux pourrait donc gagner
# par une pile que personne n'a validée — et le niveau ne prouverait plus rien.

func test_the_level_declares_how_many_ranks_are_open() -> void:
	# La valeur attendue est lue DANS LE NIVEAU : la recopier ici en ferait une
	# troisième vérité, qui dériverait au premier redessin (invariant n°11).
	var level: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEVEL_PATH))
	assert_eq(_screen._open_slots, LevelSpec.open_slots(level),
		"les rangs ouverts sont ceux que le niveau déclare")
	assert_false(_screen._slots[0].locked)
	assert_false(_screen._slots[1].locked)
	assert_true(_screen._slots[2].locked, "le rang 3 n'existe pas sur ce niveau")
	assert_true(_screen._slots[3].locked)

func test_a_locked_rank_refuses_every_path() -> void:
	# Les deux chemins, sans glissement et par glissement.
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 2)
	assert_eq(_screen._compact_stack(), [] as Array[int], "rien n'entre par un rang fermé")
	_screen._on_rule_dropped(3, RuleRegistry.R01_TOWARD_LIGHT, -1)
	assert_eq(_screen._compact_stack(), [] as Array[int], "ni par glissement")

func test_a_locked_rank_is_invisible_but_keeps_its_share() -> void:
	# UN RANG VERROUILLÉ NE SE MONTRE PLUS DU TOUT.
	#
	# Il était dessiné, plus étroit, pour « indiquer ce qui vient ». Verdict de
	# l'essai sur l'appareil : « inutile, moche — pas la même taille — et ça
	# perturbe le joueur ». Le troisième point est le pire : un rang visible mais
	# inerte se lit comme un rang CASSÉ, pas comme un rang à venir ; on essaie
	# d'y poser une règle et rien ne répond. ENF-20 ne s'y applique plus, il n'y
	# a plus rien à distinguer.
	assert_eq(_screen._slots[2].modulate.a, 0.0,
		"un rang fermé ne se dessine pas")
	assert_eq(_screen._slots[0].modulate.a, 1.0,
		"un rang ouvert se dessine")

	# MAIS IL GARDE SA PART DE LARGEUR. Le cacher vraiment (`visible = false`)
	# le ferait ignorer par le conteneur, et les rangs ouverts s'étireraient : la
	# même règle changerait de taille d'un niveau à l'autre, et une cible tactile
	# qui bouge se rate.
	assert_eq(_screen._slots[2].size_flags_stretch_ratio,
		_screen._slots[0].size_flags_stretch_ratio,
		"tous les rangs gardent la même part de la barre")
	assert_true(_screen._slots[2].visible,
		"un rang fermé reste dans la disposition, sinon les autres s'étirent")
	assert_eq(_screen._slots[2].mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_a_locked_rank_is_never_offered_as_the_next_free_one() -> void:
	_pick_then_place(RuleRegistry.R01_TOWARD_LIGHT, 0)
	_pick_then_place(RuleRegistry.R02_FLEE_DANGER, 1)
	# La pile est pleine pour CE niveau : plus aucune invitation.
	for slot in _screen._slots:
		assert_false(slot._next_available,
			"pile pleine : aucun rang ne doit inviter, surtout pas un rang fermé")

## --- Ni survol, ni focus : rien qui distingue un bouton sans raison ----------
##
## DEUX TRACES FANTÔMES, trouvées à l'essai sur l'appareil et corrigées au même
## endroit, parce qu'elles ont la même cause : l'interface prétend des états qui
## n'existent pas au doigt.
##
##   · le SURVOL — le moteur maintient un pointeur émulé à la dernière position
##     touchée ; le doigt est parti, la tuile restait « survolée » ;
##   · le FOCUS — le dernier bouton touché le garde, et le moteur peint alors le
##     texte avec `font_focus_color`, qui IGNORE le `font_color` posé par
##     l'appelant. Dans la liste des niveaux, une tuile s'affichait en blanc au
##     milieu des vertes, sans qu'aucune règle du jeu ne la distingue.
##
## Une différence à l'écran doit vouloir dire quelque chose. Sur un téléphone il
## n'y a ni clavier ni tabulation : le focus ne peut rien vouloir dire.

func test_no_button_can_take_focus() -> void:
	var b := UiButtons.make("essai")
	add_child_autofree(b)
	assert_eq(b.focus_mode, Control.FOCUS_NONE,
		("un bouton qui prend le focus se repeint avec `font_focus_color` et "
		+ "efface la couleur voulue — une tuile blanche au milieu des vertes"))

## L'AUTRE MOITIÉ — le survol — N'EST PAS ÉPROUVABLE ICI, et il vaut mieux
## l'écrire que de laisser un test creux le prétendre.
##
## `_drop_hover_on_touch` ne s'applique que si `DisplayServer` annonce un écran
## tactile. Une suite headless n'en a pas : la fonction sort immédiatement, et
## un test qui comparerait les deux styles vérifierait la branche « poste de
## travail » en croyant vérifier le téléphone. C'est exactement le genre
## d'assertion qui passe au vert en ne regardant rien.
##
## Le survol est donc couvert par la capture d'appareil, et par elle seule. Le
## FOCUS, lui, ne dépend d'aucun périphérique : il se teste partout, d'où le
## test ci-dessus.

func test_tinting_a_button_covers_every_state() -> void:
	# MESURÉ AU PIXEL SUR L'APPAREIL : une tuile à (242,242,242) au milieu de
	# tuiles à (51,199,143). Elle n'avait rien de particulier — c'était celle qui
	# se trouvait sous le pointeur ÉMULÉ, laissé par le moteur à la dernière
	# position touchée, et `font_hover_color` écrasait la couleur voulue.
	#
	# La correction précédente avait aligné le STYLE de survol sans toucher à la
	# COULEUR DU TEXTE : elle paraissait complète et ne l'était qu'à moitié.
	var b := UiButtons.make("essai")
	add_child_autofree(b)
	var wanted := Color(0.2, 0.78, 0.56)
	UiButtons.tint(b, wanted)
	var missing := PackedStringArray()
	for state in ["font_color", "font_hover_color", "font_focus_color",
			"font_pressed_color"]:
		if b.get_theme_color(state) != wanted:
			missing.append(state)
	assert_eq(missing, PackedStringArray(),
		("états non teintés : %s — celui qui manque est celui qui se verra, "
		+ "et seulement sous le doigt") % ", ".join(missing))
