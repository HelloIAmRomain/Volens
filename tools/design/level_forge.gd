extends SceneTree
## LA FORGE — on énumère des géométries, on les MESURE, on garde les conformes.
##
## POURQUOI ELLE EXISTE. Écrire un niveau à la main, c'est décider de sa
## géométrie AVANT de pouvoir voir son espace de solutions — on ne le découvre
## qu'après, en le jouant. Cinq géométries de bouclier ont été jetées pour cette
## seule raison, trois refontes de ch2_05 aussi, et vingt-deux niveaux sur
## trente-deux n'avaient qu'UNE pile gagnante sans que personne l'ait voulu. La
## forge inverse l'ordre : elle produit la carte, l'interroge, et ne présente
## que ce qui a répondu.
##
## ## C'est le VALIDATEUR qui juge, pas la forge
##
## Le verdict de conformité vient de `ValidateLib.validate_level`, celui-là même
## qui décide en ligne de commande — jamais d'un second calcul. Une forge qui
## aurait sa propre idée du « bon niveau » produirait des cartes que le
## validateur refuserait ensuite, et on passerait le temps gagné à arbitrer
## entre deux outils. C'est l'esprit de DT-15 : une seule implémentation.
##
## Elle en tire ses trois VETOS, tous des motifs de refus du CDC :
##
##   1. **QN-01** — hors de `3 ≤ classes ≤ 40`, la carte est soit un puzzle
##      déguisé (une seule façon de gagner, déguisée en plusieurs piles), soit
##      un niveau creux où presque tout passe.
##   2. **Sur-place perpétuel** — « le joueur y verra un bug ». Une pile
##      gagnante qui laisse des agents osciller pour toujours disqualifie la
##      carte, quelle que soit sa variété.
##   3. **Solution trop courte** — une carte que `[R01]` seule résout n'enseigne
##      rien : c'était la cause mécanique des vingt-deux solutions uniques.
##
## ## Ce qu'elle RÉCOMPENSE, et pourquoi ce ne sont pas les mêmes critères
##
## Les vetos disent « jouable » ; le score dit « intéressant », et c'est là que
## passent les remarques accumulées à l'essai :
##
##   · **des associations de règles NEUVES** — une paire qui ne gagne ensemble
##     nulle part dans le catalogue actuel vaut plus que dix familles déjà vues.
##     C'est la réponse directe à « une règle ne fonctionne qu'avec certaines
##     règles ; tout doit au plus possible aller avec tout » ;
##   · **une signature inédite** — un jeu de règles qui gagne déjà un autre
##     niveau est refusé d'office : le joueur récitait `[8,9]` sur trois niveaux
##     du chapitre 3 ;
##   · **aucun monopole** — une règle présente dans toutes les gagnantes n'est
##     pas un choix, c'est un péage ;
##   · **deux défis séparables** — économie ET abstinence possibles, donc deux
##     recherches distinctes plutôt qu'un écran qui s'allume d'un coup.
##
## ## Trois garde-fous, et ils sont la condition de l'exercice
##
## 1. **AUCUN TIRAGE ALÉATOIRE, nulle part.** Le balayage est un produit
##    cartésien parcouru dans un ordre fixe. Deux exécutions donnent la même
##    liste, donc la liste se discute.
##
## 2. **ON GÉNÈRE DANS L'IDIOME** — la lumière est DERRIÈRE le mur, la sortie
##    est l'OUVERTURE de ce mur. C'est ce qui donne l'entonnoir gratuitement, et
##    ce qui fait qu'une carte forgée ressemble aux autres.
##
##    **MAIS PAS TOUJOURS DANS LE MÊME SENS.** La carte canonique est ensuite
##    pivotée d'un quart, d'un demi ou de trois quarts de tour — la sortie passe
##    au Nord, à l'Est, au Sud ou à l'Ouest. Ce n'est pas cosmétique :
##    l'invariant n°19 dit qu'à égalité toute règle préfère le Nord puis l'Est,
##    donc **une carte pivotée n'est PAS la même carte**, et le miroir de N9 —
##    construit et mesuré — ne se résout pas. Chaque orientation est donc
##    évaluée séparément, comme un niveau distinct qu'elle est.
##
## 3. **LA SORTIE EST DU `.lvl`, jamais du JSON.** Le convertisseur porte les
##    contrôles G1 à G3 et calcule `calibrated_on`. Émettre du JSON
##    contournerait précisément les garde-fous écrits pour ce genre de carte.
##    Mieux : la forge APPELLE le parseur pour évaluer, donc toute géométrie
##    qu'il refuserait est éliminée avant d'être simulée.
##
## ## Ce qu'elle ne fait PAS, et ne fera pas
##
## **Elle ne pose aucune piste.** R09 y serait ingénérable : une piste tronquée
## est structurellement impossible (l'agent arrivé au sommet voit la trace
## derrière lui plus forte que sa case vierge et redescend — pathologie P3,
## mesurée sur ch3_04), et une piste complète rend le niveau trivial. Le tracé
## d'un détour est une intention, pas un paramètre.
##
## **Elle ne remplace pas le jugement.** Elle classe des candidats ; la leçon du
## niveau, sa fiche et son nom restent une décision humaine. Une carte qui
## mesure bien et ne raconte rien n'est pas un niveau.
##
## ## Usage
##
##   godot --headless --path . --script res://tools/design/level_forge.gd -- \
##       --rules=R01,R02,R04,R13 --slots=3 --want=R13 \
##       "--objective=extraction:85;preservation:3" --max=400 --top=5
##
## ## Les paramètres, et ce que chacun décide
##
## **Ce que le joueur reçoit**
##   `--rules=R01,R04,R06`   la bibliothèque offerte. La forge la RESSERRE
##                           ensuite à ce qui porte : c'est un point de départ,
##                           pas un contrat.
##   `--slots=3`             le nombre de rangs de la pile.
##   `--objective=…`         `extraction:85;preservation:3` — plusieurs objectifs
##                           séparés par « ; ».
##
## **Ce qu'on pose sur la carte**
##   `--band=none,one_gap,two_gaps,split`
##                           la paroi médiane. `two_gaps` ouvre deux passages
##                           équidistants de la sortie (deux routes de coût
##                           comparable) ; `split` en pose un À L'APLOMB de la
##                           nuée et l'autre à l'opposé (raccourci contre
##                           détour).
##   `--plug=true,false`     un danger dans le goulot.
##   `--station=none,left,right,under`
##                           un atelier à boucliers, posé À L'ÉCART du goulot :
##                           sous l'entonnoir il couvre tout le monde et la carte
##                           redevient triviale (décision 191).
##   `--face=N,E,S,O`        l'orientation. Une carte pivotée n'est PAS la même
##                           carte (invariant n°19).
##
## **Ce qu'on exige du résultat**
##   `--want=R13`            règles qui doivent PORTER une gagnante.
##   `--min-sets` `--max-sets`  bornes sur le nombre de familles.
##   `--min-len=2`           longueur minimale de la plus courte gagnante.
##
## **Ce qu'on dépense**
##   `--max=1200`            budget de géométries évaluées.
##   `--top=5`              combien de candidats écrire.
##   `--probe-ticks=100`     plafond de ticks PENDANT la recherche.
##   `--out=reports/forge/x` où écrire.
##
## LES COMBINAISONS INCOHÉRENTES SONT ÉCARTÉES AVANT GÉNÉRATION : un goulot
## bouché sans R13 ni atelier ferme la carte, un atelier sans danger ne protège
## de rien. C'est ce contrôle qui aurait évité les 1 054 candidats morts des
## balayages « bouclier ».

