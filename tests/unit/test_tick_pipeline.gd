extends GutTest
## Tests unitaires du pipeline de tick (T-011). Étape 2 est encore au palier
## « à vide » (tout agent présent reste immobile) : ces tests couvrent la
## charpente des sept étapes, pas la cascade de règles (T-012).

func _make_empty_grid(width: int, height: int) -> GridState:
	var grid := GridState.new()
	grid.size = Vector2i(width, height)
	var n := width * height
	grid.cells = PackedInt32Array()
	grid.cells.resize(n)
	grid.pheromone = PackedInt32Array()
	grid.pheromone.resize(n)
	grid.cycle_index = PackedInt32Array()
	grid.cycle_index.resize(n)
	for i in range(n):
		grid.cycle_index[i] = -1
	return grid

func _make_state(width: int, height: int, agent_positions: Array) -> SimState:
	var state := SimState.new()
	state.tick = 0
	state.outcome = SimState.Outcome.RUNNING
	state.counters = Counters.new()
	state.rule_params = RuleParams.new()
	state.grid = _make_empty_grid(width, height)
	state.agents = []
	for i in range(agent_positions.size()):
		var agent := AgentState.new()
		agent.id = i
		agent.pos = agent_positions[i]
		agent.dir = Directions.NORTH
		agent.flags = AgentState.PRESENT
		state.agents.append(agent)
	return state

# --- load_level ---------------------------------------------------------

func test_load_level_builds_grid_and_agents() -> void:
	var level_data := {
		"max_ticks": 50,
		"grid": {
			"size": [2, 2],
			"cells": [0, 1, 0, 0],
		},
		"agents": [{"pos": [0, 0]}, {"pos": [1, 1]}],
	}
	var state := SimCore.load_level(level_data, RuleParams.new())

	assert_eq(state.tick, 0)
	assert_eq(state.max_ticks, 50)
	assert_eq(state.outcome, SimState.Outcome.RUNNING)
	assert_eq(state.grid.size, Vector2i(2, 2))
	assert_eq(state.grid.cell_type_at(Vector2i(1, 0)), GridState.CellType.WALL)
	assert_eq(state.agents.size(), 2)
	assert_eq(state.agents[0].id, 0)
	assert_eq(state.agents[1].pos, Vector2i(1, 1))
	assert_true(state.agents[0].is_present())

# --- step() : immutabilité et incrément de tick -------------------------

func test_step_never_mutates_the_input_state() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	var next_state := SimCore.step(state, [])

	assert_eq(state.tick, 0, "l'état t reste en lecture seule (DT-08)")
	assert_eq(next_state.tick, 1)
	assert_ne(state, next_state, "step() renvoie un nouvel objet, jamais l'entrée mutée")

func test_step_leaves_agents_immobile_at_the_empty_stage() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	var next_state := SimCore.step(state, [])

	assert_eq(next_state.agents[0].pos, Vector2i(1, 1), "T-011 : étape 2 renvoie systématiquement l'immobilité")

func test_two_successive_runs_produce_the_same_positions() -> void:
	var state_a := _make_state(4, 4, [Vector2i(0, 0), Vector2i(3, 3)])
	var state_b := _make_state(4, 4, [Vector2i(0, 0), Vector2i(3, 3)])
	for i in range(5):
		state_a = SimCore.step(state_a, [])
		state_b = SimCore.step(state_b, [])

	assert_eq(state_a.tick, state_b.tick)
	assert_eq(state_a.agents[0].pos, state_b.agents[0].pos)
	assert_eq(state_a.agents[1].pos, state_b.agents[1].pos)

# --- étape 3 : résolution des conflits -----------------------------------

func test_conflict_same_target_cell_smallest_id_wins() -> void:
	# Deux agents adjacents visent la même case libre.
	var state := _make_state(3, 1, [Vector2i(0, 0), Vector2i(2, 0)])
	var desired: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0)]  # tous deux visent (1,0)

	var granted := SimCore._resolve_conflicts(state, desired)

	assert_eq(granted[0], Vector2i(1, 0), "id 0 (plus petit) l'emporte")
	assert_eq(granted[1], Vector2i.ZERO, "id 1 reste sur place")

func test_conflict_defender_keeps_its_cell_even_against_a_smaller_id() -> void:
	# id 0 (plus petit id) tente d'entrer sur la case d'id 1, qui reste immobile.
	var state := _make_state(2, 1, [Vector2i(0, 0), Vector2i(1, 0)])
	var desired: Array[Vector2i] = [Vector2i(1, 0), Vector2i.ZERO]

	var granted := SimCore._resolve_conflicts(state, desired)

	assert_eq(granted[0], Vector2i.ZERO, "un agent immobile défend toujours sa case (RG-01), quel que soit l'id")
	assert_eq(granted[1], Vector2i.ZERO)

