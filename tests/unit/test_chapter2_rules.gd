extends GutTest
## R04, R05, R06 — le moteur du chapitre 2 (CDC §7.2, la coordination).
##
## CHAQUE RÈGLE EST ÉPROUVÉE LÀ OÙ ELLE TRAVAILLE, jamais là où elle est
## confortable (invariant n°12). Le chapitre 1 a coûté trois semaines à
## réapprendre ce point sur R03, puis l'a réappris deux fois encore sur la
## contention et sur le cadrage. Ici, explicitement :
##
##   · R04 se juge sur un GOULOT — sur une nuée dispersée elle n'a rien à
##     écarter et paraîtra toujours correcte ;
##   · R05 se juge sur une nuée DIVISÉE — sur un courant unanime elle n'a
##     rien départagé ;
##   · R06 se juge sur un CONTOUR CONCAVE — sur un couloir droit elle avance
##     tout droit comme n'importe quelle autre règle.
##
## Aucun de ces tests ne passe par un fichier de niveau : ils construisent
## l'état à la main pour placer le mécanisme exactement au point où il décide.

var _params: RuleParams

func before_each() -> void:
	_params = RuleParams.new()

# --- fabrique d'états minimale ---------------------------------------------

## `rows` : une chaîne par rangée, '#' = mur, tout le reste = libre.
func _state(rows: Array, positions: Array, dirs: Array = []) -> SimState:
	var state := SimState.new()
	var grid := GridState.new()
	grid.size = Vector2i(String(rows[0]).length(), rows.size())
	grid.cells = PackedInt32Array()
	grid.cells.resize(grid.size.x * grid.size.y)
	grid.pheromone = PackedInt32Array()
	grid.pheromone.resize(grid.size.x * grid.size.y)
	grid.cycle_index = PackedInt32Array()
	grid.cycle_index.resize(grid.size.x * grid.size.y)
	for y in range(rows.size()):
		var line: String = rows[y]
		for x in range(grid.size.x):
			grid.cells[y * grid.size.x + x] = (GridState.CellType.WALL
				if line[x] == "#" else GridState.CellType.EMPTY)
			grid.cycle_index[y * grid.size.x + x] = -1
	state.grid = grid
	var agents: Array[AgentState] = []
	for i in range(positions.size()):
		var a := AgentState.new()
		a.id = i
		a.pos = positions[i]
		a.dir = int(dirs[i]) if i < dirs.size() else Directions.NORTH
		agents.append(a)
	state.agents = agents
	# SIMULATION EN COURS, pas état neuf. R05 se tait au tick 0 — personne n'a
	# encore bougé — et une fabrique qui livrerait des états au tick 0 ferait
	# passer ses tests pour une raison qui n'est pas celle qu'ils examinent.
	# Le test du premier tick repose `tick = 0` lui-même, explicitement.
	state.tick = 1
	return state

func _eval(rule_id: int, state: SimState, agent_index: int) -> Vector2i:
	return RuleRegistry.get_rule(rule_id).evaluate(state.agents[agent_index], state, _params)

# --- R04 : S'ÉCARTER, éprouvée sur un goulot -------------------------------

func test_r04_abstains_below_the_threshold() -> void:
	# Deux voisins serrés, seuil à 3 : rien à desserrer, la cascade continue.
	# C'est l'abstention naturelle qui empêche R04 de geler la pile (P1).
	var s := _state(["......", "......", "......"],
		[Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 1)])
	assert_eq(_eval(RuleRegistry.R04_SPREAD_OUT, s, 0), Rule.ABSTAIN,
		"deux voisins pour un seuil de trois : R04 doit se taire")

func test_r04_loosens_a_bottleneck() -> void:
	# LE CAS D'ÉPREUVE. Quatre agents serrés autour de l'agent 0 dans un
	# couloir d'une rangée de haut : le seuil est franchi et la seule issue
	# qui augmente la distance au barycentre est l'Ouest.
	var s := _state(["########", "#......#", "########"],
		[Vector2i(4, 1), Vector2i(3, 1), Vector2i(5, 1), Vector2i(5, 1), Vector2i(3, 1)])
	var move := _eval(RuleRegistry.R04_SPREAD_OUT, s, 0)
	assert_ne(move, Rule.ABSTAIN, "seuil franchi : R04 doit proposer un desserrement")
	assert_eq(move.y, 0, "le couloir est horizontal : aucun pas vertical possible")

