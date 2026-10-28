extends CanvasLayer
# Couche UI pliée ou dépliée (SOCLE §A3) : instanciée une fois dans main.tscn, jamais reconstruite.

const VeilleeReportS = preload("res://scripts/ui/veillee_report.gd")
const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const BA = preload("res://balance/balance_a.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")

signal purify_requested
signal purify_chosen(equip: bool)
signal forge_requested(slot: int, cendre: bool)

const LEVEL_UP_TOAST_SEC: float = 2.5 # PROPOSÉ, à valider (jalon 13)
const SUPERIOR_COLOR: Color = Color("#E69F00") # couleur de l'École Enclume ; PROPOSÉ, à valider (jalon 16 bis)
# Verdict de la carte : vert meilleure, vermillon moins bonne, blanc mixte (palette Okabe-Ito, comme #E69F00) ; PROPOSÉ, à valider (jalon 16 bis)
const VERDICT_COLORS: Dictionary = {1: Color("#009E73"), -1: Color("#D55E00"), 0: Color(1, 1, 1)}
const FORGE_REASON_COLOR: Color = Color(1, 1, 1, 0.6) # raison d'un bouton grisé, atténuée ; PROPOSÉ, à valider (jalon 16 bis)
const WINDOW_HEIGHT_RATIO: float = 0.5 # hauteur de la fenêtre / hauteur de la zone ; validé sur Fold (jalon 17)
# Icônes (jalon 17), déclarées une seule fois : [planche, région en taille native]. Tuiles d'onglet : validé sur Fold (jalon 17).
const HUD_ICONS: Dictionary = {
	"or": [preload("res://assets/icons/hud/coin_05d.png"), Rect2(1, 1, 14, 15)],
	"cendre": [preload("res://assets/icons/hud/campfire_16x16.png"), Rect2(2, 0, 12, 16)],
	"eclats": [preload("res://assets/icons/hud/item_gem_quartz.png"), Rect2(1, 1, 14, 14)],
	"minerai": [preload("res://assets/icons/hud/Stones_ores_gems_without_grass.png"), Rect2(0, 22, 15, 10)]}
const TD = preload("res://assets/tiles/kenney_tiny_dungeon/tilemap_packed.png")
const TT = preload("res://assets/tiles/kenney_tiny_town/tilemap_packed.png")
const TAB_ICONS: Array = [[TD, 112], [TT, 107], [TD, 74], [TT, 83]] # Perso, Sacoche, Forge, Options
const TAB_TITLES: Array[String] = ["Perso", "Sacoche", "Forge", "Options"]
const PAGES: String = "Margin/VBox/Monde/Fenetre/Box/Defile/Pages/"

@export var compact: bool = true

@onready var _margin: MarginContainer = $Margin
@onready var _hud: Control = $Margin/VBox/Hud
@onready var _gauge: ProgressBar = $Margin/VBox/Jauge
@onready var _toast: Label = $Margin/VBox/Monde/Messages/Toast

var _toast_id: int = 0 # numéro du dernier toast affiché
@onready var _report: PanelContainer = find_child("Report", true, false) # plié : sous le bandeau ; déplié : fenêtre centrée
@onready var _report_lines: VBoxContainer = _report.get_node("Lines")
@onready var _error: Label = $Margin/VBox/Monde/Messages/Error
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

static func atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var t: AtlasTexture = AtlasTexture.new()
	t.atlas = sheet
	t.region = region
	return t

# Tuile entière d'une planche Kenney à 12 colonnes.
static func tile_region(i: int) -> Rect2:
	return Rect2((i % 12) * 16, (i / 12) * 16, 16, 16)

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

# Une nouvelle montée remplace le texte et relance la durée.
func show_level_up(voc: String, level: int) -> void:
	_toast.text = "%s niveau %d !" % [ProgressionS.VOCATION_NAMES[voc], level]
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
