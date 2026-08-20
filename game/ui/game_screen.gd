class_name GameScreen
extends Control
## Écran de jeu [T-032, DCT §9.2].
##
## DISPOSITION, et l'arbitrage qui la décide. Le concepteur veut le transport
## en haut à droite et le bas réservé aux règles. ENF-01 exige que toute
## commande soit atteignable au pouce, et interdit les actions critiques dans
## le tiers supérieur. Les deux tiennent grâce à une mesure (UiMetrics) :
## sur 1080x2400, le tiers supérieur (y <= 720) est hors de portée en prise à
## une main sur un écran de 6,8 pouces. On y place donc les boutons de
## transport comme AFFORDANCE VISIBLE, et l'on garantit un **second chemin**
## dans la zone confortable : **un appui sur la grille bascule marche/pause**.
## Le bouton du haut n'est jamais requis — il montre l'état et sert à la
## souris ; le pouce, lui, touche la grille.
##
## Le bouton fermer va en HAUT À GAUCHE, à l'opposé du transport : fermer par
## erreur en cherchant pause serait le pire défaut de cet écran.
##
## Le rembobinage disparaît de l'interface, pas du code : `core/replay/`
## garde ses clichés-clés et sa remontée du temps (DT-11/12). C'est
## l'affordance qu'on retire, jamais la capacité.

signal finished(level_id: String, won: bool, ticks: int, lost: int, stack: Array, reason: String)
signal quit_requested
signal state_changed

## ×1 → ×2 → ×3 → ×1 (RG-10 : « au moins trois vitesses »).
## LA VITESSE EST EN TICKS PAR SECONDE, et elle valait UN. Un niveau de
## quarante ticks demandait donc quarante secondes d'attente au joueur, qui
## regardait une nuee avancer d'une case par seconde : « le jeu est trop lent,
## les attentes sont frustrantes » — essai sur l'appareil, 15 aout 2026.
##
## Le probleme n'etait pas le nombre de vitesses (RG-10 en exige trois, il y en
## a trois) mais leur ECHELLE. Les glyphes restent des multiplicateurs RELATIFS
## — c'est ce qu'un joueur lit — et non la cadence.
##
## PREMIER REGLAGE A 4/8/16 : « un peu trop rapide » a l'essai. Ramene a 3/6/12,
## soit un niveau de quarante ticks en treize secondes a la vitesse la plus
## lente. On regle une cadence en SECONDES D'ATTENTE REELLES, jamais en
## multiplicateurs — c'est ce que le premier chiffre (un tick par seconde)
## n'avait jamais ete mesure.
const SPEEDS: Array[float] = [3.0, 6.0, 12.0]
## LA VITESSE NE SE DESSINE PLUS AVEC UN TRIANGLE. Elle en portait un, creux,
## à côté du triangle plein de la lecture : deux formes identiques au pouce,
## qui obligeaient à comparer un remplissage pour savoir sur quoi on appuie.
## Tout glyphe fléché rouvrirait la confusion — chevrons, doubles pointes,
## bobine : ce sont tous des triangles. Le multiplicateur écrit est la seule
## forme qui ne ressemble à rien d'autre à l'écran, se lit sans apprentissage
## et ne dépend d'aucun caractère exotique.
const SPEED_GLYPHS: Array[String] = ["×1", "×2", "×4"]

var _view: SimView
var _view_host: SubViewportContainer
var _viewport: SubViewport
var _objective_label: Label
var _slots: Array[RuleSlot] = []
var _chips: Array[RuleChip] = []
var _panel: PanelContainer
var _explain_panel: Panel
var _explain_label: Label
var _play_button: Button
var _speed_button: Button

var _level_data: Dictionary = {}
var _level_id: String = ""
var _params: RuleParams
var _allowed: Array[int] = []

## Nombre de rangs OUVERTS sur ce niveau (`slots`). La pile en compte quatre
## (RG-05), mais un niveau en déclare moins — et le validateur n'énumère les
## piles que jusqu'à ce nombre. Laisser le joueur en remplir quatre lui
## permettrait de trouver une solution que personne n'a validée.
var _open_slots: int = UiMetrics.SLOT_COUNT
var _stack: Array[int] = []
## Règle sélectionnée en attente de destination, et sa provenance :
## -1 = le panneau, >= 0 = l'emplacement d'où elle vient (pour l'échange).
var _selected_rule: int = RuleRegistry.EMPTY
var _selected_from: int = -1
var _has_selection: bool = false
var _playing: bool = false
var _speed_index: int = 0
var _finished: bool = false
## Temps mort ⚙️ entre l'instant où la simulation tranche et l'écran de bilan.
## La simulation atteint LOST au tick où l'objectif devient inatteignable —
## souvent avant que rien de visible ne se soit produit. Sans ce délai, le
## bilan surgit sur un écran où il ne s'est apparemment rien passé, et
## l'échec devient inexplicable (pilier P4).
## PORTE A 2,2 s. La marque de mort avait besoin de son temps d'ecran — sauf
## qu'elle n'etait jamais dessinee (voir SimView._mark_departures), et que la
## simulation tourne desormais quatre fois plus vite. Le joueur voyait un ecran
## de defaite arriver sur une scene ou il ne s'etait visiblement rien passe :
## « les echecs sont incompris ». L'echo dure 1,6 s ; le bilan attend qu'il
## finisse, plus une demi-seconde pour comprendre ce qu'on vient de voir.
const OUTCOME_DELAY := 2.2
var _outcome_countdown: float = -1.0
var _objective_panel: Panel
var _edge_echo: Control
var _banner_flash: float = 0.0
var _objective_panel_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	get_viewport().size_changed.connect(_layout)

