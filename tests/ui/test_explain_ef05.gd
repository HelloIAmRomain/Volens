extends GutTest
## Diagnostic EF-05 — le pilier P4 rendu tangible.
##
## Ce que ces tests protègent : qu'un joueur qui échoue puisse TOUJOURS
## former une hypothèse. Un diagnostic muet, ou qui désigne la mauvaise
## règle, est pire que pas de diagnostic — il induit en erreur.

func _grid(width: int, height: int) -> GridState:
	var g := GridState.new()
	g.size = Vector2i(width, height)
	var n := width * height
	g.cells = PackedInt32Array(); g.cells.resize(n)
	g.pheromone = PackedInt32Array(); g.pheromone.resize(n)
	g.cycle_index = PackedInt32Array(); g.cycle_index.resize(n)
	for i in range(n):
		g.cycle_index[i] = -1
	return g

func _state(width: int, height: int, positions: Array) -> SimState:
	var s := SimState.new()
	s.tick = 0
	s.outcome = SimState.Outcome.RUNNING
	s.counters = Counters.new()
	s.rule_params = RuleParams.new()
	s.grid = _grid(width, height)
	s.agents = []
	for i in range(positions.size()):
		var a := AgentState.new()
		a.id = i
		a.pos = positions[i]
		a.flags = AgentState.PRESENT
		s.agents.append(a)
	return s

func _put_cell(s: SimState, pos: Vector2i, cell_type: int) -> void:
	s.grid.cells[s.grid.index_of(pos)] = cell_type

# --- la règle qui décide ---------------------------------------------------

func test_names_the_rule_that_decided_and_its_direction() -> void:
	var s := _state(5, 5, [Vector2i(2, 2)])
	_put_cell(s, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]

	var r := RuleExplainer.explain(s.agents[0], s, stack)

	assert_eq(int(r["slot"]), 0, "c'est la première règle qui a décidé")
	assert_string_contains(String(r["lines"][0]), "Vers la lumière")
	assert_string_contains(String(r["lines"][0]), "vers le haut")

func test_explains_why_each_preceding_rule_did_not_apply() -> void:
	# LE cas d'usage : « pourquoi ma première règle n'a-t-elle rien fait ? »
	var s := _state(5, 5, [Vector2i(2, 2)])
	_put_cell(s, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)
	var stack: Array[int] = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]

	var r := RuleExplainer.explain(s.agents[0], s, stack)

	assert_eq(int(r["slot"]), 1, "R02 s'abstient, R01 décide")
	assert_eq((r["lines"] as Array).size(), 2, "une ligne par règle consultée")
	assert_string_contains(String(r["lines"][0]), "aucun danger")

func test_says_when_no_rule_applies_at_all() -> void:
	# Une nuée immobile sans explication est la pire situation pour un
	# testeur : il croit à un bug.
	var s := _state(5, 5, [Vector2i(2, 2)])
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]

	var r := RuleExplainer.explain(s.agents[0], s, stack)

	assert_eq(int(r["slot"]), -1)
	assert_string_contains(String(r["lines"][1]), "immobile")

# --- motifs d'abstention, un par condition réelle ---------------------------

func test_reason_no_light_on_the_map() -> void:
	var s := _state(5, 5, [Vector2i(2, 2)])
	var r := RuleExplainer.explain(s.agents[0], s, [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])
	assert_string_contains(String(r["lines"][0]), "aucune lumière")

func test_reason_already_on_the_light() -> void:
	var s := _state(5, 5, [Vector2i(2, 2)])
	_put_cell(s, Vector2i(2, 2), GridState.CellType.LIGHT_SOURCE)
	var r := RuleExplainer.explain(s.agents[0], s, [RuleRegistry.R01_TOWARD_LIGHT] as Array[int])
	assert_string_contains(String(r["lines"][0]), "déjà sur la lumière")

func test_reason_danger_out_of_perception_range() -> void:
	var s := _state(20, 1, [Vector2i(0, 0)])
	_put_cell(s, Vector2i(15, 0), GridState.CellType.STATIC_DANGER)
	var r := RuleExplainer.explain(s.agents[0], s, [RuleRegistry.R02_FLEE_DANGER] as Array[int])
	assert_string_contains(String(r["lines"][0]), "trop loin")

func test_reason_no_perceived_neighbour() -> void:
	var s := _state(5, 5, [Vector2i(2, 2)])
	var r := RuleExplainer.explain(s.agents[0], s, [RuleRegistry.R03_STAY_GROUPED] as Array[int])
	assert_string_contains(String(r["lines"][0]), "aucun voisin")

# --- le mouvement refusé ------------------------------------------------------

func test_reports_a_move_denied_by_conflict_resolution() -> void:
	# « Ma règle dit d'avancer et l'agent ne bouge pas » : sans cette ligne,
	# le joueur conclut que la règle est cassée (RG-06).
	var note := RuleExplainer.movement_note(Vector2i(0, -1), Vector2i.ZERO)
	assert_string_contains(note, "occupée")

func test_says_nothing_when_the_move_went_through() -> void:
	assert_eq(RuleExplainer.movement_note(Vector2i(0, -1), Vector2i(0, -1)), "")
	assert_eq(RuleExplainer.movement_note(Vector2i.ZERO, Vector2i.ZERO), "")

# --- garantie de non-régression ------------------------------------------------

func test_explaining_never_mutates_the_state() -> void:
	# EF-05 est en LECTURE SEULE. Si le diagnostic déplaçait une empreinte,
	# ce ne serait pas une évolution mais un défaut (règle du lot).
	var s := _state(6, 6, [Vector2i(2, 2), Vector2i(3, 3)])
	_put_cell(s, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)
	_put_cell(s, Vector2i(5, 5), GridState.CellType.STATIC_DANGER)
	var before := SimCore.hash_state(s)

	var stack: Array[int] = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R03_STAY_GROUPED, RuleRegistry.R01_TOWARD_LIGHT]
	for agent in s.agents:
		RuleExplainer.explain(agent, s, stack)

	assert_eq(SimCore.hash_state(s), before, "expliquer ne change rien à l'état")
