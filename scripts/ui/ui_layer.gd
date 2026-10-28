extends CanvasLayer
# Couche UI pliée ou dépliée (SOCLE §A3) : instanciée une fois dans main.tscn, jamais reconstruite.

const VeilleeReportS = preload("res://scripts/ui/veillee_report.gd")
const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const BA = preload("res://balance/balance_a.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")
const VText = preload("res://scripts/ui/village_text.gd")
const NewGameS = preload("res://scripts/new_game.gd")
const Dag = preload("res://scripts/offline_dag.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const AssignS = preload("res://scripts/village/assignment.gd")

signal purify_requested
signal purify_chosen(equip: bool)
signal forge_requested(slot: int, cendre: bool)
signal cadence_chosen(index: int, cadence: String)
signal posture_chosen(key: String, posture: String)
signal post_chosen(index: int, post: String)
signal npc_freed(index: int)

const LEVEL_UP_TOAST_SEC: float = 2.5 # PROPOSÉ, à valider (jalon 13)
const SUPERIOR_COLOR: Color = Color("#E69F00") # couleur de l'École Enclume ; PROPOSÉ, à valider (jalon 16 bis)
# Verdict de la carte : vert meilleure, vermillon moins bonne, blanc mixte (palette Okabe-Ito, comme #E69F00) ; PROPOSÉ, à valider (jalon 16 bis)
const VERDICT_COLORS: Dictionary = {1: Color("#009E73"), -1: Color("#D55E00"), 0: Color(1, 1, 1)}
const FORGE_REASON_COLOR: Color = Color(1, 1, 1, 0.6) # raison d'un bouton grisé, atténuée ; PROPOSÉ, à valider (jalon 16 bis)
# Fiche PNJ (jalon 19, Z8) : intertitres bleu ciel, attente verte (Okabe-Ito), fond de fiche ; PROPOSÉ, à valider
const SECTION_COLOR: Color = Color("#56B4E9")
const NEXT_COLOR: Color = Color("#009E73")
const DETAIL_BG: Color = Color(1, 1, 1, 0.06)
const DETAIL_MARGIN_PX: int = 4
# Moral par bande de production (VText.moral_band), Okabe-Ito comme VERDICT_COLORS ; PROPOSÉ, à valider (jalon 19 bis)
const MORAL_COLORS: Dictionary = {"STRIKE": Color("#D55E00"), "LOW": Color("#E69F00"), "NORMAL": Color(1, 1, 1), "HIGH": Color("#009E73")}
const SHOP_ICON_TILES: Dictionary = {"MAT": "roche", "TAVERN": "tonneau", "FORGE": "enclume"} # tuiles de village.json
const WINDOW_HEIGHT_RATIO: float = 0.5 # hauteur de la fenêtre / hauteur de la zone ; validé sur Fold (jalon 17)
# Icônes (jalon 17), déclarées une seule fois : [planche, région en taille native]. Tuiles d'onglet : validé sur Fold (jalon 17).
const HUD_ICONS: Dictionary = {
	"or": [preload("res://assets/icons/hud/coin_05d.png"), Rect2(1, 1, 14, 15)],
	"cendre": [preload("res://assets/icons/hud/campfire_16x16.png"), Rect2(2, 0, 12, 16)],
	"eclats": [preload("res://assets/icons/hud/item_gem_quartz.png"), Rect2(1, 1, 14, 14)],
	"minerai": [preload("res://assets/icons/hud/Stones_ores_gems_without_grass.png"), Rect2(0, 22, 15, 10)]}
const TD = preload("res://assets/tiles/kenney_tiny_dungeon/tilemap_packed.png")
const TT = preload("res://assets/tiles/kenney_tiny_town/tilemap_packed.png")
const TAB_ICONS: Array = [[TD, 112], [TT, 107], [TD, 74], [TD, 99], [TT, 104], [TT, 83]] # Perso, Sacoche, Forge, PNJ, Village, Options
const TAB_TITLES: Array[String] = ["Perso", "Sacoche", "Forge", "PNJ", "Village", "Options"]
const PAGES: String = "Margin/VBox/Monde/Fenetre/Box/Defile/Pages/"
# Feu de camp de la Cendre (jalon 17 bis) : 4 images côte à côte sur la planche de krial.
const FIRE_FRAMES: int = 4
const FIRE_FRAME_MS: int = 125 # durée de l'auteur (GIF 120–130 ms) ; technique, validé sur Fold (jalon 17 bis)

@export var compact: bool = true

@onready var _margin: MarginContainer = $Margin
@onready var _hud: Control = $Margin/VBox/Hud
@onready var _gauge: ProgressBar = $Margin/VBox/Jauge
@onready var _toast: Label = $Margin/VBox/Monde/Messages/Toast

var _toast_id: int = 0 # numéro du dernier toast affiché
@onready var _report: PanelContainer = find_child("Report", true, false) # plié : sous le bandeau ; déplié : fenêtre centrée
@onready var _report_lines: VBoxContainer = _report.get_node("Lines")
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
@onready var _perso: Label = get_node_or_null(PAGES + "Perso")
@onready var _sacoche: Label = get_node_or_null(PAGES + "Sacoche/Lines")
@onready var _purify: Button = get_node_or_null(PAGES + "Sacoche/Purifier")
@onready var _purify_reason: Label = get_node_or_null(PAGES + "Sacoche/Raison")
@onready var _forge: Control = get_node_or_null(PAGES + "Forge")
@onready var _forge_cendre: CheckButton = get_node_or_null(PAGES + "Forge/AvecCendre")
@onready var _forge_help: Label = get_node_or_null(PAGES + "Forge/Aide")
@onready var _forge_reason: Label = get_node_or_null(PAGES + "Forge/Raison")
@onready var _superior: Label = get_node_or_null("Margin/VBox/Monde/Apercu/Box/Superieure")
@onready var _verdict: Label = get_node_or_null("Margin/VBox/Monde/Apercu/Box/Verdict")
var _forge_buttons: Array[Button] = []
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
var _shop_blocks: Dictionary = {} # clé de boutique -> {"head", "lines", "buttons", "help"}
var _atre: Dictionary = {} # {"head", "detail", "slots"}

static func atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var t: AtlasTexture = AtlasTexture.new()
	t.atlas = sheet
	t.region = region
	return t

# Tuile entière d'une planche Kenney à 12 colonnes.
static func tile_region(i: int) -> Rect2:
	return Rect2((i % 12) * 16, (i / 12) * 16, 16, 16)

# Région de l'image du feu à l'instant ms : celle de HUD_ICONS["cendre"], décalée d'une largeur d'image (planche / FIRE_FRAMES).
static func fire_region(ms: int) -> Rect2:
	var base: Rect2 = HUD_ICONS["cendre"][1]
	var step: float = float(HUD_ICONS["cendre"][0].get_width()) / FIRE_FRAMES
	return Rect2(base.position.x + step * ((ms / FIRE_FRAME_MS) % FIRE_FRAMES), base.position.y, base.size.x, base.size.y)

# Image 0 du feu, élargie à 16 px comme les tuiles : les textes des lignes Village restent alignés (jalon 19 bis).
static func fire_icon_region() -> Rect2:
	var base: Rect2 = HUD_ICONS["cendre"][1]
	return Rect2(base.position.x - (VL.CELL - base.size.x) / 2.0, base.position.y, VL.CELL, base.size.y)

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
	for key: String in HUD_ICONS:
		var icon: TextureRect = _hud.get_node_or_null("Ligne/%s/Icone" % key.capitalize())
		if icon != null:
			icon.texture = atlas(HUD_ICONS[key][0], HUD_ICONS[key][1])
	if _window != null:
		var group: ButtonGroup = ButtonGroup.new()
		group.allow_unpress = true
		for i in TAB_TITLES.size():
			var t: Button = get_node("Margin/VBox/Onglets/" + TAB_TITLES[i])
			t.icon = atlas(TAB_ICONS[i][0], tile_region(TAB_ICONS[i][1]))
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
		_purify_reason.add_theme_color_override("font_color", FORGE_REASON_COLOR)
		$Margin/VBox/Monde/Apercu/Box/Choix/Equiper.pressed.connect(purify_chosen.emit.bind(true))
		$Margin/VBox/Monde/Apercu/Box/Choix/Jeter.pressed.connect(purify_chosen.emit.bind(false))
		get_node(PAGES + "Options/CreditsButton").pressed.connect($Credits.show)
		_build_village_pages()
		if is_inside_tree(): # hors arbre sous le simulateur headless : il appelle fit_window lui-même
			fit_window(get_viewport().get_visible_rect().size.y)
			get_viewport().size_changed.connect(func() -> void: fit_window(get_viewport().get_visible_rect().size.y))
	if _forge != null:
		_forge_cendre.text = "Avec Cendre (%d)" % BA.CENDRE_COST_STANDARD_CRAFT
		_forge_cendre.toggled.connect(func(_on: bool) -> void: refresh_forge_help())
		_forge_reason.add_theme_color_override("font_color", FORGE_REASON_COLOR)
		_superior.add_theme_color_override("font_color", SUPERIOR_COLOR)
		_superior.text = "QUALITÉ SUPÉRIEURE : +%d ilvl" % BA.SUPERIOR_QUALITY_ILVL_BONUS
		for slot in EqText.SLOT_NAMES.size():
			var b: Button = Button.new()
			b.text = "Forger " + EqText.with_article(slot)
			b.disabled = true
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			b.pressed.connect(func() -> void: forge_requested.emit(slot, _forge_cendre.button_pressed))
			_forge.get_node("Boutons").add_child(b)
			_forge_buttons.append(b)
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
	get_node(PAGES + "PNJ/Raison").add_theme_color_override("font_color", FORGE_REASON_COLOR)
	get_node(PAGES + "Village/Raison").add_theme_color_override("font_color", FORGE_REASON_COLOR)
	var tip: Label = Label.new()
	tip.text = "Astuce : fais glisser un PNJ sur un bâtiment"
	pnj.add_child(tip)
	var post_names: Dictionary = {}
	for p: String in AssignS.active_posts():
		post_names[p] = _names["posts"][p]
	var group: ButtonGroup = ButtonGroup.new()
	group.allow_unpress = true
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = DETAIL_BG
	style.set_content_margin_all(DETAIL_MARGIN_PX)
	for i in NewGameS.START_POSTS.size():
		var made: Array = _card(pnj, group, style, atlas(TD, tile_region(int(data["tiles"][_npc_sprites[i]][1]))))
		var head: Button = made[0]
		var box: VBoxContainer = made[1]
		var moral: Label = Label.new()
		moral.name = "Moral"
		moral.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moral.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var margin: StyleBox = head.get_theme_stylebox("normal")
		moral.anchor_left = 1.0
		moral.anchor_right = 1.0
		moral.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		moral.offset_top = margin.get_margin(SIDE_TOP)
		moral.offset_right = -margin.get_margin(SIDE_RIGHT)
		head.add_child(moral)
		_section(box, "Profil")
		var lines: Label = Label.new()
		box.add_child(lines)
		_section(box, "Poste (chiffre = aptitude)")
		var posts: Dictionary = _block(box, post_names, func(post: String) -> void: post_chosen.emit(i, post))
		posts["row"].name = "Postes"
		posts["help"].name = "Demain"
		posts["help"].add_theme_color_override("font_color", NEXT_COLOR)
		posts["lines"].add_theme_color_override("font_color", FORGE_REASON_COLOR)
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
	var a: Array = _card(village, vgroup, style, atlas(HUD_ICONS["cendre"][0], fire_icon_region()))
	_atre = {"head": a[0], "detail": Label.new(), "slots": Label.new()}
	a[1].add_child(_atre["detail"])
	_section(a[1], "Postes")
	_atre["slots"].name = "Occupation"
	a[1].add_child(_atre["slots"])
	for key: String in Dag.SHOP_ITEM:
		var s: Array = _card(village, vgroup, style, atlas(TD, tile_region(int(data["tiles"][SHOP_ICON_TILES[key]][1]))))
		var block: Dictionary = _block(s[1], _names["postures"], func(value: String) -> void: posture_chosen.emit(key, value))
		block["row"].name = "Posture"
		var title: Label = _section(block["row"].get_parent(), "Posture")
		title.get_parent().move_child(title, 1)
		block["head"] = s[0]
		_shop_blocks[key] = block

# Ligne dépliable : bouton de tête (icône, texte sur 2 lignes) et fiche cachée dessous, une ouverte par groupe.
# -> [tête, VBox de la fiche].
func _card(parent: Node, group: ButtonGroup, style: StyleBox, icon: Texture2D) -> Array:
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
	detail.add_theme_stylebox_override("panel", style)
	card.add_child(detail)
	head.toggled.connect(func(on: bool) -> void: detail.visible = on)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	detail.add_child(box)
	return [head, box]

func _section(parent: Node, text: String) -> Label:
	var title: Label = Label.new()
	title.text = text
	title.add_theme_color_override("font_color", SECTION_COLOR)
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
	help.add_theme_color_override("font_color", FORGE_REASON_COLOR)
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
		card["moral"].add_theme_color_override("font_color", MORAL_COLORS[VText.moral_band(npc["moral"], npc["on_strike"])])
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
	for key: String in _shop_blocks:
		var shop: Dictionary = village["shops"][key]
		var block: Dictionary = _shop_blocks[key]
		var pending: String = shop.get("posture_next", "")
		block["head"].text = "\n".join(VText.shop_head(key, shop, _names))
		block["lines"].text = "\n".join(VText.shop_lines(key, shop, village["isolat"], managers.get(key, 0), _names))
		_set_choice(block["buttons"], _names["postures"].keys().find(pending if pending != "" else shop["posture"]), can_set)
		block["help"].text = VText.posture_help(shop["posture"], pending, _names)

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
	if _sacoche != null:
		_sacoche.text = "\n".join(EqText.sacoche_lines(player, ore))

# Couples créés dans la scène : un couple sans valeur est masqué.
func _refresh_hud() -> void:
	if _player.is_empty():
		return
	var shown: Dictionary = {}
	for pair: Array in EqText.hud_values(_gold, _player, _ore, _cargo, compact):
		shown[pair[0]] = pair[1]
	for key: String in HUD_ICONS:
		var couple: Control = _hud.get_node_or_null("Ligne/" + key.capitalize())
		if couple != null:
			couple.visible = shown.has(key)
			couple.get_node("Valeur").text = shown.get(key, "")

# Onglet Perso : vocations (XP dans le niveau / XP requise), stats portées, puis une ligne par emplacement (affixes en retrait).
func show_perso(player: Dictionary, stats: Dictionary) -> void:
	if _perso == null:
		return
	var lines: PackedStringArray = []
	for voc: String in ProgressionS.VOCATIONS:
		var xp: int = player["voc_xp"][voc]
		var p: Vector2i = ProgressionS.level_progress(xp)
		lines.append("%s  Nv %d  %d / %d XP" % [ProgressionS.VOCATION_NAMES[voc], ProgressionS.level_of(xp), p.x, p.y])
	lines.append("")
	lines.append_array(EqText.stats_lines(stats))
	lines.append("")
	lines.append_array(EqText.equipment_lines(player["equipment"]))
	_perso.text = "\n".join(lines)

# Bouton actif si reason est vide, sinon grisé avec la raison dessous (comme la Forge) ; relu à chaque image par main.gd.
func set_purify_reason(reason: String) -> void:
	if _purify == null:
		return
	var on: bool = reason == ""
	if _purify.disabled == on:
		_purify.disabled = not on
	_purify_reason.text = reason
	_purify_reason.visible = not on

# Forge (jalons 16 et 16 bis) : réserve et aide, mises à jour par main.gd (_show_player) et à chaque bascule ; textes seulement.
func set_forge_help_source(help_of: Callable) -> void:
	_forge_help_of = help_of

func show_forge(ore: int, cendre_have: int) -> void:
	if _forge != null:
		_forge.get_node("Reserve").text = EqText.forge_reserve(ore, cendre_have)
		refresh_forge_help()

func refresh_forge_help() -> void:
	if _forge != null and _forge_help_of.is_valid():
		_forge_help.text = "\n".join(_forge_help_of.call(_forge_cendre.button_pressed))

# 4 boutons actifs si reason_of(cendre) est vide, sinon grisés avec la raison ; relu à chaque image par main.gd
# (la sortie du rayon de l'Âtre n'a pas d'événement). Label.text ne redessine rien si le texte est identique.
func set_forge_enabled(reason_of: Callable) -> void:
	if _forge == null:
		return
	var reason: String = reason_of.call(_forge_cendre.button_pressed)
	var on: bool = reason == ""
	for b: Button in _forge_buttons:
		if b.disabled == on:
			b.disabled = not on
	_forge_reason.text = reason
	_forge_reason.visible = not on

# Aperçu (purification) ou carte de résultat (craft) : nouvelle pièce, pièce équipée du même emplacement, écart de stats.
# Qualité Supérieure et verdict en tête, en couleur (jalon 16 bis). La fenêtre est masquée et les onglets grisés.
func show_preview(piece: Dictionary, current: Variant, diff: String, forged: bool, verdict: int) -> void:
	if _preview == null:
		return
	_superior.visible = piece.get("superior", false)
	_verdict.text = EqText.VERDICTS[verdict]
	_verdict.add_theme_color_override("font_color", VERDICT_COLORS[verdict])
	var lines: PackedStringArray = ["Pièce forgée" if forged else "Pièce purifiée"]
	lines.append_array(EqText.piece_lines(piece["slot"], piece))
	lines.append("Équipée")
	lines.append_array(EqText.piece_lines(piece["slot"], current))
	lines.append(diff)
	_preview.get_node("Box/Lines").text = "\n".join(lines)
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
	show_toast("%s niveau %d !" % [ProgressionS.VOCATION_NAMES[voc], level])

# Changement de poste (jalon 19) : result = sortie de Assignment.move.
func show_move(index: int, post: String, result: Dictionary) -> void:
	show_toast(VText.move_toast(index, post, result, _names))

# Un nouveau toast (montée, poste) remplace le texte et relance la durée.
func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_id += 1
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
	_cargo = [cargo_kg, cap_kg] if shown else null
	_refresh_hud()

func show_report(report: Dictionary) -> void:
	for child: Node in _report_lines.get_children():
		_report_lines.remove_child(child)
		child.queue_free()
	for line: String in VeilleeReportS.lines(report, compact):
		var label: Label = Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_report_lines.add_child(label)
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
