class_name SimState
extends RefCounted
## État complet et immuable d'un tick de simulation [DCT §4.1]. Trivialement
## sérialisable (types entiers, Vector2i, tableaux) — condition des
## clichés-clés (replay) et de l'empreinte (T-013).
##
## Invariant : agents[i].id == i pour tout i (ordre = identifiant, DT-07).
## Un agent n'est jamais retiré du tableau ; sa sortie/perte se lit sur ses
## drapeaux (AgentState.SORTI / PERDU / présence de PRESENT).

enum Outcome { RUNNING, WON, LOST }

var tick: int = 0
var agents: Array[AgentState] = []
var grid: GridState
var counters: Counters
var outcome: int = Outcome.RUNNING

## Limite de ticks du niveau (RG-09) ; configuration de niveau, pas un
## paramètre d'équilibrage des règles.
var max_ticks: int = 0

## Paramètres des règles [DT-10], partagés par référence : configuration
## immuable, jamais mutée pendant un tick, donc pas besoin d'être clonée.
var rule_params: RuleParams

## Objectifs du niveau [RG-15], configuration immuable partagée par
## référence (comme rule_params) et exclue de l'empreinte : leurs effets
## s'observent dans counters et outcome.
var objectives: Array[ObjectiveDef] = []

## Copie profonde explicite pour le double tampon (T-010) : `state` (t) reste
## en lecture seule pendant tout le tick pendant que `step()` construit t+1
## à partir de cette copie (DT-08).
func clone() -> SimState:
	var copy := SimState.new()
	copy.tick = tick
	copy.agents = []
	for a in agents:
		copy.agents.append(a.clone())
	copy.grid = grid.clone()
	copy.counters = counters.clone()
	copy.outcome = outcome
	copy.max_ticks = max_ticks
	copy.rule_params = rule_params
	copy.objectives = objectives
	return copy
