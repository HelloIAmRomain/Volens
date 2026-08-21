extends GutTest
## R07 à R16 — les dix règles des chapitres 3 à 6, et le genre EFFET.
##
## CHAQUE RÈGLE EST ÉPROUVÉE LÀ OÙ ELLE TRAVAILLE (invariant n°12). Les cas
## confortables sont nommés dans l'en-tête de chaque règle et volontairement
## ABSENTS d'ici : une piste unique ne prouve rien sur R09, une nuée compacte
## ne prouve rien sur R10, un couloir droit ne prouve rien sur R06.
##
## Ce fichier construit ses états à la main, sans passer par un fichier de
## niveau : c'est le seul moyen de placer un mécanisme exactement au point où
## il décide, plutôt qu'à l'endroit où une carte a bien voulu le mettre.

var _params: RuleParams

func before_each() -> void:
	_params = RuleParams.new()

# --- fabrique ---------------------------------------------------------------

## `rows` : '#' mur, 'L' lumière, 'X' danger, 'R' ressource, 'D' dépôt,
## 'E' sortie, '.' vide.
func _state(rows: Array, positions: Array, dirs: Array = []) -> SimState:
	var state := SimState.new()
	var grid := GridState.new()
	grid.size = Vector2i(String(rows[0]).length(), rows.size())
	var n: int = grid.size.x * grid.size.y
	grid.cells = PackedInt32Array()
	grid.cells.resize(n)
	grid.pheromone = PackedInt32Array()
	grid.pheromone.resize(n)
	grid.cycle_index = PackedInt32Array()
	grid.cycle_index.resize(n)
	for i in range(n):
		grid.cycle_index[i] = -1
	for y in range(rows.size()):
		var line: String = rows[y]
		for x in range(grid.size.x):
			grid.cells[y * grid.size.x + x] = _cell_of(line[x])
	grid._ensure_layers()
	state.grid = grid
	var agents: Array[AgentState] = []
	for i in range(positions.size()):
		var a := AgentState.new()
		a.id = i
		a.pos = positions[i]
		a.dir = int(dirs[i]) if i < dirs.size() else Directions.NORTH
		a.flags = AgentState.PRESENT
		agents.append(a)
	state.agents = agents
	state.counters = Counters.new()
	state.rule_params = _params
	state.tick = 1
	return state

func _cell_of(c: String) -> int:
	match c:
		"#": return GridState.CellType.WALL
		"L": return GridState.CellType.LIGHT_SOURCE
		"X": return GridState.CellType.STATIC_DANGER
		"R": return GridState.CellType.RESOURCE
		"D": return GridState.CellType.DROPOFF
		"E": return GridState.CellType.EXIT
		_:   return GridState.CellType.EMPTY

func _eval(rule_id: int, state: SimState, i: int) -> Vector2i:
	return RuleRegistry.get_rule(rule_id).evaluate(state.agents[i], state, _params)

func _mark(pos: Vector2i, state: SimState, intensity: int) -> void:
	state.grid.pheromone[state.grid.index_of(pos)] = intensity

# --- R07 : ATTENDRE ---------------------------------------------------------

func test_r08_is_an_effect_and_does_not_consume_the_decision() -> void:
	# LE TEST QUI JUSTIFIE LE GENRE EFFET. R08 en tête de pile ne doit PAS
	# empêcher R01 de décider : elle marque, puis rend la main. Si elle
	# consommait la décision, l'agent resterait sur place et toute la
	# stigmergie serait inutilisable.
	var s := _state(["LLL", "...", "..."], [Vector2i(1, 2)])
	var stack: Array[int] = [RuleRegistry.R08_MARK_TRAIL, RuleRegistry.R01_TOWARD_LIGHT]
	var after := SimCore.step(s, stack)
	assert_eq(after.agents[0].pos, Vector2i(1, 1), "R01 doit décider malgré R08 au-dessus")
	assert_gt(after.grid.pheromone[after.grid.index_of(Vector2i(1, 2))], 0,
		"R08 doit avoir marqué la case de DÉPART, pas celle d'arrivée")

func test_r08_marks_the_cell_of_the_snapshot_not_the_destination() -> void:
	# Une piste décalée d'une case est une piste fausse : elle ne relie plus
	# les endroits par lesquels la nuée est réellement passée.
	var s := _state(["LLL", "...", "..."], [Vector2i(1, 2)])
	var stack: Array[int] = [RuleRegistry.R08_MARK_TRAIL, RuleRegistry.R01_TOWARD_LIGHT]
	var after := SimCore.step(s, stack)
	assert_eq(after.grid.pheromone[after.grid.index_of(Vector2i(1, 1))], 0,
		"la case d'ARRIVÉE ne doit pas être marquée à ce tick")

