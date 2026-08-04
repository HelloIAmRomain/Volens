class_name GoldenRunner
extends RefCounted
## Coureur partagé des recettes d'or (T-021, DCT §11.2) : utilisé par le
## test GUT (tests/golden/test_golden.gd) et par le script autonome
## (tools/check_golden.gd) — une seule implémentation, pas deux vérités.
##
## tools/ n'importe que core/ et data/ (règle 3, docs/ARCHITECTURE.md) ; c'est ici que
## les JSON sont lus, jamais dans core/sim/.

const RULES_PATH := "res://data/rules.json"
const GOLDEN_PATH := "res://tests/golden/golden.json"

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Fichier introuvable : " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		push_error("JSON invalide : " + path)
		return {}
	return parsed

## Rejoue une recette et renvoie les empreintes hexadécimales aux ticks
## demandés : { "50": "…", "150": "…", "300": "…" }. Les points de contrôle
## doivent être croissants. La simulation continue après un outcome décidé
## (l'état terminal reste stable, son empreinte aussi — c'est voulu : la
## stabilité post-terminale fait partie du contrat).
static func run_recipe(level_path: String, stack_raw: Array, checkpoints: Array) -> Dictionary:
	var level_data := load_json(level_path)
	var rules_data := load_json(RULES_PATH)
	if level_data.is_empty() or rules_data.is_empty():
		return {}

	var stack: Array[int] = []
	for v in stack_raw:
		stack.append(int(v))

	var state := SimCore.load_level(level_data, RuleParams.from_dict(rules_data))
	var out: Dictionary = {}
	var last_tick: int = 0
	for cp in checkpoints:
		var target := int(cp)
		while last_tick < target:
			state = SimCore.step(state, stack)
			last_tick += 1
		out[str(target)] = StateHash.to_hex(SimCore.hash_state(state))
	return out
