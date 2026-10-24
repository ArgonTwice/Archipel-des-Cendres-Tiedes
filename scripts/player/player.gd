extends Node2D
# Porte-Braise (SOCLE §A3) : marche dans la direction du joystick, esquive par balayage, bute sur les cellules pleines.
# _process et non _physics_process : l'écran du Fold rafraîchit au-delà de 60 Hz, sans interpolation physique ;
# PlayerMotion.move reste exact quel que soit delta. Aucune écriture dans SaveManager.state, position non sauvegardée.

const PM = preload("res://scripts/player/player_motion.gd")
const BA = preload("res://balance/balance_a.gd")
const NpcS = preload("res://scripts/village/npc.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const VL = preload("res://scripts/village/village_layout.gd")

signal evacuation_started
signal teleported # sous le noir, mort ou passage

enum State { IDLE, MOVE, DODGE }

const IFRAME_ALPHA: float = 0.5 # repère visuel de DODGE_IFRAME_SEC ; à valider (jalon 9)
# Miroir seulement au-delà de 30° de la verticale : sur un glisser vertical, le pouce oscille de 1 à 2 px et
# retournait le sprite à chaque glissé (W1 « vibrant » sur le Fold 8). À valider (jalon 9).
const FLIP_MIN_X: float = 0.5

var state: int = State.IDLE # IDLE = « à l'arrêt » : accroche de la récolte
var _sprite: Sprite2D
var _solid: Dictionary = {}
var _dir: Vector2 = Vector2.ZERO
var _clock: float = 0.0 # somme des delta
var _dodge_dir: Vector2 = Vector2.ZERO
var _dodge_t: float = -1.0 # -1 = pas d'esquive en cours
var _dodge_start: float = -1.0 # instant de départ de la dernière esquive
var _dodge_from: Vector2
var level: int = 1 # niveau de Combattant : aucune vocation dans l'état, niveau de départ
var max_hp: int = 0
var hp: int = 0
var atk: int = 0
var def: int = 0
var _spawn: Vector2
var _last_strike: float = -1.0 # -1 = aucun coup encore
var _hit_t: float = 0.0
var _bounds: Rect2i = VL.GROUND_RECT
var _home_solid: Dictionary = {}
var _home_bounds: Rect2i = VL.GROUND_RECT
var _fade_t: float = -1.0 # -1 = aucun fondu (évacuation ou passage)
var _fade_death: bool = false
var _fade_moved: bool = false # déplacement sous le noir déjà fait pendant ce fondu
var _fade_target: Vector2
var _fade_solid: Dictionary = {}
var _fade_bounds: Rect2i

# Nœuds lus ici et non en @onready : setup peut précéder _ready (simulateur headless).
func setup(pos: Vector2, texture: Texture2D, shadow: Texture2D, solid: Dictionary) -> void:
	_sprite = $Sprite
	_sprite.texture = texture
	$Ombre.texture = shadow
	position = pos
	_solid = solid
	_bounds = VL.GROUND_RECT
	_home_solid = solid
	_home_bounds = VL.GROUND_RECT
	_spawn = VL.cell_center(VL.PLAYER_SPAWN_CELL)
	var stats: Dictionary = CombatS.player_stats(level, CombatS.starting_weapon_atk())
	max_hp = stats["hp"]
	atk = stats["atk"]
	def = stats["def"]
	_set_hp(max_hp)

func set_move_dir(dir: Vector2) -> void:
	var was_moving: bool = _dir != Vector2.ZERO
	_dir = dir
	if absf(dir.x) >= FLIP_MIN_X and _sprite != null:
		_sprite.flip_h = dir.x < 0.0
	if was_moving != (dir != Vector2.ZERO) and _dodge_t < 0.0:
		_log("marche" if dir != Vector2.ZERO else "arret")

func dodge(dir: Vector2) -> bool:
	if in_fade() or _dodge_t >= 0.0 or not PM.can_dodge(_clock, _dodge_start):
		_log("esquive_refusee")
		return false
	_dodge_dir = dir
	_dodge_t = 0.0
	_dodge_start = _clock
	_dodge_from = position
	return true

# Auto-attaque à l'arrêt et en marche (SOCLE §A3 modifié par Antho le 24/10), jamais en esquive ni en fondu.
func can_strike() -> bool:
	return not in_fade() and state != State.DODGE and (_last_strike < 0.0 or _clock - _last_strike >= CombatS.attack_period())

func strike(target_pos: Vector2) -> void:
	_last_strike = _clock
	if state == State.IDLE and target_pos.x != position.x and _sprite != null: # en marche, le sprite garde le sens de la marche
		_sprite.flip_h = target_pos.x < position.x

func is_invulnerable() -> bool:
	return _dodge_t >= 0.0 and PM.in_iframes(_dodge_t)

# Faux si les i-frames ou un fondu annulent le coup. À 0 PV : évacuation (Engourdi reporté).
func take_hit(dmg: int) -> bool:
	if in_fade() or is_invulnerable():
		return false
	_set_hp(hp - dmg)
	_hit_t = CombatS.PLAYER_HIT_SEC
	if _sprite != null:
		_sprite.modulate = CombatS.PLAYER_HIT_MODULATE
	if hp <= 0:
		if OS.is_debug_build():
			print("[COMBAT] " + JSON.stringify({"event": "mort_joueur", "pos": _xy(position)}))
		_start_fade(true, _spawn, _home_solid, _home_bounds)
		evacuation_started.emit()
	return true

# Passage entre le village et les nœuds : même fondu que l'évacuation, sans soin. Le doigt tenu n'est pas oublié :
# le joueur repart dans la même direction à la fin du fondu.
func travel(target: Vector2, solid: Dictionary, bounds: Rect2i) -> void:
	_start_fade(false, target, solid, bounds)

func _start_fade(death: bool, target: Vector2, solid: Dictionary, bounds: Rect2i) -> void:
	_fade_t = 0.0
	_fade_death = death
	_fade_moved = false
	_fade_target = target
	_fade_solid = solid
	_fade_bounds = bounds
	_dodge_t = -1.0

# Fondu en cours (mort ou passage) : invulnérable, ni marche, ni esquive, ni coup.
func in_fade() -> bool:
	return _fade_t >= 0.0

# Évacuation = fondu de mort seulement.
func is_evacuating() -> bool:
	return in_fade() and _fade_death

func fade_alpha() -> float:
	return CombatS.evac_alpha(_fade_t) if in_fade() else 0.0

func bounds() -> Rect2i:
	return _bounds

func on_input_reset() -> void:
	_log("reset")

func _process(delta: float) -> void:
	_clock += delta
	var motion: Vector2 = Vector2.ZERO
	if in_fade():
		_fade_t += delta
		if not _fade_moved and _fade_t >= CombatS.EVAC_FADE_OUT_SEC: # écran noir
			_fade_moved = true
			position = _fade_target
			_solid = _fade_solid
			_bounds = _fade_bounds
			if _fade_death:
				_set_hp(max_hp)
				_last_strike = -1.0
			_log("retour" if _fade_death else "passage")
			teleported.emit()
		if _fade_t >= CombatS.evac_duration():
			_fade_t = -1.0
	elif _dodge_t >= 0.0:
		motion = _dodge_dir * (PM.dodge_progress(_dodge_t + delta) - PM.dodge_progress(_dodge_t))
		_dodge_t += delta
	else:
		motion = _dir * BA.PLAYER_BASE_MSPD * delta
	position = PM.move(position, motion, _solid, _bounds)
	if _dodge_t >= BA.DODGE_DURATION_SEC:
		_dodge_t = -1.0
		_log("esquive", {"de": _xy(_dodge_from), "a": _xy(position), "dist": snappedf(_dodge_from.distance_to(position), 0.01)})
	if in_fade():
		state = State.IDLE
	else:
		state = State.DODGE if _dodge_t >= 0.0 else (State.MOVE if _dir != Vector2.ZERO else State.IDLE)
	if _sprite != null:
		_sprite.position.y = NpcS.bob_offset(_clock, state == State.MOVE)
		modulate.a = IFRAME_ALPHA if _dodge_t >= 0.0 and PM.in_iframes(_dodge_t) else 1.0
		if _hit_t > 0.0:
			_hit_t -= delta
			if _hit_t <= 0.0:
				_sprite.modulate = Color.WHITE
	if CombatS.in_safe_zone(position): # le village et le Brasero soignent. PROPOSÉ, à valider (jalon 11) pour le Brasero
		_set_hp(max_hp)

func _set_hp(value: int) -> void:
	if value != hp:
		hp = value
		queue_redraw()

func _draw() -> void:
	if hp >= max_hp:
		return
	var bar: Vector2i = CombatS.BAR_SIZE
	var origin: Vector2 = Vector2(-bar.x / 2.0, CombatS.BAR_Y)
	draw_rect(Rect2(origin, bar), CombatS.BAR_BG, true, -1.0, false)
	draw_rect(Rect2(origin, Vector2(CombatS.bar_fill_px(hp, max_hp), bar.y)), CombatS.BAR_PLAYER, true, -1.0, false)

# Transitions seulement, jamais à chaque image ; build debug seulement.
func _log(event: String, extra: Dictionary = {}) -> void:
	if not OS.is_debug_build():
		return
	var d: Dictionary = {"event": event, "pos": _xy(position)}
	d.merge(extra)
	print("[JOUEUR] " + JSON.stringify(d))

static func _xy(p: Vector2) -> Array:
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01)]
