class_name RuleCarry
extends Rule
## R11 — Porter et déposer [CDC §7.2] : l'agent ramasse la ressource présente
## sur sa case s'il n'en porte pas, et la laisse sur un dépôt adjacent s'il en
## porte une.
##
## POURQUOI CE FUT DEUX RÈGLES, ET POURQUOI CE N'EN EST PLUS QU'UNE.
##
## « Porter » et « Déposer » ont vécu séparées jusqu'au 21 août 2026. La mesure
## a tranché : sur les CINQ niveaux qui les emploient, la contention RG-13 entre
## R11 et R12 vaut **zéro** — leur ordre relatif n'a jamais changé le moindre
## résultat.
##
## Et ce n'est pas un accident de cartes : c'est structurel. Un agent est soit
## les mains VIDES sur une ressource, soit CHARGÉ près d'un dépôt. Les deux
## gardes s'excluent au même tick, donc les deux effets ne peuvent jamais se
## disputer une décision — sur aucune carte concevable.
##
## **Deux rangs de pile pour une seule décision, c'est un coût sans retour.**
## Le joueur en dispose de trois ou quatre ; en consacrer deux à un couple dont
## l'ordre ne se voit pas, c'est lui retirer un choix sans rien lui donner. Les
## deux règles apparaissaient d'ailleurs en MONOPOLE dans toutes les familles
## gagnantes du chapitre 4 : ensemble ou pas du tout.
##
## LA CASCADE EST REPRODUITE À L'IDENTIQUE — ramasser d'abord, déposer ensuite,
## dans le même tick. C'était le comportement de la pile `[R11, R12]`, où R12
## lisait le drapeau que R11 venait de poser : une ressource adjacente à un
## dépôt se ramassait et se livrait d'un coup. Fusionner en `sinon` aurait
## changé cela en silence.
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
		_params: RuleParams, _moved: bool) -> bool:
	var agent := state.agents[agent_index]
	if not agent.is_present():
		return false
	var carrier := next_state.agents[agent_index]
	var acted := false
	# RAMASSER — une ressource à la fois.
	if (carrier.flags & AgentState.PORTEUR) == 0:
		var idx: int = state.grid.index_of(agent.pos)
		# On lit `next_state` pour la case : un agent d'id plus petit a pu prendre
		# la ressource au même tick, et il n'en reste alors plus rien. C'est
		# l'unique endroit du moteur où un effet voit celui d'un autre agent, et
		# c'est nécessaire — sans quoi deux agents ramasseraient la même ressource.
		if next_state.grid.cells[idx] == GridState.CellType.RESOURCE:
			next_state.grid.cells[idx] = GridState.CellType.EMPTY
			carrier.flags |= AgentState.PORTEUR
			acted = true

	# DÉPOSER — ADJACENT, PAS SOUS LES PIEDS, et cette nuance porte tout le
	# chapitre 4. Si le dépôt se faisait en marchant DESSUS, une case de dépôt
	# serait une sortie de plus et R01 y mènerait seule ; en exigeant l'adjacence,
	# le dépôt devient un point que la nuée doit FRÔLER sans y entrer.
	#
	# L'ordre N>E>S>O départage les dépôts adjacents. Un seul dépôt par tick et
	# par agent : `counters.delivered` avance d'exactement un.
	#
	# LE PORTEUR REDEVIENT LIBRE et peut repartir chercher. Rien ne le lui dit —
	# aucune règle ne connaît « il reste des ressources » — et c'est délibéré : le
	# joueur doit composer une pile qui fasse le va-et-vient sans le savoir.
	if (carrier.flags & AgentState.PORTEUR) == 0:
		return acted
	for dir in Directions.ORDER:
		var candidate: Vector2i = agent.pos + Directions.offset(dir)
		if not state.grid.is_in_bounds(candidate):
			continue
		if state.grid.cell_type_at(candidate) != GridState.CellType.DROPOFF:
			continue
		carrier.flags &= ~AgentState.PORTEUR
		next_state.counters.delivered += 1
		return true
	return acted
