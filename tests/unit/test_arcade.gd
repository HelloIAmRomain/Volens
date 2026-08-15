extends GutTest
## MODE ÉPREUVE — le tirage doit être JUSTE, et la table qui le fonde HONNÊTE.
##
## Le mode repose sur une donnée dérivée (`data/arcade.json`) et sur un tirage
## aléatoire. Les deux peuvent mentir en silence, et de la pire façon : en
## donnant au joueur une main avec laquelle le niveau est impossible. Il perdrait
## ses lancements sur un problème sans solution, et rien ne le lui dirait.
##
## Ces tests interdisent les deux, et le second est un contrôle GÉNÉRIQUE : il
## ne vérifie pas quelques tirages, il vérifie que **tout tirage possible** est
## jouable, pour tout niveau et pour cent graines.

var _params: RuleParams

func before_all() -> void:
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	_params = RuleParams.from_dict(rules if rules is Dictionary else {})

func _ready_levels() -> Array[String]:
	var out: Array[String] = []
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if bool(entry["ready"]):
			out.append(String(entry["id"]))
	return out

# --- la table est-elle à jour ? --------------------------------------------

func test_the_stored_sets_match_a_fresh_computation() -> void:
	# UNE VALEUR DÉRIVÉE NON VÉRIFIÉE FINIT TOUJOURS PAR DIVERGER. Le fichier
	# est produit hors ligne ; un niveau retouché sans régénération le rendrait
	# faux, et le tirage proposerait des mains injouables. Même dispositif que
	# `calibrated_on`, et pour la même raison.
	var levels := _ready_levels()
	assert_gt(levels.size(), 0, "aucun niveau prêt : le balayage est cassé")
	var stale := PackedStringArray()
	for level_id in levels:
		var fresh := ArcadeSets.minimal_sufficient_sets(
			LevelCatalog.load_level_data(level_id), _params)
		var stored := ArcadeData.sufficient_sets(level_id)
		if str(_normalised(fresh)) != str(_normalised(stored)):
			stale.append("%s (stocké %s, calculé %s)" % [
				level_id, str(_normalised(stored)), str(_normalised(fresh))])
	assert_eq(stale, PackedStringArray(),
		("`data/arcade.json` est périmé — régénérer avec "
		+ "`tools/arcade/build.gd`. Écarts : %s") % ", ".join(stale))

## Les deux sources rendent des Array de Variant ; on compare des listes de
## listes d'entiers, triées, pour que seule la SUBSTANCE compte.
func _normalised(sets: Array) -> Array:
	var out: Array = []
	for s in sets:
		var one: Array = []
		for v in (s as Array):
			one.append(int(v))
		one.sort()
		out.append(one)
	out.sort_custom(func(a: Array, b: Array) -> bool: return str(a) < str(b))
	return out

func test_every_ready_level_is_covered() -> void:
	# Un niveau absent de la table reçoit la bibliothèque entière : le mode
	# fonctionne encore, mais il perd son sel sans que rien ne le signale.
	var uncovered := PackedStringArray()
	for level_id in _ready_levels():
		if ArcadeData.sufficient_sets(level_id).is_empty():
			uncovered.append(level_id)
	assert_eq(uncovered, PackedStringArray(),
		"niveaux sans ensemble suffisant connu : %s" % ", ".join(uncovered))

# --- tout tirage possible est-il jouable ? ---------------------------------

func test_every_draw_of_every_level_contains_a_solution() -> void:
	# LE CONTRÔLE QUI COMPTE, et il est générique : cent graines par niveau,
	# et chaque main doit contenir un ensemble suffisant. Vérifier trois
	# tirages choisis n'aurait rien prouvé — c'est précisément la graine qu'on
	# n'a pas essayée qui rendrait le niveau impossible.
	var unfair := PackedStringArray()
	var checked := 0
	for level_id in _ready_levels():
		var sufficient := ArcadeData.sufficient_sets(level_id)
		var allowed: Array = LevelCatalog.load_level_data(level_id).get("allowed_rules", [])
		for s in range(100):
			var draw := ArcadeDraw.draw(level_id, sufficient, allowed, s)
			checked += 1
			if not ArcadeSets.is_playable(draw, sufficient):
				unfair.append("%s graine %d → %s" % [level_id, s, str(draw)])
				break
	assert_eq(unfair, PackedStringArray(),
		("Un tirage sans solution ferait perdre des lancements sur un niveau "
		+ "impossible, sans que rien ne le dise. Occurrences : %s") % ", ".join(unfair))
	assert_gt(checked, 0, "aucun tirage examiné : le balayage est cassé")