func load_level(level_data: Dictionary, params: RuleParams, level_id: String = "") -> void:
	_level_data = level_data
	_level_id = level_id
	_params = params
	_finished = false
	_allowed = []
	for v in level_data.get("allowed_rules", [1]):
		_allowed.append(int(v))
	# LECTURE UNIQUE, partagée avec le validateur (`LevelSpec`). Toute autre
	# lecture de la clé `slots` est un défaut : voir invariant n°11.
	_open_slots = LevelSpec.open_slots(level_data)
	for i in range(_slots.size()):
		_slots[i].set_locked(i >= _open_slots)
	_stack = []
	for i in range(UiMetrics.SLOT_COUNT):
		_stack.append(RuleRegistry.EMPTY)
	_build_chips()
	_apply_stack()

# --- reprise (EF-20/21) ---------------------------------------------------

func store_session(session: Session) -> void:
	session.level_id = _level_id
	session.stack = _compact_stack()
	session.tick = _view.current_state().tick if _view != null and _view.current_state() != null else 0
	session.speed_index = _speed_index

func restore_session(session: Session) -> void:
	# Tick et vitesse lus D'ABORD : `_apply_stack()` émet `state_changed`,
	# que l'application relaie vers la sauvegarde — laquelle réécrirait
	# `session.tick` avec zéro avant qu'on s'en serve.
	var target_tick: int = session.tick
	var target_speed: int = session.speed_index
	for i in range(mini(session.stack.size(), UiMetrics.SLOT_COUNT)):
		_stack[i] = session.stack[i]
	_apply_stack()
	if target_tick > 0:
		_view.seek(target_tick)
	_speed_index = clampi(target_speed, 0, SPEEDS.size() - 1)
	_playing = false
	_refresh_transport()

func set_speed_index(index: int) -> void:
	_speed_index = clampi(index, 0, SPEEDS.size() - 1)
	_refresh_transport()

# --- construction ---------------------------------------------------------

func _build() -> void:
	# LE JEU EST LE FOND. La vue est le PREMIER enfant, donc le plus bas de la
	# pile de dessin comme de l'entrée : tout ce qui suit — barres, bandeau,
	# pile, panneaux — se pose au-dessus d'elle. L'ordre inverse produisait
	# l'effet d'un écran encastré dans un autre, et donnait l'entrée à la vue
	# par-dessus les boutons.
	_view_host = SubViewportContainer.new()
	_view_host.stretch = true
	_view_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_view_host.gui_input.connect(_on_view_input)
	add_child(_view_host)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view_host.add_child(_viewport)
	_viewport.size_changed.connect(func() -> void: if _view != null: _view._on_viewport_resized())
	_view = SimView.new()
	# Une sortie d'agent se voit (le compteur monte, l'agent s'efface) ET se
	# sent. Jamais l'inverse : le retour haptique double, il n'informe pas seul.
	_view.agents_exited.connect(func(_count: int) -> void: Haptics.exited())
	_viewport.add_child(_view)

	# Barre haute gauche : quitter, puis réinitialiser (EF-04). Loin du
	# transport, exprès.
	var left_row := HBoxContainer.new()
	left_row.name = "LeftBar"
	left_row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(left_row)
	var quit := _make_button("✕", "Retour aux niveaux")
	quit.pressed.connect(func() -> void: quit_requested.emit())
	left_row.add_child(quit)
	var reset := _make_button("↺", "Réinitialiser l'essai")
	reset.pressed.connect(func() -> void: _pause(); _view.reset(); _hide_explain(); _notify_state())
	left_row.add_child(reset)

	# Barre haute droite : marche/pause et vitesse. Doublées par l'appui sur
	# la grille, donc jamais le seul chemin (ENF-01).
	var right_row := HBoxContainer.new()
	right_row.name = "RightBar"
	right_row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(right_row)
	_play_button = _make_button("▶", "Marche / pause — ou appui sur la grille", UiButtons.Rank.PRIMARY)
	_play_button.pressed.connect(_toggle_play)
	right_row.add_child(_play_button)
	_speed_button = _make_button("▷", "Vitesse de lecture", UiButtons.Rank.SECONDARY)
	_speed_button.pressed.connect(_cycle_speed)
	right_row.add_child(_speed_button)

	_objective_label = Label.new()
	_objective_label.add_theme_font_size_override("font_size", UiMetrics.font_size(28))
	_objective_label.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	# L'interface est PAR-DESSUS le jeu : elle doit rester lisible sur
	# n'importe quel fond, y compris le halo d'une source de lumière. Un
	# contour sombre suffit et n'ajoute aucune boîte — poser un bandeau opaque
	# recréerait le cadre qu'on vient d'enlever.
	_objective_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.9))
	_objective_label.add_theme_constant_override("outline_size", 8)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Le bandeau est CLIQUABLE : il rouvre l'énoncé complet à tout moment.
	_objective_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_objective_label.gui_input.connect(_on_banner_input)
	add_child(_objective_label)

	_build_stack_bar()
	_build_panel()
	_build_explain_panel()
	_build_objective_panel()

	# HALO DE BORD — l'issue se lit AUSSI a la peripherie. Un joueur qui suit un
	# agent des yeux au centre de l'ecran ne verra pas un changement discret ;
	# une bordure qui s'allume est perceptible sans etre regardee.
	_edge_echo = _EdgeEcho.new()
	_edge_echo.name = "EdgeEcho"
	_edge_echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_edge_echo)
	_edge_echo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout()

func _build_stack_bar() -> void:
	var row := HBoxContainer.new()
	row.name = "StackBar"
	row.add_theme_constant_override("separation", int(UiMetrics.GAP))
	add_child(row)
	for i in range(UiMetrics.SLOT_COUNT):
		var slot := RuleSlot.new(i)
		slot.rule_dropped.connect(_on_rule_dropped)
		slot.tapped.connect(_on_slot_tapped.bind(i))
		slot.long_pressed.connect(_on_slot_long_pressed.bind(i))
		slot.remove_requested.connect(_on_remove_requested)
		row.add_child(slot)
		_slots.append(slot)

