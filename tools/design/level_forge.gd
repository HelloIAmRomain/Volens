extends SceneTree
## LA FORGE — on énumère des géométries, on les MESURE, on garde les variées.
##
## POURQUOI ELLE EXISTE. Écrire un niveau à la main, c'est décider de sa
## géométrie AVANT de pouvoir voir son espace de solutions — on ne le découvre
## qu'après, en le jouant. Cinq géométries de bouclier ont été jetées pour cette
## seule raison, et vingt-deux niveaux sur trente-deux n'ont qu'UNE pile
## gagnante minimale sans que personne l'ait voulu. La forge inverse l'ordre :
## elle produit la carte, l'interroge, et ne présente que ce qui a répondu.
##
## ELLE NE REMPLACE PAS LE JUGEMENT. Elle classe des candidats ; la fiche du
## niveau, sa leçon et son nom restent une décision humaine. Une carte qui
## mesure bien mais ne raconte rien n'est pas un niveau.
##
## ## Trois garde-fous, et ils sont la condition de l'exercice
##
## 1. **AUCUN TIRAGE ALÉATOIRE, nulle part.** Le balayage est un produit
##    cartésien parcouru dans un ordre fixe. Deux exécutions donnent la même
##    liste, donc la liste se discute. Un générateur aléatoire aurait produit
##    des cartes qu'on ne saurait pas reproduire — et `core/` interdit déjà le
##    hasard pour la raison voisine.
##
## 2. **ON GÉNÈRE DANS L'IDIOME**, jamais en géométrie libre : la lumière est
##    DERRIÈRE le mur, la sortie est l'OUVERTURE de ce mur (docs/ARCHITECTURE.md). C'est ce
##    qui donne l'entonnoir gratuitement, et c'est ce qui fait qu'une carte
##    forgée ressemble aux autres au lieu d'avoir l'air tombée d'ailleurs.
##
## 3. **LA SORTIE EST DU `.lvl`, jamais du JSON.** Le convertisseur porte les
##    contrôles G1 à G3 (invariant n°14) et calcule l'empreinte `calibrated_on`
##    (invariant n°15). Émettre du JSON, c'est contourner précisément les
##    garde-fous écrits pour ce genre de carte. Mieux : la forge APPELLE le
##    parseur pour évaluer, donc toute géométrie que le convertisseur refuserait
##    est éliminée avant même d'être simulée — le refus devient un filtre.
##
## ## Ce que la forge cherche
##
## Le défaut mesuré par `combinations.gd` n'est pas « trop peu de niveaux »,
## c'est **trop peu de FAMILLES par niveau**. Le score récompense donc :
##
##   · plusieurs jeux de règles gagnants **réellement distincts**, pas plusieurs
##     ordres du même trio ;
##   · **aucune règle présente dans toutes** les gagnantes minimales — une règle
##     obligatoire n'est pas un choix, c'est un péage ;
##   · les règles demandées (`--want`) réellement PORTEUSES ;
##   · et il refuse la bouillie : un niveau où tout gagne n'est pas varié, il est
##     vide. Au-delà de `--max-sets` jeux distincts, le candidat est rejeté.
##
## ## Le levier principal : la PISTE INITIALE
##
## `*` et les chiffres posent une piste avant le premier tick. Le mécanisme est
## implémenté depuis des mois et **aucun niveau ne s'en sert**. Or une piste qui
## s'arrête à MI-CHEMIN fait de R09 un moteur sans R01, et laisse la fin du
## trajet à une autre règle — c'est-à-dire qu'elle fabrique des familles
## différentes par construction. C'est la réponse la plus directe à « je ne veux
## pas toujours les mêmes règles gagnantes ».
##
## ## Usage
##
##   godot --headless --path . --script res://tools/design/level_forge.gd -- \
##       --rules=R01,R04,R09,R13 --slots=3 --want=R13 \
##       --objective=extraction:100 --top=5
##
## Options : --max=<candidats>  --min-sets=<n>  --max-sets=<n>  --min-len=<n>
##           --out=<dossier>  --avoid=<jeux déjà utilisés, ex. "[1,13];[1,9]">

