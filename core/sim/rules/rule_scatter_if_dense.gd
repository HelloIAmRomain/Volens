class_name RuleScatterIfDense
extends Rule
## R14 — Disperser si dense [CDC §7.2] : l'agent quitte les zones où la densité
## locale dépasse un seuil ⚙️ (`RuleParams.dense_range_sq`,
## `RuleParams.dense_max_neighbours`).
##
## EN QUOI ELLE DIFFÈRE DE R04 « S'ÉCARTER », et pourquoi les deux existent.
## La question est légitime : les deux comptent des voisins et s'éloignent.
##
## | | R04 s'écarter | R14 disperser si dense |
## |---|---|---|
## | portée | **adjacence** (d² ≤ 2) | **zone** (d² ≤ 9 ⚙️) |
## | ce qu'elle voit | le contact | l'attroupement |
## | direction | s'éloigne du barycentre serré | s'éloigne de la case la plus PEUPLÉE |
## | à quoi elle sert | desserrer un goulot | vider une région |
##
## R04 traite le coude-à-coude et rend une case ; R14 traite la foule et rend
## un quartier. Une nuée peut être partout adjacente sans être dense — un
## cordon d'une case de large — et partout dense sans être adjacente — un nuage
## lâche mais nombreux. Les deux règles se déclenchent donc sur des formes
## différentes, ce qu'un niveau doit rendre visible plutôt que d'espérer.
##
## ELLE FUIT LE PLUS PEUPLÉ, PAS LE BARYCENTRE, et c'est ce qui la rend lisible
## sur une foule : le barycentre d'un attroupement en fer à cheval tombe dans
## le vide au milieu, et s'en éloigner enverrait les agents vers l'extérieur du
## fer — c'est-à-dire vers les branches, les plus peuplées de toutes. On compte
## donc, pour chaque case candidate, combien de congénères l'entourent, et l'on
## va vers la MOINS entourée.
##
## LE CAS D'ÉPREUVE (invariant n°12) est la NUÉE EN FER À CHEVAL, précisément
## parce qu'elle sépare R14 d'une simple répulsion barycentrique. Sur un bloc
## compact, les deux formulations donnent le même pas et le test ne prouve rien.

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	var here: int = _crowd_around(agent, state, agent.pos, params.dense_range_sq)
	if here < params.dense_max_neighbours:
		return ABSTAIN  # pas assez dense : la règle suivante décide

	var best_dir: int = -1
	var best_crowd: int = here   # il faut faire STRICTEMENT mieux que sur place
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if not state.grid.can_traverse(agent.pos, candidate):
			continue
		var crowd: int = _crowd_around(agent, state, candidate, params.dense_range_sq)
		if crowd < best_crowd:
			best_crowd = crowd
			best_dir = dir
	if best_dir < 0:
		return ABSTAIN  # nulle part où respirer : la règle suivante décide
	return Directions.offset(best_dir)

## Congénères présents dans le rayon autour de `centre`, l'agent lui-même exclu.
static func _crowd_around(agent: AgentState, state: SimState, centre: Vector2i,
		range_sq: int) -> int:
	var count := 0
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - centre.x
		var dy: int = other.pos.y - centre.y
		if dx * dx + dy * dy <= range_sq:
			count += 1
	return count
