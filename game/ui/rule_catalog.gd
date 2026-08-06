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
	2: {"key": "rule.r02", "name": "Fuir le rouge", "glyph": "⚠", "line": "L'agent s'éloigne du danger perçu."},
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

## Énoncé d'objectif en UNE ligne, avec l'avancement en continu (RG-17).
## `objectives` est le tableau brut du fichier de niveau ; les compteurs
## viennent de l'état courant.
static func objective_line(objectives: Array, state: SimState) -> String:
	if objectives.is_empty():
		return "Aucun objectif"
	var total: int = state.agents.size()
	var parts := PackedStringArray()
	for entry in objectives:
		match String(entry.get("type", "")):
			"extraction":
				var needed: int = int(ceil(float(int(entry.get("percent", 100)) * total) / 100.0))
				parts.append("%d/%d sortis" % [state.counters.exited, needed])
			"collect":
				parts.append("%d/%d livrés" % [state.counters.delivered, int(entry.get("count", 1))])
			"preservation":
				parts.append("pertes : %d/%d max" % [state.counters.lost, int(entry.get("max_lost", 0))])
			"celerity":
				parts.append("temps : %d/%d" % [state.tick, int(entry.get("max_ticks", 0))])
			"interdiction":
				parts.append("zone interdite")
	return "   ·   ".join(parts)
