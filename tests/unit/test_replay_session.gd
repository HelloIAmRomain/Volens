extends GutTest
## Tests unitaires de la session de relecture (T-033, DT-11/DT-12) : la
## remontée du temps par re-simulation doit être indiscernable, à
## l'empreinte près, d'une avance directe.

func _corridor_level() -> Dictionary:
	return {
		"max_ticks": 200,
		"grid": {"size": [3, 12], "cells": [
			0, 9, 0,
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
			0, 3, 0,
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
		]},
		"agents": [{"pos": [0, 11]}, {"pos": [2, 11]}, {"pos": [1, 10]}],
	}

func _new_session(interval: int = 25) -> ReplaySession:
	var state := SimCore.load_level(_corridor_level(), RuleParams.new())
	var stack: Array[int] = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]
	return ReplaySession.new(state, stack, interval)

## Empreinte de référence au tick t par avance directe, sans session.
func _direct_hash_at(t: int) -> int:
	var state := SimCore.load_level(_corridor_level(), RuleParams.new())
	var stack: Array[int] = [RuleRegistry.R02_FLEE_DANGER, RuleRegistry.R01_TOWARD_LIGHT]
	for i in range(t):
		state = SimCore.step(state, stack)
	return SimCore.hash_state(state)

func test_step_forward_advances_one_tick() -> void:
	var session := _new_session()
	session.step_forward()
	assert_eq(session.current_tick(), 1)

func test_forward_run_matches_direct_simulation() -> void:
	var session := _new_session()
	for i in range(60):
		session.step_forward()
	assert_eq(SimCore.hash_state(session.current()), _direct_hash_at(60))

func test_seek_backward_reproduces_the_exact_state() -> void:
	var session := _new_session()
	for i in range(60):
		session.step_forward()

	session.seek(37)  # entre les clichés 25 et 50 : re-simulation de 12 ticks
	assert_eq(session.current_tick(), 37)
	assert_eq(SimCore.hash_state(session.current()), _direct_hash_at(37),
		"la remontée du temps est indiscernable d'une avance directe (DT-12)")

func test_seek_to_a_snapshot_tick_is_exact_too() -> void:
	var session := _new_session()
	for i in range(60):
		session.step_forward()

	session.seek(50)
	assert_eq(session.current_tick(), 50)
	assert_eq(SimCore.hash_state(session.current()), _direct_hash_at(50))

func test_seek_forward_beyond_current_advances() -> void:
	var session := _new_session()
	session.seek(42)
	assert_eq(session.current_tick(), 42)
	assert_eq(SimCore.hash_state(session.current()), _direct_hash_at(42))

func test_seek_zero_and_reset_return_to_the_initial_state() -> void:
	var session := _new_session()
	var initial_hash := SimCore.hash_state(session.current())
	for i in range(30):
		session.step_forward()

	session.seek(0)
	assert_eq(session.current_tick(), 0)
	assert_eq(SimCore.hash_state(session.current()), initial_hash)

	session.step_forward()
	session.reset()
	assert_eq(session.current_tick(), 0)
	assert_eq(SimCore.hash_state(session.current()), initial_hash, "réinitialisation (EF-04) : tick 0, pile conservée")

func test_seek_negative_clamps_to_zero() -> void:
	var session := _new_session()
	session.seek(-5)
	assert_eq(session.current_tick(), 0)

func test_snapshots_accumulate_at_the_interval() -> void:
	var session := _new_session(25)
	for i in range(100):
		session.step_forward()
	# Clichés attendus : 0, 25, 50, 75, 100.
	assert_eq(session.snapshot_count(), 5)

func test_seek_does_not_duplicate_snapshots() -> void:
	var session := _new_session(25)
	for i in range(100):
		session.step_forward()
	session.seek(10)
	session.seek(100)  # re-traverse 25/50/75/100 déjà archivés
	assert_eq(session.snapshot_count(), 5, "aucun doublon de cliché après re-simulation")

func test_mutating_the_callers_stack_does_not_affect_the_session() -> void:
	var state := SimCore.load_level(_corridor_level(), RuleParams.new())
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]
	var session := ReplaySession.new(state, stack)
	stack.append(RuleRegistry.R02_FLEE_DANGER)  # l'appelant modifie sa copie

	assert_eq(session.stack(), [RuleRegistry.R01_TOWARD_LIGHT] as Array[int],
		"la pile est figée à la création : nouvel essai = nouvelle session (RG-10)")

func test_mutating_the_callers_initial_state_does_not_affect_the_session() -> void:
	var state := SimCore.load_level(_corridor_level(), RuleParams.new())
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]
	var session := ReplaySession.new(state, stack)
	var before := SimCore.hash_state(session.current())
	state.agents[0].pos = Vector2i(2, 2)  # l'appelant abîme sa référence

	assert_eq(SimCore.hash_state(session.current()), before, "copie défensive à la création")