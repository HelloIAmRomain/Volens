extends GutTest
## L'ISSUE D'UNE PARTIE DOIT SE VOIR AVANT D'ÊTRE ANNONCÉE.
##
## POURQUOI CE FICHIER EXISTE. « Les échecs sont incompris : on ne comprend pas
## ce qui fait perdre, l'écran de défaite arrive avant le moment fatidique » —
## essai sur l'appareil, 15 août 2026. Cause : `_death_marks` était remis à
## zéro, filtré par âge et dessiné, mais **rien n'y ajoutait jamais rien**. La
## croix sur la case fatale n'a pas été affichée une seule fois depuis qu'elle
## est écrite.
##
## Un dessin qu'aucune donnée n'alimente est invisible ET silencieux : aucun
## test ne le remarque, aucune capture ne le montre, et le code a l'air correct.
## Ces tests vérifient la DONNÉE, pas le dessin — c'est elle qui manquait.
##
## DEUX DÉFAUTS DE PLUS ont été trouvés à la capture et sont figés ici : l'écho
## sortait VERT sur une mort, et décalé d'une case. Un agent meurt en ENTRANT
## sur le danger ; marquer sa position d'avant désignait la mauvaise case, et le
## contrôle de létalité y répondait « pas de danger ici ».

func _view_on(level_id: String, stack: Array[int]) -> SimView:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2400)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(sub)
	var view := SimView.new()
	sub.add_child(view)
	var level: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/levels/%s.json" % level_id))
	view.load_level(level as Dictionary, RuleParams.new(), stack)
	return view

func test_a_death_is_marked_on_the_fatal_cell_and_in_red() -> void:
	# ch1_02 porte un danger, et « Vers la lumière » seule y jette la nuée : le
	# cas d'épreuve est celui où le mécanisme est SOLLICITÉ (invariant n°12).
	var view := _view_on("ch1_02", [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])
	var seen: Array[Vector2i] = []
	view.agent_lost.connect(func(cell: Vector2i) -> void: seen.append(cell))
	for i in range(30):
		view.step_forward()
	assert_gt(seen.size(), 0,
		("Aucune mort signalée alors que la nuée traverse un danger. Le signal "
		+ "n'est pas émis — c'est exactement le défaut d'origine : un dessin "
		+ "qu'aucune donnée n'alimente."))

	var grid: GridState = view.current_state().grid
	var wrong := PackedStringArray()
	for cell in seen:
		if not grid.is_danger_active_at(cell, view.current_state().tick):
			wrong.append(str(cell))
	assert_eq(wrong, PackedStringArray(),
		("Une mort a été marquée sur une case SANS danger : %s. L'agent meurt "
		+ "en ENTRANT sur le danger ; c'est la case d'arrivée qu'il faut "
		+ "désigner, pas celle d'où il venait — sans quoi l'écho se dessine à "
		+ "côté, et en vert.") % ", ".join(wrong))

	var fatal_marks := 0
	for mark in view._death_marks:
		if bool(mark.get("fatal", false)):
			fatal_marks += 1
	assert_gt(fatal_marks, 0, "une mort doit produire une marque ROUGE (fatal = true)")

func test_only_the_last_agent_out_gets_a_victory_echo() -> void:
	# Un anneau par sortie ferait vingt anneaux sur une victoire : du bruit, pas
	# de l'information. C'est l'instant qui TRANCHE qu'il faut montrer.
	var view := _view_on("ch1_01", [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])
	var seen: Array[Vector2i] = []
	view.last_agent_exited.connect(func(cell: Vector2i) -> void: seen.append(cell))
	for i in range(60):
		view.step_forward()
	assert_eq(view.current_state().outcome, SimState.Outcome.WON,
		"ch1_01 doit être gagné par « Vers la lumière » seule")
	assert_eq(seen.size(), 1,
		("Exactement UN écho de victoire est attendu — celui du dernier sorti. "
		+ "Reçus : %d.") % seen.size())

func test_the_summary_waits_for_the_echo_to_play() -> void:
	# L'écho dure 1,6 s. Un bilan qui tombe avant laisse le joueur devant une
	# scène où il ne s'est visiblement rien passé.
	assert_gte(GameScreen.OUTCOME_DELAY, SimView.DEATH_MARK_SECONDS,
		("Le bilan doit attendre la fin de l'écho : délai %.1f s pour un écho "
		+ "de %.1f s.") % [GameScreen.OUTCOME_DELAY, SimView.DEATH_MARK_SECONDS])
