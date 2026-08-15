extends SceneTree
## CHERCHE, POUR CHAQUE NIVEAU, LA BIBLIOTHÈQUE QUI LUI REND UN CHOIX.
##
## LE DÉFAUT QU'IL SERT À RÉPARER, mesuré le 15 août 2026 : dans 21 niveaux sur
## 29, la pile peut contenir **toute** la bibliothèque. Le joueur n'a donc rien
## à choisir — son seul travail est l'ordre, parmi six permutations. Or le vrai
## mécanisme de Volens est qu'une règle haute **masque** tout ce qui est en
## dessous : il ne se manifeste que si l'on doit renoncer à quelque chose.
##
## LE GABARIT EXISTE DÉJÀ : ch2_04 offre 4 règles pour 3 rangs, cinq solutions
## en cinq classes, premier gagnant au rang 25 sur 40. C'est la forme visée.
##
## L'outil énumère les élargissements possibles (une ou deux règles ajoutées,
## prises parmi celles que le joueur a déjà rencontrées) et mesure, pour chacun,
## ce qui fait ou non un puzzle. Il ne décide rien : il classe, et le concepteur
## arbitre. Une carte reste une carte — aucune géométrie n'est touchée, donc
## `calibrated_on` tient et les recettes d'or ne bougent pas.
##
## Usage :
##   godot --headless --path . --script res://tools/design/space_search.gd \
##       -- --level=ch3_02          (ou rien : tout le catalogue)

const GUARD := 400

## Le contrat de jouabilité, en chiffres. Chacun vient d'une mesure, pas d'un
## goût — les commentaires disent laquelle.
const MIN_SPACE := 40        # 15 piles s'épuisent en quelques minutes
const MIN_WINNERS := 2       # une seule gagnante fait un cadenas, pas un puzzle
const MAX_WIN_RATIO := 0.20  # ch6_01 gagnait 8 fois sur 15 : une loterie
const MIN_FIRST_RANK := 12   # rang médian actuel : 11, donc la force brute paie
const MIN_SUFFICIENT := 2    # 25 niveaux sur 29 n'ont qu'une seule idée gagnante

var _params: RuleParams

func _init() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

	var only := ""
	var file := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			only = arg.substr(8)
		elif arg.begins_with("--file="):
			file = arg.substr(7)

	# `--file=` mesure un PROTOTYPE hors catalogue. Un niveau qu'il faut d'abord
	# inscrire au catalogue pour le mesurer est un niveau qu'on inscrit avant de
	# savoir s'il vaut quelque chose — et qu'on n'en retire plus.
	if file != "":
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
		if parsed is Dictionary:
			_report(file.get_file(), parsed as Dictionary, ([] as Array[int]))
		quit()
		return

	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		if only != "" and level_id != only:
			continue
		if LevelCatalog.chapter_of(level_id) == 1:
			continue   # le chapitre 1 enseigne : sa maigreur est voulue (CDC §12.2.1)
		_search(level_id)
	quit()

## Les règles que le joueur a déjà RENCONTRÉES à ce point du jeu. Offrir une
## règle jamais vue ne fait pas un choix, cela fait une devinette.
func _seen_by(level_id: String) -> Array[int]:
	var chapter := LevelCatalog.chapter_of(level_id)
	var seen: Array[int] = []
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var other := String(entry["id"])
		if LevelCatalog.chapter_of(other) > chapter:
			continue
		for v in LevelCatalog.load_level_data(other).get("allowed_rules", []):
			var base := RuleRegistry.base_rule_id(int(v))
			if not seen.has(base):
				seen.append(base)
	seen.sort()
	return seen

func _search(level_id: String) -> void:
	var data := LevelCatalog.load_level_data(level_id)
	var current: Array[int] = []
	for v in data.get("allowed_rules", []):
		current.append(int(v))
	var pool: Array[int] = []
	for r in _seen_by(level_id):
		if not current.has(r):
			pool.append(r)
	_report(level_id, data, pool)

func _report(level_id: String, data: Dictionary, pool: Array[int]) -> void:
	var current: Array[int] = []
	for v in data.get("allowed_rules", []):
		current.append(int(v))
	var slots := LevelSpec.open_slots(data)

	print("\n=== %s (rangs %d, actuel %s) ===" % [level_id, slots, str(current)])
	var rows: Array = []
	rows.append(_measure(data, current, slots, "actuel"))
	for a in pool:
		var one := current.duplicate()
		one.append(a)
		rows.append(_measure(data, one, slots, "+R%02d" % a))
	for a in pool:
		for b in pool:
			if b <= a:
				continue
			var two := current.duplicate()
			two.append(a)
			two.append(b)
			rows.append(_measure(data, two, slots, "+R%02d+R%02d" % [a, b]))

	rows.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return int(x["score"]) > int(y["score"]))
	print("  ajout        espace  gagn.  ratio  rang1  idées  contrat  score")
	var shown := 0
	for row in rows:
		if shown >= 8 and String(row["label"]) != "actuel":
			continue
		shown += 1
		print("  %-12s %5d  %4d  %5.2f  %5d  %5d  %-7s  %d" % [
			row["label"], row["space"], row["winners"], row["ratio"],
			row["first"], row["ideas"], "OUI" if row["passes"] else "non",
			row["score"]])

func _measure(data: Dictionary, allowed: Array[int], slots: int, label: String) -> Dictionary:
	var space := 0
	var winners := 0
	var first := -1
	var sets: Array = []
	for stack_variant in StackEnumerator.enumerate(allowed, slots):
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		if stack.is_empty():
			continue
		space += 1
		if _outcome(data, stack) != SimState.Outcome.WON:
			continue
		winners += 1
		if first < 0:
			first = space
		var as_set: Array = stack.duplicate()
		as_set.sort()
		if not sets.has(as_set):
			sets.append(as_set)

	# Idées distinctes = ensembles suffisants MINIMAUX. Si {R01,R04} gagne,
	# {R01,R04,R05} gagne aussi et n'apprend rien de plus.
	var ideas := 0
	for candidate in sets:
		var redundant := false
		for other in sets:
			if other != candidate and _contains(candidate, other):
				redundant = true
				break
		if not redundant:
			ideas += 1

	var ratio: float = float(winners) / float(max(space, 1))
	var passes: bool = space >= MIN_SPACE and winners >= MIN_WINNERS \
		and ratio <= MAX_WIN_RATIO and first >= MIN_FIRST_RANK and ideas >= MIN_SUFFICIENT

	# LE SCORE PRIVILÉGIE LES IDÉES, puis la résistance à la force brute. Une
	# grande liste de gagnantes ne vaut rien si elles disent toutes la même
	# chose : c'est le nombre de MANIÈRES de gagner qui fait le puzzle.
	var score := 0
	if passes:
		score += 1000
	score += ideas * 100
	score += mini(first, 60)
	if winners < MIN_WINNERS:
		score -= 500
	if ratio > MAX_WIN_RATIO:
		score -= int((ratio - MAX_WIN_RATIO) * 1000.0)
	return {
		"label": label, "space": space, "winners": winners, "ratio": ratio,
		"first": first, "ideas": ideas, "passes": passes, "score": score,
	}

func _contains(big: Array, small: Array) -> bool:
	for v in small:
		if not big.has(v):
			return false
	return true

func _outcome(data: Dictionary, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, _params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome
