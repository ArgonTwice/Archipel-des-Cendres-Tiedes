extends CanvasLayer
# Couche UI pliée ou dépliée (SOCLE §A3) : instanciée une fois dans main.tscn, jamais reconstruite.

const VeilleeReportS = preload("res://scripts/ui/veillee_report.gd")
const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const BA = preload("res://balance/balance_a.gd")

@export var compact: bool = true

@onready var _margin: MarginContainer = $Margin
@onready var _gold: Label = $Margin/VBox/Gold
@onready var _expedition: Label = $Margin/VBox/Expedition
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

func _on_report_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		_report.visible = false
