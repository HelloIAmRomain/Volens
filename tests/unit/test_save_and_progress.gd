extends GutTest
## Sauvegarde, progression et session [DT-14, EF-11, EF-20/21].
## Le contexte d'usage est un téléphone tué par le système sans préavis :
## ces tests portent sur ce qui se passe quand l'écriture n'aboutit pas.

const TEST_PATH := "user://test_save_store.json"

func after_each() -> void:
	SaveStore.erase(TEST_PATH)

func test_write_then_read_round_trip() -> void:
	assert_true(SaveStore.write(TEST_PATH, {"a": 1, "b": "deux"}, 1))
	var data := SaveStore.read(TEST_PATH, 1)
	assert_eq(int(data["a"]), 1)
	assert_eq(String(data["b"]), "deux")
	assert_eq(int(data["schema_version"]), 1)

func test_no_temporary_file_survives_a_successful_write() -> void:
	# L'écriture atomique passe par un temporaire puis renomme : si le
	# temporaire subsiste, le renommage n'a pas eu lieu.
	SaveStore.write(TEST_PATH, {"a": 1}, 1)
	assert_false(FileAccess.file_exists(TEST_PATH + SaveStore.TEMP_SUFFIX),
		"le fichier temporaire doit avoir été renommé, pas laissé derrière")

func test_a_corrupted_file_falls_back_cleanly() -> void:
	# Le cas réel : coupure d'alimentation en pleine écriture d'une version
	# antérieure. On repart des valeurs par défaut, jamais un plantage.
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{ceci n'est pas du JSON")
	f.close()

	assert_eq(SaveStore.read(TEST_PATH, 1), {}, "repli propre sur un fichier corrompu")

func test_an_unknown_schema_version_falls_back_cleanly() -> void:
	SaveStore.write(TEST_PATH, {"a": 1}, 99)
	assert_eq(SaveStore.read(TEST_PATH, 1), {}, "aucune migration connue : repli propre")

func test_missing_file_is_not_an_error() -> void:
	assert_eq(SaveStore.read("user://jamais_ecrit.json", 1), {})

# --- progression ---------------------------------------------------------------

func test_progress_keeps_only_the_best_run() -> void:
	var p := Progress.new()
	p.solved = {}
	p.record_win("essai", 40, 2)
	p.record_win("essai", 55, 0)  # moins bon : ne doit pas écraser

	assert_eq(p.best_ticks("essai"), 40, "rejouer moins bien ne détruit pas un record (EF-11)")

	p.record_win("essai", 31, 0)
	assert_eq(p.best_ticks("essai"), 31)
	p.reset()

func test_unsolved_level_reports_no_best() -> void:
	var p := Progress.new()
	assert_false(p.is_solved("ch1_01"))
	assert_eq(p.best_ticks("ch1_01"), -1)

# --- catalogue -----------------------------------------------------------------

func test_every_catalogued_level_is_ready_and_none_is_a_placeholder() -> void:
	# LE NOMBRE N'EST PLUS FIGE — il l'a ete tant que le catalogue s'arretait au
	# chapitre 1, et l'inscrire en dur a coute une journee de rouge le jour ou le
	# chapitre 2 est arrive. Ce qui doit rester vrai n'est pas « il y a cinq
	# niveaux » mais « aucun niveau du catalogue n'est une promesse » : un niveau
	# annonce et non pret est un ecran noir en puissance.
	assert_gt(LevelCatalog.count(), 0, "catalogue vide")
	var not_ready := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			not_ready.append(String(entry["id"]))
	assert_eq(not_ready, PackedStringArray(),
		"niveaux annonces mais non prets : %s" % ", ".join(not_ready))

func test_next_playable_skips_solved_levels() -> void:
	var p := Progress.new()
	assert_eq(LevelCatalog.next_playable(p), "ch1_01")
	p.solved = {"ch1_01": {"ticks": 14, "lost": 0}}
	assert_eq(LevelCatalog.next_playable(p), "ch1_02")

func test_every_ready_level_actually_loads() -> void:
	# Un niveau annoncé prêt et introuvable donnerait un écran noir. La garde
	# vaut pour tout le catalogue, pas pour un identifiant écrit à la main.
	var examined := 0
	for i in range(LevelCatalog.count()):
		var item: Dictionary = LevelCatalog.entry(i)
		if not bool(item["ready"]):
			continue
		examined += 1
		var level_id := String(item["id"])
		assert_ne(LevelCatalog.path_of(level_id), "", "%s : prêt mais sans chemin" % level_id)
		assert_false(LevelCatalog.load_level_data(level_id).is_empty(),
			"%s : prêt mais illisible" % level_id)
	assert_gt(examined, 0, "aucun niveau prêt examiné : le filtre a tout écarté")

func test_an_unknown_level_yields_nothing() -> void:
	# Le repli doit rester propre pour un identifiant qui n'existe pas — une
	# sauvegarde d'une version antérieure, par exemple.
	# Identifiant volontairement impossible : « ch2_01 » servait ici jusqu'a ce
	# que le chapitre 2 existe. Un test dont l'exemple devient valide cesse de
	# tester ce qu'il annonce, sans jamais le dire — meme piege qu'en N7 sur R07.
	assert_eq(LevelCatalog.path_of("ch99_99"), "")
	assert_eq(LevelCatalog.load_level_data("ch99_99"), {})

# --- session -------------------------------------------------------------------

func test_session_round_trip_preserves_the_recipe() -> void:
	var s := Session.new()
	s.level_id = "ch1_02"
	s.stack = [2, 1]
	s.tick = 17
	s.speed_index = 0
	s.save_to_disk()

	var back := Session.load_from_disk()
	assert_eq(back.level_id, "ch1_02")
	assert_eq(back.stack, [2, 1] as Array[int])
	assert_eq(back.tick, 17)
	assert_eq(back.speed_index, 0)
	back.clear()

func test_an_empty_session_is_not_valid() -> void:
	var s := Session.new()
	assert_false(s.is_valid(), "sans niveau, il n'y a rien à reprendre")

func test_session_stores_only_the_recipe_never_the_state() -> void:
	# La recette (niveau, pile, tick) suffit : le déterminisme reconstruit
	# l'état exact. Un fichier qui ne décrit pas d'état ne peut pas décrire
	# un état impossible.
	var s := Session.new()
	s.level_id = "ch1_01"
	s.stack = [1]
	s.tick = 5
	s.save_to_disk()

	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(Session.PATH))
	var keys: Array = (raw as Dictionary).keys()
	keys.sort()
	assert_eq(keys, ["level_id", "schema_version", "speed_index", "stack", "tick"],
		"aucune position d'agent dans le fichier de session")
	s.clear()

