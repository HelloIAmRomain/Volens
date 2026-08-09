extends GutTest
## DT-22 NE DOIT PAS EXISTER EN PRODUCTION — et ce n'est pas un masquage.
##
## Un écran caché derrière un geste secret finit par être trouvé, et un écran
## de diagnostic dans un jeu épuré est un défaut, pas une discrétion. La
## garantie est donc structurelle : **les fichiers ne sont pas dans le
## paquet**. Ces tests vérifient les trois verrous qui le rendent vrai.

const SELFCHECK_DIR := "res://game/selfcheck"
const PRESETS := "res://export_presets.cfg"

func _all_gd(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path + "/" + entry
		if dir.current_is_dir():
			_all_gd(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()

func test_no_shipped_file_names_the_class_statically() -> void:
	# Verrou n°3, le seul qui protège du démarrage : une build de production
	# sans les fichiers ne doit pas planter. Nommer `SelfCheckScreen` ailleurs
	# créerait une dépendance statique vers une classe absente du paquet.
	var files: Array = []
	_all_gd("res://core", files)
	_all_gd("res://game", files)
	for path in files:
		if path.begins_with(SELFCHECK_DIR):
			continue
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains("SelfCheckScreen"),
			"%s nomme SelfCheckScreen : la build de production ne démarrerait pas" % path)

func test_the_entry_point_is_guarded_by_the_build_flag() -> void:
	var text := FileAccess.get_file_as_string("res://game/ui/settings_screen.gd")
	assert_true(text.contains('OS.has_feature("test_build")'),
		"l'entrée doit être gardée par le drapeau de build, pas par un geste")
	assert_true(text.contains("ResourceLoader.exists"),
		"et par la présence réelle du fichier : le drapeau seul ne suffit pas")

func test_the_production_preset_excludes_the_directory() -> void:
	# Verrou n°1 : les fichiers ne partent pas.
	if not FileAccess.file_exists(PRESETS):
		# Le fichier est hors dépôt sur les postes qui n'exportent pas.
		pending("export_presets.cfg absent de ce poste")
		return
	var text := FileAccess.get_file_as_string(PRESETS)
	assert_true(text.contains("game/selfcheck/*"),
		"le préréglage de production doit exclure game/selfcheck/*")
	assert_true(text.contains("tests/*"),
		"il doit aussi exclure tests/* : sans corpus, l'écran n'aurait rien à vérifier")

func test_the_short_code_is_deterministic_and_readable() -> void:
	# Le code est recopié À LA MAIN par quelqu'un qui ne sait pas ce qu'il
	# transcrit : toute paire ambiguë produirait de faux écarts.
	var a := SelfCheckScreen.short_code(1234567890)
	assert_eq(a, SelfCheckScreen.short_code(1234567890), "déterministe")
	for forbidden in ["O", "0", "I", "1", "S", "5"]:
		assert_false(a.contains(forbidden),
			"le code ne doit contenir aucun caractère ambigu (%s)" % forbidden)

func test_a_single_differing_hash_changes_the_code() -> void:
	# C'est toute l'utilité du code : deux appareils qui divergent d'un bit
	# doivent produire deux codes différents.
	assert_ne(SelfCheckScreen.short_code(1234567890),
		SelfCheckScreen.short_code(1234567891),
		"deux accumulateurs voisins doivent donner deux codes distincts")

func test_the_context_line_carries_model_and_architecture() -> void:
	# « Le hash correspond » sans savoir sur quelle architecture est une
	# donnée orpheline — or c'est exactement l'architecture qu'on cherche à
	# établir (DCT §11.2, A6).
	var line := SelfCheckScreen.context_line()
	assert_gt(line.length(), 0)
	assert_eq(line.split(" · ").size(), 3,
		"modèle · architecture · version du système")
