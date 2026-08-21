extends GutTest
## LE `.json` QUE LE JEU CHARGE DOIT ÊTRE CELUI QUE LE `.lvl` DÉCRIT.
##
## HISTOIRE DE CE FICHIER. Le `.lvl` est la SOURCE — c'est lui qu'on écrit, lui
## qui porte la fiche de conception en en-tête. Le `.json` est le PRODUIT : le
## convertisseur le fabrique, et c'est lui, et lui seul, que le jeu charge.
## Rien ne vérifiait qu'ils disaient la même chose.
##
## LA DÉRIVE A EU LIEU, ET ELLE A DURÉ TROIS MINUTES. En sondant trois
## bibliothèques possibles pour ch4_05, j'ai converti trois fois, puis restauré
## le `.lvl` d'origine — sans reconvertir. Le `.json` est resté sur la DERNIÈRE
## sonde. Pendant ce temps le niveau jouait avec une bibliothèque que sa source
## ne mentionnait nulle part, et un test tout neuf, écrit pour attraper une
## règle offerte trop tôt, l'a déclaré conforme : il lisait le `.json`.
##
## **Un test qui interroge le produit et non la source valide la dérive au lieu
## de la voir.** Trois minutes cette fois. Rien ne garantissait que ce soit trois
## minutes plutôt que trois semaines — un `git status` distrait suffisait.
##
## CE QUE CE TEST FAIT. Il reconvertit chaque `.lvl` du catalogue EN MÉMOIRE et
## compare le résultat au `.json` sur le disque. Le convertisseur est pur : même
## texte, même sortie, toujours. Une divergence ne peut donc signifier qu'une
## chose — le `.json` n'a pas été régénéré après une modification de sa source.
##
## IL NE COMPARE PAS LES OCTETS mais les CHAMPS, un à un. Deux JSON identiques
## peuvent différer par leur ordre de clés ou leur nombre d'espaces, et un test
## qui crierait là-dessus serait débranché dans la semaine.
##
## LES DEUX CÔTÉS PASSENT PAR JSON AVANT D'ÊTRE COMPARÉS, et sans cela le test
## est un faux positif intégral — il l'a été à sa première exécution, déclarant
## les TRENTE-QUATRE niveaux désynchronisés. Le convertisseur rend des entiers
## et des tableaux typés ; un fichier relu rend des flottants. `3` et `3.0` sont
## le même niveau et deux chaînes différentes. On normalise donc les deux côtés
## dans le même domaine — celui du fichier, puisque c'est lui que le jeu lit.

## Le plancher de période des dangers cycliques vient de `data/rules.json`, comme
## pour le convertisseur en ligne de commande. Le recopier ici ferait diverger un
## paramètre de plus (invariant n°16).
func _min_period() -> int:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/rules.json"))
	var rules: Dictionary = parsed if parsed is Dictionary else {}
	var validation: Dictionary = rules.get("validation", {})
	return int(validation.get("min_cycle_period", ValidateLib.MIN_CYCLE_PERIOD_DEFAULT))

func test_every_shipped_json_matches_the_lvl_it_came_from() -> void:
	var stale := PackedStringArray()
	var compared := 0
	var floor_period := _min_period()
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		# LE CHEMIN SE DÉDUIT DU CATALOGUE, jamais écrit en dur : c'est lui qui
		# sait où vivent les niveaux, et un littéral de plus ici serait un second
		# endroit à corriger le jour d'un déménagement (invariant n°16).
		var source := LevelCatalog.path_of(level_id).replace(".json", ".lvl")
		if not FileAccess.file_exists(source):
			continue   # niveau écrit directement en JSON : rien à confronter
		var result := LvlParser.parse(FileAccess.get_file_as_string(source), floor_period)
		var errors: PackedStringArray = result.get("errors", PackedStringArray())
		if not errors.is_empty():
			stale.append("%s : sa propre source ne se convertit plus (%s)"
				% [level_id, ", ".join(errors)])
			continue
		compared += 1
		var rebuilt: Variant = JSON.parse_string(JSON.stringify(result["level"]))
		var fresh: Dictionary = rebuilt if rebuilt is Dictionary else {}
		var shipped := LevelCatalog.load_level_data(level_id)
		for key in fresh:
			if JSON.stringify(fresh[key]) != JSON.stringify(shipped.get(key, null)):
				stale.append("%s → %s" % [level_id, key])
		for key in shipped:
			if not fresh.has(key):
				stale.append("%s → %s (dans le .json, absent de la source)"
					% [level_id, key])
	assert_gt(compared, 0, "aucun .lvl confronté : le balayage du catalogue est cassé")
	# ON N'IMPRIME QUE LES HUIT PREMIERS ÉCARTS. Le message complet du premier
	# essai faisait deux cent quarante entrées et douze mille caractères : un
	# rapport qu'on ne peut pas lire ne dit rien de plus qu'un rapport vide.
	var shown := stale.slice(0, 8)
	if stale.size() > 8:
		shown.append("… et %d autres" % (stale.size() - 8))
	assert_eq(stale, PackedStringArray(),
		("`.json` désynchronisé de son `.lvl` : %s — le jeu charge autre chose que "
		+ "ce que la source décrit. Reconvertir : "
		+ "`godot --headless --path . --script res://tools/lvl/run.gd -- --in=…`")
		% ", ".join(shown))
