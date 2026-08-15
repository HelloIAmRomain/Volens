extends GutTest
## LE MODE ÉPREUVE MORD-IL ENCORE ?
##
## Un mode de difficulté est une AFFIRMATION sur le catalogue : « chercher au
## hasard coûte plus cher que le budget accordé ». Cette affirmation est vraie
## aujourd'hui et rien ne la retient — un niveau adouci, une règle ajoutée à une
## bibliothèque, et la force brute repasse sous le budget. Le mode continuerait
## alors de s'afficher, de compter ses lancements, et de ne rien exiger.
##
## C'EST LA SIXIÈME FORME DU PIÈGE DE L'INVARIANT 12, sous un autre déguisement.
## Le tirage de règles avait été vérifié sur la seule question confortable —
## « toute main est-elle jouable ? » — à laquelle la réponse était oui. La
## question qui comptait, « la main retire-t-elle jamais quelque chose ? », n'a
## été posée qu'après coup, et la réponse mesurée le 15 août 2026 est **non
## dans 24 niveaux sur 29**. Un mécanisme observé là où il n'a rien à faire
## paraît toujours correct.
##
## Ces tests posent la question inconfortable, et une bonne fois pour toutes.

const GUARD := 400

func _ready_levels_by_chapter() -> Dictionary:
	var out: Dictionary = {}
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var chapter := LevelCatalog.chapter_of(level_id)
		if not out.has(chapter):
			out[chapter] = ([] as Array[String])
		(out[chapter] as Array[String]).append(level_id)
	return out

# --- ce que le mode exige vraiment -----------------------------------------

func test_brute_force_costs_more_than_the_budget_in_every_chapter() -> void:
	# LA RAISON D'ÊTRE DU MODE, rendue opposable. Si la somme des rangs du
	# premier gagnant tient dans le budget, un joueur peut traverser le chapitre
	# entier sans jamais réfléchir — et l'Épreuve n'est plus qu'un compteur
	# décoratif au-dessus du mode normal.
	var by_chapter := _ready_levels_by_chapter()
	assert_gt(by_chapter.size(), 0, "aucun chapitre prêt : le balayage est cassé")
	var toothless := PackedStringArray()
	var examined := 0
	for chapter in by_chapter:
		var levels: Array[String] = by_chapter[chapter]
		var brute := 0
		for level_id in levels:
			var rank := CatalogueSolutions.first_winner_rank(level_id)
			assert_gt(rank, 0, "%s n'a aucune pile gagnante" % level_id)
			brute += rank
		var budget := levels.size() * TrialRun.LAUNCHES_PER_LEVEL
		examined += 1
		if brute <= budget:
			toothless.append("chapitre %d : force brute %d ≤ budget %d" % [
				chapter, brute, budget])
	assert_eq(toothless, PackedStringArray(),
		("Le budget de l'Épreuve n'exige plus rien dans ces chapitres : "
		+ "la force brute y tient dans les lancements accordés. Soit les niveaux "
		+ "ont été adoucis, soit LAUNCHES_PER_LEVEL est trop généreux. %s")
		% ", ".join(toothless))
	assert_eq(examined, by_chapter.size(), "tous les chapitres doivent être examinés")

func test_a_reasoner_still_has_slack() -> void:
	# L'AUTRE BORD, et il compte autant. Un budget qui punit la force brute mais
	# étrangle aussi celui qui raisonne ne trace aucune frontière : il rend le
	# jeu frustrant pour tout le monde. Un joueur qui comprend consomme deux ou
	# trois lancements par niveau — le budget doit lui laisser de la marge.
	var by_chapter := _ready_levels_by_chapter()
	var cramped := PackedStringArray()
	for chapter in by_chapter:
		var levels: Array[String] = by_chapter[chapter]
		var budget := levels.size() * TrialRun.LAUNCHES_PER_LEVEL
		var reasoner := levels.size() * 3
		if budget <= reasoner:
			cramped.append("chapitre %d : budget %d, joueur qui raisonne %d" % [
				chapter, budget, reasoner])
	assert_eq(cramped, PackedStringArray(),
		("Le budget n'accorde plus de marge à un joueur qui raisonne (3 "
		+ "lancements par niveau) : le mode punirait la compréhension. %s")
		% ", ".join(cramped))

# --- ce que le mode N'EXIGE PAS, et pourquoi c'est écrit ici ---------------

func test_the_drawn_hand_is_documented_as_nearly_vacuous() -> void:
	# CE TEST NE CORRIGE RIEN — il empêche un mensonge de se réinstaller.
	#
	# Mesuré le 15 août 2026 : le tirage laisse la bibliothèque INTACTE dans 24
	# niveaux sur 29. La raison est structurelle et non accidentelle : presque
	# chaque niveau n'a **qu'un seul ensemble suffisant minimal**, et cet
	# ensemble contient la règle-moteur du chapitre. Retirer une règle de la
	# main reviendrait à retirer la solution.
	#
	# La conséquence dépasse le mode : un quota par règle — « R01 dans trois
	# niveaux au plus » — serait vide pour exactement la même raison. Le quota
	# le plus serré qui reste satisfaisable vaut la taille du chapitre dans
	# quatre chapitres sur six, c'est-à-dire aucune contrainte. **On ne peut pas
	# restreindre le choix des règles quand il n'y a rien à choisir.**
	#
	# Le jour où les niveaux offriront de vraies solutions alternatives, ce test
	# échouera. Ce sera une bonne nouvelle, et il faudra le réécrire.
	var params := RuleParams.from_dict(_rules_dict())
	var single_solution := 0
	var total := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		total += 1
		if ArcadeData.sufficient_sets(String(entry["id"])).size() <= 1:
			single_solution += 1
	assert_gt(total, 0, "aucun niveau prêt : le balayage est cassé")
	assert_gt(single_solution, total / 2,
		("Bonne nouvelle si ce test échoue : plus de la moitié des niveaux "
		+ "offrent désormais plusieurs ensembles suffisants, donc le tirage et "
		+ "un éventuel quota par règle ont enfin prise. Relire le commentaire "
		+ "ci-dessus et rouvrir la question. (%d niveaux à solution unique sur %d)")
		% [single_solution, total])
	assert_not_null(params, "les paramètres de règles doivent se charger")

func _rules_dict() -> Dictionary:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/rules.json"))
	return parsed if parsed is Dictionary else {}
