class_name RuleFollowNeighbours
extends Rule
## R05 — Suivre les voisins [CDC §7.2] : l'agent adopte la direction
## majoritaire de ses voisins perçus ⚙️ (`RuleParams.follow_perception_range_sq`).
##
## ELLE LIT `AgentState.dir`, ET C'EST TOUT CE QU'ELLE AJOUTE. Le champ est
## spécifié au DCT §4.1 depuis le premier jour, peuplé par
## `SimCore._apply_movements` à chaque déplacement effectif, et déjà parcouru
## par `StateHash`. R05 ne l'introduit pas : elle l'utilise enfin. Aucune
## empreinte ne bouge de son fait, et rien n'est ajouté au modèle d'état.
##
## CE N'EST PAS L'HYSTÉRÉSIS GELÉE du dossier des genres de règles. Une
## hystérésis est un état de DÉCISION — quelle règle a parlé, depuis combien
## de ticks — qui modifierait la cascade elle-même. `dir` est un FAIT
## OBSERVABLE du tick précédent, au même titre qu'une position. R05 reste un
## proposeur : elle gagne de quoi lire, pas un nouveau mode d'expression.
##
## DÉTERMINISME DU DÉPOUILLEMENT. Les voix sont comptées dans un tableau de
## quatre entiers indexé par `Directions`, jamais dans un `Dictionary` : la
## contrainte de l'invariant n°8 porte sur l'itération, et un tableau indexé
## par une constante entière n'a pas d'ordre à trahir. Le parcours des
## congénères suit `state.agents`, donc l'ordre des `id` croissants. À
## égalité de voix, l'ordre N>E>S>O tranche, comme partout ailleurs.
##
## ON NE COMPTE QUE LES AGENTS QUI ONT BOUGÉ. Un agent immobile conserve la
## `dir` de son dernier déplacement effectif — une direction qu'il n'a pas
## choisie ce tick-ci. Le faire voter reviendrait à donner une voix à un
## souvenir. `SimState` ne porte pas de drapeau « a bougé au tick précédent »,
## et lui en ajouter un modifierait l'empreinte ; on retient donc le critère
## disponible et honnête : **un voisin ne vote que s'il n'est pas sur la case
## d'où sa `dir` l'aurait fait venir**, c'est-à-dire s'il a effectivement pu
## avancer. Voir `_has_moved`.
##
## ABSTENTION NATURELLE : aucun voisin perçu, aucune voix, ou direction
## majoritaire murée. R05 se tait alors et la cascade continue.
##
## LE CAS D'ÉPREUVE (invariant n°12) est la nuée DIVISÉE — deux courants
## contraires, ou un éclaireur à contre-sens. Sur une nuée qui va déjà toute
## dans le même sens, R05 paraîtra toujours correcte et n'aura rien départagé.

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	# AU PREMIER TICK, PERSONNE N'A BOUGÉ. Tous les agents portent la `dir`
	# initiale (Nord) posée par `SimCore.load_level` : les faire voter
	# produirait une unanimité qui ne décrit aucun mouvement, et R05 imposerait
	# le Nord à toute la nuée sur la foi d'une valeur par défaut. Défaut trouvé
	# en écrivant le test du voisin immobile, pas en relisant la règle.
	if state.tick == 0:
		return ABSTAIN

	# Tableau de voix indexé par Directions.NORTH..WEST — pas de Dictionary.
	var votes: Array[int] = [0, 0, 0, 0]
	var voters := 0
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - agent.pos.x
		var dy: int = other.pos.y - agent.pos.y
		if dx * dx + dy * dy > params.follow_perception_range_sq:
			continue
		if not _has_moved(other, state):
			continue
		votes[other.dir] += 1
		voters += 1

	if voters == 0:
		return ABSTAIN  # personne à suivre

	# Majorité, départagée par N>E>S>O : on parcourt dans l'ordre canonique et
	# on ne remplace qu'en cas de STRICTE supériorité, ce qui donne la
	# priorité à la direction la plus haute dans l'ordre à égalité de voix.
	var best_dir: int = Directions.NORTH
	var best_votes: int = -1
	for dir in Directions.ORDER:
		if votes[dir] > best_votes:
			best_votes = votes[dir]
			best_dir = dir

	var offset: Vector2i = Directions.offset(best_dir)
	if not state.grid.can_traverse(agent.pos, agent.pos + offset):
		return ABSTAIN  # la direction majoritaire est murée : la suite décide
	return offset

## Vrai si l'agent a effectivement avancé au tick précédent : la case d'où sa
## `dir` l'aurait fait venir est franchissable et distincte de la sienne. Un
## agent qui n'a pas bougé porte encore une `dir` ancienne — la faire voter
## donnerait une voix à un souvenir plutôt qu'à un mouvement.
##
## Le critère est une approximation assumée, et sa limite est nommée : un
## agent bloqué CONTRE un mur exactement dans le dos de sa dernière direction
## est traité comme immobile, alors qu'il a pu bouger au tick d'avant. Le
## critère exact demanderait un drapeau par agent, donc un champ de plus dans
## l'empreinte. Ce n'est pas un oubli : c'est le compromis choisi, et il est
## conservateur — il retire des voix, il n'en invente aucune.
static func _has_moved(other: AgentState, state: SimState) -> bool:
	var came_from: Vector2i = other.pos - Directions.offset(other.dir)
	return state.grid.is_walkable(came_from) and state.grid.can_traverse(came_from, other.pos)
