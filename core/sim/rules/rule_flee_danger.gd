class_name RuleFleeDanger
extends Rule
## R02 — Fuir le danger [CDC §7.2] : évaluation à l'instant d'arrivée (revue
## S3, option C). Un danger est MENAÇANT si sa case sera active au tick où
## un déplacement décidé maintenant prend effet (t+1) : statique = toujours,
## cyclique = selon sa phase à t+1 (RG-08 : le cycle est visible et
## prévisible). Un danger dormant qui le restera à t+1 n'exerce AUCUNE
## répulsion — la traversée en phase calme est un puzzle voulu. Formulable
## au joueur en une phrase : « je ne mets pas le pied là où ça brûlera
## quand j'y serai ».
##
## Trois comportements, dans cet ordre :
## 1. case courante létale à t+1 -> évacuation : première direction N>E>S>O
##    franchissable et non létale à t+1 (départage fixe, spécifié en revue) ;
## 2. menaçant le plus proche à portée ⚙️ (flee_perception_range_sq,
##    data/rules.json) -> fuite : première direction N>E>S>O franchissable,
##    non létale à t+1, qui éloigne (Manhattan) du menaçant ;
## 3. sinon ABSTAIN.
##
## R02 ÉVITE mais ne protège pas : la létalité effective reste l'affaire
## exclusive de l'étape 5 du pipeline — un agent sans R02 dans sa pile fonce
## dans le feu et meurt, c'est son rôle d'archétype (CDC §7.3).
##
## Portée de perception en carré de distance euclidienne (dx*dx + dy*dy,
## DT-04, pas de sqrt) ; direction choisie par distance de Manhattan (la
## métrique pertinente pour un déplacement à quatre directions).

const _NOT_FOUND := Vector2i(-1, -1)

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	var arrival_tick: int = state.tick + 1

	# 1. Évacuation : la case courante sera létale quand la décision prendra
	# effet — n'importe quelle case adjacente sûre, départage N>E>S>O.
	if state.grid.is_danger_active_at(agent.pos, arrival_tick):
		for dir in Directions.ORDER:
			var candidate: Vector2i = agent.pos + Directions.offset(dir)
			if state.grid.is_walkable(candidate) and not state.grid.is_danger_active_at(candidate, arrival_tick):
				return Directions.offset(dir)
		return ABSTAIN  # aucune issue sûre : la cascade continue, l'étape 5 tranchera

	# 2. Fuite du menaçant le plus proche, s'il est à portée de perception.
	var target: Vector2i = _nearest_threat(agent.pos, state.grid, arrival_tick)
	if target == _NOT_FOUND:
		return ABSTAIN
	var dx: int = target.x - agent.pos.x
	var dy: int = target.y - agent.pos.y
	if dx * dx + dy * dy > params.flee_perception_range_sq:
		return ABSTAIN  # hors de portée de perception

	var current_dist: int = _manhattan(agent.pos, target)
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if not state.grid.is_walkable(candidate):
			continue
		if state.grid.is_danger_active_at(candidate, arrival_tick):
			continue  # jamais un pas vers une case létale à l'arrivée
		if _manhattan(candidate, target) > current_dist:
			return Directions.offset(dir)
	return ABSTAIN  # aucune direction sûre n'éloigne (coincé)

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

## Renvoie le danger MENAÇANT (actif à `arrival_tick`) le plus proche de
## `from`, ou `_NOT_FOUND`. Égalité : premier rencontré ligne par ligne.
static func _nearest_threat(from: Vector2i, grid: GridState, arrival_tick: int) -> Vector2i:
	var best: Vector2i = _NOT_FOUND
	var best_dist := -1
	for y in range(grid.size.y):
		for x in range(grid.size.x):
			var p := Vector2i(x, y)
			if not grid.is_danger_active_at(p, arrival_tick):
				continue
			var d: int = _manhattan(from, p)
			if best == _NOT_FOUND or d < best_dist:
				best = p
				best_dist = d
	return best
