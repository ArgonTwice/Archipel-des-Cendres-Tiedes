extends Node
# Racine : charge la partie, bascule plié / déplié (SOCLE §A3), affiche le Rapport de veillée (§A4).

const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const ClockS = preload("res://autoload/Clock.gd")

@onready var _camera: Camera2D = $Camera2D
@onready var _ui_folded: CanvasLayer = $UI_Folded
@onready var _ui_unfolded: CanvasLayer = $UI_Unfolded

var _folded: bool = true
var _tween: Tween

func _ready() -> void:
	var r: Dictionary = SaveManager.start(ClockS.now_utc())
	if r.is_empty(): # state reste vide : plus aucune sauvegarde
		for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
			layer.show_error("Sauvegarde illisible. Rien n'a été écrit.")
	else:
		_show(r)
	_folded = FoldModeS.is_folded(get_window().size)
	FoldModeS.apply(_folded, _ui_folded, _ui_unfolded)
	_camera.zoom = FoldModeS.zoom_for(_folded)
	_apply_safe_area()
	get_viewport().size_changed.connect(_on_size_changed)
	SaveManager.synced.connect(_show)

func _show(r: Dictionary) -> void:
	for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
		layer.show_gold(r["state"]["village"]["player_gold"])
		layer.show_report(r)

func _apply_safe_area() -> void:
	for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
		layer.apply_safe_area(get_window().size)

# Plusieurs size_changed pendant un pliage = une seule bascule.
func _on_size_changed() -> void:
	_apply_safe_area()
	var folded: bool = FoldModeS.is_folded(get_window().size)	if folded == _folded:
		return
	_folded = folded
	FoldModeS.apply(_folded, _ui_folded, _ui_unfolded)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_camera, "zoom", FoldModeS.zoom_for(_folded), FoldModeS.TWEEN_SEC)
	var r: Dictionary = SaveManager.sync(ClockS.now_utc())
	if not r.is_empty():
		_show(r)
