extends SceneTree
## L'AUDIT DE JOUABILITÉ, avec le bon compteur.
##
## LE COMPTEUR NAÏF MENT, et il ment TOUJOURS dans le sens rassurant. Compter
## toutes les piles gagnantes attribue à un niveau autant de « solutions » qu'il
## y a de façons de rallonger la même : si [R09] gagne, alors [R09,R01],
## [R09,R05], [R09,R01,R05]… gagnent aussi, et le niveau semble offrir sept
## solutions alors qu'il n'en a **qu'une**, avec du remplissage derrière.
##
## UNE GAGNANTE NE COMPTE QUE SI AUCUNE SOUS-SUITE D'ELLE NE GAGNE DÉJÀ. C'est
## la définition d'une pile gagnante MINIMALE : on retire des rangs sans changer
## l'ordre des rangs restants, et si l'on gagne encore, la pile de départ
## n'apportait rien. Sous-suite et non sous-ensemble — l'ordre est le jeu.
##
## Ce que l'audit rapporte pour chaque niveau :
##   espace     piles non vides énumérables
##   brutes     gagnantes au compteur naïf (celui des fiches `expected_wins`)
##   MINIMALES  gagnantes qui apportent réellement quelque chose
##   ratio      minimales / espace — la vraie permissivité
##   rang1      rang de la première gagnante dans l'ordre d'exploration
##   plancher   longueur de la plus courte gagnante : 1 = une règle suffit
##
## Usage : godot --headless --path . --script res://tools/design/audit.gd

const GUARD := 400

var _params: RuleParams

func _init() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

	print("niveau   rangs lib espace brutes MINI ratio rang1 plancher  objectifs")
	var degenerate := PackedStringArray()
	var lottery := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var row := _audit(level_id)
		var kinds := PackedStringArray()
		for o in LevelCatalog.load_level_data(level_id).get("objectives", []):
			kinds.append(String((o as Dictionary).get("type", "?")))
		print("%-8s %3d  %3d %6d %6d %4d %5.2f %5d %8d  %s" % [
			level_id, row["slots"], row["lib"], row["space"], row["raw"],
			row["minimal"], row["ratio"], row["first"], row["floor"],
			", ".join(kinds)])
		if int(row["floor"]) <= 1 and LevelCatalog.chapter_of(level_id) > 1:
			degenerate.append(level_id)
		if float(row["ratio"]) > 0.10:
			lottery.append(level_id)

	print("\nUNE SEULE RÈGLE SUFFIT (hors chapitre 1) : %s" % (
		", ".join(degenerate) if not degenerate.is_empty() else "aucun"))
	print("PERMISSIVITÉ > 10 %% (minimales) : %s" % (
		", ".join(lottery) if not lottery.is_empty() else "aucun"))
	quit()

func _audit(level_id: String) -> Dictionary:
	var data := LevelCatalog.load_level_data(level_id)
	var allowed: Array[int] = []
	for v in data.get("allowed_rules", []):
		allowed.append(int(v))
	var slots := LevelSpec.open_slots(data)

	var space := 0
	var first := -1
	var winners: Array = []
	for stack_variant in StackEnumerator.enumerate(allowed, slots):
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		if stack.is_empty():
			continue
		space += 1
		if _outcome(data, stack) != SimState.Outcome.WON:
			continue
		if first < 0:
			first = space
		winners.append(stack)

	# MINIMALES : on retire une gagnante dès qu'une de ses sous-suites gagne.
	var minimal: Array = []
	var floor_len := 99
	for stack in winners:
		var redundant := false
		for other in winners:
			if other.size() < stack.size() and _is_subsequence(other, stack):
				redundant = true
				break
		if not redundant:
			minimal.append(stack)
			floor_len = mini(floor_len, (stack as Array).size())
	return {
		"slots": slots, "lib": allowed.size(), "space": space,
		"raw": winners.size(), "minimal": minimal.size(),
		"ratio": float(minimal.size()) / float(maxi(space, 1)),
		"first": first, "floor": floor_len if floor_len < 99 else 0,
	}

## `small` est-elle une SOUS-SUITE de `big` ? On supprime des rangs de `big`
## sans réordonner les autres. Sous-ensemble aurait été faux : [R02,R01] et
## [R01,R02] sont deux piles différentes, et c'est tout le jeu.
func _is_subsequence(small: Array, big: Array) -> bool:
	var j := 0
	for v in big:
		if j < small.size() and small[j] == v:
			j += 1
	return j == small.size()

func _outcome(data: Dictionary, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, _params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome
