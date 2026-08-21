class_name LevelCatalog
extends RefCounted
## Catalogue des niveaux, conçus et valides — un chapitre apres l'autre.
##
## Les niveaux 3 à 5 portent l'arc QN-02 : trois familles de piles, chacune
## gagnante sur exactement deux niveaux, aucune sur les trois. La propriété
## n'est pas déclarative — elle est simulée à chaque exécution des tests
## (`tests/unit/test_chapter1_arc.gd`).

const LEVELS := [
	{"id": "ch1_01", "name": "La nuée", "path": "res://data/levels/ch1_01.json", "ready": true},
	{"id": "ch1_02", "name": "Le détour", "path": "res://data/levels/ch1_02.json", "ready": true},
	{"id": "ch1_03", "name": "Les traînards", "path": "res://data/levels/ch1_03.json", "ready": true},
	{"id": "ch1_04", "name": "Le prix du temps", "path": "res://data/levels/ch1_04.json", "ready": true},
	{"id": "ch1_05", "name": "Plusieurs vérités", "path": "res://data/levels/ch1_05.json", "ready": true},
	{"id": "ch2_01", "name": "Trois portes", "path": "res://data/levels/ch2_01.json", "ready": true},
	{"id": "ch2_02", "name": "Sans lumière", "path": "res://data/levels/ch2_02.json", "ready": true},
	{"id": "ch2_03", "name": "La mauvaise porte", "path": "res://data/levels/ch2_03.json", "ready": true},
	{"id": "ch2_04", "name": "Le détour long", "path": "res://data/levels/ch2_04.json", "ready": true},
	# ch2_05 « Les deux moitiés » A ÉTÉ FUSIONNÉ AVEC ch2_04 le 20 août 2026.
	#
	# Les deux niveaux acceptaient EXACTEMENT les mêmes trois familles gagnantes
	# — `[1,4,5]`, `[1,4,6]`, `[4,5,6]` — sur le même mobilier, avec la même
	# bibliothèque et le même objectif. Seule la nuée différait : un bloc de 5×4
	# d'un côté, deux groupes de 2×5 de l'autre. Deux tableaux, une seule
	# question, et le joueur qui résolvait l'un récitait sur l'autre.
	#
	# ON GARDE ch2_04, qui porte cinq gagnantes minimales contre quatre, et dont
	# la leçon — l'asymétrie Nord>Est>Sud>Ouest — est le sujet du chapitre.
	# Trois refontes de ch2_05 avaient été mesurées avant d'en arriver là ; la
	# dernière a été refusée par le validateur pour agents en sur-place
	# perpétuel. Fusionner valait mieux que garder un niveau qui a l'air cassé.
	{"id": "ch2_06", "name": "L'ouverture décalée", "path": "res://data/levels/ch2_06.json", "ready": true},
	{"id": "ch2_07", "name": "Le passage par la droite", "path": "res://data/levels/ch2_07.json", "ready": true},
	{"id": "ch3_01", "name": "La trace des autres", "path": "res://data/levels/ch3_01.json", "ready": true},
	{"id": "ch3_02", "name": "La trace qui s'efface", "path": "res://data/levels/ch3_02.json", "ready": true},
	{"id": "ch3_03", "name": "Le repli", "path": "res://data/levels/ch3_03.json", "ready": true},
	{"id": "ch3_04", "name": "Le long relais", "path": "res://data/levels/ch3_04.json", "ready": true},
	{"id": "ch4_01", "name": "Le premier fardeau", "path": "res://data/levels/ch4_01.json", "ready": true},
	# ch4_02 « Le sas » A ÉTÉ RETIRÉ le 21 août 2026, pour la même raison que
	# ch2_05 : il posait la question de ch4_01, à l'identique.
	#
	# LA MESURE NE LAISSE AUCUNE PLACE À L'INTERPRÉTATION. Même bibliothèque
	# [R01, R03, R05, R11], mêmes trois rangs, même objectif de collecte, même
	# phrase de leçon — et surtout LES DIX MÊMES PILES GAGNANTES, dans le même
	# ordre, du premier au dernier rang. Un mur et un sas dessinés par-dessus ne
	# changent aucune réponse : ils changent le trajet, pas la question.
	#
	# LA FUSION R11+R12 L'A RÉVÉLÉ SANS L'AVOIR CAUSÉ. Tant que porter et
	# déposer coûtaient deux rangs, la pile [R11, R01, R05] ne tenait pas dans
	# trois emplacements ; une fois le rang libéré, elle a résolu QUATRE niveaux
	# d'un coup et le cliquet de passe-partout (plafond mesuré : 3) l'a signalé.
	# Le doublon, lui, était là depuis le début.
	#
	# LES FICHIERS `data/levels/ch4_02.*` SONT CONSERVÉS, et ce n'est pas un
	# oubli : deux recettes du corpus d'or les rejouent. Les supprimer aurait
	# obligé à régénérer des empreintes — c'est-à-dire à toucher la seule chose
	# qui distingue « le code a régressé » de « l'entrée a changé ».
	#
	# ch4_05 « Le second dépôt » le remplace, et pose l'inverse : trois rangs
	# obligatoires, dont un — « S'écarter » — ne sert pas au transport mais à
	# défaire la file que la lumière forme devant un seul des deux dépôts.
	{"id": "ch4_03", "name": "La navette", "path": "res://data/levels/ch4_03.json", "ready": true},
	{"id": "ch4_04", "name": "Le tri", "path": "res://data/levels/ch4_04.json", "ready": true},
	{"id": "ch4_05", "name": "Le second dépôt", "path": "res://data/levels/ch4_05.json", "ready": true},
	{"id": "ch5_01", "name": "Le passage", "path": "res://data/levels/ch5_01.json", "ready": true},
	{"id": "ch5_02", "name": "Les deux vigies", "path": "res://data/levels/ch5_02.json", "ready": true},
	{"id": "ch5_03", "name": "La fenêtre", "path": "res://data/levels/ch5_03.json", "ready": true},
	{"id": "ch5_04", "name": "Trop et pas assez", "path": "res://data/levels/ch5_04.json", "ready": true},
	{"id": "ch5_05", "name": "Deux fois le prix", "path": "res://data/levels/ch5_05.json", "ready": true},
	{"id": "ch5_06", "name": "Le triple verrou", "path": "res://data/levels/ch5_06.json", "ready": true},
	{"id": "ch5_07", "name": "La bascule", "path": "res://data/levels/ch5_07.json", "ready": true},
	{"id": "ch5_08", "name": "La ronde", "path": "res://data/levels/ch5_08.json", "ready": true},
	{"id": "ch5_09", "name": "Le péage", "path": "res://data/levels/ch5_09.json", "ready": true},
	{"id": "ch5_10", "name": "Le danger et la porte", "path": "res://data/levels/ch5_10.json", "ready": true},
	# ch5_11 « L'atelier » EST LE PREMIER NIVEAU OÙ LE BOUCLIER EXISTE.
	#
	# L'atelier à boucliers était le seul élément que le moteur connaissait et
	# qu'aucun niveau n'employait — et le carnet avait conclu, en titre, qu'il
	# était « inerte PAR CONSTRUCTION » (décision 198). La conclusion reposait
	# sur ~4 900 géométries qui exploraient quatre fois la même région.
	#
	# Mesure qui a tranché, sur cette carte, les trois cases d'atelier retirées
	# et RIEN d'autre : **7 piles gagnantes avec, ZÉRO sans**. Et `[R01]` seule
	# ne gagne pas — le troisième cas que 198 déclarait inexistant.
	# Réfutation complète au carnet, décision 208.
	{"id": "ch5_11", "name": "L'atelier", "path": "res://data/levels/ch5_11.json", "ready": true},
	# ch5_12 EST LE PREMIER NIVEAU À QUATRE RANGS AVANT LA FINALE. Le jeu n'en
	# comptait qu'un, ch6_05, tout au bout : le joueur passait de trois
	# emplacements à quatre pour le dernier tableau. La marche se fait ici, à la
	# fin du chapitre 5, là où elle s'apprend encore.
	#
	# Il apporte QUATRE associations de règles inédites au catalogue — R03 avec
	# R04, R06 et R14, puis R06 avec R14 — et c'est pour elles qu'il existe.
	#
	# Ses CINQ gagnantes sont toutes minimales et toutes à quatre rangs : une
	# échéance déclarée écarte les piles de trois, dont [R04, R06, R01] qui
	# gagnait déjà les trois niveaux de coordination du chapitre 2.
	{"id": "ch5_12", "name": "Le quatrième rang", "path": "res://data/levels/ch5_12.json", "ready": true},
	{"id": "ch6_01", "name": "Le droit d'ignorer", "path": "res://data/levels/ch6_01.json", "ready": true},
	{"id": "ch6_02", "name": "La piste interdite", "path": "res://data/levels/ch6_02.json", "ready": true},
	{"id": "ch6_03", "name": "Personne ne reste", "path": "res://data/levels/ch6_03.json", "ready": true},
	{"id": "ch6_04", "name": "Attendre ou traverser", "path": "res://data/levels/ch6_04.json", "ready": true},
	{"id": "ch6_05", "name": "Le sas rouvert", "path": "res://data/levels/ch6_05.json", "ready": true},
]

