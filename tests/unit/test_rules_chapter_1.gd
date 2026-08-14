extends GutTest
## Tests unitaires des trois règles du chapitre 1 (T-012) : cas nominal,
## bord de grille, conflit de case, abstention — et cascade de la pile.

var _params: RuleParams

func before_each() -> void:
	_params = RuleParams.new()
	_params.flee_perception_range_sq = 25
	_params.group_perception_range_sq = 16

func _make_grid(width: int, height: int) -> GridState:
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
	state.counters = Counters.new()
	state.rule_params = _params
	state.grid = _make_grid(width, height)
	state.agents = []
	for i in range(agent_positions.size()):
		var agent := AgentState.new()
		agent.id = i
		agent.pos = agent_positions[i]
		agent.flags = AgentState.PRESENT
		state.agents.append(agent)
	return state

func _set_cell(state: SimState, pos: Vector2i, cell_type: int) -> void:
	state.grid.cells[state.grid.index_of(pos)] = cell_type

# --- R01 : vers la lumière -------------------------------------------------

func test_toward_light_moves_closer_nominal() -> void:
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	_set_cell(state, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)
	var rule := RuleTowardLight.new()

	# Lumière au nord : Nord réduit la distance et est premier dans l'ordre.
	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.NORTH))

func test_toward_light_tie_break_follows_north_east_order() -> void:
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	# Lumière en diagonale nord-est : Nord et Est réduisent tous deux la
	# distance de Manhattan — Nord doit gagner (N > E > S > O, DT-07).
	_set_cell(state, Vector2i(4, 0), GridState.CellType.LIGHT_SOURCE)
	var rule := RuleTowardLight.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.NORTH))

func test_toward_light_picks_nearest_of_two_lights() -> void:
	var state := _make_state(7, 1, [Vector2i(2, 0)])
	_set_cell(state, Vector2i(0, 0), GridState.CellType.LIGHT_SOURCE)  # distance 2
	_set_cell(state, Vector2i(6, 0), GridState.CellType.LIGHT_SOURCE)  # distance 4
	var rule := RuleTowardLight.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.WEST))

func test_toward_light_abstains_without_any_light() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	var rule := RuleTowardLight.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_toward_light_abstains_on_the_light_cell_itself() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	_set_cell(state, Vector2i(1, 1), GridState.CellType.LIGHT_SOURCE)
	var rule := RuleTowardLight.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_toward_light_at_grid_edge_skips_blocked_directions() -> void:
	# L'agent est au coin : les règles sont conscientes des murs et de la
	# bordure (voir Rule) — Nord (hors grille) est ignoré, Est rapproche.
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	_set_cell(state, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)
	var rule := RuleTowardLight.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.EAST))

func test_toward_light_abstains_when_walled_in() -> void:
	# Couloir 1 case : l'agent est emmuré, aucune direction franchissable ne
	# rapproche -> abstention (« mouvement bloqué », DCT §4.2), la cascade
	# passerait à la règle suivante.
	var state := _make_state(3, 1, [Vector2i(0, 0)])
	_set_cell(state, Vector2i(1, 0), GridState.CellType.WALL)
	_set_cell(state, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)
	var rule := RuleTowardLight.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

# --- R02 : fuir le rouge -----------------------------------------------------

func test_flee_danger_moves_away_nominal() -> void:
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	_set_cell(state, Vector2i(2, 4), GridState.CellType.STATIC_DANGER)
	var rule := RuleFleeDanger.new()

	# Danger au sud, à portée (d²=4 ≤ 25) : Nord éloigne et est premier.
	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.NORTH))

func test_flee_danger_abstains_when_danger_is_out_of_range() -> void:
	var state := _make_state(20, 1, [Vector2i(0, 0)])
	_set_cell(state, Vector2i(10, 0), GridState.CellType.STATIC_DANGER)  # d²=100 > 25
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_flee_danger_abstains_without_any_danger() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

