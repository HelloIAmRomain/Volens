class_name Counters
extends RefCounted
## Compteurs d'objectifs [DCT §4.1].

var exited: int = 0     # agents sortis (RG-14 Sortie)
var lost: int = 0       # agents perdus (RG-14 danger)
var delivered: int = 0  # ressources livrées (R12)

func clone() -> Counters:
	var copy := Counters.new()
	copy.exited = exited
	copy.lost = lost
	copy.delivered = delivered
	return copy
