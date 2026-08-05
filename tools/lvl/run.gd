extends SceneTree
## CLI du convertisseur de niveaux (avance sur T-074) :
##
##   godot --headless --path . --script res://tools/lvl/run.gd -- \
##       --in=data/levels/ch1_01.lvl [--out=res://data/levels] [--validate]
##
## Convertit un fichier `.lvl` en JSON de niveau dans data/levels/, et avec
## `--validate` enchaîne le validateur (DT-15 : le même SimCore que le jeu)
## sur le niveau produit — l'aller-retour conception -> mesure en une
## commande.

const DEFAULT_OUT := "res://data/levels"

func _init() -> void:
	var args := _parse_args()
	var in_path: String = args.get("in", "")
	if in_path.is_empty():
		push_error("Paramètre requis : --in=<chemin du fichier .lvl>")
		quit(2)
		return
	if not in_path.begins_with("res://"):
		in_path = "res://" + in_path
	if not FileAccess.file_exists(in_path):
		push_error("Fichier introuvable : " + in_path)
		quit(2)
		return

	var rules_data := GoldenRunner.load_json(GoldenRunner.RULES_PATH)
	if rules_data.is_empty():
		quit(2)
		return
	var validation: Dictionary = rules_data.get("validation", {})
	var min_period := int(validation.get("min_cycle_period", ValidateLib.MIN_CYCLE_PERIOD_DEFAULT))

	var parsed := LvlParser.parse(FileAccess.get_file_as_string(in_path), min_period)
	var errors: PackedStringArray = parsed["errors"]
	if not errors.is_empty():
		print("Niveau REFUSÉ — %d erreur(s) :" % errors.size())
		for e in errors:
			print("  ✗ " + e)
		quit(1)
		return

	var level: Dictionary = parsed["level"]
	var level_id := String(level.get("id", ""))
	if level_id.is_empty():
		level_id = in_path.get_file().get_basename()
	var out_dir := String(args.get("out", DEFAULT_OUT))
	var out_path := out_dir + "/" + level_id + ".json"
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("Écriture impossible : " + out_path)
		quit(2)
		return
	file.store_string(JSON.stringify(level, "  ") + "\n")
	file.close()
	print("Converti : %s -> %s (%d agents, %d×%d)" % [
		in_path, out_path, (level["agents"] as Array).size(),
		level["grid"]["size"][0], level["grid"]["size"][1]])

	if not args.has("validate"):
		quit(0)
		return

	var report := ValidateLib.validate_level(level, RuleParams.from_dict(rules_data), min_period)
	var summary: Dictionary = report["summary"]
	print("piles simulées   : %d (slots : %d)" % [summary["n_stacks"], summary.get("slots", 4)])
	print("piles gagnantes  : %d / %d (%d %%)" % [summary["n_win"], summary.get("n_total", 0), summary.get("win_ratio_percent", 0)])
	if int(summary.get("expected_wins", -1)) >= 0:
		print("fiche            : attendu %d, constaté %d" % [summary["expected_wins"], summary["n_win"]])
	if summary["min_ticks"] >= 0:
		print("étalon efficience: %d ticks, pile %s" % [summary["min_ticks"], str(summary["best_stack"])])
	print("verdict          : %s" % summary["qn01_verdict"])
	quit(0)

func _parse_args() -> Dictionary:
	var out: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		out[body.substr(0, eq)] = body.substr(eq + 1) if eq != -1 else ""
	return out
