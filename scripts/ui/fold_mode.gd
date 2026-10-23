class_name FoldMode
extends RefCounted
# Plié / déplié (SOCLE §A3) : double CanvasLayer préchargé, bascule de visibilité + Tween de zoom caméra.
# Constantes techniques UI, aucune valeur d'équilibrage.

const FOLDED_MIN_ASPECT: float = 1.5 # plié si hauteur >= 1,5 x largeur (externe 21:9 = 2,33 ; interne ≈ 1,1)
const ZOOM_FOLDED: Vector2 = Vector2.ONE
const ZOOM_UNFOLDED: Vector2 = Vector2(0.5, 0.5)
const TWEEN_SEC: float = 0.2

static func is_folded(window_size: Vector2i) -> bool:
	return window_size.y >= window_size.x * FOLDED_MIN_ASPECT

static func zoom_for(folded: bool) -> Vector2:
	return ZOOM_FOLDED if folded else ZOOM_UNFOLDED

# Visibilité et process_mode seulement : aucune reconstruction d'UI.
static func apply(folded: bool, ui_folded: CanvasLayer, ui_unfolded: CanvasLayer) -> void:
	ui_folded.visible = folded
	ui_folded.process_mode = Node.PROCESS_MODE_INHERIT if folded else Node.PROCESS_MODE_DISABLED
	ui_unfolded.visible = not folded
	ui_unfolded.process_mode = Node.PROCESS_MODE_DISABLED if folded else Node.PROCESS_MODE_INHERIT
