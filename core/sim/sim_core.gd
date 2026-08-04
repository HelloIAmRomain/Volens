class_name SimCore
extends RefCounted
## Cœur de simulation [DCT §4]. Module pur, headless, déterministe : aucune
## dépendance au rendu, aucun float, aucun aléatoire, aucune horloge.

## Construit l'état initial à partir d'un niveau déjà chargé et analysé
## (Dictionary). `core/sim/` ne lit aucun fichier lui-même : c'est
## l'appelant (tools/, game/) qui lit le JSON et transmet un Dictionary.
static func load_level(level_data: Dictionary, rule_params: RuleParams) -> SimState:
	var state := SimState.new()
	state.tick = 0
	state.outcome = SimState.Outcome.RUNNING
	state.rule_params = rule_params
	state.max_ticks = int(level_data.get("max_ticks", 0))
	state.counters = Counters.new()
	state.grid = _load_grid(level_data.get("grid", {}))
	state.agents = _load_agents(level_data.get("agents", []))
	state.objectives = _load_objectives(level_data.get("objectives", []), state.grid)
	return state

static func _load_objectives(objectives_arr: Array, grid: GridState) -> Array[ObjectiveDef]:
	var out: Array[ObjectiveDef] = []
	for entry in objectives_arr:
		var obj := ObjectiveDef.from_dict(entry, grid)
		if obj != null:
			out.append(obj)
	return out

static func _load_grid(grid_data: Dictionary) -> GridState:
	var grid := GridState.new()
	var size_arr: Array = grid_data.get("size", [0, 0])
	grid.size = Vector2i(int(size_arr[0]), int(size_arr[1]))
	var cell_count: int = grid.size.x * grid.size.y

	var cells_arr: Array = grid_data.get("cells", [])
	grid.cells = PackedInt32Array()
	grid.cells.resize(cell_count)
	for i in range(cell_count):
		grid.cells[i] = int(cells_arr[i]) if i < cells_arr.size() else GridState.CellType.EMPTY

	grid.pheromone = PackedInt32Array()
	grid.pheromone.resize(cell_count)  # initialisé à zéro

	var cycle_index_arr: Array = grid_data.get("cycle_index", [])
	grid.cycle_index = PackedInt32Array()
	grid.cycle_index.resize(cell_count)
	for i in range(cell_count):
		grid.cycle_index[i] = int(cycle_index_arr[i]) if i < cycle_index_arr.size() else -1

	grid.cycles = []
	var cycles_arr: Array = grid_data.get("cycles", [])
	for c in cycles_arr:
		var cd := CycleDef.new()
		cd.period = int(c.get("period", 1))
		cd.active_ticks = int(c.get("active_ticks", 0))
		grid.cycles.append(cd)

	return grid

static func _load_agents(agents_arr: Array) -> Array[AgentState]:
	var agents: Array[AgentState] = []
	for i in range(agents_arr.size()):
		var a: Dictionary = agents_arr[i]
		var agent := AgentState.new()
		agent.id = i  # invariant : id == index (DT-07)
		var pos_arr: Array = a.get("pos", [0, 0])
		agent.pos = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		agent.dir = Directions.NORTH
		agent.flags = AgentState.PRESENT
		agents.append(agent)
	return agents

## Empreinte de l'état [DCT §4.2, DT-09] — délègue à StateHash (T-013).
static func hash_state(state: SimState) -> int:
	return StateHash.hash_state(state)

## Transition pure d'un tick [DCT §4.4] : lit `state` (t) en lecture seule du
## début à la fin, construit et renvoie un état neuf (t+1). Mêmes entrées,
## mêmes sorties, toujours (DT-10 §2.1 / invariant n°10 docs/ARCHITECTURE.md).
static func step(state: SimState, stack: Array[int]) -> SimState:
	var next_state := state.clone()
	next_state.tick = state.tick + 1

	_update_cycles(next_state)                                    # 1. éléments cycliques
	var desired := _decide_agents(state, stack)                   # 2. décision (lit `state`, jamais `next_state`)
	var granted := _resolve_conflicts(state, desired)              # 3. conflits de case
	_apply_movements(next_state, granted)                          # 4. application des mouvements
	_apply_environment_effects(next_state)                         # 5. effets d'environnement
	_evaporate_pheromones(next_state)                              # 6. évaporation des pistes
	_evaluate_outcome(next_state)                                  # 7. évaluation des objectifs

	return next_state

## Étape 1 — no-op documenté : CycleDef.is_active_at(tick) est une requête
## pure calculée à la demande (DT-05), il n'y a donc aucune phase à stocker
## ni à muter ici. L'étape reste présente pour respecter l'ordre du DCT §4.4
## et pour accueillir une future optimisation par cache si nécessaire.
static func _update_cycles(_state: SimState) -> void:
	pass

