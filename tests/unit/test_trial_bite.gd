extends GutTest
## LE MODE ÉPREUVE MORD-IL ENCORE ?
##
## Un mode de difficulté est une AFFIRMATION sur le catalogue : « chercher au
## hasard coûte plus cher que le budget accordé ». Cette affirmation est vraie
## aujourd'hui et rien ne la retient — un niveau adouci, une règle ajoutée à une
## bibliothèque, et la force brute repasse sous le budget. Le mode continuerait
## alors de s'afficher, de compter ses lancements, et de ne rien exiger.
##
## C'EST LA HUITIÈME FORME DU PIÈGE DE L'INVARIANT 12. Le tirage de règles avait
## été vérifié sur la seule question confortable — « toute main est-elle
## jouable ? » — à laquelle la réponse était oui. La question qui comptait,
## « la main retire-t-elle jamais quelque chose ? », n'a été posée qu'après
## coup, et la réponse était **non dans 24 niveaux sur 29**. Un mécanisme
## observé là où il n'a rien à faire paraît toujours correct.
##
## Le défaut était dans les NIVEAUX, pas dans le mode : leurs bibliothèques
## comptaient trois règles pour trois rangs, donc rien à retirer. Élargies à
## cinq ou six le 15 août 2026, le tirage retire désormais 1 à 3 règles dans
## vingt niveaux sur vingt-neuf. Les tests ci-dessous refusent le retour.
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

func test_only_cleared_chapters_are_offered() -> void:
	# Le mode punit la recherche, jamais l'ignorance : une épreuve sur un
	# chapitre qu'on n'a pas fini échouerait sur des niveaux qu'on n'a pas
	# encore compris.
	var progress := Progress.new()
	assert_eq(TrialSelectScreen.cleared_chapters(progress), ([] as Array[int]),
		"une progression vierge n'ouvre aucune épreuve")
	var chapters := LevelCatalog.chapters()
	assert_gt(chapters.size(), 0, "le catalogue doit avoir des chapitres")
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if bool(entry["ready"]) and LevelCatalog.chapter_of(String(entry["id"])) == chapters[0]:
			progress.record_win(String(entry["id"]), 20, 0)
	assert_eq(TrialSelectScreen.cleared_chapters(progress), ([chapters[0]] as Array[int]),
		"le premier chapitre résolu, et lui seul, doit être offert")

func test_cleared_chapters_tolerates_a_null_progress() -> void:
	# L'écran est construit avant que la progression ne soit sûrement chargée
	# dans le harnais de captures ; un plantage y serait invisible en test.
	assert_eq(TrialSelectScreen.cleared_chapters(null), ([] as Array[int]))

# --- ce que le mode N'EXIGE PAS, et pourquoi c'est écrit ici ---------------

func test_the_drawn_hand_actually_removes_something() -> void:
	# LA QUESTION QUI COMPTE, et elle n'avait pas été posée : le tirage retire-t-il
	# jamais quelque chose ? Il ne retirait rien dans 24 niveaux sur 29 tant que
	# les bibliothèques faisaient trois règles. Elles en font cinq ou six depuis
	# le 15 août 2026, et ce test refuse qu'on y revienne.
	#
	# Les chapitres 1 et 2 sont EXEMPTÉS : ils enseignent, et leur étroitesse est
	# le moyen. Ailleurs, une main qui vaut la bibliothèque entière est un
	# mécanisme décoratif.
	var inert := PackedStringArray()
	var examined := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		if LevelCatalog.chapter_of(level_id) <= 2:
			continue
		var allowed: Array = LevelCatalog.load_level_data(level_id).get("allowed_rules", [])
		var sets := ArcadeData.sufficient_sets(level_id)
		var widest := 0
		for s in range(40):
			widest = maxi(widest, ArcadeDraw.draw(level_id, sets, allowed, s).size())
		examined += 1
		if widest >= allowed.size():
			inert.append("%s (main %d = bibliothèque %d)" % [level_id, widest, allowed.size()])
	assert_gt(examined, 0, "aucun niveau examiné : le balayage est cassé")
	assert_eq(inert, PackedStringArray(),
		("Le tirage ne retire rien sur ces niveaux : il y est décoratif. "
		+ "Élargir leur bibliothèque, ou cesser de compter le tirage comme un "
		+ "ingrédient du mode. %s") % ", ".join(inert))

func test_several_levels_offer_genuinely_different_ideas() -> void:
	# CE QUE LE TIRAGE ET UN EVENTUEL QUOTA EXIGENT POUR AVOIR PRISE : que les
	# niveaux aient plus d'une IDEE gagnante. Le 15 août 2026 au matin, quatre
	# niveaux sur vingt-neuf en avaient plusieurs, et c'est pourquoi toute
	# mecanique de restriction etait condamnee d'avance — on ne restreint pas un
	# choix qui n'existe pas.
	#
	# L'elargissement des bibliotheques (carnet, decision 181) a porte ce nombre
	# a neuf. Le seuil ci-dessous est bas EXPRES : il ne celebre pas un resultat,
	# il interdit un retour en arriere.
	var multi := PackedStringArray()
	var total := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		total += 1
		var level_id := String(entry["id"])
		if ArcadeData.sufficient_sets(level_id).size() > 1:
			multi.append(level_id)
	assert_gt(total, 0, "aucun niveau prêt : le balayage est cassé")
	assert_gte(multi.size(), 8,
		("Trop peu de niveaux offrent plusieurs manières de gagner (%d sur %d) : "
		+ "le jeu redevient une suite de serrures à une clé. Niveaux concernés : %s")
		% [multi.size(), total, ", ".join(multi)])