static func count() -> int:
	return LEVELS.size()

static func entry(index: int) -> Dictionary:
	if index < 0 or index >= LEVELS.size():
		return {}
	return LEVELS[index]

static func index_of(level_id: String) -> int:
	for i in range(LEVELS.size()):
		if LEVELS[i]["id"] == level_id:
			return i
	return -1

static func path_of(level_id: String) -> String:
	var i := index_of(level_id)
	return "" if i < 0 else String(LEVELS[i]["path"])

## Niveau suivant dans l'ordre du chapitre, ou "" s'il n'y en a pas.
## Sert au bouton « Niveau suivant » du bilan.
static func level_after(level_id: String) -> String:
	var i := index_of(level_id)
	if i < 0 or i + 1 >= LEVELS.size():
		return ""
	return String(LEVELS[i + 1]["id"])

## PROGRESSION VERROUILLÉE : un niveau n'est ouvert que si le précédent est
## résolu. Le chapitre est une rampe d'apprentissage (CDC §8.5) — chaque
## niveau suppose acquise la leçon du précédent. Y entrer sans elle, c'est
## buter sur un dispositif qu'on n'a pas les moyens de lire, et conclure que
## le jeu est obscur alors qu'il est simplement lu dans le désordre.
##
## Le premier niveau est toujours ouvert : il n'a pas de prédécesseur.
static func is_unlocked(level_id: String, progress: Progress) -> bool:
	var i := index_of(level_id)
	if i < 0 or not bool(LEVELS[i]["ready"]):
		return false
	if i == 0:
		return true
	# CE QU'ON A DÉJÀ RÉSOLU NE SE REVERROUILLE JAMAIS.
	#
	# Constaté sur l'appareil : après l'insertion de ch5_09 au milieu du
	# catalogue, ch6_01 — résolu depuis longtemps — s'affichait CADENASSÉ, nom
	# masqué, derrière « terminez “Le péage” ». Le chapitre annonçait pourtant
	# « 5 / 5 résolus » juste au-dessus, puisque le compte, lui, lit la
	# progression. L'écran se contredisait sur la même colonne.
	#
	# Le verrou est en chaîne — chaque niveau demande le précédent — donc toute
	# insertion en amont rompt la chaîne pour une progression existante. Reprendre
	# à un joueur l'accès à ce qu'il a terminé ne se lit jamais comme une mise à
	# jour : cela se lit comme une perte de sauvegarde.
	if progress.is_solved(level_id):
		return true
	return progress.is_solved(String(LEVELS[i - 1]["id"]))