func test_r08_saturates_instead_of_growing_without_bound() -> void:
	# Sans plafond, un agent immobile creuserait un puits d'intensité que R09
	# suivrait éternellement — et l'entier dériverait (invariant n°5).
	var s := _state(["...", "...", "..."], [Vector2i(1, 1)])
	var stack: Array[int] = [RuleRegistry.R08_MARK_TRAIL, RuleRegistry.R03_STAY_GROUPED]
	for i in range(50):
		s = SimCore.step(s, stack)
	assert_lte(s.grid.pheromone[s.grid.index_of(Vector2i(1, 1))], _params.trail_max,
		"l'intensité ne doit jamais dépasser la saturation")

func test_r08_position_in_the_stack_changes_who_marks() -> void:
	# LA PROPRIÉTÉ DE JEU. Au rang 1, tout le monde marque ; sous une règle qui
	# décide partout, plus personne. C'est ce que le joueur découvre en
	# déplaçant la tuile d'un rang, et c'est le sujet du jeu.
	var first: Array[int] = [RuleRegistry.R08_MARK_TRAIL, RuleRegistry.R01_TOWARD_LIGHT]
	var last: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT, RuleRegistry.R08_MARK_TRAIL]
	var a := SimCore.step(_state(["LLL", "...", "..."], [Vector2i(1, 2)]), first)
	var b := SimCore.step(_state(["LLL", "...", "..."], [Vector2i(1, 2)]), last)
	assert_gt(a.grid.pheromone[a.grid.index_of(Vector2i(1, 2))], 0, "au rang 1 : marque")
	assert_eq(b.grid.pheromone[b.grid.index_of(Vector2i(1, 2))], 0,
		"sous R01, qui décide ici, la cascade n'atteint jamais R08")

func test_r09_takes_the_strongest_branch_of_a_fork() -> void:
	# LE CAS D'ÉPREUVE : une piste en Y. Sur une piste unique, n'importe quelle
	# règle de mouvement aurait produit la même trajectoire.
	var s := _state([".....", ".....", "....."], [Vector2i(2, 1)])
	_mark(Vector2i(1, 1), s, 10)   # branche ouest, faible
	_mark(Vector2i(3, 1), s, 40)   # branche est, forte
	assert_eq(_eval(RuleRegistry.R09_FOLLOW_TRAIL, s, 0),
		Directions.offset(Directions.EAST), "R09 doit prendre la branche la plus intense")

func test_r09_abstains_on_a_local_maximum() -> void:
	# Sans cette abstention, l'agent au sommet d'une piste descendrait, puis
	# remonterait, indéfiniment — l'oscillation P3 sous une forme de plus.
	var s := _state([".....", ".....", "....."], [Vector2i(2, 1)])
	_mark(Vector2i(2, 1), s, 50)
	_mark(Vector2i(1, 1), s, 20)
	_mark(Vector2i(3, 1), s, 20)
	assert_eq(_eval(RuleRegistry.R09_FOLLOW_TRAIL, s, 0), Rule.ABSTAIN,
		"au sommet local, R09 doit rendre la main")

func test_r09_abstains_without_any_trail() -> void:
	var s := _state([".....", ".....", "....."], [Vector2i(2, 1)])
	assert_eq(_eval(RuleRegistry.R09_FOLLOW_TRAIL, s, 0), Rule.ABSTAIN,
		"aucune trace : R09 n'a pas d'objet")

func test_the_trail_evaporates_and_therefore_forgets() -> void:
	# Une piste qui ne s'efface pas n'est plus une mémoire, c'est une carte.
	var s := _state(["...", "...", "..."], [Vector2i(0, 0)])
	_mark(Vector2i(2, 2), s, 5)
	var stack: Array[int] = [RuleRegistry.R03_STAY_GROUPED]
	for i in range(6):
		s = SimCore.step(s, stack)
	assert_eq(s.grid.pheromone[s.grid.index_of(Vector2i(2, 2))], 0,
		"la piste doit avoir disparu après son délai")

# --- R10 : REBROUSSER SI SEUL ----------------------------------------------

