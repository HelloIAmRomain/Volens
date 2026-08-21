extends GutTest
## UN NIVEAU N'OFFRE JAMAIS UNE RÈGLE D'UN CHAPITRE POSTÉRIEUR AU SIEN.
##
## HISTOIRE DE CE FICHIER, et elle est fraîche. En remplaçant ch4_02 par un
## niveau forgé, je lui ai donné une bibliothèque `[R01, R04, R11, R14]` — et
## **R14 « Disperser si dense » appartient au chapitre 5**. Le niveau se jouait
## bien, la carte était mesurée, le validateur content, et les 463 tests verts.
##
## CE QUE ÇA CASSAIT SANS QUE RIEN NE LE DISE. RG-11 : « la progression du
## joueur est exclusivement l'expansion de cette bibliothèque ». Offrir R14 au
## chapitre 4, c'est la lui donner AVANT le chapitre qui l'enseigne — donc vider
## ch5_02 de son objet, qui est précisément de la présenter. Le jeu n'aurait pas
## planté ; il aurait juste enseigné deux fois, la seconde pour rien.
##
## AUCUN TEST NE POUVAIT LE VOIR, et c'est le motif de celui-ci : le catalogue
## déduit l'introduction d'une règle du PREMIER niveau qui l'offre. Déplacer
## l'introduction n'était donc pas une faute détectable — c'était, mécaniquement,
## une nouvelle vérité. Il fallait confronter le catalogue à autre chose que
## lui-même : le CDC §7.2, qui assigne chaque règle à un chapitre.
##
## LE RATTACHEMENT EST ARITHMÉTIQUE, PAS DÉCLARÉ. Les tables du CDC donnent
## trois règles par chapitre, dans l'ordre : R01-R03 au chapitre 1, R04-R06 au
## 2, R07-R09 au 3, R10-R12 au 4, R13-R15 au 5, R16 au 6. Une seconde table
## recopiée ici divergerait au premier ajout (invariant n°16) ; la formule, elle,
## ne peut pas mentir sur ce qu'elle n'a pas.
##
## LES IDENTIFIANTS RETIRÉS — R07, R10, R12 — gardent leur chapitre d'origine.
## C'est sans conséquence : plus aucun niveau ne les offre, et le jour où l'un
## d'eux reviendrait, il reviendrait à sa place.

## Chapitre où le CDC §7.2 introduit la règle. Le joker R16 porte son argument
## dans ses bits hauts : on interroge sa règle de base, jamais l'entier brut.
func _cdc_chapter_of(rule_id: int) -> int:
	var base := RuleRegistry.base_rule_id(rule_id)
	if base < 1:
		return 0
	@warning_ignore("integer_division")
	return ((base - 1) / 3) + 1

func test_no_level_offers_a_rule_from_a_later_chapter() -> void:
	var breaches := PackedStringArray()
	var checked := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var level_chapter := LevelCatalog.chapter_of(level_id)
		var data := LevelCatalog.load_level_data(level_id)
		for v in data.get("allowed_rules", []):
			var rule_chapter := _cdc_chapter_of(int(v))
			checked += 1
			if rule_chapter > level_chapter:
				breaches.append("%s (chapitre %d) offre R%02d, introduite au chapitre %d"
					% [level_id, level_chapter, RuleRegistry.base_rule_id(int(v)), rule_chapter])
	assert_gt(checked, 0, "aucune règle examinée : le balayage du catalogue est cassé")
	assert_eq(breaches, PackedStringArray(),
		("règle offerte avant le chapitre qui l'enseigne : %s — RG-11 fait de la "
		+ "progression l'expansion de la bibliothèque, et le chapitre qui devait "
		+ "présenter la règle n'a plus rien à présenter.") % ", ".join(breaches))

func test_the_chapter_formula_matches_the_cdc_tables() -> void:
	# GARDE DE LA GARDE. Si la formule dérivait, le test ci-dessus deviendrait
	# une tautologie silencieuse — il comparerait le catalogue à une invention.
	# Les six lignes ci-dessous sont recopiées des tables du CDC §7.2.
	var expected := {
		1: 1, 2: 1, 3: 1,
		4: 2, 5: 2, 6: 2,
		7: 3, 8: 3, 9: 3,
		10: 4, 11: 4, 12: 4,
		13: 5, 14: 5, 15: 5,
		16: 6,
	}
	var wrong := PackedStringArray()
	for rule_id in expected:
		if _cdc_chapter_of(int(rule_id)) != int(expected[rule_id]):
			wrong.append("R%02d : formule %d, CDC %d"
				% [rule_id, _cdc_chapter_of(int(rule_id)), int(expected[rule_id])])
	assert_eq(wrong, PackedStringArray(),
		"la formule ne rend plus le rattachement du CDC §7.2 : %s" % ", ".join(wrong))

func test_the_joker_is_placed_by_its_base_rule() -> void:
	# ch6_01 offre un joker, dont l'identifiant vaut 784 et non 16. Sans passage
	# par la règle de base, la formule lui rendrait un chapitre absurde et le
	# test principal refuserait un niveau parfaitement légal.
	var joker := RuleRegistry.make_joker(GridState.CellType.STATIC_DANGER)
	assert_gt(joker, 16, "le joker doit porter son argument dans ses bits hauts")
	assert_eq(_cdc_chapter_of(joker), 6,
		"le joker est une règle du chapitre 6, quel que soit son argument")

func test_every_rule_of_the_library_is_introduced_somewhere() -> void:
	# L'AUTRE SENS, et il vaut d'être dit : une règle qu'aucun niveau n'offre
	# n'existe pas pour le joueur. C'est exactement ce qui a fait retirer R10.
	var orphans := PackedStringArray()
	for rule_id in RuleRegistry.ALL:
		var offered := false
		for i in range(LevelCatalog.count()):
			var entry: Dictionary = LevelCatalog.entry(i)
			if not bool(entry["ready"]):
				continue
			var data := LevelCatalog.load_level_data(String(entry["id"]))
			for v in data.get("allowed_rules", []):
				if RuleRegistry.base_rule_id(int(v)) == RuleRegistry.base_rule_id(int(rule_id)):
					offered = true
					break
			if offered:
				break
		if not offered:
			orphans.append("R%02d" % RuleRegistry.base_rule_id(int(rule_id)))
	assert_eq(orphans, PackedStringArray(),
		("règles vivantes qu'aucun niveau n'offre : %s — elles ne sont pas dans "
		+ "le jeu, elles sont dans le code.") % ", ".join(orphans))
