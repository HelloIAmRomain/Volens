extends GutTest
## Tests unitaires des structures d'état (T-010).

func test_agent_state_is_present_by_default() -> void:
	var agent := AgentState.new()
	assert_true(agent.is_present())

func test_agent_state_flags_are_distinct_bits() -> void:
	assert_eq(AgentState.PRESENT, 1)
	assert_eq(AgentState.PORTEUR, 2)
	assert_eq(AgentState.SORTI, 4)
	assert_eq(AgentState.PERDU, 8)

func test_agent_state_clone_is_a_deep_independent_copy() -> void:
	var original := AgentState.new()
	original.id = 3
	original.pos = Vector2i(1, 2)
	original.dir = Directions.EAST
	original.flags = AgentState.PRESENT | AgentState.PORTEUR

	var copy := original.clone()
	copy.pos = Vector2i(9, 9)
	copy.flags = AgentState.SORTI

	assert_eq(original.pos, Vector2i(1, 2), "l'original ne doit pas être affecté par la copie")
	assert_eq(original.flags, AgentState.PRESENT | AgentState.PORTEUR)
	assert_eq(copy.id, 3, "l'id est bien recopié")

func test_grid_state_index_and_bounds() -> void:
	var grid := GridState.new()
	grid.size = Vector2i(3, 2)
	grid.cells = PackedInt32Array([0, 0, 0, 0, 0, 0])
	grid.pheromone = PackedInt32Array([0, 0, 0, 0, 0, 0])
	grid.cycle_index = PackedInt32Array([-1, -1, -1, -1, -1, -1])

	assert_eq(grid.index_of(Vector2i(0, 0)), 0)
	assert_eq(grid.index_of(Vector2i(2, 1)), 5)
	assert_true(grid.is_in_bounds(Vector2i(2, 1)))
	assert_false(grid.is_in_bounds(Vector2i(3, 0)))
	assert_false(grid.is_in_bounds(Vector2i(-1, 0)))

func test_grid_state_wall_is_not_walkable() -> void:
	var grid := GridState.new()
	grid.size = Vector2i(2, 1)
	grid.cells = PackedInt32Array([GridState.CellType.EMPTY, GridState.CellType.WALL])
	grid.pheromone = PackedInt32Array([0, 0])
	grid.cycle_index = PackedInt32Array([-1, -1])

	assert_true(grid.is_walkable(Vector2i(0, 0)))
	assert_false(grid.is_walkable(Vector2i(1, 0)))
	assert_false(grid.is_walkable(Vector2i(5, 5)), "hors grille = non franchissable")

func test_static_danger_is_always_active() -> void:
	var grid := GridState.new()
	grid.size = Vector2i(1, 1)
	grid.cells = PackedInt32Array([GridState.CellType.STATIC_DANGER])
	grid.pheromone = PackedInt32Array([0])
	grid.cycle_index = PackedInt32Array([-1])

	assert_true(grid.is_danger_active_at(Vector2i(0, 0), 0))
	assert_true(grid.is_danger_active_at(Vector2i(0, 0), 999))

func test_cyclic_danger_follows_its_cycle_def() -> void:
	var cycle := CycleDef.new()
	cycle.period = 4
	cycle.active_ticks = 2  # actif aux ticks 0,1 mod 4 ; inactif à 2,3 mod 4

	var grid := GridState.new()
	grid.size = Vector2i(1, 1)
	grid.cells = PackedInt32Array([GridState.CellType.CYCLIC_DANGER])
	grid.pheromone = PackedInt32Array([0])
	grid.cycle_index = PackedInt32Array([0])
	grid.cycles = [cycle]

	assert_true(grid.is_danger_active_at(Vector2i(0, 0), 0))
	assert_true(grid.is_danger_active_at(Vector2i(0, 0), 5))  # 5 mod 4 = 1 -> actif
	assert_false(grid.is_danger_active_at(Vector2i(0, 0), 2))
	assert_false(grid.is_danger_active_at(Vector2i(0, 0), 7))  # 7 mod 4 = 3 -> inactif

func test_grid_state_clone_is_independent() -> void:
	var grid := GridState.new()
	grid.size = Vector2i(1, 1)
	grid.cells = PackedInt32Array([GridState.CellType.EMPTY])
	grid.pheromone = PackedInt32Array([5])
	grid.cycle_index = PackedInt32Array([-1])

	var copy := grid.clone()
	copy.pheromone[0] = 99

	assert_eq(grid.pheromone[0], 5, "la piste d'origine ne doit pas changer")
	assert_eq(copy.pheromone[0], 99)

func test_counters_clone_is_independent() -> void:
	var original := Counters.new()
	original.exited = 2
	var copy := original.clone()
	copy.exited = 7

	assert_eq(original.exited, 2)
	assert_eq(copy.exited, 7)

func test_sim_state_clone_deep_copies_everything() -> void:
	var state := SimState.new()
	state.tick = 10
	state.grid = GridState.new()
	state.grid.size = Vector2i(1, 1)
	state.grid.cells = PackedInt32Array([0])
	state.grid.pheromone = PackedInt32Array([0])
	state.grid.cycle_index = PackedInt32Array([-1])
	state.counters = Counters.new()
	state.agents = [AgentState.new()]
	state.agents[0].id = 0
	state.rule_params = RuleParams.new()

	var copy := state.clone()
	copy.tick = 11
	copy.agents[0].pos = Vector2i(4, 4)
	copy.counters.exited = 1
	copy.grid.pheromone[0] = 3

	assert_eq(state.tick, 10, "l'état t reste en lecture seule (DT-08)")
	assert_eq(state.agents[0].pos, Vector2i.ZERO)
	assert_eq(state.counters.exited, 0)
	assert_eq(state.grid.pheromone[0], 0)
	assert_same(copy.rule_params, state.rule_params, "rule_params est une config immuable partagée, pas clonée")