## Étape 2 — cascade de règles (T-012) : pour chaque agent présent, la
## première règle non-ABSTAIN de la pile l'emporte (RG-05, règle d'or). Lit
## exclusivement `state` (t), jamais l'état en cours de construction (RG-07).
static func _decide_agents(state: SimState, stack: Array[int]) -> Array[Vector2i]:
	var n := state.agents.size()
	var directions: Array[Vector2i] = []
	directions.resize(n)
	for i in range(n):
		var agent := state.agents[i]
		directions[i] = _decide_one(agent, state, stack) if agent.is_present() else Vector2i.ZERO
	return directions

## Emplacement vide (RuleRegistry.EMPTY) : ignoré, la cascade continue.
## Aucune règle applicable : immobile (RG-05).
static func _decide_one(agent: AgentState, state: SimState, stack: Array[int]) -> Vector2i:
	for rule_id in stack:
		if rule_id == RuleRegistry.EMPTY:
			continue
		var rule := RuleRegistry.get_rule(rule_id)
		if rule == null:
			continue
		var result: Vector2i = rule.evaluate(agent, state, state.rule_params)
		if result != Rule.ABSTAIN:
			return result
	return Vector2i.ZERO

## Étape 3 — résolution des conflits de case (RG-06/RG-01).
##
## Algorithme de réservation itératif : une case occupée par un agent qui n'en
## bouge pas (immobile par choix, bloqué par un mur/la bordure, ou ayant perdu
## un conflit à une passe précédente) défend cette case contre tout autre
## prétendant, quel que soit son id — sans quoi deux agents pourraient se
## retrouver sur la même case, en violation de RG-01. Entre agents qui visent
## réellement la même case libre, le plus petit id l'emporte (RG-06) ; les
## perdants restent sur place (DCT §4.4). Converge en au plus N passes : une
## case ne peut que devenir « défendue » au fil des passes, jamais l'inverse.
## Un échange direct de deux agents (A→case de B, B→case de A) est autorisé :
## aucune des deux cases n'est jamais partagée au même instant.
static func _resolve_conflicts(state: SimState, desired_dirs: Array[Vector2i]) -> Array[Vector2i]:
	var n := state.agents.size()
	var destinations: Array[Vector2i] = []
	destinations.resize(n)
	for i in range(n):
		var agent := state.agents[i]
		if not agent.is_present():
			destinations[i] = agent.pos
			continue
		var dir: Vector2i = desired_dirs[i]
		if dir == Vector2i.ZERO:
			destinations[i] = agent.pos
			continue
		var target: Vector2i = agent.pos + dir
		destinations[i] = target if state.grid.is_walkable(target) else agent.pos

	var stable := false
	while not stable:
		stable = true
		# Regroupe les agents présents par case cible (parcours par id croissant,
		# donc chaque liste de prétendants est déjà triée par id croissant).
		var claims: Dictionary = {}
		for i in range(n):
			if not state.agents[i].is_present():
				continue
			var idx: int = state.grid.index_of(destinations[i])
			if not claims.has(idx):
				claims[idx] = []
			claims[idx].append(i)

		for i in range(n):
			if not state.agents[i].is_present():
				continue
			var idx: int = state.grid.index_of(destinations[i])
			var contenders: Array = claims[idx]
			if contenders.size() <= 1:
				continue
			var defender: int = -1
			for c in contenders:
				if destinations[c] == state.agents[c].pos:
					defender = c
					break
			var winner: int = defender if defender != -1 else contenders[0]
			if winner != i and destinations[i] != state.agents[i].pos:
				destinations[i] = state.agents[i].pos
				stable = false

	var granted: Array[Vector2i] = []
	granted.resize(n)
	for i in range(n):
		granted[i] = destinations[i] - state.agents[i].pos
	return granted

## Étape 4 — applique les mouvements accordés à `next_state` (RG-07 : ces
## mouvements ont été décidés sur l'état t, jamais sur next_state en cours
## de construction).
static func _apply_movements(next_state: SimState, granted_dirs: Array[Vector2i]) -> void:
	for i in range(next_state.agents.size()):
		var dir: Vector2i = granted_dirs[i]
		if dir == Vector2i.ZERO:
			continue
		var agent := next_state.agents[i]
		agent.pos += dir
		agent.dir = _direction_index_of(dir)

static func _direction_index_of(dir: Vector2i) -> int:
	for d in Directions.ORDER:
		if Directions.offset(d) == dir:
			return d
	return Directions.NORTH  # inatteignable pour un vecteur de déplacement valide

