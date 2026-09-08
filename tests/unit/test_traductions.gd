extends GutTest
## ENF-40/41 — FRANÇAIS ET ANGLAIS LIVRÉS ENSEMBLE, et vérifié plutôt que promis.
##
## POURQUOI CE FICHIER EXISTE. « Français et anglais à parité » est une exigence
## obligatoire du CDC, et c'est le genre d'exigence qui se perd en silence : on
## ajoute un écran, on écrit sa chaîne en français, on la câble, tout marche —
## et le jeu parle anglais partout sauf là. Rien ne le signale, parce que
## `TranslationServer` rend la CLÉ quand la traduction manque, et qu'une clé
## ressemble à du texte tant qu'on ne la lit pas.
##
## LE FORMAT CSV A ÉTÉ CHOISI POUR ÇA (DCT §9.3, « fichiers CSV/PO, clés
## stables ») : une ligne par clé, les deux langues CÔTE À CÔTE. La parité se
## lit à l'œil dans un diff, et se mesure ici.
##
## CE QUE CE TEST NE PEUT PAS VOIR, et il vaut mieux le nommer : il vérifie que
## toute clé DÉCLARÉE porte ses deux langues. Il ne sait pas qu'une chaîne est
## restée en dur dans un fichier `.gd` sans jamais devenir une clé — c'est
## l'inverse, et cela demanderait de reconnaître le français dans du code.
## La migration reste donc un travail à mener, dont ce test protège le résultat.

const CSV_PATH := "res://data/i18n/volens.csv"
const LOCALES := ["fr", "en"]

func _rows() -> Array:
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(f, "fichier de traduction introuvable : %s" % CSV_PATH)
	if f == null:
		return []
	var out: Array = []
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and not String(line[0]).is_empty():
			out.append(line)
	f.close()
	return out

func test_the_header_declares_exactly_the_two_shipped_locales() -> void:
	var rows := _rows()
	assert_gt(rows.size(), 1, "fichier de traduction vide")
	if rows.is_empty():
		return
	var header: PackedStringArray = rows[0]
	var got: Array = []
	for i in range(1, header.size()):
		got.append(String(header[i]))
	assert_eq(got, LOCALES,
		("l'en-tête doit déclarer exactement %s, dans cet ordre — sinon les "
		+ "colonnes lues plus bas ne sont pas celles qu'on croit. Constaté : %s")
		% [str(LOCALES), str(got)])

func test_no_key_is_declared_twice() -> void:
	# UNE CLÉ EN DOUBLE N'EST PAS UNE ERREUR VISIBLE : la seconde écrase
	# silencieusement la première, et la chaîne affichée n'est pas celle qu'on
	# vient de relire dans le fichier.
	var seen := {}
	var doubles := PackedStringArray()
	var rows := _rows()
	for i in range(1, rows.size()):
		var key := String((rows[i] as PackedStringArray)[0])
		if seen.has(key):
			doubles.append(key)
		seen[key] = true
	assert_eq(doubles, PackedStringArray(),
		"clés déclarées deux fois : %s" % ", ".join(doubles))

func test_every_key_carries_both_languages() -> void:
	# LE CŒUR DE ENF-40/41. Une case vide, et le joueur anglophone voit une clé.
	var missing := PackedStringArray()
	var checked := 0
	var rows := _rows()
	for i in range(1, rows.size()):
		var row: PackedStringArray = rows[i]
		var key := String(row[0])
		checked += 1
		for c in range(1, LOCALES.size() + 1):
			var value: String = String(row[c]) if c < row.size() else ""
			if value.strip_edges().is_empty():
				missing.append("%s [%s]" % [key, LOCALES[c - 1]])
	assert_gt(checked, 0, "aucune clé examinée : la lecture du CSV est cassée")
	assert_eq(missing, PackedStringArray(),
		("traductions manquantes — le joueur y verrait la clé brute : %s")
		% ", ".join(missing))

func test_every_living_rule_has_a_name_and_a_sentence_in_both_locales() -> void:
	# L'AUTRE SENS : le CSV peut être parfaitement pariteux et ne rien dire des
	# règles que le jeu offre réellement. On interroge donc le registre, pas le
	# fichier — c'est le catalogue qui décide de ce qui doit exister.
	var previous := TranslationServer.get_locale()
	var faults := PackedStringArray()
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		for id in RuleRegistry.ALL:
			var label := RuleCatalog.name_of(int(id))
			var line := RuleCatalog.line_of(int(id))
			# Une clé non traduite revient TELLE QUELLE : elle commence par
			# « rule. » et ne ressemble à rien d'autre dans le jeu.
			if label.begins_with("rule.") or label.is_empty():
				faults.append("R%02d nom [%s]" % [int(id), locale])
			if line.begins_with("rule.") or line.length() < 20:
				faults.append("R%02d phrase [%s]" % [int(id), locale])
	TranslationServer.set_locale(previous)
	assert_eq(faults, PackedStringArray(),
		"règles sans libellé utilisable : %s" % ", ".join(faults))

