extends GutTest
## DEUX NIVEAUX NE SE RESSEMBLENT PAS — ils sont différents, ou l'un des deux
## ne sert à rien.
##
## HISTOIRE DE CE FICHIER. « Il faut éviter d'avoir plusieurs fois le même
## niveau. » Un doublon a été signalé au chapitre 2 et fusionné à la main. Un
## second a survécu tout le développement du chapitre 3 : **ch3_02 et ch3_04
## avaient la même bibliothèque, le même objectif, le même nombre de rangs et
## EXACTEMENT les mêmes cases non vides** — les trois de la sortie, sur deux
## terrains par ailleurs entièrement vides. Une rangée de hauteur, trois agents
## et cinquante ticks les séparaient.
##
## POURQUOI PERSONNE NE L'A VU. Les deux fiches racontent des leçons
## différentes : « la tête entretient la piste pour la queue » et « ce qui n'a
## pas été marqué au passage ne le sera jamais ». Deux phrases distinctes pour
## une seule idée, et la relecture s'arrête à la phrase. **Une fiche décrit ce
## qu'on a voulu ; le JSON décrit ce qu'on a fait**, et c'est le second qu'il
## faut comparer.
##
## LE CRITÈRE EST VOLONTAIREMENT ÉTROIT. On n'essaie pas de mesurer une
## « ressemblance » — ce serait un réglage de seuil sans fin, et un test qui
## crie au loup finit désactivé. On refuse une COÏNCIDENCE EXACTE sur les quatre
## champs qui définissent l'exercice posé au joueur. Deux niveaux qui les
## partagent tous les quatre posent la même question, quoi qu'en disent leurs
## fiches.
##
## IL IGNORE LA POSITION DE LA NUÉE, ET C'EST DÉLIBÉRÉ — c'est même la règle de
## conception que ce test énonce : **même carte + même bibliothèque + même
## objectif = même niveau, quelle que soit la disposition de départ.** Le
## dispositif l'a démontré en trouvant une SECONDE paire que personne ne
## cherchait, ch2_04 ≡ ch2_05, où seule la nuée diffère — un bloc de 5×4 contre
## deux groupes de 2×5. Et la mesure des gagnantes tranche : les deux acceptent
## exactement les mêmes trois familles, `[1,4,5]`, `[1,4,6]` et `[4,5,6]`.
## Déplacer les agents avait produit deux tableaux et une seule question.
##
## CE QU'IL NE PRÉTEND PAS COUVRIR : deux niveaux presque identiques, dont l'un
## a un mur d'une case en plus. Aucun test lexical ne tranchera cela — c'est le
## travail de `tools/design/combinations.gd`, qui compare les GAGNANTES et voit
## que les deux se résolvent pareil. Ce fichier attrape le doublon franc, celui
## qui n'a aucune excuse.

## Les champs qui définissent l'exercice. Le terrain compte par ses cases NON
## VIDES : deux grilles de hauteurs différentes mais au même mobilier posent le
## même problème — c'était précisément le cas de ch3_02 et ch3_04.
func _fingerprint(level_id: String) -> String:
	var data := LevelCatalog.load_level_data(level_id)
	var rules: Array = (data.get("allowed_rules", []) as Array).duplicate()
	rules.sort()

	var grid: Dictionary = data.get("grid", {})
	var size: Array = grid.get("size", [0, 0])
	var width: int = int(size[0]) if size.size() > 0 else 0
	var cells: Array = grid.get("cells", [])
	var furniture: Array = []
	for i in range(cells.size()):
		var c: int = int(cells[i])
		if c != GridState.CellType.EMPTY:
			@warning_ignore("integer_division")
			furniture.append("%d,%d=%d" % [i % maxi(1, width), i / maxi(1, width), c])

	# Les objectifs se comparent triés : l'ordre de déclaration n'est pas une
	# différence de conception.
	var objectives: Array = []
	for o in data.get("objectives", []):
		objectives.append(JSON.stringify(o))
	objectives.sort()

	return "rules=%s|slots=%d|objectifs=%s|mobilier=%s" % [
		str(rules), LevelSpec.open_slots(data), str(objectives), str(furniture)]

