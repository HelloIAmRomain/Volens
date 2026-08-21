extends GutTest
## UNE CONDITION DE DÉFAITE NON ANNONCÉE N'EST PAS UNE DIFFICULTÉ, C'EST UN PIÈGE.
##
## HISTOIRE DE CE FICHIER. « J'ai testé le niveau 10, ça a fail à cause du temps
## mais l'objectif temps n'était pas inscrit. » Le message de défaite disait vrai
## — « le temps imparti s'est écoulé » — mais le panneau d'ouverture n'avait
## jamais parlé de temps : le joueur apprenait APRÈS COUP qu'une horloge courait.
##
## LA CAUSE ÉTAIT UN GLISSEMENT DE RÔLE, et c'est moi qui l'avais provoqué.
## `max_ticks` est une BORNE DE SÛRETÉ : elle empêche une simulation immobile de
## tourner pour toujours. J'avais serré celle de ch2_06 à trente pour écarter
## une pile qui résolvait quatre niveaux du jeu — c'est-à-dire pour faire un
## travail de CONCEPTION avec un garde-fou technique.
##
## **Un plafond qui décide du jeu doit se déclarer.** L'échéance est devenue un
## `objective: celerity`, qui s'annonce, s'explique en cas d'échec, et laisse
## `max_ticks` revenir à son office. Le niveau se joue à l'identique : quatre
## gagnantes, trois classes, avant comme après.
##
## CE QUE CE TEST PEUT VOIR, ET CE QU'IL NE PEUT PAS. Il compare le plafond au
## meilleur temps DÉCLARÉ par le défi d'efficience. Un niveau sans ce défi ne
## déclare pas son meilleur temps, et le test ne peut rien en dire — la mesure
## demanderait de rejouer tout l'espace des piles, ce que fait le validateur.
## Le contrôle porte donc sur ce qui est écrit, pas sur ce qui est vrai ; c'est
## une limite qu'il vaut mieux nommer que laisser croire couverte.

## Marge exigée entre le plafond et le meilleur temps connu. En deçà, le plafond
## n'est plus une sécurité : il tranche entre les solutions, et c'est un rôle
## d'objectif. Le double est aussi ce que la forge calibre, si bien qu'un niveau
## forgé passe exactement à la limite — l'égalité est donc acceptée.
const REQUIRED_MARGIN := 2

func test_no_level_lets_the_tick_cap_decide_in_silence() -> void:
	var guilty := PackedStringArray()
	var checked := 0
	for i in range(LevelCatalog.count()):
		var entry: Dictionary = LevelCatalog.entry(i)
		if not bool(entry["ready"]):
			continue
		var level_id := String(entry["id"])
		var data := LevelCatalog.load_level_data(level_id)
		var best: int = int(LevelSpec.challenges(data).get("efficiency_ticks", 0))
		if best <= 0:
			continue   # aucun temps déclaré : rien à comparer
		checked += 1
		if _announces_a_deadline(data):
			continue
		var cap: int = int(data.get("max_ticks", 0))
		if cap < best * REQUIRED_MARGIN:
			guilty.append("%s (plafond %d, meilleur temps %d)" % [level_id, cap, best])
	assert_gt(checked, 0,
		"aucun niveau ne déclare de temps de référence : le contrôle serait creux")
	assert_eq(guilty, PackedStringArray(),
		("plafond de ticks trop serré sans échéance annoncée : %s — le joueur perd "
		+ "sur une horloge dont personne ne lui a parlé. Déclarer un "
		+ "`objective: celerity`, ou desserrer le plafond.") % ", ".join(guilty))

func test_a_declared_deadline_is_what_the_player_reads() -> void:
	# L'AUTRE MOITIÉ : déclarer l'échéance ne sert à rien si l'écran ne la dit
	# pas. On interroge le texte que le panneau d'ouverture produit vraiment.
	var data := LevelCatalog.load_level_data("ch2_06")
	assert_true(_announces_a_deadline(data),
		"ch2_06 doit porter une échéance déclarée, sinon ce test est creux")
	var brief := RuleCatalog.objective_brief(
		data.get("objectives", []), (data.get("agents", []) as Array).size())
	var joined := " ".join(brief)
	assert_true(joined.contains("ticks"),
		("l'énoncé d'ouverture doit annoncer le temps imparti ; il dit : « %s »")
		% joined)

func _announces_a_deadline(data: Dictionary) -> bool:
	for o in data.get("objectives", []):
		if String((o as Dictionary).get("type", "")) == "celerity":
			return true
	return false