func test_the_french_column_still_matches_the_catalogue() -> void:
	# DEUX SOURCES POUR UNE MÊME CHAÎNE, ET C'EST ASSUMÉ — mais surveillé.
	#
	# `LevelCatalog.LEVELS` garde le nom français : c'est là que le concepteur
	# écrit, et une table dont les entrées seraient des clés nues
	# (`level.ch3_02.name`) ne se relirait plus. Le CSV en porte une copie, parce
	# que c'est lui qui sert l'affichage.
	#
	# Une copie non surveillée finit TOUJOURS par diverger — c'est l'invariant
	# n°16, écrit après trois divergences sur trois champs différents. Ici, le
	# jour où l'on renomme un niveau dans le catalogue sans toucher au CSV, le
	# joueur francophone verrait l'ANCIEN nom, et rien ne le dirait.
	var drift := PackedStringArray()
	var rows := _rows()
	var by_key := {}
	for i in range(1, rows.size()):
		var row: PackedStringArray = rows[i]
		by_key[String(row[0])] = String(row[1]) if row.size() > 1 else ""
	var checked := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		var level_id := String(entry["id"])
		var key := "level.%s.name" % level_id
		if not by_key.has(key):
			drift.append("%s : aucune clé %s" % [level_id, key])
			continue
		checked += 1
		if String(by_key[key]) != String(entry["name"]):
			drift.append("%s : catalogue « %s » vs CSV « %s »"
				% [level_id, String(entry["name"]), String(by_key[key])])
	assert_gt(checked, 0, "aucun niveau confronté : le balayage est cassé")
	assert_eq(drift, PackedStringArray(),
		"le nom français a divergé entre le catalogue et le fichier de traduction : %s"
		% ", ".join(drift))

func test_every_level_has_an_english_name() -> void:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var untranslated := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var level_id := String((LevelCatalog.entry(i))["id"])
		var shown := LevelCatalog.name_of(level_id)
		# `name_of` retombe sur le français quand la clé manque : on compare donc
		# à la table plutôt que de guetter un préfixe de clé.
		if shown == String((LevelCatalog.entry(i))["name"]):
			untranslated.append(level_id)
	TranslationServer.set_locale(previous)
	assert_eq(untranslated, PackedStringArray(),
		("niveaux sans nom anglais — le joueur anglophone y lirait du français : "
		+ "%s") % ", ".join(untranslated))

func test_zero_takes_the_singular_in_french_and_the_plural_in_english() -> void:
	# LE CAS QUI PIÈGE, ET IL EST FRÉQUENT. Le code portait la règle française
	# pour tout le monde — `"s" si n > 1` — ce qui donne « 0 agents » en français
	# et « 0 agent » en anglais : faux dans les deux sens, sur le cas NORMAL
	# d'une partie réussie, où l'on ne perd personne.
	#
	# Français : zéro et un au singulier. Anglais : seul un.
	var previous := TranslationServer.get_locale()
	var expected := {
		"fr": {0: "0 agent.", 1: "1 agent.", 2: "2 agents."},
		"en": {0: "0 agents.", 1: "1 agent.", 2: "2 agents."},
	}
	var wrong := PackedStringArray()
	for locale in expected:
		TranslationServer.set_locale(String(locale))
		for n in (expected[locale] as Dictionary):
			var line := RuleCatalog.objective_brief(
				[{"type": "preservation", "max_lost": int(n)}], 20)[0]
			var tail := String((expected[locale] as Dictionary)[n])
			if not line.ends_with(tail):
				wrong.append("[%s] n=%d → « %s », attendu une fin en « %s »"
					% [locale, int(n), line, tail])
	TranslationServer.set_locale(previous)
	assert_eq(wrong, PackedStringArray(),
		"accord du pluriel incorrect : %s" % ", ".join(wrong))

func test_the_two_locales_actually_differ() -> void:
	# GARDE CONTRE LA COLONNE RECOPIÉE. Remplir la colonne anglaise avec le
	# français satisfait tous les tests ci-dessus et ne traduit rien — c'est la
	# façon la plus courante de « finir » une localisation.
	var previous := TranslationServer.get_locale()
	var identical := PackedStringArray()
	for id in RuleRegistry.ALL:
		TranslationServer.set_locale("fr")
		var fr := RuleCatalog.name_of(int(id))
		TranslationServer.set_locale("en")
		var en := RuleCatalog.name_of(int(id))
		if fr == en:
			identical.append("R%02d (« %s »)" % [int(id), fr])
	TranslationServer.set_locale(previous)
	assert_eq(identical, PackedStringArray(),
		("noms identiques dans les deux langues — colonne anglaise recopiée ? "
		+ "%s") % ", ".join(identical))
