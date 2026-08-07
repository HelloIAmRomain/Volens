class_name SimView
extends Node2D
## Rendu de la simulation (T-030, DCT §6). Ne lit `core/` que pour afficher :
## aucune décision de jeu ici, aucune écriture dans l'état. Sens de dépendance
## respecté — game/view → core/replay → core/sim, jamais l'inverse.
##
## DT-13 : nuée et traînées en MultiMesh 2D (un appel de dessin chacune),
## halos et hachures par shaders `canvas_item` sur des primitives, zéro
## texture importée. ÉCART À SIGNALER : les cases sont rendues en MultiMesh
## plutôt qu'en TileMapLayer — un TileMapLayer impose un atlas de texture, ce
## que « tout le visuel est procédural » interdit, et une grille de niveau ne
## dépasse pas 14x18 = 252 cases. Un seul appel de dessin dans les deux cas.
##
## DCT §6.2 : la position affichée est interpolée entre le tick courant et le
## suivant, au prorata du temps écoulé — 60 i/s quelle que soit la cadence de
## simulation, sans contact avec `sim` (DT-06 : la simulation n'a pas d'horloge).

## Calques, dans l'ordre du DCT §6.3 : décor < dangers < nuée < buts.
enum Layer { DECOR = 0, DANGER = 10, TRAIL = 20, AGENT = 30, GOAL = 40 }

const AGENT_SHADER := preload("res://game/view/shaders/agent.gdshader")
const HALO_SHADER := preload("res://game/view/shaders/halo.gdshader")
const HATCH_SHADER := preload("res://game/view/shaders/hatch.gdshader")

## Traînée : longueur en TICKS, pas en images — c'est la forme collective
## dans le temps de simulation qui est en question (DA-01), pas un flou.
var trail_ticks: int = 6
## Faux par défaut : on ne juge pas si quelque chose est beau en fixant une
## surcouche de diagnostic. Esthétique d'abord, diagnostic ensuite (touche C).
var show_decision_colors: bool = false
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		_apply_reduced_motion()

var _session: ReplaySession
var _stack: Array[int] = []
var _level_data: Dictionary = {}
var _params: RuleParams

## Interpolation : `_from` est l'état affiché, `_to` le suivant, `_alpha` la
## fraction écoulée entre les deux.
var _from: SimState
var _to: SimState
var _alpha: float = 0.0

var _cell_size: float = 32.0
var _grid_origin: Vector2 = Vector2.ZERO
## Historique des positions par agent, en cases, du plus ancien au plus récent.
var _trails: Array[Array] = []
## Direction accordée au dernier tick, par agent : sert au comptage des
## demi-tours (diagnostic de tremblement, cf. sondes du 6 août).
var _last_dir: Array[Vector2i] = []
var _reversals: int = 0

var _walls_mm: MultiMeshInstance2D
var _danger_mm: MultiMeshInstance2D
var _goal_mm: MultiMeshInstance2D
var _trail_mm: MultiMeshInstance2D
var _agent_mm: MultiMeshInstance2D
var _deaths_mm: MultiMeshInstance2D
var _grid_lines: Node2D

## Marques de mort : { cell, age }. Purement visuelles, jamais un état.
var _death_marks: Array = []

# --- construction ------------------------------------------------------------

func _ready() -> void:
	_grid_lines = _GridLines.new()
	_grid_lines.z_index = Layer.DECOR
	add_child(_grid_lines)

	_walls_mm = _make_layer(Layer.DECOR, null)
	_danger_mm = _make_layer(Layer.DANGER, HATCH_SHADER)
	_goal_mm = _make_layer(Layer.GOAL, HALO_SHADER)
	_trail_mm = _make_layer(Layer.TRAIL, AGENT_SHADER)
	_agent_mm = _make_layer(Layer.AGENT, AGENT_SHADER)
	_deaths_mm = _make_layer(Layer.GOAL - 1, AGENT_SHADER)

func _make_layer(z: int, shader: Shader) -> MultiMeshInstance2D:
	var node := MultiMeshInstance2D.new()
	node.z_index = z
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = 0
	node.multimesh = mm
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		node.material = mat
	add_child(node)
	return node

func _apply_reduced_motion() -> void:
	for node in [_danger_mm, _goal_mm]:
		if node != null and node.material is ShaderMaterial:
			(node.material as ShaderMaterial).set_shader_parameter("reduced_motion", reduced_motion)

