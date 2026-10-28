extends Node
# Racine : charge la partie, bascule plié / déplié (SOCLE §A3), affiche le Rapport de veillée (§A4).

const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const ClockS = preload("res://autoload/Clock.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const BA = preload("res://balance/balance_a.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const EquipmentS = preload("res://scripts/loot/equipment.gd")
const PurifS = preload("res://scripts/loot/purification.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")
const ForgeS = preload("res://scripts/loot/forge.gd")
const Dag = preload("res://scripts/offline_dag.gd")
const AssignS = preload("res://scripts/village/assignment.gd")

const DRAG_MIN_PX: float = 4.0 # en deçà, un lâcher est un appui : annulé (jalon 19) ; technique, PROPOSÉ

@onready var _world: Node2D = $World # village.gd
@onready var _camera: Camera2D = $Camera2D
@onready var _ui_folded: CanvasLayer = $UI_Folded
@onready var _ui_unfolded: CanvasLayer = $UI_Unfolded
@onready var _stick: Node2D = $UI_Folded/Stick # touch_stick.gd
@onready var _black: ColorRect = $Fondu/Noir

var _folded: bool = true
var _tween: Tween
var _fallback_player: Dictionary = {} # boot en erreur : XP en mémoire seulement, rien n'est sauvegardé
var _preview: Dictionary = {} # pièce en aperçu de purification, {} sinon
var _preview_place: String = ""
var _village_key: Vector2i = Vector2i(-1, -1) # (heure locale, joueur au village) du dernier show_village
var _drag: int = -1 # PNJ saisi sur la carte (déplié), -1 sinon
var _drag_from: Vector2

func _ready() -> void:
	var now: int = ClockS.now_utc()
	var r: Dictionary = SaveManager.start(now)
	var capture: String = _debug_args()
	_ui_unfolded.set_world_seed(0 if r.is_empty() else r["state"]["world_seed"]) # avant le premier _show : noms et aptitudes
	if r.is_empty(): # state reste vide : plus aucune sauvegarde
		_world.setup(0, {}, now, _player_state)
		for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
			layer.show_error("Sauvegarde illisible. Rien n'a été écrit.")
	else:
		_world.setup(r["state"]["world_seed"], r["state"]["village"], now, _player_state)
		_show(r)
		_auto_assign()
	var player: Node2D = _world.player() # player.gd
	player.set_equipment(_player_state()["equipment"])
	player.set_level(ProgressionS.combat_level(_player_state()))
	_ui_unfolded.set_forge_help_source(_forge_help)
	_show_player()
	var seg: Node2D = _world.segment() # segment.gd
	seg.xp_changed.connect(_show_player)
	seg.expedition_ended.connect(func(_reason: String) -> void:
		_show_player() # coffre rempli au retour (jalon 16)
		_sync())
	_stick.direction_changed.connect(player.set_move_dir)
	_stick.swiped.connect(player.dodge)
	_stick.was_reset.connect(player.on_input_reset)
	player.evacuation_started.connect(_stick.reset) # un doigt resté posé ne fait pas repartir le joueur depuis l'Âtre
	_ui_folded.get_node("Aptitudes").setup(player)
	player.teleported.connect(func() -> void: _set_camera_limits(_world.rect_at(player.position)))
	for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
		seg.expedition_changed.connect(layer.show_expedition)
		seg.leveled.connect(layer.show_level_up)
	_ui_unfolded.purify_requested.connect(_on_purify_requested)
	_ui_unfolded.purify_chosen.connect(_on_purify_chosen)
	_ui_unfolded.forge_requested.connect(_on_forge_requested)
	_ui_unfolded.cadence_chosen.connect(_on_village_set.bind("cadence"))
	_ui_unfolded.posture_chosen.connect(_on_village_set.bind("posture"))
	_ui_unfolded.post_chosen.connect(_on_post_chosen.bind("bouton"))
	_ui_unfolded.npc_freed.connect(_on_npc_freed)
	_show_forge_pending() # carte de craft laissée ouverte à la fermeture de l'appli
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
	if not _folded:
		_ui_unfolded.set_purify_reason(_purify_block_reason())
		_ui_unfolded.set_forge_enabled(_forge_block_reason)
	var key: Vector2i = Vector2i(_world.hour_at(ClockS.now_utc()), int(CombatS.in_village(player.position)))
	if key != _village_key: # heure locale ou entrée / sortie du village
		_show_village()

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
	_show_player()
	_world.refresh(r["state"]["village"], ClockS.now_utc())
	_show_village()

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
	_release_drag()
	_cancel_preview() # rien n'est consommé : le même tirage reviendra
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_camera, "zoom", FoldModeS.zoom_for(_folded), FoldModeS.TWEEN_SEC)
	_tween.tween_property(_camera, "position", camera_target(_folded, _world.player().position), FoldModeS.TWEEN_SEC)
	_auto_assign()
	_sync()