## LA LISTE D'ATTENTE EST VIDE, ET C'EST L'ÉTAT NORMAL.
##
## Elle a porté deux paires, toutes deux résolues :
##
##   · **ch3_02 ≡ ch3_04** (18 août 2026) — ch3_04 refondu sur une poche fermée
##     au nord, où « vers la lumière » se piège elle-même et où la piste connaît
##     le détour. Ses recettes d'or ont été régénérées sur autorisation, après
##     prédiction écrite : seize lignes modifiées, toutes ch3_04.
##   · **ch2_04 ≡ ch2_05** (20 août 2026) — FUSIONNÉS. Les deux acceptaient
##     exactement les mêmes trois familles gagnantes, sur le même mobilier, avec
##     la même bibliothèque et le même objectif ; seule la nuée différait. On a
##     gardé ch2_04, plus riche d'une gagnante et porteur de la leçon du
##     chapitre. Trois refontes de ch2_05 avaient été mesurées d'abord, la
##     dernière refusée par le validateur pour agents en sur-place perpétuel :
##     fusionner valait mieux que garder un niveau qui a l'air cassé.
##
## CE QU'ELLE RESTE. Non pas une liste de tolérance mais une liste d'ATTENTE :
## une entrée n'y a sa place que le temps qu'une décision humaine soit prise —
## typiquement parce que la correction invaliderait des empreintes d'or, ce qui
## ne se fait jamais seul. Le second test refuse qu'une entrée y survive à son
## motif, et c'est ce qui empêche l'attente de devenir une habitude.
const KNOWN_TWINS: Array = []

func test_no_two_levels_pose_the_same_exercise() -> void:
	var seen: Dictionary = {}
	var duplicates := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var key := _fingerprint(level_id)
		if seen.has(key):
			var pair := "%s ≡ %s" % [String(seen[key]), level_id]
			if not KNOWN_TWINS.has(pair):
				duplicates.append(pair)
		else:
			seen[key] = level_id
	assert_eq(duplicates, PackedStringArray(),
		("niveaux jumeaux (même bibliothèque, mêmes rangs, mêmes objectifs, même "
		+ "mobilier) : %s — l'un des deux ne pose aucune question nouvelle")
		% ", ".join(duplicates))

func test_the_waiting_list_does_not_outlive_the_problem() -> void:
	# UNE LISTE D'ATTENTE QUI SURVIT À SON MOTIF DEVIENT UNE LISTE DE TOLÉRANCE,
	# et plus personne ne se souvient de ce qu'elle attendait. Dès qu'une paire
	# cesse d'être jumelle — parce qu'on l'a enfin corrigée — son entrée doit
	# disparaître, sinon elle couvrirait un futur doublon portant les mêmes noms.
	var seen: Dictionary = {}
	var actual := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var key := _fingerprint(level_id)
		if seen.has(key):
			actual.append("%s ≡ %s" % [String(seen[key]), level_id])
		else:
			seen[key] = level_id
	var stale := PackedStringArray()
	for pair in KNOWN_TWINS:
		if not actual.has(pair):
			stale.append(String(pair))
	assert_eq(stale, PackedStringArray(),
		("entrées périmées dans KNOWN_TWINS : %s — ces niveaux ne sont plus "
		+ "jumeaux, retirer la ligne") % ", ".join(stale))

func test_the_detector_itself_works() -> void:
	# AUTO-TEST DU DISPOSITIF. Une empreinte qui se calculerait mal — champ
	# absent, grille illisible — rendrait la même chaîne pour tout le monde ou
	# une chaîne unique par niveau, et le test passerait au vert dans les deux
	# cas. On vérifie donc qu'elle DISTINGUE deux niveaux notoirement différents
	# et qu'elle est stable pour un même niveau.
	var a := _fingerprint("ch1_01")
	var b := _fingerprint("ch4_01")
	assert_ne(a, b, "l'empreinte ne distingue plus deux niveaux sans rapport")
	assert_eq(a, _fingerprint("ch1_01"), "l'empreinte n'est pas stable")
	assert_true(a.contains("mobilier="), "l'empreinte a perdu le terrain")
