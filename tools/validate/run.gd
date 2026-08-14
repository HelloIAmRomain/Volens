extends SceneTree
## Validateur v1 en ligne de commande (T-024, DCT §8, EQ-01).
##
##   godot --headless --path . --script res://tools/validate/run.gd -- \
##       --level=test_smoke [--out=reports/validate]
##
## --level accepte un nom (cherché dans data/levels/) ou un chemin res://.
## Produit <niveau>.csv (une ligne par pile) et <niveau>.summary.json dans
## le répertoire de sortie (res://reports/validate/ par défaut, ignoré par
## Git : les rapports sont des artefacts, pas des sources).

const LEVELS_DIR := "res://data/levels/"
const DEFAULT_OUT := "res://reports/validate"

func _init() -> void:
	var args := _parse_args()
	var level_arg: String = args.get("level", "")
	if level_arg.is_empty():
		push_error("Paramètre requis : --level=<nom ou chemin res://>")
		quit(2)
		return

	var level_path := level_arg if level_arg.begins_with("res://") else LEVELS_DIR + level_arg + ".json"
	var level_name := level_path.get_file().get_basename()
	var level_data := GoldenRunner.load_json(level_path)
	var rules_data := GoldenRunner.load_json(GoldenRunner.RULES_PATH)
	if level_data.is_empty() or rules_data.is_empty():
		quit(2)
		return

	# Plancher de période ⚙️ : surchargeable depuis data/rules.json.
	var validation: Dictionary = rules_data.get("validation", {})
	var min_period := int(validation.get("min_cycle_period", ValidateLib.MIN_CYCLE_PERIOD_DEFAULT))
	var report := ValidateLib.validate_level(level_data, RuleParams.from_dict(rules_data), min_period)
	var summary: Dictionary = report["summary"]

	var out_dir: String = args.get("out", DEFAULT_OUT)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_write_csv(out_dir + "/" + level_name + ".csv", report["rows"])
	_write_json(out_dir + "/" + level_name + ".summary.json", summary)

	print("Volens validate v1 — %s" % level_name)
	print("piles simulées   : %d (attendu : %d, slots : %d)" % [summary["n_stacks"], summary["expected_stacks"], (int(summary["slots"]) if summary.has("slots") else LevelSpec.MAX_SLOTS)])
	print("piles gagnantes  : %d / %d (%d %%), en %d classe(s) structurelle(s)" % [summary["n_win"], summary.get("n_total", summary["n_stacks"]), summary.get("win_ratio_percent", 0), summary["n_win_classes"]])
	if summary.has("expected_wins") and int(summary["expected_wins"]) >= 0:
		print("fiche            : attendu %d, constaté %d" % [summary["expected_wins"], summary["n_win"]])
	if summary["min_ticks"] >= 0:
		print("étalon efficience: %d ticks, pile %s" % [summary["min_ticks"], str(summary["best_stack"])])
	var contention: Dictionary = summary.get("contention_by_pair", {})
	if not contention.is_empty():
		var keys := contention.keys()
		keys.sort()
		var parts := PackedStringArray()
		for k in keys:
			parts.append("R%s %d" % [String(k).replace("-", "/R"), int(contention[k])])
		print("contention RG-13 : %s   (0 = ordre inobservable)" % "   ".join(parts))
	# QN-03 : l'outil MESURE, il ne juge pas — le seuil plancher n'est pas fixé.
	print("echecs proches   : %d / %d perdantes (%d %%)   [QN-03, seuil plancher non fixe]" % [
		int(summary.get("n_near_misses", 0)), int(summary.get("n_losses", 0)),
		int(summary.get("near_miss_ratio_percent", 0))])
	if int(summary.get("wins_with_oscillation", 0)) > 0:
		print("sur-place        : %d pile(s) gagnante(s), jusqu'à %d agent(s) — à corriger au dessin" % [
			summary["wins_with_oscillation"], summary["max_oscillating_agents"]])
	# RG-18 : ce que le concepteur doit savoir pour inscrire des défis JUSTES.
	var abstinence: PackedInt32Array = summary.get("challenge_abstinence_options", PackedInt32Array())
	var abst_names := PackedStringArray()
	for r in abstinence:
		abst_names.append("R%02d" % int(r))
	print("defis RG-18      : economie %s   abstinence possible sur %s   efficience >= %d ticks" % [
		"POSSIBLE" if bool(summary.get("challenge_economy_possible", false)) else "impossible",
		", ".join(abst_names) if abst_names.size() > 0 else "aucune regle",
		int(summary.get("min_ticks", -1))])
	print("verdict QN-01    : %s" % summary["qn01_verdict"])
	print("rapports         : %s/%s.{csv,summary.json}" % [out_dir, level_name])
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

func _write_csv(path: String, rows: Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_line("stack;outcome;ticks;exited;lost;manque_%;oscillating;stuck;final_hash;looped")
	var outcome_names := ["RUNNING", "WON", "LOST"]
	for row in rows:
		var stack_str := "-".join(PackedStringArray(Array(row["stack"]).map(func(v: Variant) -> String: return str(int(v)))))
		# `manque_%` : distance à l'objectif d'une pile perdante (QN-03).
		# Vide pour une pile gagnante — elle n'a rien manqué.
		var shortfall: String = "" if int(row["outcome"]) == SimState.Outcome.WON \
			else str(int(row.get("shortfall_percent", 100)))
		file.store_line("%s;%s;%d;%d;%d;%s;%d;%d;%s;%s" % [
			stack_str if not stack_str.is_empty() else "(vide)",
			outcome_names[row["outcome"]], row["ticks"], row["exited"],
			row["lost"], shortfall, row["oscillating"], row["stuck"],
			row["final_hash"], str(row["looped"])])
	file.close()

func _write_json(path: String, summary: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "  ") + "\n")
	file.close()
