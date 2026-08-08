extends GutTest
## LA CHARTE DES COULEURS EST UNE PROMESSE ; ces tests la tiennent.
##
## La charte dit trois choses (`game/view/view_palette.gd`) :
##   1. une teinte **réservée** par entrée du vocabulaire RG-14 ;
##   2. les emplacements de pile n'ont **aucune teinte propre** — un rang se
##      lit à son numéro et à sa position ;
##   3. la palette de diagnostic est **modale** et ne coexiste jamais avec la
##      lecture normale.
##
## Rien de tout cela n'est vérifiable à l'œil une fois la charte écrite : deux
## teintes se rapprochent d'une retouche à l'autre, et le jour où l'on ajoute
## le neuvième élément on ne se souvient plus de ce qui était pris. Le défaut
## d'origine était exactement celui-là — l'emplacement 2 portait l'ambre de la
## lumière, l'emplacement 4 le vert de la sortie.

## Les neuf entrées du vocabulaire (RG-14). Le mur est volontairement exclu
## des teintes signifiantes : c'est du décor.
const VOCABULARY := [
	GridState.CellType.EXIT,
	GridState.CellType.STATIC_DANGER,
	GridState.CellType.RESOURCE,
	GridState.CellType.DROPOFF,
	GridState.CellType.PRESSURE_DOOR,
	GridState.CellType.ONE_WAY,
	GridState.CellType.LIGHT_SOURCE,
]

## Écart de teinte minimal entre deux éléments ⚙️, en degrés. En deçà, deux
## éléments côte à côte se confondent sur une dalle en plein soleil.
const MIN_HUE_GAP_DEGREES := 20.0

func _hue_degrees(c: Color) -> float:
	return c.h * 360.0

func test_every_vocabulary_entry_has_a_colour() -> void:
	for cell_type in VOCABULARY:
		var c := ViewPalette.element_color(cell_type)
		assert_ne(c, ViewPalette.BACKGROUND,
			"élément %d sans teinte réservée : il se confondrait avec le fond" % cell_type)

func test_element_hues_are_pairwise_distinguishable() -> void:
	for i in range(VOCABULARY.size()):
		for j in range(i + 1, VOCABULARY.size()):
			var a := ViewPalette.element_color(VOCABULARY[i])
			var b := ViewPalette.element_color(VOCABULARY[j])
			var gap: float = absf(_hue_degrees(a) - _hue_degrees(b))
			gap = minf(gap, 360.0 - gap)   # la roue est circulaire
			assert_gt(gap, MIN_HUE_GAP_DEGREES,
				"éléments %d et %d : %.0f° d'écart seulement" % [VOCABULARY[i], VOCABULARY[j], gap])

func test_the_stack_ranks_carry_no_hue_identity() -> void:
	# LE défaut d'origine : l'emplacement 2 portait l'ambre de la lumière et
	# l'emplacement 4 le vert de la sortie.
	#
	# La propriété qui l'interdit n'est PAS un écart de teinte — sur une
	# couleur désaturée la teinte n'a pas de sens perceptif, et exiger un écart
	# reviendrait à interdire un gris parce qu'il tire imperceptiblement vers
	# le bleu. C'est la **désaturation** qui garantit qu'un rang ne peut pas
	# être lu comme un élément.
	for slot_colour in [ViewPalette.SLOT_IDLE, ViewPalette.SLOT_FILLED, ViewPalette.SLOT_LOCKED]:
		assert_lt(slot_colour.s, 0.35,
			"un emplacement de pile ne porte pas de teinte propre (saturation %.2f)" % slot_colour.s)

func test_the_slot_widget_never_reaches_for_the_diagnostic_palette() -> void:
	# Garde STRUCTURELLE, la seule qui empêche le défaut de revenir : la
	# désaturation se vérifie sur des constantes, mais rien n'empêcherait un
	# jour `RuleSlot` d'appeler `slot_color()` — c'est exactement ce qu'il
	# faisait. La palette de diagnostic est modale ; l'interface de pile n'y
	# touche pas.
	var source := FileAccess.get_file_as_string("res://game/ui/rule_slot.gd")
	assert_false(source.contains("slot_color"),
		"RuleSlot emprunte la palette de diagnostic : un rang redeviendrait une teinte")
	assert_false(source.contains("SLOT_COLORS"),
		"RuleSlot emprunte la palette de diagnostic")

func test_the_dormant_cycle_keeps_the_hue_of_its_active_phase() -> void:
	# Un danger cyclique dormant reste LE MÊME élément : changer sa teinte
	# ferait croire à un autre objet plutôt qu'à un autre état.
	var active := ViewPalette.element_color(GridState.CellType.CYCLIC_DANGER, true)
	var dormant := ViewPalette.element_color(GridState.CellType.CYCLIC_DANGER, false)
	var gap: float = absf(_hue_degrees(active) - _hue_degrees(dormant))
	gap = minf(gap, 360.0 - gap)
	assert_lt(gap, MIN_HUE_GAP_DEGREES, "même élément, même teinte")
	assert_lt(dormant.v, active.v, "la phase dormante se distingue par la LUMINOSITÉ")

func test_the_swarm_is_one_colour_outside_diagnosis() -> void:
	# DA-01 : la nuée est le personnage, et un personnage n'a pas quatre
	# couleurs. La palette de diagnostic existe, mais elle est modale.
	var view := SimView.new()
	autofree(view)
	assert_false(view.show_decision_colors,
		"la coloration par règle est une surcouche, jamais l'état par défaut")
	assert_gt(ViewPalette.SLOT_COLORS.size(), 0, "la palette modale existe")
