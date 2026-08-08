class_name Settings
extends RefCounted
## Réglages du joueur. Fichier PROPRE, avec son propre `schema_version` :
## on n'ajoute pas un champ à `progress.json` pour éviter d'avoir à migrer un
## format qui, lui, porte des données que le joueur ne veut pas perdre.
##
## Aucune donnée personnelle, aucune transmission (ENF-30/31).

const PATH := "user://settings.json"
const SCHEMA_VERSION := 1

## ENF-24 : le retour haptique est actif par défaut et coupable à tout moment.
var haptics: bool = true
## ENF-23 : mouvement réduit. Déjà honoré par les shaders (`reduced_motion`).
var reduced_motion: bool = false

static func load_from_disk() -> Settings:
	var s := Settings.new()
	var data := SaveStore.read(PATH, SCHEMA_VERSION)
	s.haptics = bool(data.get("haptics", true))
	s.reduced_motion = bool(data.get("reduced_motion", false))
	s.apply()
	return s

func save_to_disk() -> void:
	SaveStore.write(PATH, {"haptics": haptics, "reduced_motion": reduced_motion}, SCHEMA_VERSION)

## Propage aux consommateurs qui n'ont pas de raison de connaître la sauvegarde.
func apply() -> void:
	Haptics.enabled = haptics

func set_haptics(value: bool) -> void:
	haptics = value
	apply()
	save_to_disk()