func test_r11_picks_up_and_the_resource_leaves_the_grid() -> void:
	var s := _state([".R.", "...", "..."], [Vector2i(1, 0)])
	var stack: Array[int] = [RuleRegistry.R11_CARRY, RuleRegistry.R03_STAY_GROUPED]
	var after := SimCore.step(s, stack)
	assert_true((after.agents[0].flags & AgentState.PORTEUR) != 0, "l'agent doit porter")
	assert_eq(after.grid.cell_type_at(Vector2i(1, 0)), GridState.CellType.EMPTY,
		"la ressource doit avoir quitté la grille")

func test_r11_gives_the_contested_resource_to_the_smallest_id() -> void:
	# LE CAS D'ÉPREUVE : deux agents sur la même ressource au même tick. C'est
	# là que le déterminisme du chapitre 4 se joue, pas sur un agent seul.
	var s := _state([".R.", "...", "..."], [Vector2i(1, 0), Vector2i(1, 0)])
	var stack: Array[int] = [RuleRegistry.R11_CARRY, RuleRegistry.R03_STAY_GROUPED]
	var after := SimCore.step(s, stack)
	assert_true((after.agents[0].flags & AgentState.PORTEUR) != 0, "l'id 0 doit l'emporter")
	assert_true((after.agents[1].flags & AgentState.PORTEUR) == 0,
		"l'id 1 ne doit pas ramasser une ressource déjà prise")

func test_r11_does_not_take_a_second_resource() -> void:
	var s := _state([".R.", "...", "..."], [Vector2i(1, 0)])
	s.agents[0].flags |= AgentState.PORTEUR
	var stack: Array[int] = [RuleRegistry.R11_CARRY, RuleRegistry.R03_STAY_GROUPED]
	var after := SimCore.step(s, stack)
	assert_eq(after.grid.cell_type_at(Vector2i(1, 0)), GridState.CellType.RESOURCE,
		"un porteur ne prend pas une seconde ressource")

func test_r11_drops_on_an_ADJACENT_dropoff() -> void:
	# L'adjacence porte tout le chapitre : si le dépôt se faisait en marchant
	# dessus, une case de dépôt serait une sortie de plus et le dépôt inutile.
	#
	# Le dépôt était porté par R12 jusqu'à la fusion du 21 août 2026 ; il vit
	# maintenant dans R11 « Porter et déposer », dont c'est la seconde moitié.
	var s := _state([".D.", "...", "..."], [Vector2i(1, 1)])
	s.agents[0].flags |= AgentState.PORTEUR
	var stack: Array[int] = [RuleRegistry.R11_CARRY, RuleRegistry.R03_STAY_GROUPED]
	var after := SimCore.step(s, stack)
	assert_true((after.agents[0].flags & AgentState.PORTEUR) == 0, "le porteur doit s'être délesté")
	assert_eq(after.counters.delivered, 1, "une livraison doit être comptée")

func test_r11_lets_every_carrier_around_one_dropoff_deliver() -> void:
	# LE CAS D'ÉPREUVE : le dépôt encombré. Un dépôt n'a pas de capacité, et
	# c'est ce qu'il faut vérifier — un porteur seul ne prouverait rien.
	var s := _state(["...", ".D.", "..."],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)])
	for a in s.agents:
		a.flags |= AgentState.PORTEUR
	var stack: Array[int] = [RuleRegistry.R11_CARRY, RuleRegistry.R03_STAY_GROUPED]
	var after := SimCore.step(s, stack)
	assert_eq(after.counters.delivered, 4, "les quatre porteurs adjacents doivent livrer")

func test_a_carrier_never_exits_the_level() -> void:
	# Sortir avec la ressource sur le dos, ce serait la perdre en comptant un
	# succès — et le joueur ne verrait qu'un compteur qui n'avance pas.
	var s := _state([".E.", "...", "..."], [Vector2i(1, 0)])
	s.agents[0].flags |= AgentState.PORTEUR
	var stack: Array[int] = [RuleRegistry.R03_STAY_GROUPED]
	var after := SimCore.step(s, stack)
	assert_true(after.agents[0].is_present(), "un porteur ne sort pas")
	assert_eq(after.counters.exited, 0, "et n'est pas compté comme sorti")

# --- R13 : BOUCHER ----------------------------------------------------------

func test_r13_neutralizes_the_danger_it_walked_into() -> void:
	var s := _state(["...", ".X.", "..."], [Vector2i(1, 0)])
	var stack: Array[int] = [RuleRegistry.R13_PLUG]
	var after := SimCore.step(s, stack)
	assert_false(after.agents[0].is_present(), "l'agent doit s'être consumé")
	assert_eq(after.grid.cell_type_at(Vector2i(1, 1)), GridState.CellType.EMPTY,
		"le danger doit être neutralisé définitivement")