func test_r04_abstains_when_no_direction_loosens() -> void:
	# Emmuré : aucune case franchissable n'augmente la distance. R04 rend la
	# main plutôt que de proposer un pas impossible — sinon elle masquerait la
	# suite de la pile exactement comme R03 v1 (pathologie P1).
	var s := _state(["###", "#.#", "###"],
		[Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)])
	assert_eq(_eval(RuleRegistry.R04_SPREAD_OUT, s, 0), Rule.ABSTAIN,
		"aucune issue ne desserre : R04 doit rendre la main")

func test_r04_and_r03_never_propose_the_same_step() -> void:
	# LA PROPRIÉTÉ EST « JAMAIS LE MÊME PAS », PAS « LE PAS OPPOSÉ ».
	#
	# La première rédaction de ce test exigeait `spread == -group`, et elle
	# était FAUSSE — pas le code, l'assertion. Minimiser la distance au
	# barycentre a ici un optimum unique (l'Est) ; la maximiser en a deux, le
	# Nord et l'Ouest à égalité, et l'ordre N>E>S>O tranche pour le Nord. Un
	# « exact opposé » n'existe que si les deux optimisations sont uniques, ce
	# que rien ne garantit sur une grille.
	#
	# Ce qui doit être vrai, en revanche, l'est toujours : R03 rapproche
	# strictement, R04 éloigne strictement, donc elles ne peuvent jamais
	# proposer le même pas. Si elles le faisaient, l'une des deux serait écrite
	# à l'envers, et aucun niveau ne le dirait.
	var s := _state(["........", "........", "........"],
		[Vector2i(4, 1), Vector2i(5, 1), Vector2i(5, 0), Vector2i(5, 2)])
	var spread := _eval(RuleRegistry.R04_SPREAD_OUT, s, 0)
	_params.group_min_neighbours = 99   # force R03 à ne jamais se croire groupée
	var group := _eval(RuleRegistry.R03_STAY_GROUPED, s, 0)
	assert_ne(spread, Rule.ABSTAIN, "R04 doit parler sur ce voisinage")
	assert_ne(group, Rule.ABSTAIN, "R03 doit parler sur ce voisinage")
	assert_ne(spread, group, "R03 et R04 ne peuvent jamais proposer le même pas")

# --- R05 : SUIVRE LES VOISINS, éprouvée sur une nuée divisée ---------------

func test_r05_abstains_without_anyone_to_follow() -> void:
	var s := _state(["......", "......", "......"], [Vector2i(0, 1)])
	assert_eq(_eval(RuleRegistry.R05_FOLLOW_NEIGHBOURS, s, 0), Rule.ABSTAIN,
		"aucun voisin perçu : R05 doit se taire")

func test_r05_adopts_the_majority_direction_of_a_divided_swarm() -> void:
	# LE CAS D'ÉPREUVE. Trois voisins vont à l'Est, deux à l'Ouest : la
	# majorité est l'Est. Sur un courant unanime, ce test ne prouverait rien.
	var s := _state(["........", "........", "........"],
		[Vector2i(4, 1),
		 Vector2i(3, 1), Vector2i(5, 1), Vector2i(4, 0),
		 Vector2i(4, 2), Vector2i(3, 0)],
		[Directions.NORTH,
		 Directions.EAST, Directions.EAST, Directions.EAST,
		 Directions.WEST, Directions.WEST])
	assert_eq(_eval(RuleRegistry.R05_FOLLOW_NEIGHBOURS, s, 0),
		Directions.offset(Directions.EAST),
		"trois voix à l'Est contre deux à l'Ouest : R05 doit suivre l'Est")

