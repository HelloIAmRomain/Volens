class_name RuleCarry
extends Rule
## R11 — Porter [CDC §7.2] : l'agent ramasse la ressource présente sur sa case
## s'il n'en porte pas déjà.
##
## GENRE `EFFET`. Ramasser n'est pas se déplacer — même raisonnement que R08.
##
## LA RESSOURCE DISPARAÎT DE LA GRILLE, définitivement. Elle n'est ni copiée ni
## partagée : un agent la prend, la case redevient vide. C'est ce qui rend le
## chapitre 4 arithmétique — il y a exactement autant de ressources que le
## niveau en pose, et perdre un porteur, c'est perdre une ressource.
##
## UN PORTEUR NE SORT PAS DU NIVEAU. La règle est appliquée par
## `SimCore._apply_environment_effects`, pas ici, mais elle appartient à ce
## mécanisme et mérite d'être dite au même endroit : sortir avec la ressource
## sur le dos reviendrait à la perdre tout en comptant un succès. Le joueur ne
## verrait qu'un compteur de livraisons qui n'avance pas, sans cause visible.
##
## POURQUOI LA POSITION COMPTE. R11 au rang 1 : tout agent qui passe sur une
## ressource la prend, toujours. R11 après une règle de mouvement qui décide
## partout — R01 par exemple — n'est jamais atteinte, et la nuée traverse les
## ressources sans les voir. **C'est le piège pédagogique du chapitre 4**, et
## il est honnête : la cascade fait exactement ce qu'elle a toujours fait.
##
## LE CAS D'ÉPREUVE (invariant n°12) est le RAMASSAGE EN CONCURRENCE — deux
## agents sur la même ressource au même tick. L'ordre des id tranche, comme
## pour les conflits de case, et le second ne trouve plus rien : le
## déterminisme du chapitre 4 se juge là, pas sur un agent seul face à une pile
## de ressources.

func kind() -> int:
	return Kind.EFFECT

func apply_effect(agent_index: int, state: SimState, next_state: SimState,
		_params: RuleParams) -> bool:
	var agent := state.agents[agent_index]
	if not agent.is_present():
		return false
	var carrier := next_state.agents[agent_index]
	if (carrier.flags & AgentState.PORTEUR) != 0:
		return false  # déjà chargé : une ressource à la fois
	var idx: int = state.grid.index_of(agent.pos)
	# On lit `next_state` pour la case : un agent d'id plus petit a pu prendre
	# la ressource au même tick, et il n'en reste alors plus rien. C'est
	# l'unique endroit du moteur où un effet voit celui d'un autre agent, et
	# c'est nécessaire — sans quoi deux agents ramasseraient la même ressource.
	if next_state.grid.cells[idx] != GridState.CellType.RESOURCE:
		return false
	next_state.grid.cells[idx] = GridState.CellType.EMPTY
	carrier.flags |= AgentState.PORTEUR
	return true