## Les boutons passent par `UiButtons` : la cible tactile minimale (ENF-01)
## et les registres visuels y sont posés une seule fois, pour tous les écrans.
func _make_button(text: String, tip: String, rank: int = UiButtons.Rank.QUIET) -> Button:
	return UiButtons.make(text, rank, 30, tip)

func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "RulePanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.border_width_top = 2
	style.border_color = Color(0.25, 0.28, 0.36)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	add_child(_panel)

	# LE TIROIR ENVELOPPE, IL NE DÉBORDE PAS. Un `HBoxContainer` posait les
	# règles sur une ligne unique, quelle qu'en soit la largeur : à quatre
	# règles sur un écran de 720 la dernière sortait de l'écran, donc devenait
	# injouable — et le joueur n'avait aucun moyen de savoir qu'elle existait.
	#
	# Ce n'est pas un détail d'affichage : tout ce qui suit (élargir les
	# bibliothèques pour rendre au joueur un vrai choix) fait passer les niveaux
	# de trois à cinq ou six règles. Corriger la disposition d'abord, sinon la
	# correction de fond casse l'écran.
	# GRILLE A COLONNES CALCULEES, et non conteneur a enveloppe automatique.
	# `HFlowContainer` enveloppait bien, mais sa taille MINIMALE est celle d'une
	# colonne unique : le `PanelContainer` qui l'heberge s'y ajustait, et le
	# tiroir occupait tout l'ecran — bouton de lancement compris — pour six
	# regles disposees sur trois rangs. Une grille annonce sa taille exacte.
	var row := GridContainer.new()
	row.name = "ChipRow"
	row.columns = 2
	row.add_theme_constant_override("h_separation", int(UiMetrics.GAP))
	row.add_theme_constant_override("v_separation", int(UiMetrics.GAP))
	_panel.add_child(row)

func _build_chips() -> void:
	var row := _panel.get_node("ChipRow") as GridContainer
	row.columns = _chips_per_row(_panel_width())
	for child in row.get_children():
		child.queue_free()
	_chips = []
	# Le retrait passe désormais par l'icône de l'emplacement sélectionné,
	# plus par une pastille aussi grosse qu'une règle.
	for rule_id in _allowed:
		var chip := RuleChip.new(rule_id)
		chip.tapped.connect(_on_chip_tapped.bind(rule_id))
		chip.long_pressed.connect(_on_chip_long_pressed.bind(rule_id))
		row.add_child(chip)
		_chips.append(chip)

func _build_explain_panel() -> void:
	_explain_panel = Panel.new()
	_explain_panel.name = "ExplainPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.97)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = Color(0.35, 0.85, 1.0, 0.85)
	_explain_panel.add_theme_stylebox_override("panel", style)
	_explain_panel.visible = false
	_explain_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_explain_panel)

	_explain_label = Label.new()
	# Sans enveloppe, une phrase de règle sortait de l'écran par la droite.
	_explain_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explain_label.add_theme_font_size_override("font_size", UiMetrics.font_size(24))
	_explain_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	_explain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_explain_panel.add_child(_explain_label)

## Énoncé d'objectif : chiffré, explicite, sans un mot de tutoriel. Ni
## explication de règle, ni conseil — seulement ce qu'il faut obtenir.
func _build_objective_panel() -> void:
	_objective_panel = Panel.new()
	_objective_panel.name = "ObjectivePanel"
	# LE PANNEAU NE DOIT PAS MASQUER LE NIVEAU QU'IL DÉCRIT. Il occupait le
	# centre du plateau, opaque, et cachait le danger de ch1_02 — c'est-à-dire
	# exactement l'élément que l'énoncé donne à comprendre. Trois corrections
	# cumulées : il descend au BAS de la vue, il se dimensionne sur son
	# contenu au lieu d'une hauteur fixe, et il est TRANSLUCIDE.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.80)
	style.set_corner_radius_all(18)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.72, 0.95, 0.75)
	_objective_panel.add_theme_stylebox_override("panel", style)
	_objective_panel.visible = false
	_objective_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_objective_panel.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
				or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed):
			_dismiss_objective_panel())
	add_child(_objective_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 14)
	_objective_panel.add_child(box)

	var title := Label.new()
	title.name = "Title"
	title.text = "Objectif"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiMetrics.font_size(30))
	title.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	_objective_panel_label = Label.new()
	_objective_panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_panel_label.add_theme_font_size_override("font_size", UiMetrics.font_size(26))
	_objective_panel_label.add_theme_color_override("font_color", Color(0.90, 0.93, 1.0))
	_objective_panel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_objective_panel_label)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = ""
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", UiMetrics.font_size(20))
	hint.add_theme_color_override("font_color", Color(0.45, 0.50, 0.60))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)

## DURÉES DE L'ÉNONCÉ ⚙️.
##
## `OBJECTIVE_MIN_SECONDS` : le panneau ne peut PAS être renvoyé avant ce
## délai. Sans plancher, le geste qui ouvre le niveau chasse l'énoncé avant
## qu'il soit lu — et le joueur découvre qu'il a raté quelque chose sans
## savoir quoi.
##
## RAMENÉ DE 2,0 À 1,2 s. Le plancher existe pour absorber le geste QUI VIENT
## D'OUVRIR le niveau — celui-là arrive en quelques centaines de millisecondes,
## pas au bout de deux secondes. Le reste n'était pas de la protection mais de
## l'attente imposée, et elle s'ajoutait aux autres : « le jeu est trop lent,
## les attentes sont frustrantes » (essai sur l'appareil). Le joueur qui veut
## lire garde la main — le panneau ne s'efface seul qu'au bout de dix secondes,
## et le bandeau le rouvre à volonté.
##
## `OBJECTIVE_MAX_SECONDS` : au-delà, il s'efface seul. Dix secondes, c'est
## trois fois le temps de lecture de l'énoncé le plus long du chapitre —
## assez pour une lecture posée, trop court pour rester en travers du plateau
## si le joueur a regardé ailleurs. Le bandeau, lui, rouvre l'énoncé à
## volonté : rien n'est perdu.
const OBJECTIVE_MIN_SECONDS := 1.2
const OBJECTIVE_MAX_SECONDS := 10.0
var _objective_elapsed: float = -1.0

