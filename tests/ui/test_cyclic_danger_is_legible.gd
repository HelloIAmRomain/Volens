extends GutTest
## DEUX ZONES QUI TUENT DOIVENT SE DISTINGUER — même quand elles tuent toutes
## les deux.
##
## POURQUOI CE FICHIER EXISTE. « Si j'ai deux zones qui tuent ou qui font la même
## chose, c'est une erreur de conception ; s'il y a une ambiguïté, c'est pas
## normal. » L'audit du vocabulaire (carnet, décision 197) a trouvé le cas exact :
##
##   · un danger cyclique **éteint** portait déjà une teinte dormante — il se
##     distinguait très bien ;
##   · un danger cyclique **allumé** portait EXACTEMENT la teinte d'un danger
##     permanent — rien ne le distinguait.
##
## C'était le pire découpage possible : la différence n'apparaissait que
## lorsqu'elle avait cessé d'être utile, et disparaissait précisément au moment
## où elle décidait de la vie d'un agent. Le joueur voyait deux zones rouges
## identiques dont l'une allait s'ouvrir, sans aucun moyen de savoir laquelle —
## et en concluait que le jeu était capricieux.
##
## CE QUE LA MARQUE DIT, et ce n'est pas ce que dit la teinte : la teinte dit
## « en ce moment c'est dangereux », la marque dit « CETTE case-là change ».
## C'est une propriété permanente, donc elle s'affiche en permanence — dans les
## deux phases, sans clignoter. Une marque qui apparaîtrait avec le danger
## n'ajouterait rien ; une marque qui clignoterait demanderait d'être regardée
## au bon moment, ce qu'ENF-21 refuse.
##
## LE TEST PORTE SUR LA DONNÉE, jamais sur les pixels — leçon de
## `test_outcome_echo.gd` : une marque que rien n'alimente est invisible ET
## silencieuse, et le code a l'air correct.

## ch5_03 porte des dangers cycliques. Le décor est vérifié par un test dédié :
## si le niveau cessait d'en porter, tout ce fichier passerait au vert en ne
## vérifiant plus rien.
const CYCLIC_LEVEL := "ch5_03"
const STATIC_LEVEL := "ch1_02"

func _view_on(level_id: String) -> SimView:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2400)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(sub)
	var view := SimView.new()
	sub.add_child(view)
	view.load_level(LevelCatalog.load_level_data(level_id), RuleParams.new(),
		[RuleRegistry.R01_TOWARD_LIGHT] as Array[int])
	return view

func _cyclic_cells(level_id: String) -> int:
	var grid: GridState = _view_on(level_id).current_state().grid
	var n := 0
	for y in range(grid.size.y):
		for x in range(grid.size.x):
			if grid.cell_type_at(Vector2i(x, y)) == GridState.CellType.CYCLIC_DANGER:
				n += 1
	return n

func test_the_reference_levels_still_carry_what_they_must() -> void:
	# GARDE-FOU DU DÉCOR, et il vaut dans les deux sens : il faut un niveau qui
	# porte des dangers cycliques, et un qui n'en porte pas — sans le second, un
	# marqueur posé PARTOUT passerait tous les autres tests.
	assert_gt(_cyclic_cells(CYCLIC_LEVEL), 0,
		"%s doit porter des dangers cycliques, sinon ces tests sont creux" % CYCLIC_LEVEL)
	assert_eq(_cyclic_cells(STATIC_LEVEL), 0,
		"%s ne doit porter aucun danger cyclique" % STATIC_LEVEL)

func test_a_cyclic_danger_is_marked_even_while_it_is_lethal() -> void:
	# LE CŒUR DU CORRECTIF. On avance jusqu'à trouver un tick où le danger est
	# ACTIF — c'est la phase où la teinte ne distingue plus rien — et la marque
	# doit y être. Le cas d'épreuve est celui où le mécanisme est SOLLICITÉ
	# (invariant n°12), pas celui où il est confortable.
	var view := _view_on(CYCLIC_LEVEL)
	var seen_active := false
	for i in range(24):
		var grid: GridState = view.current_state().grid
		var tick: int = view.current_state().tick
		for y in range(grid.size.y):
			for x in range(grid.size.x):
				var p := Vector2i(x, y)
				if grid.cell_type_at(p) == GridState.CellType.CYCLIC_DANGER \
						and grid.is_danger_active_at(p, tick):
					seen_active = true
		if seen_active:
			break
		view.step_forward()
	assert_true(seen_active,
		("aucun tick ne rend le danger cyclique actif en 24 pas : le test "
		+ "n'éprouve alors PAS la phase où la teinte cesse de distinguer"))
	assert_gt(_marked_count(view), 0,
		("un danger cyclique ACTIF doit rester marqué : sans cela il est "
		+ "indiscernable d'un danger permanent, et le joueur ne peut pas savoir "
		+ "qu'il s'ouvrira"))

func test_the_mark_covers_every_cyclic_cell_and_only_those() -> void:
	# NI PLUS, NI MOINS. Une marque qui manquerait une case laisserait une zone
	# ambiguë ; une marque posée sur les dangers permanents ferait la promesse
	# inverse — « celui-ci s'ouvrira » — et coûterait des agents.
	var view := _view_on(CYCLIC_LEVEL)
	assert_eq(_marked_count(view), _cyclic_cells(CYCLIC_LEVEL),
		"la marque doit couvrir exactement les cases cycliques")

func test_a_permanent_danger_is_never_marked() -> void:
	var view := _view_on(STATIC_LEVEL)
	assert_eq(_marked_count(view), 0,
		("un danger permanent ne porte pas la marque du cyclique : elle "
		+ "promettrait une ouverture qui ne viendra jamais"))

## Le nombre de cases portant la marque « cette case change ». On interroge le
## nœud qui dessine, pas l'image : c'est la DONNÉE qui manquait à l'origine.
func _marked_count(view: SimView) -> int:
	for child in view.get_children():
		if child.has_method("pulsing_count"):
			return int(child.call("pulsing_count"))
	fail_test("aucun nœud de marques trouvé sous la vue")
	return -1
