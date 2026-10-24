extends Node
# Racine : charge la partie, bascule plié / déplié (SOCLE §A3), affiche le Rapport de veillée (§A4).

const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const ClockS = preload("res://autoload/Clock.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const BA = preload("res://balance/balance_a.gd")
const CombatS = preload("res://scripts/combat/combat.gd")

@onready var _world: Node2D = $World # village.gd
@onready var _camera: Camera2D = $Camera2D
@onready var _ui_folded: CanvasLayer = $UI_Folded
@onready var _ui_unfolded: CanvasLayer = $UI_Unfolded
@onready var _stick: Node2D = $UI_Folded/Stick # touch_stick.gd
@onready var _black: ColorRect = $Fondu/Noir

var _folded: bool = true
var _tween: Tween

func _ready() -> void:
	var now: int = ClockS.now_utc()
	var r: Dictionary = SaveManager.start(now)
	var capture: String = _debug_args()
	if r.is_empty(): # state reste vide : plus aucune sauvegarde
		_world.setup(0, {}, now)
		for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
			layer.show_error("Sauvegarde illisible. Rien n'a été écrit.")
	else:
		_world.setup(r["state"]["world_seed"], r["state"]["village"], now)
		_show(r)
	var player: Node2D = _world.player() # player.gd
	_stick.direction_changed.connect(player.set_move_dir)
	_stick.swiped.connect(player.dodge)
	_stick.was_reset.connect(player.on_input_reset)
	player.evacuation_started.connect(_stick.reset) # un doigt resté posé ne fait pas repartir le joueur depuis l'Âtre
	player.teleported.connect(func() -> void: _set_camera_limits(_world.rect_at(player.position)))
	for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
		_world.segment().expedition_changed.connect(layer.show_expedition)
	_black.color = CombatS.EVAC_COLOR
	_black.color.a = 0.0
	_set_camera_limits(VL.GROUND_RECT)
	_folded = FoldModeS.is_folded(get_window().size)
	var s: int = _apply_scale(_folded)
	FoldModeS.apply(_folded, _ui_folded, _ui_unfolded)
	_camera.zoom = FoldModeS.zoom_for(_folded)
	_camera.position = camera_target(_folded, player.position)
	_apply_safe_area(s)
	get_viewport().size_changed.connect(_on_size_changed)
	SaveManager.synced.connect(_show)
	_log_measure("ready", _folded)
	if capture != "":
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(capture)
		get_tree().quit()

# La caméra suit sa cible au pixel près (arrondi : pas de scintillement), sauf pendant le Tween de bascule.
# Le noir du fondu d'évacuation est appliqué plié et déplié.
func _process(_delta: float) -> void:
	var player: Node2D = _world.player() # player.gd
	if _tween == null or not _tween.is_running():
		_camera.position = camera_target(_folded, player.position)
	_black.color.a = player.fade_alpha()

# Plié : sur le joueur. Déplié hors du rayon de l'Âtre : le combat continue, caméra sur le joueur (n°25).
# Déplié dans le rayon : Vision d'architecte centrée sur l'Âtre, tout le rayon visible.
static func camera_target(folded: bool, player_pos: Vector2) -> Vector2:
	if folded or (BA.UNFOLDED_COMBAT_LOCK_CAMERA_ON_PLAYER and not CombatS.in_village(player_pos)):
		return player_pos.round()
	return Vector2.ZERO

# Bords du lieu (sol du village ou nœud de Brume) : la caméra ne montre jamais de vide. Appelé sous le noir des fondus.
func _set_camera_limits(r: Rect2i) -> void:
	var half: int = VL.CELL / 2
	_camera.limit_left = r.position.x * VL.CELL - half
	_camera.limit_top = r.position.y * VL.CELL - half
	_camera.limit_right = r.end.x * VL.CELL - half
	_camera.limit_bottom = r.end.y * VL.CELL - half

# Vérification sur PC (build debug seulement), après « -- » : --hour=H force l'heure locale (rendu et ancres),
# --capture=chemin.png enregistre le viewport au bout d'une seconde puis quitte. Rend le chemin de capture.
func _debug_args() -> String:
	var capture: String = ""
	if not OS.is_debug_build():
		return capture
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--hour="):
			_world.hour_override = a.get_slice("=", 1).to_int()
		elif a.begins_with("--capture="):
			capture = a.get_slice("=", 1)
	return capture

# Sonde du jalon 6 (build debug seulement) : mesures écran du Fold, lues par adb logcat -s godot.
# folded : mode détecté pour cet événement (calculé avant le return anticipé de _on_size_changed).
func _log_measure(event: String, folded: bool) -> void:
	if not OS.is_debug_build():
		return
	var window: Vector2i = get_window().size
	var screen: Vector2i = DisplayServer.screen_get_size()
	var visible: Vector2i = Vector2i(get_viewport().get_visible_rect().size.round())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var d: Dictionary = {"event": event, "folded": folded, "window": [window.x, window.y], "screen": [screen.x, screen.y],
		"scale": FoldModeS.ui_scale(window, folded), "content": [get_window().content_scale_size.x, get_window().content_scale_size.y], "visible": [visible.x, visible.y],
		"safe": [safe.position.x, safe.position.y, safe.size.x, safe.size.y], "dpi": DisplayServer.screen_get_dpi(),
		"screen_scale": DisplayServer.screen_get_scale(), "refresh": DisplayServer.screen_get_refresh_rate()}
	if event == "ready":
		d["user_dir"] = OS.get_user_data_dir()
	print("[MESURE] " + JSON.stringify(d))

func _show(r: Dictionary) -> void:
	for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
		layer.show_gold(r["state"]["village"]["player_gold"])
		layer.show_report(r)
	_world.refresh(r["state"]["village"], ClockS.now_utc())

# Échelle d'interface choisie ici (FoldMode.ui_scale), zone = fenêtre / échelle : pas de bandes noires.
# Affecter content_scale_size relance size_changed : la garde != empêche la boucle.
# deferred : depuis size_changed, l'affectation directe est réentrante dans la mise à jour de la fenêtre et
# laisse un rendu à l'échelle 5,6 avec bandes (mesuré au jalon 7 sur le Fold 8) ; on l'affecte après.
func _apply_scale(folded: bool, deferred: bool = false) -> int:
	var s: int = FoldModeS.ui_scale(get_window().size, folded)
	var c: Vector2i = FoldModeS.content_size(get_window().size, s)
	if get_window().content_scale_size != c:
		if deferred:
			get_window().set_deferred("content_scale_size", c)
		else:
			get_window().content_scale_size = c
	return s

func _apply_safe_area(s: int) -> void:
	for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
		layer.apply_safe_area(get_window().size, s)

# Plusieurs size_changed pendant un pliage = une seule bascule.
func _on_size_changed() -> void:
	var folded: bool = FoldModeS.is_folded(get_window().size)
	_apply_safe_area(_apply_scale(folded, true))
	_log_measure("size_changed", folded)
	if folded == _folded:
		return
	_folded = folded
	FoldModeS.apply(_folded, _ui_folded, _ui_unfolded)
	_stick.reset()
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_camera, "zoom", FoldModeS.zoom_for(_folded), FoldModeS.TWEEN_SEC)
	_tween.tween_property(_camera, "position", camera_target(_folded, _world.player().position), FoldModeS.TWEEN_SEC)
	var r: Dictionary = SaveManager.sync(ClockS.now_utc())
	if not r.is_empty():
		_show(r)