# --- pilotage ----------------------------------------------------------------

## Charge un niveau. La pile peut ensuite changer sans rechargement.
func load_level(level_data: Dictionary, params: RuleParams, stack: Array[int]) -> void:
	_level_data = level_data
	_params = params
	set_stack(stack)

## Change la pile : nouvel essai, donc nouvelle session (RG-10). C'est
## l'opération qui permet de comparer deux ordonnancements de suite.
func set_stack(stack: Array[int]) -> void:
	_stack = stack.duplicate()
	var initial := SimCore.load_level(_level_data, _params)
	_session = ReplaySession.new(initial, _stack)
	_reset_display()
	_fit_to_viewport()

func reset() -> void:
	if _session == null:
		return
	_session.reset()
	_reset_display()

func _reset_display() -> void:
	_from = _session.current()
	_to = _from
	_alpha = 0.0
	_reversals = 0
	_death_marks = []
	_trails = []
	_last_dir = []
	for i in range(_from.agents.size()):
		_trails.append([_from.agents[i].pos])
		_last_dir.append(Vector2i.ZERO)
	_rebuild_static_layers()

func stack() -> Array[int]:
	return _stack.duplicate()

func current_state() -> SimState:
	return _to

func reversals() -> int:
	return _reversals

## Avance le temps d'affichage de `seconds` à `ticks_per_second`. Les ticks
## sont consommés autant de fois que nécessaire — l'affichage ne saute jamais
## un tick, même si l'image a mis longtemps à venir.
func advance(seconds: float, ticks_per_second: float) -> void:
	if _session == null:
		return
	_alpha += seconds * ticks_per_second
	var guard := 0
	while _alpha >= 1.0 and guard < 64:
		_alpha -= 1.0
		_step_one_tick()
		guard += 1
	if guard >= 64:
		_alpha = 0.0

func step_forward() -> void:
	if _session == null:
		return
	_alpha = 0.0
	_step_one_tick()

## Recule d'un tick par re-simulation (DT-12). Les traînées sont reconstruites
## depuis le début : elles ne sont qu'un affichage, jamais un état.
func step_backward() -> void:
	if _session == null:
		return
	var target: int = maxi(_session.current_tick() - 1, 0)
	seek(target)

func seek(target_tick: int) -> void:
	if _session == null:
		return
	_session.seek(maxi(target_tick, 0))
	_alpha = 0.0
	_to = _session.current()
	_from = _to
	_rebuild_trails_from_scratch()

func _step_one_tick() -> void:
	_from = _to
	_to = _session.step_forward()
	_record_tick(_from, _to)

## Historique des traînées et comptage des demi-tours : purement descriptif.
func _record_tick(from_state: SimState, to_state: SimState) -> void:
	for i in range(to_state.agents.size()):
		var agent := to_state.agents[i]
		if i < _trails.size():
			var t: Array = _trails[i]
			t.append(agent.pos)
			while t.size() > trail_ticks + 1:
				t.pop_front()
		var moved: Vector2i = agent.pos - from_state.agents[i].pos
		if moved != Vector2i.ZERO:
			if i < _last_dir.size() and _last_dir[i] != Vector2i.ZERO and moved == -_last_dir[i]:
				_reversals += 1
			if i < _last_dir.size():
				_last_dir[i] = moved

## Après un saut dans le temps : rejoue depuis 0 pour reconstituer les
## traînées et le compteur de demi-tours, sans toucher à la session.
func _rebuild_trails_from_scratch() -> void:
	var target: int = _session.current_tick()
	var state := SimCore.load_level(_level_data, _params)
	_trails = []
	_last_dir = []
	for i in range(state.agents.size()):
		_trails.append([state.agents[i].pos])
		_last_dir.append(Vector2i.ZERO)
	_reversals = 0
	for t in range(target):
		var next_state := SimCore.step(state, _stack)
		_record_tick(state, next_state)
		state = next_state

# --- géométrie ---------------------------------------------------------------

func _fit_to_viewport() -> void:
	if _to == null:
		return
	var vp := get_viewport_rect().size
	var grid := _to.grid.size
	if grid.x <= 0 or grid.y <= 0:
		return
	# Marge : 6 % de la plus petite dimension, pour que la nuée ne colle pas
	# aux bords (l'atteignabilité au pouce viendra avec l'UI, T-032).
	var usable := vp * 0.88
	_cell_size = minf(usable.x / float(grid.x), usable.y / float(grid.y))
	var span := Vector2(grid.x, grid.y) * _cell_size
	_grid_origin = (vp - span) * 0.5
	if _grid_lines != null:
		_grid_lines.configure(grid, _cell_size, _grid_origin)
	_rebuild_static_layers()