const OUT_DEFAULT := "res://reports/forge"
## Cache des signatures du catalogue. Le calculer coûte plusieurs minutes ; le
## refaire à chaque exécution de la forge ferait renoncer à s'en servir.
const CACHE := "res://reports/forge/catalogue.json"

var _params: RuleParams
var _min_period := 6
var _flee_sq := 25

# --- le brief -----------------------------------------------------------------
var _rules: Array[int] = []
var _slots := 3
var _want: Array[int] = []
var _objective := "extraction 100"
var _max_candidates := 400
var _min_sets := 2
var _max_sets := 8
var _min_len := 2
var _top := 5
var _out := OUT_DEFAULT
var _faces: Array[int] = []
## PLAFOND DE TICKS PENDANT LA RECHERCHE — et c'est le premier poste de coût.
##
## Chaque pile PERDANTE tourne jusqu'au plafond, et la plupart des piles
## perdent : sur 156 piles, une dizaine gagnent. Chercher à 300 ticks revenait à
## payer 300 ticks pour chaque échec, alors que les cartes de l'idiome se
## gagnent en 20 à 60 et que `max_ticks` est de toute façon RECALIBRÉ à
## l'émission (le double du meilleur temps).
##
## Un plafond de recherche plus bas ne fausse donc rien : il écarte les piles
## qui n'auraient pas tenu l'échéance finale de toute façon. Le relever ne sert
## que si l'on cherche une carte volontairement longue.
var _probe_ticks := 100
var _bands: Array[String] = []
var _plugs: Array[bool] = []
var _stations: Array[String] = []

# --- ce que le catalogue occupe DÉJÀ ------------------------------------------
var _known_sets: Dictionary = {}      # "[1, 9]" -> true
var _known_pairs: Dictionary = {}     # "1-9"    -> true

func _init() -> void:
	_read_brief()
	var rules_json: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/rules.json"))
	var rules_data: Dictionary = rules_json if rules_json is Dictionary else {}
	_params = RuleParams.from_dict(rules_data)
	var validation: Dictionary = rules_data.get("validation", {})
	_min_period = int(validation.get("min_cycle_period", 6))
	_flee_sq = int((rules_data.get("fuir_le_rouge", {}) as Dictionary).get(
		"perception_range_sq", 25))

	if _rules.is_empty():
		print("Brief vide : --rules=R01,R04,… est obligatoire.")
		quit(2)
		return

	_load_catalogue()
	print("FORGE — bibliothèque %s, %d rangs, objectif « %s »"
		% [_names(_rules), _slots, _objective])
	if not _want.is_empty():
		print("        règles exigées porteuses : %s" % _names(_want))
	print("        le catalogue occupe déjà %d signatures et %d associations"
		% [_known_sets.size(), _known_pairs.size()])

	var kept: Array = []
	var reasons: Dictionary = {}
	var seen := 0
	for shape in _shapes():
		if seen >= _max_candidates:
			break
		var text: String = _render(shape, _probe_ticks)
		if text.is_empty():
			continue   # gabarit impossible : ne consomme pas le budget
		seen += 1
		var parsed := LvlParser.parse(text, _min_period, _flee_sq)
		var errors: PackedStringArray = parsed["errors"]
		if not errors.is_empty():
			_tally(reasons, "convertisseur : " + errors[0].get_slice(":", 0))
			continue
		# --- FILTRES À COÛT NUL, AVANT TOUTE SIMULATION ----------------------
		#
		# Le balayage passait l'essentiel de son temps à énumérer l'espace des
		# piles de cartes qui n'avaient AUCUNE chance : sur 1 500 géométries,
		# 700 à 1 400 sans une seule gagnante et 260 gagnées en une règle. Chacune
		# coûtait 156 simulations complètes pour un verdict qu'un parcours de
		# grille ou trois simulations donnent.
		var level: Dictionary = parsed["level"]
		# ASSEZ D'AGENTS PEUVENT-ILS SEULEMENT ARRIVER ?
		#
		# Le parcours rend le nombre d'agents dont la composante contient la
		# sortie. Une bande médiane en mure régulièrement une partie : ceux-là ne
		# sortiront jamais, quelle que soit la pile. Si le compte tombe sous ce
		# que l'objectif d'extraction exige, la carte est perdue d'avance — et
		# c'est SÛR, pas une heuristique.
		var can_arrive := _agents_that_can_reach_exit(level)
		if can_arrive < _required_exits(level):
			_tally(reasons, "%d agents peuvent atteindre la sortie, %d exigés"
				% [can_arrive, _required_exits(level)])
			continue
		# TOUTE ROUTE PASSE PAR UN DANGER, ET RIEN NE PEUT LE NEUTRALISER.
		#
		# C'est le motif qui a coûté le plus cher : les balayages « bouclier »
		# ont produit 1 054 candidats sur 1 200 sans une seule gagnante, tous de
		# cette forme. Chacun payait 156 simulations pour apprendre ce qu'un
		# second parcours de grille dit en quelques microsecondes.
		#
		# LE RAISONNEMENT EST SOUND : si la sortie est inatteignable en évitant
		# les dangers, alors TOUT agent qui sort en a traversé un. Sans R13 pour
		# le boucher ni atelier pour l'encaisser, chacun y meurt — donc autant de
		# pertes que d'agents sortis, ce qu'aucun budget de préservation
		# raisonnable ne couvre. On ne rejette que dans ce cas-là.
		if not _exit_is_reachable(level, true) and not _can_survive_a_danger(level):
			_tally(reasons, "toute route traverse un danger que rien ne neutralise")
			continue
		# UNE RÈGLE SEULE QUI GAGNE SUFFIT À CONDAMNER LA CARTE, et le savoir
		# coûte autant de simulations qu'il y a de règles — jamais 156.
		var trivial := _shortest_winner_length(level)
		if trivial > 0 and trivial < _min_len:
			_tally(reasons, "gagnée en %d règle(s) : trop courte" % trivial)
			continue

		var verdict := _judge(level, reasons)
		if int(verdict["score"]) <= 0:
			continue
		verdict["shape"] = shape
		kept.append(verdict)

	kept.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(a["score"]) > int(b["score"]))

	print("\n%d géométries balayées, %d retenues." % [seen, kept.size()])
	var keys: Array = reasons.keys()
	keys.sort()
	for reason in keys:
		print("    écarté × %-4d %s" % [int(reasons[reason]), String(reason)])
	_emit(kept, reasons)
	quit()

