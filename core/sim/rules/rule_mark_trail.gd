class_name RuleMarkTrail
extends Rule
## R08 — Marquer la piste [CDC §7.2] : l'agent dépose sur sa case un marqueur
## qui s'estompe après un délai fixe ⚙️ (`RuleParams.trail_deposit`,
## `RuleParams.trail_evaporation`).
##
## **PREMIÈRE RÈGLE DU GENRE `EFFET`, et la raison pour laquelle ce genre
## existe.** Déposer un marqueur n'est pas proposer un déplacement. Sous le
## genre proposeur — le seul qui existait jusqu'au 14 août 2026 — R08 n'avait
## que deux formes possibles, mauvaises toutes les deux :
##
##   · s'abstenir toujours, et alors elle ne fait rien et n'est pas dans la
##     pile ;
##   · proposer l'immobilité, et alors elle masque TOUTE la suite de la pile
##     et fige la nuée sur place.
##
## C'est la pathologie P1 du dossier des genres, et R08 en était le cas le plus
## net. Elle agit, puis rend la main : la cascade continue, une autre règle
## décide du déplacement.
##
## LA POSITION DANS LA PILE CHANGE TOUT, et c'est ce qui fait d'un effet une
## vraie décision de jeu plutôt qu'un automatisme :
##
##   · **au rang 1** — « laisse toujours une trace ». Toute la nuée marque à
##     chaque tick ; les pistes deviennent une carte de fréquentation, et les
##     couloirs très empruntés brillent plus que les impasses ;
##   · **au dernier rang** — « ne marque que si tu ne savais pas quoi faire ».
##     Seuls les agents qu'aucune règle n'a su guider déposent, et la piste
##     signale alors les endroits où la nuée hésite, pas ceux où elle passe.
##
## Deux jeux différents avec la même tuile. Le joueur le découvre en la
## déplaçant d'un rang, ce que le jeu prétend enseigner depuis le premier
## niveau.
##
## SATURATION PLUTÔT QU'ACCUMULATION LIBRE. L'intensité est plafonnée à
## `trail_max`. Sans plafond, un agent immobile produirait une intensité qui
## croît sans limite, R09 la suivrait éternellement, et la piste cesserait
## d'être une mémoire pour devenir un puits. Le plafond est aussi ce qui garde
## l'entier borné — invariant n°5, aucune valeur qui dérive.

func kind() -> int:
	return Kind.EFFECT

func apply_effect(agent_index: int, state: SimState, next_state: SimState,
		params: RuleParams, moved: bool) -> bool:
	var agent := state.agents[agent_index]
	if not agent.is_present():
		return false
	# UNE PISTE EST UNE TRACE DE PASSAGE, PAS D'OCCUPATION — et sans cette
	# condition le mécanisme s'auto-détruit. Mesuré en construisant N10 : un
	# agent immobile, atteint par la cascade à chaque tick, renforçait sa propre
	# case jusqu'à saturation pendant que la trace devant lui s'évaporait. Il
	# creusait un puits sous ses pieds, et R09 — qui ne va que vers PLUS intense
	# que sa case — ne pouvait plus jamais l'en faire sortir. La nuée se figeait
	# exactement là où elle avait le plus besoin d'avancer.
	if not moved:
		return false
	# La case marquée est celle du CLICHÉ, pas celle d'arrivée : c'est là que
	# l'agent était quand il a décidé. Une piste décalée d'une case est une
	# piste fausse (voir SimCore, étape 4).
	var idx: int = state.grid.index_of(agent.pos)
	var current: int = next_state.grid.pheromone[idx]
	if current >= params.trail_max:
		return false
	next_state.grid.pheromone[idx] = mini(params.trail_max, current + params.trail_deposit)
	return true
