class_name RuleCatalog
extends RefCounted
## Présentation des règles côté interface : nom court et glyphe. Les
## identifiants viennent de `RuleRegistry` (core/), la présentation vit ici —
## `core/` ne connaît ni texte ni couleur.
##
## Les libellés passeront par le système de traduction de Godot (DCT §9.3) ;
## ils sont ici en dur le temps du prototype, avec des clés stables prêtes à
## être extraites.

## id de règle -> { key, nom, glyphe, phrase }
## CHAQUE PHRASE DIT CE QUE LA RÈGLE FAIT, ET SEULEMENT CELA. Aucune ne dit à
## quoi elle sert : le jeu ne donne pas de conseil, il décrit un mécanisme et
## laisse le joueur en tirer les conséquences. Une phrase qui dirait « utile
## pour sortir d'un cul-de-sac » ferait le travail à sa place — et serait
## fausse la moitié du temps, comme les niveaux le montrent.
##
## LES RÈGLES D'EFFET SONT NOMMÉES COMME TELLES, parce que la règle d'or ne
## s'applique pas à elles de la même façon : « puis rend la main » est la
## moitié de ce que le joueur doit savoir pour les placer.
const RULES := {
	1: {"key": "rule.r01", "name": "Vers la lumière", "glyph": "☀", "line": "L'agent se rapproche de la lumière la plus proche. Il refuse tout pas qui l'en éloigne."},
	2: {"key": "rule.r02", "name": "Fuir le danger", "glyph": "⚠", "line": "L'agent s'éloigne du danger perçu."},
	3: {"key": "rule.r03", "name": "Rester groupé", "glyph": "◍", "line": "L'agent isolé rejoint le centre de ses voisins. Groupé, il laisse la main."},
	4: {"key": "rule.r04", "name": "S'écarter", "glyph": "⤢", "line": "Au contact de trop de voisins, l'agent prend le pas qui l'en éloigne le plus."},
	5: {"key": "rule.r05", "name": "Suivre les voisins", "glyph": "⇉", "line": "L'agent adopte la direction majoritaire des voisins qui ont bougé."},
	6: {"key": "rule.r06", "name": "Longer le mur", "glyph": "⌐", "line": "Contre un obstacle : à droite, sinon tout droit, sinon à gauche, sinon demi-tour."},
	7: {"key": "rule.r07", "name": "Attendre", "glyph": "⏸", "line": "L'agent reste immobile. Aucune règle placée en dessous ne parlera jamais."},
	8: {"key": "rule.r08", "name": "Marquer la piste", "glyph": "✦", "line": "EFFET — en avançant, l'agent marque la case quittée, puis rend la main. La marque s'estompe."},
	9: {"key": "rule.r09", "name": "Suivre la piste", "glyph": "⋯", "line": "L'agent va vers le marqueur voisin plus intense que le sien."},
	10: {"key": "rule.r10", "name": "Rebrousser si seul", "glyph": "↩", "line": "Sans aucun congénère à portée, l'agent fait demi-tour."},
	11: {"key": "rule.r11", "name": "Porter", "glyph": "◆", "line": "EFFET — l'agent ramasse l'objet de sa case, puis rend la main. Un porteur ne sort pas du niveau."},
	12: {"key": "rule.r12", "name": "Déposer au but", "glyph": "▽", "line": "EFFET — le porteur pose son objet dans un dépôt voisin, puis rend la main."},
	13: {"key": "rule.r13", "name": "Boucher", "glyph": "✚", "line": "L'agent entre dans un danger adjacent et s'y consume, le neutralisant définitivement."},
	14: {"key": "rule.r14", "name": "Disperser si dense", "glyph": "⁘", "line": "Dans une zone trop peuplée, l'agent va vers la case la moins entourée."},
	15: {"key": "rule.r15", "name": "Suivre le plus lent", "glyph": "⧗", "line": "Trop en avance sur le dernier qu'il perçoit, l'agent s'arrête et l'attend."},
	16: {"key": "rule.r16", "name": "Ignorer", "glyph": "⊘", "line": "L'agent cesse de subir un type de case, choisi au placement. Son rang ne change rien, mais il coûte une place."},
}

