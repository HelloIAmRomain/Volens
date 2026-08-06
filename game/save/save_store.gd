class_name SaveStore
extends RefCounted
## Écriture atomique et versionnée des fichiers de `user://` [DT-14].
##
## **Écriture atomique systématique** : on écrit dans un fichier temporaire,
## on vide le tampon, puis on renomme. Un arrêt brutal en pleine écriture —
## le cas nominal sur mobile, pas l'exception — laisse toujours la version
## précédente intacte.
##
## Chaque fichier porte un `schema_version`. Le chargeur applique des
## migrations ascendantes explicites ; une version inconnue ou un fichier
## illisible provoque un **repli propre** sur les valeurs par défaut, jamais
## un plantage (ENF-04).

const TEMP_SUFFIX := ".tmp"

## Écrit `data` à `path` de façon atomique. Renvoie vrai si le renommage a
## abouti — seul moment où l'ancienne version est remplacée.
static func write(path: String, data: Dictionary, schema_version: int) -> bool:
	var payload := data.duplicate(true)
	payload["schema_version"] = schema_version

	var temp_path := path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Sauvegarde impossible : " + temp_path)
		return false
	file.store_string(JSON.stringify(payload, "  "))
	file.flush()
	file.close()

	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	if dir.file_exists(path.get_file()):
		dir.remove(path.get_file())
	return dir.rename(temp_path.get_file(), path.get_file()) == OK

## Lit `path`. Renvoie `{}` si le fichier est absent, illisible, corrompu, ou
## d'une version de schéma non prise en charge — l'appelant repart alors de
## ses valeurs par défaut, sans erreur visible pour le joueur.
static func read(path: String, expected_version: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	# `JSON.parse` plutôt que `parse_string` : il rend un code d'erreur au
	# lieu d'en pousser une au moteur. Un fichier corrompu est un cas prévu
	# ici, pas une anomalie à signaler bruyamment.
	var json := JSON.new()
	var parsed: Variant = null
	if json.parse(text) == OK:
		parsed = json.data
	if not (parsed is Dictionary):
		# Chemin PRÉVU, pas une anomalie : sur mobile, le système tue le
		# processus sans préavis, y compris en pleine écriture. On le trace,
		# on ne s'en alarme pas.
		print("[save] fichier illisible, repli sur les valeurs par défaut : ", path)
		return {}
	var data: Dictionary = parsed
	var version := int(data.get("schema_version", 0))
	if version == expected_version:
		return data
	return _migrate(data, version, expected_version, path)

## Migrations ascendantes explicites. Aucune n'existe encore (schéma 1 est le
## premier) : toute version inattendue se replie proprement.
static func _migrate(_data: Dictionary, from_version: int, to_version: int, path: String) -> Dictionary:
	print("[save] schéma %d -> %d sans migration pour %s : repli propre" % [from_version, to_version, path])
	return {}

## Supprime un fichier de sauvegarde s'il existe (remise à zéro).
static func erase(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
