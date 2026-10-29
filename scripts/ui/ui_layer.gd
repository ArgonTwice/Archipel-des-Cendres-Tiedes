extends CanvasLayer
# Couche UI pliée ou dépliée (SOCLE §A3) : instanciée une fois dans main.tscn, jamais reconstruite.

const VeilleeReportS = preload("res://scripts/ui/veillee_report.gd")
const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const BA = preload("res://balance/balance_a.gd")
const BD = preload("res://balance/balance_d.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")
const VText = preload("res://scripts/ui/village_text.gd")
const NewGameS = preload("res://scripts/new_game.gd")
const Dag = preload("res://scripts/offline_dag.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const AssignS = preload("res://scripts/village/assignment.gd")
const UiStyle = preload("res://scripts/ui/ui_style.gd") # couleurs par rôle et icônes (Charte §1 et §3)
const BB = preload("res://balance/balance_b.gd")
const DebugS = preload("res://scripts/debug/debug_tools.gd")
const ShopUpS = preload("res://scripts/village/shop_upgrade.gd")

signal purify_requested
signal purify_chosen(equip: bool)
signal forge_requested(slot: int, cendre: bool)
signal cadence_chosen(index: int, cadence: String)
signal posture_chosen(key: String, posture: String)
signal post_chosen(index: int, post: String)
signal npc_freed(index: int)
signal atre_requested # Agrandir le Grand Âtre (jalon 21)
signal shop_upgrade_requested(key: String) # Agrandir une boutique (jalon 22)
signal debug_requested(action: String) # mode debug (build debug seulement)
signal debug_invincible(on: bool)

const LEVEL_UP_TOAST_SEC: float = 2.5 # PROPOSÉ, à valider (jalon 13)
const WINDOW_HEIGHT_RATIO: float = 0.5 # hauteur de la fenêtre / hauteur de la zone ; validé sur Fold (jalon 17)
const TAB_TITLES: Array[String] = ["Perso", "Sacoche", "Forge", "PNJ", "Village", "Options"]
const PAGES: String = "Margin/VBox/Monde/Fenetre/Box/Defile/Pages/"
# Feu de camp de la Cendre (jalon 17 bis) : 4 images côte à côte sur la planche de krial.
const FIRE_FRAMES: int = 4
const FIRE_FRAME_MS: int = 125 # durée de l'auteur (GIF 120–130 ms) ; technique, validé sur Fold (jalon 17 bis)

@export var compact: bool = true

@onready var _margin: MarginContainer = $Margin
@onready var _hud: Control = $Margin/VBox/Hud
@onready var _gauge: ProgressBar = $Margin/VBox/Jauge
@onready var _toast: HBoxContainer = $Margin/VBox/Monde/Messages/Toast # icône 16 px + texte (jalon 20 ter)
@onready var _toast_icon: TextureRect = $Margin/VBox/Monde/Messages/Toast/Icone
@onready var _toast_text: Label = $Margin/VBox/Monde/Messages/Toast/Texte
var _gauge_fill: StyleBoxFlat # remplissage de la jauge, recoloré sans recréer la jauge (jalon 20 ter)

var _toast_id: int = 0 # numéro du dernier toast affiché
@onready var _report: PanelContainer = find_child("Report", true, false) # plié : sous le bandeau ; déplié : fenêtre centrée
@onready var _report_lines: VBoxContainer = _report.get_node("Lines")
var _report_rows: Dictionary = {} # clé de VeilleeReport.KEYS -> _line, créée une fois (jalon 20 ter)
@onready var _error: Label = $Margin/VBox/Monde/Messages/Error
@onready var _fire: TextureRect = get_node_or_null("Margin/VBox/Hud/Ligne/Cendre/Icone")
var _fire_frame: int = 0 # image affichée : _ready pose l'image 0
# Bandeau : dernières valeurs reçues (Or, joueur, coffre, cargaison en expédition).
var _gold: int = 0
var _player: Dictionary = {}
var _ore: int = 0
var _cargo: Variant = null

# Fenêtre, onglets et carte : couche dépliée seulement.
@onready var _window: PanelContainer = get_node_or_null("Margin/VBox/Monde/Fenetre")
@onready var _title: Label = get_node_or_null("Margin/VBox/Monde/Fenetre/Box/Barre/Ligne/Titre")
@onready var _scroll: ScrollContainer = get_node_or_null("Margin/VBox/Monde/Fenetre/Box/Defile")
@onready var _preview: PanelContainer = get_node_or_null("Margin/VBox/Monde/Apercu")
@onready var _perso: VBoxContainer = get_node_or_null(PAGES + "Perso")
@onready var _sacoche: VBoxContainer = get_node_or_null(PAGES + "Sacoche")
@onready var _purify: Button = get_node_or_null(PAGES + "Sacoche/Purifier")
@onready var _purify_reason: Label = get_node_or_null(PAGES + "Sacoche/Raison")
@onready var _forge: Control = get_node_or_null(PAGES + "Forge")
@onready var _forge_reason: Label = get_node_or_null(PAGES + "Forge/Raison")
@onready var _verdict: Label = get_node_or_null("Margin/VBox/Monde/Apercu/Box/Verdict")
var _forge_buttons: Array[Button] = []
# Forge (jalon 20 bis) : créée une fois dans _ready ; show_forge et refresh_forge_help ne changent que textes et états.
var _forge_with_cendre: bool = true # mode de craft, non sauvegardé
var _forge_rows: Dictionary = {} # "minerai", "cendre" -> {"text", "tag", "icon"}
var _forge_mode: Dictionary = {} # _block du mode : "buttons" (Sans, Avec), "help"
var _forge_reason_of: Callable # dernière source de raison reçue (set_forge_enabled), relue au changement de mode
# Carte d'Aperçu (jalon 20 bis, revue après Z11) : tête, résumé des 2 pièces, tableau « Si tu équipes » ; créée une fois.
var _preview_head: Dictionary = {} # {"text", "tag", "icon"}
var _summaries: Array[Label] = [] # Nouvelle, Équipée
var _stat_cells: Array = [] # 6 lignes de 4 Labels : stat, avec l'équipée, avec la nouvelle, écart
# Mode debug : {"village" (boutons), "village_reasons", "shards", "shards_reason", "mist", "mist_reason"} ; vide en release.
var _debug: Dictionary = {}
# Onglets du bas (jalon 17, à la Kairosoft) : une seule fenêtre ouverte à la fois, aucune au lancement ; un 2e appui ou « × » referme.
var _tabs: Array[Button] = []
var _pages: Array[Control] = []
var _forge_help_of: Callable # (cendre: bool) -> PackedStringArray, fourni par main.gd
# Onglets PNJ et Village (jalon 18) : cartes et blocs créés une fois dans _ready ; show_village ne change que textes et boutons.
var _names: Dictionary = {}
var _npc_sprites: Array = [] # village.json : le sprite fixe le genre du nom (VText.npc_identities)
# {"head" (ligne de liste), "lines" (Profil), "hint", "posts" (4 boutons de poste), "pending", "free" (Libérer),
#  "cad_title", "row" et "buttons" (cadence), "help", "moral" (étiquette de la tête)}
var _npc_cards: Array[Dictionary] = []
var _world_seed: int = 0
var _shop_blocks: Dictionary = {} # clé de boutique -> {"head", "lines", "buttons", "help", "tag", "upgrade", "effect", "button", "reason"}
var _atre: Dictionary = {} # {"head", "tag", "detail", "slots", "upgrade" (titre, effet, bouton, raison), "button", "effect", "reason"}
var _detail_style: StyleBoxFlat # fond de fiche, partagé par toutes les cartes
# Perso et Sacoche (jalon 20) : créés une fois dans _ready ; show_perso / show_player ne changent que textes, couleurs, visibilité.
var _voc_lines: Dictionary = {} # vocation -> {"text", "tag"}
var _stats: Label
var _slot_cards: Array[Dictionary] = [] # {"head", "tag", "schools", "lines"}
var _sac_rows: Dictionary = {} # "cendre", "minerai" -> {"text", "tag"} ; "eclats" -> {"head", "tag", "lines"}

# Région de l'image du feu à l'instant ms : celle de l'icône « cendre », décalée d'une largeur d'image (planche / FIRE_FRAMES).
static func fire_region(ms: int) -> Rect2:
	var base: Rect2 = UiStyle.ICONS["cendre"][1]
	var step: float = float(UiStyle.ICONS["cendre"][0].get_width()) / FIRE_FRAMES
	return Rect2(base.position.x + step * ((ms / FIRE_FRAME_MS) % FIRE_FRAMES), base.position.y, base.size.x, base.size.y)

# Horloge monotone et cosmétique (pas l'horloge de jeu). Couche masquée : process_mode DISABLED, le feu se fige.
func _process(_delta: float) -> void:
	_animate_fire(Time.get_ticks_msec())

# Ne touche la région qu'au changement d'image : pas de redessin à chaque image.
func _animate_fire(ms: int) -> void:
	var frame: int = (ms / FIRE_FRAME_MS) % FIRE_FRAMES
	if _fire == null or frame == _fire_frame:
		return
	_fire_frame = frame
	(_fire.texture as AtlasTexture).region = fire_region(ms)

func _ready() -> void:
	_report.gui_input.connect(_on_report_input)
	for key: String in VeilleeReportS.KEYS:
		_report_rows[key] = _line(_report_lines, UiStyle.icon(VeilleeReportS.ICONS[key]))
		_report_rows[key]["tag"].add_theme_color_override("font_color", UiStyle.MUTED)
	var close: Label = Label.new()
	close.text = "Touche pour fermer"
	close.add_theme_color_override("font_color", UiStyle.MUTED)
	_report_lines.add_child(close)
	_gauge_fill = (_gauge.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
	_gauge.add_theme_stylebox_override("fill", _gauge_fill)
	for key: String in UiStyle.HUD_KEYS:
		var icon: TextureRect = _hud.get_node_or_null("Ligne/%s/Icone" % key.capitalize())
		if icon != null:
			icon.texture = UiStyle.icon(key)
	_detail_style = StyleBoxFlat.new()
	_detail_style.bg_color = UiStyle.DETAIL_BG
	_detail_style.set_content_margin_all(UiStyle.DETAIL_MARGIN_PX)
	if _window != null:
		var group: ButtonGroup = ButtonGroup.new()
		group.allow_unpress = true
		for i in TAB_TITLES.size():
			var t: Button = get_node("Margin/VBox/Onglets/" + TAB_TITLES[i])
			t.icon = UiStyle.icon("TAB_" + TAB_TITLES[i].to_upper())
			t.button_group = group
			t.toggled.connect(func(on: bool) -> void:
				if on:
					_scroll.scroll_vertical = 0
				_apply_tabs())
			_tabs.append(t)
			_pages.append(get_node(PAGES + TAB_TITLES[i]))
		$Margin/VBox/Monde/Fenetre/Box/Barre/Ligne/Fermer.pressed.connect(func() -> void:
			for t: Button in _tabs:
				t.button_pressed = false)
		_purify.pressed.connect(purify_requested.emit)
		_purify_reason.add_theme_color_override("font_color", UiStyle.REASON)
		$Margin/VBox/Monde/Apercu/Box/Choix/Equiper.pressed.connect(purify_chosen.emit.bind(true))
		$Margin/VBox/Monde/Apercu/Box/Choix/Jeter.pressed.connect(purify_chosen.emit.bind(false))
		var credits: Button = get_node(PAGES + "Options/CreditsButton")
		_style_action(credits, UiStyle.icon("CREDITS"))
		credits.pressed.connect($Credits.show)
		_build_village_pages()
		_build_perso()
		_build_sacoche()
		_build_preview()
		build_debug(OS.is_debug_build())
		if is_inside_tree(): # hors arbre sous le simulateur headless : il appelle fit_window lui-même
			fit_window(get_viewport().get_visible_rect().size.y)
			get_viewport().size_changed.connect(func() -> void: fit_window(get_viewport().get_visible_rect().size.y))
	if _forge != null:
		_build_forge()
	if _scroll != null:
		touch_scroll(_scroll)

# Défilement tactile (Z8) : boutons et panneaux en PASS, le glissé remonte au ScrollContainer (défilement et inertie) ;
# un appui simple reste un appui. À appeler une fois, après la création des pages.
static func touch_scroll(scroll: ScrollContainer) -> void:
	for c: Control in scroll.find_children("*", "Control", true, false):
		if c.mouse_filter == Control.MOUSE_FILTER_STOP:
			c.mouse_filter = Control.MOUSE_FILTER_PASS

# Pages PNJ et Village (jalons 19 et 19 bis, façon Kairosoft) : une ligne par PNJ, puis Âtre et boutiques ; un appui
# ouvre la fiche dessous, une seule à la fois par page. PNJ : Profil, Poste (aptitude sur chaque bouton), Cadence ;
# Moral coloré sur la ligne. Village : rayon et occupation des postes ; boutique : lignes, Posture.
func _build_village_pages() -> void:
	var data: Dictionary = VL.load_data()
	_npc_sprites = data["npc_sprites"]
	_names = VText.with_identities(VText.load_names(), 0, _npc_sprites) # remplacé par set_world_seed
	var pnj: Node = get_node(PAGES + "PNJ")
	var village: Node = get_node(PAGES + "Village")
	get_node(PAGES + "PNJ/Raison").add_theme_color_override("font_color", UiStyle.REASON)
	get_node(PAGES + "Village/Raison").add_theme_color_override("font_color", UiStyle.REASON)
	var tip: Label = Label.new()
	tip.text = "Astuce : fais glisser un PNJ sur un bâtiment"
	pnj.add_child(tip)
	var post_names: Dictionary = {}
	for p: String in AssignS.active_posts():
		post_names[p] = _names["posts"][p]
	var group: ButtonGroup = ButtonGroup.new()
	group.allow_unpress = true
	for i in NewGameS.START_POSTS.size():
		var made: Array = _card(pnj, group, UiStyle.atlas(UiStyle.TD, UiStyle.tile_region(int(data["tiles"][_npc_sprites[i]][1]))))
		var head: Button = made[0]
		var box: VBoxContainer = made[1]
		var moral: Label = made[2]
		moral.name = "Moral"
		_section(box, "Profil")
		var lines: Label = Label.new()
		box.add_child(lines)
		_section(box, "Poste (chiffre = aptitude)")
		var posts: Dictionary = _block(box, post_names, func(post: String) -> void: post_chosen.emit(i, post))
		posts["row"].name = "Postes"
		posts["help"].name = "Demain"
		posts["help"].add_theme_color_override("font_color", UiStyle.NEXT)
		posts["lines"].add_theme_color_override("font_color", UiStyle.MUTED)
		var free: Button = Button.new()
		free.name = "Liberer"
		free.text = "Libérer"
		free.focus_mode = Control.FOCUS_NONE
		free.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		free.visible = false
		free.pressed.connect(func() -> void: npc_freed.emit(i))
		posts["row"].get_parent().add_child(free)
		var cad_title: Label = _section(box, "Cadence")
		var cad: Dictionary = _block(box, _names["cadences"], func(value: String) -> void: cadence_chosen.emit(i, value))
		cad["lines"].free()
		cad["row"].name = "Cadence"
		cad["help"].name = "AideCadence"
		var producer: bool = Dag.POST_SHOP.has(NewGameS.START_POSTS[i][0])
		for c: Control in [cad_title, cad["row"], cad["help"]]:
			c.visible = producer
		_npc_cards.append({"head": head, "lines": lines, "hint": posts["lines"], "posts": posts["buttons"], "pending": posts["help"], "free": free,
			"cad_title": cad_title, "row": cad["row"], "buttons": cad["buttons"], "help": cad["help"], "moral": moral})
	var vgroup: ButtonGroup = ButtonGroup.new()
	vgroup.allow_unpress = true
	var a: Array = _card(village, vgroup, UiStyle.icon("ATRE"))
	_atre = {"head": a[0], "tag": a[2], "detail": Label.new(), "slots": Label.new()}
	_atre["tag"].add_theme_color_override("font_color", UiStyle.NEXT)
	a[1].add_child(_atre["detail"])
	_section(a[1], "Postes")
	_atre["slots"].name = "Occupation"
	a[1].add_child(_atre["slots"])
	# Agrandir (jalon 21) : effet, bouton d'action, raison ; toute la section cachée au niveau maximal.
	var up_title: Label = _section(a[1], "Agrandir")
	_atre["effect"] = Label.new()
	_atre["effect"].add_theme_color_override("font_color", UiStyle.MUTED)
	a[1].add_child(_atre["effect"])
	_atre["button"] = _action(a[1], UiStyle.icon("ATRE"))
	_atre["button"].name = "Agrandir"
	_atre["button"].disabled = true
	_atre["button"].pressed.connect(atre_requested.emit)
	_atre["reason"] = Label.new()
	_atre["reason"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_atre["reason"].add_theme_color_override("font_color", UiStyle.REASON)
	a[1].add_child(_atre["reason"])
	_atre["upgrade"] = [up_title, _atre["effect"], _atre["button"], _atre["reason"]]
	for key: String in Dag.SHOP_ITEM:
		var s: Array = _card(village, vgroup, UiStyle.icon(key))
		var block: Dictionary = _block(s[1], _names["postures"], func(value: String) -> void: posture_chosen.emit(key, value))
		block["row"].name = "Posture"
		var title: Label = _section(block["row"].get_parent(), "Posture")
		title.get_parent().move_child(title, 1)
		block["head"] = s[0]
		block["tag"] = s[2]
		block["tag"].add_theme_color_override("font_color", UiStyle.NEXT)
		# Agrandir (jalon 22) : même section que l'Âtre, après la Posture ; cachée au niveau maximal.
		var up: Label = _section(s[1], "Agrandir")
		block["effect"] = Label.new()
		block["effect"].add_theme_color_override("font_color", UiStyle.MUTED)
		s[1].add_child(block["effect"])
		block["button"] = _action(s[1], UiStyle.icon(key))
		block["button"].name = "Agrandir"
		block["button"].disabled = true
		block["button"].pressed.connect(func() -> void: shop_upgrade_requested.emit(key))
		block["reason"] = Label.new()
		block["reason"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		block["reason"].add_theme_color_override("font_color", UiStyle.REASON)
		s[1].add_child(block["reason"])
		block["upgrade"] = [up, block["effect"], block["button"], block["reason"]]
		_shop_blocks[key] = block

# Perso (jalon 20) : Vocations (3 lignes simples), Stats, Équipement (4 lignes dépliables, une ouverte à la fois).
func _build_perso() -> void:
	_section(_perso, "Vocations")
	for voc: String in ProgressionS.VOCATIONS:
		_voc_lines[voc] = _line(_perso, UiStyle.icon(voc))
	_section(_perso, "Stats")
	_stats = Label.new()
	_perso.add_child(_stats)
	_section(_perso, "Équipement")
	var group: ButtonGroup = ButtonGroup.new()
	group.allow_unpress = true
	for slot in EqText.SLOT_NAMES.size():
		var c: Array = _card(_perso, group, UiStyle.icon("SLOT_%d" % slot))
		var schools: Label = Label.new() # 1re ligne de la fiche de l'arme : Écoles et ATK d'arme
		schools.name = "Ecoles"
		c[1].add_child(schools)
		var bonus: Label = null # arme seulement : bonus 3/3 actif ou absent (jalon 20 quater)
		if slot == 0:
			bonus = Label.new()
			bonus.name = "Bonus"
			bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			c[1].add_child(bonus)
		var lines: Label = Label.new()
		c[1].add_child(lines)
		_slot_cards.append({"head": c[0], "tag": c[2], "schools": schools, "bonus": bonus, "lines": lines})

# Sacoche (jalon 20) : Cendre, Éclats (fiche par ilvl), coffre, au-dessus du bouton Purifier et de sa raison.
func _build_sacoche() -> void:
	_sac_rows["cendre"] = _line(_sacoche, UiStyle.icon("cendre"))
	var group: ButtonGroup = ButtonGroup.new()
	group.allow_unpress = true
	var c: Array = _card(_sacoche, group, UiStyle.icon("ECLAT"))
	var lines: Label = Label.new()
	c[1].add_child(lines)
	_sac_rows["eclats"] = {"head": c[0], "tag": c[2], "lines": lines}
	_sac_rows["minerai"] = _line(_sacoche, UiStyle.icon("minerai"))
	# Purifier à droite de la ligne Éclats, toujours visible (Z11) : rangée [tête | bouton], raison sous la rangée. Le bouton
	# est le frère de la tête, pas son enfant : l'appui ne bascule pas la fiche.
	var card: Node = c[0].get_parent()
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Rangee"
	row.add_theme_constant_override("separation", 2)
	card.add_child(row)
	card.move_child(row, 0)
	c[0].reparent(row)
	c[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_purify.owner = null # nœuds de la scène déplacés sous des nœuds créés en code : sans propriétaire de scène
	_purify_reason.owner = null
	_purify.reparent(row)
	_purify.text = "Purifier"
	_purify.focus_mode = Control.FOCUS_NONE
	for st: String in ["normal", "hover"]: # fond foncé d'un choix enfoncé : se lit comme un bouton à côté de la ligne
		_purify.add_theme_stylebox_override(st, _purify.get_theme_stylebox("pressed"))
	_purify_reason.reparent(card)
	card.move_child(_purify_reason, 1)

# Forge (jalon 20 bis) : minerai et Cendre en lignes simples, Mode en rangée de choix (aide dessous), puis les 4 boutons
# d'action dans Boutons et la raison.
func _build_forge() -> void:
	_forge_reason.add_theme_color_override("font_color", UiStyle.REASON)
	var boutons: Node = _forge.get_node("Boutons")
	_forge_rows["minerai"] = _line(_forge, UiStyle.icon("minerai"))
	_forge_rows["cendre"] = _line(_forge, UiStyle.icon("cendre"))
	_section(_forge, "Mode")
	_forge_mode = _block(_forge, {"SANS": "Sans Cendre", "AVEC": "Avec Cendre (%d)" % BA.CENDRE_COST_STANDARD_CRAFT}, func(value: String) -> void:
		_forge_with_cendre = value == "AVEC"
		refresh_forge_help()
		_refresh_forge_reason())
	_forge_mode["lines"].free()
	_forge_mode["row"].name = "Mode"
	_set_choice(_forge_mode["buttons"], 1, true)
	_section(_forge, "Forger")
	_forge.move_child(boutons, -1)
	_forge.move_child(_forge_reason, -1)
	for slot in EqText.SLOT_NAMES.size():
		var b: Button = _action(boutons, UiStyle.icon("SLOT_%d" % slot))
		b.text = "\n".join(EqText.forge_button(slot, null))
		b.disabled = true
		b.pressed.connect(func() -> void: forge_requested.emit(slot, _forge_with_cendre))
		_forge_buttons.append(b)
	_section(_forge, "École de l'Arme") # en bas, après la raison : texte fixe, rempli une fois (jalon 20 quater)
	var help: Label = Label.new()
	help.name = "Ecole"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", UiStyle.MUTED)
	help.text = "\n".join(EqText.school_help())
	_forge.add_child(help)

# Carte d'Aperçu, sous Apercu/Box : tête, Verdict, Pieces (Nouvelle et Équipée en une ligne chacune), Stats (une ligne par
# stat du personnage : avec l'équipée, avec la nouvelle, écart en couleur), puis Choix.
func _build_preview() -> void:
	var box: VBoxContainer = _preview.get_node("Box")
	_preview_head = _line(box, UiStyle.icon("SLOT_0"))
	_preview_head["tag"].add_theme_color_override("font_color", UiStyle.SUPERIOR)
	box.move_child(box.get_child(-1), 0)
	var pieces: GridContainer = GridContainer.new()
	pieces.name = "Pieces"
	pieces.columns = 2
	pieces.add_theme_constant_override("h_separation", 8)
	box.add_child(pieces)
	for title: String in ["Nouvelle", "Équipée"]:
		var t: Label = Label.new()
		t.text = title
		t.add_theme_color_override("font_color", UiStyle.TITLE)
		pieces.add_child(t)
		var l: Label = Label.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # Écoles mêlées : sur 2 lignes
		pieces.add_child(l)
		_summaries.append(l)
	var stats: GridContainer = GridContainer.new()
	stats.name = "Stats"
	stats.columns = 4
	stats.add_theme_constant_override("h_separation", 8)
	box.add_child(stats)
	for row in EqText.STAT_LABELS.size() + 1:
		var cells: Array[Label] = []
		for col in 4:
			var l: Label = Label.new()
			if col == 0:
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			stats.add_child(l)
			cells.append(l)
		if row == 0: # en-tête
			for col in 4:
				cells[col].text = ["Si tu équipes", "Équipée", "Nouvelle", "Écart"][col]
				cells[col].add_theme_color_override("font_color", UiStyle.TITLE)
		else:
			cells[0].text = EqText.STAT_LABELS[row - 1]
			_stat_cells.append(cells)
	box.move_child(box.get_node("Choix"), -1)

# Mode debug, sous Crédits : créé seulement si enabled (OS.is_debug_build() en jeu) ; en release, aucun nœud.
# Temps, Ressources, Progression et Remise à zéro au village seulement ; Combat en mémoire, Saturation en Brume seulement.
func build_debug(enabled: bool) -> void:
	if not enabled or not _debug.is_empty():
		return
	var page: Node = get_node(PAGES + "Options")
	_section(page, "Debug")
	_debug = {"village": [], "village_reasons": [], "shards": []}
	var groups: Array = [["Temps", [["tick", "Tick du jour"], ["absence", "+%d h d'absence" % int(BB.OFFLINE_MAX_HOURS)],
			["chantier", "Finir le chantier"]]],
		["Ressources", [["cendre", "Cendre au max"], ["eclat", "+1 Éclat"], ["eclat_elite", "+1 Éclat d'Élite"],
			["minerai", "+%d minerais" % DebugS.DEBUG_ORE], ["or", "+%d Or" % DebugS.DEBUG_GOLD], ["materiaux", "Matériaux au max"]]],
		["Progression", ProgressionS.VOCATIONS.map(func(v: String) -> Array: return [v, "+1 niveau " + ProgressionS.VOCATION_NAMES[v]])],
		["Remise à zéro", [["zero_joueur", "Joueur à zéro"], ["zero_ressources", "Ressources à zéro"], ["zero_batiments", "Bâtiments à zéro"],
			["zero_pnj", "PNJ à zéro"], ["postes", "Postes au plafond"]]],
		["Combat", [["saturation", "Saturation pleine"]]], ["Sauvegarde", [["copie", "Copier la sauvegarde"]]]]
	for g: Array in groups:
		_section(page, g[0])
		var reason: Label = Label.new()
		reason.add_theme_color_override("font_color", UiStyle.REASON)
		reason.visible = false
		page.add_child(reason)
		if g[0] == "Combat":
			var inv: Button = _action(page, null)
			inv.text = "Invincible"
			inv.toggle_mode = true # revient à faux au lancement : jamais sauvegardé
			inv.toggled.connect(debug_invincible.emit)
			_debug["mist_reason"] = reason
		elif g[0] != "Sauvegarde":
			_debug["village_reasons"].append(reason)
		for a: Array in g[1]:
			var b: Button = _action(page, null)
			b.text = a[1]
			b.pressed.connect(debug_requested.emit.bind(a[0]))
			if a[0] == "saturation":
				_debug["mist"] = b
			elif g[0] != "Sauvegarde":
				_debug["village"].append(b)
			if a[0].begins_with("eclat"):
				_debug["shards"].append(b)

# Geste Retour d'Android : ferme l'écran Crédits, sinon le Rapport, sinon l'onglet ouvert. La carte Équiper / Jeter reste
# (décision bloquante). Rend vrai si quelque chose s'est fermé.
func go_back() -> bool:
	var credits: Control = get_node_or_null("Credits")
	if credits != null and credits.visible:
		credits.visible = false
		return true
	if _report.visible:
		_report.visible = false
		return true
	for t: Button in _tabs:
		if t.button_pressed and not t.disabled:
			t.button_pressed = false
			return true
	return false

# Grisé et raisons du mode debug ; relu à chaque image par main.gd, ne touche que ce qui change.
func set_debug_state(in_village: bool, in_mist: bool, bag_full: bool) -> void:
	if _debug.is_empty():
		return
	for b: Button in _debug["village"]:
		var off: bool = not in_village or (bag_full and b in _debug["shards"])
		if b.disabled != off:
			b.disabled = off
	for k in _debug["village_reasons"].size():
		var r: Label = _debug["village_reasons"][k]
		r.text = "Au village seulement" if not in_village else ("Sacoche pleine" if k == 1 and bag_full else "")
		r.visible = r.text != ""
	if _debug["mist"].disabled == in_mist:
		_debug["mist"].disabled = not in_mist
	_debug["mist_reason"].text = "En Brume seulement"
	_debug["mist_reason"].visible = not in_mist

# Bouton d'action (Charte §2) : icône 16 px, verbe puis rappel sur 2 lignes, toute la largeur, sans bascule.
func _action(parent: Node, icon: Texture2D) -> Button:
	var b: Button = Button.new()
	parent.add_child(b)
	_style_action(b, icon)
	return b

func _style_action(b: Button, icon: Texture2D) -> void:
	b.icon = icon
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = false

# Étiquette d'état à droite de la ligne du nom (Charte §5), sans capter l'appui.
func _tag(host: Control) -> Label:
	var tag: Label = Label.new()
	tag.name = "Tag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var margin: StyleBox = host.get_theme_stylebox("normal", "Button")
	tag.anchor_left = 1.0
	tag.anchor_right = 1.0
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.offset_top = margin.get_margin(SIDE_TOP)
	tag.offset_right = -margin.get_margin(SIDE_RIGHT)
	host.add_child(tag)
	return tag

# Ligne simple (Charte §2) : même rendu qu'une tête fermée (fond du bouton, icône 16 px, 2 lignes, étiquette), sans bascule.
func _line(parent: Node, icon: Texture2D) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(panel)
	panel.add_theme_stylebox_override("panel", panel.get_theme_stylebox("normal", "Button"))
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", panel.get_theme_constant("h_separation", "Button"))
	panel.add_child(row)
	var pic: TextureRect = TextureRect.new()
	pic.texture = icon
	pic.mouse_filter = Control.MOUSE_FILTER_PASS
	pic.custom_minimum_size = Vector2(16, 16)
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pic)
	var text: Label = Label.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var tag: Label = Label.new() # sur la ligne du nom, comme l'étiquette d'une tête de carte
	tag.name = "Tag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(tag)
	return {"text": text, "tag": tag, "icon": pic, "panel": panel}

# Ligne dépliable : bouton de tête (icône, texte sur 2 lignes, étiquette d'état) et fiche cachée dessous, une ouverte par
# groupe. -> [tête, VBox de la fiche, étiquette].
func _card(parent: Node, group: ButtonGroup, icon: Texture2D) -> Array:
	var card: VBoxContainer = VBoxContainer.new()
	card.add_theme_constant_override("separation", 0)
	parent.add_child(card)
	var head: Button = Button.new()
	head.name = "Tete"
	head.toggle_mode = true
	head.button_group = group
	head.focus_mode = Control.FOCUS_NONE
	head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.icon = icon
	card.add_child(head)
	var detail: PanelContainer = PanelContainer.new()
	detail.name = "Detail"
	detail.visible = false
	detail.add_theme_stylebox_override("panel", _detail_style)
	card.add_child(detail)
	head.toggled.connect(func(on: bool) -> void: detail.visible = on)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	detail.add_child(box)
	return [head, box, _tag(head)]

func _section(parent: Node, text: String) -> Label:
	var title: Label = Label.new()
	title.text = text
	title.add_theme_color_override("font_color", UiStyle.TITLE)
	parent.add_child(title)
	return title

# Lignes, rangée de boutons à bascule (un ButtonGroup) si choices n'est pas vide, aide atténuée.
func _block(parent: Node, choices: Dictionary, on_choice: Callable) -> Dictionary:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	var lines: Label = Label.new()
	box.add_child(lines)
	var buttons: Array[Button] = []
	var row: HBoxContainer = null
	if not choices.is_empty():
		row = HBoxContainer.new()
		row.name = "Choix"
		row.add_theme_constant_override("separation", 2)
		box.add_child(row)
		var group: ButtonGroup = ButtonGroup.new()
		for value: String in choices:
			var b: Button = Button.new()
			b.text = choices[value]
			b.toggle_mode = true
			b.button_group = group
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(on_choice.bind(value))
			row.add_child(b)
			buttons.append(b)
	var help: Label = Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", UiStyle.MUTED)
	box.add_child(help)
	return {"lines": lines, "buttons": buttons, "help": help, "row": row}

# Noms des PNJ tirés de la graine du monde ; main.gd appelle ensuite show_village.
func set_world_seed(world_seed: int) -> void:
	_world_seed = world_seed
	if not _npc_cards.is_empty():
		_names = VText.with_identities(_names, world_seed, _npc_sprites)

# Onglets PNJ et Village : textes et état des boutons seulement. Bouton allumé = valeur en attente, sinon en cours.
func show_village(village: Dictionary, hour: int, can_set: bool, reason: String) -> void:
	if _npc_cards.is_empty():
		return
	for page: String in ["PNJ", "Village"]:
		var r: Label = get_node(PAGES + page + "/Raison")
		r.text = reason
		r.visible = not can_set
	if village.is_empty():
		return
	var managers: Dictionary = {}
	for i in mini(_npc_cards.size(), village["npcs"].size()):
		var npc: Dictionary = village["npcs"][i]
		if npc["manages"] != "":
			managers[npc["manages"]] = i
		var card: Dictionary = _npc_cards[i]
		var lines: PackedStringArray = VText.npc_lines(npc, i, hour, _names)
		var head: PackedStringArray = lines[0].split(" : ", true, 1) # nom, puis poste, étoiles et gérance
		card["head"].text = head[0] + "\n" + head[1]
		card["moral"].text = VText.moral_tag(npc)
		card["moral"].add_theme_color_override("font_color", UiStyle.MORAL_COLORS[VText.moral_band(npc["moral"], npc["on_strike"])])
		card["lines"].text = "\n".join(lines.slice(1))
		var apt: Dictionary = AssignS.aptitudes(_world_seed, i)
		card["hint"].text = VText.apt_lines(apt, AssignS.favorite(i), _names)[1]
		var active: Array[String] = AssignS.active_posts()
		for k in active.size():
			card["posts"][k].text = "%s %d" % [_names["posts"][active[k]], apt[active[k]]]
		_set_choice(card["posts"], active.find(AssignS.effective_post(npc)), can_set)
		card["pending"].text = "\n".join(VText.post_lines(npc, _names))
		card["free"].visible = npc.get("locked", false)
		card["free"].disabled = not can_set
		var producer: bool = Dag.POST_SHOP.has(npc["post"]) # la cadence suit le poste du jour
		for c: Control in [card["cad_title"], card["row"], card["help"]]:
			c.visible = producer
		if producer:
			var pending: String = npc.get("cadence_next", "")
			_set_choice(card["buttons"], _names["cadences"].keys().find(pending if pending != "" else npc["cadence"]), can_set)
			card["help"].text = VText.cadence_help(npc["cadence"], pending, _names)
	var lvl: int = village.get("atre_lvl", 1)
	_atre["head"].text = "\n".join(VText.atre_head(lvl, village["npcs"].size()))
	_atre["detail"].text = VText.atre_detail(lvl)
	_atre["slots"].text = VText.slots_line(village, lvl, _names)
	_atre["tag"].text = "Chantier" if village.has("atre_chantier_end") else ""
	var more: bool = lvl < BD.VERTICAL_SLICE_MAX_ATRE_LEVEL
	for c: Control in _atre["upgrade"]:
		c.visible = more
	if more:
		_atre["effect"].text = VText.upgrade_effect(lvl)
		_atre["button"].text = "\n".join(VText.upgrade_button(lvl, _names))
	for key: String in _shop_blocks:
		var shop: Dictionary = village["shops"][key]
		var block: Dictionary = _shop_blocks[key]
		var pending: String = shop.get("posture_next", "")
		block["head"].text = "\n".join(VText.shop_head(key, shop, _names))
		block["lines"].text = "\n".join(VText.shop_lines(key, shop, village["isolat"], managers.get(key, 0), _names))
		_set_choice(block["buttons"], _names["postures"].keys().find(pending if pending != "" else shop["posture"]), can_set)
		block["help"].text = VText.posture_help(shop["posture"], pending, _names)
		block["tag"].text = "Chantier" if shop.has("chantier_end") else ""
		var bigger: bool = shop["lvl"] < ShopUpS.MAX_LEVEL
		for c: Control in block["upgrade"]:
			c.visible = bigger
		if bigger:
			block["effect"].text = VText.shop_upgrade_effect(key, shop)
			block["button"].text = "\n".join(VText.shop_upgrade_button(shop["lvl"], _names))

# Grisé : Godot dessine le style « disabled » même enfoncé ; le bouton choisi garde alors le fond « pressed » (AC4).
func _set_choice(buttons: Array[Button], on: int, enabled: bool) -> void:
	for k in buttons.size():
		var b: Button = buttons[k]
		b.set_pressed_no_signal(k == on)
		b.disabled = not enabled
		if b.disabled and k == on:
			b.add_theme_stylebox_override("disabled", b.get_theme_stylebox("pressed"))
		else:
			b.remove_theme_stylebox_override("disabled")

# Bouton Agrandir actif si reason est vide, sinon grisé avec la raison dessous ; relu à chaque image par main.gd.
func set_atre_reason(reason: String) -> void:
	if _atre.is_empty():
		return
	var on: bool = reason == ""
	if _atre["button"].disabled == on:
		_atre["button"].disabled = not on
	_atre["reason"].text = reason
	_atre["reason"].visible = not on and _atre["button"].visible

# Boutons « Agrandir la boutique » : clé de boutique -> raison ("" = actif) ; relu à chaque image, ne touche que ce qui change.
func set_shop_reasons(reasons: Dictionary) -> void:
	for key: String in reasons:
		var block: Dictionary = _shop_blocks.get(key, {})
		if block.is_empty():
			continue
		var on: bool = reasons[key] == ""
		if block["button"].disabled == on:
			block["button"].disabled = not on
		if block["reason"].text != reasons[key]:
			block["reason"].text = reasons[key]
		var shown: bool = not on and block["button"].visible
		if block["reason"].visible != shown:
			block["reason"].visible = shown

# Hauteur fixe de la fenêtre, ancrée en bas de Monde (juste au-dessus des onglets) : offsets seulement.
func fit_window(zone_height: float) -> void:
	if _window != null:
		_window.offset_top = -roundf(zone_height * WINDOW_HEIGHT_RATIO)

func show_gold(gold: int) -> void:
	_gold = gold
	_refresh_hud()

# Bandeau et onglet Sacoche ; ore : minerai du coffre.
func show_player(player: Dictionary, ore: int) -> void:
	_player = player
	_ore = ore
	_refresh_hud()
	if _sac_rows.is_empty():
		return
	_sac_rows["cendre"]["text"].text = "\n".join(EqText.cendre_row(player["cendre"]))
	_sac_rows["eclats"]["head"].text = "\n".join(EqText.shards_row(player["shard_bag"]))
	_sac_rows["eclats"]["lines"].text = "\n".join(EqText.shards_detail(player["shard_bag"]))
	_sac_rows["minerai"]["text"].text = "\n".join(EqText.ore_row(ore))

# Couples créés dans la scène : un couple sans valeur est masqué.
func _refresh_hud() -> void:
	if _player.is_empty():
		return
	var shown: Dictionary = {}
	for pair: Array in EqText.hud_values(_gold, _player, _ore, _cargo, compact):
		shown[pair[0]] = pair[1]
	for key: String in UiStyle.HUD_KEYS:
		var couple: Control = _hud.get_node_or_null("Ligne/" + key.capitalize())
		if couple != null:
			couple.visible = shown.has(key)
			couple.get_node("Valeur").text = shown.get(key, "")

# Onglet Perso : vocations (rattrapage en GOOD), stats portées, une ligne dépliable par emplacement (Supérieure en
# SUPERIOR, Écoles de l'arme en couleur d'École quand les 3 sont identiques).
func show_perso(player: Dictionary, stats: Dictionary) -> void:
	if _voc_lines.is_empty():
		return
	for voc: String in ProgressionS.VOCATIONS:
		var l: Dictionary = _voc_lines[voc]
		l["text"].text = "\n".join(EqText.voc_head(voc, player["voc_xp"]))
		l["tag"].text = EqText.voc_tag(voc, player["voc_xp"])
		l["tag"].add_theme_color_override("font_color", UiStyle.GOOD)
	_stats.text = "\n".join(EqText.stats_lines(stats))
	for slot in _slot_cards.size():
		var c: Dictionary = _slot_cards[slot]
		var piece: Variant = player["equipment"][slot]
		c["head"].text = "\n".join(EqText.piece_head(slot, piece))
		c["tag"].text = EqText.piece_tag(slot, piece)
		c["tag"].add_theme_color_override("font_color", UiStyle.SUPERIOR)
		c["schools"].visible = piece != null and slot == 0
		if c["bonus"] != null:
			c["bonus"].visible = piece != null
			if piece != null:
				var bl: Array = EqText.school_bonus_line(piece)
				c["bonus"].text = bl[0]
				c["bonus"].add_theme_color_override("font_color", UiStyle.ROLES[bl[1]])
		if piece == null:
			c["lines"].text = EqText.empty_detail(slot)
			continue
		var detail: PackedStringArray = EqText.piece_detail(slot, piece)
		if slot == 0: # Écoles seules en couleur, ATK d'arme en tête du reste (jalon 20 ter)
			var s: Array = piece["schools"]
			var wl: PackedStringArray = EqText.weapon_lines(piece)
			c["schools"].text = wl[0]
			c["schools"].add_theme_color_override("font_color", UiStyle.school_color(s[0]) if s[0] == s[1] and s[1] == s[2] else UiStyle.TEXT)
			detail[0] = wl[1]
		c["lines"].text = "\n".join(detail)
		c["lines"].visible = not detail.is_empty()

# Bouton actif si reason est vide, sinon grisé avec la raison dessous (comme la Forge) ; relu à chaque image par main.gd.
func set_purify_reason(reason: String) -> void:
	if _purify == null:
		return
	var on: bool = reason == ""
	if _purify.disabled == on:
		_purify.disabled = not on
	_purify_reason.text = reason
	_purify_reason.visible = not on

# Forge (jalons 16, 16 bis et 20 bis) : réserves, pièce équipée sur chaque bouton et aide du mode, mises à jour par main.gd
# (_show_player) et à chaque bascule ; textes seulement.
func set_forge_help_source(help_of: Callable) -> void:
	_forge_help_of = help_of

func show_forge(ore: int, cendre_have: int, equipment: Array) -> void:
	if _forge == null:
		return
	_forge_rows["minerai"]["text"].text = "\n".join(EqText.ore_row(ore))
	_forge_rows["cendre"]["text"].text = "\n".join(EqText.forge_cendre_row(cendre_have))
	for slot in _forge_buttons.size():
		_forge_buttons[slot].text = "\n".join(EqText.forge_button(slot, equipment[slot]))
	refresh_forge_help()

func refresh_forge_help() -> void:
	if _forge != null and _forge_help_of.is_valid():
		_forge_mode["help"].text = "\n".join(_forge_help_of.call(_forge_with_cendre))

# 4 boutons actifs si reason_of(cendre) est vide, sinon grisés avec la raison ; relu à chaque image par main.gd
# (la sortie du rayon de l'Âtre n'a pas d'événement). Label.text ne redessine rien si le texte est identique.
func set_forge_enabled(reason_of: Callable) -> void:
	if _forge == null:
		return
	_forge_reason_of = reason_of
	_refresh_forge_reason()

func _refresh_forge_reason() -> void:
	if not _forge_reason_of.is_valid():
		return
	var reason: String = _forge_reason_of.call(_forge_with_cendre)
	var on: bool = reason == ""
	for b: Button in _forge_buttons:
		if b.disabled == on:
			b.disabled = not on
	_forge_reason.text = reason
	_forge_reason.visible = not on

# Aperçu (purification) ou carte de résultat (craft) : tête (Supérieure en SUPERIOR), verdict en couleur (jalon 16 bis),
# résumé des 2 pièces, tableau stat par stat « Si tu équipes » (jalon 20 bis, Z11). La fenêtre est masquée et les onglets grisés.
func show_preview(piece: Dictionary, current: Variant, before_st: Dictionary, after_st: Dictionary, forged: bool) -> void:
	if _preview == null:
		return
	var slot: int = piece["slot"]
	var verdict: int = EqText.compare(before_st, after_st)
	_preview_head["icon"].texture = UiStyle.icon("SLOT_%d" % slot)
	_preview_head["text"].text = "\n".join(EqText.preview_head(forged, slot))
	_preview_head["tag"].text = EqText.piece_tag(slot, piece)
	_verdict.text = EqText.VERDICTS[verdict]
	_verdict.add_theme_color_override("font_color", UiStyle.VERDICT_COLORS[verdict])
	_summaries[0].text = EqText.piece_summary(slot, piece)
	_summaries[1].text = EqText.piece_summary(slot, current)
	var rows: Array = EqText.stat_rows(before_st, after_st)
	for k in _stat_cells.size():
		for col in [1, 2, 3]:
			_stat_cells[k][col].text = rows[k][col]
		_stat_cells[k][3].add_theme_color_override("font_color", UiStyle.DIFF_COLORS[rows[k][4]])
	_preview.visible = true
	_apply_tabs()

func hide_preview() -> void:
	if _preview != null:
		_preview.visible = false
		_apply_tabs()

# Page de l'onglet enfoncé, titre à son nom ; la carte passe devant et grise les onglets jusqu'au choix.
func _apply_tabs() -> void:
	var card: bool = _preview.visible
	var open: int = -1
	for i in _tabs.size():
		_pages[i].visible = _tabs[i].button_pressed
		if _tabs[i].button_pressed:
			open = i
		_tabs[i].disabled = card
	_window.visible = open >= 0 and not card
	if open >= 0:
		_title.text = TAB_TITLES[open]

func show_level_up(voc: String, level: int) -> void:
	show_toast("%s niveau %d !" % [ProgressionS.VOCATION_NAMES[voc], level], voc)

# Saturation de Brume (jalon 20 ter) : accompagne la jauge pleine en BAD, la couleur ne porte jamais seule le sens.
func show_elite_awake() -> void:
	show_toast("L'Élite s'éveille !", "ELITE")

# Changement de poste (jalon 19) : result = sortie de Assignment.move.
func show_move(index: int, post: String, result: Dictionary) -> void:
	show_toast(VText.move_toast(index, post, result, _names), "TAB_PNJ")

# Un nouveau toast (montée, poste) remplace le texte et relance la durée. icon_notion : clé de UiStyle.ICONS, "" sans icône.
func show_toast(text: String, icon_notion: String = "") -> void:
	_toast_text.text = text
	_toast_icon.visible = icon_notion != ""
	if _toast_icon.visible:
		_toast_icon.texture = UiStyle.icon(icon_notion)
	_toast.visible = true
	_toast_id += 1
	if is_inside_tree(): # hors arbre sous le simulateur headless
		get_tree().create_timer(LEVEL_UP_TOAST_SEC).timeout.connect(_hide_toast.bind(_toast_id))

# Seul le dernier timer masque : comparer à ticks_msec ratait quand le timer (somme des delta) finissait quelques ms avant.
func _hide_toast(id: int) -> void:
	if id == _toast_id:
		_toast.visible = false

# Compteur d'expédition (volet E §3, jalon 17) : jauge de saturation = Cendre de l'expédition sur le budget avant l'Élite,
# cargaison dans le bandeau. Les Éclats du bandeau sont ceux de la Sacoche (show_player).
func show_expedition(shown: bool, cendre: int, _shards: int, cargo_kg: float, cap_kg: float) -> void:
	_gauge.visible = shown
	_gauge.max_value = BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET
	_gauge.value = cendre
	_gauge_fill.bg_color = UiStyle.BAD if _gauge.value >= _gauge.max_value else UiStyle.TEXT # pleine : Élite éveillé
	_cargo = [cargo_kg, cap_kg] if shown else null
	_refresh_hud()

# Lignes créées une fois dans _ready : on masque les clés absentes, on remplit texte, couleur de rôle et étiquette.
func show_report(report: Dictionary) -> void:
	var shown: Dictionary = {}
	for r: Dictionary in VeilleeReportS.rows(report, compact):
		shown[r["key"]] = r
	for key: String in _report_rows:
		var l: Dictionary = _report_rows[key]
		l["panel"].visible = shown.has(key)
		if shown.has(key):
			l["text"].text = shown[key]["text"]
			l["text"].add_theme_color_override("font_color", UiStyle.ROLES[shown[key]["role"]])
			l["tag"].text = shown[key]["tag"]
	_report.visible = true

func show_error(text: String) -> void:
	_error.text = text
	_error.visible = true

# Zone sûre (encoche de l'écran externe), en pixels de viewport, à l'échelle choisie par main.gd.
func apply_safe_area(window_size: Vector2i, scale: int) -> void:
	if not OS.has_feature("mobile"):
		return
	var m: PackedInt32Array = FoldModeS.safe_margins(window_size, scale, DisplayServer.get_display_safe_area())
	_margin.add_theme_constant_override("margin_left", m[0])
	_margin.add_theme_constant_override("margin_top", m[1])
	_margin.add_theme_constant_override("margin_right", m[2])
	_margin.add_theme_constant_override("margin_bottom", m[3])
	var skills: Control = get_node_or_null("Aptitudes") # plié seulement : boutons d'aptitude dans la zone sûre
	if skills != null:
		skills.offset_left = m[0]
		skills.offset_top = m[1]
		skills.offset_right = -m[2]
		skills.offset_bottom = -m[3]

func _on_report_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		_report.visible = false
