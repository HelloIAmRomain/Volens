extends SceneTree
## Tests d'or autonomes (T-021) — non-régression du déterminisme [DT-09].
##
##   godot --headless --path . --script res://tools/check_golden.gd
##
## Vérifie chaque recette de tests/golden/golden.json : rejoue et compare
## les empreintes aux ticks archivés. Toute divergence est une RÉGRESSION
## DU DÉTERMINISME à corriger — jamais une valeur à mettre à jour
## (docs/ARCHITECTURE.md, règle 1).
##
## Mode --write : RÉGÉNÈRE le fichier d'or à partir des recettes qu'il
## contient. À n'utiliser que sur décision humaine explicite (création
## initiale du corpus, ou changement de comportement voulu, documenté et
## assumé). La CI n'utilise jamais ce mode.

func _init() -> void:
	var write_mode := OS.get_cmdline_user_args().has("--write")
	var golden := GoldenRunner.load_json(GoldenRunner.GOLDEN_PATH)
	if golden.is_empty():
		quit(2)
		return

	# Échec bruyant si une empreinte n'est pas une String (troncature float64
	# sinon). Le mode --write reste permis : c'est le chemin de réparation.
	var type_errors := GoldenRunner.hash_type_errors(golden)
	if not write_mode and not type_errors.is_empty():
		for e in type_errors:
			print("TYPE    " + e)
		print("\nEmpreinte non textuelle : golden.json corrompu (risque de troncature flottante).")
		quit(2)
		return

	var recipes: Array = golden.get("recipes", [])
	var failures := 0
	var rules_fp := GoldenRunner.rules_fingerprint()

	for recipe in recipes:
		var level_path: String = recipe["level"]
		var stack: Array = recipe["stack"]
		var expected: Dictionary = recipe.get("hashes", {})
		var checkpoints: Array = golden.get("checkpoints", [50, 150, 300])

		var got := GoldenRunner.run_recipe(level_path, stack, checkpoints)
		if got.is_empty():
			print("ERREUR  %s %s : recette inexécutable" % [level_path, str(stack)])
			failures += 1
			continue

		if write_mode:
			recipe["hashes"] = got
			recipe["rules_hash"] = rules_fp  # revue S3, 3.1
			print("ÉCRIT   %s %s : %s" % [level_path, str(stack), str(got)])
			continue

		var recipe_ok := true
		for cp in got.keys():
			if str(expected.get(cp, "")) != str(got[cp]):
				print("ÉCHEC   %s %s @t=%s : attendu %s, obtenu %s" % [
					level_path, str(stack), cp, expected.get(cp, "(absent)"), got[cp]])
				recipe_ok = false
				failures += 1
		if recipe_ok:
			print("OK      %s %s" % [level_path, str(stack)])
		else:
			var archived_fp: String = String(recipe.get("rules_hash", ""))
			if not archived_fp.is_empty() and archived_fp != rules_fp:
				print("        ⚠ data/rules.json a changé depuis l'archivage (%s -> %s) : divergence peut-être voulue (rééquilibrage) — à trancher humainement, jamais automatiquement." % [archived_fp, rules_fp])

	if write_mode:
		var file := FileAccess.open(GoldenRunner.GOLDEN_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(golden, "  ") + "\n")
		file.close()
		print("\n⚠ Fichier d'or RÉÉCRIT (%d recettes). Geste exceptionnel : à justifier au carnet de bord." % recipes.size())
		quit(0)
		return

	if failures > 0:
		print("\n%d divergence(s) : RÉGRESSION DU DÉTERMINISME — à corriger, pas à mettre à jour." % failures)
		quit(1)
	else:
		print("\nToutes les recettes d'or concordent (%d)." % recipes.size())
		quit(0)
