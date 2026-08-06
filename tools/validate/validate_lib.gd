class_name ValidateLib
extends RefCounted
## Cœur du validateur v1 (T-024, DCT §8) : simule chaque pile de l'espace
## énuméré avec LE MÊME code que le jeu (DT-15 — SimCore, jamais une
## réimplémentation) et produit un rapport.
##
## Coupes sûres (DT-16 étage 2) :
## — arrêt dès que `outcome` quitte RUNNING ;
## — détection de cycle : si le couple (empreinte de dynamique, tick modulo
##   ppcm des périodes) se répète, la simulation boucle — les compteurs ne
##   progresseront plus jamais, l'issue est un échec anticipé.

## Plancher de période des dangers cycliques ⚙️ (revue S3) : en dessous,
## l'oscillation d'une nuée se lit comme un tremblement, pas comme un
## avance/recul. Surchargeable depuis data/rules.json ("validation").
const MIN_CYCLE_PERIOD_DEFAULT := 6

## Identifiants des règles de transport du chapitre 4 (pas encore dans
## RuleRegistry) : nécessaires pour que `delivered` puisse progresser.
const R11_CARRY := 11
const R12_DROP := 12

## Détection du sur-place perpétuel (6 août 2026). Un agent peut rester
## bloqué dans un cycle court — typiquement un aller-retour de période 2 sur
## la frontière de portée de R02 : à d² <= portée la règle le repousse, à
## d² > portée elle s'abstient et R01 le ramène. C'est un cycle limite
## structurel (répulseur à seuil + attracteur), pas un défaut de réglage.
##
## Le niveau reste GAGNABLE quand les autres agents sortent — la coupe de
## boucle (DT-16) ne le voit donc pas — mais le joueur, lui, y voit un bug.
## D'où cette mesure à part : « aucune pile gagnante ne doit laisser un agent
## osciller » est un critère de conception vérifiable à l'écriture du niveau.
const OSCILLATION_WINDOW := 12
const MAX_OSCILLATION_PERIOD := 6

## Simule une pile jusqu'à l'issue, la limite de ticks du niveau, ou une
## boucle détectée. Renvoie : outcome, ticks, exited, lost, final_hash,
## looped.
static func simulate_stack(level_data: Dictionary, params: RuleParams, stack: Array[int]) -> Dictionary:
	var state := SimCore.load_level(level_data, params)
	var tick_cap: int = state.max_ticks if state.max_ticks > 0 else 300
	var modulus: int = _cycle_modulus(state)
	var seen: Dictionary = {}

	# Fenêtre glissante des dernières positions, par agent.
	var history: Array = []
	for agent in state.agents:
		history.append([agent.pos])

	var looped := false
	while state.outcome == SimState.Outcome.RUNNING and state.tick < tick_cap:
		state = SimCore.step(state, stack)
		for i in range(state.agents.size()):
			var h: Array = history[i]
			h.append(state.agents[i].pos)
			if h.size() > OSCILLATION_WINDOW:
				h.pop_front()
		if state.outcome != SimState.Outcome.RUNNING:
			break
		var key := "%d:%s" % [state.tick % modulus, StateHash.to_hex(StateHash.dynamics_hash(state))]
		if seen.has(key):
			looped = true
			break
		seen[key] = true

	var outcome: int = state.outcome
	if looped:
		outcome = SimState.Outcome.LOST  # boucle = objectif à jamais hors d'atteinte

	var motion := _classify_motion(state, history, looped)

	return {
		"stack": stack.duplicate(),
		"outcome": outcome,
		"ticks": state.tick,
		"exited": state.counters.exited,
		"lost": state.counters.lost,
		"final_hash": StateHash.to_hex(SimCore.hash_state(state)),
		"equivalence_key": equivalence_key(state),
		"looped": looped,
		"oscillating": motion["oscillating"],
		"stuck": motion["stuck"],
	}

## Classe les agents encore présents à la fin : combien font du sur-place
## perpétuel (cycle de période >= 2), combien sont figés (période 1).
##
## Deux chemins, parce que la simulation peut s'arrêter tôt : si la coupe de
## boucle a tranché, l'état ENTIER se répète, donc tout agent qui bouge
## encore est par définition dans un cycle — inutile d'attendre une fenêtre
## pleine. Sinon, on cherche une périodicité dans la fenêtre glissante.
static func _classify_motion(state: SimState, history: Array, looped: bool) -> Dictionary:
	var oscillating := 0
	var stuck := 0
	for i in range(state.agents.size()):
		if not state.agents[i].is_present():
			continue
		var positions: Array = history[i]
		var period := 0
		if looped:
			period = 1 if _all_equal(positions) else 2
		else:
			period = _cycle_period(positions)
		if period == 1:
			stuck += 1
		elif period >= 2:
			oscillating += 1
	return {"oscillating": oscillating, "stuck": stuck}

static func _all_equal(positions: Array) -> bool:
	for i in range(1, positions.size()):
		if positions[i] != positions[0]:
			return false
	return true

