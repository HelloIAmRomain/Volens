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
	## BASCULE — le premier agent qui la foule ouvre les portes definitivement.
	## Complement permanent de la plaque, qui est momentanee.
	"S": GridState.CellType.SWITCH,
	## ATELIER A BOUCLIERS : tout agent qui traverse en repart protege. Le
	## bouclier encaisse UN contact mortel puis se brise, sans abimer le danger.
	"B": GridState.CellType.SHIELD,
}
## Ordre calqué sur `Directions` : NORTH, EAST, SOUTH, WEST. L'index dans ce
## tableau EST l'identifiant de direction — les désynchroniser ferait entrer
## les agents par le mauvais côté sans qu'aucun test de niveau ne le dise.
const _ONE_WAY_SYMBOLS := ["^", ">", "v", "<"]

## PISTE INITIALE — « * » depose un marqueur a saturation sur une case vide.
##
## Ce n'est pas un dixieme element du vocabulaire RG-14 : la piste n'est pas un
## type de CASE, c'est une valeur portee par une case ordinaire, exactement
## comme au cours d'une partie. Le symbole ne fait qu'ecrire dans la couche de
## pheromone ce que R08 y ecrirait.
##
## CE QU'IL RACONTE : une nuee est deja passee ici. C'est le seul moyen qu'a un
## niveau de commencer avec une memoire, et le chapitre 3 en a besoin — sans
## trace prealable, R09 n'a rien a suivre au premier tick et le mecanisme ne
## peut pas s'enseigner isolement.
##
## UNE PISTE DOIT ETRE UNE PENTE, PAS UN TAPIS. R09 va vers le marqueur voisin
## STRICTEMENT plus intense que sa propre case — sans quoi un agent au sommet
## d'une piste descendrait, puis remonterait, indefiniment (pathologie P3).
## Consequence : une piste d'intensite uniforme n'oriente personne. Mesure
## faite : vingt-cinq agents immobiles sur une colonne marquee a plat.
##
## Les chiffres 1 a 9 posent donc une intensite croissante — `_TRAIL_STEP` par
## echelon — et « * » la saturation. On dessine la pente en ecrivant les
## chiffres dans le sens de la marche.
const _TRAIL_SYMBOL := "*"
const _TRAIL_STEP := 6
const _TRAIL_MAX := 60

