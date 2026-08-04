extends GutTest
## Tests unitaires de l'empreinte d'état FNV-1a (T-013).

func _make_state() -> SimState:
	var state := SimState.new()
	state.tick = 7
	state.max_ticks = 100
	state.outcome = SimState.Outcome.RUNNING
	state.counters = Counters.new()
	state.rule_params = RuleParams.new()
	state.grid = GridState.new()
	state.grid.size = Vector2i(2, 2)
	state.grid.cells = PackedInt32Array([0, 1, 9, 3])
	state.grid.pheromone = PackedInt32Array([0, 2, 0, 0])
	state.grid.cycle_index = PackedInt32Array([-1, -1, -1, -1])
	var cycle := CycleDef.new()
	cycle.period = 4
	cycle.active_ticks = 2
	state.grid.cycles = [cycle]
	state.agents = []
	for i in range(2):
		var agent := AgentState.new()
		agent.id = i
		agent.pos = Vector2i(i, 1)
		agent.dir = Directions.EAST
		agent.flags = AgentState.PRESENT
		state.agents.append(agent)
	return state

func test_hash_is_stable_across_two_computations() -> void:
	var state := _make_state()
	assert_eq(SimCore.hash_state(state), SimCore.hash_state(state))

func test_hash_is_identical_for_two_identically_built_states() -> void:
	assert_eq(SimCore.hash_state(_make_state()), SimCore.hash_state(_make_state()))

func test_clone_has_the_same_hash() -> void:
	var state := _make_state()
	assert_eq(SimCore.hash_state(state), SimCore.hash_state(state.clone()))

func test_hash_covers_every_significant_field() -> void:
	# Chaque champ signifiant muté isolément doit changer l'empreinte.
	var reference: int = SimCore.hash_state(_make_state())
	var mutations: Dictionary = {}

	var s := _make_state()
	s.tick += 1
	mutations["tick"] = SimCore.hash_state(s)

	s = _make_state()
	s.outcome = SimState.Outcome.WON
	mutations["outcome"] = SimCore.hash_state(s)

	s = _make_state()
	s.max_ticks += 1
	mutations["max_ticks"] = SimCore.hash_state(s)

	s = _make_state()
	s.agents[1].pos = Vector2i(1, 0)
	mutations["agent.pos"] = SimCore.hash_state(s)

	s = _make_state()
	s.agents[0].dir = Directions.SOUTH
	mutations["agent.dir"] = SimCore.hash_state(s)

	s = _make_state()
	s.agents[0].flags |= AgentState.PORTEUR
	mutations["agent.flags"] = SimCore.hash_state(s)

	s = _make_state()
	s.grid.cells[0] = 1
	mutations["grid.cells"] = SimCore.hash_state(s)

	s = _make_state()
	s.grid.pheromone[0] = 5
	mutations["grid.pheromone"] = SimCore.hash_state(s)

	s = _make_state()
	s.grid.cycle_index[0] = 0
	mutations["grid.cycle_index"] = SimCore.hash_state(s)

	s = _make_state()
	s.grid.cycles[0].period = 5
	mutations["cycle.period"] = SimCore.hash_state(s)

	s = _make_state()
	s.counters.exited = 1
	mutations["counters.exited"] = SimCore.hash_state(s)

	s = _make_state()
	s.counters.lost = 1
	mutations["counters.lost"] = SimCore.hash_state(s)

	s = _make_state()
	s.counters.delivered = 1
	mutations["counters.delivered"] = SimCore.hash_state(s)

	for field in ["tick", "outcome", "max_ticks", "agent.pos", "agent.dir",
			"agent.flags", "grid.cells", "grid.pheromone", "grid.cycle_index",
			"cycle.period", "counters.exited", "counters.lost", "counters.delivered"]:
		assert_ne(mutations[field], reference, "muter %s doit changer l'empreinte" % field)

func test_permuted_agent_positions_produce_a_different_hash() -> void:
	# L'ordre de parcours (id croissant) fait partie de l'empreinte : deux
	# nuées aux mêmes cases mais aux agents intervertis sont deux états
	# distincts.
	var a := _make_state()
	var b := _make_state()
	b.agents[0].pos = a.agents[1].pos
	b.agents[1].pos = a.agents[0].pos

	assert_ne(SimCore.hash_state(a), SimCore.hash_state(b))

func test_negative_values_are_hashed_by_bit_pattern() -> void:
	# cycle_index contient des -1 : l'absorption octet par octet masquée doit
	# les distinguer d'autres valeurs sans erreur de signe.
	var a := _make_state()
	var b := _make_state()
	b.grid.cycle_index[3] = 0

	assert_ne(SimCore.hash_state(a), SimCore.hash_state(b))

func test_to_hex_is_16_chars_and_unsigned() -> void:
	var state := _make_state()
	var hex := StateHash.to_hex(SimCore.hash_state(state))

	assert_eq(hex.length(), 16)
	assert_false(hex.begins_with("-"), "jamais de signe : motif binaire non signé")

func test_known_fnv1a_vector_for_a_single_zero_byte() -> void:
	# Vecteur de contrôle indépendant de notre code : FNV-1a 64 bits d'un
	# unique octet 0x00 = basis ^ 0x00 * prime = 0xAF63BD4C8601B7DF
	# (valeur publique de référence du FNV). Notre _feed_int absorbe 8
	# octets ; on vérifie donc l'étape élémentaire via la constante et une
	# multiplication enroulante.
	var h: int = (StateHash.OFFSET_BASIS ^ 0x00) * StateHash.PRIME
	assert_eq(StateHash.to_hex(h), "af63bd4c8601b7df")