## --- Le jugement -------------------------------------------------------------
##
## Les VETOS d'abord, dans l'ordre du moins cher au plus cher à expliquer : un
## candidat écarté doit dire POURQUOI, sinon « 400 balayées, 0 retenue » ne
## renseigne sur rien et on corrige le gabarit au hasard.
func _judge(data: Dictionary, reasons: Dictionary) -> Dictionary:
	var report := ValidateLib.validate_level(data, _params, _min_period)
	var summary: Dictionary = report["summary"]
	var classes := int(summary["n_win_classes"])

	if classes == 0:
		_tally(reasons, "aucune pile gagnante")
		return {"score": 0}
	# VETO 1 — QN-01. Le seuil n'est pas de la forge : c'est le CDC, et c'est le
	# validateur qui l'applique en ligne de commande sur les mêmes chiffres.
	if classes < 3:
		_tally(reasons, "QN-01 : %d classe(s), puzzle déguisé" % classes)
		return {"score": 0}
	if classes > 40:
		_tally(reasons, "QN-01 : %d classes, niveau creux" % classes)
		return {"score": 0}
	# VETO 2 — « le joueur y verra un bug ». Motif qui a fait rejeter la
	# troisième refonte de ch2_05, et il vaut pour toute carte.
	if int(summary["wins_with_oscillation"]) > 0:
		_tally(reasons, "sur-place perpétuel dans une pile gagnante")
		return {"score": 0}

	# LES GAGNANTES SE LISENT DANS LE RAPPORT, elles ne se recalculent pas. Le
	# validateur vient de simuler tout l'espace des piles ; réénumérer derrière
	# lui doublait le coût de chaque candidat, et surtout entretenait une
	# SECONDE implémentation de « qui gagne » — le genre de doublon qui finit par
	# diverger et par faire mentir l'outil sur ses propres résultats.
	var minimal := _minimal_from_rows(report["rows"])
	var shortest := 99
	var sets: Dictionary = {}
	var borne: Dictionary = {}
	for stack in minimal:
		shortest = mini(shortest, (stack as Array).size())
		var s := _bases(stack)
		s.sort()
		sets[str(s)] = true
		for r in s:
			borne[r] = true
	# VETO 3 — une carte que deux règles ne suffisent pas à décrire.
	if shortest < _min_len:
		_tally(reasons, "gagnée en %d règle(s) : trop courte" % shortest)
		return {"score": 0}
	if sets.size() < _min_sets or sets.size() > _max_sets:
		_tally(reasons, "%d famille(s), hors des bornes demandées" % sets.size())
		return {"score": 0}
	for r in _want:
		if not borne.has(r):
			_tally(reasons, "R%02d ne porte aucune gagnante" % r)
			return {"score": 0}
	# VETO 4 — LA SIGNATURE EST DÉJÀ SERVIE. Un jeu de règles qui gagne déjà un
	# autre niveau ne pose pas une question neuve : le joueur récite. Automatique
	# ici, alors qu'il fallait auparavant le lister à la main.
	var reused := PackedStringArray()
	for key in sets:
		if _known_sets.has(key):
			reused.append(String(key))
	if reused.size() == sets.size():
		_tally(reasons, "toutes les familles existent déjà ailleurs")
		return {"score": 0}

	# --- récompenses ---------------------------------------------------------
	var score := 0
	var why := PackedStringArray()

	# LES ASSOCIATIONS NEUVES PÈSENT LE PLUS LOURD, et c'est délibéré : c'est la
	# seule mesure qui répond à « je veux des règles qui combinent bien avec
	# certaines dans un niveau et avec d'autres ailleurs ». Une famille de plus
	# ne vaut rien si elle réunit les mêmes règles que partout.
	var fresh_pairs := PackedStringArray()
	for key in sets:
		var ids := _ids_of(String(key))
		for i in range(ids.size()):
			for j in range(i + 1, ids.size()):
				var pair := "%d-%d" % [ids[i], ids[j]]
				if not _known_pairs.has(pair) and not fresh_pairs.has(pair):
					fresh_pairs.append(pair)
	score += fresh_pairs.size() * 30
	if not fresh_pairs.is_empty():
		why.append("%d association(s) inédite(s)" % fresh_pairs.size())

	score += (sets.size() - reused.size()) * 12
	why.append("%d famille(s) dont %d inédite(s)"
		% [sets.size(), sets.size() - reused.size()])

	# QN-01 est un intervalle, pas un maximum : on récompense d'être DEDANS, pas
	# d'aller vers le haut. Quarante classes n'est pas mieux que quatre.
	score += 20
	why.append("%d classes (QN-01)" % classes)

	var monopolies := _monopolies(minimal)
	if monopolies.is_empty():
		score += 25
		why.append("aucun monopole")
	else:
		score -= monopolies.size() * 8
		why.append("monopole %s" % _names(monopolies))

	# DEUX DÉFIS SÉPARABLES. « Les défis ne devraient pas être réalisés en un
	# coup » : il en faut deux que des piles DIFFÉRENTES obtiennent.
	if bool(summary["challenge_economy_possible"]) \
			and not (summary["challenge_abstinence_options"] as Array).is_empty():
		score += 15
		why.append("économie + abstinence")

	score += borne.size() * 4

	# L'ORDRE DOIT SE VOIR — c'est le jeu, pas un détail.
	#
	# RG-13 : deux règles dont les zones d'action ne se recouvrent jamais sur
	# cette carte forment une paire à l'ordre INOBSERVABLE. Les permuter ne
	# change rien, et le joueur qui essaie apprend que l'ordre ne compte pas —
	# exactement le contraire de ce que Volens enseigne. Le validateur les
	# comptait déjà ; la forge les ignorait.
	#
	# On récompense donc les cartes où les règles SE DISPUTENT la décision, et
	# l'on pénalise chaque paire aveugle. C'est la mesure la plus proche de
	# « intérêt de jeu » que l'outillage sache produire.
	var blind: int = (summary["blind_pairs"] as PackedStringArray).size()
	var contested := 0
	for key in (summary["contention_by_pair"] as Dictionary):
		if int((summary["contention_by_pair"] as Dictionary)[key]) > 0:
			contested += 1
	score += contested * 6 - blind * 4
	why.append("%d paire(s) en dispute, %d aveugle(s)" % [contested, blind])

	# LES ÉCHECS DOIVENT ÊTRE PROCHES (QN-03). Une pile qui échoue de peu donne
	# envie de recommencer ; une pile qui échoue de loin décourage. Une carte
	# dont AUCUN échec n'approche du but ne se laisse pas explorer : on y gagne
	# ou l'on n'y comprend rien.
	if int(summary["n_near_misses"]) > 0:
		score += 10
		why.append("%d échec(s) proche(s)" % int(summary["n_near_misses"]))

	var names := PackedStringArray()
	for key in sets:
		names.append(String(key))
	return {
		"score": score, "why": ", ".join(why), "families": " / ".join(names),
		"classes": classes, "fresh": fresh_pairs,
		"min_ticks": int(summary["min_ticks"]),
		"best_stack": summary["best_stack"],
		"n_win": int(summary["n_win"]),
		"verdict": String(summary["qn01_verdict"]),
		# CE QU'IL FAUT POUR ÉCRIRE UN NIVEAU FINI, et non un candidat à
		# retoucher : la bibliothèque réduite à ce qui PORTE, les compteurs que
		# la fiche doit déclarer, et l'empreinte de géométrie.
		"carriers": borne.keys(),
		"shortest": shortest,
		"abstinence": _abstinence_options(minimal),
		"geometry": String(data.get("geometry_hash", "")),
	}