func test_a_death_that_r13_did_not_decide_neutralizes_nothing() -> void:
	# CE QUI DISTINGUE UN SACRIFICE D'UN ACCIDENT. Un agent poussé sur un
	# danger par une autre règle meurt sans rien ouvrir. Le joueur le vérifie
	# en plaçant R13 sous une règle qui décide partout : sa nuée meurt sans
	# jamais dégager le passage.
	var s := _state(["...", ".X.", ".L."], [Vector2i(1, 0)])
	var stack: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT, RuleRegistry.R13_PLUG]
	var after := SimCore.step(s, stack)
	assert_false(after.agents[0].is_present(), "l'agent meurt quand même")
	assert_eq(after.grid.cell_type_at(Vector2i(1, 1)), GridState.CellType.STATIC_DANGER,
		"mais le danger reste : ce n'était pas un sacrifice")

func test_r13_abstains_where_there_is_nothing_to_plug() -> void:
	var s := _state(["...", "...", "..."], [Vector2i(1, 1)])
	assert_eq(_eval(RuleRegistry.R13_PLUG, s, 0), Rule.ABSTAIN,
		"aucun danger adjacent : R13 n'a pas d'objet")

# --- R14 : DISPERSER SI DENSE ----------------------------------------------

func test_r14_abstains_below_the_density_threshold() -> void:
	var s := _state([".......", ".......", "......."], [Vector2i(3, 1), Vector2i(4, 1)])
	assert_eq(_eval(RuleRegistry.R14_SCATTER_IF_DENSE, s, 0), Rule.ABSTAIN,
		"un seul voisin : rien à disperser")

func test_r14_leaves_the_crowd_for_the_emptier_side() -> void:
	# LE CAS D'ÉPREUVE : la foule d'un seul côté. L'agent doit s'en éloigner,
	# et le pas choisi doit réduire le nombre de congénères qui l'entourent.
	var positions := [Vector2i(5, 1)]
	for x in range(1, 5):
		for y in range(0, 3):
			positions.append(Vector2i(x, y))
	var s := _state(["..........", "..........", ".........."], positions)
	var move := _eval(RuleRegistry.R14_SCATTER_IF_DENSE, s, 0)
	assert_ne(move, Rule.ABSTAIN, "seuil franchi : R14 doit parler")
	var before := RuleScatterIfDense._crowd_around(s.agents[0], s, Vector2i(5, 1), _params.dense_range_sq)
	var after := RuleScatterIfDense._crowd_around(s.agents[0], s, Vector2i(5, 1) + move, _params.dense_range_sq)
	assert_lt(after, before, "le pas choisi doit réduire l'entourage")

func test_r14_and_r04_answer_different_shapes() -> void:
	# Si les deux règles se déclenchaient toujours ensemble, l'une des deux
	# serait de trop. Un cordon d'une case de large est partout ADJACENT sans
	# être DENSE : R04 parle, R14 se tait.
	var s := _state(["..........", "..........", ".........."],
		[Vector2i(4, 1), Vector2i(3, 1), Vector2i(5, 1), Vector2i(4, 0)])
	assert_ne(_eval(RuleRegistry.R04_SPREAD_OUT, s, 0), Rule.ABSTAIN,
		"trois voisins au contact : R04 parle")
	assert_eq(_eval(RuleRegistry.R14_SCATTER_IF_DENSE, s, 0), Rule.ABSTAIN,
		"mais la zone n'est pas dense : R14 se tait")

# --- R15 : SUIVRE LE PLUS LENT ---------------------------------------------

func test_r15_waits_for_the_agent_furthest_from_the_goal() -> void:
	# LE CAS D'ÉPREUVE : la nuée ÉTIRÉE. Sur une nuée compacte, tous les écarts
	# sont nuls et R15 ne se déclencherait jamais.
	var s := _state(["..L..", ".....", ".....", ".....", ".....", ".....", "....."],
		[Vector2i(2, 1), Vector2i(2, 6)])
	assert_eq(_eval(RuleRegistry.R15_FOLLOW_THE_SLOWEST, s, 0), Vector2i.ZERO,
		"cinq cases d'avance sur le dernier : l'agent de tête attend")

