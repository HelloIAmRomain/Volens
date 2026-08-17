extends GutTest
## LA LISTE DES PERMISSIONS EST CLOSE, ET C'EST PLUS FORT QUE DE LES INTERDIRE.
##
## HISTOIRE DE CE FICHIER. Le projet s'interdisait TOUTE permission — « le jeu
## est hors ligne, sans permission et sans collecte de données ». L'intention
## était la vie privée. L'effet, lui, était que le retour haptique (ENF-24)
## était **entièrement implémenté et totalement inerte** : Android exige
## `android.permission.VIBRATE` pour accéder au vibreur, et sans elle
## `Input.vibrate_handheld()` ne fait rien et ne signale rien. Neuf appels, un
## module réglé au millième de seconde, et pas une vibration en des mois.
##
## MESURÉ SUR L'APPAREIL avant de trancher (Galaxy S22 Ultra, 17 août 2026) :
##
##   · absente de `pm list permissions -d` — elle n'est pas de niveau dangereux ;
##   · `dumpsys package` la donne `granted=true` dès l'installation : aucune
##     boîte de dialogue, aucun consentement demandé, rien à refuser ;
##   · aucun accès à des données, à un capteur ni au réseau ;
##   · avec elle, `VibratorManagerService` journalise bien la vibration.
##
## **L'interdiction ne servait donc pas son objet.** Elle protégeait la vie
## privée en n'empêchant aucune collecte, et coûtait une exigence du CDC.
##
## CE QUI LA REMPLACE EST PLUS STRICT, PAS PLUS LÂCHE : une liste CLOSE et
## VERSIONNÉE. Une permission de plus doit y être écrite avec sa justification,
## et ce fichier refuse tout ce qui touche au réseau. L'interdiction générale,
## elle, ne tenait que par la discipline de qui relisait un fichier hors dépôt.
##
## POURQUOI LA LISTE N'EST PAS DANS `export_presets.cfg`. Ce fichier n'est pas
## versionné : la seule chose qui décide de ce à quoi l'application accède
## échappait au dépôt, à la relecture et à la CI. Un garde-fou de la suite a
## refusé un test qui l'aurait lu — « un test dont l'objet n'est pas versionné
## n'est pas un test : vert ici, absent ailleurs ». Il avait raison deux fois :
## la liste devait être versionnée, et la conformité du fichier de build est une
## affaire de BUILD, vérifiée dans le paquet produit (voir docs/ARCHITECTURE.md, export).

const LIST := "res://data/android_permissions.json"

func _list() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LIST))
	return parsed if parsed is Dictionary else {}

func _allowed() -> Array:
	return (_list().get("allowed", {}) as Dictionary).keys()

func test_every_allowed_permission_is_justified() -> void:
	# UNE PERMISSION SANS JUSTIFICATION ÉCRITE EST UNE PERMISSION QU'ON A CESSÉ
	# DE PESER. Le champ n'est pas décoratif : c'est lui qui oblige à répondre
	# « à quoi sert-elle, et à quoi donne-t-elle accès ? » avant de l'ajouter.
	var allowed: Dictionary = _list().get("allowed", {})
	assert_gt(allowed.size(), 0, "la liste versionnée doit être lisible")
	var incomplete := PackedStringArray()
	for name in allowed:
		var entry: Dictionary = allowed[name]
		if not String(name).begins_with("android.permission."):
			incomplete.append("%s (nom mal formé)" % name)
		elif String(entry.get("pourquoi", "")).is_empty():
			incomplete.append("%s (aucune justification)" % name)
	assert_eq(incomplete, PackedStringArray(),
		"entrées incomplètes : %s" % ", ".join(incomplete))

func test_no_network_permission_ever() -> void:
	# LA SEULE QUI COMPTE VRAIMENT. Le jeu est hors ligne ; une permission
	# réseau contredirait l'exigence de fond, pas une question de forme. Aucune
	# fonctionnalité ne peut la justifier — c'est le sens d'ENF-30/31.
	var forbidden: Array = _list().get("forbidden_always", [])
	assert_gt(forbidden.size(), 0, "la liste des interdits doit être lisible")
	var found := PackedStringArray()
	for p in _allowed():
		if forbidden.has(p):
			found.append("%s : autorisée ET interdite, la liste se contredit" % p)
	assert_eq(found, PackedStringArray(), ", ".join(found))
	for p in ["android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE"]:
		assert_true(forbidden.has(p),
			"%s doit rester explicitement interdite" % p)

func test_the_haptic_permission_is_on_the_list() -> void:
	# L'AUTRE BORD, et c'est celui qui a manqué pendant des mois : le retour
	# haptique était écrit, branché en neuf endroits, réglé au millième de
	# seconde — et muet, faute d'une ligne. **Un code qui ne peut pas s'exécuter
	# coûte plus cher qu'un code absent** : il occupe la place et donne
	# l'illusion que la fonctionnalité existe.
	assert_true(_allowed().has("android.permission.VIBRATE"),
		("`VIBRATE` n'est plus sur la liste : tout `game/platform/haptics.gd` "
		+ "redevient inerte, silencieusement, sans qu'aucun test ne le dise."))