## Règles qu'AU MOINS UNE gagnante minimale n'emploie pas — ce sont les seules
## sur lesquelles un défi d'abstinence a un sens. Interdire une règle qu'aucune
## solution ne peut éviter ne serait pas un défi, ce serait un mur.
func _abstinence_options(minimal: Array) -> Array:
	var out: Array = []
	var all_rules: Dictionary = {}
	for stack in minimal:
		for r in _bases(stack):
			all_rules[r] = true
	for r in all_rules:
		for stack in minimal:
			if not _bases(stack).has(r):
				out.append(r)
				break
	out.sort()
	return out

## UN FICHIER FINI, PAS UN CANDIDAT À RETOUCHER.
##
## Les trois choses qu'il fallait ajouter à la main après chaque balayage sont
## écrites ici : les compteurs que la fiche doit déclarer (`expected_wins`,
## `expected_classes`), l'empreinte de géométrie qui protège les paramètres
## calibrés (invariant n°15), et une ligne de défis.
##
## LES COMPTEURS NE SONT PAS DÉCORATIFS. Le validateur les confronte à la
## simulation : un niveau qui les déclare faux est signalé « ÉCART À LA FICHE ».
## Les recopier depuis la mesure qu'on vient de faire est la seule façon qu'ils
## soient justes le jour où le fichier est écrit.
##
## LES DEUX DÉFIS DOIVENT EXIGER DEUX PILES DIFFÉRENTES — « les défis ne
## devraient pas être réalisés en un coup ». L'économie demande la plus courte
## des gagnantes ; l'abstinence interdit une règle QUE CETTE PLUS COURTE EMPLOIE,
## ce qui force à en chercher une autre. Interdire une règle qu'aucune gagnante
## n'évite serait un mur, pas un défi : `_abstinence_options` ne rend que celles
## qu'au moins une solution sait éviter.
func _finish(shape: Dictionary, c: Dictionary, max_ticks: int,
		library: Array) -> String:
	var lines := _render(shape, max_ticks, library).split("\n")
	var out := PackedStringArray()
	for line in lines:
		if line == "---":
			out.append("expected_wins: %d" % int(c["n_win"]))
			out.append("expected_classes: %d" % int(c["classes"]))
			var geometry := String(c.get("geometry", ""))
			if not geometry.is_empty():
				out.append("calibrated_on: %s" % geometry)
			var challenge := _challenge_line(c)
			if not challenge.is_empty():
				out.append("challenge: %s" % challenge)
		out.append(line)
	return "\n".join(out)

## Deux défis au plus, et jamais deux que la même pile décroche.
func _challenge_line(c: Dictionary) -> String:
	var parts := PackedStringArray()
	var shortest := int(c.get("shortest", 0))
	var best: Array = c.get("best_stack", [])
	if shortest > 0:
		parts.append("economy=%d" % shortest)
	# On cherche une abstinence portant sur une règle de la MEILLEURE pile :
	# l'interdire écarte précisément la solution que l'économie récompense.
	var used: Dictionary = {}
	for r in best:
		used[RuleRegistry.base_rule_id(int(r))] = true
	for r in (c.get("abstinence", []) as Array):
		if used.has(int(r)):
			parts.append("abstinence=R%02d" % int(r))
			break
	return " ".join(parts)

## --- Les deux filtres qui font tout le gain ----------------------------------
##
## LA SORTIE EST-ELLE SEULEMENT ATTEIGNABLE ? Un parcours en largeur sur la
## grille, quelques centaines de cases, contre 156 simulations de 300 ticks. Il
## ne dit pas qu'un niveau est jouable — c'est un CONTRE-EXEMPLE, pas une preuve
## — mais quand il dit non, aucune pile ne peut gagner, et c'est sûr.
##
## On ignore les dangers et les portes : une porte close peut s'ouvrir, un danger
## cyclique s'éteindre. Le mur, lui, ne bouge jamais. Un filtre de rejet doit
## être PESSIMISTE sur ce qu'il refuse, sinon il écarte des cartes valables — et
## c'est le genre d'erreur qu'on ne voit jamais, puisqu'elle se manifeste par une
## absence.
## Combien d'agents ont la sortie dans leur composante connexe. Remplace
## l'ancien « la sortie est-elle atteignable » : la même question, mais chiffrée,
## donc confrontable à l'objectif.
func _agents_that_can_reach_exit(data: Dictionary) -> int:
	var grid: Dictionary = data.get("grid", {})
	var size: Array = grid.get("size", [0, 0])
	var w: int = int(size[0])
	var h: int = int(size[1])
	var cells: Array = grid.get("cells", [])
	if w <= 0 or h <= 0 or cells.size() < w * h:
		return 0
	# On part DE LA SORTIE : un seul parcours, et l'on compte ensuite les agents
	# atteints. Partir de chaque agent en referait un par agent.
	var queue: Array = []
	var seen: Dictionary = {}
	for i in range(cells.size()):
		if int(cells[i]) == GridState.CellType.EXIT:
			seen[i] = true
			queue.append(i)
	var head := 0
	while head < queue.size():
		var idx: int = queue[head]
		head += 1
		@warning_ignore("integer_division")
		var x: int = idx % w
		@warning_ignore("integer_division")
		var y: int = idx / w
		for step in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var nx: int = x + step.x
			var ny: int = y + step.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var n: int = ny * w + nx
			if seen.has(n) or int(cells[n]) == GridState.CellType.WALL:
				continue
			seen[n] = true
			queue.append(n)
	var reachable := 0
	for a in data.get("agents", []):
		var p: Array = (a as Dictionary)["pos"]
		if seen.has(int(p[1]) * w + int(p[0])):
			reachable += 1
	return reachable

