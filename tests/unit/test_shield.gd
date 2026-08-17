extends GutTest
## LE BOUCLIER PROTÈGE, IL NE DÉTRUIT PAS.
##
## POURQUOI CE FICHIER. Le jeu n'avait qu'une façon de survivre à un danger :
## R13 « Boucher », où l'agent se consume et emporte le danger avec lui. C'est
## un SACRIFICE — « dans l'imaginaire collectif, un bouclier est un objet de
## défense, pas d'attaque ». Le bouclier encaisse un contact, se brise, et
## laisse le danger en place.
##
## LES QUATRE PROPRIÉTÉS QUI LE DÉFINISSENT, et chacune a son test :
##   1. la station équipe qui la traverse ;
##   2. le bouclier absorbe UN contact mortel — l'agent survit, rien n'est perdu ;
##   3. il se BRISE : le contact suivant tue ;
##   4. le danger reste ACTIF pour les autres — c'est ce qui le sépare de R13.

const GUARD := 60

func _grid_line(rows: Array) -> Dictionary:
	var cells: Array = []
	var width: int = String(rows[0]).length()
	for row in rows:
		for ch in String(row):
			match ch:
				"#": cells.append(GridState.CellType.WALL)
				"X": cells.append(GridState.CellType.STATIC_DANGER)
				"B": cells.append(GridState.CellType.SHIELD)
				"E": cells.append(GridState.CellType.EXIT)
				"L": cells.append(GridState.CellType.LIGHT_SOURCE)
				_: cells.append(GridState.CellType.EMPTY)
	return {"size": [width, rows.size()], "cells": cells}

## UN COULOIR VERTICAL, ET L'ORDRE DES CASES EST TOUT LE TEST : la lumière en
## haut, le DANGER au milieu, l'ATELIER en dessous. Un agent qui monte traverse
## donc l'atelier PUIS le danger. La première version plaçait l'atelier au-dessus
## du danger : l'agent s'équipait et ne rencontrait plus rien, le test passait à
## côté de ce qu'il prétendait vérifier.
func _level(agents: Array) -> Dictionary:
	return {
		"id": "test_shield",
		"max_ticks": 40,
		"slots": 3,
		"allowed_rules": [RuleRegistry.R01_TOWARD_LIGHT],
		"grid": _grid_line(["L", ".", "X", ".", "B", ".", "."]),
		"agents": agents,
		"objectives": [{"type": "extraction", "percent": 100}],
	}

func _run(level: Dictionary, ticks: int) -> SimState:
	var state := SimCore.load_level(level, RuleParams.new())
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]
	for i in range(ticks):
		if state.outcome != SimState.Outcome.RUNNING:
			break
		state = SimCore.step(state, stack)
	return state

func test_the_station_equips_whoever_crosses_it() -> void:
	# L'agent part de (0,5), monte vers la lumière et traverse l'atelier en (0,4).
	var state := _run(_level([{"pos": [0, 5]}]), 1)
	assert_eq(state.agents[0].pos, Vector2i(0, 4), "l'agent monte d'une case")
	assert_true((state.agents[0].flags & AgentState.PROTEGE) != 0,
		"traverser l'atelier équipe l'agent")

func test_an_unprotected_agent_dies_on_the_danger() -> void:
	# LE TÉMOIN : sans bouclier, le même danger tue. Sans lui, le test suivant ne
	# prouverait rien — il pourrait porter sur un danger qui ne tue personne.
	# L'agent part de (0,3), SOUS le danger et AU-DESSUS de l'atelier : il ne
	# s'équipe donc jamais.
	var state := _run(_level([{"pos": [0, 3]}]), 2)
	assert_eq(state.counters.lost, 1, "un agent non protégé meurt sur le danger")

func test_the_shield_absorbs_one_lethal_contact() -> void:
	# (0,5) → (0,4) atelier → (0,3) → (0,2) danger. Trois pas suffisent.
	var state := _run(_level([{"pos": [0, 5]}]), 3)
	assert_eq(state.counters.lost, 0,
		"un agent protégé ne meurt pas : le bouclier encaisse")
	assert_true(state.agents[0].is_present(), "et il est toujours en jeu")
	assert_eq(state.agents[0].flags & AgentState.PROTEGE, 0,
		"mais son bouclier s'est BRISÉ : il n'en a plus")

func test_the_danger_survives_the_shield() -> void:
	# LA PROPRIÉTÉ QUI SÉPARE LE BOUCLIER DU SACRIFICE. R13 « Boucher » neutralise
	# la case ; le bouclier ne touche pas au terrain. Un second agent, non
	# protégé, doit donc mourir exactement au même endroit.
	# Un agent équipé (parti de 0,5) et un autre qui ne l'est pas (parti de 0,3).
	var state := _run(_level([{"pos": [0, 5]}, {"pos": [0, 3]}]), 4)
	assert_eq(state.grid.cell_type_at(Vector2i(0, 2)),
		GridState.CellType.STATIC_DANGER,
		"le danger est intact — un bouclier ne nettoie pas la carte")
	assert_gt(state.counters.lost, 0,
		"et il tue encore : le second agent, sans bouclier, y reste")
