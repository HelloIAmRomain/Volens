class_name RuleTurnBackIfAlone
extends Rule
## R10 — Rebrousser si seul [CDC §7.2] : l'agent fait demi-tour s'il ne perçoit
## aucun congénère.
##
## ELLE EST LE CONTRAIRE EXACT DE R03, ET C'EST VOULU. R03 « rester groupé »
## ramène l'isolé VERS le barycentre : encore faut-il qu'il perçoive quelqu'un.
## R10 traite le cas où il ne perçoit plus personne — le seul cas que R03 ne
## sait pas traiter, puisqu'elle s'y abstient faute de barycentre.
##
## Ensemble, elles couvrent tout l'espace : R03 pour l'agent qui voit encore la
## nuée, R10 pour celui qui l'a perdue. Séparément, chacune laisse un trou. Le
## joueur qui ne pose que R03 découvre que ses éclaireurs disparaissent au
## loin ; celui qui ne pose que R10 découvre que sa nuée se délite lentement
## sans jamais se perdre tout à fait.
##
## « REBROUSSER » S'APPUIE SUR `dir`, comme R06 : c'est la direction opposée à
## la dernière empruntée. Sans cap, « faire demi-tour » n'a pas de sens.
##
## SI LE DEMI-TOUR EST MURÉ, ELLE S'ABSTIENT plutôt que de choisir une autre
## direction. Un demi-tour est un demi-tour ; en faire « un pas quelconque vers
## l'arrière » en ferait une seconde règle de fuite, et le joueur ne pourrait
## plus prédire ce qu'elle fait.
##
## LE CAS D'ÉPREUVE (invariant n°12) est l'ÉCLAIREUR QUI S'ÉLOIGNE — un agent
## que la géométrie sépare durablement du gros de la nuée. Sur une nuée
## compacte, R10 ne se déclenche jamais et paraîtra toujours correcte.

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - agent.pos.x
		var dy: int = other.pos.y - agent.pos.y
		if dx * dx + dy * dy <= params.alone_perception_range_sq:
			return ABSTAIN  # il reste quelqu'un : rien à rebrousser
	var back: Vector2i = -Directions.offset(agent.dir)
	if not state.grid.can_traverse(agent.pos, agent.pos + back):
		return ABSTAIN  # demi-tour impossible : la règle suivante décide
	return back