## Combien d'agents l'objectif d'extraction exige. Zéro si le niveau n'en porte
## pas — un objectif de collecte ne se compte pas en sorties.
func _required_exits(data: Dictionary) -> int:
	var agents: int = (data.get("agents", []) as Array).size()
	var needed := 0
	for o in data.get("objectives", []):
		var obj: Dictionary = o
		if String(obj.get("type", "")) == "extraction":
			@warning_ignore("integer_division")
			needed = maxi(needed, (int(obj.get("percent", 100)) * agents + 99) / 100)
	return needed

## La carte offre-t-elle un moyen de traverser un danger sans y rester ?
## R13 le neutralise en s'y consumant ; un atelier à boucliers encaisse le
## contact. Sans l'un des deux, un danger sur le seul chemin est un mur qui tue.
func _can_survive_a_danger(data: Dictionary) -> bool:
	for v in data.get("allowed_rules", []):
		if RuleRegistry.base_rule_id(int(v)) == RuleRegistry.R13_PLUG:
			return true
	for c in (data.get("grid", {}) as Dictionary).get("cells", []):
		if int(c) == GridState.CellType.SHIELD:
			return true
	return false

## `avoid_danger` : le même parcours, mais en refusant d'entrer sur un danger
## fixe. Deux questions différentes — « peut-on arriver ? » et « peut-on arriver
## SANS mourir ? » — avec le même code, ce qui évite qu'elles divergent.
func _exit_is_reachable(data: Dictionary, avoid_danger: bool) -> bool:
	var grid: Dictionary = data.get("grid", {})
	var size: Array = grid.get("size", [0, 0])
	var w: int = int(size[0])
	var h: int = int(size[1])
	var cells: Array = grid.get("cells", [])
	if w <= 0 or h <= 0 or cells.size() < w * h:
		return false
	var queue: Array = []
	var seen: Dictionary = {}
	for a in data.get("agents", []):
		var p: Array = (a as Dictionary)["pos"]
		var idx: int = int(p[1]) * w + int(p[0])
		if not seen.has(idx):
			seen[idx] = true
			queue.append(idx)
	var head := 0
	while head < queue.size():
		var idx: int = queue[head]
		head += 1
		if int(cells[idx]) == GridState.CellType.EXIT:
			return true
		@warning_ignore("integer_division")
		var x: int = idx % w
		@warning_ignore("integer_division")
		var y: int = idx / w
		for step in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var nx: int = x + step.x
			var ny: int = y + step.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var n: int = ny * w + nx
			if seen.has(n) or int(cells[n]) == GridState.CellType.WALL:
				continue
			if avoid_danger and int(cells[n]) == GridState.CellType.STATIC_DANGER:
				continue
			seen[n] = true
			queue.append(n)
	return false

## Longueur de la plus courte pile gagnante parmi les piles COURTES, ou 0 si
## aucune ne gagne. On monte par longueur croissante et on s'arrête au premier
## succès : une carte que `[R01]` seule résout est condamnée par `--min-len`, et
## l'apprendre coûte alors autant de simulations qu'il y a de règles.
##
## ON NE VA PAS AU-DELÀ DE `_min_len - 1` : au-dessus, ce n'est plus un motif de
## rejet, et l'énumération complète du validateur fera le travail une seule fois.
func _shortest_winner_length(data: Dictionary) -> int:
	var allowed: Array[int] = []
	for v in data.get("allowed_rules", []):
		allowed.append(int(v))
	for length in range(1, maxi(_min_len, 1)):
		for stack_variant in StackEnumerator.enumerate(allowed, length):
			var stack: Array[int] = []
			for v in stack_variant:
				stack.append(int(v))
			if stack.size() != length:
				continue
			var row := ValidateLib.simulate_stack(data, _params, stack)
			if int(row["outcome"]) == SimState.Outcome.WON:
				return length
	return 0

## Retire de la bibliothèque tout ce qui ne porte aucune gagnante, et re-mesure.
##
## DEUX PASSES SUFFISENT EN PRATIQUE, mais la boucle est écrite pour converger :
## retirer une règle supprime des piles, ce qui peut rendre MINIMALES des
## gagnantes qui ne l'étaient pas — donc changer la liste des porteuses. On
## s'arrête dès que la bibliothèque ne bouge plus, et on garde le dernier verdict
## VALIDE : un resserrage qui ferait tomber le niveau sous QN-01 est un
## resserrage de trop, et c'est alors le candidat entier qu'on écarte.
func _narrow(shape: Dictionary, verdict: Dictionary, reasons: Dictionary) -> Dictionary:
	var library: Array = _rules.duplicate()
	var best := verdict
	for _pass in range(3):
		var carriers: Array = (best["carriers"] as Array).duplicate()
		carriers.sort()
		if carriers.size() >= library.size():
			break
		var text := _render(shape, _probe_ticks, carriers)
		if text.is_empty():
			break
		var parsed := LvlParser.parse(text, _min_period, _flee_sq)
		if not (parsed["errors"] as PackedStringArray).is_empty():
			break
		var judged := _judge(parsed["level"], reasons)
		if int(judged["score"]) <= 0:
			# La carte ne tenait que par ses fausses pistes.
			_tally(reasons, "ne survit pas au resserrage de la bibliothèque")
			return {"score": 0}
		library = carriers
		best = judged
	best["library"] = library
	return best

## Règles présentes dans TOUTES les gagnantes minimales.
func _monopolies(minimal: Array) -> Array:
	if minimal.size() < 2:
		return []
	var candidates := _bases(minimal[0])
	for stack in minimal:
		var bases := _bases(stack)
		var kept: Array = []
		for r in candidates:
			if bases.has(r):
				kept.append(r)
		candidates = kept
	return candidates

