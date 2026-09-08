class_name SelfCheckScreen
extends Control
## DT-22 — écran d'auto-vérification d'empreinte. **N'existe que dans les
## builds de test**, jamais en production (voir `game/selfcheck/README.md`).
##
## CE QU'IL REMPLACE. La vérification du déterminisme demande deux
## architectures CPU distinctes (DCT §11.2, A6) : x86_64 est couvert par la CI
## et l'émulateur, arm64 par le seul appareil de référence. Le parc de testeurs
## du test fermé — recruté de toute façon pour l'obligation Google Play —
## fournit la diversité arm64 réelle, **sans acheter un second appareil**.
##
## ENF-30 TIENT, ET C'EST LA CONDITION QUI A FAIT CHOISIR CE DISPOSITIF : le
## testeur **recopie à la main** un code court dans le canal de retour convenu.
## Aucune transmission automatique, aucune permission, aucun réseau.
##
## TROIS CHOIX DE CONCEPTION, chacun pour une raison précise.
##
## 1. **L'écran tranche lui-même.** Le testeur ne connaît pas la valeur
##    attendue : lui demander de comparer un code à rien serait lui demander
##    l'impossible. Les empreintes de référence étant dans la build, l'écran
##    affiche « CONFORME » ou « ÉCART DÉTECTÉ ». Le code recopié ne sert qu'au
##    diagnostic, et n'est vraiment utile qu'en cas d'écart.
##
## 2. **Le code porte son contexte.** « Le hash correspond » sans savoir sur
##    quel modèle, quelle architecture et quelle version d'Android est une
##    donnée orpheline. Modèle et architecture sont affichés à côté du code et
##    recopiés avec lui : deux mots de plus pour le testeur, et la différence
##    entre une information et un chiffre inutilisable.
##
## 3. **Le rejeu est étalé sur plusieurs images.** Trente recettes de trois
##    cents ticks bloqueraient l'interface plusieurs secondes — sur Android, un
##    gel de cette durée déclenche le dialogue « l'application ne répond
##    plus ». Une recette par image, avec progression visible.

signal back_requested

## Alphabet du code court : ni O ni 0, ni I ni 1, ni S ni 5. Le code est
## recopié À LA MAIN par quelqu'un qui ne sait pas ce qu'il transcrit —
## toute paire ambiguë finirait par produire un faux écart.
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRTUVWXYZ2346789"
const CODE_LENGTH := 8

const GOLDEN_PATH := "res://tests/golden/golden.json"
const RULES_PATH := "res://data/rules.json"

var _recipes: Array = []
var _checkpoints: Array = []
var _params: RuleParams
var _index: int = 0
var _mismatches: Array[String] = []
var _accumulator: int = StateHash.OFFSET_BASIS

var _title: Label
var _progress: Label
var _verdict: Label
var _code: Label
var _context: Label
var _detail: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_load_corpus()
	set_process(true)

func _build() -> void:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE, int(UiMetrics.MARGIN))

	_title = _label(TranslationServer.translate("ui.selfcheck.title"), 40, ViewPalette.AGENT_PLAIN)
	column.add_child(_title)
	_progress = _label(TranslationServer.translate("ui.selfcheck.preparing"), 26, Color(0.55, 0.60, 0.72))
	column.add_child(_progress)
	column.add_child(_spacer(UiMetrics.GAP))
	_verdict = _label("", 44, ViewPalette.AGENT_PLAIN)
	column.add_child(_verdict)
	_code = _label("", 56, ViewPalette.AGENT_PLAIN)
	column.add_child(_code)
	_context = _label("", 26, Color(0.78, 0.83, 0.93))
	column.add_child(_context)
	column.add_child(_spacer(UiMetrics.GAP))
	_detail = _label("", 22, Color(0.55, 0.60, 0.72))
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_detail)

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grow)
	var back := UiButtons.make(TranslationServer.translate("ui.back3"))
	back.pressed.connect(func() -> void: back_requested.emit())
	column.add_child(back)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

