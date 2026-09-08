extends GutTest

## CE FICHIER VÉRIFIE DU TEXTE FRANÇAIS : IL FIXE DONC LA LANGUE (carnet, 211).
## Ce qui est éprouvé ici est le CONTENU, pas la langue — la parité des deux
## langues a son propre fichier, `test_traductions.gd`.
var _locale_avant := ""

func before_all() -> void:
	_locale_avant = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")

func after_all() -> void:
	TranslationServer.set_locale(_locale_avant)
## Garde-fou du diagnostic EF-05 : l'explicateur ne doit jamais MENTIR.
##
## Un diagnostic faux est pire que pas de diagnostic — il envoie le joueur
## chercher au mauvais endroit. Ces tests balaient les niveaux du corpus
## d'or, agent par agent, tick par tick, et confrontent chaque affirmation
## de l'explicateur à l'état réel.
##
## Deux garanties de nature différente :
## 1. STRUCTURELLE — quelle règle a décidé, et lesquelles se sont abstenues :
##    l'explicateur interroge les VRAIES règles, il ne peut pas se tromper.
##    Le test le vérifie quand même : c'est le jour où quelqu'un « optimisera »
##    l'explicateur en réimplémentant la cascade qu'il servira.
## 2. VÉRACITÉ — le MOTIF annoncé est déduit à part, et c'est là que la
##    dérive peut naître. Chaque motif est donc confronté à l'état.

const LEVELS := [
	"res://data/levels/ch1_01.json",
	"res://data/levels/ch1_02.json",
	"res://data/levels/test_smoke.json",
	"res://tests/golden/levels/golden_corridor.json",
	"res://tests/golden/levels/golden_field.json",
]

const STACKS := [[1, 2, 3], [2, 3, 1], [3, 1, 2], [2, 1]]

func _load(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func test_the_deciding_rule_is_always_the_one_the_cascade_would_pick() -> void:
	var checked := 0
	for path in LEVELS:
		var level := _load(path)
		if level.is_empty():
			continue
		for stack_raw in STACKS:
			var stack: Array[int] = []
			for v in stack_raw:
				stack.append(int(v))
			var state := SimCore.load_level(level, RuleParams.new())
			for t in range(12):
				for agent in state.agents:
					if not agent.is_present():
						continue
					var report := RuleExplainer.explain(agent, state, stack)
					var truth := _first_applicable(agent, state, stack)
					assert_eq(int(report["slot"]), truth,
						"%s pile %s t=%d agent %d : l'explicateur désigne %d, la cascade %d" % [
							path.get_file(), str(stack_raw), t, agent.id, int(report["slot"]), truth])
					checked += 1
				state = SimCore.step(state, stack)
	assert_gt(checked, 500, "le balayage doit être significatif (%d décisions vérifiées)" % checked)

func test_every_abstention_motive_matches_the_actual_state() -> void:
	var checked := 0
	for path in LEVELS:
		var level := _load(path)
		if level.is_empty():
			continue
		for stack_raw in STACKS:
			var stack: Array[int] = []
			for v in stack_raw:
				stack.append(int(v))
			var state := SimCore.load_level(level, RuleParams.new())
			for t in range(12):
				for agent in state.agents:
					if not agent.is_present():
						continue
					var report := RuleExplainer.explain(agent, state, stack)
					for line in report["lines"]:
						checked += _check_claim(String(line), agent, state, path, t)
				state = SimCore.step(state, stack)
	assert_gt(checked, 100, "des motifs doivent avoir été rencontrés (%d vérifiés)" % checked)

## Confronte une affirmation à l'état. Renvoie 1 si elle a été vérifiée.
func _check_claim(line: String, agent: AgentState, state: SimState, path: String, tick: int) -> int:
	var where := "%s t=%d agent %d" % [path.get_file(), tick, agent.id]
	if line.contains("aucune lumière sur la carte"):
		assert_eq(_count_cells(state, GridState.CellType.LIGHT_SOURCE), 0,
			"%s : « aucune lumière » alors qu'il y en a" % where)
		return 1
	if line.contains("déjà sur la lumière"):
		assert_eq(state.grid.cell_type_at(agent.pos), GridState.CellType.LIGHT_SOURCE,
			"%s : « déjà sur la lumière » alors qu'il est ailleurs" % where)
		return 1
	if line.contains("aucun danger menaçant"):
		assert_eq(_count_threats(state), 0,
			"%s : « aucun danger menaçant » alors qu'il y en a" % where)
		return 1
	if line.contains("trop loin pour être perçu"):
		var d := _nearest_threat_dist_sq(state, agent.pos)
		assert_gt(d, state.rule_params.flee_perception_range_sq,
			"%s : « trop loin » alors que d² = %d <= portée" % [where, d])
		return 1
	if line.contains("aucun voisin perçu"):
		assert_eq(_perceived(state, agent), 0,
			"%s : « aucun voisin perçu » alors qu'il en a" % where)
		return 1
	return 0

# --- vérité de terrain, calculée indépendamment de l'explicateur -----------

func _first_applicable(agent: AgentState, state: SimState, stack: Array[int]) -> int:
	for i in range(stack.size()):
		var rule := RuleRegistry.get_rule(stack[i])
		if rule != null and rule.evaluate(agent, state, state.rule_params) != Rule.ABSTAIN:
			return i
	return -1

func _count_cells(state: SimState, cell_type: int) -> int:
	var n := 0
	for c in state.grid.cells:
		if c == cell_type:
			n += 1
	return n

func _count_threats(state: SimState) -> int:
	var n := 0
	for y in range(state.grid.size.y):
		for x in range(state.grid.size.x):
			if state.grid.is_danger_active_at(Vector2i(x, y), state.tick + 1):
				n += 1
	return n

func _nearest_threat_dist_sq(state: SimState, from: Vector2i) -> int:
	var best := 1 << 30
	for y in range(state.grid.size.y):
		for x in range(state.grid.size.x):
			var p := Vector2i(x, y)
			if not state.grid.is_danger_active_at(p, state.tick + 1):
				continue
			# R02 choisit le plus proche en MANHATTAN, puis teste sa distance
			# au carré : on reproduit exactement cet ordre.
			var dx: int = p.x - from.x
			var dy: int = p.y - from.y
			best = mini(best, dx * dx + dy * dy)
	return best

func _perceived(state: SimState, agent: AgentState) -> int:
	var n := 0
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - agent.pos.x
		var dy: int = other.pos.y - agent.pos.y
		if dx * dx + dy * dy <= state.rule_params.group_perception_range_sq:
			n += 1
	return n