## --- Ce que le catalogue occupe déjà ------------------------------------------
##
## Sans cette photo, la forge proposerait des cartes dont la réponse est celle
## d'un niveau existant — ce qui est exactement le défaut qu'elle doit corriger.
## Le calcul coûte plusieurs minutes ; il est donc mis en cache, clefé par une
## empreinte de TOUS les fichiers de niveau et de `data/rules.json`. Un cache
## qui sert une réponse périmée sans le dire serait pire que pas de cache : ici
## le moindre octet modifié le fait recalculer.
func _load_catalogue() -> void:
	var stamp := _catalogue_stamp()
	# On teste l'existence AVANT de parser : passer une chaîne vide à `JSON` fait
	# hurler le moteur sur la sortie d'erreur, et un outil qui crie à sa première
	# exécution normale apprend à ignorer ses propres avertissements.
	var raw := FileAccess.get_file_as_string(CACHE) if FileAccess.file_exists(CACHE) else ""
	var cached: Variant = JSON.parse_string(raw) if not raw.is_empty() else null
	if cached is Dictionary and String((cached as Dictionary).get("stamp", "")) == stamp:
		for key in (cached as Dictionary).get("sets", []):
			_known_sets[String(key)] = true
		for pair in (cached as Dictionary).get("pairs", []):
			_known_pairs[String(pair)] = true
		return

	print("(photo du catalogue — quelques minutes, mise en cache ensuite)")
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var data := LevelCatalog.load_level_data(String(entry["id"]))
		var report := ValidateLib.validate_level(data, _params, _min_period)
		for stack in _minimal_from_rows(report["rows"]):
			var s := _bases(stack)
			s.sort()
			_known_sets[str(s)] = true
			for a in range(s.size()):
				for b in range(a + 1, s.size()):
					_known_pairs["%d-%d" % [s[a], s[b]]] = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DEFAULT))
	var f := FileAccess.open(CACHE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"stamp": stamp, "sets": _known_sets.keys(), "pairs": _known_pairs.keys()}))
		f.close()

func _catalogue_stamp() -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(FileAccess.get_file_as_bytes("res://data/rules.json"))
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		ctx.update(FileAccess.get_file_as_bytes(String(entry["path"])))
	return ctx.finish().hex_encode()

## --- Le balayage des géométries ---------------------------------------------
## Bornes du CDC §8.1, que le convertisseur applique de son côté. On les
## respecte ICI, à la génération, plutôt que d'aller se les faire refuser : un
## quart de tour ÉCHANGE largeur et hauteur, et une grille 9×11 parfaitement
## légale devient un 11×9 illégal. Trente candidats sur soixante étaient perdus
## à ce seul titre — et la forge n'avait plus de budget pour les vrais essais.
const MIN_W := 8
const MAX_W := 14
const MIN_H := 10
const MAX_H := 18

func _fits_after_turn(w: int, h: int, face: int) -> bool:
	var fw: int = h if face % 2 == 1 else w
	var fh: int = w if face % 2 == 1 else h
	return fw >= MIN_W and fw <= MAX_W and fh >= MIN_H and fh <= MAX_H

## LA COHÉRENCE AVEC LA BIBLIOTHÈQUE SE VÉRIFIE AVANT DE GÉNÉRER, pas après.
##
## Poser un mobilier qu'aucune règle du brief ne sait employer produit une carte
## morte, et le balayage la paie au prix fort : les deux passes « bouclier » ont
## produit **1 054 candidats sur 1 200 sans une seule gagnante**, tous parce
## qu'un goulot bouché barrait la seule route alors que la bibliothèque n'avait
## ni R13 pour le neutraliser ni atelier pour l'encaisser.
##
## C'est le pendant, côté GÉNÉRATION, du principe qui gouverne les règles : un
## élément qui ne sert à rien ne rend pas le niveau plus difficile, il le rend
## plus long. Ici il ne le rend même pas plus long : il le rend impossible.
func _furniture_is_playable(plug: bool, station: String) -> bool:
	var has_plug_rule := false
	for r in _rules:
		if RuleRegistry.base_rule_id(r) == RuleRegistry.R13_PLUG:
			has_plug_rule = true
	# Un goulot bouché sans rien pour le franchir ferme la carte.
	if plug and not has_plug_rule and station == "none":
		return false
	# Un atelier sans danger ne protège de rien : c'est du décor.
	if station != "none" and not plug:
		return false
	return true

func _shapes() -> Array:
	var out: Array = []
	for w in [9, 11, 13]:
		for h in [11, 13, 15]:
			for ox in [1, w / 4, w / 2, (3 * w) / 4, w - 2]:
				# LA LUMIÈRE-LEURRE EST BALAYÉE, ET C'EST LA LEÇON DE ch2_04.
				# Posée derrière la sortie, elle rend `[R01]` suffisante et le
				# niveau se résout tout seul ; posée à l'opposé, elle devient un
				# piège et il faut composer pour l'atteindre. Les deux régimes
				# doivent être essayés, pas seulement le premier.
				for lx in [ox, maxi(0, ox - 2), mini(w - 1, ox + 2), 0, w - 1]:
					for band in (_bands if not _bands.is_empty() else ["none", "one_gap", "two_gaps", "split"]):
						# L'OUVERTURE SE PLACE PAR RAPPORT À LA SORTIE, jamais en
						# absolu — et c'est le réglage qui décide si le balayage
						# trouve quelque chose.
						#
						# Mesuré sur 250 candidats : 103 se gagnaient avec une seule
						# règle et 100 n'avaient aucune gagnante — 81 % aux deux
						# extrêmes. Des colonnes absolues donnent soit un goulot pile
						# sous la sortie (la lumière y mène seule, carte triviale),
						# soit un détour d'une demi-carte (personne n'arrive).
						#
						# Le seul niveau retenu jusqu'ici, ch2_06, a son ouverture
						# décalée d'UNE case : assez pour que « vers la lumière »
						# refuse le pas de côté, pas assez pour que la carte devienne
						# infranchissable. C'est cette bande étroite qu'on balaie.
						for delta in [-2, -1, 1, 2]:
							var gx: int = clampi(ox + delta, 1, w - 2)
							if gx == ox:
								continue
							for plug in (_plugs if not _plugs.is_empty() else [false, true]):
								if plug and band == "none":
									continue   # rien à boucher sans goulot
								for station in (_stations if not _stations.is_empty() else ["none"]):
									if not _furniture_is_playable(plug, station):
										continue
									for swarm in [[4, 5], [5, 4], [5, 5]]:
										for bx in [1, (w - int(swarm[0])) / 2, w - int(swarm[0]) - 1]:
											for face in (_faces if not _faces.is_empty() else [0, 1, 2, 3]):
												if not _fits_after_turn(w, h, face):
													continue
												out.append({
													"w": w, "h": h, "ox": ox, "lx": lx,
													"band": band, "gx": gx, "plug": plug,
													"station": _station_x(w, gx, station),
													"sw": int(swarm[0]), "sh": int(swarm[1]),
													"bx": bx, "face": face,
												})
	return out

func _station_x(w: int, gx: int, where: String) -> int:
	match where:
		"under": return gx - 1
		"left": return maxi(1, gx - 4)
		"right": return mini(w - 4, gx + 2)
		_: return -1

