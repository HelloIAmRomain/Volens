extends SceneTree
## Calcule les ENSEMBLES SUFFISANTS de chaque niveau, pour le mode Contrainte.
##
##   godot --headless --path . --script res://tools/arcade/build.gd
##
## UN ENSEMBLE SUFFISANT est un ensemble de règles — non ordonné — tel qu'il
## existe au moins une pile gagnante n'employant que ces règles. Le mode
## Contrainte tire les règles offertes au joueur ; sans cette table, un tirage
## pourrait ne contenir aucune solution, et le niveau serait injouable sans que
## rien ne le dise.
##
## ON NE STOCKE QUE DES ENSEMBLES, JAMAIS DES ORDRES, et c'est le cœur du mode :
## il retire au joueur la question « quelles règles ? » et lui laisse
## entièrement celle qui est le sujet du jeu — « dans quel ordre ? ». Le fichier
## produit ne révèle donc aucune solution.
##
## ON NE GARDE QUE LES ENSEMBLES MINIMAUX : si {R01, R04} suffit, {R01, R04,
## R05} suffit aussi et n'apprend rien. Les minimaux sont exactement ce qu'il
## faut pour construire un tirage juste et serré.
##
## LE FICHIER EST DÉRIVÉ, DONC IL PEUT MENTIR. `tests/unit/test_arcade.gd` le
## recalcule et refuse toute divergence — même dispositif que `calibrated_on`
## pour les paramètres de carte, et pour la même raison.
const OUT_PATH := "res://data/arcade.json"

func _init() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	var params := RuleParams.from_dict(rules as Dictionary)
	var out: Dictionary = {
		"_comment": "GÉNÉRÉ par tools/arcade/build.gd — ne pas éditer à la main. "
			+ "Ensembles de règles (non ordonnés) suffisant à gagner. "
			+ "Vérifié par tests/unit/test_arcade.gd.",
		"levels": {},
	}
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var sets := ArcadeSets.minimal_sufficient_sets(
			LevelCatalog.load_level_data(level_id), params)
		var as_arrays: Array = []
		for s in sets:
			as_arrays.append(s)
		out["levels"][level_id] = as_arrays
		print("%-9s %d ensemble(s) minimal(aux) : %s" % [level_id, sets.size(), str(sets)])
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ") + "\n")
	f.close()
	print("\nÉcrit : %s" % OUT_PATH)
	quit(0)