func _to_pixels(cell: Vector2) -> Vector2:
	return _grid_origin + (cell + Vector2(0.5, 0.5)) * _cell_size

## Case de grille sous un point de l'écran, ou (-1,-1) hors grille. Sert au
## diagnostic EF-05 : le joueur touche un agent, pas une coordonnée.
func cell_at_pixel(pixel: Vector2) -> Vector2i:
	if _to == null or _cell_size <= 0.0:
		return Vector2i(-1, -1)
	var local := (pixel - _grid_origin) / _cell_size
	var cell := Vector2i(int(floor(local.x)), int(floor(local.y)))
	if not _to.grid.is_in_bounds(cell):
		return Vector2i(-1, -1)
	return cell

## Index de l'agent présent le plus proche d'une case, dans un rayon de
## tolérance — le doigt est large, la case est petite (ENF-01).
func agent_near(cell: Vector2i, tolerance: int = 1) -> int:
	if _to == null:
		return -1
	var best := -1
	var best_dist := tolerance + 1
	for i in range(_to.agents.size()):
		var agent := _to.agents[i]
		if not agent.is_present():
			continue
		var d: int = absi(agent.pos.x - cell.x) + absi(agent.pos.y - cell.y)
		if d < best_dist:
			best_dist = d
			best = i
	return best

## Position affichée d'un agent, pour ancrer une surimpression de diagnostic.
func agent_pixel(index: int) -> Vector2:
	if _to == null or index < 0 or index >= _to.agents.size():
		return Vector2.ZERO
	return _to_pixels(Vector2(_to.agents[index].pos))

## Direction réellement accordée à un agent au dernier tick — à comparer à ce
## que sa règle avait proposé (RG-06 : le pipeline peut refuser).
func last_granted(index: int) -> Vector2i:
	if _from == null or _to == null or index >= _to.agents.size():
		return Vector2i.ZERO
	if not _from.agents[index].is_present() or not _to.agents[index].is_present():
		return Vector2i.ZERO
	return _to.agents[index].pos - _from.agents[index].pos

## État du tick PRÉCÉDENT : c'est sur lui que la décision du dernier
## mouvement a été prise (RG-07, décisions sur cliché immuable).
func previous_state() -> SimState:
	return _from

func tick() -> int:
	return 0 if _to == null else _to.tick

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		return

func _on_viewport_resized() -> void:
	_fit_to_viewport()

# --- dessin ------------------------------------------------------------------

## DÉCOMPOSITION EN RÉGIONS. Le vocabulaire de niveau est fait de cases ;
## l'œil, lui, lit des formes. Deux cases de lumière côte à côte doivent se
## lire comme UNE zone lumineuse, pas comme deux points — et la bande de
## sortie pleine largeur de ch1_01 doit se lire comme une bande.
##
## Algorithme glouton : on prend la case libre la plus haute à gauche, on
## étend vers la droite tant que le type se répète, puis vers le bas tant que
## la ligne entière se répète. Une bande pleine largeur donne UN rectangle,
## un bloc plein en donne un aussi. Les formes concaves se décomposent en
## quelques rectangles, jamais en cases isolées.
func _rects_of(predicate: Callable) -> Array:
	var grid := _to.grid
	var w: int = grid.size.x
	var h: int = grid.size.y
	var taken := {}
	var rects: Array = []
	for y in range(h):
		for x in range(w):
			var key: int = y * w + x
			if taken.has(key) or not predicate.call(Vector2i(x, y)):
				continue
			var rw := 1
			while x + rw < w and not taken.has(y * w + x + rw) and predicate.call(Vector2i(x + rw, y)):
				rw += 1
			var rh := 1
			while y + rh < h:
				var full := true
				for k in range(rw):
					if taken.has((y + rh) * w + x + k) or not predicate.call(Vector2i(x + k, y + rh)):
						full = false
						break
				if not full:
					break
				rh += 1
			for yy in range(y, y + rh):
				for xx in range(x, x + rw):
					taken[yy * w + xx] = true
			rects.append(Rect2i(x, y, rw, rh))
	return rects

