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
var show_decision_colors: bool = true
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
var _grid_lines: Node2D

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

func _make_layer(z: int, shader: Shader) -> MultiMeshInstance2D:
	var node := MultiMeshInstance2D.new()
	node.z_index = z
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		return

func _on_viewport_resized() -> void:
	_fit_to_viewport()

# --- dessin ------------------------------------------------------------------

func _rebuild_static_layers() -> void:
	if _to == null or _walls_mm == null:
		return
	var grid := _to.grid
	var walls: Array = []
	var goals: Array = []
	for y in range(grid.size.y):
		for x in range(grid.size.x):
			var t: int = grid.cells[y * grid.size.x + x]
			match t:
				GridState.CellType.WALL:
					walls.append([Vector2(x, y), ViewPalette.WALL])
				GridState.CellType.EXIT:
					goals.append([Vector2(x, y), ViewPalette.EXIT])
				GridState.CellType.LIGHT_SOURCE:
					goals.append([Vector2(x, y), ViewPalette.LIGHT])
				GridState.CellType.RESOURCE:
					goals.append([Vector2(x, y), ViewPalette.RESOURCE])
				GridState.CellType.DROPOFF:
					goals.append([Vector2(x, y), ViewPalette.DROPOFF])
	_fill(_walls_mm, walls, _cell_size)
	# Les buts débordent de leur case : le halo doit rayonner.
	_fill(_goal_mm, goals, _cell_size * 2.6)

func _process(_dt: float) -> void:
	if _to == null:
		return
	_draw_dangers()
	_draw_trails()
	_draw_agents()

## Les dangers cycliques changent d'aspect selon leur phase : reconstruits
## à chaque image, ils sont peu nombreux.
func _draw_dangers() -> void:
	var grid := _to.grid
	var items: Array = []
	for y in range(grid.size.y):
		for x in range(grid.size.x):
			var pos := Vector2i(x, y)
			var t: int = grid.cells[y * grid.size.x + x]
			if t != GridState.CellType.STATIC_DANGER and t != GridState.CellType.CYCLIC_DANGER:
				continue
			var active: bool = grid.is_danger_active_at(pos, _to.tick)
			items.append([Vector2(x, y), ViewPalette.cell_color(t, active)])
	_fill(_danger_mm, items, _cell_size)

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
	_fill(_agent_mm, items, _cell_size * 0.62)

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
			c.a = age * 0.30
			items.append([Vector2(t[k]), c])
	_fill(_trail_mm, items, _cell_size * 0.34)

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

func _fill(node: MultiMeshInstance2D, items: Array, size: float) -> void:
	if node == null:
		return
	var mm := node.multimesh
	mm.instance_count = items.size()
	for i in range(items.size()):
		var cell: Vector2 = items[i][0]
		mm.set_instance_transform_2d(i, Transform2D(0.0, Vector2(size, size), 0.0, _to_pixels(cell)))
		mm.set_instance_color(i, items[i][1])

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