## Nom du type de case neutralisé par un joker. Le vocabulaire est celui de
## RG-14, mot pour mot : le joueur doit reconnaître ce qu'il a vu sur la carte.
const IGNORABLE := {
	GridState.CellType.STATIC_DANGER: "le feu",
	GridState.CellType.CYCLIC_DANGER: "le feu cyclique",
	GridState.CellType.ONE_WAY: "les sens uniques",
	GridState.CellType.PRESSURE_DOOR: "les portes",
}

static func name_of(rule_id: int) -> String:
	var base := RuleRegistry.base_rule_id(rule_id)
	var entry: Dictionary = RULES.get(base, {})
	var label := String(entry.get("name", "règle %d" % base))
	# UN JOKER SANS SON ARGUMENT EST ILLISIBLE : « Ignorer » ne dit pas quoi.
	# Le nom porte donc la cible, et deux jokers de cibles différentes se
	# distinguent à l'œil sans qu'on ait à les sélectionner.
	var ignored := RuleRegistry.ignored_cell_of(rule_id)
	if ignored >= 0 and IGNORABLE.has(ignored):
		return "%s %s" % [label, IGNORABLE[ignored]]
	return label

static func glyph_of(rule_id: int) -> String:
	var entry: Dictionary = RULES.get(RuleRegistry.base_rule_id(rule_id), {})
	return String(entry.get("glyph", "?"))

static func line_of(rule_id: int) -> String:
	var entry: Dictionary = RULES.get(RuleRegistry.base_rule_id(rule_id), {})
	return String(entry.get("line", ""))

## Avancement en continu dans le bandeau (RG-17) : chiffré, jamais en
## pourcentage abstrait. « 14/20 sortis · 0 perdu » se lit d'un coup d'œil,
## « extraction 100 % » demande un calcul.
static func objective_line(objectives: Array, state: SimState) -> String:
	if objectives.is_empty():
		return "Aucun objectif"
	var total: int = state.agents.size()
	var parts := PackedStringArray()
	for entry in objectives:
		match String(entry.get("type", "")):
			"extraction":
				parts.append("%d/%d sortis" % [state.counters.exited, _needed(entry, total)])
			"collect":
				parts.append("%d/%d livrés" % [state.counters.delivered, int(entry.get("count", 1))])
			"preservation":
				# « 1/1 perdus » SE LIT COMME UN BUT À ATTEINDRE, exactement comme
				# « 14/20 sortis » juste à côté — alors que le second nombre est un
				# PLAFOND à ne pas franchir, soit le sens inverse sous la même forme.
				# Signalé à l'essai : « on pourrait croire qu'il faut un perdu ».
				# On change donc la forme, pas seulement le mot : une limite ne
				# s'écrit jamais comme une fraction.
				var cap: int = int(entry.get("max_lost", 0))
				var lost: int = state.counters.lost
				if cap <= 0:
					parts.append("%d perdu%s · aucune perte tolérée" % [
						lost, "s" if lost > 1 else ""])
				else:
					parts.append("%d perdu%s · %d max" % [
						lost, "s" if lost > 1 else "", cap])
			"celerity":
				parts.append("%d/%d ticks" % [state.tick, int(entry.get("max_ticks", 0))])
			"interdiction":
				parts.append("zone interdite")
	# Un simple RELEVÉ, sur un niveau qui ne compte pas les pertes : « agent »
	# est écrit en toutes lettres pour qu'on ne le lise pas comme un objectif
	# chiffré accolé au précédent.
	if state.counters.lost > 0 and not _has_type(objectives, "preservation"):
		parts.append("%d agent%s perdu%s" % [state.counters.lost,
			"s" if state.counters.lost > 1 else "", "s" if state.counters.lost > 1 else ""])
	return "   ·   ".join(parts)