# Pliage, dépliage et fin d'expédition (jalon 13) : même écriture.
func _sync() -> void:
	var r: Dictionary = SaveManager.sync(ClockS.now_utc())
	if not r.is_empty():
		_show(r)

# Dictionnaire courant du joueur, relu à chaque appel : sync remplace SaveManager.state.
func _player_state() -> Dictionary:
	if not SaveManager.state.is_empty():
		return SaveManager.state["player"]
	if _fallback_player.is_empty():
		_fallback_player = ProgressionS.new_player()
	return _fallback_player

func _show_player() -> void:
	var p: Dictionary = _player_state()
	for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
		layer.show_player(p, ForgeS.ore(p))
	_ui_unfolded.show_perso(p, EquipmentS.player_stats(ProgressionS.combat_level(p), p["equipment"]))
	_ui_unfolded.show_forge(ForgeS.ore(p), p["cendre"])

# Purification (Volet F §1, déplié) : au village sans limite, au Brasero 2 par expédition ; jamais sans sauvegarde
# ni avec une carte ouverte.
func _can_purify() -> bool:
	return not SaveManager.state.is_empty() and _preview.is_empty() and _player_state()["forge_pending"] == null \
		and PurifS.has_shard(_player_state()) and _world.segment().purify_place(_world.player().position) != ""

# Raison affichée sous « Purifier un Éclat » grisé (jalon 17) ; vide exactement quand _can_purify est vrai.
func _purify_block_reason() -> String:
	if SaveManager.state.is_empty():
		return "Sauvegarde illisible. Rien n'a été écrit."
	var p: Dictionary = _player_state()
	var pos: Vector2 = _world.player().position
	var seg: Node2D = _world.segment() # segment.gd
	return EqText.purify_block_reason(CombatS.in_village(pos), seg.at_brazier(pos), seg.brazier_used(), p["shard_bag"].size(),
		p["forge_pending"] != null or not _preview.is_empty())

func _on_purify_requested() -> void:
	if not _can_purify():
		return
	var p: Dictionary = _player_state()
	_preview_place = _world.segment().purify_place(_world.player().position)
	_preview = PurifS.preview(SaveManager.state["world_seed"], p)
	_show_card(_preview, false)

# Carte commune à la purification et au craft : nouvelle pièce, pièce équipée, écart de stats.
func _show_card(piece: Dictionary, forged: bool) -> void:
	var p: Dictionary = _player_state()
	var level: int = ProgressionS.combat_level(p)
	var after: Array = p["equipment"].duplicate(true)
	after[piece["slot"]] = piece
	var before_st: Dictionary = EquipmentS.player_stats(level, p["equipment"])
	var after_st: Dictionary = EquipmentS.player_stats(level, after)
	_ui_unfolded.show_preview(piece, p["equipment"][piece["slot"]], EqText.diff_line(before_st, after_st), forged, EqText.compare(before_st, after_st))

