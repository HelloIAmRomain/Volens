class_name RuleFollowTrail
extends Rule
## R09 — Suivre la piste [CDC §7.2] : l'agent se dirige vers le marqueur voisin
## le plus intense.
##
## ELLE NE VA PAS VERS UN BUT, ELLE VA VERS UNE TRACE — et c'est toute la
## différence avec R01. R01 connaît la lumière, qui ne bouge pas ; R09 ne
## connaît que ce que la nuée a laissé derrière elle. Une piste peut mener
## nulle part, tourner en rond, ou s'être effacée. **C'est le premier moment du
## jeu où la nuée agit sur une information qu'elle a elle-même produite**, et
## c'est ce que le CDC appelle le tournant du jeu.
##
## ABSTENTION NATURELLE, à deux titres : aucune case voisine ne porte de
## marqueur, ou aucune n'en porte PLUS que celle où l'agent se trouve déjà.
## Cette seconde condition est ce qui empêche R09 de faire du sur-place au
## sommet d'une piste : sans elle, un agent sur le maximum local proposerait un
## pas vers une case moins intense, y irait, reviendrait — l'oscillation P3,
## exactement.
##
## COMPARAISON STRICTE, ORDRE N>E>S>O À ÉGALITÉ. Deux voisins de même intensité
## ne se départagent pas par leur valeur : c'est l'ordre canonique qui tranche,
## comme partout ailleurs dans la simulation.
##
## LE CAS D'ÉPREUVE (invariant n°12) est la piste **en Y** — deux branches
## d'intensités différentes menant à des endroits différents. Sur une piste
## unique, R09 ne fait que suivre un couloir et ne prouve rien : n'importe
## quelle règle de mouvement aurait produit la même trajectoire.

func evaluate(agent: AgentState, state: SimState, _params: RuleParams) -> Vector2i:
	var here: int = state.grid.pheromone[state.grid.index_of(agent.pos)]
	var best_dir: int = -1
	var best_intensity: int = here   # il faut faire STRICTEMENT mieux que sa propre case
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if not state.grid.can_traverse(agent.pos, candidate):
			continue
		var intensity: int = state.grid.pheromone[state.grid.index_of(candidate)]
		if intensity > best_intensity:
			best_intensity = intensity
			best_dir = dir
	if best_dir < 0:
		return ABSTAIN  # aucune trace meilleure que la sienne : la suite décide
	return Directions.offset(best_dir)
