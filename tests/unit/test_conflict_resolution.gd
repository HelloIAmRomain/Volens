extends GutTest
## Tests de preuve de la résolution des conflits (revue S3, points 1.1, 2.4
## et déni en cascade) : le point fixe de SimCore._resolve_conflicts est
## indépendant de l'ordre des ids, résout tous les cycles fermés, et propage
## les refus comme les libérations.
##
## Rappel de géométrie : à pas cardinaux, chaque déplacement inverse la
## parité de (x + y) — le graphe des cases est biparti, donc tout cycle
## fermé d'agents est de longueur PAIRE. La « rotation à 3 agents » du type
## A→B→C→A n'existe pas ; la vraie configuration à 3 est la rotation autour
## d'un coin libre, qui est une chaîne.

const E := Vector2i(1, 0)
const W := Vector2i(-1, 0)
const N := Vector2i(0, -1)
const S := Vector2i(0, 1)
const STAY := Vector2i.ZERO

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

## Cases occupées, triées : l'invariant géométrique comparé entre deux
## déclarations d'agents dans des ordres différents.
func _occupied_cells(state: SimState) -> Array:
	var cells: Array = []
	for agent in state.agents:
		if agent.is_present():
			cells.append("%d,%d" % [agent.pos.x, agent.pos.y])
	cells.sort()
	return cells

## Colonne 1×5, lumière en haut : sous R01, chaque agent veut monter.
func _column_level(agent_positions: Array) -> Dictionary:
	var agents: Array = []
	for p in agent_positions:
		agents.append({"pos": p})
	return {
		"max_ticks": 50,
		"grid": {"size": [1, 5], "cells": [9, 0, 0, 0, 0]},
		"agents": agents,
	}

# --- 1.1 : indépendance à l'ordre des ids ----------------------------------

func test_chain_vacate_outcome_is_independent_of_id_order() -> void:
	# Preuve demandée en revue (1.1) : même configuration physique, ids
	# intervertis via l'ordre du fichier de niveau. Les empreintes brutes
	# diffèrent trivialement (l'id est haché) : c'est la GÉOMÉTRIE qui doit
	# être invariante — mêmes cases occupées à t+1, et les deux agents
	# avancent, quel que soit celui qui porte le plus petit id.
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]
	var a := SimCore.load_level(_column_level([[0, 2], [0, 3]]), RuleParams.new())
	var b := SimCore.load_level(_column_level([[0, 3], [0, 2]]), RuleParams.new())

	a = SimCore.step(a, stack)
	b = SimCore.step(b, stack)

	assert_eq(_occupied_cells(a), _occupied_cells(b), "l'ordre des ids ne change pas la géométrie")
	assert_eq(_occupied_cells(a), ["0,1", "0,2"], "libération en chaîne : les deux agents avancent")

# --- 2.4 : cycles fermés ----------------------------------------------------

func test_two_agents_swap_their_cells() -> void:
	var state := _make_state(2, 1, [Vector2i(0, 0), Vector2i(1, 0)])

	var granted := SimCore._resolve_conflicts(state, [E, W] as Array[Vector2i])

	assert_eq(granted, [E, W] as Array[Vector2i], "échange direct : aucune case n'est partagée à aucun instant")

func test_four_agents_rotate_around_a_square() -> void:
	# Le mécanisme de résolution est par revendications de cases, pas par
	# occupation : toute permutation sans case contestée passe. L'échange à
	# deux n'est PAS un cas particulier (revue 2.4).
	var state := _make_state(2, 2,
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)])

	var granted := SimCore._resolve_conflicts(state, [E, S, W, N] as Array[Vector2i])

	assert_eq(granted, [E, S, W, N] as Array[Vector2i], "rotation fermée à 4 : tous tournent")

func test_six_agents_rotate_around_a_ring() -> void:
	var state := _make_state(3, 2, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(1, 1), Vector2i(0, 1),
	])

	var granted := SimCore._resolve_conflicts(state, [E, E, S, W, W, N] as Array[Vector2i])

	assert_eq(granted, [E, E, S, W, W, N] as Array[Vector2i], "rotation fermée à 6 : tous tournent")

func test_three_agents_around_a_free_corner_resolve_as_a_chain() -> void:
	# Le « cycle à 3 » est géométriquement impossible (grille bipartie, voir
	# en-tête) : la configuration réelle à 3 agents est la rotation autour
	# d'un coin LIBRE — une chaîne, tous avancent.
	var state := _make_state(2, 2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)])

	var granted := SimCore._resolve_conflicts(state, [E, S, W] as Array[Vector2i])

	assert_eq(granted, [E, S, W] as Array[Vector2i])

# --- déni en cascade (ajout de revue) ----------------------------------------

func test_denial_cascades_when_the_cycle_head_abstains() -> void:
	# A vise la case de B, B vise la case de C, C reste immobile : C défend
	# sa case, B est refusé et redevient défenseur, A est refusé à son tour.
	# Le point fixe propage les REFUS, pas seulement les libérations — cette
	# configuration exige au moins deux passes.
	var state := _make_state(2, 2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)])

	var granted := SimCore._resolve_conflicts(state, [E, S, STAY] as Array[Vector2i])

	assert_eq(granted, [STAY, STAY, STAY] as Array[Vector2i], "le refus remonte la chaîne jusqu'à A")

func test_denial_cascade_is_independent_of_id_order() -> void:
	# Même configuration physique, agents déclarés dans l'ordre inverse :
	# même immobilité générale.
	var state := _make_state(2, 2, [Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 0)])

	var granted := SimCore._resolve_conflicts(state, [STAY, S, E] as Array[Vector2i])

	assert_eq(granted, [STAY, STAY, STAY] as Array[Vector2i])
