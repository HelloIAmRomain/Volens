class_name LvlParser
extends RefCounted
## Convertisseur de niveaux `.lvl` -> Dictionary de niveau (avance sur
## T-074, préalable à T-040). Vit dans `tools/` : n'importe que `core/` et
## `data/`, aucun rendu, aucune interface.
##
## Format `.lvl` : en-tête `clé: valeur` (lignes `#` = commentaires),
## séparateur `---`, puis la grille ASCII (les espaces entre symboles sont
## ignorés). Clés : id, name, tutorial, allowed_rules, slots, max_ticks,
## lesson, expected_wins ; `objective:` répétable ; `cycle:` (v1 : une
## seule définition, partagée par toutes les cases C).
##
## DEUX CONVENTIONS FIGÉES — elles affectent le déterminisme :
## 1. Les identifiants d'agents sont attribués en ORDRE DE LECTURE (ligne
##    par ligne, de gauche à droite). L'id départage les prétendants à une
##    même case (DT-07) : deux fichiers visuellement identiques mais saisis
##    dans un ordre différent seraient deux simulations différentes —
##    l'ordre de lecture rend la convention prévisible et reproductible.
## 2. L'origine est EN HAUT À GAUCHE, y croissant vers le bas — cohérent
##    avec l'écriture du fichier et l'affichage portrait.
##
## Limitations v1, assumées et documentées :
## — pas de « phase » de cycle : CycleDef ne porte pas de décalage, tout
##   cycle démarre actif à t=0 ; en ajouter un toucherait le parcours de
##   hachage (corpus d'or entier) pour un besoin que le chapitre 1 n'a pas ;
## — sens uniques (^ > v <) REJETÉS : l'orientation n'est pas représentable
##   dans core/sim en l'état (chapitre 2+) ;
## — une seule définition de cycle par niveau (plusieurs C = même cycle).

## Bornes de grille du CDC §8.1 : 8×10 à 14×18, plus haute que large.
const MIN_WIDTH := 8
const MAX_WIDTH := 14
const MIN_HEIGHT := 10
const MAX_HEIGHT := 18

## Effectif de la nuée, RG-14 : 20 à 50 agents ⚙️. Trou de validation
## découvert en revue de conception le 6 août 2026 — les bornes RG
## contrôlables à la conversion sont depuis passées en revue EN BLOC
## (un trou trouvé en signale rarement un seul).
const MIN_AGENTS := 20
const MAX_AGENTS := 50

const _SYMBOLS := {
	".": GridState.CellType.EMPTY,
	"#": GridState.CellType.WALL,
	"L": GridState.CellType.LIGHT_SOURCE,
	"E": GridState.CellType.EXIT,
	"X": GridState.CellType.STATIC_DANGER,
	"C": GridState.CellType.CYCLIC_DANGER,
	"r": GridState.CellType.RESOURCE,
	"D": GridState.CellType.DROPOFF,
	"P": GridState.CellType.PRESSURE_DOOR,
}
const _ONE_WAY_SYMBOLS := ["^", ">", "v", "<"]

