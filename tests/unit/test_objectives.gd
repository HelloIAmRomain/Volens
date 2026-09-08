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
## Tests unitaires des objectifs de niveau (RG-15, RG-09) et de dynamics_hash.

func _make_state(width: int, height: int, agent_positions: Array) -> SimState:
	var state := SimState.new()
	state.counters = Counters.new()
	state.rule_params = RuleParams.new()
	state.grid = GridState.new()
	state.grid.size = Vector2i(width, height)
	var n := width * height
	state.grid.cells = PackedInt32Array()
	state.grid.cells.resize(n)
	state.grid.pheromone = PackedInt32Array()
	state.grid.pheromone.resize(n)
	state.grid.cycle_index = PackedInt32Array()
	state.grid.cycle_index.resize(n)
	for i in range(n):
		state.grid.cycle_index[i] = -1
	state.agents = []
	for i in range(agent_positions.size()):
		var agent := AgentState.new()
		agent.id = i
		agent.pos = agent_positions[i]
		agent.flags = AgentState.PRESENT
		state.agents.append(agent)
	return state

func _extraction(percent: int) -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.type = ObjectiveDef.Type.EXTRACTION
	o.percent = percent
	return o

func _preservation(max_lost: int) -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.type = ObjectiveDef.Type.PRESERVATION
	o.max_lost = max_lost
	return o

func _mark_exited(state: SimState, agent_index: int) -> void:
	state.agents[agent_index].flags = AgentState.SORTI
	state.counters.exited += 1

func _mark_lost(state: SimState, agent_index: int) -> void:
	state.agents[agent_index].flags = AgentState.PERDU
	state.counters.lost += 1

# --- chargement -------------------------------------------------------------

func test_load_level_parses_objectives() -> void:
	var level_data := {
		"grid": {"size": [3, 3], "cells": []},
		"agents": [{"pos": [0, 0]}],
		"objectives": [
			{"type": "extraction", "percent": 60},
			{"type": "preservation", "max_lost": 2},
			{"type": "celerity", "max_ticks": 40},
			{"type": "interdiction", "cells": [[1, 1], [2, 2]]},
			{"type": "collect", "count": 3},
			{"type": "type_inconnu"},
		],
	}
	var state := SimCore.load_level(level_data, RuleParams.new())

	assert_eq(state.objectives.size(), 5, "le type inconnu est ignoré")
	assert_eq(state.objectives[0].type, ObjectiveDef.Type.EXTRACTION)
	assert_eq(state.objectives[0].percent, 60)
	assert_eq(state.objectives[3].cells[0], state.grid.index_of(Vector2i(1, 1)))
	assert_true(state.objectives[0].is_achievement())
	assert_false(state.objectives[1].is_achievement())

# --- extraction ---------------------------------------------------------------

func test_extraction_win_at_exact_threshold() -> void:
	# 3 sortis sur 5 = 60 % : le seuil exact gagne (comparaison entière).
	var state := _make_state(5, 5, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	state.objectives = [_extraction(60)]
	for i in range(3):
		_mark_exited(state, i)

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.WON)

func test_extraction_not_won_below_threshold() -> void:
	var state := _make_state(5, 5, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	state.objectives = [_extraction(60)]
	for i in range(2):
		_mark_exited(state, i)

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.RUNNING)

func test_extraction_becomes_unattainable_when_too_many_are_lost() -> void:
	# 60 % de 5 = 3 requis ; 3 perdus -> 2 candidats restants au mieux : LOST
	# immédiat (RG-09), sans attendre la limite de ticks.
	var state := _make_state(5, 5, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	state.objectives = [_extraction(60)]
	for i in range(3):
		_mark_lost(state, i)

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST)

# --- préservation ---------------------------------------------------------------

func test_preservation_tolerates_losses_up_to_k() -> void:
	var state := _make_state(5, 5, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	state.objectives = [_preservation(1)]
	_mark_lost(state, 0)

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.RUNNING, "lost == max_lost : encore toléré")

func test_preservation_violated_loses_immediately() -> void:
	var state := _make_state(5, 5, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	state.objectives = [_preservation(1)]
	_mark_lost(state, 0)
	_mark_lost(state, 1)

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST)

# --- objectif composé (RG-16) ----------------------------------------------------

func test_composed_objective_requires_both() -> void:
	# Extraction 60 % + préservation 1 : la contrainte violée prime, même si
	# l'extraction est acquise au même tick.
	var state := _make_state(5, 5, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	state.objectives = [_extraction(60), _preservation(1)]
	for i in range(3):
		_mark_exited(state, i)
	_mark_lost(state, 3)
	_mark_lost(state, 4)

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST, "la contrainte violée prime sur l'accomplissement")

# --- célérité --------------------------------------------------------------------

func test_celerity_win_on_the_wire_is_won() -> void:
	# Revue S3 (2.2) : la célérité est une ÉCHÉANCE (tick <= T), pas un
	# événement — gagner AU tick exact de la borne est gagné. « Je passe sur
	# le fil » est l'une des meilleures sensations du genre (ENF-04).
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	state.objectives = [_extraction(100)]
	var celerity := ObjectiveDef.new()
	celerity.type = ObjectiveDef.Type.CELERITY
	celerity.max_ticks = 10
	state.objectives.append(celerity)
	_mark_exited(state, 0)
	state.tick = 10

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.WON, "victoire évaluée avant l'échéance de célérité")