## Premier niveau non résolu et jouable, ou le dernier jouable si tout est
## résolu. Sert au bouton « Continuer » du menu.
static func next_playable(progress: Progress) -> String:
	var last := ""
	for entry_data in LEVELS:
		if not bool(entry_data["ready"]):
			continue
		last = String(entry_data["id"])
		if not progress.is_solved(last):
			return last
	return last

## --- CHAPITRES ------------------------------------------------------------
##
## Le numero de chapitre est DEDUIT de l'identifiant (`ch3_02` -> 3), jamais
## saisi a cote. Une seconde declaration serait une seconde verite, et l'on
## sait ce qu'il advient de celles-la : elles divergent, et la divergence ne se
## voit que par accident (invariant n°16).
static func chapter_of(level_id: String) -> int:
	if not level_id.begins_with("ch"):
		return 0
	var underscore := level_id.find("_")
	if underscore < 2:
		return 0
	return int(level_id.substr(2, underscore - 2))

## Titre de chapitre, tel que le CDC §7.2 les nomme.
const CHAPTER_TITLES := {
	1: "Le mouvement élémentaire",
	2: "La coordination",
	3: "La mémoire du monde",
	4: "Le transport",
	5: "Le sacrifice et la régulation",
	6: "L'exception",
}

static func chapter_title(chapter: int) -> String:
	return String(CHAPTER_TITLES.get(chapter, "Chapitre %d" % chapter))

