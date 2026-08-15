class_name TrialRun
extends RefCounted
## MODE « ÉPREUVE » — le second mode de jeu.
##
## POURQUOI IL EXISTE, ET CE QU'IL CORRIGE. La mesure du parcours a nommé le
## risque du mode normal : **l'espace des piles est épuisable.** La moitié des
## niveaux offrent seize piles ; un joueur qui renonce à comprendre les essaie
## toutes en quelques minutes. La difficulté n'est pas dans la recherche, elle
## est dans la compréhension — et rien n'oblige à comprendre.
##
## L'Épreuve rend la force brute COÛTEUSE. **Un seul ingrédient y parvient, et
## il faut le dire dans cet ordre — l'inverse serait une jolie phrase fausse.**
##
## 1. **LES LANCEMENTS SONT COMPTÉS, et partagés par tout le chapitre.** Chaque
##    fois que le joueur lance la simulation, le compteur descend. Essayer
##    seize piles au premier niveau, c'est arriver au deuxième sans rien.
##    Comprendre devient moins cher que chercher — ce qui est exactement la
##    proposition du jeu, enfin opposable.
##
##    MESURÉ, pas espéré (15 août 2026) : la somme des rangs de la première
##    pile gagnante vaut 32, 75, 36, 71, 63 et 73 lancements selon le chapitre,
##    contre des budgets de 25, 25, 20, 20, 30 et 25. La force brute coûte de
##    1,3 à 3,5 fois le budget accordé, partout. `tests/unit/test_trial_bite.gd`
##    refuse que cela cesse d'être vrai.
##
## 2. **LES RÈGLES SONT TIRÉES — et ce second ingrédient a failli être vide.**
##    Le niveau n'offre plus toute sa bibliothèque mais un sous-ensemble garanti
##    jouable.
##
##    IL NE RETIRAIT D'ABORD RIEN, dans 24 niveaux sur 29 : les bibliothèques ne
##    comptaient que trois ou quatre règles, presque toutes necessaires. On ne
##    restreint pas le choix des règles quand il n'y a rien à choisir — et un
##    quota par règle aurait été vide pour exactement la même raison.
##
##    LE DEFAUT ETAIT DANS LES NIVEAUX, PAS DANS LE MODE. Le 15 août 2026, les
##    bibliothèques sont passées à cinq ou six règles pour trois rangs (carnet,
##    décision 181). Mesuré depuis : **le tirage retire 1 à 3 règles dans 20
##    niveaux sur 29**, et les neuf exceptions sont les chapitres 1 et 2, dont
##    l'étroitesse est voulue — ils enseignent.
##
##    Morale, et elle vaut au-delà d'ici : un mécanisme peut être correct et
##    sans effet, l'effet dépendant de données qu'il ne contrôle pas. Le
##    vérifier SÛR ne dit rien de son UTILITÉ (invariant n°12, huitième forme).
##
## **L'HONNÊTETÉ DU TIRAGE EST UNE CONDITION, PAS UNE PRÉCAUTION.** Un tirage
## qui ne contiendrait aucune solution ferait perdre des lancements sur un
## niveau impossible, sans que rien ne le dise. Il est donc construit À PARTIR
## d'un ensemble suffisant, jamais filtré après coup.
##
## L'ALÉATOIRE VIT ICI, JAMAIS DANS `core/`. Le tirage est fait avant la
## simulation et lui est transmis comme une donnée ; `SimCore` reste pur,
## déterministe et sans horloge (invariants 6 et 7). Le tirage est d'ailleurs
## reproductible : même graine, même main.

## Lancements accordés pour un chapitre entier.
##
## CALIBRÉ SUR LA MESURE, pas choisi : le rang médian de la première pile
## gagnante est de 9 sur l'ensemble du catalogue. Un joueur qui cherche au
## hasard consomme donc environ 9 lancements par niveau ; un joueur qui
## raisonne en consomme 2 ou 3. À 5 par niveau, le premier échoue et le second
## garde de la marge — c'est précisément la frontière qu'on veut tracer.
const LAUNCHES_PER_LEVEL := 5

var chapter: int = 0
var level_ids: Array[String] = []
var index: int = 0
var launches_left: int = 0
var seed_value: int = 0
var failed: bool = false

static func start(chapter_number: int, run_seed: int) -> TrialRun:
	var run := TrialRun.new()
	run.chapter = chapter_number
	run.seed_value = run_seed
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		if LevelCatalog.chapter_of(String(entry["id"])) == chapter_number:
			run.level_ids.append(String(entry["id"]))
	run.launches_left = run.level_ids.size() * LAUNCHES_PER_LEVEL
	return run

func current_level() -> String:
	return level_ids[index] if index < level_ids.size() else ""

func is_finished() -> bool:
	return failed or index >= level_ids.size()

func is_won() -> bool:
	return not failed and index >= level_ids.size()

## Un lancement consommé. Renvoie `false` s'il n'en restait aucun — l'épreuve
## est alors perdue, et elle l'est SUR LE CHAMP : laisser jouer un lancement
## qu'on n'a pas serait mentir sur la seule ressource du mode.
func spend_launch() -> bool:
	if launches_left <= 0:
		failed = true
		return false
	launches_left -= 1
	if launches_left <= 0:
		# Le dernier lancement est accordé ; c'est la tentative SUIVANTE qui
		# sera refusée. Un compteur à zéro n'est pas encore un échec.
		pass
	return true

func advance() -> void:
	index += 1

## Les règles offertes pour le niveau courant. Déterministe pour une graine et
## un niveau donnés : rejouer la même épreuve rejoue la même main.
func draw_for(level_id: String, sufficient: Array, allowed: Array) -> Array[int]:
	return ArcadeDraw.draw(level_id, sufficient, allowed, seed_value)

func to_dict() -> Dictionary:
	return {
		"chapter": chapter,
		"index": index,
		"launches_left": launches_left,
		"seed": seed_value,
		"failed": failed,
	}

static func from_dict(d: Dictionary) -> TrialRun:
	var run := TrialRun.start(int(d.get("chapter", 1)), int(d.get("seed", 0)))
	run.index = int(d.get("index", 0))
	run.launches_left = int(d.get("launches_left", run.launches_left))
	run.failed = bool(d.get("failed", false))
	return run
