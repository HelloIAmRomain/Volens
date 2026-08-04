extends SceneTree
## Lanceur de simulation headless (lot S2, §1.6).
##
##   godot --headless --path . --script res://tools/run_sim.gd -- \
##       --level=test_smoke --ticks=200 [--stack=1,2,3] [--verbose]
##
## Charge data/levels/<level>.json et data/rules.json, exécute N ticks du
## cœur de simulation et affiche l'empreinte finale. La pile vient de
## --stack (ids de règles séparés par des virgules) ou, à défaut, du champ
## "stack" du fichier de niveau ; sans l'un ni l'autre, pile vide.
##
## tools/ n'importe que core/ et data/ (docs/ARCHITECTURE.md) : ce script lit les JSON
## et transmet des Dictionary à SimCore — core/sim/ ne touche aucun fichier.

const LEVELS_DIR := "res://data/levels/"
const RULES_PATH := "res://data/rules.json"

func _init() -> void:
	var args := _parse_args()
	var level_name: String = args.get("level", "")
	var ticks: int = int(args.get("ticks", "200"))
	var verbose: bool = args.has("verbose")

	if level_name.is_empty():
		push_error("Paramètre requis manquant : --level=<nom> (fichier dans data/levels/)")
		quit(2)
		return

	var level_data := _load_json(LEVELS_DIR + level_name + ".json")
	if level_data.is_empty():
		quit(2)
		return
	var rules_data := _load_json(RULES_PATH)
	if rules_data.is_empty():
		quit(2)
		return

	var stack := _resolve_stack(args, level_data)
	var params := RuleParams.from_dict(rules_data)
	var state := SimCore.load_level(level_data, params)

	print("Volens run_sim — niveau=%s ticks=%d pile=%s" % [level_name, ticks, str(stack)])

	for i in range(ticks):
		state = SimCore.step(state, stack)
		if verbose:
			print("tick %4d  empreinte=%s  sortis=%d perdus=%d  issue=%d" % [
				state.tick, StateHash.to_hex(SimCore.hash_state(state)),
				state.counters.exited, state.counters.lost, state.outcome])

	print("tick final      : %d" % state.tick)
	print("issue           : %s" % ["RUNNING", "WON", "LOST"][state.outcome])
	print("sortis / perdus : %d / %d" % [state.counters.exited, state.counters.lost])
	print("empreinte finale: %s" % StateHash.to_hex(SimCore.hash_state(state)))
	quit(0)

## Analyse les arguments utilisateur (après « -- ») en paires clé/valeur.
func _parse_args() -> Dictionary:
	var out: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		if eq == -1:
			out[body] = ""
		else:
			out[body.substr(0, eq)] = body.substr(eq + 1)
	return out

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Fichier introuvable : " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not (parsed is Dictionary):
		push_error("JSON invalide : " + path)
		return {}
	return parsed

func _resolve_stack(args: Dictionary, level_data: Dictionary) -> Array[int]:
	var stack: Array[int] = []
	var raw: Array = []
	if args.has("stack"):
		for part in String(args["stack"]).split(",", false):
			raw.append(int(part))
	else:
		raw = level_data.get("stack", [])
	for value in raw:
		stack.append(int(value))
	return stack