func test_event_constraint_still_beats_victory_at_the_same_tick() -> void:
	# Contre-borne de la précédente : préservation et interdiction restent
	# des ÉVÉNEMENTS — au tick d'égalité, la violation prime la victoire.
	var state := _make_state(5, 5, [Vector2i(0, 0), Vector2i(1, 0)])
	state.objectives = [_extraction(50), _preservation(0)]
	_mark_exited(state, 0)  # extraction 50 % atteinte...
	_mark_lost(state, 1)    # ...mais une perte au même tick

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST, "l'événement prime, l'échéance non")

func test_celerity_loses_at_its_own_bound_before_level_limit() -> void:
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	state.max_ticks = 100
	state.objectives = [_extraction(100)]
	var celerity := ObjectiveDef.new()
	celerity.type = ObjectiveDef.Type.CELERITY
	celerity.max_ticks = 10
	state.objectives.append(celerity)
	state.tick = 10

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST)

# --- interdiction -----------------------------------------------------------------

func test_interdiction_loses_when_an_agent_enters_the_zone() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	var forbidden := ObjectiveDef.new()
	forbidden.type = ObjectiveDef.Type.INTERDICTION
	forbidden.cells = PackedInt32Array([state.grid.index_of(Vector2i(1, 1))])
	state.objectives = [forbidden]

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST)

func test_interdiction_ignores_absent_agents() -> void:
	var state := _make_state(3, 3, [Vector2i(1, 1)])
	state.agents[0].flags = AgentState.SORTI  # plus présent
	var forbidden := ObjectiveDef.new()
	forbidden.type = ObjectiveDef.Type.INTERDICTION
	forbidden.cells = PackedInt32Array([state.grid.index_of(Vector2i(1, 1))])
	state.objectives = [forbidden]

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.RUNNING)

# --- collect (inatteignable tant que R11/R12 n'existent pas) -----------------------

func test_collect_unattainable_without_resources_loses() -> void:
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	var collect := ObjectiveDef.new()
	collect.type = ObjectiveDef.Type.COLLECT
	collect.count = 2
	state.objectives = [collect]

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST, "aucune ressource sur la grille : inatteignable")

func test_collect_still_running_while_stock_suffices() -> void:
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	state.grid.cells[state.grid.index_of(Vector2i(2, 2))] = GridState.CellType.RESOURCE
	state.grid.cells[state.grid.index_of(Vector2i(2, 1))] = GridState.CellType.RESOURCE
	var collect := ObjectiveDef.new()
	collect.type = ObjectiveDef.Type.COLLECT
	collect.count = 2
	state.objectives = [collect]

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.RUNNING)

# --- sans accomplissement -----------------------------------------------------------

func test_level_without_achievement_objective_is_never_won() -> void:
	var state := _make_state(3, 3, [Vector2i(0, 0)])
	state.objectives = [_preservation(5)]
	state.max_ticks = 2
	state.tick = 2

	SimCore._evaluate_outcome(state)
	assert_eq(state.outcome, SimState.Outcome.LOST, "seule la limite de ticks tranche")

# --- intégration : victoire via le pipeline complet ----------------------------------

func test_full_pipeline_win_by_walking_into_the_exit() -> void:
	# Couloir : agent, sortie, lumière derrière la sortie. R01 pousse l'agent
	# à travers la sortie -> extraction 100 % -> WON, puis l'issue est figée.
	var level_data := {
		"max_ticks": 20,
		"grid": {"size": [5, 1], "cells": [0, 0, 2, 0, 9]},
		"agents": [{"pos": [0, 0]}],
		"objectives": [{"type": "extraction", "percent": 100}],
	}
	var state := SimCore.load_level(level_data, RuleParams.new())
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]

	var won_at := -1
	for i in range(10):
		state = SimCore.step(state, stack)
		if state.outcome == SimState.Outcome.WON and won_at == -1:
			won_at = state.tick

	assert_eq(state.outcome, SimState.Outcome.WON)
	assert_eq(won_at, 2, "sortie atteinte au tick 2 (2 pas)")
	assert_eq(state.counters.exited, 1)

# --- empreinte : objectifs exclus, dynamics_hash -------------------------------------

func test_objectives_are_excluded_from_the_hash() -> void:
	var a := _make_state(3, 3, [Vector2i(0, 0)])
	var b := _make_state(3, 3, [Vector2i(0, 0)])
	b.objectives = [_extraction(50)]

	assert_eq(SimCore.hash_state(a), SimCore.hash_state(b),
		"les objectifs sont de la configuration, pas de l'état simulé")

func test_dynamics_hash_ignores_tick_but_not_positions() -> void:
	var a := _make_state(3, 3, [Vector2i(0, 0)])
	var b := _make_state(3, 3, [Vector2i(0, 0)])
	b.tick = 42
	assert_eq(StateHash.dynamics_hash(a), StateHash.dynamics_hash(b), "le tick est ignoré")
	assert_ne(SimCore.hash_state(a), SimCore.hash_state(b), "l'empreinte complète, elle, le voit")

	b.agents[0].pos = Vector2i(1, 1)
	assert_ne(StateHash.dynamics_hash(a), StateHash.dynamics_hash(b), "les positions comptent")
