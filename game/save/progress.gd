class_name Progress
extends RefCounted
## Progression du joueur : niveaux résolus et meilleure performance.
## Aucune donnée personnelle, aucune transmission (ENF-30/31).

const PATH := "user://progress.json"
## 2 depuis le 14 août 2026 : les défis RG-18 obtenus sont conservés. La
## migration 1 -> 2 est écrite et préserve `solved` (voir `SaveStore._migrate`).
const SCHEMA_VERSION := 2

## id de niveau -> { "ticks": int, "lost": int } de la MEILLEURE résolution.
var solved: Dictionary = {}

## id de niveau -> Array[String] des défis RG-18 obtenus, jamais retirés.
##
## LE CHAMP S'APPELLE `earned`, PAS `challenges`, et le nom est délibéré. Un
## niveau porte lui aussi un bloc `challenges` — ce qu'il PROPOSE — et le
## contrôle lexical de l'invariant n°16 refuse toute lecture de ce nom hors de
## `LevelSpec`. Deux concepts distincts qui partagent un nom finissent toujours
## par être confondus ; ici le garde-fou l'a signalé avant moi.
##
## Ce que le niveau PROPOSE se lit par `LevelSpec.challenges()`.
## Ce que le joueur a OBTENU se lit ici.
##
## ILS S'ACCUMULENT ET NE SE PERDENT PAS. Un joueur qui rejoue moins bien ne
## doit pas voir un défi s'éteindre : ce serait punir le fait de rejouer,
## exactement ce que RG-19 interdit — aucun défi ne conditionne rien, donc
## aucun ne se reprend. Même raison que pour `best_ticks` (EF-11).
var earned: Dictionary = {}

static func load_from_disk() -> Progress:
	var p := Progress.new()
	var data := SaveStore.read(PATH, SCHEMA_VERSION)
	var raw: Dictionary = data.get("solved", {})
	for key in raw:
		p.solved[String(key)] = raw[key]
	var raw_earned: Dictionary = data.get("earned", {})
	for key in raw_earned:
		var names := PackedStringArray()
		for n in (raw_earned[key] as Array):
			names.append(String(n))
		p.earned[String(key)] = names
	return p

func save_to_disk() -> void:
	SaveStore.write(PATH, {"solved": solved, "earned": earned}, SCHEMA_VERSION)

func is_solved(level_id: String) -> bool:
	return solved.has(level_id)

func best_ticks(level_id: String) -> int:
	if not solved.has(level_id):
		return -1
	return int((solved[level_id] as Dictionary).get("ticks", -1))

## N'enregistre que si c'est mieux : le joueur ne perd jamais un record en
## rejouant moins bien (EF-11).
func record_win(level_id: String, ticks: int, lost: int) -> void:
	var previous := best_ticks(level_id)
	if previous == -1 or ticks < previous:
		solved[level_id] = {"ticks": ticks, "lost": lost}
		save_to_disk()

## Enregistre les défis obtenus lors d'une partie. Union, jamais remplacement.
func record_challenges(level_id: String, just_earned: PackedStringArray) -> void:
	if just_earned.is_empty():
		return
	var known: PackedStringArray = earned.get(level_id, PackedStringArray())
	var changed := false
	for name in just_earned:
		if not known.has(name):
			known.append(name)
			changed = true
	if not changed:
		return
	known.sort()
	earned[level_id] = known
	save_to_disk()

func earned_challenges(level_id: String) -> PackedStringArray:
	return earned.get(level_id, PackedStringArray())

func reset() -> void:
	solved = {}
	earned = {}
	SaveStore.erase(PATH)
