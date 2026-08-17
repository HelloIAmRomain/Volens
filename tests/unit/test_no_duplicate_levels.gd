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

## LES DEUX PAIRES CONNUES, ET POURQUOI ELLES SONT ENCORE LÀ.
##
## Ce n'est pas une liste de tolérance : c'est une liste d'ATTENTE, et elle
## attend une décision humaine précise. **Corriger l'un ou l'autre de ces
## niveaux invalide des empreintes d'or archivées** — `tests/golden/golden.json`
## en garde deux recettes pour ch2_05 et deux pour ch3_04. Or une empreinte d'or
## qui change signale une régression du déterminisme ; la mettre à jour parce
## qu'on a bougé un mur est exactement le geste que le protocole interdit de
## faire seul. La géométrie de ces deux niveaux est donc GELÉE tant que la
## régénération des recettes n'a pas été explicitement demandée.
##
## Trois tentatives de refonte de ch2_05 ont été mesurées avant ce constat, et
## la dernière a été refusée par le validateur pour un motif qui vaut d'être
## gardé : « 1 pile gagnante laisse jusqu'à 2 agents faire du sur-place
## perpétuel — le joueur y verra un bug ». Un doublon assumé vaut mieux qu'un
## niveau qui a l'air cassé.
##
## NUANCE HONNÊTE SUR ch2_04 ≡ ch2_05 : les deux acceptent les mêmes familles,
## mais pas pour la même raison. ch2_05 sépare la nuée en deux groupes hors de
## portée de perception, et sa question réelle — « comment deux moitiés qui ne
## se voient pas s'accordent-elles ? » — n'a pas d'équivalent en ch2_04. Le
## doublon est réel du point de vue des SOLUTIONS, discutable du point de vue du
## sujet. C'est précisément ce qu'une décision humaine doit trancher.
const KNOWN_TWINS := ["ch2_04 ≡ ch2_05", "ch3_02 ≡ ch3_04"]

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
