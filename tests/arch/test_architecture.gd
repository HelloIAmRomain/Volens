extends GutTest
## Tests d'architecture (T-022) : interdits de dépendance et interdits
## lexicaux, par analyse statique du texte des scripts [DT-03, DT-04].
##
## Les commentaires sont retirés avant analyse (un commentaire a le droit de
## dire « pas de sqrt ») ; les littéraux de chaîne sont préservés mais aucun
## fichier de core/ ne doit de toute façon contenir de chemin res://.

const CORE_DIR := "res://core"
const CORE_SIM_DIR := "res://core/sim"
const TOOLS_DIR := "res://tools"

## Interdits lexicaux dans core/ (invariants n°5-7 docs/ARCHITECTURE.md, DT-04).
## Chaque entrée : [motif RegEx, description du grief].
const CORE_BANS: Array = [
	["\\brandi\\b|\\brandf\\b|\\brandomize\\b|RandomNumberGenerator|\\bshuffle\\b|pick_random", "aléatoire interdit dans core/ (DT-05)"],
	["\\bdelta\\b|get_ticks_msec|get_datetime|\\bTime\\.|\\bOS\\.", "temps réel/horloge interdit dans core/ (DT-06)"],
	["\\bfloat\\b|\\bsqrt\\s*\\(|\\bsin\\s*\\(|\\bcos\\s*\\(|\\bpow\\s*\\(", "flottant/transcendante interdit dans core/ (DT-04)"],
	["\\d\\.\\d", "littéral flottant interdit dans core/ (DT-04)"],
	["\\bpreload\\s*\\(|\\bload\\s*\\(|res://", "core/ ne charge aucune ressource : résolution par class_name uniquement (DT-03)"],
	["FileAccess|DirAccess|\\bJSON\\b", "core/ ne lit aucun fichier : l'appelant charge et transmet (DT-15)"],
	["extends\\s+Node\\b", "core/ est headless : RefCounted uniquement, jamais de nœud (DT-03)"],
]

## core/sim/ n'importe que core/sim/ : aucune référence aux classes de
## core/replay/ (préfixe de nommage réservé Replay*).
const SIM_ONLY_BANS: Array = [
	["\\bReplay[A-Z]", "core/sim/ n'importe pas core/replay/ (règle 2, docs/ARCHITECTURE.md)"],
]

## tools/ n'importe que core/ et data/.
const TOOLS_BANS: Array = [
	["res://game", "tools/ n'importe pas game/ (règle 3, docs/ARCHITECTURE.md)"],
	["res://addons", "tools/ n'importe pas addons/"],
]

func test_core_has_no_banned_lexical_pattern() -> void:
	_assert_dir_clean(CORE_DIR, CORE_BANS)

func test_core_sim_only_imports_core_sim() -> void:
	_assert_dir_clean(CORE_SIM_DIR, SIM_ONLY_BANS)

func test_tools_only_imports_core_and_data() -> void:
	_assert_dir_clean(TOOLS_DIR, TOOLS_BANS)

func test_core_never_references_game() -> void:
	# game/ est vide à ce jour ; ce test verrouille l'avenir : toute classe
	# de game/ devra être préfixée d'un nom jamais utilisé dans core/, et
	# tout chemin res://game y est déjà interdit via le ban res:// global.
	_assert_dir_clean(CORE_DIR, [["res://game|\\bGame[A-Z]", "core/ n'importe jamais game/ (règle 1, docs/ARCHITECTURE.md)"]])

func test_the_scanner_itself_detects_a_violation() -> void:
	# Auto-test du dispositif : le scanner doit détecter un randf() injecté.
	# Sans ce test, un scanner cassé (regex vide, répertoire mal lu) passerait
	# silencieusement au vert pour toujours.
	var violations := _scan_text("var x: int = randf()", "fichier_fictif.gd", CORE_BANS)
	assert_gt(violations.size(), 0, "le scanner doit détecter randf() dans du code nu")
	var clean := _scan_text("## commentaire parlant de randf() et de sqrt(2.0)\nvar x: int = 3", "fichier_fictif.gd", CORE_BANS)
	assert_eq(clean.size(), 0, "les commentaires ne déclenchent pas le scanner : %s" % str(clean))

# --- moteur d'analyse ---------------------------------------------------------

func _assert_dir_clean(dir_path: String, bans: Array) -> void:
	var files := _collect_gd_files(dir_path)
	assert_gt(files.size(), 0, "aucun script trouvé sous %s — chemin cassé ?" % dir_path)
	var all_violations: Array[String] = []
	for file_path in files:
		var source := FileAccess.get_file_as_string(file_path)
		all_violations.append_array(_scan_text(source, file_path, bans))
	assert_eq(all_violations.size(), 0, "violations d'architecture :\n" + "\n".join(all_violations))

func _collect_gd_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path + "/" + entry
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_collect_gd_files(full))
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return out

## Analyse un source débarrassé de ses commentaires ; renvoie une liste de
## griefs « fichier:ligne : motif — grief ».
func _scan_text(source: String, file_path: String, bans: Array) -> Array[String]:
	var violations: Array[String] = []
	var lines := source.split("\n")
	for line_index in range(lines.size()):
		var code := _strip_comment(lines[line_index])
		for ban in bans:
			var regex := RegEx.new()
			regex.compile(ban[0])
			var m := regex.search(code)
			if m != null:
				violations.append("%s:%d : « %s » — %s" % [file_path, line_index + 1, m.get_string(), ban[1]])
	return violations

## Retire la partie commentaire d'une ligne (# hors littéral de chaîne).
func _strip_comment(line: String) -> String:
	var in_string := false
	var quote := ""
	for i in range(line.length()):
		var c := line[i]
		if in_string:
			if c == quote and (i == 0 or line[i - 1] != "\\"):
				in_string = false
		elif c == "\"" or c == "'":
			in_string = true
			quote = c
		elif c == "#":
			return line.substr(0, i)
	return line