func test_conflict_chain_vacate_lets_the_follower_advance() -> void:
	# id 0 avance vers la case que id 1 est en train de quitter.
	var state := _make_state(3, 1, [Vector2i(0, 0), Vector2i(1, 0)])
	var desired: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 0)]

	var granted := SimCore._resolve_conflicts(state, desired)

	assert_eq(granted[0], Vector2i(1, 0))
	assert_eq(granted[1], Vector2i(1, 0))

func test_wall_blocks_movement() -> void:
	var state := _make_state(2, 1, [Vector2i(0, 0)])
	state.grid.cells[state.grid.index_of(Vector2i(1, 0))] = GridState.CellType.WALL
	var desired: Array[Vector2i] = [Vector2i(1, 0)]

	var granted := SimCore._resolve_conflicts(state, desired)

	assert_eq(granted[0], Vector2i.ZERO, "un mur bloque le déplacement, l'agent reste sur place")

func test_grid_edge_blocks_movement() -> void:
	var state := _make_state(1, 1, [Vector2i(0, 0)])
	var desired: Array[Vector2i] = [Vector2i(-1, 0)]  # hors grille

	var granted := SimCore._resolve_conflicts(state, desired)

	assert_eq(granted[0], Vector2i.ZERO)

func test_absent_agent_does_not_defend_or_claim_a_cell() -> void:
	var state := _make_state(2, 1, [Vector2i(0, 0), Vector2i(1, 0)])
	state.agents[1].flags = AgentState.SORTI  # plus PRESENT
	var desired: Array[Vector2i] = [Vector2i(1, 0), Vector2i.ZERO]

	var granted := SimCore._resolve_conflicts(state, desired)

	assert_eq(granted[0], Vector2i(1, 0), "un agent absent ne défend plus sa case")

# --- étape 5 : effets d'environnement -------------------------------------

func test_agent_entering_exit_is_flagged_sorti() -> void:
	var state := _make_state(1, 1, [Vector2i(0, 0)])
	state.grid.cells[0] = GridState.CellType.EXIT

	SimCore._apply_environment_effects(state)

	assert_false(state.agents[0].is_present())
	assert_eq(state.agents[0].flags & AgentState.SORTI, AgentState.SORTI)
	assert_eq(state.counters.exited, 1)

func test_agent_entering_static_danger_is_flagged_perdu() -> void:
	var state := _make_state(1, 1, [Vector2i(0, 0)])
	state.grid.cells[0] = GridState.CellType.STATIC_DANGER

	SimCore._apply_environment_effects(state)

	assert_false(state.agents[0].is_present())
	assert_eq(state.agents[0].flags & AgentState.PERDU, AgentState.PERDU)
	assert_eq(state.counters.lost, 1)

func test_agent_on_inactive_cyclic_danger_is_safe() -> void:
	var state := _make_state(1, 1, [Vector2i(0, 0)])
	state.grid.cells[0] = GridState.CellType.CYCLIC_DANGER
	state.grid.cycle_index[0] = 0
	var cycle := CycleDef.new()
	cycle.period = 4
	cycle.active_ticks = 1  # actif seulement au tick 0 mod 4
	state.grid.cycles = [cycle]
	state.tick = 2  # 2 mod 4 = 2 -> inactif

	SimCore._apply_environment_effects(state)

	assert_true(state.agents[0].is_present())
	assert_eq(state.counters.lost, 0)

# --- étape 6 : évaporation des pistes --------------------------------------

func test_pheromone_evaporates_by_one_and_floors_at_zero() -> void:
	var state := _make_state(1, 1, [])
	state.grid.pheromone[0] = 1

	SimCore._evaporate_pheromones(state)
	assert_eq(state.grid.pheromone[0], 0)

	SimCore._evaporate_pheromones(state)
	assert_eq(state.grid.pheromone[0], 0, "ne descend jamais sous zéro")

# --- étape 7 : issue --------------------------------------------------------

func test_outcome_becomes_lost_when_tick_limit_is_reached() -> void:
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	state.max_ticks = 3
	for i in range(3):
		state = SimCore.step(state, [])

	assert_eq(state.outcome, SimState.Outcome.LOST)

func test_outcome_never_reverts_once_decided() -> void:
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	state.outcome = SimState.Outcome.WON
	state.max_ticks = 1

	var next_state := SimCore.step(state, [])

	assert_eq(next_state.outcome, SimState.Outcome.WON, "une issue déjà tranchée ne revient jamais en arrière")
