extends SceneTree
## CE QUE LE TIRAGE DE L'EPREUVE RETIRE VRAIMENT, apres l'elargissement des
## bibliotheques. Il ne retirait rien dans 24 niveaux sur 29 ; la question est
## de savoir si cela a change, et il faut le MESURER, pas l'esperer.
func _init() -> void:
	var removed_total := 0
	var levels := 0
	var never := PackedStringArray()
	for i in range(LevelCatalog.count()):
		var e: Dictionary = LevelCatalog.entry(i)
		if not bool(e["ready"]):
			continue
		var id := String(e["id"])
		var allowed: Array = LevelCatalog.load_level_data(id).get("allowed_rules", [])
		var sets := ArcadeData.sufficient_sets(id)
		var worst := 99
		var best := 0
		for s in range(60):
			var n: int = ArcadeDraw.draw(id, sets, allowed, s).size()
			worst = mini(worst, n)
			best = maxi(best, n)
		levels += 1
		removed_total += allowed.size() - best
		if best >= allowed.size():
			never.append(id)
		print("%-8s lib=%d  main=%d..%d  retire %d..%d" % [
			id, allowed.size(), worst, best,
			allowed.size() - best, allowed.size() - worst])
	print("")
	print("Niveaux ou le tirage ne retire JAMAIS rien : %d sur %d%s" % [
		never.size(), levels,
		("  (" + ", ".join(never) + ")") if never.size() > 0 else ""])
	quit()
