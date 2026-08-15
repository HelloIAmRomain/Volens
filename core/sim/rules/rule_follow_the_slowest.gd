class_name RuleFollowTheSlowest
extends Rule
## R15 — Suivre le plus lent [CDC §7.2] : l'agent règle son avance sur le
## congénère le plus en retard qu'il perçoit.
##
## « RÉGLER SON AVANCE » VEUT DIRE ATTENDRE, et il faut le dire clairement,
## parce que c'est la seule lecture qui tienne dans un jeu sans vitesse. Un
## agent avance d'une case ou de zéro : il n'y a pas de demi-pas. La seule
## manière de se caler sur plus lent que soi est donc de **ne pas bouger** tant
## que l'écart dépasse un seuil ⚙️.
##
## R15 est ainsi une **régulation**, pas une locomotion : elle ne conduit
## jamais nulle part. Posée seule, la nuée se fige. Posée avant R01, elle donne
## une nuée qui progresse au rythme de son dernier — lente, groupée, et qui
## n'abandonne personne.
##
## « LE PLUS EN RETARD » SE MESURE PAR RAPPORT AU BUT, pas par rapport à
## l'agent. On compare les distances de Manhattan à la lumière : le traînard
## est celui qui en est le plus loin. Sans référence commune, « en retard »
## n'aurait pas de sens — deux agents éloignés l'un de l'autre seraient chacun
## le retardataire de l'autre, et la nuée entière s'immobiliserait.
##
## AUCUNE LUMIÈRE : ABSTENTION. La règle n'a alors pas de référentiel, et
## inventer un substitut (le barycentre, l'agent d'id 0) donnerait un
## comportement que le joueur ne pourrait pas prédire.
##
## ELLE COMPTE LES SORTIS COMME PARTIS, PAS COMME EN RETARD. Un agent sorti
## n'est plus présent, donc invisible à cette règle : sans quoi la nuée
## attendrait éternellement des agents qui ont déjà réussi.
##
## LE CAS D'ÉPREUVE (invariant n°12) est la nuée ÉTIRÉE par un goulot — tête
## sortie du couloir, queue encore dedans. Sur une nuée compacte, tous les
## écarts sont nuls, R15 ne se déclenche jamais et paraîtra toujours correcte.

func evaluate(agent: AgentState, state: SimState, params: RuleParams) -> Vector2i:
	var light: Vector2i = RuleTowardLight.nearest_light(agent.pos, state)
	if light.x < 0:
		return ABSTAIN  # aucun référentiel : la règle n'a pas d'objet

	var my_distance: int = _manhattan(agent.pos, light)
	var worst: int = my_distance
	for other in state.agents:
		if other.id == agent.id or not other.is_present():
			continue
		var dx: int = other.pos.x - agent.pos.x
		var dy: int = other.pos.y - agent.pos.y
		if dx * dx + dy * dy > params.pace_perception_range_sq:
			continue
		worst = maxi(worst, _manhattan(other.pos, light))

	if worst - my_distance > params.pace_max_gap:
		return Vector2i.ZERO  # trop d'avance : on attend le dernier
	return ABSTAIN            # le groupe est resserré : la suite décide

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