## Rend une géométrie en texte `.lvl`, dans l'orientation canonique — sortie au
## Nord — puis la fait pivoter d'un quart de tour par cran de `face`.
## `library` vide = la bibliothèque du brief. Le resserrage lui passe la liste
## réduite, et l'émission finale la reprend : le fichier écrit porte donc
## exactement les règles qui PORTENT une gagnante, pas celles qu'on avait
## offertes au départ.
func _render(s: Dictionary, max_ticks: int = 300, library: Array = []) -> String:
	var w := int(s["w"])
	var h := int(s["h"])
	var rows: Array = []
	for y in range(h):
		var row: Array = []
		for x in range(w):
			row.append(".")
		rows.append(row)

	rows[0][int(s["lx"])] = "L"
	for x in range(w):
		rows[1][x] = "#"
	rows[1][int(s["ox"])] = "E"

	# La bande médiane crée un CHOIX de route, donc des familles. Sans elle,
	# l'entonnoir de l'idiome n'a qu'une réponse.
	var my := h / 2
	var band := String(s["band"])
	if band != "none":
		for x in range(w):
			rows[my][x] = "#"
		# `split` PERCE SES PROPRES OUVERTURES et n'utilise pas `gx` : lui laisser
		# ouvrir la sienne en plus donnait TROIS passages, dont deux voisins — le
		# goulot bouché se contournait d'une case, et le raccourci qu'on voulait
		# faire payer devenait gratuit. Le défaut ne se voyait pas dans les
		# chiffres, seulement en relisant la carte produite.
		if band != "split":
			rows[my][int(s["gx"])] = "."
		if band == "two_gaps":
			# LA SECONDE OUVERTURE EST LE MIROIR DE LA PREMIÈRE PAR RAPPORT À
			# LA SORTIE, et ce n'est pas une coquetterie de symétrie.
			#
			# Elle se calculait par une arithmétique arbitraire — un tiers de
			# largeur modulo la grille — qui la posait n'importe où : tantôt
			# collée à la première (une seule route en pratique), tantôt à
			# l'autre bout (un détour que personne ne prend). Dans les deux cas
			# une seule famille gagnante, et le candidat tombait.
			#
			# Deux ouvertures ÉQUIDISTANTES de la sortie donnent deux routes de
			# coût comparable, donc deux réponses défendables — c'est la
			# condition géométrique pour que le niveau porte plusieurs familles.
			# Et l'invariant n°19 garantit qu'elles ne se valent pas tout à fait :
			# à égalité tout préfère l'Est, donc le miroir n'est jamais un
			# doublon.
			var other: int = clampi(2 * int(s["ox"]) - int(s["gx"]), 1, w - 2)
			if other != int(s["gx"]):
				rows[my][other] = "."
		elif band == "split":
			# DEUX ROUTES DE COÛTS DIFFÉRENTS, et c'est une forme que les autres
			# gabarits ne savent pas produire. `two_gaps` place ses ouvertures au
			# hasard de l'arithmétique : elles finissent voisines, les deux
			# routes se valent, et le choix n'existe pas.
			#
			# Ici l'une des ouvertures tombe À L'APLOMB de la nuée — le chemin le
			# plus court possible — et l'autre à l'extrémité opposée de la paroi.
			# Le raccourci est alors court PARCE QU'il est court, pas par
			# accident, et le détour coûte toute la largeur de la carte.
			#
			# C'EST LA FORME QUE LA DÉCISION 191 RÉCLAME POUR LE BOUCLIER :
			# « une carte où traverser le danger est un CHOIX — un raccourci
			# payant contre un détour lent ». Bouché, le raccourci se paie ; libre
			# et lointain, le détour se paie en temps.
			var near: int = clampi(int(s["bx"]) + int(s["sw"]) / 2, 1, w - 2)
			var far: int = 1 if near > w / 2 else w - 2
			rows[my][near] = "."
			rows[my][far] = "."
			s["near_gap"] = near
		if bool(s["plug"]):
			var plugged: int = int(s.get("near_gap", s["gx"]))
			rows[my][plugged] = "X"

	# L'ATELIER À BOUCLIERS, À L'ÉCART de la ligne droite : posé dans
	# l'entonnoir il couvre tout le monde et `[R01]` seule regagne (décision
	# 191). Seuls les agents qu'une règle a détournés le traversent.
	var station := int(s.get("station", -1))
	if station >= 0 and band != "none":
		for dx in range(3):
			var x: int = station + dx
			if x >= 0 and x < w and rows[my + 1][x] == ".":
				rows[my + 1][x] = "B"

	# La nuée se place par rapport à la BANDE, pas au bas de la grille : calée
	# sur le bas, elle chevauchait la bande deux fois sur trois.
	var floor_by: int = h - int(s["sh"]) - 1
	var by: int = maxi(my + 2, floor_by) if band != "none" else floor_by
	if by + int(s["sh"]) > h or by <= 1:
		return ""
	for dy in range(int(s["sh"])):
		for dx in range(int(s["sw"])):
			var x: int = int(s["bx"]) + dx
			if x >= 0 and x < w:
				rows[by + dy][x] = "o"

	rows = _rotate(rows, int(s["face"]))
	var lines := PackedStringArray()
	for row in rows:
		lines.append(" ".join(PackedStringArray(row)))
	var header := PackedStringArray()
	header.append("id: forge_tmp")
	header.append("name: Forge")
	header.append("tutorial: false")
	header.append("allowed_rules: [%s]" % ", ".join(
		_names(library if not library.is_empty() else _rules)))
	header.append("slots: %d" % _slots)
	header.append("max_ticks: %d" % max_ticks)
	for objective in _objective.split(";", false):
		header.append("objective: %s" % objective.strip_edges())
	header.append("---")
	return "\n".join(header) + "\n" + "\n".join(lines) + "\n"

## Quart de tour horaire, `quarters` fois. La sortie passe au Nord, à l'Est, au
## Sud ou à l'Ouest — et l'invariant n°19 garantit que ce n'est PAS la même
## carte : à égalité toute règle préfère le Nord puis l'Est, donc une nuée qui
## monte vers la sortie ne se comporte pas comme une nuée qui descend.
func _rotate(rows: Array, quarters: int) -> Array:
	var out: Array = rows
	for _q in range(posmod(quarters, 4)):
		var h: int = out.size()
		var w: int = (out[0] as Array).size()
		var turned: Array = []
		for y in range(w):
			var row: Array = []
			for x in range(h):
				row.append((out[h - 1 - x] as Array)[y])
			turned.append(row)
		out = turned
	return out