const GUARD := 400
const OUT_DEFAULT := "res://reports/forge"

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
var _avoid: Array[String] = []
## Restrictions du balayage. Le produit cartésien complet dépasse la centaine de
## milliers de géométries ; ces filtres servent à INTERROGER une hypothèse
## précise (« et si le goulot était bouché ? ») plutôt qu'à parcourir l'espace
## dans l'ordre où il se présente, ce qui revient à ne fouiller qu'un coin.
var _bands: Array[String] = []
var _trails: Array[String] = []
var _plugs: Array[bool] = []

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

	print("FORGE — bibliothèque %s, %d rangs, objectif « %s »"
		% [_names(_rules), _slots, _objective])
	if not _want.is_empty():
		print("        règles exigées porteuses : %s" % _names(_want))

	var kept: Array = []
	var reasons: Dictionary = {}
	var seen := 0
	var refused_by_parser := 0
	var no_winner := 0
	var mush := 0
	for shape in _shapes():
		if seen >= _max_candidates:
			break
		var text: String = _render(shape)
		if text.is_empty():
			continue   # gabarit impossible : ne consomme pas le budget
		seen += 1
		var parsed := LvlParser.parse(text, _min_period, _flee_sq)
		var errors: PackedStringArray = parsed["errors"]
		if not errors.is_empty():
			refused_by_parser += 1
			# ON AGRÈGE LES MOTIFS DE REFUS. Sans eux on pilote à l'aveugle :
			# « 399 refusées » ne dit pas s'il faut corriger le gabarit ou le
			# brief, et les deux corrections n'ont rien à voir.
			var reason: String = errors[0].get_slice(":", 0)
			reasons[reason] = int(reasons.get(reason, 0)) + 1
			continue
		var data: Dictionary = parsed["level"]
		var minimal := _minimal_winners(data)
		if minimal.is_empty():
			no_winner += 1
			continue
		var verdict := _score(minimal)
		if int(verdict["sets"]) > _max_sets:
			mush += 1
			continue
		if int(verdict["score"]) <= 0:
			continue
		verdict["shape"] = shape
		verdict["text"] = text
		kept.append(verdict)

	kept.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(a["score"]) > int(b["score"]))

	print(("\n%d géométries balayées : %d refusées par le convertisseur, %d sans "
		+ "gagnante, %d en bouillie, %d retenues.")
		% [seen, refused_by_parser, no_winner, mush, kept.size()])
	for reason in reasons:
		print("    refus × %-4d %s" % [int(reasons[reason]), String(reason)])
	_emit(kept)
	quit()

## --- Score ------------------------------------------------------------------
##
## Un candidat vaut par le nombre de FAMILLES qu'il porte, pas par le nombre de
## piles : deux ordres d'un même trio racontent la même chose.
func _score(minimal: Array) -> Dictionary:
	var sets: Dictionary = {}
	for stack in minimal:
		var s := _bases(stack)
		s.sort()
		sets[str(s)] = true

	# MONOPOLE — une règle dans toutes les gagnantes minimales. Rédhibitoire
	# dès qu'il y a plusieurs gagnantes : sinon le choix annoncé n'existe pas.
	var monopolies: Array = []
	if minimal.size() > 1:
		var candidates := _bases(minimal[0])
		for stack in minimal:
			var bases := _bases(stack)
			var kept: Array = []
			for r in candidates:
				if bases.has(r):
					kept.append(r)
			candidates = kept
		monopolies = candidates

	var borne: Dictionary = {}
	for stack in minimal:
		for r in _bases(stack):
			borne[r] = true
	var shortest := 99
	for stack in minimal:
		shortest = mini(shortest, (stack as Array).size())

	var score := 0
	var why := PackedStringArray()
	if sets.size() < _min_sets:
		return {"score": 0, "sets": sets.size()}
	if shortest < _min_len:
		return {"score": 0, "sets": sets.size()}
	for r in _want:
		if not borne.has(r):
			return {"score": 0, "sets": sets.size()}
	for key in sets:
		if _avoid.has(String(key)):
			return {"score": 0, "sets": sets.size()}   # déjà servi ailleurs

	score += sets.size() * 10
	why.append("%d familles" % sets.size())
	if monopolies.is_empty():
		score += 25
		why.append("aucun monopole")
	else:
		score -= monopolies.size() * 8
		why.append("monopole %s" % _names(monopolies))
	# Une famille de plus vaut mieux qu'une pile de plus : on récompense la
	# DIVERSITÉ, pas la quantité, et une nuée de piles autour d'un seul jeu de
	# règles est un signe de mou, pas de richesse.
	score += mini(minimal.size(), sets.size() * 3)
	score += borne.size() * 4
	why.append("%d règles porteuses" % borne.size())

	var names := PackedStringArray()
	for key in sets:
		names.append(String(key))
	return {
		"score": score, "sets": sets.size(), "minimal": minimal.size(),
		"why": ", ".join(why), "families": " / ".join(names),
		"shortest": shortest, "borne": borne.keys(),
	}