## Analyse un texte `.lvl`. Renvoie { "level": Dictionary, "errors":
## PackedStringArray } — des erreurs non vides invalident le niveau.
static func parse(text: String, min_cycle_period: int) -> Dictionary:
	var errors := PackedStringArray()
	var lines := text.split("\n")

	# --- Séparation en-tête / grille --------------------------------------
	var separator := -1
	for i in range(lines.size()):
		if lines[i].strip_edges() == "---":
			separator = i
			break
	if separator == -1:
		errors.append("séparateur `---` introuvable entre l'en-tête et la grille")
		return {"level": {}, "errors": errors}

	# --- En-tête -----------------------------------------------------------
	var header: Dictionary = {}
	var objectives: Array = []
	var cycle: Dictionary = {}
	for i in range(separator):
		var line := lines[i].strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var colon := line.find(":")
		if colon == -1:
			errors.append("ligne %d : `clé: valeur` attendu, lu « %s »" % [i + 1, line])
			continue
		var key := line.substr(0, colon).strip_edges()
		var value := line.substr(colon + 1).strip_edges()
		match key:
			"objective":
				var obj := _parse_objective(value, i + 1, errors)
				if not obj.is_empty():
					objectives.append(obj)
			"cycle":
				cycle = _parse_cycle(value, i + 1, errors)
			_:
				header[key] = value

	# --- Grille ------------------------------------------------------------
	var cells_rows: Array = []   # Array de Array[String] (symboles)
	for i in range(separator + 1, lines.size()):
		var raw := lines[i]
		if raw.strip_edges().is_empty():
			continue
		var row: Array = []
		for j in range(raw.length()):
			var ch := raw[j]
			if ch == " " or ch == "\t" or ch == "\r":
				continue
			row.append(ch)
		cells_rows.append({"symbols": row, "line": i + 1})

	if cells_rows.is_empty():
		errors.append("grille vide après le séparateur `---`")
		return {"level": {}, "errors": errors}

	var width: int = (cells_rows[0]["symbols"] as Array).size()
	var height: int = cells_rows.size()
	for entry in cells_rows:
		var n: int = (entry["symbols"] as Array).size()
		if n != width:
			errors.append("ligne %d : grille non rectangulaire (%d case(s), %d attendue(s))" % [entry["line"], n, width])

	if width < MIN_WIDTH or width > MAX_WIDTH or height < MIN_HEIGHT or height > MAX_HEIGHT:
		errors.append("dimensions %d×%d hors bornes CDC §8.1 (%d×%d à %d×%d)" % [width, height, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT])
	elif height <= width:
		errors.append("grille %d×%d : le CDC exige plus haute que large (portrait)" % [width, height])

	var cells: Array = []
	var cycle_index: Array = []
	var agents: Array = []
	var has_exit := false
	var has_cyclic := false
	var resource_count := 0
	for y in range(height):
		var symbols: Array = cells_rows[y]["symbols"]
		for x in range(mini(width, symbols.size())):
			var ch: String = symbols[x]
			var cell: int = GridState.CellType.EMPTY
			if ch == "o":
				# Convention n°1 : id = ordre de lecture (y puis x croissants).
				agents.append({"pos": [x, y]})
			elif ch in _ONE_WAY_SYMBOLS:
				errors.append("(%d,%d) : sens unique « %s » non supporté en v1 — l'orientation n'est pas représentable dans core/sim (chapitre 2+)" % [x, y, ch])
			elif _SYMBOLS.has(ch):
				cell = _SYMBOLS[ch]
			else:
				errors.append("(%d,%d) : symbole inconnu « %s »" % [x, y, ch])
			cells.append(cell)
			if cell == GridState.CellType.EXIT:
				has_exit = true
			if cell == GridState.CellType.RESOURCE:
				resource_count += 1
			if cell == GridState.CellType.CYCLIC_DANGER:
				has_cyclic = true
				cycle_index.append(0)
			else:
				cycle_index.append(-1)

	# --- Validations sémantiques -------------------------------------------
	if agents.is_empty():
		errors.append("aucun agent (« o ») dans la grille")
	elif agents.size() < MIN_AGENTS or agents.size() > MAX_AGENTS:
		errors.append("effectif de %d agents hors RG-14 (20 à 50 ⚙️) — dix points ne font pas une nuée, la forme collective est le personnage (DA-01)" % agents.size())

	# Cohérence des objectifs (revue générale du 6 août 2026).
	var max_ticks := int(header.get("max_ticks", "0"))
	var seen_types: Dictionary = {}
	var has_achievement := false
	var has_extraction := false
	for obj in objectives:
		var obj_type: String = obj.get("type", "")
		if seen_types.has(obj_type):
			errors.append("objectif « %s » en double" % obj_type)
		seen_types[obj_type] = true
		match obj_type:
			"extraction":
				has_achievement = true
				has_extraction = true
				var pc := int(obj["percent"])
				if pc < 1 or pc > 100:
					errors.append("extraction %d %% hors bornes (1 à 100 ; 0 rendrait le niveau dégénéré)" % pc)
			"collect":
				has_achievement = true
				if int(obj["count"]) < 1:
					errors.append("collect : compte < 1")
				elif int(obj["count"]) > resource_count:
					errors.append("collect %d > %d ressource(s) sur la grille : inatteignable dès le tick 0" % [int(obj["count"]), resource_count])
			"preservation":
				if not agents.is_empty() and int(obj["max_lost"]) >= agents.size():
					errors.append("preservation max_lost=%d >= effectif %d : contrainte sans effet" % [int(obj["max_lost"]), agents.size()])
			"celerity":
				if max_ticks >= 1 and int(obj["max_ticks"]) >= max_ticks:
					errors.append("celerity %d >= limite du niveau %d : échéance sans effet" % [int(obj["max_ticks"]), max_ticks])
			"interdiction":
				for pair in obj.get("cells", []):
					if int(pair[0]) < 0 or int(pair[0]) >= width or int(pair[1]) < 0 or int(pair[1]) >= height:
						errors.append("interdiction : case (%d,%d) hors de la grille %d×%d" % [int(pair[0]), int(pair[1]), width, height])
	if not has_achievement:
		errors.append("aucun objectif d'accomplissement (extraction/collect) : le niveau ne peut jamais être gagné — refus (exigence T-074, CDC §12.2.1)")

	if has_extraction and not has_exit:
		errors.append("objectif d'extraction sans aucune sortie (« E ») dans la grille")

	if has_cyclic and cycle.is_empty():
		errors.append("case « C » présente mais aucune ligne `cycle: period=N active=M` en en-tête")
	if not cycle.is_empty() and not has_cyclic:
		errors.append("cycle déclaré en en-tête mais aucune case « C » dans la grille")
	if not cycle.is_empty():
		var period := int(cycle.get("period", 0))
		var active := int(cycle.get("active_ticks", 0))
		if period < min_cycle_period:
			errors.append("cycle : période %d < plancher %d ⚙️ (validation.min_cycle_period)" % [period, min_cycle_period])
		if active < 1 or active >= period:
			errors.append("cycle : active=%d invalide (attendu 1 <= active < période %d)" % [active, period])

	var allowed_rules := _parse_allowed_rules(String(header.get("allowed_rules", "")), errors)
	var slots := int(header.get("slots", str(LevelSpec.MAX_SLOTS)))
	if slots < 1 or slots > StackEnumerator.MAX_SLOTS:
		errors.append("slots=%d invalide (attendu 1 à %d, RG-05)" % [slots, StackEnumerator.MAX_SLOTS])
	if max_ticks < 1:
		errors.append("max_ticks manquant ou invalide (entier >= 1 requis)")
	if header.has("expected_wins") and int(header["expected_wins"]) < 0:
		errors.append("expected_wins=%s invalide (entier >= 0 requis)" % header["expected_wins"])

	# Prédictions de fiche vs espace atteignable (CDC §12.2.1) :
	# expected_wins compte des PILES (convention de l'outil, arbitrage du
	# 6 août 2026) ; expected_classes, optionnel, compte des classes
	# structurelles — le validateur rapporte les deux.
	if header.has("expected_wins") and not allowed_rules.is_empty() \
			and slots >= 1 and slots <= StackEnumerator.MAX_SLOTS:
		var n_total := StackEnumerator.expected_count(allowed_rules.size(), slots)
		if int(header["expected_wins"]) > n_total:
			errors.append("expected_wins=%d > N_total=%d (%d règle(s), %d emplacement(s), pile vide incluse)" % [
				int(header["expected_wins"]), n_total, allowed_rules.size(), slots])
	if header.has("expected_classes"):
		if int(header["expected_classes"]) < 1:
			errors.append("expected_classes=%s invalide (entier >= 1 requis)" % header["expected_classes"])
		elif header.has("expected_wins") and int(header["expected_classes"]) > int(header["expected_wins"]):
			errors.append("expected_classes=%d > expected_wins=%d : impossible (une classe contient au moins une pile)" % [
				int(header["expected_classes"]), int(header["expected_wins"])])

	if not errors.is_empty():
		return {"level": {}, "errors": errors}

	# --- Assemblage du Dictionary de niveau ----------------------------------
	var level: Dictionary = {
		"id": String(header.get("id", "")),
		"max_ticks": max_ticks,
		"slots": slots,
		"allowed_rules": allowed_rules,
		"grid": {
			"size": [width, height],
			"cells": cells,
			"cycle_index": cycle_index if has_cyclic else [],
			"cycles": [cycle] if not cycle.is_empty() else [],
		},
		"agents": agents,
		"objectives": objectives,
	}
	if header.has("name"):
		level["name"] = _unquote(String(header["name"]))
	if header.has("lesson"):
		level["lesson"] = _unquote(String(header["lesson"]))
	if String(header.get("tutorial", "")).strip_edges() == "true":
		level["tutorial"] = true
	if header.has("expected_wins"):
		level["expected_wins"] = int(header["expected_wins"])
	if header.has("expected_classes"):
		level["expected_classes"] = int(header["expected_classes"])
	return {"level": level, "errors": errors}

