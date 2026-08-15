class_name RuleSpreadOut
extends Rule
## R04 — S'écarter [CDC §7.2] : l'agent s'éloigne si sa case compte trop de
## voisins à portée rapprochée ⚙️ (`RuleParams.crowd_max_neighbours`).
##
## GENRE : proposeur ordinaire, comme R02 et R03. Aucun état, aucune lecture
## de `dir`, aucun ajout au modèle — R04 aurait pu être écrite au chapitre 1.
## C'est la seule des trois règles du chapitre 2 dans ce cas.
##
## SYMÉTRIQUE DE R03, ET DÉLIBÉRÉMENT. R03 se rapproche du barycentre perçu
## quand l'agent est isolé ; R04 s'en éloigne quand il est comprimé. Même
## arithmétique entière — sommes mises à l'échelle par `count`, jamais de
## division (invariant n°5) — même ordre de départage N>E>S>O, seul le sens
## de la comparaison change.
##
## ABSTENTION NATURELLE, et c'est ce qui la rend utilisable : sous le seuil,
## R04 se tait et laisse la main. Elle ne peut donc pas geler la pile comme
## R03 v1 le faisait (pathologie P1) : son terminal est la dispersion, qui
## est atteignable, là où « converger vers le barycentre » ne l'était pas.
##
## CE QU'ELLE NE PEUT PAS FAIRE — à retenir avant de dessiner un niveau. R04
## ne peut PAS ouvrir une impasse. Son seuil est LOCAL, exactement comme la
## portée de R02 : ou bien il se déclenche avant l'entrée dans le cul-de-sac
## et l'agent oscille de part et d'autre du seuil de densité (pathologie P3),
## ou bien la direction qui desserre est justement celle qui est murée. Le
## résultat établi en construisant N3 vaut ici sans changement : seule une
## règle dont la condition dépend des congénères EN TANT QUE GROUPE, et dont
## la cible est derrière l'agent, ouvre une impasse. R05 et R06 le peuvent ;
## R04 non.
##
## LE CAS D'ÉPREUVE (invariant n°12) est le GOULOT, jamais la nuée dispersée
## — où R04 n'a rien à écarter et paraîtra toujours correcte.

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	var sum_x := 0
	var sum_y := 0
	var count := 0
	var close_count := 0
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - agent.pos.x
		var dy: int = other.pos.y - agent.pos.y
		var dist_sq: int = dx * dx + dy * dy
		if dist_sq > params.crowd_range_sq:
			continue
		close_count += 1
		sum_x += other.pos.x
		sum_y += other.pos.y
		count += 1

	if close_count < params.crowd_max_neighbours:
		return ABSTAIN  # sous le seuil : rien à desserrer, la suite décide
	if count == 0:
		return ABSTAIN  # inatteignable tant que le seuil est >= 1, gardé par sûreté

	# S'ÉLOIGNER, c'est augmenter la distance au barycentre des voisins serrés.
	# Même produit croisé entier que R03, comparaison inversée.
	#
	# ELLE PREND LE PLUS GRAND ÉCART, PAS LE PREMIER QUI ÉCARTE — et c'est une
	# correction du 14 août 2026, imposée par la mesure. La première rédaction
	# renvoyait le premier pas de l'ordre N>E>S>O qui augmentait la distance.
	# Or, pour une nuée qui monte, le Nord l'augmente presque toujours : R04 se
	# comportait donc comme une R01 affaiblie, et poussait vers l'avant au lieu
	# d'écarter. Mesuré sur un piège place au Nord : elle y jetait la nuée qu'elle
	# était censée en détourner.
	#
	# En retenant le MAXIMUM, le pas latéral l'emporte partout où il écarte
	# davantage — ce qui est le cas dès que la nuée est devant ou derrière, la
	# seule situation où « s'écarter » veut dire quelque chose. L'ordre N>E>S>O
	# ne départage plus que les ex æquo, ce qui est son rôle.
	var current_dist: int = _scaled_distance(agent.pos, sum_x, sum_y, count)
	var best_dir: int = -1
	var best_dist: int = current_dist
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if not state.grid.can_traverse(agent.pos, candidate):
			continue
		var d: int = _scaled_distance(candidate, sum_x, sum_y, count)
		if d > best_dist:
			best_dist = d
			best_dir = dir
	if best_dir < 0:
		return ABSTAIN  # aucune issue ne desserre : la règle suivante décide
	return Directions.offset(best_dir)

static func _scaled_distance(p: Vector2i, sum_x: int, sum_y: int, count: int) -> int:
	return absi(p.x * count - sum_x) + absi(p.y * count - sum_y)
