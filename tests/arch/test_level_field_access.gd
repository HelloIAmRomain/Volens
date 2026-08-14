extends GutTest
## UNE VALEUR DE NIVEAU NE SE LIT QU'À UN SEUL ENDROIT.
##
## **Toute valeur de niveau recopiée hors de son fichier source finit par
## diverger.** Ce n'est pas une prudence, c'est un constat : le motif s'est
## produit trois fois, sur trois champs différents, et à chaque fois la
## divergence est passée inaperçue jusqu'à ce qu'un test échoue pour une autre
## raison.
##
##   · `slots` — l'interface offrait quatre rangs là où le validateur en
##     énumérait deux. Conséquence : `expected_wins` devenait faux, et la leçon
##     du niveau avec lui (invariant n°11) ;
##   · `expected_wins` — une table en dur dans `test_chapter1_arc` recopiait
##     les valeurs des trois derniers niveaux. Elle a dérivé **dès la première
##     refonte**, et le test a échoué en annonçant « 2 attendu 7 » alors que la
##     vérité était l'inverse ;
##   · `slots` encore — une assertion recopiait « ch1_02 déclare slots: 2 ».
##
## Trois corrections au cas par cas auraient laissé le quatrième champ passer.
## Ce test est le contrôle générique : **les champs déclaratifs d'un niveau ne
## se lisent que par `LevelSpec`.**
##
## Ce qui reste permis, et pourquoi :
##   · `LevelSpec` — c'est lui, la source de vérité ;
##   · `tools/lvl/lvl_parser.gd` — il ÉCRIT ces champs depuis un en-tête texte,
##     il ne les consomme pas ;
##   · lire la clé sur un **rapport de validateur** ou sur le **bloc de relevé
##     d'une fiche** n'est pas lire un niveau : ces objets portent leur propre
##     copie, et la confronter au niveau est justement le but. On les distingue
##     par l'indexation directe (`x["clé"]`), qui ne ressemble pas à une
##     lecture de niveau.

## Champs DÉCLARATIFS : ils décrivent ce que le niveau prétend être, ne
## pilotent pas la simulation, et sont donc recopiés partout.
##
## `max_ticks`, `objectives`, `allowed_rules` et `agents` n'y figurent pas :
## ce sont des ENTRÉES de la simulation, lues par `SimCore` là où c'est son
## travail. Les protéger de la même façon interdirait au moteur de fonctionner.
const GUARDED_FIELDS := ["expected_wins", "expected_classes", "tutorial", "calibrated_on",
	"slots", "challenges"]

const ALLOWED := [
	"res://core/sim/level_spec.gd",      # la source de vérité
	"res://tools/lvl/lvl_parser.gd",     # il écrit ces champs, il ne les lit pas
]

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

func _sources() -> Array:
	var files: Array = []
	for root in ["res://core", "res://game", "res://tools", "res://tests"]:
		_all_gd(root, files)
	return files

func test_declarative_fields_are_read_only_through_level_spec() -> void:
	var files := _sources()
	assert_gt(files.size(), 0, "aucune source trouvée — le balayage est cassé")
	var offenders := PackedStringArray()
	for path in files:
		if ALLOWED.has(path) or path == get_script().resource_path:
			continue
		var text := FileAccess.get_file_as_string(path)
		for field in GUARDED_FIELDS:
			if text.contains('get("%s"' % field):
				offenders.append("%s → %s" % [path.get_file(), field])
	offenders.sort()
	assert_eq(offenders, PackedStringArray(),
		("Champ déclaratif lu ailleurs que par `LevelSpec` : toute valeur de niveau "
		+ "recopiée hors de sa source finit par diverger. Occurrences : %s")
		% ", ".join(offenders))

func test_level_spec_exposes_every_guarded_field() -> void:
	# Sans cette garde, il suffirait de retirer un accesseur pour que le
	# contrôle précédent devienne vide de sens sur ce champ.
	var text := FileAccess.get_file_as_string("res://core/sim/level_spec.gd")
	for field in GUARDED_FIELDS:
		assert_true(text.contains('get("%s"' % field),
			"`%s` est déclaré protégé mais LevelSpec ne le lit pas" % field)

func test_the_accessors_agree_with_the_level_files() -> void:
	# Le contrôle lexical garantit qu'on passe par l'accesseur ; celui-ci
	# garantit que l'accesseur dit la vérité.
	var examined := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		examined += 1
		var level_id := String(entry["id"])
		var data := LevelCatalog.load_level_data(level_id)
		var raw: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(LevelCatalog.path_of(level_id)))
		assert_true(raw is Dictionary, "%s illisible" % level_id)
		var d: Dictionary = raw
		assert_eq(LevelSpec.expected_wins(data), int(d["expected_wins"]),
			"%s : expected_wins" % level_id)
		assert_eq(LevelSpec.open_slots(data), int(d["slots"]),
			"%s : slots" % level_id)
		assert_eq(LevelSpec.calibrated_on(data), String(d["calibrated_on"]),
			"%s : calibrated_on" % level_id)
	# Le filtre `ready` peut vider cette boucle sans qu'une ligne change ici.
	assert_gt(examined, 0, "aucun niveau prêt examiné : le filtre a tout écarté")
