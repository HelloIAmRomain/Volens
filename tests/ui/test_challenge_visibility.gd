extends GutTest
## LE JOUEUR DOIT SAVOIR CE QUI EST FAIT, ET CE QU'IL RESTE À FAIRE.
##
## POURQUOI CE FICHIER EXISTE. Deux angles morts signalés à l'essai : « à la fin
## du niveau, ce n'est pas clair quels défis ont été résolus ou non, à la fois en
## général et sur l'exécution actuelle », et « dans le menu, il faudrait pouvoir
## savoir ce qu'il reste à accomplir ».
##
## LES DEUX ÉCRANS DISAIENT UNE MOITIÉ DE LA CHOSE, et pas la même :
##
##   · **Le bilan** ne connaissait que la partie qui venait de finir. Un défi
##     acquis trois parties plus tôt s'y affichait creux, exactement comme un
##     défi jamais obtenu — le joueur repartait le chercher pour rien.
##   · **Le menu** affichait des pastilles ◆◇ qui disent COMBIEN de défis sont
##     acquis, jamais LESQUELS ni ce qu'ils demandent. Un losange creux sans
##     libellé est une énigme sur l'énigme.
##
## CES TESTS PORTENT SUR LA DONNÉE, jamais sur le dessin. C'est la leçon de
## `test_outcome_echo.gd` : une marque que rien n'alimente est invisible ET
## silencieuse, et le code a l'air correct.

const KEY_ECONOMY := "Économie"
const KEY_ABSTINENCE := "Abstinence"

## Un niveau qui propose RÉELLEMENT plusieurs défis — pas un niveau choisi au
## hasard, dont la suite changerait la calibration sans que ce fichier bronche.
const LEVEL := "ch5_09"

func _spec() -> Dictionary:
	return LevelSpec.challenges(LevelCatalog.load_level_data(LEVEL))

func test_the_reference_level_still_offers_two_challenges() -> void:
	# GARDE-FOU DU DÉCOR. Si ch5_09 cessait de proposer ses deux défis, tout ce
	# fichier continuerait de passer au vert en ne vérifiant plus rien.
	var spec := _spec()
	assert_gt(int(spec.get("economy_max", 0)), 0,
		"ch5_09 doit proposer un défi d'économie, sinon ces tests sont creux")
	assert_ne(int(spec.get("abstinence_rule", 0)), 0,
		"ch5_09 doit proposer un défi d'abstinence")

## --- L'écran de bilan : trois états, pas deux ---------------------------------

func test_a_challenge_won_in_this_run_is_marked_earned() -> void:
	# L'économie de ch5_09 vaut 2 : une pile de deux règles l'obtient.
	var states := SummaryScreen.challenge_states(LEVEL, [9, 1], 25)
	var economy := _entry(states, KEY_ECONOMY)
	assert_true(bool(economy["earned"]),
		"une pile de 2 règles doit obtenir l'économie (max %d)"
			% int(_spec().get("economy_max", 0)))

func test_a_challenge_missed_in_this_run_is_not_marked_earned() -> void:
	var states := SummaryScreen.challenge_states(LEVEL, [1, 4, 13], 60)
	var economy := _entry(states, KEY_ECONOMY)
	assert_false(bool(economy["earned"]),
		"une pile de 3 règles ne peut pas obtenir « 2 règles au plus »")

func test_only_the_challenges_won_now_are_recorded() -> void:
	# CE QU'ON ENREGISTRE NE DOIT PAS ENFLER. `challenges_earned` alimente la
	# sauvegarde ; y faire entrer un défi non obtenu l'offrirait pour toujours,
	# et aucun écran ne le démentirait ensuite.
	# L'ASSERTION PORTE SUR L'ENSEMBLE, PAS SUR CHAQUE LIGNE. Une boucle sur une
	# collection vide n'assertionne rien et passe au vert sans le dire — et le
	# jour où elle se vide est justement celui où plus personne ne cherche.
	var recorded := ", ".join(SummaryScreen.challenges_earned(LEVEL, [1, 4, 13], 60))
	assert_false(recorded.contains(KEY_ECONOMY),
		"l'économie n'était pas obtenue et ne doit pas être enregistrée : « %s »" % recorded)

