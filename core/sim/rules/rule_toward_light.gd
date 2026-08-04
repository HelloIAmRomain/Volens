class_name RuleTowardLight
extends Rule
## R01 — Vers la lumière [CDC §7.2] : l'agent se rapproche d'une case de la
## source de lumière la plus proche. Aucun ⚙️ de portée dans le CDC pour
## cette règle : la lumière la plus proche est toujours perçue, quelle que
## soit la distance.
##
## Distance en métrique de Manhattan (DT-04) : c'est la distance pertinente
## pour un déplacement à quatre directions, contrairement au carré de
## distance euclidienne (réservé aux portées de perception circulaires).

## Sentinelle « aucune lumière trouvée » : les positions de grille sont
## toujours >= 0, donc une coordonnée négative est un marqueur sûr — cela
## évite un type de retour Variant/nullable pour rester typé statiquement.
const _NOT_FOUND := Vector2i(-1, -1)

func evaluate(agent: AgentState, state: SimState, _params: RuleParams) -> Vector2i:
	var target: Vector2i = _nearest_light(agent.pos, state.grid)
	if target == _NOT_FOUND:
		return ABSTAIN

	var current_dist: int = _manhattan(agent.pos, target)
	if current_dist == 0:
		return ABSTAIN  # déjà sur la case cible, rien à rapprocher

	# Directions candidates dans l'ordre de départage fixe N > E > S > O
	# (DT-07) : la première direction franchissable qui réduit strictement
	# la distance l'emporte ; toutes bloquées -> abstention (voir Rule).
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if state.grid.is_walkable(candidate) and _manhattan(candidate, target) < current_dist:
			return Directions.offset(dir)
	return ABSTAIN  # aucune direction franchissable ne rapproche

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

## Renvoie la position de la source de lumière la plus proche de `from`, ou
## `_NOT_FOUND` s'il n'y en a aucune sur la grille. En cas d'égalité, la
## première rencontrée par un parcours ligne par ligne (y croissant, puis x
## croissant) l'emporte — déterministe, mais sans signification pour le joueur.
static func _nearest_light(from: Vector2i, grid: GridState) -> Vector2i:
	var best: Vector2i = _NOT_FOUND
	var best_dist := -1
	for y in range(grid.size.y):
		for x in range(grid.size.x):
			var p := Vector2i(x, y)
			if grid.cell_type_at(p) == GridState.CellType.LIGHT_SOURCE:
				var d: int = _manhattan(from, p)
				if best == _NOT_FOUND or d < best_dist:
					best = p
					best_dist = d
	return best