## Analyse un texte `.lvl`. Renvoie { "level": Dictionary, "errors":
## PackedStringArray } — des erreurs non vides invalident le niveau.
## `flee_range_sq` : portée de perception de R02 (data/rules.json). Elle sert
## aux contrôles de géométrie, qui raisonnent sur ce que la fuite perçoit.
## Valeur par défaut alignée sur RuleParams pour que les appels historiques
## à deux arguments restent valides.
static func parse(text: String, min_cycle_period: int, flee_range_sq: int = 25) -> Dictionary:
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
	var doors: Array = []
	var patrols: Array = []
	var header_trail: Array = []
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
			"trail":
				# `trail: 4,0=60 5,0=60` — pose une piste sur des cases qui portent
				# DEJA un symbole. Les chiffres de la grille suffisent pour une case
				# vide ; ils ne peuvent rien dire d'une sortie ou d'une case de
				# depart, qui portent leur propre lettre. Or R09 ne va que vers plus
				# intense que sa case : une sortie non marquee est une sortie que la
				# piste ne franchit pas, et la nuee s'arrete a une case du but.
				for token in value.split(" "):
					var tok := String(token).strip_edges()
					if tok.is_empty():
						continue
					var halves := tok.split("=")
					var xy := String(halves[0]).split(",")
					if xy.size() != 2 or halves.size() != 2:
						errors.append("ligne %d : « %s » n'est pas x,y=intensite" % [i + 1, tok])
						continue
					header_trail.append([int(xy[0]), int(xy[1]), int(halves[1])])
			"patrol":
				# `patrol: 3,5;4,5;5,5;4,5` — un trajet FERMÉ, parcouru en boucle,
				# une case par tick. Répétable : plusieurs patrouilles cohabitent.
				#
				# LE TRAJET SE DÉCRIT EN ENTIER, aller ET retour, plutôt qu'en
				# « va-et-vient » implicite. C'est plus long à écrire et cela évite
				# une ambiguïté qui coûterait cher : sur un aller-retour déduit, la
				# case de demi-tour est-elle occupée une fois ou deux ? La réponse
				# change la période, donc tous les temps de passage du niveau.
				# Les couples x,y sont conservés TELS QUELS, comme ceux des portes :
				# la largeur de la grille n'est pas encore connue à la lecture de
				# l'en-tête, et c'est `SimCore.load_level` qui indexe.
				var path := _parse_patrol(value, i + 1, errors)
				if not path.is_empty():
					patrols.append(path)
			"door":
				# `door: required=2 plates=1,4;2,4 panels=5,6;6,6`
				# Répétable : un niveau peut porter plusieurs portes indépendantes.
				var parsed := _parse_door(value, i + 1, errors)
				if not parsed.is_empty():
					doors.append(parsed)
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
	var one_way: Array = []
	var trail: Array = []
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
				# SENS UNIQUE, accepté depuis le 14 août 2026 : `GridState.one_way_dir`
				# porte l'orientation et `can_traverse` la contrôle. Le symbole DÉSIGNE
				# la direction autorisée, pas celle qui est interdite — « > » se lit
				# « on ne peut y entrer qu'en allant vers l'Est ».
				one_way.append([x, y, _ONE_WAY_SYMBOLS.find(ch)])
			elif ch == _TRAIL_SYMBOL:
				trail.append([x, y, _TRAIL_MAX])
			elif ch.length() == 1 and ch >= "1" and ch <= "9":
				trail.append([x, y, int(ch) * _TRAIL_STEP])
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

	# --- Contraintes de GÉOMÉTRIE (invariants n°13 et n°14, docs/ARCHITECTURE.md) -------
	#
	# Ces trois contrôles existent parce que les trois leçons correspondantes
	# ont RÉCIDIVÉ après avoir été consignées — la dernière dix minutes après
	# son écriture. Une note ne protège de rien ; ces contrôles, si.
	#
	# Chacun a rendu un niveau INSOLUBLE au moins une fois pendant la
	# conception du chapitre 1, et le diagnostic prenait à chaque fois une
	# simulation complète de seize piles. Ici il coûte une lecture de grille.
	# Uniquement sur une grille déjà cohérente : analyser la géométrie d'une
	# grille non rectangulaire n'a pas de sens, et l'indexation y sortirait des
	# bornes. Les erreurs de structure se corrigent d'abord.
	var warnings := PackedStringArray()
	if errors.is_empty():
		# LES TROIS CONTROLES DE GEOMETRIE NE PORTENT QUE SUR R02. Ils decrivent
		# tous des pathologies de la FUITE — refus d'avancer vers un danger plein
		# nord, fuite opposee a l'ouverture, oscillation entre deux repulseurs. Sur
		# un niveau qui n'offre pas R02, ils interdisent des cartes parfaitement
		# jouables : un danger n'y est plus qu'un piege immobile, et deux dangers
		# n'enferment personne puisque rien ne repousse.
		if allowed_rules.has(RuleRegistry.R02_FLEE_DANGER):
			_check_geometry(cells, width, height, agents, flee_range_sq, errors, warnings)

	if not errors.is_empty():
		return {"level": {}, "errors": errors, "warnings": warnings}

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
			"one_way": one_way,
			"doors": doors,
			"patrols": patrols,
			"trail": trail + header_trail,
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

	# --- Défis facultatifs [RG-18] ---
	#
	# `challenge: economy=2 abstinence=R06 efficiency=24`. AUCUN n'est
	# obligatoire : un niveau sans ligne `challenge:` n'en propose simplement
	# aucun, et l'interface le dit plutôt que d'afficher trois cases éteintes
	# que rien ne permet d'allumer.
	#
	# `economy=N` A REMPLACÉ UNE CONSTANTE GLOBALE, et c'était le défaut le plus
	# répandu du jeu : le seuil valait « trois emplacements » pour tout le monde,
	# alors que vingt-huit niveaux sur vingt-neuf n'en ont que trois. Le défi
	# était donc OFFERT d'office, en même temps que la victoire. Il est désormais
	# mesuré par niveau — et absent quand toutes les gagnantes ont la même taille.
	if header.has("challenge"):
		var spec: Dictionary = {}
		for token in String(header["challenge"]).split(" "):
			var t := String(token).strip_edges()
			if t.begins_with("abstinence="):
				var rule_token := t.substr(11).lstrip("Rr")
				var rule_id := int(rule_token)
				if RuleRegistry.get_rule(rule_id) == null:
					errors.append("challenge : abstinence sur la règle %s, qui n'existe pas" % t.substr(11))
				elif not allowed_rules.has(rule_id):
					# Un défi d'abstinence sur une règle que le niveau n'offre
					# pas est gagné d'avance : il ne demande rien.
					errors.append(("challenge : abstinence sur R%02d, qui n'est pas dans "
						+ "allowed_rules — le défi serait acquis sans rien faire") % rule_id)
				else:
					spec["abstinence_rule"] = rule_id
			elif t.begins_with("efficiency="):
				spec["efficiency_ticks"] = int(t.substr(11))
			elif t.begins_with("economy="):
				var cap := int(t.substr(8))
				if cap < 1 or cap > slots:
					errors.append(("challenge : economy=%d hors des rangs du niveau "
						+ "(1 à %d) — un seuil au-dessus du nombre de rangs est acquis "
						+ "d'office") % [cap, slots])
				else:
					spec["economy_max"] = cap
			elif not t.is_empty():
				errors.append(("challenge : jeton « %s » inconnu (attendu economy=N, "
					+ "abstinence=Rxx ou efficiency=N)") % t)
		if not spec.is_empty():
			level["challenges"] = spec

	# --- Calibration : les paramètres valent-ils encore ? [invariant n°15] ---
	#
	# Échéance, seuil de préservation, pourcentage d'extraction et limite de
	# ticks sont MESURÉS sur une géométrie donnée. Si la grille ou les
	# positions initiales ont bougé depuis, ils ne décrivent plus rien.
	# Le niveau archive donc l'empreinte sous laquelle il a été calibré ; on la
	# recalcule ici, et l'on refuse si elle a changé.
	var geometry := LevelSpec.geometry_hash(level)
	level["geometry_hash"] = geometry
	if header.has("calibrated_on"):
		var declared := String(header["calibrated_on"]).strip_edges()
		level["calibrated_on"] = declared
		if declared != geometry:
			errors.append(("la géométrie a changé depuis la calibration : `calibrated_on: %s` "
				+ "mais la grille actuelle vaut %s. Les paramètres mesurés (échéance, "
				+ "préservation, extraction, max_ticks) ont été calibrés sur une AUTRE carte "
				+ "et ne décrivent plus ce niveau (invariant n°15). Remesurer, puis inscrire "
				+ "`calibrated_on: %s`.") % [declared, geometry, geometry])
			return {"level": {}, "errors": errors, "warnings": warnings}
	else:
		warnings.append(("aucun `calibrated_on` : les paramètres de ce niveau ne sont "
			+ "protégés par rien. Inscrire `calibrated_on: %s` une fois les mesures faites "
			+ "(invariant n°15).") % geometry)
	return {"level": level, "errors": errors, "warnings": warnings}