func show_objective_panel() -> void:
	var total: int = _view.current_state().agents.size() if _view != null and _view.current_state() != null else 0
	var lines := RuleCatalog.objective_brief(_level_data.get("objectives", []), total)
	_objective_panel_label.text = "\n".join(PackedStringArray(lines))
	_objective_panel.visible = true
	_objective_elapsed = 0.0
	_layout()

func _hide_objective_panel() -> void:
	if _objective_panel != null:
		_objective_panel.visible = false
	_objective_elapsed = -1.0

## Renvoi PAR UN GESTE : refusé tant que le plancher n'est pas écoulé.
## Renvoie vrai si le geste a bien été consommé par le panneau.
func _dismiss_objective_panel() -> bool:
	if _objective_panel == null or not _objective_panel.visible:
		return false
	if _objective_elapsed >= 0.0 and _objective_elapsed < OBJECTIVE_MIN_SECONDS:
		return true   # geste absorbé : l'énoncé reste, mais rien ne se passe derrière
	_hide_objective_panel()
	return true

## À la reprise (EF-21) : pas de panneau — il coûterait un geste avant le
## premier geste utile. Le bandeau se souligne brièvement, c'est tout.
func flash_banner() -> void:
	_banner_flash = 1.4

func _on_banner_input(event: InputEvent) -> void:
	var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if pressed:
		show_objective_panel()

# --- composition de la pile : deux chemins équivalents ---------------------

## Glissement : panneau → emplacement (pose ou remplace), emplacement →
## emplacement (échange).
func _on_rule_dropped(slot_index: int, rule_id: int, from_slot: int) -> void:
	if slot_index >= _open_slots:
		Haptics.refuse(self)
		return
	var source: int = from_slot if from_slot >= 0 else _index_of_rule(rule_id)
	if source >= 0:
		_swap_slots(source, slot_index)
	else:
		_stack[slot_index] = rule_id
		_apply_stack()
	Haptics.drop()
	_clear_selection()
	_close_panel()

## Glissement d'un emplacement vers l'extérieur : retire. C'est l'écran
## lui-même qui accueille la chute, à défaut d'une cible plus précise.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and int((data as Dictionary).get("from_slot", -1)) >= 0

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_slot := int((data as Dictionary)["from_slot"])
	_stack[from_slot] = RuleRegistry.EMPTY
	_apply_stack()
	_clear_selection()

## Chemin SANS GLISSEMENT (ENF-25), et chemin principal : un appui
## sélectionne, un appui destine. Il unifie poser, retirer, déplacer et
## échanger dans un seul geste — l'échange en particulier, qui est l'action
## la plus fréquente après poser, puisque tout le jeu tient à l'ordre.
func _on_slot_tapped(slot_index: int) -> void:
	if slot_index >= _open_slots:
		Haptics.refuse(self)
		return
	if _has_selection:
		if _selected_from >= 0:
			_swap_slots(_selected_from, slot_index)
		else:
			var already: int = _index_of_rule(_selected_rule)
			if already >= 0:
				_swap_slots(already, slot_index)
			else:
				_stack[slot_index] = _selected_rule
				_apply_stack()
		Haptics.drop()
		_clear_selection()
		_close_panel()
		return
	if _stack[slot_index] != RuleRegistry.EMPTY:
		_select(_stack[slot_index], slot_index)
		_open_panel()
	else:
		_open_panel()

func _on_remove_requested(slot_index: int) -> void:
	Haptics.drop()
	_stack[slot_index] = RuleRegistry.EMPTY
	_apply_stack()
	_clear_selection()

func _on_chip_tapped(rule_id: int) -> void:
	if _has_selection and _selected_from == -1 and _selected_rule == rule_id:
		_clear_selection()
		return
	_select(rule_id, -1)

func _select(rule_id: int, from_slot: int) -> void:
	Haptics.select()
	_selected_rule = rule_id
	_selected_from = from_slot
	_has_selection = true
	_refresh_selection()

func _clear_selection() -> void:
	_has_selection = false
	_selected_rule = RuleRegistry.EMPTY
	_selected_from = -1
	_refresh_selection()

func _refresh_selection() -> void:
	for chip in _chips:
		chip.selected = _has_selection and _selected_from == -1 and chip.rule_id == _selected_rule
	for i in range(_slots.size()):
		_slots[i].selected = _has_selection and _selected_from == i

## Échange deux emplacements — y compris quand l'un est vide, ce qui revient
## à déplacer.
func _swap_slots(a: int, b: int) -> void:
	if a == b:
		return
	var tmp: int = _stack[a]
	_stack[a] = _stack[b]
	_stack[b] = tmp
	_apply_stack()

## Une règle n'occupe jamais deux emplacements : l'espace des piles est fait
## d'arrangements SANS répétition, l'interface doit rendre impossible ce que
## l'énumérateur ne compte pas. D'où la reposer ailleurs la DÉPLACE.
func _index_of_rule(rule_id: int) -> int:
	if rule_id == RuleRegistry.EMPTY:
		return -1
	for i in range(_stack.size()):
		if _stack[i] == rule_id:
			return i
	return -1