# --- R02, option C (revue S3, 2.1) : évaluation à l'instant d'arrivée -----

## Pose un danger cyclique et son CycleDef sur la case donnée.
func _set_cyclic(state: SimState, pos: Vector2i, period: int, active_ticks: int) -> void:
	_set_cell(state, pos, GridState.CellType.CYCLIC_DANGER)
	var cycle := CycleDef.new()
	cycle.period = period
	cycle.active_ticks = active_ticks
	state.grid.cycles.append(cycle)
	state.grid.cycle_index[state.grid.index_of(pos)] = state.grid.cycles.size() - 1

func test_flee_danger_flees_cyclic_danger_active_at_arrival() -> void:
	# Période 6, actif aux phases 0-2. Décision au tick 5 : arrivée au tick 6,
	# phase 0 -> actif. Le danger est dormant MAINTENANT mais menaçant à
	# l'arrivée : il se fuit (« je ne mets pas le pied là où ça brûlera
	# quand j'y serai »).
	var state := _make_state(5, 1, [Vector2i(1, 0)])
	_set_cyclic(state, Vector2i(0, 0), 6, 3)
	state.tick = 5
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.EAST))

func test_flee_danger_ignores_cyclic_danger_dormant_at_arrival() -> void:
	# Décision au tick 2 : le danger est actif MAINTENANT (phase 2) mais
	# dormant à l'arrivée (phase 3) -> aucune répulsion, la traversée en
	# phase calme est un puzzle voulu (option C, ni option A ni option B).
	var state := _make_state(5, 1, [Vector2i(1, 0)])
	_set_cyclic(state, Vector2i(0, 0), 6, 3)
	state.tick = 2
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_flee_danger_evacuates_own_cell_lethal_at_arrival_north_first() -> void:
	# L'agent est SUR une case qui sera létale à l'arrivée : évacuation vers
	# n'importe quelle adjacente sûre, départage N>E>S>O (spécifié en revue).
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	_set_cyclic(state, Vector2i(2, 2), 6, 3)
	state.tick = 5  # arrivée au tick 6, phase 0 -> sa case s'allume
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.NORTH))

func test_flee_danger_evacuation_skips_unsafe_neighbours() -> void:
	# Même évacuation, mais le Nord est un danger statique (létal à
	# l'arrivée) : première direction sûre suivante -> Est.
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	_set_cyclic(state, Vector2i(2, 2), 6, 3)
	_set_cell(state, Vector2i(2, 1), GridState.CellType.STATIC_DANGER)
	state.tick = 5
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.EAST))

func test_flee_danger_abstains_when_no_safe_evacuation_exists() -> void:
	# Case courante létale à l'arrivée, voisines toutes létales ou hors
	# grille : ABSTAIN — R02 évite mais ne protège pas, l'étape 5 tranchera.
	var state := _make_state(3, 1, [Vector2i(1, 0)])
	_set_cyclic(state, Vector2i(1, 0), 6, 3)
	_set_cell(state, Vector2i(0, 0), GridState.CellType.STATIC_DANGER)
	_set_cell(state, Vector2i(2, 0), GridState.CellType.STATIC_DANGER)
	state.tick = 5
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_flee_danger_never_steps_onto_a_cell_lethal_at_arrival() -> void:
	# Fuite du danger statique à l'ouest : la seule direction qui éloigne
	# (Est) sera létale à l'arrivée -> ABSTAIN plutôt qu'un pas dans le feu.
	var state := _make_state(8, 1, [Vector2i(1, 0)])
	_set_cell(state, Vector2i(0, 0), GridState.CellType.STATIC_DANGER)
	_set_cyclic(state, Vector2i(2, 0), 6, 3)
	state.tick = 5  # arrivée phase 0 -> la case (2,0) s'allume
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_flee_danger_range_boundary_is_inclusive() -> void:
	_params.flee_perception_range_sq = 4
	var state := _make_state(8, 1, [Vector2i(1, 0)])
	_set_cell(state, Vector2i(3, 0), GridState.CellType.STATIC_DANGER)  # d²=4, exactement à portée
	var rule := RuleFleeDanger.new()

	# Perçu (d² == portée², borne incluse) et la fuite vers l'ouest est libre.
	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.WEST), "d² == portée² : encore perçu")

