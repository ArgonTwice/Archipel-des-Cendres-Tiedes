extends CanvasLayer
# Couche UI pliée ou dépliée (SOCLE §A3) : instanciée une fois dans main.tscn, jamais reconstruite.

const VeilleeReportS = preload("res://scripts/ui/veillee_report.gd")
const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const BA = preload("res://balance/balance_a.gd")
const ProgressionS = preload("res://scripts/progression.gd")

const LEVEL_UP_TOAST_SEC: float = 2.5 # PROPOSÉ, à valider (jalon 13)

@export var compact: bool = true

@onready var _margin: MarginContainer = $Margin
@onready var _gold: Label = $Margin/VBox/Gold
@onready var _vocations: Label = $Margin/VBox/Vocations
@onready var _lantern: Label = $Margin/VBox/Lanterne
@onready var _expedition: Label = $Margin/VBox/Expedition
@onready var _toast: Label = $Margin/VBox/Toast

var _toast_until: int = 0 # Time.get_ticks_msec() de fin du toast en cours
@onready var _report: PanelContainer = $Margin/VBox/Report
@onready var _report_lines: VBoxContainer = $Margin/VBox/Report/Lines
@onready var _error: Label = $Margin/VBox/Error

func _ready() -> void:
	_report.gui_input.connect(_on_report_input)
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
	_lantern.text = "Lanterne : Cendre %d/%d  Éclats %d/%d" % [player["cendre"], BA.LANTERN_CENDRE_CAP[0], player["shards"], BA.LANTERN_SHARD_BAG_CAP[0]]

# Une nouvelle montée remplace le texte et relance la durée.
func show_level_up(voc: String, level: int) -> void:
	_toast.text = "%s niveau %d !" % [ProgressionS.VOCATION_NAMES[voc], level]
	_toast.visible = true
	_toast_until = Time.get_ticks_msec() + roundi(LEVEL_UP_TOAST_SEC * 1000.0)
	get_tree().create_timer(LEVEL_UP_TOAST_SEC).timeout.connect(_hide_toast)

func _hide_toast() -> void:
	if Time.get_ticks_msec() >= _toast_until:
		_toast.visible = false

# Compteur d'expédition (volet E §3) : Cendre Vive sur le budget avant l'Élite, Éclats.
func show_expedition(shown: bool, cendre: int, shards: int) -> void:
	_expedition.visible = shown
	_expedition.text = "Cendre %d/%d  Éclats %d" % [cendre, BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET, shards]

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
