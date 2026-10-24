extends Node2D
# Porte-Braise (SOCLE §A3) : marche dans la direction du joystick, esquive par balayage, bute sur les cellules pleines.
# _process et non _physics_process : l'écran du Fold rafraîchit au-delà de 60 Hz, sans interpolation physique ;
# PlayerMotion.move reste exact quel que soit delta. Aucune écriture dans SaveManager.state, position non sauvegardée.

const PM = preload("res://scripts/player/player_motion.gd")
const BA = preload("res://balance/balance_a.gd")
const NpcS = preload("res://scripts/village/npc.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const VL = preload("res://scripts/village/village_layout.gd")

enum State { IDLE, MOVE, DODGE }

const IFRAME_ALPHA: float = 0.5 # repère visuel de DODGE_IFRAME_SEC ; à valider (jalon 9)
# Miroir seulement au-delà de 30° de la verticale : sur un glisser vertical, le pouce oscille de 1 à 2 px et
# retournait le sprite à chaque glissé (W1 « vibrant » sur le Fold 8). À valider (jalon 9).
const FLIP_MIN_X: float = 0.5

var state: int = State.IDLE # IDLE = « à l'arrêt » : accroche de l'auto-attaque du jalon combat
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

# Nœuds lus ici et non en @onready : setup peut précéder _ready (simulateur headless).
func setup(pos: Vector2, texture: Texture2D, shadow: Texture2D, solid: Dictionary) -> void:
	_sprite = $Sprite
	_sprite.texture = texture
	$Ombre.texture = shadow
	position = pos
	_solid = solid
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
	if _dodge_t >= 0.0 or not PM.can_dodge(_clock, _dodge_start):
		_log("esquive_refusee")
		return false
	_dodge_dir = dir
	_dodge_t = 0.0
	_dodge_start = _clock
	_dodge_from = position
	return true

# Auto-attaque à l'arrêt seulement (IDLE), cadence continue.
func can_strike() -> bool:
	return state == State.IDLE and (_last_strike < 0.0 or _clock - _last_strike >= CombatS.attack_period())

func strike(target_pos: Vector2) -> void:
	_last_strike = _clock
	if target_pos.x != position.x and _sprite != null:
		_sprite.flip_h = target_pos.x < position.x

func is_invulnerable() -> bool:
	return _dodge_t >= 0.0 and PM.in_iframes(_dodge_t)

# Faux si les i-frames annulent le coup. À 0 PV : retour devant l'Âtre, PV pleins (Engourdi reporté).
func take_hit(dmg: int) -> bool:
	if is_invulnerable():
		return false
	_set_hp(hp - dmg)
	_hit_t = CombatS.PLAYER_HIT_SEC
	if _sprite != null:
		_sprite.modulate = CombatS.PLAYER_HIT_MODULATE
	if hp <= 0:
		if OS.is_debug_build():
			print("[COMBAT] " + JSON.stringify({"event": "mort_joueur", "pos": _xy(position)}))
		position = _spawn
		_set_hp(max_hp)
		_dodge_t = -1.0
		_last_strike = -1.0
	return true

func on_input_reset() -> void:
	_log("reset")

func _process(delta: float) -> void:
	_clock += delta
	var motion: Vector2
	if _dodge_t >= 0.0:
		motion = _dodge_dir * (PM.dodge_progress(_dodge_t + delta) - PM.dodge_progress(_dodge_t))
		_dodge_t += delta
	else:
		motion = _dir * BA.PLAYER_BASE_MSPD * delta
	position = PM.move(position, motion, _solid)
	if _dodge_t >= BA.DODGE_DURATION_SEC:
		_dodge_t = -1.0
		_log("esquive", {"de": _xy(_dodge_from), "a": _xy(position), "dist": snappedf(_dodge_from.distance_to(position), 0.01)})
	state = State.DODGE if _dodge_t >= 0.0 else (State.MOVE if _dir != Vector2.ZERO else State.IDLE)
	if _sprite != null:
		_sprite.position.y = NpcS.bob_offset(_clock, state == State.MOVE)
		modulate.a = IFRAME_ALPHA if _dodge_t >= 0.0 and PM.in_iframes(_dodge_t) else 1.0
		if _hit_t > 0.0:
			_hit_t -= delta
			if _hit_t <= 0.0:
				_sprite.modulate = Color.WHITE
	if CombatS.in_village(position): # le village soigne
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