func _load_corpus() -> void:
	var golden: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	if not (golden is Dictionary) or not (rules is Dictionary):
		_progress.text = TranslationServer.translate("ui.selfcheck.no_corpus")
		set_process(false)
		return
	_recipes = (golden as Dictionary).get("recipes", [])
	_checkpoints = (golden as Dictionary).get("checkpoints", [50, 150, 300])
	_params = RuleParams.from_dict(rules)

## Une recette par image : sur Android, trente rejeux d'affilée gèlent
## l'interface assez longtemps pour déclencher « l'application ne répond plus ».
func _process(_delta: float) -> void:
	if _index >= _recipes.size():
		_finish()
		set_process(false)
		return
	_verify(_recipes[_index])
	_index += 1
	_progress.text = "%d / %d recettes" % [_index, _recipes.size()]

func _verify(recipe: Dictionary) -> void:
	var level_path := String(recipe["level"])
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(level_path))
	if not (parsed is Dictionary):
		_mismatches.append("%s : niveau absent" % level_path.get_file())
		return
	var got := RecipeRunner.run(parsed as Dictionary, _params, recipe["stack"], _checkpoints)
	var expected: Dictionary = recipe.get("hashes", {})
	for key in got:
		var value := String(got[key])
		# L'accumulateur absorbe TOUTES les empreintes obtenues, dans l'ordre
		# du corpus : deux appareils qui divergent d'un seul bit produisent
		# deux codes différents.
		for b in value.to_utf8_buffer():
			_accumulator = StateHash.feed_int(_accumulator, b)
		if String(expected.get(key, "")) != value:
			_mismatches.append("%s %s @t=%s" % [
				level_path.get_file().get_basename(), str(recipe["stack"]), key])

func _finish() -> void:
	_progress.text = TranslationServer.translate("ui.selfcheck.replayed") % _recipes.size()
	_code.text = short_code(_accumulator)
	_context.text = context_line()

	if _mismatches.is_empty():
		_verdict.text = TranslationServer.translate("ui.selfcheck.ok")
		_verdict.add_theme_color_override("font_color", ViewPalette.EXIT)
		_detail.text = (TranslationServer.translate("ui.selfcheck.identical") + "\n"
			+ TranslationServer.translate("ui.selfcheck.copy"))
	else:
		_verdict.text = TranslationServer.translate("ui.selfcheck.mismatch")
		_verdict.add_theme_color_override("font_color", ViewPalette.DANGER)
		var head := PackedStringArray()
		for i in range(mini(_mismatches.size(), 4)):
			head.append(_mismatches[i])
		_detail.text = ("%d recette(s) divergent : %s%s\n"
			+ "Recopiez le code ET les deux lignes au-dessus : c'est ce qui rend "
			+ "l'écart diagnosticable.") % [
				_mismatches.size(), ", ".join(head),
				"…" if _mismatches.size() > 4 else ""]

## Code court dérivé de l'accumulateur. Déterministe, sans caractère ambigu.
static func short_code(accumulator: int) -> String:
	var alphabet := CODE_ALPHABET
	var n: int = alphabet.length()
	var out := ""
	var h: int = accumulator
	for i in range(CODE_LENGTH):
		# `& 0x7FFFFFFF` écarte le bit de signe : un modulo sur un entier
		# négatif donnerait un index négatif et un code illisible.
		out += alphabet[(h & 0x7FFFFFFF) % n]
		h = (h >> 5) ^ (h << 7)
		if i == 3:
			out += "-"   # un tiret au milieu : on recopie mieux par groupes
	return out

## Modèle, architecture, version du système. Sans eux, « le hash correspond »
## est une donnée orpheline : on ne saurait pas de quelle architecture provient
## la confirmation, et c'est précisément ce qu'on cherche à établir.
static func context_line() -> String:
	var arch := "arm64" if OS.has_feature("arm64") else (
		"x86_64" if OS.has_feature("x86_64") else "arch inconnue")
	var model := OS.get_model_name()
	if model.is_empty():
		model = OS.get_name()
	return "%s · %s · %s" % [model, arch, OS.get_version()]
