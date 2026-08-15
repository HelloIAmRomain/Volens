class_name RuleHugWall
extends Rule
## R06 — Longer le mur [CDC §7.2] : l'agent suit l'obstacle qu'il a à main
## droite.
##
## ELLE SE SERT DE `AgentState.dir` COMME CAP. Sans orientation, « droite »
## n'existe pas : deux agents au même endroit longeant le même mur en sens
## contraire doivent voir des murs différents, ce qu'aucune fonction de la
## seule position ne peut produire. Le champ est spécifié au DCT §4.1, peuplé
## et déjà haché — R06 ne l'introduit pas, elle l'utilise.
##
## LA MAIN EST LA DROITE, ET C'EST UNE CONVENTION FIGÉE, du même ordre que
## l'ordre de départage N>E>S>O : elle n'est pas « le bon choix », elle est
## LE choix, et elle ne se renégocie pas niveau par niveau. Avec Y croissant
## vers le bas, la droite d'un cap est `(dir + 1) % 4` — au Nord (0,-1)
## correspond l'Est (1,0).
##
## L'ALGORITHME, dans l'ordre : droite, tout droit, gauche, demi-tour. C'est
## le suivi de paroi classique, et le premier essai franchissable l'emporte.
## Tester la droite EN PREMIER est ce qui fait « longer » : l'agent recolle
## au mur dès qu'il le peut, au lieu de s'en écarter en ligne droite.
##
## ELLE A UN TERMINAL, donc elle ne gèle pas la pile (pathologie P1) :
## **s'il n'y a aucun obstacle adjacent, il n'y a rien à longer et R06
## s'abstient.** Sans cette condition, R06 proposerait un déplacement partout,
## en tout temps, et masquerait définitivement la suite de la pile — c'est
## exactement la faute de R03 v1, et elle est ici évitée par construction.
##
## ELLE PEUT OUVRIR UNE IMPASSE, et c'est sa raison d'être. Le résultat
## établi en construisant N3 — seule une règle dont la cible est derrière
## l'agent en sort — s'applique : dans un cul-de-sac, droite, tout droit et
## gauche sont murés, R06 propose le demi-tour, et l'agent ressort. R01 ne
## le pouvait pas (le retour éloigne de la lumière), R02 non plus (la seule
## case libre pointe vers le danger). R06 est le premier dispositif de sortie
## qui ne dépende ni d'un seuil, ni des congénères.
##
## LE CAS D'ÉPREUVE (invariant n°12) est le contour CONCAVE — recoins,
## chicanes, culs-de-sac. Sur un couloir droit, R06 avance tout droit comme
## n'importe quelle autre règle et ne prouve rien.

func evaluate(agent: AgentState, state: SimState, _params: RuleParams) -> Vector2i:
	if not _touches_obstacle(agent.pos, state):
		return ABSTAIN  # rien à longer : la règle suivante décide

	# Droite, tout droit, gauche, demi-tour — premier franchissable.
	for turn in [1, 0, 3, 2]:
		var dir: int = (agent.dir + turn) % 4
		var offset: Vector2i = Directions.offset(dir)
		if state.grid.can_traverse(agent.pos, agent.pos + offset):
			return offset
	return ABSTAIN  # emmuré des quatre côtés : aucune règle ne peut l'aider

## Un obstacle adjacent orthogonalement — mur ou bordure de grille. C'est le
## terminal de la règle : sans mur à longer, R06 n'a pas d'objet.
static func _touches_obstacle(pos: Vector2i, state: SimState) -> bool:
	for dir in Directions.ORDER:
		if not state.grid.can_traverse(pos, pos + Directions.offset(dir)):
			return true
	return false
