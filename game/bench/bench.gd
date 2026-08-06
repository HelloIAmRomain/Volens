extends Node2D
## Banc de visualisation — JETABLE. Sert à répondre de visu aux questions
## perceptives qu'aucun compteur ne tranche : « tremblement ou hésitation »,
## « beau ou cassé », « ces deux piles se ressemblent-elles ». Le rendu qu'il
## pilote (game/view/) est du vrai code de production ; ce fichier ne l'est pas.
##
##   godot --path . game/bench/bench.tscn -- \
##       --level=data/levels/diag/diag_archetypes.json \
##       --stacks=2-3-1,3-2-1 [--speed=4] [--trail=6]
##
## Commandes (clavier)             | (tactile)
##   Espace   marche / pause       | toucher l'écran
##   → / D    un tick en avant     |
##   ← / A    un tick en arrière   |
##   1 2 3 4  1, 2, 4, 8 ticks/s   |
##   Tab      pile suivante        |
##   R        réinitialiser        |
##   C        couleurs par règle   |
##   H        surcouche            | appui long
##   M        animations réduites  |

const SPEEDS: Array[float] = [1.0, 2.0, 4.0, 8.0]
const LONG_PRESS_SECONDS := 0.45

var _view: SimView
var _overlay: Label
var _banner: ColorRect
var _hint: Label

var _stacks: Array = []
var _stack_index: int = 0
var _speed_index: int = 2
var _playing: bool = false
var _rewinding: bool = false
var _rewind_accumulator: float = 0.0
var _press_time: float = -1.0
var _autoquit_frames: int = -1
var _frames: int = 0

func _ready() -> void:
	var args := _parse_args()
	_autoquit_frames = int(args.get("autoquit", "-1"))

	var level_path := String(args.get("level", "data/levels/ch1_01.json"))
	if not level_path.begins_with("res://"):
		level_path = "res://" + level_path
	var level_data := _load_json(level_path)
	if level_data.is_empty():
		push_error("Niveau illisible : " + level_path)
		get_tree().quit(2)
		return
	var rules_data := _load_json("res://data/rules.json")

	_stacks = _parse_stacks(String(args.get("stacks", "")), level_data)

	RenderingServer.set_default_clear_color(ViewPalette.BACKGROUND)
	_view = SimView.new()
	_view.trail_ticks = int(args.get("trail", "6"))
	add_child(_view)
	_view.load_level(level_data, RuleParams.from_dict(rules_data), _current_stack())

	if args.has("speed"):
		var wanted := float(args["speed"])
		for i in range(SPEEDS.size()):
			if is_equal_approx(SPEEDS[i], wanted):
				_speed_index = i

	_build_overlay(level_path)
	get_viewport().size_changed.connect(_on_resized)

func _on_resized() -> void:
	if _view != null:
		_view._on_viewport_resized()
	_layout_overlay()

# --- boucle -------------------------------------------------------------------

func _process(delta: float) -> void:
	if _view == null:
		return
	if _rewinding:
		_rewind_accumulator += delta * SPEEDS[_speed_index]
		while _rewind_accumulator >= 1.0:
			_rewind_accumulator -= 1.0
			_view.step_backward()
	elif _playing:
		_view.advance(delta, SPEEDS[_speed_index])
	if _press_time >= 0.0:
		_press_time += delta
		if _press_time >= LONG_PRESS_SECONDS:
			_overlay.visible = not _overlay.visible
			_press_time = -1.0
	_update_overlay()
	_update_banner()

	_frames += 1
	if _autoquit_frames > 0 and _frames >= _autoquit_frames:
		print("Banc : %d images rendues sans erreur, sortie automatique." % _frames)
		get_tree().quit(0)

# --- entrées -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE:
				_playing = not _playing
			KEY_RIGHT, KEY_D:
				_playing = false
				_view.step_forward()
			KEY_LEFT, KEY_A:
				_playing = false
				_view.step_backward()
			KEY_1:
				_speed_index = 0
			KEY_2:
				_speed_index = 1
			KEY_3:
				_speed_index = 2
			KEY_4:
				_speed_index = 3
			KEY_TAB:
				_next_stack()
			KEY_R:
				_view.reset()
			KEY_C:
				_view.show_decision_colors = not _view.show_decision_colors
			KEY_H:
				_overlay.visible = not _overlay.visible
			KEY_M:
				_view.reduced_motion = not _view.reduced_motion
			KEY_ESCAPE:
				get_tree().quit(0)
	elif event is InputEventKey and not event.pressed:
		var code := (event as InputEventKey).keycode
		if code == KEY_LEFT or code == KEY_A:
			_rewinding = false

	# Rembobinage continu à l'appui maintenu (DCT §5.2).
	if event is InputEventKey and event.pressed and event.is_echo():
		var code2 := (event as InputEventKey).keycode
		if code2 == KEY_LEFT or code2 == KEY_A:
			_rewinding = true

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed if event is InputEventMouseButton else (event as InputEventScreenTouch).pressed
		if pressed:
			_press_time = 0.0
		else:
			if _press_time >= 0.0 and _press_time < LONG_PRESS_SECONDS:
				_playing = not _playing
			_press_time = -1.0