## --- Sortie ------------------------------------------------------------------
func _emit(kept: Array, reasons: Dictionary) -> void:
	if kept.is_empty():
		print("\nAucun candidat ne satisfait le brief. Les motifs d'écart "
			+ "ci-dessus disent où céder : bibliothèque, objectif, ou --min-sets.")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	print("\nMEILLEURS CANDIDATS")
	const FACES := ["Nord", "Est", "Sud", "Ouest"]
	# UN PALMARÈS DE SIX VARIANTES DE LA MÊME CARTE N'EST PAS UN PALMARÈS. Le
	# balayage produit des géométries voisines — une colonne de nuée décalée, une
	# grille d'une rangée de plus — qui donnent exactement les mêmes familles
	# gagnantes. Elles occupaient les six places et masquaient les idées
	# différentes plus bas dans le classement. On n'en montre donc qu'une par
	# jeu de familles, et le choix se fait entre des propositions DISTINCTES.
	var shown := 0
	var seen_families: Dictionary = {}
	for i in range(kept.size()):
		if shown >= _top:
			break
		var c: Dictionary = kept[i]
		var s: Dictionary = c["shape"]
		if seen_families.has(String(c["families"])):
			continue
		# LE RESSERRAGE EST UNE FINITION, PAS UN FILTRE — et le confondre coûtait
		# quatre fois le prix. Il relance une énumération complète jusqu'à trois
		# fois ; appliqué à chaque survivant, il empêchait un balayage de 250
		# candidats de finir en neuf minutes, là où 50 candidats rejetés par les
		# filtres bon marché prennent trois secondes.
		#
		# La règle de qualité ne change pas — un candidat qui ne survit pas au
		# resserrage est écarté, et le suivant prend sa place — mais on ne la paie
		# que sur la poignée qu'on va écrire.
		var narrowed := _narrow(s, c, reasons)
		if int(narrowed["score"]) <= 0:
			continue
		c = narrowed
		c["shape"] = s
		seen_families[String(c["families"])] = true
		shown += 1
		print("\n#%d  score %d — %s" % [shown, int(c["score"]), String(c["why"])])
		print("    familles : %s" % String(c["families"]))
		if not (c["fresh"] as PackedStringArray).is_empty():
			print("    associations inédites : %s" % ", ".join(c["fresh"]))
		print("    sortie au %s, bande %s%s, %d gagnantes, meilleure %s en %d ticks"
			% [FACES[int(s["face"])], String(s["band"]),
				", goulot bouché" if bool(s["plug"]) else "",
				int(c["n_win"]), str(c["best_stack"]), int(c["min_ticks"])])
		print("    %s" % String(c["verdict"]))
		# `max_ticks` EST UN PARAMÈTRE DE LA CARTE (invariant n°15) : on le
		# calibre sur la mesure, avec le double du meilleur temps pour marge, au
		# lieu de recopier un 300 qui ne veut rien dire sur cette géométrie.
		# ON RE-REND LA CARTE avec la valeur calibrée, plutôt que de la substituer
		# dans le texte déjà produit. Un remplacement qui ne correspond à rien
		# rend le texte intact et rapporte un succès — c'est le mode de panne que
		# tout le dépôt s'interdit, et il n'y a aucune raison de le rouvrir ici.
		var calibrated: int = clampi(int(c["min_ticks"]) * 2, 60, 300)
		var library: Array = c.get("library", _rules)
		var text := _finish(s, c, calibrated, library)
		var path := "%s/forge_%02d.lvl" % [_out, shown]
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(text)
			f.close()
			print("    bibliothèque resserrée à %s" % ", ".join(_names(library)))
			print("    écrit : %s  (max_ticks %d, %d gagnantes, %d classes)"
				% [path, calibrated, int(c["n_win"]), int(c["classes"])])

## --- Mécanique commune -------------------------------------------------------
## Les gagnantes MINIMALES : celles dont aucune sous-suite ne gagne déjà. On
## raisonne en SOUS-SUITE et non en sous-ensemble, parce que l'ordre décide —
## `[R09, R01]` gagne ch3_04 là où `[R01, R09]` ne sort personne.
func _minimal_from_rows(rows: Array) -> Array:
	var winners: Array = []
	for row in rows:
		var stack: Array = row["stack"]
		if not stack.is_empty() and int(row["outcome"]) == SimState.Outcome.WON:
			winners.append(stack)
	var minimal: Array = []
	for stack in winners:
		var redundant := false
		for other in winners:
			if (other as Array).size() < (stack as Array).size() \
					and _is_subsequence(other, stack):
				redundant = true
				break
		if not redundant:
			minimal.append(stack)
	return minimal

func _is_subsequence(small: Array, big: Array) -> bool:
	var j := 0
	for v in big:
		if j < small.size() and small[j] == v:
			j += 1
	return j == small.size()

func _bases(stack: Array) -> Array:
	var out: Array = []
	for v in stack:
		out.append(RuleRegistry.base_rule_id(int(v)))
	return out

## « [1, 4, 13] » -> [1, 4, 13]. La clé d'un jeu de règles est sa forme texte ;
## la relire évite de trimballer deux représentations en parallèle.
func _ids_of(key: String) -> Array:
	var out: Array = []
	for token in key.trim_prefix("[").trim_suffix("]").split(",", false):
		out.append(int(token.strip_edges()))
	return out

func _names(ids: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for r in ids:
		out.append("R%02d" % int(r))
	return out

func _tally(reasons: Dictionary, reason: String) -> void:
	reasons[reason] = int(reasons.get(reason, 0)) + 1

func _read_brief() -> void:
	for arg in OS.get_cmdline_user_args():
		var key := arg.get_slice("=", 0)
		var value := arg.substr(key.length() + 1)
		match key:
			"--rules":
				for token in value.split(",", false):
					_rules.append(int(token.strip_edges().lstrip("Rr")))
			"--want":
				for token in value.split(",", false):
					_want.append(int(token.strip_edges().lstrip("Rr")))
			"--slots": _slots = int(value)
			"--objective": _objective = value.replace(":", " ")
			"--max": _max_candidates = int(value)
			"--min-sets": _min_sets = int(value)
			"--max-sets": _max_sets = int(value)
			"--min-len": _min_len = int(value)
			"--probe-ticks": _probe_ticks = int(value)
			"--top": _top = int(value)
			"--out": _out = value if value.begins_with("res://") else "res://" + value
			"--band":
				for token in value.split(",", false):
					_bands.append(token.strip_edges())
			"--plug":
				for token in value.split(",", false):
					_plugs.append(token.strip_edges() == "true")
			"--station":
				for token in value.split(",", false):
					_stations.append(token.strip_edges())
			"--face":
				for token in value.split(",", false):
					_faces.append(["N", "E", "S", "O"].find(token.strip_edges().to_upper()))