## --- Contraintes de géométrie -------------------------------------------
##
## Trois pièges, tous découverts à la mesure, tous reproductibles.
##
## G1 — DANGER PLEIN NORD (avertissement). R02 fuit en augmentant la distance
##      de Manhattan. Pour un agent situé au sud d'un danger, monter la
##      DIMINUE : R02 refuse donc d'avancer tant que le danger est à portée,
##      pendant que R01 rappelle vers la lumière. Les deux se renvoient
##      l'agent à la frontière de portée — boucle infinie.
##      Avertissement et non refus : la configuration reste jouable si la
##      fuite latérale mène quelque part (c'est le cas de ch1_02).
##
## G2 — FUITE ET ENTONNOIR EN SENS OPPOSÉS (avertissement). Avec une ouverture
##      étroite, si le danger pousse les agents du côté OPPOSÉ à l'ouverture,
##      il faut revenir — et revenir, c'est rentrer dans la portée.
##
## G3 — DEUX DANGERS ENCADRANT LA NUÉE (refus). Invariant n°13 : deux
##      répulseurs statiques dont les portées couvrent un même agent depuis
##      des côtés opposés l'enferment. Refus, parce qu'aucune géométrie ne
##      rattrape ça — le niveau est insoluble par construction.
static func _check_geometry(cells: Array, width: int, height: int, agents: Array,
		flee_range_sq: int, errors: PackedStringArray, warnings: PackedStringArray) -> void:
	var dangers: Array = []
	var exits: Array = []
	if cells.size() < width * height:
		return
	for y in range(height):
		for x in range(width):
			var c: int = cells[y * width + x]
			if c == GridState.CellType.STATIC_DANGER:
				dangers.append(Vector2i(x, y))
			elif c == GridState.CellType.EXIT:
				exits.append(Vector2i(x, y))
	if dangers.is_empty() or agents.is_empty():
		return

	var positions: Array = []
	var sum_x := 0
	for a in agents:
		var p := Vector2i(int(a["pos"][0]), int(a["pos"][1]))
		positions.append(p)
		sum_x += p.x
	var block_centre_x: int = sum_x / positions.size()

	# G1 — un agent plein sud d'un danger, à portée de fuite.
	for d in dangers:
		for p in positions:
			if p.x != d.x or p.y <= d.y:
				continue
			var dy: int = p.y - d.y
			if dy * dy <= flee_range_sq:
				warnings.append(("danger (%d,%d) plein NORD de l'agent (%d,%d), à portée de fuite "
					+ "(invariant n°14) : R02 y refuse d'avancer tant que le danger est perçu. "
					+ "Vérifier que la fuite latérale mène à l'ouverture, sinon cycle limite.") % [
					d.x, d.y, p.x, p.y])
				break

	# G2 — la fuite pousse à l'opposé de l'ouverture.
	if not exits.is_empty():
		var sum_ex := 0
		for e in exits:
			sum_ex += e.x
		var exit_centre_x: int = sum_ex / exits.size()
		for d in dangers:
			if not _threatens_any(d, positions, flee_range_sq):
				continue
			var flee_dir: int = signi(block_centre_x - d.x)
			var exit_dir: int = signi(exit_centre_x - block_centre_x)
			if flee_dir != 0 and exit_dir != 0 and flee_dir != exit_dir:
				warnings.append(("danger (%d,%d) : la fuite pousse la nuée vers x %s alors que "
					+ "l'ouverture est vers x %s. Fuite et entonnoir tirent en sens opposés — "
					+ "les agents devront revenir dans la portée.") % [
					d.x, d.y, "croissant" if flee_dir > 0 else "décroissant",
					"croissant" if exit_dir > 0 else "décroissant"])

	# G3 — deux dangers encadrent un même agent : insoluble par construction.
	for i in range(dangers.size()):
		for j in range(i + 1, dangers.size()):
			var a: Vector2i = dangers[i]
			var b: Vector2i = dangers[j]
			for p in positions:
				if not _in_range(a, p, flee_range_sq) or not _in_range(b, p, flee_range_sq):
					continue
				var opposed_x: bool = signi(a.x - p.x) * signi(b.x - p.x) < 0
				var opposed_y: bool = signi(a.y - p.y) * signi(b.y - p.y) < 0
				if opposed_x or opposed_y:
					errors.append(("dangers (%d,%d) et (%d,%d) encadrent l'agent (%d,%d), tous deux "
						+ "à portée de fuite : invariant n°13 — la nuée est repoussée de l'un vers "
						+ "l'autre et n'en sort jamais. Un seul danger par niveau peut punir une "
						+ "famille de piles ; deux l'enferment.") % [a.x, a.y, b.x, b.y, p.x, p.y])
					return