## Plus petite période qui explique toute la fenêtre, ou 0 si aucune.
static func _cycle_period(positions: Array) -> int:
	var n: int = positions.size()
	if n < OSCILLATION_WINDOW:
		return 0
	for p in range(1, MAX_OSCILLATION_PERIOD + 1):
		var periodic := true
		for i in range(n - p):
			if positions[i] != positions[i + p]:
				periodic = false
				break
		if periodic:
			return p
	return 0

## Clé d'ÉQUIVALENCE d'une issue — à ne jamais confondre avec son IDENTITÉ.
##
##   Identité (StateHash.hash_state, core/sim) : inclut les identifiants
##     d'agents, sert au déterminisme et aux tests d'or, et n'en bougera pas.
##   Équivalence (ici, tools/) : les agents sont anonymes et interchangeables
##     (RG-04), donc deux issues qui ne diffèrent que par l'attribution des
##     identifiants sont LA MÊME solution. QN-01 exclut explicitement les
##     « variantes triviales » : les compter séparément gonflerait le chiffre
##     même qui sert de critère, et celui qu'affiche le bilan de fin de niveau.
##
## Invariant : multiensemble trié des (pos, dir, flags) + compteurs. Le tick
## n'en fait pas partie — l'efficience se mesure à part (min_ticks, QN-04).
static func equivalence_key(state: SimState) -> String:
	var parts := PackedStringArray()
	for agent in state.agents:
		parts.append("%d,%d,%d,%d" % [agent.pos.x, agent.pos.y, agent.dir, agent.flags])
	parts.sort()  # multiensemble : l'ordre des identifiants ne doit rien changer
	return "%s|%d,%d,%d" % [
		";".join(parts), state.counters.exited, state.counters.lost, state.counters.delivered]

## Module de répétition temporelle : ppcm des périodes des dangers
## cycliques (1 sans cycle). Deux états de même dynamique ne sont vraiment
## équivalents que si les cycles sont dans la même phase — d'où la clé
## (tick mod ppcm, empreinte de dynamique).
static func _cycle_modulus(state: SimState) -> int:
	var m := 1
	for cycle in state.grid.cycles:
		if cycle.period > 0:
			@warning_ignore("integer_division")
			var reduced: int = m / _gcd(m, cycle.period)  # division exacte (par le pgcd)
			m = reduced * cycle.period
	return m

static func _gcd(a: int, b: int) -> int:
	var x := a
	var y := b
	while y != 0:
		var t := y
		y = x % y
		x = t
	return x

