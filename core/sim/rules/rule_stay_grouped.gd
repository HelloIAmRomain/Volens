class_name RuleStayGrouped
extends Rule
## R03 — Rester groupé [CDC §7.2] : l'agent se rapproche du centre de
## gravité de ses voisins perçus ⚙️ (RuleParams.group_perception_range_sq).
##
## Aucune division flottante (invariant n°5 docs/ARCHITECTURE.md, DT-04). Le barycentre
## (sum_x/count, sum_y/count) n'est jamais calculé comme tel : comparer une
## position candidate au barycentre revient à comparer deux fractions de même
## dénominateur `count`. On compare donc les sommes mises à l'échelle par
## `count` — l'équivalent entier d'un produit croisé de comparaison de
## fractions — plutôt que de diviser : |p.x*count - sum_x| + |p.y*count - sum_y|.
## `count` est positif et constant pour tous les candidats d'un même agent à
## un même tick, donc cette mise à l'échelle préserve l'ordre des distances.

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	var sum_x := 0
	var sum_y := 0
	var count := 0
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - agent.pos.x
		var dy: int = other.pos.y - agent.pos.y
		if dx * dx + dy * dy > params.group_perception_range_sq:
			continue
		sum_x += other.pos.x
		sum_y += other.pos.y
		count += 1

	if count == 0:
		return ABSTAIN  # aucun voisin perçu

	var current_dist: int = _scaled_distance(agent.pos, sum_x, sum_y, count)
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if state.grid.is_walkable(candidate) and _scaled_distance(candidate, sum_x, sum_y, count) < current_dist:
			return Directions.offset(dir)
	return ABSTAIN  # déjà au plus près (franchissable) du barycentre perçu

static func _scaled_distance(p: Vector2i, sum_x: int, sum_y: int, count: int) -> int:
	return absi(p.x * count - sum_x) + absi(p.y * count - sum_y)