func test_r15_tolerates_a_gap_exactly_equal_to_the_threshold() -> void:
	# « SUR LE FIL » EST TOLÉRÉ, comme pour l'échéance de célérité (ENF-04) : le
	# seuil est un maximum admis, pas un maximum interdit. Le dire ici évite
	# qu'on le déplace d'une unité un jour, en croyant corriger un décalage.
	var s := _state(["..L..", ".....", ".....", ".....", "....."],
		[Vector2i(2, 1), Vector2i(2, 4)])
	assert_eq(_params.pace_max_gap, 3, "prémisse du test : le seuil vaut 3")
	assert_eq(_eval(RuleRegistry.R15_FOLLOW_THE_SLOWEST, s, 0), Rule.ABSTAIN,
		"un écart EXACTEMENT égal au seuil ne déclenche pas l'attente")

func test_r15_abstains_when_the_group_is_tight() -> void:
	var s := _state(["..L..", ".....", ".....", ".....", "....."],
		[Vector2i(2, 1), Vector2i(2, 2)])
	assert_eq(_eval(RuleRegistry.R15_FOLLOW_THE_SLOWEST, s, 0), Rule.ABSTAIN,
		"groupe resserré : R15 rend la main")

func test_r15_abstains_without_a_light_to_measure_against() -> void:
	# Sans référentiel commun, « en retard » n'a pas de sens : deux agents
	# éloignés seraient chacun le retardataire de l'autre, et la nuée entière
	# s'immobiliserait.
	var s := _state([".....", ".....", "....."], [Vector2i(0, 0), Vector2i(4, 2)])
	assert_eq(_eval(RuleRegistry.R15_FOLLOW_THE_SLOWEST, s, 0), Rule.ABSTAIN,
		"aucune lumière : R15 n'a pas de référentiel")

func test_r15_ignores_agents_that_already_left() -> void:
	# Sans quoi la nuée attendrait éternellement des agents ayant déjà réussi.
	var s := _state(["..L..", ".....", ".....", ".....", "....."],
		[Vector2i(2, 1), Vector2i(2, 4)])
	s.agents[1].flags = AgentState.SORTI
	assert_eq(_eval(RuleRegistry.R15_FOLLOW_THE_SLOWEST, s, 0), Rule.ABSTAIN,
		"le retardataire est sorti : plus personne à attendre")

# --- R16 : LE JOKER ---------------------------------------------------------

func test_r16_encodes_its_argument_without_changing_the_stack_type() -> void:
	var joker := RuleRegistry.make_joker(GridState.CellType.STATIC_DANGER)
	assert_eq(RuleRegistry.base_rule_id(joker), RuleRegistry.R16_IGNORE,
		"la base doit rester R16")
	assert_eq(RuleRegistry.ignored_cell_of(joker), GridState.CellType.STATIC_DANGER,
		"l'argument doit se relire")
	assert_eq(RuleRegistry.ignored_cell_of(RuleRegistry.R01_TOWARD_LIGHT), -1,
		"une règle ordinaire n'est pas un joker")

func test_r16_lets_the_swarm_walk_through_fire() -> void:
	var rows := [".L.", ".X.", "..."]
	var plain: Array[int] = [RuleRegistry.R01_TOWARD_LIGHT]
	var joker: Array[int] = [RuleRegistry.make_joker(GridState.CellType.STATIC_DANGER),
		RuleRegistry.R01_TOWARD_LIGHT]
	var a := SimCore.step(_state(rows, [Vector2i(1, 2)]), plain)
	var b := SimCore.step(_state(rows, [Vector2i(1, 2)]), joker)
	assert_false(a.agents[0].is_present(), "sans joker, l'agent meurt sur le danger")
	assert_true(b.agents[0].is_present(), "avec le joker, il traverse")