func test_r05_breaks_a_tie_with_the_canonical_order() -> void:
	# Une voix chacun : l'ordre N>E>S>O tranche, comme partout ailleurs dans
	# la simulation. Sans ce départage, la règle dépendrait de l'ordre de
	# parcours des agents — donc d'un détail d'implémentation.
	var s := _state(["........", "........", "........"],
		[Vector2i(4, 1), Vector2i(3, 1), Vector2i(5, 1)],
		[Directions.NORTH, Directions.SOUTH, Directions.EAST])
	assert_eq(_eval(RuleRegistry.R05_FOLLOW_NEIGHBOURS, s, 0),
		Directions.offset(Directions.EAST),
		"égalité Sud/Est : l'Est l'emporte par l'ordre N>E>S>O")

func test_r05_abstains_when_the_majority_direction_is_walled() -> void:
	# Elle ne force pas un pas impossible : la cascade continue.
	var s := _state(["####", "#..#", "####"],
		[Vector2i(1, 1), Vector2i(2, 1)], [Directions.NORTH, Directions.NORTH])
	assert_eq(_eval(RuleRegistry.R05_FOLLOW_NEIGHBOURS, s, 0), Rule.ABSTAIN,
		"la direction majoritaire est murée : R05 doit rendre la main")

func test_r05_ignores_a_neighbour_whose_direction_could_not_have_brought_it_there() -> void:
	# Un agent dont la `dir` le ferait venir d'un MUR ne s'est pas déplacé
	# ainsi : il porte une direction ancienne. Le faire voter donnerait une
	# voix à un souvenir plutôt qu'à un mouvement.
	#
	# La première rédaction plaçait le voisin en (1,1) avec `dir` Ouest et
	# attendait qu'il ne vote pas — incohérent : venant de (2,1), case libre,
	# il a parfaitement pu faire ce pas. C'est le cap EST qui est impossible
	# ici, puisqu'il le ferait venir de (0,1), un mur.
	var s := _state(["#####", "#...#", "#####"],
		[Vector2i(2, 1), Vector2i(1, 1)], [Directions.NORTH, Directions.EAST])
	assert_eq(_eval(RuleRegistry.R05_FOLLOW_NEIGHBOURS, s, 0), Rule.ABSTAIN,
		"le seul voisin n'a pas pu avancer ainsi : sa direction ne vote pas")

func test_r05_says_nothing_on_the_first_tick() -> void:
	# Au tick 0, personne n'a bougé et tous portent la `dir` initiale posée
	# par `SimCore.load_level`. Les faire voter produirait une unanimité qui
	# ne décrit aucun mouvement, et R05 imposerait le Nord à toute la nuée sur
	# la foi d'une valeur par défaut.
	var s := _state(["........", "........", "........"],
		[Vector2i(4, 1), Vector2i(3, 1), Vector2i(5, 1)],
		[Directions.NORTH, Directions.EAST, Directions.EAST])
	s.tick = 0
	assert_eq(_eval(RuleRegistry.R05_FOLLOW_NEIGHBOURS, s, 0), Rule.ABSTAIN,
		"au premier tick, aucun mouvement n'a eu lieu : R05 doit se taire")

# --- R06 : LONGER LE MUR, éprouvée sur un contour concave ------------------

func test_r06_abstains_in_open_ground() -> void:
	# Son terminal, et ce qui l'empêche de masquer la suite de la pile pour
	# toujours : sans mur adjacent, il n'y a rien à longer.
	var s := _state([".....", ".....", "....."], [Vector2i(2, 1)])
	assert_eq(_eval(RuleRegistry.R06_HUG_WALL, s, 0), Rule.ABSTAIN,
		"aucun obstacle adjacent : R06 n'a pas d'objet")

func test_r06_prefers_its_right_hand() -> void:
	# Cap au Nord, mur au Nord, ouvert à l'Est : la main droite d'abord.
	var s := _state(["###", "#..", "..."], [Vector2i(1, 1)], [Directions.NORTH])
	assert_eq(_eval(RuleRegistry.R06_HUG_WALL, s, 0),
		Directions.offset(Directions.EAST),
		"cap au Nord et Nord muré : R06 prend sa droite, l'Est")

