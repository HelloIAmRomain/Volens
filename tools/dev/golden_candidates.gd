extends SceneTree
## CÉRÉMONIE DU CORPUS D'OR — calcul des candidates, EN LECTURE SEULE.
##
##   godot --headless --path . --script res://tools/dev/golden_candidates.gd
##
## POURQUOI CE SCRIPT EXISTE PLUTÔT QUE `--write`. Le mode `--write` de
## `check_golden.gd` régénère les empreintes de TOUTES les recettes du
## fichier, y compris celles qui existaient déjà. Pour un AJOUT, il
## absorberait donc en silence le seul défaut que la cérémonie doit
## détecter : une empreinte existante qui bouge.
##
## Ici, rien n'est écrit. Le script calcule les empreintes des seules
## recettes candidates ; on les insère ensuite dans `golden.json` sans
## toucher aux entrées existantes, et `check_golden` SANS `--write` sert de
## confrontation — si une ancienne empreinte avait bougé, il échouerait.
##
## Il teste au passage trois propriétés qu'une recette doit avoir pour être
## utile, et le dit quand elles sont fausses :
##   · l'état est STABILISÉ au premier point de contrôle (sinon la recette
##     archive un instantané au milieu d'un mouvement, fragile par nature) ;
##   · la dynamique ne bouge plus entre les points de contrôle (sinon les
##     trois empreintes disent la même chose et deux sont du remplissage) ;
##   · les empreintes candidates sont deux à deux DISTINCTES (deux recettes
##     de même empreinte n'en font qu'une, et la seconde ment sur la
##     couverture du corpus).
##
## `CANDIDATES` est à réécrire à chaque cérémonie : ce fichier est un
## instrument, pas un registre.

const CANDIDATES := [
	["res://data/levels/ch1_01.json", [1]],
	["res://data/levels/ch1_02.json", [1]],
	["res://data/levels/ch1_02.json", [2, 1]],
	["res://data/levels/ch1_03.json", [1]],
	["res://data/levels/ch1_03.json", [2, 1]],
	["res://data/levels/ch1_03.json", [2, 3, 1]],
	["res://data/levels/ch1_03.json", [3, 1]],
	["res://data/levels/ch1_04.json", [1]],
	["res://data/levels/ch1_04.json", [3, 1]],
	["res://data/levels/ch1_04.json", [2, 1]],
	["res://data/levels/ch1_05.json", [1]],
	["res://data/levels/ch1_05.json", [2, 1]],
	["res://data/levels/ch1_05.json", [3, 1]],
]

func _init() -> void:
	var rules := GoldenRunner.load_json(GoldenRunner.RULES_PATH)
	var params := RuleParams.from_dict(rules)
	var seen := {}
	var out: Array = []
	print("recette;h50;h150;h300;dyn50;dyn150;dyn300;present@50;exited@50;lost@50;outcome@50")
	for c in CANDIDATES:
		var path: String = c[0]
		var stack_raw: Array = c[1]
		var stack: Array[int] = []
		for v in stack_raw:
			stack.append(int(v))

		var hashes := GoldenRunner.run_recipe(path, stack_raw, [50, 150, 300])
		# Relecture indépendante pour les mesures de dynamique et de peuplement.
		var state := SimCore.load_level(GoldenRunner.load_json(path), params)
		var dyn := {}
		var snap := {}
		var t := 0
		for cp in [50, 150, 300]:
			while t < cp:
				state = SimCore.step(state, stack)
				t += 1
			dyn[str(cp)] = StateHash.to_hex(StateHash.dynamics_hash(state))
			var present := 0
			for a in state.agents:
				if a.is_present():
					present += 1
			snap[str(cp)] = [present, state.counters.exited, state.counters.lost, state.outcome]

		var label := "%s %s" % [path.get_file().get_basename(), str(stack_raw)]
		var s50: Array = snap["50"]
		print("%s;%s;%s;%s;%s;%s;%s;%d;%d;%d;%d" % [
			label, hashes["50"], hashes["150"], hashes["300"],
			dyn["50"], dyn["150"], dyn["300"],
			s50[0], s50[1], s50[2], s50[3]])

		if seen.has(hashes["50"]):
			print("  ⚠ P2.c FAUSSE : empreinte t=50 identique à « %s »" % seen[hashes["50"]])
		seen[hashes["50"]] = label
		if dyn["50"] != dyn["150"] or dyn["150"] != dyn["300"]:
			print("  ⚠ P2.b FAUSSE : la dynamique bouge encore entre 50 et 300")
		if s50[0] != 0:
			print("  ⚠ P2.a FAUSSE : %d agent(s) encore présent(s) à t=50" % s50[0])
		out.append({"level": path, "stack": stack_raw, "hashes": hashes,
			"rules_hash": GoldenRunner.rules_fingerprint()})

	print("\n--- JSON des nouvelles recettes ---")
	print(JSON.stringify(out))
	quit(0)