func test_the_summary_distinguishes_already_acquired_from_just_earned() -> void:
	# LE CŒUR DU CORRECTIF. Une partie qui n'obtient PAS l'économie, alors
	# qu'elle avait été acquise avant, doit malgré tout la montrer comme acquise
	# — sinon le joueur la croit perdue et repart la chercher.
	var already := PackedStringArray(["%s — 2 règles au plus" % KEY_ECONOMY])
	var screen := SummaryScreen.new()
	add_child_autofree(screen)
	screen.setup(LEVEL, true, 60, 2, [1, 4, 13], "", already)
	var texts := _labels(screen)

	var acquired := false
	for t in texts:
		if t.contains("déjà acquis"):
			acquired = true
	assert_true(acquired,
		("un défi acquis lors d'une partie précédente doit être signalé comme tel ; "
		+ "libellés vus : %s") % ", ".join(texts))

func test_a_challenge_never_earned_shows_neither_mention() -> void:
	# L'AUTRE BORD : sans historique, aucune mention ne doit apparaître, sans
	# quoi tout défi passerait pour acquis et la distinction serait décorative.
	var screen := SummaryScreen.new()
	add_child_autofree(screen)
	screen.setup(LEVEL, true, 60, 2, [1, 4, 13], "", PackedStringArray())
	var texts := _labels(screen)
	# L'ÉCRAN DOIT AVOIR AFFICHÉ QUELQUE CHOSE avant qu'on se réjouisse de ne
	# pas y trouver la mention : sur un écran vide, l'absence ne prouve rien.
	assert_gt(texts.size(), 0, "l'écran de bilan n'a affiché aucun libellé")
	assert_false(", ".join(texts).contains("déjà acquis"),
		"aucun défi n'était acquis : « déjà acquis » ne doit pas s'afficher")

## --- Le menu : ce qui RESTE, nommé --------------------------------------------

func test_the_menu_names_what_is_left_to_do() -> void:
	var remaining := LevelSelectScreen._remaining_challenges(_spec(), PackedStringArray())
	assert_gt(remaining.size(), 0,
		"aucun défi acquis : le menu doit nommer ce qui reste")
	# LE LIBELLÉ DOIT DIRE CE QU'IL FAUT FAIRE, pas comment le défi s'appelle.
	# « Abstinence » ne renseigne personne ; « sans “Suivre la piste” » se joue.
	var speaks := false
	for line in remaining:
		if line.contains("règle") or line.contains("sans «") or line.contains("ticks"):
			speaks = true
	assert_true(speaks,
		"le restant doit énoncer la CONDITION, pas le nom du défi : %s" % ", ".join(remaining))

func test_an_acquired_challenge_leaves_the_remaining_list() -> void:
	var earned := PackedStringArray(["%s — 2 règles au plus" % KEY_ECONOMY])
	var remaining := ", ".join(LevelSelectScreen._remaining_challenges(_spec(), earned))
	assert_false(remaining.contains("règle"),
		"l'économie est acquise : elle ne doit plus figurer dans le restant (« %s »)" % remaining)
	# ET L'AUTRE DÉFI DOIT SURVIVRE. Sans cette moitié, une fonction qui rendrait
	# toujours une liste vide passerait le test — ce qui est exactement le défaut
	# qu'on prétend surveiller.
	assert_true(remaining.contains("sans «"),
		"l'abstinence n'est pas acquise : elle doit rester annoncée (« %s »)" % remaining)

func test_a_fully_completed_level_shows_nothing() -> void:
	# LE SILENCE EST LA RÉCOMPENSE. Une liste qui continue de réclamer après
	# qu'on a tout fait transforme un niveau fini en dette (RG-19).
	var earned := PackedStringArray([
		"%s — 2 règles au plus" % KEY_ECONOMY,
		"%s — sans quelque chose" % KEY_ABSTINENCE,
	])
	assert_eq(LevelSelectScreen._remaining_challenges(_spec(), earned), PackedStringArray(),
		"tous les défis acquis : le menu ne doit plus rien réclamer")

## --- Outillage ----------------------------------------------------------------

func _entry(states: Array, key: String) -> Dictionary:
	for e in states:
		if String(e["key"]) == key:
			return e
	fail_test("défi « %s » absent de ch5_09" % key)
	return {}

## Tous les textes de Label de l'arbre — on interroge ce que le joueur LIT,
## sans dépendre de la structure exacte des conteneurs, qui change au gré des
## retouches de mise en page.
func _labels(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	if node is Label:
		out.append((node as Label).text)
	for child in node.get_children():
		out.append_array(_labels(child))
	return out
