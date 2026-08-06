extends Node
## Point d'entrée de l'écran de jeu, le temps du prototype : lit le niveau
## demandé et instancie `GameScreen`. Sera remplacé par la machine à états
## d'écrans (DCT §9.1, Accueil → Carte → Jeu → Bilan) quand elle existera.
##
##   godot --path . game/ui/game_screen.tscn -- --level=data/levels/ch1_01.json

func _ready() -> void:
	var args := _parse_args()
	var level_path := String(args.get("level", "data/levels/ch1_01.json"))
	if not level_path.begins_with("res://"):
		level_path = "res://" + level_path
	var level_data := _load_json(level_path)
	if level_data.is_empty():
		push_error("Niveau illisible : " + level_path)
		get_tree().quit(2)
		return

	var screen := GameScreen.new()
	add_child(screen)
	screen.load_level(level_data, RuleParams.from_dict(_load_json("res://data/rules.json")))

	var frames := int(args.get("autoquit", "-1"))
	if frames > 0:
		_autoquit(frames)

func _autoquit(frames: int) -> void:
	for i in range(frames):
		await get_tree().process_frame
	print("Écran de jeu : %d images rendues sans erreur, sortie automatique." % frames)
	get_tree().quit(0)

func _parse_args() -> Dictionary:
	var out: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		out[body.substr(0, eq)] = body.substr(eq + 1) if eq != -1 else ""
	return out

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