# Équiper / Jeter : la carte de craft passe avant l'aperçu de purification (les deux ne coexistent jamais).
func _on_purify_chosen(equip: bool) -> void:
	var p: Dictionary = _player_state()
	if p["forge_pending"] != null:
		_log_json("[FORGE] ", ForgeS.choose(p, equip))
		_after_choice(equip)
		return
	if _preview.is_empty():
		return
	_log_json("[EQUIPEMENT] ", PurifS.commit(p, _preview, equip, _preview_place))
	_world.segment().on_purified(_preview_place)
	_after_choice(equip)

func _after_choice(equip: bool) -> void:
	if equip:
		_world.player().set_equipment(_player_state()["equipment"])
	_cancel_preview()
	_show_player()
	_sync()

func _cancel_preview() -> void:
	_preview = {}
	_preview_place = ""
	_ui_unfolded.hide_preview()
	_show_forge_pending()

func _show_forge_pending() -> void:
	var pending: Variant = _player_state()["forge_pending"]
	if pending != null:
		_show_card(pending, true)

# Forge du village (Volet F §2, déplié) : dans le rayon de l'Âtre, jamais sans sauvegarde ni avec une carte ouverte.
func _can_forge(cendre: bool) -> bool:
	return not SaveManager.state.is_empty() and _preview.is_empty() 		and ForgeS.can_craft(_player_state(), cendre, CombatS.in_village(_world.player().position))

# Raison affichée sous les boutons grisés (jalon 16 bis) ; vide exactement quand _can_forge est vrai.
func _forge_block_reason(cendre: bool) -> String:
	if SaveManager.state.is_empty():
		return "Sauvegarde illisible. Rien n'a été écrit."
	var p: Dictionary = _player_state()
	return EqText.forge_block_reason(CombatS.in_village(_world.player().position), ForgeS.ore(p), p["cendre"], cendre,
		p["forge_pending"] != null or not _preview.is_empty())

func _forge_help(cendre: bool) -> PackedStringArray:
	var p: Dictionary = _player_state()
	var isolat: int = 0 if SaveManager.state.is_empty() else SaveManager.state["village"].get("isolat", 0)
	return EqText.forge_help(cendre, ForgeS.piece_level(p, isolat), ForgeS.xp_preview(p, cendre, isolat))

func _on_forge_requested(slot: int, cendre: bool) -> void:
	if not _can_forge(cendre):
		return
	var p: Dictionary = _player_state()
	var r: Dictionary = ForgeS.craft(SaveManager.state["world_seed"], p, slot, cendre, SaveManager.state["village"].get("isolat", 0))
	_log_json("[FORGE] ", r["log"])
	if r["gain"]["level_after"] > r["gain"]["level_before"]:
		_log_json("[FORGE] ", {"event": "niveau", "vocation": "FORGERON", "niveau": r["gain"]["level_after"], "xp": p["voc_xp"]["FORGERON"]})
		for layer in [_ui_folded, _ui_unfolded]: # ui_layer.gd
			layer.show_level_up("FORGERON", r["gain"]["level_after"])
	_show_player()
	_show_forge_pending()
	_sync() # la pièce en attente est écrite : quitter sur la carte la fait revenir

# Onglets PNJ et Village (jalon 18) : lecture partout, réglages au village seulement, jamais sans sauvegarde.
func _village_block_reason() -> String:
	if SaveManager.state.is_empty():
		return "Sauvegarde illisible"
	return "" if CombatS.in_village(_world.player().position) else "Réglages au village seulement"

func _show_village() -> void:
	var now: int = ClockS.now_utc()
	var in_village: bool = CombatS.in_village(_world.player().position)
	_village_key = Vector2i(_world.hour_at(now), int(in_village))
	var reason: String = _village_block_reason()
	var village: Dictionary = {} if SaveManager.state.is_empty() else SaveManager.state["village"]
	_ui_unfolded.show_village(village, _village_key.x, reason == "", reason)

