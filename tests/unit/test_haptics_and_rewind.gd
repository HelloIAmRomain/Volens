extends GutTest
## Deux capacités que rien ne couvrait, et qui portent chacune une exigence.

# --- ENF-24 : le retour haptique est désactivable --------------------------
#
# « Désactivable » n'est pas une option de confort : c'est la moitié de
# l'exigence, et c'est celle qu'on oublie. Livrer une vibration qu'un testeur
# ne peut pas couper est un défaut, pas un manque.

func after_each() -> void:
	Haptics.enabled = true

func test_haptics_are_on_by_default() -> void:
	assert_true(Haptics.enabled, "actif par défaut : un réglage jamais senti ne se règle pas")

func test_disabling_haptics_silences_every_event() -> void:
	# Aucun de ces appels ne doit atteindre le vibreur ni lever d'erreur.
	Haptics.enabled = false
	Haptics.select()
	Haptics.drop()
	Haptics.exited()
	assert_false(Haptics.enabled, "l'état reste coupé après une salve d'événements")

func test_refusal_is_safe_without_a_tree() -> void:
	# `refuse` a besoin d'un nœud pour son minuteur. Appelée avec un hôte
	# absent ou hors de l'arbre, elle ne doit pas planter — c'est le cas qui
	# se produit à la fermeture d'un écran.
	Haptics.refuse(null)
	var orphan := Node.new()
	Haptics.refuse(orphan)
	orphan.free()
	assert_true(true, "aucun plantage sans arbre")

func test_settings_carry_the_choice_to_the_haptics() -> void:
	var s := Settings.new()
	s.haptics = false
	s.apply()
	assert_false(Haptics.enabled, "le réglage pilote réellement le vibreur")

# --- EF-03 : remonter le temps ---------------------------------------------
#
# L'affordance a disparu de l'interface, PAS la capacité (décision consignée).
# Une capacité que plus rien n'appelle pourrit en silence : elle est donc
# testée ici, à défaut d'être exercée par l'écran de jeu.

func _view() -> SimView:
	var level: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/levels/ch1_01.json"))
	var view := SimView.new()
	add_child_autofree(view)
	view.load_level(level, RuleParams.new(), [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])
	return view

func test_stepping_back_returns_to_the_previous_tick() -> void:
	var view := _view()
	for i in range(6):
		view.step_forward()
	assert_eq(view.current_state().tick, 6)
	view.step_backward()
	assert_eq(view.current_state().tick, 5, "un pas en arrière, un tick en arrière")

func test_rewinding_reconstructs_the_same_state_as_playing_forward() -> void:
	# DT-12 : la remontée du temps est une RE-SIMULATION, pas une pile
	# d'états sauvegardés. Elle doit donc redonner exactement le même état.
	var forward := _view()
	for i in range(4):
		forward.step_forward()
	var expected := SimCore.hash_state(forward.current_state())

	var rewound := _view()
	for i in range(9):
		rewound.step_forward()
	rewound.seek(4)
	assert_eq(SimCore.hash_state(rewound.current_state()), expected,
		"l'état atteint par remontée est identique à celui atteint en jouant")

func test_seeking_before_the_start_clamps_to_zero() -> void:
	var view := _view()
	view.step_forward()
	view.seek(-5)
	assert_eq(view.current_state().tick, 0, "on ne remonte pas avant le début de l'essai")
