class_name CatalogueSolutions
extends RefCounted
## L'ESPACE DES SOLUTIONS DE TOUT LE JEU, calculé UNE FOIS par exécution.
##
## POURQUOI CE CACHE EXISTE. Deux tests ont besoin de la même chose — quelles
## piles gagnent quel niveau — et chacun la recalculait de son côté : énumérer
## et simuler l'intégralité du catalogue, deux fois. Mesuré le 15 août 2026 :
## 78 secondes chacun, soit **86 % du temps total de la suite** dépensés deux
## fois pour le même résultat.
##
## Le coût croît avec le catalogue. À vingt-cinq niveaux c'est déjà le poste
## dominant ; à soixante-dix, chaque test approcherait les quatre minutes et la
## suite cesserait d'être lancée à chaque modification — ce qui est la seule
## façon dont une suite de tests meurt vraiment.
##
## DÉTERMINISME : le calcul est pur (mêmes niveaux, mêmes règles, même
## résultat), donc le mettre en cache ne peut rien fausser. C'est exactement la
## propriété que le corpus d'or protège par ailleurs.

const GUARD_TICKS := 400

static var _winners: Dictionary = {}     # level_id -> Array[String] de clés de pile
static var _computed: bool = false

## CACHE SUR DISQUE, CLEFÉ PAR EMPREINTE DES ENTRÉES.
##
## POURQUOI IL A FALLU L'AJOUTER. Le 15 août 2026, les bibliothèques sont
## passées de trois à cinq ou six règles pour rendre au joueur un vrai choix
## (carnet, décision 181). L'espace énuméré est passé de 15 piles à 85-516, et
## la suite de 250 secondes à **1246**. Vingt minutes, c'est le seuil au-delà
## duquel on cesse de lancer les tests à chaque modification — et une suite
## qu'on ne lance plus est une suite morte. Le fichier le disait déjà en
## commentaire ; il fallait l'entendre.
##
## L'EMPREINTE REND LE CACHE SÛR, et c'est la seule raison de s'y fier : elle
## couvre TOUS les fichiers de niveau et `data/rules.json`. Le moindre octet qui
## change invalide le cache et force le recalcul. Le mode de panne d'un cache
## est de servir une réponse périmée sans le dire ; ici il ne peut pas.
##
## Le fichier vit dans `user://` — jamais dans le dépôt, jamais en CI où chaque
## exécution part propre et doit tout recalculer.
const CACHE_PATH := "user://catalogue_solutions.json"

## `level_id` -> Array[String], chaque entrée étant `str(Array[int])`.
static func winners() -> Dictionary:
	if not _computed:
		_compute()
	return _winners

## Nombre de niveaux distincts où la règle apparaît dans au moins une gagnante.
## Les jokers comptent pour leur règle de base (R16), qui est ce qu'EQ-04 mesure.
static func levels_won_with(rule_id: int) -> int:
	var n := 0
	for level_id in winners():
		for key in (winners()[level_id] as Array):
			var stack: Variant = str_to_var(String(key))
			if not (stack is Array):
				continue
			var found := false
			for r in (stack as Array):
				if RuleRegistry.base_rule_id(int(r)) == rule_id:
					found = true
					break
			if found:
				n += 1
				break
	return n

## Rang de la PREMIÈRE pile gagnante dans l'ordre d'exploration naturel, les
## piles vides exclues. C'est le coût de la force brute, en lancements : le
## joueur qui n'essaie pas de comprendre paie ce nombre-là.
##
## Ne simule RIEN — il réutilise les gagnantes déjà en cache et ne refait que
## l'énumération, qui est bon marché. Recalculer aurait doublé le poste le plus
## cher de la suite pour une information déjà présente.
static func first_winner_rank(level_id: String) -> int:
	var won: Array = winners().get(level_id, [])
	var data := LevelCatalog.load_level_data(level_id)
	var allowed: Array[int] = []
	for v in data.get("allowed_rules", []):
		allowed.append(int(v))
	var rank := 0
	for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
		var stack: Array[int] = []
		for v in stack_variant:
			stack.append(int(v))
		if stack.is_empty():
			continue
		rank += 1
		if won.has(str(stack)):
			return rank
	return -1

## Empreinte de TOUT ce dont le résultat dépend. Un seul octet de différence,
## et le cache est jeté : c'est ce qui autorise à s'y fier.
static func _inputs_fingerprint() -> String:
	var payload := FileAccess.get_file_as_string("res://data/rules.json")
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		var path := LevelCatalog.path_of(String(entry["id"]))
		if path.is_empty():
			continue
		payload += String(entry["id"]) + FileAccess.get_file_as_string(path)
	return payload.sha256_text()

static func _load_cache(fingerprint: String) -> bool:
	if not FileAccess.file_exists(CACHE_PATH):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CACHE_PATH))
	if not (parsed is Dictionary):
		return false
	var d: Dictionary = parsed
	if String(d.get("fingerprint", "")) != fingerprint:
		return false
	var raw: Variant = d.get("winners", {})
	if not (raw is Dictionary):
		return false
	_winners = {}
	for level_id in (raw as Dictionary):
		var list: Array[String] = []
		for k in ((raw as Dictionary)[level_id] as Array):
			list.append(String(k))
		_winners[level_id] = list
	return true

static func _save_cache(fingerprint: String) -> void:
	var f := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"fingerprint": fingerprint, "winners": _winners}))
	f.close()

static func _compute() -> void:
	_computed = true
	var fingerprint := _inputs_fingerprint()
	if _load_cache(fingerprint):
		return
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json"))
	var params := RuleParams.from_dict(rules if rules is Dictionary else {})
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var data := LevelCatalog.load_level_data(level_id)
		var allowed: Array[int] = []
		for v in data.get("allowed_rules", []):
			allowed.append(int(v))
		var won: Array[String] = []
		for stack_variant in StackEnumerator.enumerate(allowed, LevelSpec.open_slots(data)):
			var stack: Array[int] = []
			for v in stack_variant:
				stack.append(int(v))
			if _simulate(data, params, stack) == SimState.Outcome.WON:
				won.append(str(stack))
		_winners[level_id] = won
	_save_cache(fingerprint)

static func _simulate(data: Dictionary, params: RuleParams, stack: Array[int]) -> int:
	var state := SimCore.load_level(data, params)
	var guard := 0
	while state.outcome == SimState.Outcome.RUNNING and guard < GUARD_TICKS:
		state = SimCore.step(state, stack)
		guard += 1
	return state.outcome
