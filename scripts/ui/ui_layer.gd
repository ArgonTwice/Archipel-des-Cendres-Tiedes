extends CanvasLayer
# Couche UI pliée ou dépliée (SOCLE §A3) : instanciée une fois dans main.tscn, jamais reconstruite.

const VeilleeReportS = preload("res://scripts/ui/veillee_report.gd")
const FoldModeS = preload("res://scripts/ui/fold_mode.gd")

@export var compact: bool = true

@onready var _margin: MarginContainer = $Margin
@onready var _gold: Label = $Margin/VBox/Gold
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

# Zone sûre (encoche de l'écran externe), en pixels de viewport : division par l'échelle entière du stretch.
func apply_safe_area(window_size: Vector2i) -> void:
	if not OS.has_feature("mobile"):
		return
	var scale: int = FoldModeS.integer_scale(window_size, FoldModeS.base_size())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	_margin.add_theme_constant_override("margin_left", ceili(float(safe.position.x) / scale))
	_margin.add_theme_constant_override("margin_top", ceili(float(safe.position.y) / scale))
	_margin.add_theme_constant_override("margin_right", ceili(float(window_size.x - safe.end.x) / scale))
	_margin.add_theme_constant_override("margin_bottom", ceili(float(window_size.y - safe.end.y) / scale))

func _on_report_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		_report.visible = false
