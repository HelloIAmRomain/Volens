class_name MechanicPrimer
extends RefCounted
## CE QU'UN ÉLÉMENT FAIT, DIT UNE FOIS, LA PREMIÈRE FOIS QU'ON LE VOIT.
##
## POURQUOI CE FICHIER EXISTE. Volens n'a pas de tutoriel, et c'est une décision
## de conception : « le jeu doit être limpide ». Mais limpide ne veut pas dire
## devinable — une plaque à pression et une bascule sont deux marques colorées
## dont rien, à l'écran, ne dit que l'une tient tant qu'on l'occupe et que
## l'autre s'enclenche pour de bon. Le joueur les découvre en perdant, et
## conclut que le jeu est capricieux.
##
## CE N'EST PAS UN TUTORIEL, ET LA DIFFÉRENCE EST NETTE :
##
##   · **une seule ligne**, celle qui manque à l'écran — jamais la stratégie, ni
##     ce qu'il faut en faire. Dire « posez deux agents dessus » retirerait au
##     joueur exactement le travail qu'on lui demande ;
##   · **une seule fois dans toute la partie**, à la première rencontre ;
##   · **rien à valider** : la carte se referme au premier contact, et le niveau
##     tourne déjà derrière.
##
## LE CATALOGUE EST CLOS ET IL SUIT RG-14. Une entrée de plus ici doit
## correspondre à un élément qui EXISTE sur une carte, et l'audit du vocabulaire
## (carnet, décision 197) est le garde-fou : un élément qu'aucun niveau ne porte
## n'a pas à être présenté.

## Élément -> nom lisible et phrase unique. La phrase dit CE QUE LA CASE FAIT,
## au présent, sans conseil : c'est une légende, pas un guide.
const ENTRIES := {
	GridState.CellType.STATIC_DANGER: {
		"key": "danger",
		"name": "Danger",
		"line": "Un agent qui entre ici est perdu.",
	},
	GridState.CellType.CYCLIC_DANGER: {
		"key": "danger_cyclique",
		"name": "Danger intermittent",
		"line": "Marqué aux quatre coins : celui-ci s'éteint, puis se rallume.",
	},
	GridState.CellType.RESOURCE: {
		"key": "ressource",
		"name": "Ressource",
		"line": "Un agent qui passe dessus l'emporte avec lui.",
	},
	GridState.CellType.DROPOFF: {
		"key": "depot",
		"name": "Dépôt",
		"line": "Un agent qui porte une ressource la laisse ici.",
	},
	GridState.CellType.PRESSURE_DOOR: {
		"key": "plaque",
		"name": "Plaque à pression",
		"line": "La porte reste ouverte tant que des agents sont dessus.",
	},
	GridState.CellType.SWITCH: {
		"key": "bascule",
		"name": "Bascule",
		"line": "Le premier agent qui la foule ouvre la porte pour de bon.",
	},
	GridState.CellType.SHIELD: {
		"key": "atelier",
		"name": "Atelier",
		"line": "Un agent qui traverse en repart protégé, pour un seul contact.",
	},
	GridState.CellType.LIGHT_SOURCE: {
		"key": "lumiere",
		"name": "Lumière",
		"line": "Ce que la nuée voit de loin. Ce n'est pas la sortie.",
	},
}

## LE SENS UNIQUE N'EST PAS UNE CASE, et l'audit du vocabulaire s'y était fait
## prendre : il vit dans `grid.one_way`, une liste à part. Le chercher parmi les
## valeurs de case le déclarait absent de niveaux qui le portent — un inventaire
## qui n'interroge qu'une seule représentation déclare morts les éléments rangés
## ailleurs.
const ONE_WAY_ENTRY := {
	"key": "sens_unique",
	"name": "Passage à sens unique",
	"line": "On le franchit dans un sens, jamais dans l'autre.",
}

## TOUTES les clés du vocabulaire, dans l'ordre fixe. Sert à marquer d'un coup
## l'ensemble des légendes comme vues — le banc de captures en a besoin : sans
## cela, chaque écran qu'il ouvre s'affiche sous une carte de légende, et les
## images produites montrent la légende au lieu du jeu.
static func all_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for cell in ENTRIES:
		keys.append(String((ENTRIES[cell] as Dictionary)["key"]))
	keys.append(String(ONE_WAY_ENTRY["key"]))
	return keys

## Les éléments présents sur cette carte, dans l'ordre fixe du vocabulaire —
## jamais dans l'ordre d'un `Dictionary`, qui varierait d'une exécution à
## l'autre et ferait apparaître les cartes dans un ordre différent à chaque
## partie.
static func present_in(level_data: Dictionary) -> Array:
	var grid: Dictionary = level_data.get("grid", {})
	var cells: Array = grid.get("cells", [])
	var found: Dictionary = {}
	for c in cells:
		var t := int(c)
		if ENTRIES.has(t):
			found[t] = true
	var size: Array = grid.get("size", [0, 0])
	var width: int = int(size[0]) if size.size() > 0 else 0
	var out: Array = []
	for t in [
			GridState.CellType.LIGHT_SOURCE,
			GridState.CellType.STATIC_DANGER,
			GridState.CellType.CYCLIC_DANGER,
			GridState.CellType.RESOURCE,
			GridState.CellType.DROPOFF,
			GridState.CellType.PRESSURE_DOOR,
			GridState.CellType.SWITCH,
			GridState.CellType.SHIELD]:
		if not found.has(t):
			continue
		# CHAQUE ENTRÉE PORTE SES CASES, et c'est ce qui la rend montrable.
		# Nommer « la lumière » sans désigner laquelle ne renseigne qu'à moitié :
		# le joueur lit un mot et cherche à quoi il correspond parmi huit
		# marques colorées.
		var entry: Dictionary = (ENTRIES[t] as Dictionary).duplicate()
		# LE TYPE VOYAGE AVEC L'ENTRÉE, et pas seulement ses coordonnées : la
		# surbrillance doit rendre à la case SA teinte. Un halo blanc uniforme
		# désigne bien, mais il montre au joueur une couleur qu'il ne reverra
		# jamais — il cherchera ensuite un carré blanc là où le jeu en met un
		# ambre.
		entry["cell"] = t
		var cells_of: Array = []
		for i in range(cells.size()):
			if int(cells[i]) == t and width > 0:
				@warning_ignore("integer_division")
				cells_of.append(Vector2i(i % width, i / width))
		entry["cells"] = cells_of
		out.append(entry)
	var one_way: Array = grid.get("one_way", [])
	if not one_way.is_empty():
		var ow: Dictionary = ONE_WAY_ENTRY.duplicate()
		ow["cell"] = GridState.CellType.ONE_WAY
		var ow_cells: Array = []
		for triplet in one_way:
			ow_cells.append(Vector2i(int(triplet[0]), int(triplet[1])))
		ow["cells"] = ow_cells
		out.append(ow)
	return out

## Ceux que le joueur n'a jamais vus. Au plus DEUX à la fois : trois cartes
## d'affilée devant un niveau qu'on vient d'ouvrir se referment sans être lues,
## et l'on aurait dépensé la seule occasion de les montrer.
static func unseen_in(level_data: Dictionary, seen: PackedStringArray) -> Array:
	var out: Array = []
	for entry in present_in(level_data):
		if not seen.has(String(entry["key"])):
			out.append(entry)
		if out.size() >= 2:
			break
	return out