## Étape 5 — effets d'environnement. Seuls Sortie et Danger sont câblés dans
## ce lot (RG-14) : Ressource, Case de dépôt, Porte à pression et Sens unique
## restent inertes tant que R06/R11/R12 (chapitres 2 et 4) ne sont pas en
## place — hors périmètre du lot S2.
static func _apply_environment_effects(next_state: SimState) -> void:
	for agent in next_state.agents:
		if not agent.is_present():
			continue
		var cell_type: int = next_state.grid.cell_type_at(agent.pos)
		if cell_type == GridState.CellType.EXIT:
			agent.flags = (agent.flags & ~AgentState.PRESENT) | AgentState.SORTI
			next_state.counters.exited += 1
		elif next_state.grid.is_danger_active_at(agent.pos, next_state.tick):
			agent.flags = (agent.flags & ~AgentState.PRESENT) | AgentState.PERDU
			next_state.counters.lost += 1

## Étape 6 — évaporation des marqueurs de piste (décrément entier, R08/R09).
## Aucune règle de ce lot n'écrit encore de piste ; la grille reste à zéro.
static func _evaporate_pheromones(next_state: SimState) -> void:
	var p := next_state.grid.pheromone
	for i in range(p.size()):
		if p[i] > 0:
			p[i] -= 1

## Étape 7 — évaluation des objectifs (RG-09, RG-15). Un état WON ou LOST
## déjà atteint ne revient jamais en arrière (un niveau se termine).
##
## Ordre d'évaluation, fixe et documenté :
##   1. contraintes violées (préservation, interdiction, célérité) -> LOST —
##      une violation est irrémédiable, elle prime sur tout le reste ;
##   2. inatteignabilité mathématique des accomplissements -> LOST (RG-09) ;
##   3. tous les accomplissements satisfaits (et il en existe au moins un)
##      -> WON ;
##   4. limite de ticks du niveau atteinte -> LOST.
## Un niveau sans accomplissement n'est jamais gagné : défaut de conception,
## que le validateur signalera (zéro pile gagnante -> rejeté, CDC §12.2).
static func _evaluate_outcome(next_state: SimState) -> void:
	if next_state.outcome != SimState.Outcome.RUNNING:
		return

	# 1. Contraintes.
	for obj in next_state.objectives:
		match obj.type:
			ObjectiveDef.Type.PRESERVATION:
				if next_state.counters.lost > obj.max_lost:
					next_state.outcome = SimState.Outcome.LOST
					return
			ObjectiveDef.Type.INTERDICTION:
				if _any_present_agent_on_cells(next_state, obj.cells):
					next_state.outcome = SimState.Outcome.LOST
					return
			ObjectiveDef.Type.CELERITY:
				if next_state.tick >= obj.max_ticks:
					next_state.outcome = SimState.Outcome.LOST
					return

	# 2. Inatteignabilité, 3. accomplissements — en un seul parcours.
	var total_agents: int = next_state.agents.size()
	var present: int = _count_present(next_state)
	var achievement_count := 0
	var all_achieved := true
	for obj in next_state.objectives:
		match obj.type:
			ObjectiveDef.Type.EXTRACTION:
				achievement_count += 1
				# Comparaisons en centièmes entiers : jamais de division.
				if (next_state.counters.exited + present) * 100 < obj.percent * total_agents:
					next_state.outcome = SimState.Outcome.LOST  # plus assez d'agents
					return
				if next_state.counters.exited * 100 < obj.percent * total_agents:
					all_achieved = false
			ObjectiveDef.Type.COLLECT:
				achievement_count += 1
				if next_state.counters.delivered + _collectable_remaining(next_state) < obj.count:
					next_state.outcome = SimState.Outcome.LOST
					return
				if next_state.counters.delivered < obj.count:
					all_achieved = false

	if achievement_count > 0 and all_achieved:
		next_state.outcome = SimState.Outcome.WON
		return

	# 4. Limite de ticks du niveau.
	if next_state.max_ticks > 0 and next_state.tick >= next_state.max_ticks:
		next_state.outcome = SimState.Outcome.LOST

static func _any_present_agent_on_cells(state: SimState, cells: PackedInt32Array) -> bool:
	for agent in state.agents:
		if not agent.is_present():
			continue
		var idx: int = state.grid.index_of(agent.pos)
		for forbidden in cells:
			if idx == forbidden:
				return true
	return false

static func _count_present(state: SimState) -> int:
	var n := 0
	for agent in state.agents:
		if agent.is_present():
			n += 1
	return n

## Ressources encore livrables : cases RESOURCE restantes + agents porteurs.
## Tant que R11/R12 (chapitre 4) n'existent pas, delivered ne progresse pas
## et cette borne rend l'objectif COLLECT correctement inatteignable quand
## le stock est insuffisant.
static func _collectable_remaining(state: SimState) -> int:
	var n := 0
	for c in state.grid.cells:
		if c == GridState.CellType.RESOURCE:
			n += 1
	for agent in state.agents:
		if agent.is_present() and (agent.flags & AgentState.PORTEUR) != 0:
			n += 1
	return n