func test_r16_makes_a_closed_door_and_a_one_way_traversable() -> void:
	# DÉFAUT MESURÉ le 14 août 2026, et c'est le genre qu'aucune relecture ne
	# trouve : le joker était consulté par la LÉTALITÉ (« l'agent meurt-il sur
	# cette case ? ») mais pas par le FRANCHISSEMENT (« ce pas est-il
	# possible ? »). « Ignorer les portes » ne franchissait donc aucune porte, et
	# le niveau qui en dépendait restait insoluble sans qu'aucun test ne bronche.
	#
	# La correction porte sur `GridState.ignored_cell` : le joker vit là où les
	# règles posent leur question, pas à côté.
	var s := _state(["...", "...", "..."], [Vector2i(1, 2)])
	var door := s.grid.index_of(Vector2i(1, 1))
	s.grid.cells[door] = GridState.CellType.PRESSURE_DOOR
	s.grid.door_index[door] = 0
	s.grid.doors = [DoorDef.new()]
	s.grid.doors_open = PackedInt32Array([0])   # fermée
	assert_false(s.grid.can_traverse(Vector2i(1, 2), Vector2i(1, 1)),
		"sans joker, une porte fermée n'est pas franchissable")
	s.grid.ignored_cell = GridState.CellType.PRESSURE_DOOR
	assert_true(s.grid.can_traverse(Vector2i(1, 2), Vector2i(1, 1)),
		"avec le joker, elle doit l'être — c'est tout ce que le joker fait")

	var t := _state(["...", "...", "..."], [Vector2i(1, 2)])
	t.grid.one_way_dir[t.grid.index_of(Vector2i(1, 1))] = Directions.SOUTH
	assert_false(t.grid.can_traverse(Vector2i(1, 2), Vector2i(1, 1)),
		"sans joker, on n'entre pas à contresens dans un sens unique")
	t.grid.ignored_cell = GridState.CellType.ONE_WAY
	assert_true(t.grid.can_traverse(Vector2i(1, 2), Vector2i(1, 1)),
		"avec le joker, le sens unique cesse de contraindre")

func test_r16_never_opens_a_wall() -> void:
	# Le joker qui annulerait les murs ouvrirait tous les niveaux d'un coup, et
	# un jeu dont la dernière règle annule la géométrie n'a plus de niveaux.
	var s := _state([".L.", "###", "..."], [Vector2i(1, 2)])
	s.ignored_cell = GridState.CellType.WALL
	assert_false(s.grid.can_traverse_ignoring(Vector2i(1, 2), Vector2i(1, 1),
		GridState.CellType.WALL), "un mur reste un mur, joker ou non")

func test_r16_costs_a_rank_and_proposes_nothing() -> void:
	var s := _state([".L.", "...", "..."], [Vector2i(1, 2)])
	assert_eq(_eval(RuleRegistry.R16_IGNORE, s, 0), Rule.ABSTAIN,
		"R16 ne propose jamais de déplacement")

# --- propriétés communes des seize règles ----------------------------------

func test_every_declared_rule_is_registered() -> void:
	assert_eq(RuleRegistry.ALL.size(), 13,
		("treize règles : retrait de R07 et R10 (carnet, 189), puis fusion de R12 "
		+ "« Déposer au but » dans R11 « Porter et déposer » (carnet, 206)"))
	for id in RuleRegistry.ALL:
		assert_not_null(RuleRegistry.get_rule(id), "R%02d doit être enregistrée" % id)

func test_every_rule_returns_a_unit_step_or_abstains() -> void:
	# Un pas diagonal ou double casserait la résolution de conflits sans
	# qu'aucun test de niveau ne le dise.
	var legal := [Rule.ABSTAIN, Vector2i.ZERO]
	for d in Directions.ORDER:
		legal.append(Directions.offset(d))
	var s := _state(["#####", "#.R.#", "#.X.#", "#D.L#", "#####"],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 3)],
		[Directions.NORTH, Directions.EAST, Directions.SOUTH, Directions.WEST])
	_mark(Vector2i(2, 1), s, 20)
	var checked := 0
	for id in RuleRegistry.ALL:
		var rule := RuleRegistry.get_rule(id)
		if rule.kind() == Rule.Kind.EFFECT:
			continue
		for i in range(s.agents.size()):
			checked += 1
			assert_true(legal.has(_eval(id, s, i)),
				"R%02d, agent %d : sortie hors du jeu légal" % [id, i])
	assert_gt(checked, 0, "aucune règle de déplacement examinée : le filtre a tout écarté")

func test_effect_rules_never_decide_a_movement() -> void:
	# La propriété qui définit le genre. Si un effet décidait, la cascade
	# s'arrêterait sur lui et la règle d'or reformulée serait fausse.
	var s := _state([".R.", ".D.", "..."], [Vector2i(1, 0)])
	var effects := 0
	for id in RuleRegistry.ALL:
		var rule := RuleRegistry.get_rule(id)
		if rule.kind() != Rule.Kind.EFFECT:
			continue
		effects += 1
		assert_eq(rule.evaluate(s.agents[0], s, _params), Rule.ABSTAIN,
			"R%02d est un effet : elle ne doit jamais proposer de pas" % id)
	assert_gt(effects, 0, "aucune règle d'effet trouvée : le genre a disparu")
