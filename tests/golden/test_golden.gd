extends GutTest
## Tests d'or (T-021, DCT §11.2) : rejoue chaque recette archivée et compare
## les empreintes aux ticks de contrôle. Toute divergence est une régression
## du déterminisme — bloquante, à corriger, jamais à « mettre à jour »
## (docs/ARCHITECTURE.md règle 1). Version GUT du contrôle ; le script autonome est
## tools/check_golden.gd, les deux partagent GoldenRunner.

func test_rules_fingerprint_is_stable_16_char_hex() -> void:
	var fp := GoldenRunner.rules_fingerprint()
	assert_eq(fp.length(), 16)
	assert_eq(fp, GoldenRunner.rules_fingerprint(), "déterministe entre deux appels")

func test_every_recipe_archives_the_current_rules_fingerprint() -> void:
	# Revue S3 (3.1) : sans l'empreinte des paramètres à côté de la recette,
	# impossible de distinguer plus tard « régression du code » de
	# « changement de paramètre voulu » — au moment précis où on en a besoin.
	var golden := GoldenRunner.load_json(GoldenRunner.GOLDEN_PATH)
	var current := GoldenRunner.rules_fingerprint()
	for recipe in golden.get("recipes", []):
		assert_eq(String(recipe.get("rules_hash", "(absent)")), current,
			"recette %s : empreinte rules.json absente ou périmée" % String(recipe.get("level", "?")))

func test_archived_hashes_are_strings_never_json_numbers() -> void:
	# Revue S3 (1.2) : une empreinte 64 bits stockée en nombre JSON serait
	# tronquée en float64 (exact jusqu'à 2^53) — le test d'or comparerait
	# alors des valeurs corrompues sans jamais échouer.
	var golden := GoldenRunner.load_json(GoldenRunner.GOLDEN_PATH)
	var errors := GoldenRunner.hash_type_errors(golden)
	assert_eq(errors.size(), 0, "empreintes non-String dans golden.json : %s" % ", ".join(errors))

func test_all_golden_recipes_match_their_archived_hashes() -> void:
	var golden := GoldenRunner.load_json(GoldenRunner.GOLDEN_PATH)
	assert_false(golden.is_empty(), "tests/golden/golden.json introuvable ou invalide")

	var recipes: Array = golden.get("recipes", [])
	assert_gte(recipes.size(), 10, "le corpus doit compter au moins 10 recettes (T-021)")

	var checkpoints: Array = golden.get("checkpoints", [])
	for recipe in recipes:
		var level_path: String = recipe["level"]
		var expected: Dictionary = recipe.get("hashes", {})
		assert_false(expected.is_empty(), "recette sans empreintes archivées : %s" % level_path)

		var got := GoldenRunner.run_recipe(level_path, recipe["stack"], checkpoints)
		for cp in got.keys():
			assert_eq(str(got[cp]), str(expected.get(cp, "(absent)")),
				"RÉGRESSION DU DÉTERMINISME — %s pile=%s t=%s" % [level_path, str(recipe["stack"]), cp])