func _open_panel() -> void:
	if _panel.visible:
		return
	# LA NOTE S'EFFACE QUAND LE PANNEAU MONTE. Elle occupait le bas du terrain,
	# c'est-à-dire exactement l'endroit où le panneau vient se poser — et une
	# note qui réclamait « posez une règle » se retrouvait sous le panneau qui
	# sert à en poser une. Le message a été entendu ; il n'a plus lieu d'être.
	_hide_explain()
	_panel.size = Vector2(_panel_width(), _panel.get_combined_minimum_size().y)
	_panel.position.y = _panel_resting_y() + _panel.size.y
	_panel.visible = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "position:y", _panel_resting_y(), 0.22)

func _close_panel() -> void:
	if not _panel.visible:
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "position:y", _panel_resting_y() + _panel.size.y, 0.18)
	tween.tween_callback(func() -> void: _panel.visible = false)

# --- appui long : explication courte (dérogation ENF-25, voir carnet) ------

func _on_chip_long_pressed(rule_id: int) -> void:
	if rule_id == RuleRegistry.EMPTY:
		_show_note("Retirer — vide l'emplacement choisi.")
	else:
		_show_note("%s — %s" % [RuleCatalog.name_of(rule_id), RuleCatalog.line_of(rule_id)])

func _on_slot_long_pressed(slot_index: int) -> void:
	var rule_id: int = _stack[slot_index]
	if rule_id == RuleRegistry.EMPTY:
		_show_note("Emplacement %d — vide. Appuyez pour y poser une règle." % (slot_index + 1))
	else:
		_show_note("%d. %s — %s" % [slot_index + 1, RuleCatalog.name_of(rule_id), RuleCatalog.line_of(rule_id)])

## Durée de vie d'une NOTE — un message que le jeu adresse au joueur de sa
## propre initiative, par opposition au diagnostic qu'il ouvre lui-même en
## touchant un agent. Ce dernier reste tant qu'on ne le referme pas : on l'a
## demandé. Une note, non.
const NOTE_SECONDS := 4.0
var _note_left: float = 0.0

## UN MESSAGE TRANSITOIRE QUI NE PART JAMAIS DEVIENT DU MOBILIER.
##
## Constaté sur l'appareil : « Posez au moins une règle » restait affiché pour
## toujours, et se retrouvait SOUS le panneau de règles dès que le joueur
## l'ouvrait — deux boîtes empilées, dont l'une réclamait encore ce que l'autre
## servait à faire. Le panneau est positionné au moment où on l'affiche ; il ne
## pouvait pas savoir qu'une autre surface viendrait se poser là.
##
## La note s'efface donc d'elle-même, et surtout dès que le joueur FAIT ce
## qu'elle demandait — c'est la seule façon qu'un message ne survive pas à son
## motif.
func _show_note(text: String) -> void:
	_explain_label.text = text
	_explain_panel.visible = true
	_note_left = NOTE_SECONDS
	_position_explain_panel()


# --- EF-05 : le diagnostic, et la bascule marche/pause --------------------

## Un appui sur la grille :
##   en marche              → met en pause (le second chemin d'ENF-01) ;
##   en pause, sur un agent → diagnostic EF-05 ;
##   en pause, à vide       → relance.
## C'est ce qui rend le bouton du haut redondant, donc jamais requis.
func _on_view_input(event: InputEvent) -> void:
	# UN CONTACT DANS LE VIDE BASCULAIT LA LECTURE DEUX FOIS, donc pas du tout :
	# Android émet le tactile ET la souris émulée pour le même geste. Le
	# symptôme — « toucher une zone vide ne fait rien » — ne ressemblait pas du
	# tout à sa cause. Voir `PointerEvents`.
	if PointerEvents.is_emulated_duplicate(event):
		return
	var pressed := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pressed = (event as InputEventMouseButton).pressed
		pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
		pos = (event as InputEventScreenTouch).position
	else:
		return
	if not pressed:
		return
	# L'énoncé d'ouverture passe avant tout le reste : tant qu'il est affiché,
	# le premier geste le renvoie et ne fait rien d'autre.
	if _dismiss_objective_panel():
		return
	# Un appui hors des règles annule la sélection et referme le panneau.
	if _has_selection or _panel.visible:
		_clear_selection()
		_close_panel()
		return
	if _playing:
		_pause()
		return
	if not _show_explain_at(pos):
		_hide_explain()
		_toggle_play()

## Rectangles occupés à L'ÉCRAN par une liste de cases. La vue vit dans un
## sous-écran ; ses pixels ne sont ceux de l'écran qu'une fois décalés de la
## position de son hôte, et l'oublier place la surbrillance à côté de ce qu'elle
## désigne — d'autant plus loin que la grille est haute.
func screen_rects_of(cells: Array) -> Array:
	var out: Array = []
	if _view == null or _view_host == null:
		return out
	for c in cells:
		var r: Rect2 = _view.cell_rect_of(c)
		if r.size.x <= 0.0:
			continue
		out.append(Rect2(r.position + _view_host.position, r.size))
	return out