# --- défis obtenus, et la migration qui ne perd rien -----------------------
#
# LE FICHIER DE SAUVEGARDE A CHANGÉ DE FORME (schéma 1 -> 2, ajout des défis
# RG-18 obtenus), et c'est le seul changement du dépôt qui puisse détruire
# quelque chose d'irremplaçable : la progression d'un joueur. Le repli propre
# — comportement par défaut sur une version inconnue — l'aurait effacée.
#
# Une migration ÉCRITE vaut donc infiniment mieux que le repli, et ces tests
# la tiennent. Ils valent aussi pour toutes les suivantes : le motif est le
# même, seule la version change.

func test_a_schema_1_save_is_migrated_and_keeps_its_progress() -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"schema_version": 1,
		"solved": {"ch1_01": {"ticks": 14, "lost": 0}},
	}))
	f.close()

	var data := SaveStore.read(TEST_PATH, 2)
	assert_false(data.is_empty(), "une version connue ne doit JAMAIS tomber dans le repli")
	assert_eq(int(((data["solved"] as Dictionary)["ch1_01"] as Dictionary)["ticks"]), 14,
		"la progression du joueur est la seule chose du fichier qui ait de la valeur")
	assert_true(data.has("earned"), "le champ neuf doit exister, vide")

func test_an_unknown_schema_still_falls_back_cleanly() -> void:
	# La migration écrite ne relâche pas la garde : une version qu'on ne
	# connaît pas reste illisible, et deviner vaudrait moins que repartir.
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema_version": 47, "solved": {"x": {}}}))
	f.close()
	assert_eq(SaveStore.read(TEST_PATH, 2), {}, "schéma inconnu : repli propre")

func test_earned_challenges_accumulate_and_are_never_taken_back() -> void:
	# RG-19 : aucun défi ne conditionne rien, donc aucun ne se reprend. Voir un
	# défi s'éteindre parce qu'on a rejoué moins bien punirait le fait de
	# rejouer — exactement ce que le jeu ne doit pas faire (même raison que
	# `best_ticks`, EF-11).
	var p := Progress.new()
	p.record_challenges("essai", PackedStringArray(["Efficience — 20 ticks, seuil 20"]))
	p.record_challenges("essai", PackedStringArray(["Économie — résolu avec 2 règles"]))
	assert_eq(p.earned_challenges("essai").size(), 2, "les deux défis sont conservés")
	p.record_challenges("essai", PackedStringArray(["Économie — résolu avec 2 règles"]))
	assert_eq(p.earned_challenges("essai").size(), 2, "un défi déjà obtenu ne se compte pas deux fois")
	p.reset()

func test_a_level_without_earned_challenges_reports_an_empty_list() -> void:
	var p := Progress.new()
	assert_eq(p.earned_challenges("jamais_joue"), PackedStringArray(),
		"repli propre plutôt qu'une clé absente")

func test_the_summary_and_the_save_compute_the_same_challenges() -> void:
	# UNE SEULE IMPLÉMENTATION, et ce test la tient : `App` enregistre ce que
	# `SummaryScreen` affiche. Deux calculs séparés divergeraient, et le joueur
	# verrait un défi qui ne se conserve pas — ou l'inverse, pire encore.
	var lines := SummaryScreen.challenges_earned("ch1_05", [3, 1], 20)
	assert_gt(lines.size(), 0, "prémisse : cette pile obtient au moins un défi sur N5")
	var p := Progress.new()
	p.record_challenges("ch1_05", lines)
	# L'ENREGISTREMENT TRIE, et c'est voulu : l'ordre d'affichage d'une liste
	# conservée doit être stable d'une session à l'autre, alors que l'ordre
	# d'obtention ne l'est pas. On compare donc les CONTENUS, ce que le test
	# veut dire — et non l'ordre, qu'il n'a jamais voulu dire.
	var shown := lines.duplicate()
	shown.sort()
	assert_eq(p.earned_challenges("ch1_05"), shown,
		"ce qui est affiché est exactement ce qui est enregistré")
	p.reset()