## --- Le balayage des géométries ---------------------------------------------
##
## Produit cartésien parcouru dans un ordre fixe. L'asymétrie gauche/droite est
## balayée EXPLICITEMENT (invariant n°19) : à égalité toute règle préfère l'Est,
## donc une ouverture à l'ouest ne se résout pas comme son miroir, et il serait
## faux de n'en essayer qu'une moitié.
func _shapes() -> Array:
	var out: Array = []
	for w in [9, 11, 13]:
		for h in [11, 13]:
			for ox in [1, w / 4, w / 2, (3 * w) / 4, w - 2]:
				for light_shift in [0, -2, 2]:
					var lx: int = clampi(ox + light_shift, 0, w - 1)
					for band in (_bands if not _bands.is_empty() else ["none", "one_gap", "two_gaps"]):
						for gx in [w / 3, w / 2, (2 * w) / 3]:
							for plug in (_plugs if not _plugs.is_empty() else [false, true]):
								if plug and band == "none":
									continue   # rien à boucher sans goulot
								for trail in (_trails if not _trails.is_empty() else ["none", "half", "full"]):
									for swarm in [[4, 5], [5, 4], [5, 5]]:
										for bx in [1, (w - int(swarm[0])) / 2, w - int(swarm[0]) - 1]:
											out.append({
												"w": w, "h": h, "ox": ox, "lx": lx,
												"band": band, "gx": gx, "plug": plug,
												"trail": trail,
												"sw": int(swarm[0]), "sh": int(swarm[1]),
												"bx": bx,
											})
	return out

## Rend une géométrie en texte `.lvl`. Le mur de tête porte la sortie ; la
## lumière est au-dessus, DERRIÈRE lui — c'est l'idiome, et il n'est pas
## paramétrable : s'en écarter demande une raison écrite dans la fiche.
func _render(s: Dictionary) -> String:
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

	# La bande médiane : c'est elle qui crée un CHOIX de route, donc des
	# familles. Sans elle, l'entonnoir de l'idiome n'a qu'une réponse.
	var my := h / 2
	var band := String(s["band"])
	if band != "none":
		for x in range(w):
			rows[my][x] = "#"
		rows[my][int(s["gx"])] = "."
		if band == "two_gaps":
			var other: int = (int(s["gx"]) + w / 3) % (w - 2) + 1
			if other != int(s["gx"]):
				rows[my][other] = "."
		if bool(s["plug"]):
			rows[my][int(s["gx"])] = "X"

	# La nuée, sous la bande. Un bloc compact : l'invariant n°12 rappelle qu'un
	# bloc compact est le cas CONFORTABLE — la bande au-dessus est justement ce
	# qui le rend inconfortable.
	# La nuée se place par rapport à la BANDE, pas par rapport au bas de la
	# grille : calée sur le bas, elle chevauchait la bande deux fois sur trois
	# et le gabarit se sabordait lui-même — 267 candidats perdus avant qu'un
	# motif de refus agrégé ne le dise.
	var floor_by: int = h - int(s["sh"]) - 1
	var by: int = maxi(my + 2, floor_by) if band != "none" else floor_by
	if by + int(s["sh"]) > h or by <= 1:
		return ""   # la nuée ne tient pas sous la bande : géométrie écartée
	for dy in range(int(s["sh"])):
		for dx in range(int(s["sw"])):
			var x: int = int(s["bx"]) + dx
			if x >= 0 and x < w:
				rows[by + dy][x] = "o"

	# LA PISTE INITIALE — une PENTE, jamais un tapis : R09 va vers le marqueur
	# STRICTEMENT plus intense, donc une piste plate n'oriente personne.
	# « half » s'arrête à la bande : R09 amène la nuée au goulot et passe la
	# main. C'est là que naissent des familles différentes.
	# LA PISTE SUIT LE GOULOT, PAS LA SORTIE. Une piste tracée dans la colonne de
	# la sortie ne dit rien que R01 ne dise déjà — elle DOUBLE le moteur au lieu
	# de lui faire concurrence. Tracée vers le goulot, et la lumière décalée de
	# l'autre côté, les deux règles tirent vers des routes DIFFÉRENTES : c'est
	# là, et seulement là, que naissent deux familles gagnantes.
	var trail := String(s["trail"])
	var tx: int = int(s["gx"]) if band != "none" else int(s["ox"])
	if trail != "none":
		var target: int = 2 if trail == "full" else my + 1
		var steps: int = by - target
		if steps >= 2:
			var digit := 1
			for y in range(by - 1, target - 1, -1):
				if rows[y][tx] == ".":
					rows[y][tx] = str(mini(9, 1 + (digit * 8) / maxi(1, steps)))
				digit += 1

	var lines := PackedStringArray()
	for row in rows:
		lines.append(" ".join(PackedStringArray(row)))
	var header := PackedStringArray()
	header.append("id: forge_tmp")
	header.append("name: Forge")
	header.append("tutorial: false")
	header.append("allowed_rules: [%s]" % ", ".join(_names(_rules)))
	header.append("slots: %d" % _slots)
	header.append("max_ticks: 200")
	# Plusieurs objectifs se cumulent, séparés par « ; » dans le brief. Un
	# niveau bâti sur R13 en a BESOIN : boucher consume un agent, donc exiger
	# « extraction 100 » y rend la victoire impossible — la forge a produit 201
	# géométries sans aucune gagnante avant que ce soit dit.
	for objective in _objective.split(";", false):
		header.append("objective: %s" % objective.strip_edges())
	header.append("---")
	return "\n".join(header) + "\n" + "\n".join(lines) + "\n"

