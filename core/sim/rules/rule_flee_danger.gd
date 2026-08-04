class_name RuleFleeDanger
extends Rule
## R02 — Fuir le rouge [CDC §7.2] : l'agent s'éloigne du danger le plus
## proche s'il est à portée de perception ⚙️
## (RuleParams.flee_perception_range_sq, data/rules.json).
##
## « Danger » couvre STATIC_DANGER et CYCLIC_DANGER, actif ou non : un cycle
## est visible et prévisible (RG-08), un agent peut donc raisonnablement fuir
## par anticipation une case dangereuse même momentanément inactive. Décision
## documentée, non explicitement tranchée par le CDC/DCT.
##
## Portée de perception en carré de distance euclidienne (dx*dx + dy*dy,
## DT-04, pas de sqrt) ; direction choisie par distance de Manhattan (la
## métrique pertinente pour un déplacement à quatre directions).

const _NOT_FOUND := Vector2i(-1, -1)

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	var target: Vector2i = _nearest_danger(agent.pos, state.grid)
	if target == _NOT_FOUND:
		return ABSTAIN

	var dx: int = target.x - agent.pos.x
	var dy: int = target.y - agent.pos.y
	if dx * dx + dy * dy > params.flee_perception_range_sq:
		return ABSTAIN  # hors de portée de perception

	var current_dist: int = _manhattan(agent.pos, target)
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if state.grid.is_walkable(candidate) and _manhattan(candidate, target) > current_dist:
			return Directions.offset(dir)
	return ABSTAIN  # aucune direction franchissable n'éloigne (coincé)

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

## Renvoie le danger (statique ou cyclique) le plus proche de `from`, ou
## `_NOT_FOUND`. Égalité : premier rencontré par parcours ligne par ligne.
static func _nearest_danger(from: Vector2i, grid: GridState) -> Vector2i:
	var best: Vector2i = _NOT_FOUND
	var best_dist := -1
	for y in range(grid.size.y):
		for x in range(grid.size.x):
			var p := Vector2i(x, y)
			var t: int = grid.cell_type_at(p)
			if t == GridState.CellType.STATIC_DANGER or t == GridState.CellType.CYCLIC_DANGER:
				var d: int = _manhattan(from, p)
				if best == _NOT_FOUND or d < best_dist:
					best = p
					best_dist = d
	return best
