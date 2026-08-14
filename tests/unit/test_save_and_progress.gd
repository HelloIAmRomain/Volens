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

func test_catalog_exposes_five_levels_all_of_them_ready() -> void:
	assert_eq(LevelCatalog.count(), 5, "le chapitre 1 compte cinq niveaux")
	var ready := 0
	for i in range(LevelCatalog.count()):
		if bool(LevelCatalog.entry(i)["ready"]):
			ready += 1
	assert_eq(ready, 5, "le chapitre 1 est complet : les cinq niveaux sont conçus et validés")

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
	assert_eq(LevelCatalog.path_of("ch2_01"), "")
	assert_eq(LevelCatalog.load_level_data("ch2_01"), {})

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