func _show_explain_at(local_pos: Vector2) -> bool:
	if _view == null or _view.current_state() == null:
		return false
	var cell := _view.cell_at_pixel(local_pos)
	if cell.x < 0:
		return false
	# RAYON ZERO : seule la case TOUCHEE ouvre le diagnostic. A un rayon d'une
	# case, tout le pourtour d'une nuee de vingt agents comptait comme « sur un
	# agent », si bien qu'un appui a cote n'avait pas l'effet attendu — le joueur
	# concluait que toucher le vide ne faisait rien. Le vide doit rendre la main
	# a marche/pause, qui est le geste principal de l'ecran.
	var index := _view.agent_near(cell, 0)
	if index < 0:
		return false
	# La décision du dernier mouvement s'est prise sur l'état PRÉCÉDENT
	# (RG-07, décisions sur cliché immuable) : c'est lui qu'on interroge.
	var decision_state := _view.previous_state()
	var agent: AgentState = decision_state.agents[index]
	var report := RuleExplainer.explain(agent, decision_state, _compact_stack())
	var lines: Array = report["lines"]
	var note := RuleExplainer.movement_note(report["proposed"], _view.last_granted(index))
	if not note.is_empty():
		lines.append(note)
	_explain_label.text = "\n".join(PackedStringArray(lines))
	_explain_panel.visible = true
	_position_explain_panel()
	return true

