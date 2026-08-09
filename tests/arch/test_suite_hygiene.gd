extends GutTest
## HYGIÈNE DE LA SUITE — deux contrôles lexicaux, deux récidives.
##
## Ces tests portent sur les tests eux-mêmes. Ils existent parce que deux
## défauts de la suite se sont reproduits après avoir été corrigés une fois, et
## qu'une note n'a protégé de rien ni l'une ni l'autre fois.

const TESTS_DIR := "res://tests"

func _all_gd(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path + "/" + entry
		if dir.current_is_dir():
			_all_gd(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()

# --- 1. `pending()` est banni ----------------------------------------------

## GUT sort en **code 1** sur un test `pending`. La CI passe donc au rouge, et
## un rouge permanent cesse d'être un signal : on apprend à le lire comme du
## bruit, et la vraie régression suivante passe inaperçue.
##
## Deux occurrences, à deux semaines d'intervalle, toutes deux sur un objectif
## non atteint qu'on voulait « garder visible ». La bonne forme existe et elle
## est employée ailleurs dans cette suite : un **cliquet** — on fige le pire
## cas mesuré, on refuse toute aggravation, et l'on exige d'abaisser le seuil
## le jour où la cible est atteinte. Un objectif non tenu reste ainsi nommé,
## sans rendre la suite rouge.
func test_no_test_uses_pending() -> void:
	var files: Array = []
	_all_gd(TESTS_DIR, files)
	assert_gt(files.size(), 0, "aucun fichier de test trouvé — le balayage est cassé")
	var offenders := PackedStringArray()
	for path in files:
		if path == get_script().resource_path:
			continue   # ce fichier NOMME `pending` pour l'interdire
		var text := FileAccess.get_file_as_string(path)
		for line in text.split("\n"):
			var code := String(line).strip_edges()
			if code.begins_with("#"):
				continue
			if code.contains("pending(") and not code.contains("has_pending"):
				offenders.append("%s : %s" % [path.get_file(), code])
	assert_eq(offenders, PackedStringArray(),
		("`pending()` fait sortir GUT en erreur : la CI passe au rouge et cesse "
		+ "d'être un signal. Utiliser un CLIQUET — figer le pire cas mesuré et "
		+ "refuser l'aggravation. Occurrences : %s") % ", ".join(offenders))

# --- 2. Aucun test ne porte sur un fichier hors dépôt -----------------------

## **Un test dont l'objet n'est pas versionné n'est pas un test.** Il est vert
## sur le poste qui possède le fichier, absent partout ailleurs — donc il ne
## prouve rien, tout en donnant l'apparence d'une couverture.
##
## C'est la **cinquième forme** du piège de l'invariant n°12 : après « paraître
## correct clôt l'examen », « paraître cassé clôt l'examen », « un zéro se
## vérifie comme un chiffre inattendu » et « une note ne protège de rien »,
## voici « un test qui ne s'exécute pas nulle part ressemble à un test ».
##
## Le cas rencontré : un contrôle du préréglage d'export, écrit sur
## `export_presets.cfg` — hors dépôt parce qu'il porte des chemins personnels.
## Le bon objet était le modèle versionné `docs/export_presets.cfg.exemple`.
const UNVERSIONED := [
	"res://export_presets.cfg",   # chemins personnels, hors dépôt
	"res://reports/",             # sorties d'outils, ignorées
	"res://build/",               # artefacts d'export, ignorés
	"res://.godot/",              # cache du moteur
]

func test_no_test_targets_an_unversioned_path() -> void:
	var files: Array = []
	_all_gd(TESTS_DIR, files)
	var offenders := PackedStringArray()
	for path in files:
		if path == get_script().resource_path:
			continue   # ce fichier LISTE les chemins interdits
		var text := FileAccess.get_file_as_string(path)
		for forbidden in UNVERSIONED:
			if not text.contains(String(forbidden)):
				continue
			# Une mention dans un commentaire explicatif est légitime ; c'est
			# l'usage comme OBJET du test qui ne l'est pas.
			for line in text.split("\n"):
				var code := String(line).strip_edges()
				if code.begins_with("#") or code.begins_with("##"):
					continue
				if code.contains(String(forbidden)):
					offenders.append("%s → %s" % [path.get_file(), forbidden])
					break
	assert_eq(offenders, PackedStringArray(),
		("Un test dont l'objet n'est pas versionné n'est pas un test : vert ici, "
		+ "absent ailleurs. Viser le fichier VERSIONNÉ équivalent. Occurrences : %s")
		% ", ".join(offenders))

func test_every_resource_path_referenced_by_a_test_exists() -> void:
	# Corollaire du précédent : un chemin versionné mais faux donne un test qui
	# ne vérifie rien non plus, silencieusement.
	var files: Array = []
	_all_gd(TESTS_DIR, files)
	var pattern := RegEx.create_from_string('"(res://[^"]+\\.[a-z]+)"')
	var missing := PackedStringArray()
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for m in pattern.search_all(text):
			var target := m.get_string(1)
			if target.begins_with("res://export_presets"):
				continue   # traité par le test précédent
			if not FileAccess.file_exists(target):
				missing.append("%s → %s" % [path.get_file(), target])
	assert_eq(missing, PackedStringArray(),
		"chemins référencés par un test et introuvables : %s" % ", ".join(missing))
