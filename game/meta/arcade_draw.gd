class_name ArcadeDraw
extends RefCounted
## LE TIRAGE DES RÈGLES du mode Épreuve.
##
## IL EST CONSTRUIT À PARTIR D'UNE SOLUTION, JAMAIS FILTRÉ APRÈS COUP. On tire
## d'abord un ensemble suffisant — un ensemble de règles dont on SAIT qu'une
## pile gagnante existe —, puis on ajoute des leurres. Un tirage aléatoire qu'on
## vérifierait ensuite pourrait échouer indéfiniment sur un niveau où les
## ensembles suffisants sont rares ; celui-ci est juste par construction.
##
## L'ALÉATOIRE VIT ICI, ET NULLE PART DANS `core/`. Il produit une donnée — la
## liste des règles offertes — qui est ensuite transmise à une simulation
## strictement déterministe (invariants 6 et 7). Deux joueurs qui reçoivent la
## même main jouent le même jeu.
##
## LE TIRAGE EST REPRODUCTIBLE : il ne dépend que de la graine de l'épreuve et
## de l'identifiant du niveau. Rejouer la même épreuve rejoue la même main, ce
## qui rend un échec analysable — et une épreuve partageable, un jour, par sa
## seule graine.

## Nombre de leurres ajoutés à l'ensemble suffisant, quand le niveau en offre
## assez. UN SEUL, et c'est un choix : deux leurres sur un ensemble de deux
## règles rendraient la main indiscernable de la bibliothèque complète, et le
## tirage n'aurait plus de sens. Un leurre suffit à interdire de poser
## mécaniquement tout ce qu'on a reçu.
const DECOYS := 1

static func draw(level_id: String, sufficient: Array, allowed: Array, run_seed: int) -> Array[int]:
	var out: Array[int] = []
	if sufficient.is_empty():
		# Repli : aucun ensemble connu — on rend la bibliothèque entière plutôt
		# qu'une main qui pourrait être injouable. Mieux vaut un niveau facile
		# qu'un niveau impossible dont rien n'explique l'impossibilité.
		for r in allowed:
			out.append(int(r))
		return out

	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(run_seed, level_id)

	var chosen: Array = sufficient[rng.randi_range(0, sufficient.size() - 1)]
	for r in chosen:
		out.append(int(r))

	# Leurres pris parmi ce que le niveau offre et que la solution n'emploie pas.
	var pool: Array[int] = []
	for r in allowed:
		if not out.has(int(r)):
			pool.append(int(r))
	for i in range(mini(DECOYS, pool.size())):
		var pick: int = rng.randi_range(0, pool.size() - 1)
		out.append(pool[pick])
		pool.remove_at(pick)

	out.sort()
	return out

## Graine dérivée : deux niveaux d'une même épreuve doivent recevoir des mains
## indépendantes, sans quoi la première main révélerait les suivantes.
static func _mix(run_seed: int, level_id: String) -> int:
	var h: int = run_seed
	for b in level_id.to_utf8_buffer():
		h = StateHash.feed_int(h, b)
	return h
