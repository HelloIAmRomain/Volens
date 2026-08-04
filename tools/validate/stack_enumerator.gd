class_name StackEnumerator
extends RefCounted
## Énumération de l'espace des piles (T-024, DCT §8.2) : tous les
## arrangements ordonnés de règles DISTINCTES parmi les règles autorisées du
## niveau, de longueur 0 à 4 (les emplacements vides en fin de pile sont
## équivalents à une pile plus courte ; un vide intercalé est sauté par la
## cascade — la forme compacte est donc canonique).
##
## Ordre d'énumération déterministe : par longueur croissante, puis
## lexicographique selon l'ordre du tableau `allowed` fourni. Pour 12 règles
## autorisées : P(12,0..4) = 1 + 12 + 132 + 1320 + 11880 = 13 345 piles —
## l'ordre de grandeur du DCT §8.3.

const MAX_SLOTS: int = 4  # RG-05 : la pile compte quatre emplacements

static func enumerate(allowed: Array[int]) -> Array:
	var results: Array = []
	var current: Array[int] = []
	var used: Array[bool] = []
	used.resize(allowed.size())
	for i in range(allowed.size()):
		used[i] = false
	for length in range(MAX_SLOTS + 1):
		_build(allowed, used, current, length, results)
	return results

static func _build(allowed: Array[int], used: Array[bool], current: Array[int], target_length: int, results: Array) -> void:
	if current.size() == target_length:
		results.append(current.duplicate())
		return
	for i in range(allowed.size()):
		if used[i]:
			continue
		used[i] = true
		current.append(allowed[i])
		_build(allowed, used, current, target_length, results)
		current.pop_back()
		used[i] = false

## Nombre attendu de piles pour n règles autorisées — sert d'auto-contrôle.
static func expected_count(n: int) -> int:
	var total := 0
	for k in range(mini(n, MAX_SLOTS) + 1):
		var arrangements := 1
		for j in range(k):
			arrangements *= n - j
		total += arrangements
	return total