## Valide un niveau entier : contrôles structurels, puis énumération des
## piles autorisées, simulation de chacune, agrégation. Renvoie
## { rows, summary }.
static func validate_level(level_data: Dictionary, params: RuleParams, min_cycle_period: int = MIN_CYCLE_PERIOD_DEFAULT) -> Dictionary:
	var allowed: Array[int] = []
	for v in level_data.get("allowed_rules", []):
		allowed.append(int(v))

	# Emplacements offerts par le niveau (CDC §12.2.1) : borne l'énumération.
	# Sans clé `slots`, comportement historique (4, plafond RG-05).
	var slots := clampi(int(level_data.get("slots", StackEnumerator.MAX_SLOTS)), 1, StackEnumerator.MAX_SLOTS)

	# Contrôles structurels — avant toute énumération (revue S3).
	var structural_errors: Array[String] = []
	var grid_data: Dictionary = level_data.get("grid", {})
	var cycles_arr: Array = grid_data.get("cycles", [])
	for i in range(cycles_arr.size()):
		var period := int(cycles_arr[i].get("period", 1))
		if period < min_cycle_period:
			structural_errors.append(
				"cycle %d : période %d < plancher %d ⚙️ (l'oscillation doit se lire comme un avance/recul, pas un tremblement)" % [i, period, min_cycle_period])
	if not structural_errors.is_empty():
		return {
			"rows": [],
			"summary": {
				"n_stacks": 0,
				"expected_stacks": StackEnumerator.expected_count(allowed.size(), slots),
				"n_win": 0,
				"n_win_classes": 0,
				"min_ticks": -1,
				"best_stack": [],
				"structural_errors": structural_errors,
				"qn01_verdict": "REJETÉ : structure invalide — " + " ; ".join(structural_errors),
			},
		}

	var stacks := StackEnumerator.enumerate(allowed, slots)
	var rows: Array = []
	var wins: Array = []
	for stack_variant in stacks:
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		var row := simulate_stack(level_data, params, stack)
		rows.append(row)
		if row["outcome"] == SimState.Outcome.WON:
			wins.append(row)

	# Classes structurelles : piles gagnantes regroupées par clé d'ÉQUIVALENCE
	# (DCT §8.2), pas par empreinte — voir equivalence_key : deux issues qui
	# ne diffèrent que par l'attribution des identifiants d'agents sont la
	# même solution (RG-04, et QN-01 « hors variantes triviales »).
	var classes: Dictionary = {}
	for w in wins:
		var key: String = w["equivalence_key"]
		if not classes.has(key):
			classes[key] = 0
		classes[key] += 1

	var min_ticks := -1
	var best_stack: Array = []
	for w in wins:
		if min_ticks == -1 or int(w["ticks"]) < min_ticks:
			min_ticks = int(w["ticks"])
			best_stack = w["stack"]

	# Collecte hors chapitre (revue S3, 3.6) : distinguer « inatteignable
	# faute de règles de transport autorisées » de « niveau cassé » — sans
	# cela, l'authoring du chapitre 4 serait pénible.
	var has_collect := false
	for entry in level_data.get("objectives", []):
		if String(entry.get("type", "")) == "collect":
			has_collect = true
	var collect_out_of_chapter: bool = has_collect \
		and not (allowed.has(R11_CARRY) and allowed.has(R12_DROP))

	# Garde-fou universel (CDC §12.2.1) : si la pile vide gagne, le niveau
	# se résout sans poser une seule règle — dégénéré, quel que soit le type.
	var empty_stack_wins := false
	for row in rows:
		if (row["stack"] as Array).is_empty() and row["outcome"] == SimState.Outcome.WON:
			empty_stack_wins = true

	# Métadonnées tutorielles (CDC §12.2.1) : transportées par le format et
	# rapportées SANS verdict QN-01 — les bandes proportionnelles restent
	# indicatives tant que T-040 n'est pas clos.
	var tutorial := bool(level_data.get("tutorial", false))
	var has_expected: bool = level_data.has("expected_wins")
	var expected_wins := int(level_data.get("expected_wins", -1))
	# Arbitrage du 6 août 2026 : expected_wins compte des PILES (convention
	# de l'outil) ; expected_classes, optionnel, compte des classes
	# structurelles — les deux sont confrontés et rapportés.
	var expected_classes := int(level_data.get("expected_classes", -1))

	# Sur-place perpétuel parmi les piles GAGNANTES : le niveau est jouable et
	# paraît cassé. Rapporté, jamais bloquant — c'est au concepteur de juger.
	var wins_with_oscillation := 0
	var max_oscillating := 0
	for w in wins:
		if int(w["oscillating"]) > 0:
			wins_with_oscillation += 1
			max_oscillating = maxi(max_oscillating, int(w["oscillating"]))

	var n_classes: int = classes.size()
	var verdict: String
	if empty_stack_wins:
		verdict = "REJETÉ : dégénéré (la pile vide gagne — le niveau se résout sans poser une seule règle)"
	elif wins.is_empty():
		verdict = "REJETÉ : insoluble (zéro pile gagnante)"
		if collect_out_of_chapter:
			verdict += " — collecte hors chapitre : R11/R12 non autorisées (attendu tant que le chapitre 4 n'existe pas, pas un niveau cassé)"
	elif tutorial or has_expected:
		if has_expected:
			var gap := "" if wins.size() == expected_wins else " — ÉCART À LA FICHE"
			verdict = "SANS VERDICT QN-01 (CDC §12.2.1) — attendu %d, constaté %d%s" % [expected_wins, wins.size(), gap]
			if expected_classes >= 0:
				var class_gap := "" if n_classes == expected_classes else " — ÉCART"
				verdict += " ; classes : attendu %d, constaté %d%s" % [expected_classes, n_classes, class_gap]
		else:
			verdict = "SANS VERDICT QN-01 (CDC §12.2.1) — %d gagnante(s) sur %d" % [wins.size(), rows.size()]
	elif n_classes == 1:
		verdict = "REJETÉ : puzzle déguisé (une seule classe de solution)"
	elif n_classes < 3:
		verdict = "SOUS LE SEUIL QN-01 (classes < 3) : à retravailler"
	elif n_classes > 40:
		verdict = "AU-DESSUS DU SEUIL QN-01 (classes > 40) : niveau creux, à durcir"
	else:
		verdict = "CONFORME QN-01 (3 <= classes <= 40)"

	if wins_with_oscillation > 0:
		verdict += "   ⚠ %d pile(s) gagnante(s) laissent jusqu'à %d agent(s) faire du sur-place perpétuel : le joueur y verra un bug" % [
			wins_with_oscillation, max_oscillating]

	@warning_ignore("integer_division")
	var win_ratio_percent: int = wins.size() * 100 / rows.size() if rows.size() > 0 else 0

	return {
		"rows": rows,
		"summary": {
			"n_stacks": rows.size(),
			"n_total": rows.size(),
			"expected_stacks": StackEnumerator.expected_count(allowed.size(), slots),
			"slots": slots,
			"n_win": wins.size(),
			"n_win_classes": n_classes,
			"win_ratio_percent": win_ratio_percent,
			"min_ticks": min_ticks,
			"best_stack": best_stack,
			"tutorial": tutorial,
			"expected_wins": expected_wins,
			"expected_classes": expected_classes,
			"structural_errors": [],
			"collect_out_of_chapter": collect_out_of_chapter,
			"wins_with_oscillation": wins_with_oscillation,
			"max_oscillating_agents": max_oscillating,
			"qn01_verdict": verdict,
		},
	}