static func _in_range(a: Vector2i, b: Vector2i, range_sq: int) -> bool:
	var dx: int = a.x - b.x
	var dy: int = a.y - b.y
	return dx * dx + dy * dy <= range_sq

static func _threatens_any(d: Vector2i, positions: Array, range_sq: int) -> bool:
	for p in positions:
		if _in_range(d, p, range_sq):
			return true
	return false

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
		# LE JOKER PORTE SON ARGUMENT DANS SON NOM : `R16(X)` se lit « ignorer le
		# danger », `R16(^)` « ignorer les sens uniques », `R16(P)` « ignorer les
		# portes ». Le symbole entre parentheses est celui de la GRILLE — le joueur
		# et l'auteur de niveau designent donc la meme chose de la meme facon.
		if token.begins_with("R16(") and token.ends_with(")"):
			var symbol := token.substr(4, token.length() - 5)
			# LES SENS UNIQUES ONT LEUR PROPRE TABLE, parce qu'ils portent une
			# orientation : « ^ », « > », « v », « < » ne sont pas quatre types de
			# case mais quatre écritures du même. Le joker ne neutralise pas une
			# direction, il neutralise la CONTRAINTE — n'importe lequel des quatre
			# symboles la désigne donc, et désigne la même chose.
			var cell_type: int = -1
			if _SYMBOLS.has(symbol):
				cell_type = _SYMBOLS[symbol]
			elif symbol in _ONE_WAY_SYMBOLS:
				cell_type = GridState.CellType.ONE_WAY
			else:
				errors.append("allowed_rules : R16(%s) — symbole de case inconnu" % symbol)
				continue
			if cell_type == GridState.CellType.WALL:
				errors.append(("allowed_rules : R16(#) — le mur n'est jamais ignorable. "
					+ "Un joker qui annule la geometrie ouvre tous les niveaux d'un coup."))
				continue
			var joker := RuleRegistry.make_joker(cell_type)
			if out.has(joker):
				errors.append("allowed_rules : R16(%s) en double" % symbol)
				continue
			out.append(joker)
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
## `door: required=2 plates=1,4;2,4 panels=5,6;6,6`
##
## Les CASES DE COMMANDE ne sont pas un symbole de grille, et c'est délibéré :
## le vocabulaire de RG-14 est fermé à neuf éléments, et lui en ajouter un
## dixième pour un détail de représentation serait exactement l'inflation que
## cette clôture interdit. Une commande est une case ordinaire que la ligne
## `door:` rattache à sa porte.
static func _parse_door(value: String, line: int, errors: PackedStringArray) -> Dictionary:
	var out: Dictionary = {"required": 1, "plates": [], "panels": []}
	for token in value.split(" "):
		var t := String(token).strip_edges()
		if t.is_empty():
			continue
		if t.begins_with("required="):
			# ZÉRO EST DÉSORMAIS UNE VALEUR, pas une faute de frappe à corriger : il
			# déclare une porte que seule une bascule ouvre. Le plancher à 1 la
			# rendait inexprimable.
			out["required"] = maxi(0, int(t.substr(9)))
		elif t.begins_with("plates=") or t.begins_with("panels="):
			var key := "plates" if t.begins_with("plates=") else "panels"
			var list: Array = []
			for pair in t.substr(t.find("=") + 1).split(";"):
				var xy := String(pair).split(",")
				if xy.size() != 2:
					errors.append("ligne %d : « %s » n'est pas un couple x,y" % [line, pair])
					continue
				list.append([int(xy[0]), int(xy[1])])
			out[key] = list
		else:
			errors.append("ligne %d : jeton de porte inconnu « %s »" % [line, t])
	# UNE PORTE COMMANDÉE PAR BASCULE N'A PAS DE PLAQUE, et c'est légitime depuis
	# que la bascule existe : `required=0` la déclare. Sans ce cas, la seule façon
	# d'écrire une porte à bascule était de mentir sur ses plaques.
	var switch_only: bool = int(out["required"]) <= 0
	if (out["panels"] as Array).is_empty():
		errors.append(("ligne %d : une porte a besoin d'au moins un panneau — sans quoi "
			+ "elle n'est ni ouvrable ni fermante") % line)
		return {}
	if not switch_only and (out["plates"] as Array).is_empty():
		errors.append(("ligne %d : une porte à plaques a besoin d'au moins une commande. "
			+ "Pour une porte commandée uniquement par bascule, écrire `required=0`") % line)
		return {}
	if not switch_only and int(out["required"]) > (out["plates"] as Array).size():
		errors.append(("ligne %d : %d agents requis pour %d case(s) de commande — la porte "
			+ "ne pourrait JAMAIS s'ouvrir") % [line, int(out["required"]), (out["plates"] as Array).size()])
		return {}
	return out

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

## `patrol: 3,5;4,5;5,5;4,5` — un trajet fermé, une case par tick.
##
## LE TRAJET SE DÉCRIT EN ENTIER, aller ET retour. Un « va-et-vient » déduit
## serait plus court à écrire et laisserait une ambiguïté qui coûte cher : la
## case de demi-tour est-elle occupée une fois ou deux ? La réponse change la
## période, donc tous les temps de passage du niveau — et un paramètre calibré
## sur une période fausse est faux (invariant n°15).
static func _parse_patrol(value: String, line: int,
		errors: PackedStringArray) -> Array:
	var path: Array = []
	for pair in value.split(";"):
		var text := String(pair).strip_edges()
		if text.is_empty():
			continue
		var xy := text.split(",")
		if xy.size() != 2:
			errors.append("ligne %d : « %s » n'est pas un couple x,y" % [line, text])
			return []
		path.append([int(xy[0]), int(xy[1])])
	if path.size() < 2:
		errors.append(("ligne %d : une patrouille a besoin d'au moins deux cases — "
			+ "à une seule elle ne se déplace pas, et c'est un danger statique") % line)
		return []
	return path
