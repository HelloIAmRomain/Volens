class_name ReplaySession
extends RefCounted
## Session de relecture (T-033) : clichés-clés et remontée du temps
## [DT-11, DT-12]. Pilote core/sim/ tick par tick, conserve un cliché
## complet tous les N ticks, et atteint n'importe quel tick passé par
## restauration du cliché le plus proche puis re-simulation — jamais par
## pile d'annulations.
##
## La recette (DT-11) est (niveau, pile) : grâce au déterminisme, rejouer
## depuis le tick 0 reconstruit exactement tout état intermédiaire. La pile
## est figée pour la durée de la session : modifier la pile = nouvel essai
## = nouvelle session (RG-10).
##
## Ce module n'importe que core/sim/ (sens autorisé : replay → sim).
## Aucun temps réel : la cadence d'appel est l'affaire de l'appelant (DT-06).

## Intervalle de clichés par défaut [DT-12] : ⚙️ d'équilibrage technique —
## ≤ 12 clichés pour un niveau de 300 ticks, re-simulation ≤ 24 ticks.
const DEFAULT_SNAPSHOT_INTERVAL: int = 25

var _stack: Array[int] = []
var _snapshot_interval: int = DEFAULT_SNAPSHOT_INTERVAL
## Clichés indexés par tick/intervalle : _snapshots[k] = état au tick k*N.
## L'état initial (tick 0) est toujours le cliché 0.
var _snapshots: Array[SimState] = []
var _current: SimState

func _init(initial_state: SimState, stack: Array[int], snapshot_interval: int = DEFAULT_SNAPSHOT_INTERVAL) -> void:
	assert(snapshot_interval > 0)
	_snapshot_interval = snapshot_interval
	_stack = stack.duplicate()
	# Cliché du tick 0 : copie défensive — l'appelant garde sa référence.
	_snapshots.append(initial_state.clone())
	_current = initial_state.clone()

## État courant (lecture seule par convention : le muter casserait la
## cohérence des clichés — core/ ne peut pas l'imposer sans coût, la revue
## et les tests d'or s'en chargent).
func current() -> SimState:
	return _current

func current_tick() -> int:
	return _current.tick

func stack() -> Array[int]:
	return _stack.duplicate()

## Avance d'un tick et archive un cliché si le tick atteint est un multiple
## de l'intervalle. Avancer au-delà d'une issue décidée est permis : l'état
## terminal est stable (contrat vérifié par les tests d'or).
func step_forward() -> SimState:
	_current = SimCore.step(_current, _stack)
	if _current.tick % _snapshot_interval == 0:
		# Division entière exacte : tick est un multiple de l'intervalle ici.
		@warning_ignore("integer_division")
		var slot: int = _current.tick / _snapshot_interval
		if slot == _snapshots.size():
			_snapshots.append(_current.clone())
	return _current

## Atteint le tick demandé, en avant ou en arrière [DT-12] : restaure le
## cliché le plus proche ≤ cible puis re-simule. Ticks négatifs ramenés à 0.
func seek(target_tick: int) -> SimState:
	var target: int = maxi(target_tick, 0)
	# Division entière volontaire : index du dernier cliché ≤ cible.
	@warning_ignore("integer_division")
	var best_slot: int = target / _snapshot_interval
	var slot: int = mini(best_slot, _snapshots.size() - 1)
	# En avant depuis l'état courant : inutile de repartir d'un cliché si le
	# courant est déjà plus proche (et jamais au-delà de la cible).
	if _current.tick <= target and _current.tick >= slot * _snapshot_interval:
		while _current.tick < target:
			step_forward()
		return _current
	_current = _snapshots[slot].clone()
	while _current.tick < target:
		step_forward()
	return _current

## Réinitialise l'essai (EF-04) : retour au tick 0, pile conservée.
func reset() -> SimState:
	_current = _snapshots[0].clone()
	return _current

func snapshot_count() -> int:
	return _snapshots.size()