## Numeros de chapitre presents au catalogue, en ordre croissant. Calcule, pas
## declare : ajouter un niveau suffit a faire apparaitre son chapitre.
static func chapters() -> Array[int]:
	var out: Array[int] = []
	for entry_data in LEVELS:
		var c := chapter_of(String(entry_data["id"]))
		if c > 0 and not out.has(c):
			out.append(c)
	out.sort()
	return out

## Un chapitre est ouvert des que son PREMIER niveau l'est. Le verrouillage
## reste celui des niveaux : on n'ajoute pas une seconde serrure par-dessus.
## UN CHAPITRE OÙ L'ON A DÉJÀ JOUÉ N'EST PAS VERROUILLÉ, quoi qu'en dise son
## premier niveau.
##
## LE DÉFAUT S'EST VU SUR L'APPAREIL, et il vient de l'INSERTION d'un niveau au
## milieu du catalogue. Le verrou est en chaîne — chaque niveau demande le
## précédent — donc ajouter ch2_06 avant le chapitre 3 a reverrouillé son
## premier niveau pour une progression existante. L'écran affichait alors
## « Chapitre 3 — verrouillé » au-dessus de trois niveaux marqués RÉSOLUS.
##
## Une contradiction pareille ne se lit pas comme une conséquence de mise à
## jour : elle se lit comme un défaut, et le joueur se demande s'il a perdu sa
## progression. Le verrou du niveau inséré reste, lui — le jouer est justement
## ce qu'on lui propose — mais le chapitre cesse de mentir sur ce qu'il contient.
static func is_chapter_unlocked(chapter: int, progress: Progress) -> bool:
	for entry_data in LEVELS:
		if chapter_of(String(entry_data["id"])) != chapter:
			continue
		if progress.is_solved(String(entry_data["id"])):
			return true
	for entry_data in LEVELS:
		if chapter_of(String(entry_data["id"])) == chapter:
			return is_unlocked(String(entry_data["id"]), progress)
	return false

## Niveaux resolus / total pour un chapitre — le seul chiffre que l'ecran de
## selection ait besoin d'afficher a cote d'un titre.
static func chapter_progress(chapter: int, progress: Progress) -> Vector2i:
	var solved := 0
	var total := 0
	for entry_data in LEVELS:
		if chapter_of(String(entry_data["id"])) != chapter:
			continue
		total += 1
		if progress.is_solved(String(entry_data["id"])):
			solved += 1
	return Vector2i(solved, total)

static func load_level_data(level_id: String) -> Dictionary:
	var path := path_of(level_id)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