func _next_stack() -> void:
	if _stacks.size() <= 1:
		return
	_stack_index = (_stack_index + 1) % _stacks.size()
	_view.set_stack(_current_stack())
	_playing = false

func _current_stack() -> Array[int]:
	var out: Array[int] = []
	if _stacks.is_empty():
		return out
	for v in _stacks[_stack_index]:
		out.append(int(v))
	return out

# --- surcouche -----------------------------------------------------------------

func _build_overlay(level_path: String) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_banner = ColorRect.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.color = Color(0, 0, 0, 0)
	layer.add_child(_banner)

	_overlay = Label.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	_overlay.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_overlay.add_theme_constant_override("outline_size", 6)
	layer.add_child(_overlay)

	_hint = Label.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.text = "%s\nEspace marche/pause · ←→ pas à pas · 1-4 vitesse · Tab pile · C couleurs · H surcouche · R reset" % level_path.get_file()
	_hint.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hint.add_theme_constant_override("outline_size", 5)
	layer.add_child(_hint)
	_layout_overlay()

func _layout_overlay() -> void:
	var vp := get_viewport_rect().size
	if _overlay != null:
		_overlay.position = Vector2(18, 18)
	if _hint != null:
		_hint.position = Vector2(18, vp.y - 62)
	if _banner != null:
		_banner.position = Vector2.ZERO
		_banner.size = vp

func _update_overlay() -> void:
	if _overlay == null or not _overlay.visible:
		return
	var state := _view.current_state()
	if state == null:
		return
	var outcome_names := ["en cours", "GAGNÉ", "PERDU"]
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_overlay.text = "pile %s   (%d/%d)\ntick %d   %s\nsortis %d · perdus %d\ndemi-tours %d\n%d i/s · %.2f ms\nvitesse %d tick/s%s" % [
		_stack_label(), _stack_index + 1, maxi(_stacks.size(), 1),
		state.tick, outcome_names[state.outcome],
		state.counters.exited, state.counters.lost,
		_view.reversals(),
		Engine.get_frames_per_second(), frame_ms,
		int(SPEEDS[_speed_index]),
		"   [pause]" if not _playing else ""]

## Liseré d'écran : l'état se lit en une demi-seconde sans texte (DA-03).
func _update_banner() -> void:
	if _banner == null:
		return
	var state := _view.current_state()
	if state == null:
		return
	var c := Color(0, 0, 0, 0)
	match state.outcome:
		SimState.Outcome.WON:
			c = Color(0.16, 0.92, 0.62, 0.10)
		SimState.Outcome.LOST:
			c = Color(0.90, 0.16, 0.22, 0.10)
		_:
			c = Color(0.35, 0.85, 1.00, 0.03 if _playing else 0.0)
	_banner.color = c

func _stack_label() -> String:
	var names := {0: "vide", 1: "Lumière", 2: "Fuir", 3: "Grouper"}
	var parts := PackedStringArray()
	for rid in _current_stack():
		parts.append(String(names.get(int(rid), str(rid))))
	return " > ".join(parts) if parts.size() > 0 else "(pile vide)"

# --- entrée/sortie --------------------------------------------------------------

func _parse_args() -> Dictionary:
	var out: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		out[body.substr(0, eq)] = body.substr(eq + 1) if eq != -1 else ""
	return out

func _parse_stacks(raw: String, level_data: Dictionary) -> Array:
	var out: Array = []
	for chunk in raw.split(",", false):
		var stack: Array = []
		for token in chunk.split("-", false):
			stack.append(int(token))
		out.append(stack)
	if out.is_empty():
		var from_level: Array = level_data.get("stack", [])
		out.append(from_level if not from_level.is_empty() else [1])
	return out

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