func test_flee_danger_abstains_just_beyond_the_range_boundary() -> void:
	_params.flee_perception_range_sq = 4
	var state := _make_state(8, 1, [Vector2i(1, 0)])
	_set_cell(state, Vector2i(4, 0), GridState.CellType.STATIC_DANGER)  # d²=9 > 4
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_flee_danger_at_grid_corner_takes_the_first_walkable_escape() -> void:
	# Agent au coin (0,0), danger adjacent à l'est : Nord est hors grille
	# (ignoré), Est n'éloigne pas — Sud est la première direction
	# franchissable qui éloigne (N > E > S > O).
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	_set_cell(state, Vector2i(1, 0), GridState.CellType.STATIC_DANGER)
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.SOUTH))

func test_flee_danger_abstains_when_cornered_with_no_escape() -> void:
	# Cul-de-sac 2×1 : le danger occupe l'autre case, tout le reste est
	# bordure -> abstention (« mouvement bloqué »), pas d'oscillation.
	var state := _make_state(2, 1, [Vector2i(0, 0)])
	_set_cell(state, Vector2i(1, 0), GridState.CellType.STATIC_DANGER)
	var rule := RuleFleeDanger.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

# --- R03 : rester groupé ------------------------------------------------------

func test_stay_grouped_moves_toward_the_barycenter_nominal() -> void:
	var state := _make_state(7, 7, [Vector2i(1, 3), Vector2i(4, 3), Vector2i(4, 5)])
	var rule := RuleStayGrouped.new()

	# Agent 0 en (1,3) ; voisins perçus (rayon²=16) : (4,3) d²=9, (4,5) d²=13.
	# Barycentre (4,4) : Est réduit la distance mise à l'échelle, Nord non.
	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.EAST))

func test_stay_grouped_abstains_when_alone() -> void:
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	var rule := RuleStayGrouped.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_stay_grouped_abstains_when_neighbors_are_out_of_range() -> void:
	var state := _make_state(20, 1, [Vector2i(0, 0), Vector2i(10, 0)])  # d²=100 > 16
	var rule := RuleStayGrouped.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_stay_grouped_ignores_absent_agents() -> void:
	var state := _make_state(5, 5, [Vector2i(2, 2), Vector2i(2, 4)])
	state.agents[1].flags = AgentState.PERDU  # plus PRESENT
	var rule := RuleStayGrouped.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN, "un agent perdu n'est plus un voisin")

func test_stay_grouped_abstains_at_the_barycenter() -> void:
	# Agent 0 exactement au barycentre de ses deux voisins : aucun candidat
	# ne réduit strictement la distance -> abstention (pas d'oscillation).
	var state := _make_state(5, 5, [Vector2i(2, 2), Vector2i(1, 2), Vector2i(3, 2)])
	var rule := RuleStayGrouped.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Rule.ABSTAIN)

func test_stay_grouped_integer_barycenter_no_float_drift() -> void:
	# Barycentre fractionnaire (1/3) : la comparaison par sommes mises à
	# l'échelle doit trancher sans division. Voisins en (0,0) et (1,0) :
	# barycentre x=0,5 — depuis (3,0), Ouest doit réduire.
	var state := _make_state(6, 1, [Vector2i(3, 0), Vector2i(0, 0), Vector2i(1, 0)])
	var rule := RuleStayGrouped.new()

	assert_eq(rule.evaluate(state.agents[0], state, _params), Directions.offset(Directions.WEST))

# --- Cascade de la pile (règle d'or) -----------------------------------------