func test_a_draw_is_reproducible_and_seeds_differ() -> void:
	# Reproductible : un échec doit pouvoir être rejoué et analysé. Distinct :
	# deux niveaux d'une même épreuve doivent recevoir des mains indépendantes,
	# sans quoi la première révélerait les suivantes.
	var sets := ArcadeData.sufficient_sets("ch2_04")
	var allowed: Array = LevelCatalog.load_level_data("ch2_04").get("allowed_rules", [])
	assert_eq(ArcadeDraw.draw("ch2_04", sets, allowed, 7),
		ArcadeDraw.draw("ch2_04", sets, allowed, 7),
		"même graine, même main")
	var a := ArcadeDraw.draw("ch2_04", sets, allowed, 7)
	var b := ArcadeDraw.draw("ch2_05", ArcadeData.sufficient_sets("ch2_05"),
		LevelCatalog.load_level_data("ch2_05").get("allowed_rules", []), 7)
	assert_true(a != b or str(sets) == str(ArcadeData.sufficient_sets("ch2_05")),
		"deux niveaux d'une même épreuve ne doivent pas recevoir la même main par construction")

func test_a_draw_never_offers_a_rule_the_level_forbids() -> void:
	# Une main qui contiendrait une règle hors d'`allowed_rules` proposerait au
	# joueur une tuile que la cascade ignorerait — un mensonge muet.
	var offenders := PackedStringArray()
	for level_id in _ready_levels():
		var allowed: Array = LevelCatalog.load_level_data(level_id).get("allowed_rules", [])
		var as_ints: Array[int] = []
		for r in allowed:
			as_ints.append(int(r))
		for s in range(20):
			for rule_id in ArcadeDraw.draw(level_id, ArcadeData.sufficient_sets(level_id), allowed, s):
				if not as_ints.has(rule_id):
					offenders.append("%s → R%02d" % [level_id, rule_id])
	assert_eq(offenders, PackedStringArray(),
		"règles offertes hors de allowed_rules : %s" % ", ".join(offenders))

# --- l'épreuve elle-même ---------------------------------------------------

func test_a_run_covers_its_whole_chapter_in_order() -> void:
	var run := TrialRun.start(2, 1234)
	assert_gt(run.level_ids.size(), 0, "le chapitre 2 doit avoir des niveaux")
	for id in run.level_ids:
		assert_eq(LevelCatalog.chapter_of(id), 2, "%s n'est pas du chapitre 2" % id)
	assert_eq(run.current_level(), run.level_ids[0], "une épreuve commence au premier niveau")

func test_launches_are_shared_by_the_whole_chapter() -> void:
	# C'EST LE CŒUR DU MODE. Épuiser ses lancements au premier niveau, c'est
	# arriver au deuxième sans rien : la force brute se paie sur la suite, pas
	# sur le niveau où on l'emploie.
	var run := TrialRun.start(2, 1)
	var budget := run.launches_left
	assert_eq(budget, run.level_ids.size() * TrialRun.LAUNCHES_PER_LEVEL,
		"le budget est global, pas par niveau")
	for i in range(budget):
		assert_true(run.spend_launch(), "lancement %d refusé alors qu'il restait du budget" % i)
	assert_false(run.spend_launch(), "un lancement de trop doit être refusé")
	assert_true(run.failed, "l'épreuve est perdue dès qu'un lancement manque")
	assert_true(run.is_finished(), "une épreuve perdue est finie")
	assert_false(run.is_won(), "une épreuve perdue n'est pas gagnée")

func test_a_run_is_won_only_by_finishing_every_level() -> void:
	var run := TrialRun.start(6, 42)
	for i in range(run.level_ids.size()):
		assert_false(run.is_finished(), "l'épreuve ne peut pas finir avant le dernier niveau")
		run.advance()
	assert_true(run.is_won(), "tous les niveaux franchis : épreuve gagnée")

func test_a_run_survives_a_round_trip_through_the_save() -> void:
	# Le contexte est un téléphone que le système tue sans préavis : une épreuve
	# perdue par fermeture serait la pire des injustices, puisqu'elle est
	# précisément le mode où chaque lancement compte.
	var run := TrialRun.start(3, 99)
	run.advance()
	run.spend_launch()
	var back := TrialRun.from_dict(run.to_dict())
	assert_eq(back.chapter, run.chapter)
	assert_eq(back.index, run.index)
	assert_eq(back.launches_left, run.launches_left)
	assert_eq(back.seed_value, run.seed_value)
	assert_eq(back.current_level(), run.current_level(), "la reprise doit rendre le même niveau")