func _rebuild_static_layers() -> void:
	if _to == null or _walls_mm == null:
		return
	var grid := _to.grid
	var walls: Array = []
	for r in _rects_of(func(p: Vector2i) -> bool: return grid.cell_type_at(p) == GridState.CellType.WALL):
		walls.append(_region_item(r, ViewPalette.WALL, 0.0))
	_fill_items(_walls_mm, walls)

	# Les buts débordent de leur région : le halo doit rayonner autour de la
	# forme entière, d'où le débord et la proportion de noyau transmise.
	var goals: Array = []
	for spec in [[GridState.CellType.EXIT, ViewPalette.EXIT],
			[GridState.CellType.LIGHT_SOURCE, ViewPalette.LIGHT],
			[GridState.CellType.RESOURCE, ViewPalette.RESOURCE],
			[GridState.CellType.DROPOFF, ViewPalette.DROPOFF]]:
		var wanted: int = spec[0]
		for r in _rects_of(func(p: Vector2i) -> bool: return grid.cell_type_at(p) == wanted):
			goals.append(_region_item(r, spec[1], GOAL_BLEED))
	_fill_items(_goal_mm, goals)

## Débord du halo autour d'une région de but, en cases.
const GOAL_BLEED := 0.45

## Construit l'instance d'une région : quad élargi de `bleed` cases, couleur,
## et données par instance. Pour un but, ces données portent la PROPORTION du
## noyau dans le quad ; pour une région pleine, la taille en CASES.
func _region_item(r: Rect2i, color: Color, bleed: float) -> Dictionary:
	var cells := Vector2(r.size.x, r.size.y)
	var span := cells + Vector2(bleed, bleed) * 2.0
	var centre := Vector2(r.position.x, r.position.y) + cells * 0.5
	var custom := Color(cells.x, cells.y, 0.0, 0.0)
	if bleed > 0.0:
		custom = Color(cells.x / span.x, cells.y / span.y, 0.0, 0.0)
	return {
		"pos": _grid_origin + centre * _cell_size,
		"size": span * _cell_size,
		"color": color,
		"custom": custom,
	}

## Durée d'une marque de mort ⚙️ : assez pour être vue, pas au point de
## traîner sur l'écran suivant.
const DEATH_MARK_SECONDS := 1.6

func _process(dt: float) -> void:
	if _to == null:
		return
	for mark in _death_marks:
		mark["age"] = float(mark["age"]) + dt
	_death_marks = _death_marks.filter(func(m: Dictionary) -> bool:
		return float(m["age"]) < DEATH_MARK_SECONDS)
	_draw_deaths()
	_draw_dangers()
	_draw_trails()
	_draw_agents()

## Les dangers se dessinent aussi par RÉGION, et séparément selon leur phase :
## un danger actif et un danger dormant ne se fondent jamais dans la même
## forme, sans quoi le joueur croirait toute la zone dangereuse.
func _draw_dangers() -> void:
	var grid := _to.grid
	var tick := _to.tick
	var items: Array = []
	var active := func(p: Vector2i) -> bool:
		var t2: int = grid.cell_type_at(p)
		if t2 != GridState.CellType.STATIC_DANGER and t2 != GridState.CellType.CYCLIC_DANGER:
			return false
		return grid.is_danger_active_at(p, tick)
	var dormant := func(p: Vector2i) -> bool:
		var t2: int = grid.cell_type_at(p)
		if t2 != GridState.CellType.CYCLIC_DANGER:
			return false
		return not grid.is_danger_active_at(p, tick)
	for r in _rects_of(active):
		items.append(_region_item(r, ViewPalette.DANGER, 0.0))
	for r in _rects_of(dormant):
		items.append(_region_item(r, ViewPalette.DANGER_DORMANT, 0.0))
	_fill_items(_danger_mm, items)

## Une croix lumineuse qui s'ouvre et s'efface sur la case fatale.
func _draw_deaths() -> void:
	var items: Array = []
	for mark in _death_marks:
		var age := float(mark["age"]) / DEATH_MARK_SECONDS
		var c := ViewPalette.DANGER.lightened(0.45)
		c.a = (1.0 - age) * 0.95
		items.append([Vector2(mark["cell"]), c])
	_fill(_deaths_mm, items, _cell_size * (0.9 + 0.5 * _death_pulse()))

func _death_pulse() -> float:
	if _death_marks.is_empty():
		return 0.0
	return float(_death_marks[0]["age"]) / DEATH_MARK_SECONDS