## `[R01, R02]` ou `[1, 2]` -> [1, 2]. Chaque règle doit être implémentée
## (RuleRegistry) : une règle inconnue serait sautée par la cascade et
## fausserait silencieusement toute la validation du niveau.
static func _parse_allowed_rules(value: String, errors: PackedStringArray) -> Array:
	var out: Array = []
	var body := value.trim_prefix("[").trim_suffix("]")
	for token_raw in body.split(","):
		var token := token_raw.strip_edges()
		if token.is_empty():
			continue
		if token.begins_with("R") or token.begins_with("r"):
			token = token.substr(1)
		var rule_id := int(token)
		if RuleRegistry.get_rule(rule_id) == null:
			errors.append("allowed_rules : règle %s non implémentée à ce jour" % token_raw.strip_edges())
			continue
		if out.has(rule_id):
			errors.append("allowed_rules : règle %s en double (l'espace énuméré serait faux)" % token_raw.strip_edges())
			continue
		out.append(rule_id)
	if out.is_empty():
		errors.append("allowed_rules vide ou manquant")
	return out

## « extraction 100 », « preservation 2 », « celerity 120 », « collect 3 »,
## « interdiction (1,2) (3,4) ».
static func _parse_objective(value: String, line: int, errors: PackedStringArray) -> Dictionary:
	var parts := value.split(" ", false)
	if parts.is_empty():
		errors.append("ligne %d : objectif vide" % line)
		return {}
	match parts[0]:
		"extraction":
			return {"type": "extraction", "percent": int(parts[1]) if parts.size() > 1 else 100}
		"preservation":
			return {"type": "preservation", "max_lost": int(parts[1]) if parts.size() > 1 else 0}
		"celerity":
			return {"type": "celerity", "max_ticks": int(parts[1]) if parts.size() > 1 else 1}
		"collect":
			return {"type": "collect", "count": int(parts[1]) if parts.size() > 1 else 1}
		"interdiction":
			var cells: Array = []
			for i in range(1, parts.size()):
				var pair := parts[i].trim_prefix("(").trim_suffix(")").split(",")
				if pair.size() == 2:
					cells.append([int(pair[0]), int(pair[1])])
				else:
					errors.append("ligne %d : case interdite « %s » illisible (attendu (x,y))" % [line, parts[i]])
			return {"type": "interdiction", "cells": cells}
		_:
			errors.append("ligne %d : type d'objectif inconnu « %s »" % [line, parts[0]])
			return {}

## « period=6 active=3 » -> { period, active_ticks }.
static func _parse_cycle(value: String, line: int, errors: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for token in value.split(" ", false):
		var eq := token.find("=")
		if eq == -1:
			errors.append("ligne %d : jeton de cycle « %s » illisible (attendu clé=valeur)" % [line, token])
			continue
		var key := token.substr(0, eq)
		var v := int(token.substr(eq + 1))
		if key == "period":
			out["period"] = v
		elif key == "active":
			out["active_ticks"] = v
		else:
			errors.append("ligne %d : clé de cycle inconnue « %s » (period, active)" % [line, key])
	return out

static func _unquote(s: String) -> String:
	return s.trim_prefix("\"").trim_suffix("\"")
