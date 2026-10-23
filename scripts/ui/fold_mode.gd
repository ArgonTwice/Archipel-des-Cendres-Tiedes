class_name FoldMode
extends RefCounted
# Plié / déplié (SOCLE §A3) : double CanvasLayer préchargé, bascule de visibilité + Tween de zoom caméra.
# Constantes techniques UI, aucune valeur d'équilibrage.
# Mesures Fold 8 (jalon 6) : plié 1248 x 1972 -> x6 ; déplié 1848 x 2448 -> x7 sur la base 180 x 320, d'où une UI
# 17 % plus grosse et un zoom 0,5 à 3,5 px. Godot calcule aussi la zone visible en fractionnaire (202 x 320) puis
# l'affiche à l'échelle entière : bandes noires. Correctif : l'échelle est choisie ici, puis
# Window.content_scale_size = fenêtre / échelle ; Godot retombe exactement dessus (window.cpp :
# screen_scale = floor(screen / viewport)). Reste < 1 échelle, centré. Plié 208 x 328 et déplié 308 x 408, x6.

const FOLDED_MIN_ASPECT: float = 1.45 # Fold 8 mesuré : plié 1,58 / déplié 1,325, 1,45 ≈ milieu géométrique ; Fold 7 : 2,33 / 1,11
# Zone minimale en déplié : échelle 6 sur le Fold 8 (1848 / 240 = 7, 2448 / 360 = 6) comme sur le Fold 7 (1968 x 2184 -> 8 et 6).
const UNFOLDED_MIN_SIZE: Vector2i = Vector2i(240, 360)
const ZOOM_FOLDED: Vector2 = Vector2.ONE
const ZOOM_UNFOLDED: Vector2 = Vector2(0.5, 0.5)
const TWEEN_SEC: float = 0.2

static func is_folded(window_size: Vector2i) -> bool:
	return window_size.y >= window_size.x * FOLDED_MIN_ASPECT

static func zoom_for(folded: bool) -> Vector2:
	return ZOOM_FOLDED if folded else ZOOM_UNFOLDED

static func base_size() -> Vector2i:
	return Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

# Échelle entière du stretch (scale_mode integer).
static func integer_scale(window_size: Vector2i, base: Vector2i) -> int:
	return maxi(1, mini(window_size.x / base.x, window_size.y / base.y))

static func ui_scale(window_size: Vector2i, folded: bool) -> int:
	return integer_scale(window_size, base_size() if folded else UNFOLDED_MIN_SIZE)

static func content_size(window_size: Vector2i, scale: int) -> Vector2i:
	return Vector2i(window_size.x / scale, window_size.y / scale)

# [gauche, haut, droite, bas] en pixels de viewport. La marge noire centrée est déjà hors du viewport :
# on ne la compte pas deux fois (défaut n°4 du jalon 6).
static func safe_margins(window_size: Vector2i, scale: int, safe: Rect2i) -> PackedInt32Array:
	var screen: Vector2i = content_size(window_size, scale) * scale
	var off: Vector2i = Vector2i(roundi((window_size.x - screen.x) / 2.0), roundi((window_size.y - screen.y) / 2.0))
	return PackedInt32Array([
		maxi(0, ceili((safe.position.x - off.x) / float(scale))),
		maxi(0, ceili((safe.position.y - off.y) / float(scale))),
		maxi(0, ceili((off.x + screen.x - safe.end.x) / float(scale))),
		maxi(0, ceili((off.y + screen.y - safe.end.y) / float(scale)))])

# Visibilité et process_mode seulement : aucune reconstruction d'UI.
static func apply(folded: bool, ui_folded: CanvasLayer, ui_unfolded: CanvasLayer) -> void:
	ui_folded.visible = folded
	ui_folded.process_mode = Node.PROCESS_MODE_INHERIT if folded else Node.PROCESS_MODE_DISABLED
	ui_unfolded.visible = not folded
	ui_unfolded.process_mode = Node.PROCESS_MODE_DISABLED if folded else Node.PROCESS_MODE_INHERIT
