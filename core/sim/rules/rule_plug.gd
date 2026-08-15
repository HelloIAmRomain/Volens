class_name RulePlug
extends Rule
## R13 — Boucher [CDC §7.2] : l'agent occupe une case de danger et s'y consume,
## la neutralisant définitivement.
##
## **LA SEULE RÈGLE DU JEU QUI DEMANDE DE PERDRE QUELQUE CHOSE**, et le
## chapitre 5 est construit autour d'elle. Toutes les autres cherchent à
## préserver, contourner, regrouper. Celle-ci dit : envoie un agent mourir là,
## et le chemin est ouvert pour tous les autres.
##
## PROPOSEUR, PAS EFFET — et la distinction est instructive. Boucher EST un
## déplacement : l'agent va sur le danger. La neutralisation n'est pas un effet
## de règle mais une conséquence de l'arrivée, appliquée par
## `SimCore._apply_environment_effects`, qui vérifie que **c'est bien R13 qui a
## décidé** ce pas. Un agent poussé sur un danger par R05 ou par un conflit de
## case meurt sans rien neutraliser : **c'est ce qui distingue un sacrifice
## d'un accident**, et le joueur le vérifie en déplaçant R13 sous une règle qui
## décide partout — la nuée meurt alors sans jamais ouvrir le passage.
##
## ELLE NE VISE QUE LES DANGERS ACTIFS À L'ARRIVÉE. Se jeter sur un danger
## cyclique éteint ne neutralise rien et ne tue personne : l'agent traverse.
## R13 consulte donc le tick d'ARRIVÉE (`tick + 1`), comme R02 — les deux
## règles doivent s'accorder sur ce qu'est « un danger », sans quoi l'une
## fuirait ce que l'autre ignore.
##
## ORDRE N>E>S>O parmi les dangers adjacents. Aucun danger adjacent : abstention.
##
## LE CAS D'ÉPREUVE (invariant n°12) est le GOULOT BOUCHÉ PAR UN SEUL DANGER,
## là où le sacrifice d'un agent ouvre la route à vingt. Sur une carte où le
## danger est contournable, R13 ne fait que gâcher un agent, et le joueur qui
## la pose là apprend précisément cela.

func evaluate(agent: AgentState, state: SimState, _params: RuleParams) -> Vector2i:
	var arrival_tick: int = state.tick + 1
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if not state.grid.can_traverse(agent.pos, candidate):
			continue
		if state.grid.is_danger_active_at(candidate, arrival_tick):
			return Directions.offset(dir)
	return ABSTAIN  # rien à boucher ici : la règle suivante décide