func test_r06_turns_around_in_a_dead_end() -> void:
	# LE CAS D'ÉPREUVE, et la raison d'être de la règle. Cul-de-sac fermé au
	# Nord, à l'Est et à l'Ouest, cap au Nord : droite, tout droit et gauche
	# sont murés, le demi-tour reste.
	#
	# C'est le dispositif que le chapitre 1 n'avait pas. R01 ne sort pas d'une
	# impasse (le retour éloigne de la lumière), R02 non plus (la seule case
	# libre pointe vers le danger). R06 en sort sans dépendre d'un seuil ni
	# des congénères.
	var s := _state(["###", "#.#", "#.#", "..."],
		[Vector2i(1, 1)], [Directions.NORTH])
	assert_eq(_eval(RuleRegistry.R06_HUG_WALL, s, 0),
		Directions.offset(Directions.SOUTH),
		"cul-de-sac cap au Nord : R06 doit faire demi-tour")

func test_r06_follows_a_concave_corner_without_cutting_it() -> void:
	# Chicane : cap à l'Est le long d'un mur au Sud, le mur tourne. La droite
	# (Sud) est murée, tout droit (Est) est libre : l'agent continue de longer
	# au lieu de couper.
	var s := _state(["....", "....", "####"], [Vector2i(1, 1)], [Directions.EAST])
	assert_eq(_eval(RuleRegistry.R06_HUG_WALL, s, 0),
		Directions.offset(Directions.EAST),
		"droite murée, tout droit libre : R06 longe sans couper")

func test_r06_gives_two_opposite_headings_two_different_walls() -> void:
	# La propriété qui exige `dir` et qu'aucune fonction de la seule position
	# ne peut produire : au même endroit, deux caps opposés ne longent pas le
	# même mur. Si ce test passait sans lire `dir`, la règle serait fausse.
	var rows := ["...", ".#.", "..."]
	var north := _state(rows, [Vector2i(1, 2)], [Directions.NORTH])
	var south := _state(rows, [Vector2i(1, 2)], [Directions.SOUTH])
	assert_ne(_eval(RuleRegistry.R06_HUG_WALL, north, 0),
		_eval(RuleRegistry.R06_HUG_WALL, south, 0),
		"deux caps opposés au même endroit doivent produire deux pas différents")

# --- propriétés communes ---------------------------------------------------

func test_the_three_rules_are_registered_and_stateless() -> void:
	for id in [RuleRegistry.R04_SPREAD_OUT, RuleRegistry.R05_FOLLOW_NEIGHBOURS,
			RuleRegistry.R06_HUG_WALL]:
		var rule := RuleRegistry.get_rule(id)
		assert_not_null(rule, "R%02d doit être enregistrée" % id)
		# Le registre met en cache une instance unique : c'est licite parce
		# que les règles sont sans état. Si l'une venait à en porter, cette
		# égalité serait le premier endroit où le dire.
		assert_eq(rule, RuleRegistry.get_rule(id), "R%02d doit être sans état" % id)

func test_every_rule_returns_a_unit_step_or_abstains() -> void:
	# Une règle ne peut produire qu'un des quatre vecteurs cardinaux ou
	# ABSTAIN. Un pas diagonal ou double casserait la résolution de conflits
	# sans qu'aucun test de niveau ne le dise.
	var legal := [Directions.offset(Directions.NORTH), Directions.offset(Directions.EAST),
		Directions.offset(Directions.SOUTH), Directions.offset(Directions.WEST), Rule.ABSTAIN]
	var s := _state(["#####", "#...#", "#...#", "#####"],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 2)],
		[Directions.NORTH, Directions.EAST, Directions.SOUTH, Directions.WEST])
	for id in [RuleRegistry.R04_SPREAD_OUT, RuleRegistry.R05_FOLLOW_NEIGHBOURS,
			RuleRegistry.R06_HUG_WALL]:
		for i in range(s.agents.size()):
			assert_true(legal.has(_eval(id, s, i)),
				"R%02d, agent %d : sortie hors du jeu légal" % [id, i])
