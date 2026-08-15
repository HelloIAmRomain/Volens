extends GutTest
## RÉGLAGES DE PROJET QUI NE SE VOIENT QUE SUR L'APPAREIL.
##
## POURQUOI CE FICHIER EXISTE. `display/window/handheld/orientation` valait la
## chaîne « portrait » — syntaxe Godot 3. Godot 4 attend un ENTIER ; la valeur
## retombait donc à 0, c'est-à-dire **paysage**, et le jeu s'affichait couché
## sur le téléphone. Sur le poste de développement rien ne le disait : la
## fenêtre y est portrait par sa seule taille, et le réglage n'a aucun effet.
##
## C'est une neuvième forme du piège de l'invariant n°12 : le réglage n'était
## sollicité QUE sur l'appareil, donc jamais éprouvé là où il travaille. Un
## catalogue entier dessiné en portrait, une grille cadrée en portrait, des
## captures en portrait — et la seule valeur qui décide vraiment était fausse.
##
## Tout réglage dont l'effet est invisible en développement a sa place ici.

func _setting(name: String) -> Variant:
	return ProjectSettings.get_setting(name)

func test_the_game_is_locked_to_portrait() -> void:
	var value: Variant = _setting("display/window/handheld/orientation")
	assert_typeof(value, TYPE_INT,
		("L'orientation doit être un ENTIER (énumération Godot 4), pas une "
		+ "chaîne : « portrait » est de la syntaxe Godot 3 et retombe "
		+ "silencieusement sur paysage. Valeur lue : %s") % str(value))
	assert_eq(int(value), DisplayServer.SCREEN_PORTRAIT,
		"Le jeu est dessiné en portrait de bout en bout ; toute autre orientation le couche.")

func test_the_base_resolution_is_portrait() -> void:
	# Cohérence : la résolution de base et l'orientation doivent dire la même
	# chose. Deux réglages qui se contredisent, c'est l'un des deux qui ment.
	var w := int(_setting("display/window/size/viewport_width"))
	var h := int(_setting("display/window/size/viewport_height"))
	assert_gt(h, w, "la résolution de base doit être plus haute que large (%d×%d)" % [w, h])

func test_the_desktop_window_keeps_the_same_ratio() -> void:
	# La fenêtre de bureau est réduite, jamais déformée : un cadrage éprouvé sur
	# un ratio différent de celui de l'appareil ne prouve rien (invariant n°12).
	var w := float(_setting("display/window/size/viewport_width"))
	var h := float(_setting("display/window/size/viewport_height"))
	var ow := float(_setting("display/window/size/window_width_override"))
	var oh := float(_setting("display/window/size/window_height_override"))
	if ow <= 0.0 or oh <= 0.0:
		assert_true(true, "aucune fenêtre de bureau imposée : rien à vérifier")
		return
	assert_almost_eq(ow / oh, w / h, 0.02,
		"la fenêtre de bureau (%d×%d) déforme le ratio de base (%d×%d)" % [ow, oh, w, h])
