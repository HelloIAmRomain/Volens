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
## MIGRATIONS CONNUES. Le repli propre reste le comportement par défaut — un
## fichier d'une version inconnue est illisible, et repartir de zéro vaut mieux
## que deviner. Mais une migration ÉCRITE vaut infiniment mieux que le repli :
## elle préserve ce que le joueur a fait, et c'est la seule chose du fichier
## qui ait de la valeur pour lui.
##
## 1 -> 2 : ajout des défis RG-18 obtenus. Purement ADDITIF — `solved` est
## repris tel quel, `challenges` naît vide. Un joueur qui met à jour ne perd
## rien et n'a rien à refaire ; ses défis sont simplement à regagner, ce qui
## est exact puisqu'ils n'avaient jamais été enregistrés.
##
## 2 -> 3 : ajout des éléments de carte déjà présentés au joueur. Additif lui
## aussi — `solved` et `earned` sont repris, `seen` naît vide. Le seul effet est
## de revoir une fois la légende d'éléments déjà connus.
##
## LES MIGRATIONS SE CHAÎNENT, et il faut le dire parce que l'oubli est
## silencieux : un joueur resté en schéma 1 n'aurait trouvé aucune règle
## « 1 -> 3 » et serait tombé dans le repli propre — c'est-à-dire aurait tout
## perdu au moment précis où l'on ajoute une commodité d'affichage. On applique
## donc les étapes l'une après l'autre plutôt que d'écrire une règle par couple.
static func _migrate(data: Dictionary, from_version: int, to_version: int, path: String) -> Dictionary:
	if from_version < to_version and to_version - from_version > 1:
		var stepped := _migrate(data, from_version, from_version + 1, path)
		if stepped.is_empty():
			return {}
		return _migrate(stepped, from_version + 1, to_version, path)
	if from_version == 1 and to_version == 2:
		var out: Dictionary = {"schema_version": 2, "earned": {}}
		out["solved"] = data.get("solved", {})
		print("[save] schéma 1 -> 2 pour %s : progression conservée" % path)
		return out
	if from_version == 2 and to_version == 3:
		var out3: Dictionary = {"schema_version": 3, "seen": []}
		out3["solved"] = data.get("solved", {})
		out3["earned"] = data.get("earned", {})
		print("[save] schéma 2 -> 3 pour %s : progression et défis conservés" % path)
		return out3
	print("[save] schéma %d -> %d sans migration pour %s : repli propre" % [from_version, to_version, path])
	return {}

## LA MIGRATION EST INTERROGEABLE PAR UN TEST, et c'est délibéré. C'est le seul
## code du dépôt dont la panne se paie en données de joueur, et il ne s'exécute
## que chez quelqu'un qui met à jour — donc jamais chez nous, jamais en CI, et
## jamais avant qu'il soit trop tard. Le passer par un fichier sur disque pour
## l'éprouver aurait ajouté une source d'échec sans rien vérifier de plus.
static func migrate_for_test(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	return _migrate(data, from_version, to_version, "test://")

## Supprime un fichier de sauvegarde s'il existe (remise à zéro).
static func erase(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