func _position_explain_panel() -> void:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	var pad := 18.0
	var width: float = vp.x - m.x - m.z
	# LE TEXTE ENVELOPPE, ET LA HAUTEUR SUIT L'ENVELOPPE.
	#
	# Le libellé ne renvoyait pas à la ligne : une phrase de règle de 127
	# caractères se dessinait sur une seule ligne, donc sortait de l'écran par la
	# droite. Compter les « \n » ne suffisait pas non plus — il n'y en avait
	# aucun. On demande donc à la police combien de lignes le texte occupe RÉELLEMENT
	# à cette largeur, ce qui reste juste quel que soit l'écran.
	var inner: float = width - pad * 2.0
	var font: Font = _explain_label.get_theme_font("font")
	var font_size: int = _explain_label.get_theme_font_size("font_size")
	var lines: int = maxi(_explain_label.text.split("\n").size(), 1)
	if font != null and inner > 0.0:
		var measured: float = font.get_string_size(
			_explain_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		lines = maxi(lines, int(ceil(measured / inner)))
	var height: float = pad * 2.0 + lines * 32.0
	_explain_panel.position = Vector2(m.x, _field_bottom() - height - UiMetrics.GAP)
	_explain_panel.size = Vector2(width, height)
	_explain_label.position = Vector2(pad, pad)
	_explain_label.size = Vector2(width - pad * 2.0, height - pad * 2.0)

func _hide_explain() -> void:
	if _explain_panel != null:
		_explain_panel.visible = false
	_note_left = 0.0

# --- disposition ----------------------------------------------------------

## Bande verticale réellement libre entre les barres : sert à poser les
## panneaux qui doivent rester dans le jeu sans passer sous l'interface.
func _field_top() -> float:
	var m := UiMetrics.safe_area_margins(get_viewport_rect().size)
	return m.y + UiMetrics.MIN_TOUCH_TARGET * UiButtons.PRIMARY_SCALE + UiMetrics.GAP * 0.5 + 40 + UiMetrics.GAP

func _field_bottom() -> float:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	return vp.y - m.w - UiMetrics.MIN_TOUCH_TARGET * 1.25 - UiMetrics.GAP

## Hauteur du tiroir : autant de rangs qu'il en faut pour poser toutes les
## règles sans qu'une seule sorte de l'écran.
##
## LE CALCUL EST EXPLICITE, PAS DÉLÉGUÉ AU CONTENEUR. Demander sa taille
## minimale à `HFlowContainer` avant qu'il ait été disposé rend la hauteur d'un
## seul rang, et le tiroir se retrouve trop court d'exactement ce qu'on voulait
## corriger. Ici la formule ne dépend d'aucun ordre de disposition.
func _chips_per_row(width: float) -> int:
	# `width` est DEJA la largeur utile (marges de zone sure retranchees). En
	# retrancher la marge une seconde fois faisait tenir une seule regle par rang
	# la ou deux tiennent, et le tiroir devenait une colonne qui mangeait l'ecran.
	# Une marge comptee deux fois ne se voit pas dans un calcul : elle se voit a
	# la capture.
	var chip_w: float = UiMetrics.MIN_TOUCH_TARGET * 2.0
	return maxi(int(floor((width + UiMetrics.GAP) / (chip_w + UiMetrics.GAP))), 1)

func _panel_rows(width: float) -> int:
	var n: int = maxi(_allowed.size(), 1)
	return int(ceil(float(n) / float(_chips_per_row(width))))

## Largeur utile du tiroir. UNE SEULE SOURCE, et c'est le correctif : la
## hauteur etait calculee dans `_open_panel` a partir de `_panel.size.x`, encore
## NUL a cet instant. La formule concluait « une regle par rang », donc six
## rangs pour six regles, et le tiroir couvrait l'ecran entier — bouton de
## lancement compris. Une largeur nulle ne se voit pas dans un calcul ; elle se
## voit a la capture.
func _panel_width() -> float:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	return maxf(vp.x - m.x - m.z, 1.0)

func _panel_height(width: float = -1.0) -> float:
	var w: float = width if width > 0.0 else _panel_width()
	var rows: int = _panel_rows(w)
	return UiMetrics.MIN_TOUCH_TARGET * rows \
		+ UiMetrics.GAP * float(rows - 1) + UiMetrics.MARGIN * 2.0

func _panel_resting_y() -> float:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	return vp.y - m.w - UiMetrics.MIN_TOUCH_TARGET * 1.25 - UiMetrics.GAP \
		- _panel_height(vp.x - m.x - m.z)

func _layout() -> void:
	var vp := get_viewport_rect().size
	var m := UiMetrics.safe_area_margins(vp)
	var left: float = m.x
	var top: float = m.y
	var right: float = vp.x - m.z
	var bottom: float = vp.y - m.w
	var width: float = right - left
	var bar_h := UiMetrics.MIN_TOUCH_TARGET

	var left_row := get_node_or_null("LeftBar") as HBoxContainer
	if left_row != null:
		left_row.position = Vector2(left, top)
		left_row.size = Vector2(bar_h * 2.0 + UiMetrics.GAP, bar_h)
	var right_row := get_node_or_null("RightBar") as HBoxContainer
	if right_row != null:
		# Le bouton de lecture est plus grand : la barre droite l'est aussi, et
		# elle est alignée par le BAS pour que les glyphes restent sur une ligne.
		var play_h := bar_h * UiButtons.PRIMARY_SCALE
		var w := play_h + bar_h + UiMetrics.GAP
		right_row.position = Vector2(right - w, top)
		right_row.size = Vector2(w, play_h)
		right_row.alignment = BoxContainer.ALIGNMENT_END

	if _objective_label != null:
		_objective_label.position = Vector2(left, top + bar_h * UiButtons.PRIMARY_SCALE + UiMetrics.GAP * 0.5)
		_objective_label.size = Vector2(width, 40)

	# La pile occupe le bas — et rien d'autre : le concepteur y tient.
	var stack_h := bar_h * 1.25
	var stack_bar := get_node_or_null("StackBar") as HBoxContainer
	if stack_bar != null:
		stack_bar.position = Vector2(left, bottom - stack_h)
		stack_bar.size = Vector2(width, stack_h)

	# La vue couvre TOUT l'écran ; ce sont ses marges de contenu qui gardent la
	# nuée hors des barres, pas un découpage du rectangle.
	if _view_host != null:
		_view_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _view != null:
		_view.content_margin = Vector4(
			left, _field_top(), vp.x - right, vp.y - _field_bottom())

	if _panel != null:
		_panel.size = Vector2(width, _panel_height(width))
		_panel.custom_minimum_size = Vector2(width, _panel_height(width))
		_panel.position = Vector2(left,
			_panel_resting_y() if _panel.visible else bottom + _panel_height(width))
		# Le nombre de colonnes suit la largeur DISPONIBLE : sur un ecran etroit
		# la grille passe a deux colonnes, et le tiroir grandit d'un rang au lieu
		# de pousser une regle hors de l'ecran.
		var chip_row := _panel.get_node_or_null("ChipRow") as GridContainer
		if chip_row != null:
			chip_row.columns = _chips_per_row(width)

	if _objective_panel != null:
		var ow: float = width * 0.9
		# Hauteur SUR MESURE : titre + énoncé (une ligne par objectif) + rappel
		# de fermeture, plus les gouttières. Une hauteur fixe de 300 laissait
		# un panneau à moitié vide au milieu du plateau.
		var body_lines: int = maxi(_objective_panel_label.text.split("\n").size(), 1)
		var oh: float = 24.0 * 2.0 + 40.0 + body_lines * 34.0 + 28.0 + 28.0
		_objective_panel.position = Vector2(left + (width - ow) * 0.5,
			_field_bottom() - oh - UiMetrics.GAP)
		_objective_panel.size = Vector2(ow, oh)
		var box := _objective_panel.get_child(0) as Control
		if box != null:
			box.position = Vector2(24, 24)
			box.size = Vector2(ow - 48, oh - 48)

	if _explain_panel != null and _explain_panel.visible:
		_position_explain_panel()

# --- pile et transport ----------------------------------------------------

func _compact_stack() -> Array[int]:
	var out: Array[int] = []
	for rule_id in _stack:
		if rule_id != RuleRegistry.EMPTY:
			out.append(rule_id)
	return out

## Compacte la pile : les règles glissent vers la gauche, sans trou.
## Renvoie vrai si quelque chose a bougé — ce qui déclenche l'animation.
func _compact_in_place() -> bool:
	var packed: Array[int] = _compact_stack()
	var moved := false
	for i in range(_stack.size()):
		var wanted: int = packed[i] if i < packed.size() else RuleRegistry.EMPTY
		if _stack[i] != wanted:
			_stack[i] = wanted
			moved = true
	return moved

func _apply_stack() -> void:
	for i in range(_open_slots, _stack.size()):
		_stack[i] = RuleRegistry.EMPTY
	var slid := _compact_in_place()
	for i in range(_slots.size()):
		_slots[i].set_rule(_stack[i], slid)
	_mark_next_slot()
	if _view != null and not _level_data.is_empty():
		_view.load_level(_level_data, _params, _compact_stack())
	_pause()
	_hide_explain()
	_finished = false
	_outcome_countdown = -1.0
	_refresh_transport()
	_notify_state()

## Distingue l'emplacement suivant disponible des emplacements simplement
## inutilisés : le premier est une invitation, les autres du décor.
func _mark_next_slot() -> void:
	var next := -1
	for i in range(mini(_open_slots, _stack.size())):
		if _stack[i] == RuleRegistry.EMPTY:
			next = i
			break
	for i in range(_slots.size()):
		_slots[i].set_next_available(i == next)

func _pause() -> void:
	_playing = false
	_refresh_transport()

func _toggle_play() -> void:
	# UNE PILE VIDE NE SE LANCE PAS.
	#
	# Sans règle, aucun agent ne bouge : la simulation ne peut que courir
	# jusqu'au bout du temps imparti et rendre un écran de défaite. Un appui
	# accidentel — et l'écran de jeu invite justement à toucher n'importe où pour
	# lancer — produisait donc un échec certain, immérité, et sans rapport avec
	# ce que le joueur avait tenté. Il n'y a rien à observer dans une nuée qui ne
	# bouge pas ; le refus vaut mieux que la punition.
	# LE REFUS EST MUET, ET C'EST MIEUX AINSI.
	#
	# Il s'accompagnait d'un bandeau « Posez au moins une règle ». Signalé à
	# l'essai : « le message quand la pile est vide ne sert à rien, pire il
	# gêne ». Il a raison sur les deux points — la pile est visible à l'écran, et
	# ses emplacements vides disent déjà tout ce que la phrase répétait. Le
	# bandeau, lui, se posait sur le terrain et masquait la nuée au moment où le
	# joueur cherchait justement à comprendre pourquoi rien ne partait.
	#
	# Reste le refus lui-même, et lui n'est pas négociable : une nuée sans règle
	# ne bouge pas, la simulation ne peut que courir jusqu'au bout du temps et
	# rendre une défaite imméritée. Le retour haptique suffit à dire non.
	if not _playing and _compact_stack().is_empty():
		Haptics.refuse(self)
		return
	_playing = not _playing
	if _playing:
		_hide_explain()
	_refresh_transport()
	_notify_state()

func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_refresh_transport()
	_notify_state()

func _refresh_transport() -> void:
	if _play_button != null:
		_play_button.text = "❚❚" if _playing else "▶"
	if _speed_button != null:
		_speed_button.text = SPEED_GLYPHS[_speed_index]
		_speed_button.tooltip_text = "Vitesse %s" % SPEED_GLYPHS[_speed_index]

func _notify_state() -> void:
	state_changed.emit()

func _process(delta: float) -> void:
	if _view == null or _view.current_state() == null:
		return
	if _playing:
		_view.advance(delta, SPEEDS[_speed_index])
	var state := _view.current_state()
	if _objective_label != null:
		_objective_label.text = RuleCatalog.objective_line(
			_level_data.get("objectives", []), state)

	if _objective_elapsed >= 0.0:
		_objective_elapsed += delta
		# L'invite n'apparaît QUE lorsqu'elle devient vraie. Annoncer
		# « toucher pour fermer » pendant les deux secondes où le toucher ne
		# fait rien apprendrait au joueur que l'interface ne répond pas.
		var hint := _objective_panel.get_node_or_null("../ObjectivePanel/Hint")
		if hint == null:
			hint = _objective_panel.get_child(0).get_node_or_null("Hint")
		if hint is Label:
			(hint as Label).text = "" if _objective_elapsed < OBJECTIVE_MIN_SECONDS else "toucher pour fermer"
		if _objective_elapsed >= OBJECTIVE_MAX_SECONDS:
			_hide_objective_panel()
	if _note_left > 0.0:
		_note_left -= delta
		if _note_left <= 0.0:
			_hide_explain()
	if _banner_flash > 0.0:
		_banner_flash -= delta
		var t2: float = fmod(_banner_flash, 0.4) / 0.4
		_objective_label.add_theme_color_override("font_color",
			Color(0.55, 0.85, 1.0).lerp(Color(0.86, 0.90, 1.0), t2))
		if _banner_flash <= 0.0:
			_objective_label.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))

	if not _finished and state.outcome != SimState.Outcome.RUNNING:
		# La simulation a tranché ; l'interface, elle, laisse d'abord VOIR ce
		# qui s'est passé — l'écho a besoin de son temps d'écran.
		_finished = true
		_playing = false
		_outcome_countdown = OUTCOME_DELAY
		if _edge_echo != null:
			(_edge_echo as _EdgeEcho).play(
				state.outcome == SimState.Outcome.WON)
	if _outcome_countdown > 0.0:
		_outcome_countdown -= delta
		if _outcome_countdown <= 0.0:
			_outcome_countdown = -1.0
			finished.emit(_level_id, state.outcome == SimState.Outcome.WON,
				state.tick, state.counters.lost, _compact_stack(),
				RuleCatalog.outcome_reason(_level_data.get("objectives", []), state))

