class_name CycleDef
extends RefCounted
## Définition d'un cycle de danger [DCT §4.1, RG-08] : période et phase fixes,
## visibles et prévisibles. Aucun aléatoire (DT-05).
##
## Actif quand (tick mod period) < active_ticks — comparaison entière pure.

var period: int = 1
var active_ticks: int = 0  # nombre de ticks actifs par période, à partir de la phase 0

func is_active_at(tick: int) -> bool:
	if period <= 0:
		return false
	return (tick % period) < active_ticks

func clone() -> CycleDef:
	var copy := CycleDef.new()
	copy.period = period
	copy.active_ticks = active_ticks
	return copy
