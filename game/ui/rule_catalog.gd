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
const RULES := {
	1: {"key": "rule.r01", "name": "Vers la lumière", "glyph": "☀", "line": "L'agent se rapproche de la lumière la plus proche."},
	2: {"key": "rule.r02", "name": "Fuir le danger", "glyph": "⚠", "line": "L'agent s'éloigne du danger perçu."},
	3: {"key": "rule.r03", "name": "Rester groupé", "glyph": "◍", "line": "L'agent rejoint le centre de ses voisins."},
}

static func name_of(rule_id: int) -> String:
	var entry: Dictionary = RULES.get(rule_id, {})
	return String(entry.get("name", "règle %d" % rule_id))

static func glyph_of(rule_id: int) -> String:
	var entry: Dictionary = RULES.get(rule_id, {})
	return String(entry.get("glyph", "?"))

static func line_of(rule_id: int) -> String:
	var entry: Dictionary = RULES.get(rule_id, {})
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
				parts.append("%d/%d perdus" % [state.counters.lost, int(entry.get("max_lost", 0))])
			"celerity":
				parts.append("%d/%d ticks" % [state.tick, int(entry.get("max_ticks", 0))])
			"interdiction":
				parts.append("zone interdite")
	if state.counters.lost > 0 and not _has_type(objectives, "preservation"):
		parts.append("%d perdu%s" % [state.counters.lost, "s" if state.counters.lost > 1 else ""])
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
	return "Le temps imparti s'est écoulé avant l'objectif."

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