## HALO DE BORD D'ÉCRAN — l'issue de la partie, dite à la périphérie.
##
## POURQUOI IL EXISTE. « L'écran de défaite arrive avant le moment fatidique » :
## le joueur suivait la nuée au centre et ne voyait rien changer avant que le
## bilan ne surgisse. L'écho de la case fatale dit OÙ ; celui-ci dit QUE, et il
## est perceptible sans être regardé — la vision périphérique capte un
## changement de luminosité au bord bien avant un détail au centre.
##
## IL NE CLIGNOTE PAS. Une bordure qui clignote est une alarme, et une alarme
## sur un échec de puzzle punit au lieu d'informer. Elle s'allume et s'éteint
## une fois, en s'élargissant — un écho, comme celui de la case.
##
## Rouge sur un échec, vert sur une victoire, et rien du tout le reste du temps.
class _EdgeEcho extends Control:
	const SPAN := 1.6

	var _age: float = -1.0
	var _won: bool = false

	func play(won: bool) -> void:
		_won = won
		_age = 0.0
		set_process(true)

	func _ready() -> void:
		set_process(false)

	func _process(delta: float) -> void:
		if _age < 0.0:
			return
		_age += delta
		if _age >= SPAN:
			_age = -1.0
			set_process(false)
		queue_redraw()

	func _draw() -> void:
		if _age < 0.0:
			return
		var t: float = clampf(_age / SPAN, 0.0, 1.0)
		var tint: Color = ViewPalette.EXIT if _won else ViewPalette.DANGER
		# Bandes concentriques depuis le bord : la plus extérieure est la plus
		# opaque, et l'ensemble s'efface. Dessiné en rectangles évidés plutôt
		# qu'en dégradé — aucune texture, tout est procédural (DT-13).
		var bands := 7
		for i in range(bands):
			var depth: float = float(i) / float(bands)
			var band := tint
			band.a = (1.0 - t) * (1.0 - depth) * (1.0 - depth) * 0.55
			if band.a <= 0.003:
				continue
			var inset: float = depth * (18.0 + 26.0 * t) * UiMetrics.FONT_SCALE
			var thickness: float = maxf(6.0 * UiMetrics.FONT_SCALE, 4.0)
			draw_rect(Rect2(Vector2(inset, inset),
				size - Vector2(inset, inset) * 2.0), band, false, thickness)
