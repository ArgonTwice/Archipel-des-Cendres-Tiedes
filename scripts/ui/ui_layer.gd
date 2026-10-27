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

@export var compact: bool = true

@onready var _margin: MarginContainer = $Margin
@onready var _gold: Label = $Margin/VBox/Gold
@onready var _vocations: Label = $Margin/VBox/Vocations
@onready var _lantern: Label = $Margin/VBox/Lanterne
@onready var _expedition: Label = $Margin/VBox/Expedition
@onready var _toast: Label = $Margin/VBox/Toast

var _toast_id: int = 0 # numéro du dernier toast affiché
@onready var _report: PanelContainer = $Margin/VBox/Report
@onready var _report_lines: VBoxContainer = $Margin/VBox/Report/Lines
@onready var _error: Label = $Margin/VBox/Error

# Panneau Équipement et aperçu de purification : couche dépliée seulement.
@onready var _equipment: PanelContainer = get_node_or_null("Margin/VBox/Equipement")
@onready var _preview: PanelContainer = get_node_or_null("Margin/VBox/Apercu")
@onready var _purify: Button = get_node_or_null("Margin/VBox/Equipement/Box/Purifier")
@onready var _forge: PanelContainer = get_node_or_null("Margin/VBox/Forge")
@onready var _forge_cendre: CheckButton = get_node_or_null("Margin/VBox/Forge/Box/AvecCendre")
var _forge_buttons: Array[Button] = []

func _ready() -> void:
	_report.gui_input.connect(_on_report_input)
	if _purify != null:
		_purify.pressed.connect(purify_requested.emit)
		$Margin/VBox/Apercu/Box/Choix/Equiper.pressed.connect(purify_chosen.emit.bind(true))
		$Margin/VBox/Apercu/Box/Choix/Jeter.pressed.connect(purify_chosen.emit.bind(false))
	if _forge != null:
		_forge_cendre.text = "Avec Cendre (%d)" % BA.CENDRE_COST_STANDARD_CRAFT
		for slot in EqText.SLOT_NAMES.size():
			var b: Button = Button.new()
			b.text = "Forger " + EqText.with_article(slot)
			b.disabled = true
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			b.pressed.connect(func() -> void: forge_requested.emit(slot, _forge_cendre.button_pressed))
			$Margin/VBox/Forge/Box.add_child(b)
			_forge_buttons.append(b)
	var credits_button: Button = get_node_or_null("Margin/VBox/CreditsButton")
	if credits_button != null:
		credits_button.pressed.connect($Credits.show)

func show_gold(gold: int) -> void:
	_gold.text = "Or : %d" % gold

# Plié : « Combattant 3  Mineur 2  Forgeron 1 ». Déplié : une ligne par vocation, XP dans le niveau / XP requise.
func show_vocations(player: Dictionary) -> void:
	var parts: PackedStringArray = []
	for voc: String in ProgressionS.VOCATIONS:
		var xp: int = player["voc_xp"][voc]
		var label: String = ProgressionS.VOCATION_NAMES[voc]
		if compact:
			parts.append("%s %d" % [label, ProgressionS.level_of(xp)])
		else:
			var p: Vector2i = ProgressionS.level_progress(xp)
			parts.append("%s  Nv %d  %d / %d XP" % [label, ProgressionS.level_of(xp), p.x, p.y])
	_vocations.text = ("  " if compact else "
").join(parts)

# Lanterne niveau 1 (jalon 14).
func show_lantern(player: Dictionary) -> void:
	var elite: int = 0
	for s: Dictionary in player["shard_bag"]:
		elite += int(s["elite"])
	_lantern.text = "Lanterne : Cendre %d/%d  Éclats %d/%d" % [player["cendre"], BA.LANTERN_CENDRE_CAP[0], player["shard_bag"].size(),
		BA.LANTERN_SHARD_BAG_CAP[0]]
	if elite > 0:
		_lantern.text += " (Élite %d)" % elite

# Une ligne par emplacement (affixes en retrait), puis les stats portées.
func show_equipment(equipment: Array, stats: Dictionary) -> void:
	if _equipment == null:
		return
	var lines: PackedStringArray = EqText.equipment_lines(equipment)
	lines.append(EqText.stats_line(stats))
	$Margin/VBox/Equipement/Box/Lines.text = "
".join(lines)

func set_purify_enabled(on: bool) -> void:
	if _purify != null and _purify.disabled == on:
		_purify.disabled = not on

# Forge (jalon 16) : coffre, puis 4 boutons actifs selon can(cendre), relu à chaque image par main.gd.
func show_forge(ore: int) -> void:
	if _forge != null:
		$Margin/VBox/Forge/Box/Coffre.text = "Coffre : %d minerai%s de fer-braise" % [ore, "s" if ore > 1 else ""]

func set_forge_enabled(can: Callable) -> void:
	if _forge == null:
		return
	var on: bool = can.call(_forge_cendre.button_pressed)
	for b: Button in _forge_buttons:
		if b.disabled == on:
			b.disabled = not on

# Aperçu (purification) ou carte de résultat (craft) : nouvelle pièce, pièce équipée du même emplacement, écart de stats.
# Les panneaux Équipement et Forge sont masqués.
func show_preview(piece: Dictionary, current: Variant, diff: String) -> void:
	if _preview == null:
		return
	var lines: PackedStringArray = ["Nouvelle pièce"]
	if piece.get("superior", false):
		lines.append("Qualité Supérieure")
	lines.append_array(EqText.piece_lines(piece["slot"], piece))
	lines.append("Équipée")
	lines.append_array(EqText.piece_lines(piece["slot"], current))
	lines.append(diff)
	$Margin/VBox/Apercu/Box/Lines.text = "
".join(lines)
	_preview.visible = true
	_equipment.visible = false
	_forge.visible = false

func hide_preview() -> void:
	if _preview != null:
		_preview.visible = false
		_equipment.visible = true
		_forge.visible = true

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

# Compteur d'expédition (volet E §3) : Cendre Vive sur le budget avant l'Élite, Éclats, minerai porté (jalon 16).
# Plié : minerai sur sa propre ligne, la ligne entière dépasse 208 px.
func show_expedition(shown: bool, cendre: int, shards: int, cargo_kg: float, cap_kg: float) -> void:
	_expedition.visible = shown
	_expedition.text = "Cendre %d/%d  Éclats %d%sMinerai %s/%s kg" % [cendre, BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET, shards,
		"
" if compact else "  ", kg(cargo_kg), kg(cap_kg)]

# À l'unité, ou à 0,1 près si non entier : « 25 », « 25,8 ».
static func kg(x: float) -> String:
	var r: float = snappedf(x, 0.1)
	return str(roundi(r)) if is_equal_approx(r, roundf(r)) else EqText.dec1(r)

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
