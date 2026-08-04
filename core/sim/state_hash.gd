class_name StateHash
extends RefCounted
## Empreinte d'état FNV-1a 64 bits en arithmétique entière pure (T-013,
## DT-09). Usages : tests d'or, vérification multi-architecture (ENF-05),
## contrôle d'intégrité des recettes (DT-14).
##
## Débordement d'entier signé : les int de GDScript sont des entiers signés
## 64 bits dont le débordement s'enroule silencieusement en complément à
## deux (comportement documenté du langage), sur toutes les plateformes.
## La multiplication par le nombre premier FNV déborde donc sans erreur et
## produit le même motif binaire qu'une multiplication non signée modulo
## 2^64 — c'est exactement la sémantique attendue par FNV-1a. L'empreinte
## peut ainsi être négative en tant qu'int signé : seul son motif de 64 bits
## fait foi (affichage en hexadécimal recommandé pour comparaison).
##
## Le décalage de base FNV (0xCBF29CE484222325 = 14695981039346656037) ne
## tient pas dans un int64 signé positif : on l'écrit sous sa forme signée
## équivalente (14695981039346656037 - 2^64).
const OFFSET_BASIS: int = -3750763034362895579
const PRIME: int = 1099511628211  # 0x100000001B3

## Empreinte de l'état complet et signifiant. Ordre de parcours FIXE et
## documenté — le modifier casse toutes les empreintes archivées :
##   1. tick, outcome, max_ticks
##   2. nombre d'agents, puis chaque agent par id croissant :
##      id, pos.x, pos.y, dir, flags
##   3. grille : size.x, size.y, puis cells, pheromone, cycle_index
##      (chacun dans l'ordre des index), puis nombre de cycles et chaque
##      cycle (period, active_ticks) dans l'ordre du tableau
##   4. compteurs : exited, lost, delivered
## Les paramètres de règles (rule_params) n'en font PAS partie : ce sont des
## données de configuration, pas de l'état simulé — leur empreinte propre
## relève des rapports du validateur (EQ-03).
static func hash_state(state: SimState) -> int:
	var h: int = OFFSET_BASIS

	h = _feed_int(h, state.tick)
	h = _feed_int(h, state.outcome)
	h = _feed_int(h, state.max_ticks)

	h = _feed_int(h, state.agents.size())
	for agent in state.agents:
		h = _feed_int(h, agent.id)
		h = _feed_int(h, agent.pos.x)
		h = _feed_int(h, agent.pos.y)
		h = _feed_int(h, agent.dir)
		h = _feed_int(h, agent.flags)

	h = _feed_int(h, state.grid.size.x)
	h = _feed_int(h, state.grid.size.y)
	for c in state.grid.cells:
		h = _feed_int(h, c)
	for p in state.grid.pheromone:
		h = _feed_int(h, p)
	for ci in state.grid.cycle_index:
		h = _feed_int(h, ci)
	h = _feed_int(h, state.grid.cycles.size())
	for cycle in state.grid.cycles:
		h = _feed_int(h, cycle.period)
		h = _feed_int(h, cycle.active_ticks)

	h = _feed_int(h, state.counters.exited)
	h = _feed_int(h, state.counters.lost)
	h = _feed_int(h, state.counters.delivered)

	return h

## Absorbe un int64 octet par octet, poids faible d'abord (petit-boutiste,
## fixe par convention — indépendant de la machine puisque réalisé par
## décalages, jamais par réinterprétation mémoire). Le masque & 0xFF annule
## l'extension de signe du décalage arithmétique.
static func _feed_int(h: int, value: int) -> int:
	for k in range(8):
		var byte: int = (value >> (k * 8)) & 0xFF
		h = (h ^ byte) * PRIME  # débordement enroulant voulu (cf. en-tête)
	return h

## Représentation hexadécimale non signée sur 16 caractères, pour l'affichage
## et l'archivage des empreintes d'or (stable quel que soit le signe). Formatée
## en deux moitiés de 32 bits masquées, toujours positives : le formatage
## direct d'un int64 négatif produirait un signe « - », pas son motif binaire.
static func to_hex(h: int) -> String:
	var hi: int = (h >> 32) & 0xFFFFFFFF
	var lo: int = h & 0xFFFFFFFF
	return "%08x%08x" % [hi, lo]
