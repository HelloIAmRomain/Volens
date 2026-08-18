class_name Progress
extends RefCounted
## Progression du joueur : niveaux résolus et meilleure performance.
## Aucune donnée personnelle, aucune transmission (ENF-30/31).

const PATH := "user://progress.json"
## 2 depuis le 14 août 2026 : les défis RG-18 obtenus sont conservés. La
## migration 1 -> 2 est écrite et préserve `solved` (voir `SaveStore._migrate`).
##
## 3 depuis le 18 août 2026 : les éléments de carte déjà présentés au joueur.
## Migration 2 -> 3 purement ADDITIVE — `solved` et `earned` sont repris tels
## quels, `seen` naît vide. Le seul effet pour un joueur qui met à jour est de
## revoir une fois la légende d'éléments qu'il connaît déjà : c'est le prix le
## plus bas possible, et il est payé une seule fois.
const SCHEMA_VERSION := 3

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

## Clés des éléments de carte déjà présentés (voir `MechanicPrimer`).
##
## POURQUOI C'EST DANS LA PROGRESSION ET NON DANS LES RÉGLAGES. Ce n'est pas une
## préférence, c'est un fait sur la partie : « ce joueur a déjà rencontré la
## bascule ». Une remise à zéro de la progression doit donc l'effacer aussi —
## sinon un joueur qui recommence tout traverserait le jeu sans jamais revoir
## une seule légende, et le chapitre 4 lui tomberait dessus sans un mot.
var seen: PackedStringArray = PackedStringArray()

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
	for k in (data.get("seen", []) as Array):
		p.seen.append(String(k))
	return p

func save_to_disk() -> void:
	SaveStore.write(PATH, {"solved": solved, "earned": earned, "seen": seen},
		SCHEMA_VERSION)

## Marque des éléments comme déjà présentés. Union, jamais remplacement — et
## jamais de retrait : une légende revue n'apprend rien, elle interrompt.
func mark_seen(keys: PackedStringArray) -> void:
	var changed := false
	for k in keys:
		if not seen.has(k):
			seen.append(k)
			changed = true
	if changed:
		save_to_disk()

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
	# LES LÉGENDES REPARTENT AVEC LE RESTE. Un joueur qui recommence tout
	# traverserait sinon le jeu sans en revoir une seule, et le chapitre 4 lui
	# tomberait dessus sans un mot — le champ serait resté en mémoire alors que
	# tout ce qu'il documentait a disparu.
	seen = PackedStringArray()
	SaveStore.erase(PATH)