## --- Sortie ------------------------------------------------------------------
func _emit(kept: Array) -> void:
	if kept.is_empty():
		print("Aucun candidat ne satisfait le brief. Élargir la bibliothèque, "
			+ "baisser --min-sets, ou accepter un monopole.")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	print("\nMEILLEURS CANDIDATS")
	for i in range(mini(_top, kept.size())):
		var c: Dictionary = kept[i]
		var s: Dictionary = c["shape"]
		print("\n#%d  score %d — %s" % [i + 1, int(c["score"]), String(c["why"])])
		print("    familles : %s" % String(c["families"]))
		print("    %d×%d, sortie x=%d, lumière x=%d, bande %s, piste %s%s"
			% [int(s["w"]), int(s["h"]), int(s["ox"]), int(s["lx"]),
				String(s["band"]), String(s["trail"]),
				", goulot bouché" if bool(s["plug"]) else ""])
		var path := "%s/forge_%02d.lvl" % [_out, i + 1]
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(String(c["text"]))
			f.close()
			print("    écrit : %s" % path)

## --- Mécanique commune -------------------------------------------------------
func _minimal_winners(data: Dictionary) -> Array:
	var allowed: Array[int] = []
	for v in data.get("allowed_rules", []):
		allowed.append(int(v))
	var winners: Array = []
	for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		if stack.is_empty() or _outcome(data, stack) != SimState.Outcome.WON:
			continue
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

func _outcome(data: Dictionary, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, _params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome

func _bases(stack: Array) -> Array:
	var out: Array = []
	for v in stack:
		out.append(RuleRegistry.base_rule_id(int(v)))
	return out

func _names(ids: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for r in ids:
		out.append("R%02d" % int(r))
	return out

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
			"--top": _top = int(value)
			"--out": _out = value if value.begins_with("res://") else "res://" + value
			"--avoid":
				for token in value.split(";", false):
					_avoid.append(token.strip_edges())
			"--band":
				for token in value.split(",", false):
					_bands.append(token.strip_edges())
			"--trail":
				for token in value.split(",", false):
					_trails.append(token.strip_edges())
			"--plug":
				for token in value.split(",", false):
					_plugs.append(token.strip_edges() == "true")
