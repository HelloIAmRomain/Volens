class_name RuleExplainer
extends RefCounted
## Diagnostic EF-05 — « pourquoi cet agent a-t-il fait ça ? »
##
## C'est le pilier P4 rendu tangible : sans lui, un joueur qui échoue ne peut
## former aucune hypothèse, il abandonne, et l'on mesure sa patience au lieu
## de l'émergence.
##
## LECTURE SEULE, STRICTEMENT. Ce module n'écrit rien, ne décide rien, et
## n'est jamais consulté par la simulation. La règle qui a décidé est
## obtenue en interrogeant **les vraies règles** (`RuleRegistry`), jamais en
## réimplémentant leur logique (DT-15) : seule la *formulation du motif*
## d'abstention est déduite ici, à partir de requêtes sur l'état.
##
## Provisoire, et assumé comme tel : `SimCore.explain` (T-065, semaine 8)
## portera ce diagnostic dans `core/` avec les motifs produits par les règles
## elles-mêmes. D'ici là, cette version vit dans `game/ui/` pour ne pas
## toucher `core/` — donc pour ne pas risquer de déplacer une empreinte d'or.

## Renvoie : { "slot": int (-1 si aucune), "rule_id": int,
##             "proposed": Vector2i, "lines": Array[String] }
static func explain(agent: AgentState, state: SimState, stack: Array[int]) -> Dictionary:
	var lines: Array[String] = []
	var params := state.rule_params
	for i in range(stack.size()):
		var rule_id: int = stack[i]
		if rule_id == RuleRegistry.EMPTY:
			continue
		var rule := RuleRegistry.get_rule(rule_id)
		if rule == null:
			continue
		var result: Vector2i = rule.evaluate(agent, state, params)
		var label := "%d. %s" % [i + 1, RuleCatalog.name_of(rule_id)]
		if result != Rule.ABSTAIN:
			lines.append("%s → %s" % [label, _direction_name(result)])
			return {"slot": i, "rule_id": rule_id, "proposed": result, "lines": lines}
		lines.append("%s — %s" % [label, _abstention_reason(rule_id, agent, state, params)])
	lines.append("aucune règle ne s'applique → immobile")
	return {"slot": -1, "rule_id": RuleRegistry.EMPTY, "proposed": Vector2i.ZERO, "lines": lines}

## Motif d'abstention, formulé pour le joueur. Déduit de requêtes sur l'état,
## dans le même ordre que la règle elle-même les évalue.
static func _abstention_reason(rule_id: int, agent: AgentState, state: SimState, params: RuleParams) -> String:
	match rule_id:
		RuleRegistry.R01_TOWARD_LIGHT:
			var light := _nearest_cell(state.grid, GridState.CellType.LIGHT_SOURCE, agent.pos)
			if light.x < 0:
				return "aucune lumière sur la carte"
			if light == agent.pos:
				return "déjà sur la lumière"
			return "chemin vers la lumière bloqué"
		RuleRegistry.R02_FLEE_DANGER:
			var threat := _nearest_threat(state, agent.pos)
			if threat.x < 0:
				return "aucun danger menaçant"
			var dx: int = threat.x - agent.pos.x
			var dy: int = threat.y - agent.pos.y
			if dx * dx + dy * dy > params.flee_perception_range_sq:
				return "danger trop loin pour être perçu"
			return "nulle part où reculer"
		RuleRegistry.R03_STAY_GROUPED:
			if _perceived_neighbours(state, agent, params) == 0:
				return "aucun voisin perçu"
			return "déjà groupé"
	return "ne s'applique pas"

static func _nearest_cell(grid: GridState, cell_type: int, from: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := -1
	for y in range(grid.size.y):
		for x in range(grid.size.x):
			var p := Vector2i(x, y)
			if grid.cell_type_at(p) != cell_type:
				continue
			var d: int = absi(p.x - from.x) + absi(p.y - from.y)
			if best.x < 0 or d < best_dist:
				best = p
				best_dist = d
	return best

## Menaçant = actif au tick d'arrivée (option C de R02, décision 12).
static func _nearest_threat(state: SimState, from: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := -1
	var arrival: int = state.tick + 1
	for y in range(state.grid.size.y):
		for x in range(state.grid.size.x):
			var p := Vector2i(x, y)
			if not state.grid.is_danger_active_at(p, arrival):
				continue
			var d: int = absi(p.x - from.x) + absi(p.y - from.y)
			if best.x < 0 or d < best_dist:
				best = p
				best_dist = d
	return best

static func _perceived_neighbours(state: SimState, agent: AgentState, params: RuleParams) -> int:
	var n := 0
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - agent.pos.x
		var dy: int = other.pos.y - agent.pos.y
		if dx * dx + dy * dy <= params.group_perception_range_sq:
			n += 1
	return n

static func _direction_name(dir: Vector2i) -> String:
	if dir == Vector2i.ZERO:
		return "reste sur place"
	if dir == Vector2i(0, -1):
		return "vers le haut"
	if dir == Vector2i(1, 0):
		return "vers la droite"
	if dir == Vector2i(0, 1):
		return "vers le bas"
	if dir == Vector2i(-1, 0):
		return "vers la gauche"
	return str(dir)

## Complète le diagnostic par le sort réel du mouvement : la règle a proposé,
## le pipeline a pu refuser (case occupée par un congénère — RG-06). C'est la
## question que se pose le joueur quand un agent ne bouge pas alors que sa
## pile « devrait » le faire avancer.
static func movement_note(proposed: Vector2i, actual: Vector2i) -> String:
	if proposed == Vector2i.ZERO and actual == Vector2i.ZERO:
		return ""
	if proposed == actual:
		return ""
	if actual == Vector2i.ZERO:
		return "mouvement refusé : la case était occupée"
	return "mouvement modifié par la résolution des conflits"