## Énoncé EXPLICITE pour le panneau d'ouverture : ce que le joueur doit
## faire, en clair et en nombres. Aucune explication de règle, aucun
## conseil — ce n'est pas un tutoriel.
static func objective_brief(objectives: Array, total_agents: int) -> Array[String]:
	var lines: Array[String] = []
	for entry in objectives:
		match String(entry.get("type", "")):
			"extraction":
				lines.append("Faire sortir %d agents sur %d." % [_needed(entry, total_agents), total_agents])
			"collect":
				lines.append("Livrer %d ressources." % int(entry.get("count", 1)))
			"preservation":
				var m: int = int(entry.get("max_lost", 0))
				lines.append("Perdre au plus %d agent%s." % [m, "s" if m > 1 else ""])
			"celerity":
				lines.append("Terminer en %d ticks au plus." % int(entry.get("max_ticks", 0)))
			"interdiction":
				lines.append("Ne jamais entrer dans la zone interdite.")
	if lines.is_empty():
		lines.append("Observer la nuée.")
	return lines

## Pourquoi la partie s'est terminée, en une phrase — c'est ce qui manque le
## plus quand l'échec tombe avant qu'on ait rien vu (pilier P4).
static func outcome_reason(objectives: Array, state: SimState) -> String:
	var total: int = state.agents.size()
	if state.outcome == SimState.Outcome.WON:
		return "La nuée a rempli l'objectif." if state.counters.lost == 0 \
			else "Objectif rempli, malgré %d perte%s." % [state.counters.lost, "s" if state.counters.lost > 1 else ""]
	for entry in objectives:
		var kind := String(entry.get("type", ""))
		if kind == "preservation" and state.counters.lost > int(entry.get("max_lost", 0)):
			return "%d agents perdus : la limite de %d est dépassée." % [
				state.counters.lost, int(entry.get("max_lost", 0))]
		if kind == "extraction":
			var needed: int = _needed(entry, total)
			var still_possible: int = state.counters.exited + _present(state)
			if still_possible < needed:
				return "%d agent%s perdu%s — l'objectif de %d sur %d est devenu inatteignable." % [
					state.counters.lost, "s" if state.counters.lost > 1 else "",
					"s" if state.counters.lost > 1 else "", needed, total]
		if kind == "celerity" and state.tick >= int(entry.get("max_ticks", 0)):
			return "Le délai de %d ticks est écoulé." % int(entry.get("max_ticks", 0))
		# INTERDICTION — le seul objectif dont la violation est INSTANTANÉE, et le
		# seul dont l'échec ne se lit sur aucun compteur. Sans phrase dédiée, le
		# joueur lisait « le temps imparti s'est écoulé » alors que la partie
		# s'était arrêtée au troisième tick : un message faux vaut moins que pas
		# de message.
		if kind == "interdiction" and _anyone_on(entry, state):
			return "La nuée est entrée dans la zone interdite."
		# COLLECTE — l'échec y est un compteur qui n'a pas assez avancé, jamais un
		# événement. Le dire chiffré : « 1 sur 3 » situe l'écart, « objectif non
		# rempli » ne dit rien de ce qu'il faut corriger.
		if kind == "collect":
			var goal: int = int(entry.get("count", 1))
			if state.counters.delivered < goal:
				if state.counters.delivered == 0:
					return "Aucune ressource livrée : %d étaient demandées." % goal
				return "%d ressource%s livrée%s sur %d." % [
					state.counters.delivered, "s" if state.counters.delivered > 1 else "",
					"s" if state.counters.delivered > 1 else "", goal]
	return "Le temps imparti s'est écoulé avant l'objectif."

## Un agent se trouve-t-il sur une case interdite ? Les indices sont
## pré-calculés au chargement du niveau (`ObjectiveDef.cells`) ; on les relit
## ici sur le brut du fichier, qui porte des couples [x, y].
static func _anyone_on(entry: Dictionary, state: SimState) -> bool:
	for pair in entry.get("cells", []):
		var p := Vector2i(int(pair[0]), int(pair[1]))
		for a in state.agents:
			if a.pos == p:
				return true
	return false

static func _needed(entry: Dictionary, total: int) -> int:
	return int(ceil(float(int(entry.get("percent", 100)) * total) / 100.0))

static func _has_type(objectives: Array, kind: String) -> bool:
	for entry in objectives:
		if String(entry.get("type", "")) == kind:
			return true
	return false

static func _present(state: SimState) -> int:
	var n := 0
	for a in state.agents:
		if a.is_present():
			n += 1
	return n