# Cadence ou posture : effet au prochain tick (clé _next, OfflineDag.set_next), écrit tout de suite.
# id : index du PNJ (cadence) ou clé de la boutique (posture).
func _on_village_set(id: Variant, value: String, field: String) -> void:
	if _village_block_reason() != "":
		return
	var village: Dictionary = SaveManager.state["village"]
	var cadence: bool = field == "cadence"
	Dag.set_next(village["npcs"][id] if cadence else village["shops"][id], field, value)
	_log_json("[VILLAGE] ", {"event": "reglage", ("pnj" if cadence else "boutique"): id, "valeur": value, "effet": "demain"})
	_sync()
	_show_village()

# Postes (jalon 19) : auto-assignation en session seulement (AUTO_ASSIGN_SESSION_ONLY), au lancement et à chaque
# bascule ; effet au prochain tick. Au lancement, l'attente est écrite à la bascule suivante (même calcul si l'appli est tuée).
func _auto_assign() -> void:
	if SaveManager.state.is_empty():
		return
	var village: Dictionary = SaveManager.state["village"]
	var today: int = ClockS.day_index(ClockS.now_utc(), village["tz_offset_sec"])
	var moves: Array = AssignS.auto_assign(village, SaveManager.state["world_seed"], today, village.get("atre_lvl", 1))
	for m: Dictionary in moves:
		_log_json("[VILLAGE] ", {"event": "poste", "pnj": m["pnj"], "de": m["de"], "vers": m["vers"], "kind": "move", "source": "auto"})
	if not moves.is_empty():
		_show_village()

# Saisir-déposer sur la carte (Vision d'architecte, SOCLE §A3) : déplié, au village, doigt 0 seulement.
# L'émulation tactile à la souris couvre le PC. Le PNJ retourne à son poste du jour : le changement vaut demain.
# Le posé arrive ici : un posé sur la fenêtre est consommé par l'UI et ne saisit rien.
func _unhandled_input(event: InputEvent) -> void:
	if _folded or not (event is InputEventScreenTouch and event.pressed) or event.index != 0 or _village_block_reason() != "":
		return
	_drag_from = _to_world(event.position)
	_drag = _world.npc_at(_drag_from)
	if _drag >= 0:
		get_viewport().set_input_as_handled()

# Glissé et lâcher du PNJ saisi, lus avant l'UI (comme touch_stick.gd) : passer sur la fenêtre ne les perd pas.
func _input(event: InputEvent) -> void:
	if _drag < 0 or not (event is InputEventScreenDrag or (event is InputEventScreenTouch and not event.pressed)) or event.index != 0:
		return
	get_viewport().set_input_as_handled()
	var pos: Vector2 = _to_world(event.position)
	if event is InputEventScreenDrag:
		_world.drag_npc(_drag, pos)
		return
	var i: int = _drag
	_release_drag()
	var post: String = VL.SITE_POST.get(_world.site_at(pos), "")
	if pos.distance_to(_drag_from) >= DRAG_MIN_PX and post != "":
		_on_post_chosen(i, post, "carte")

func _to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen

func _release_drag() -> void:
	if _drag >= 0:
		_world.release_npc(_drag)
	_drag = -1

# Bouton de poste ou lâcher sur un bâtiment : verrouille ; poste plein = échange (Assignment.move).
func _on_post_chosen(index: int, post: String, source: String) -> void:
	if _village_block_reason() != "":
		return
	var village: Dictionary = SaveManager.state["village"]
	var from: String = AssignS.effective_post(village["npcs"][index])
	var r: Dictionary = AssignS.move(village, SaveManager.state["world_seed"], index, post, village.get("atre_lvl", 1))
	_log_json("[VILLAGE] ", {"event": "poste", "pnj": index, "de": from, "vers": post, "kind": r["kind"], "source": source})
	_ui_unfolded.show_move(index, post, r)
	_sync()
	_show_village()

# « Libérer » : rend le PNJ à l'auto-assignation ; l'attente reste en place.
func _on_npc_freed(index: int) -> void:
	if _village_block_reason() != "":
		return
	SaveManager.state["village"]["npcs"][index]["locked"] = false
	_sync()
	_show_village()

# Événements seulement ; build debug seulement.
func _log_json(tag: String, d: Dictionary) -> void:
	if OS.is_debug_build():
		print(tag + JSON.stringify(d))