func test_stack_first_applicable_rule_wins() -> void:
	# Danger à portée ET lumière présente : Fuir avant Lumière -> l'agent fuit.
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	_set_cell(state, Vector2i(2, 4), GridState.CellType.STATIC_DANGER)
	_set_cell(state, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)

	var flee_first: Array[int] = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]
	var dirs: Array = SimCore._decide_agents(state, flee_first)["directions"]
	assert_eq(dirs[0], Directions.offset(Directions.NORTH), "R02 s'applique en premier")

func test_stack_falls_through_an_abstaining_rule() -> void:
	# Aucun danger : R02 s'abstient, R01 prend la main.
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	_set_cell(state, Vector2i(2, 4), GridState.CellType.LIGHT_SOURCE)

	var stack: Array[int] = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]
	var dirs: Array = SimCore._decide_agents(state, stack)["directions"]
	assert_eq(dirs[0], Directions.offset(Directions.SOUTH), "R02 abstenue, R01 décide")

func test_stack_order_changes_behavior() -> void:
	# La leçon centrale du jeu (CDC §8.5 niveau 2) : inverser deux règles
	# change le mouvement. Danger au sud à portée, lumière au sud aussi.
	var state := _make_state(5, 9, [Vector2i(2, 4)])
	_set_cell(state, Vector2i(2, 6), GridState.CellType.STATIC_DANGER)
	_set_cell(state, Vector2i(2, 8), GridState.CellType.LIGHT_SOURCE)

	var flee_first: Array[int] = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]
	var light_first: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT, RuleRegistry.R02_FLEE_DANGER]

	var flee_dirs: Array = SimCore._decide_agents(state, flee_first)["directions"]
	var light_dirs: Array = SimCore._decide_agents(state, light_first)["directions"]

	assert_eq(flee_dirs[0], Directions.offset(Directions.NORTH), "prudent : fuit le danger")
	assert_eq(light_dirs[0], Directions.offset(Directions.SOUTH), "pressé : fonce vers la lumière")
	assert_ne(flee_dirs[0], light_dirs[0], "l'ordre change tout")

func test_stack_with_empty_slots_and_no_applicable_rule_stays_still() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	var stack: Array[int] = [RuleRegistry.EMPTY, RuleRegistry.R02_FLEE_DANGER, RuleRegistry.EMPTY, RuleRegistry.EMPTY]

	var dirs: Array = SimCore._decide_agents(state, stack)["directions"]
	assert_eq(dirs[0], Vector2i.ZERO, "aucune règle applicable : immobile (RG-05)")

func test_full_step_with_rules_keeps_input_state_untouched() -> void:
	var state := _make_state(5, 5, [Vector2i(2, 2)])
	_set_cell(state, Vector2i(2, 0), GridState.CellType.LIGHT_SOURCE)
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]

	var next_state := SimCore.step(state, stack)

	assert_eq(state.agents[0].pos, Vector2i(2, 2), "l'état t reste intact (DT-08)")
	assert_eq(next_state.agents[0].pos, Vector2i(2, 1), "l'agent a avancé vers la lumière dans t+1")
	assert_eq(next_state.agents[0].dir, Directions.NORTH)

func test_two_agents_conflict_through_the_full_pipeline() -> void:
	# Deux agents équidistants d'une même lumière convergent sur la même
	# case : le plus petit id l'emporte, l'autre reste immobile (RG-06).
	var state := _make_state(3, 3, [Vector2i(0, 1), Vector2i(2, 1)])
	_set_cell(state, Vector2i(1, 1), GridState.CellType.LIGHT_SOURCE)
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]

	var next_state := SimCore.step(state, stack)

	assert_eq(next_state.agents[0].pos, Vector2i(1, 1), "id 0 gagne la case")
	assert_eq(next_state.agents[1].pos, Vector2i(2, 1), "id 1 reste sur place")
