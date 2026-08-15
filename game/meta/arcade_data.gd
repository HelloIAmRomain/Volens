class_name ArcadeData
extends RefCounted
## Accès à `data/arcade.json` — les ensembles suffisants, calculés hors ligne.
##
## LE JEU NE RECALCULE JAMAIS. Déterminer les ensembles suffisants demande
## d'énumérer et de simuler l'espace entier d'un niveau : trois secondes sur un
## poste de développement, davantage sur un téléphone. Le faire au démarrage
## d'une épreuve donnerait un gel de plusieurs secondes juste avant la première
## interaction — le pire endroit possible.
##
## LE FICHIER EST DÉRIVÉ, DONC IL PEUT MENTIR : un niveau retouché sans
## régénération le rendrait faux, et le tirage proposerait des mains
## injouables. `tests/unit/test_arcade.gd` le recalcule et refuse toute
## divergence. C'est le même dispositif que `calibrated_on` pour les paramètres
## de carte, et pour la même raison — une valeur dérivée non vérifiée finit
## toujours par diverger.

const PATH := "res://data/arcade.json"

static var _levels: Dictionary = {}
static var _loaded: bool = false

## Ensembles suffisants d'un niveau, ou [] s'il est inconnu — auquel cas le
## tirage rendra la bibliothèque entière plutôt qu'une main peut-être injouable.
static func sufficient_sets(level_id: String) -> Array:
	if not _loaded:
		_load()
	var raw: Variant = _levels.get(level_id, [])
	return raw if raw is Array else []

static func _load() -> void:
	_loaded = true
	if not FileAccess.file_exists(PATH):
		print("[arcade] %s absent : le mode Épreuve offrira les bibliothèques complètes" % PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		print("[arcade] %s illisible : repli sur les bibliothèques complètes" % PATH)
		return
	var raw: Variant = (parsed as Dictionary).get("levels", {})
	if raw is Dictionary:
		_levels = raw