func _draw_agents() -> void:
	var items: Array = []
	for i in range(_to.agents.size()):
		var to_agent := _to.agents[i]
		var from_agent := _from.agents[i] if i < _from.agents.size() else to_agent
		# Un agent qui vient de sortir ou de mourir s'efface sur le tick.
		var alpha := 1.0
		if not to_agent.is_present():
			if not from_agent.is_present():
				continue
			alpha = 1.0 - _alpha
		var cell: Vector2 = Vector2(from_agent.pos).lerp(Vector2(to_agent.pos), _alpha)
		var color := ViewPalette.AGENT_PLAIN
		if show_decision_colors and to_agent.is_present():
			color = ViewPalette.slot_color(_deciding_slot(to_agent, _to))
		color.a = alpha
		items.append([cell, color])
	_fill(_agent_mm, items, _cell_size * 0.70)

func _draw_trails() -> void:
	var items: Array = []
	for i in range(_trails.size()):
		if i >= _to.agents.size() or not _to.agents[i].is_present():
			continue
		var t: Array = _trails[i]
		var color := ViewPalette.AGENT_PLAIN
		if show_decision_colors:
			color = ViewPalette.slot_color(_deciding_slot(_to.agents[i], _to))
		# Le plus ancien est le plus faible ; la tête de traînée est portée
		# par l'agent lui-même.
		for k in range(t.size() - 1):
			var age := float(k + 1) / float(t.size())
			var c := color
			c.a = age * 0.20
			items.append([Vector2(t[k]), c])
	_fill(_trail_mm, items, _cell_size * 0.22)

## Quelle règle a décidé pour cet agent, à ce tick ? Lecture seule : on
## interroge les mêmes règles que la simulation, on n'en réimplémente aucune
## (DT-15). Renvoie l'index d'emplacement, ou -1 si aucune ne s'applique.
func _deciding_slot(agent: AgentState, state: SimState) -> int:
	for i in range(_stack.size()):
		var rule_id: int = _stack[i]
		if rule_id == RuleRegistry.EMPTY:
			continue
		var rule := RuleRegistry.get_rule(rule_id)
		if rule == null:
			continue
		if rule.evaluate(agent, state, state.rule_params) != Rule.ABSTAIN:
			return i
	return -1

## Remplit une couche à partir de régions déjà exprimées en pixels.
func _fill_items(node: MultiMeshInstance2D, items: Array) -> void:
	if node == null:
		return
	var mm := node.multimesh
	mm.instance_count = items.size()
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var span: Vector2 = it["size"]
		mm.set_instance_transform_2d(i, Transform2D(0.0, span, 0.0, it["pos"]))
		mm.set_instance_color(i, it["color"])
		mm.set_instance_custom_data(i, it["custom"])

func _fill(node: MultiMeshInstance2D, items: Array, size: float) -> void:
	if node == null:
		return
	var mm := node.multimesh
	mm.instance_count = items.size()
	for i in range(items.size()):
		var cell: Vector2 = items[i][0]
		mm.set_instance_transform_2d(i, Transform2D(0.0, Vector2(size, size), 0.0, _to_pixels(cell)))
		mm.set_instance_color(i, items[i][1])
		mm.set_instance_custom_data(i, Color(1.0, 1.0, 0.0, 0.0))

# --- grille de fond -----------------------------------------------------------

class _GridLines extends Node2D:
	var _grid: Vector2i = Vector2i.ZERO
	var _cell: float = 32.0
	var _origin: Vector2 = Vector2.ZERO

	func configure(grid: Vector2i, cell: float, origin: Vector2) -> void:
		_grid = grid
		_cell = cell
		_origin = origin
		queue_redraw()

	func _draw() -> void:
		if _grid.x <= 0 or _grid.y <= 0:
			return
		var span := Vector2(_grid.x, _grid.y) * _cell
		draw_rect(Rect2(_origin, span), ViewPalette.BACKGROUND.lightened(0.02), true)
		for x in range(_grid.x + 1):
			var px := _origin.x + x * _cell
			draw_line(Vector2(px, _origin.y), Vector2(px, _origin.y + span.y), ViewPalette.GRID_LINE, 1.0)
		for y in range(_grid.y + 1):
			var py := _origin.y + y * _cell
			draw_line(Vector2(_origin.x, py), Vector2(_origin.x + span.x, py), ViewPalette.GRID_LINE, 1.0)
