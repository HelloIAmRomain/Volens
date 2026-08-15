class_name RuleDropAtGoal
extends Rule
## R12 — Déposer au but [CDC §7.2] : l'agent porteur dépose sa ressource sur
## une case de dépôt adjacente.
##
## GENRE `EFFET`, comme R11.
##
## ADJACENTE, PAS SOUS LES PIEDS, et cette nuance porte tout le chapitre 4. Si
## le dépôt se faisait en marchant DESSUS, une case de dépôt serait une simple
## sortie de plus, et R12 ne servirait à rien : R01 y mènerait seule. En
## exigeant l'adjacence, la case de dépôt devient un point que la nuée doit
## FRÔLER sans y entrer — et il faut donc une règle pour reconnaître ce moment.
##
## L'ordre N>E>S>O départage les dépôts adjacents. Un seul dépôt par tick et
## par agent : `counters.delivered` avance d'exactement un.
##
## LE PORTEUR REDEVIENT LIBRE et peut repartir chercher. Rien ne le lui dit —
## aucune règle ne connaît « il reste des ressources » — et c'est délibéré :
## le joueur doit composer une pile qui fasse le va-et-vient sans le savoir.
## Une piste (R08/R09) est le moyen le plus naturel, et c'est ainsi que le
## chapitre 4 rappelle le chapitre 3.
##
## LE CAS D'ÉPREUVE (invariant n°12) est le DÉPÔT ENCOMBRÉ : plusieurs porteurs
## autour du même dépôt au même tick. Chacun dépose — le dépôt n'a pas de
## capacité — et c'est ce qu'il faut vérifier, plutôt qu'un porteur seul devant
## un dépôt libre, où n'importe quelle implémentation paraîtrait correcte.

func kind() -> int:
	return Kind.EFFECT

func apply_effect(agent_index: int, state: SimState, next_state: SimState,
		_params: RuleParams, _moved: bool) -> bool:
	var agent := state.agents[agent_index]
	if not agent.is_present():
		return false
	var carrier := next_state.agents[agent_index]
	if (carrier.flags & AgentState.PORTEUR) == 0:
		return false  # rien à déposer
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if not state.grid.is_in_bounds(candidate):
			continue
		if state.grid.cell_type_at(candidate) != GridState.CellType.DROPOFF:
			continue
		carrier.flags &= ~AgentState.PORTEUR
		next_state.counters.delivered += 1
		return true
	return false
