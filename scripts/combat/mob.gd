extends Node2D
# Monstre de la lisière (SOCLE §A3) : repère, approche en ligne droite, télégraphe puis frappe. Aucune IA de chemin.
# Piloté par lisiere.gd (step), jamais par son propre _process : l'ordre des opérations est celui du jumeau Python.

const BA = preload("res://balance/balance_a.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const PM = preload("res://scripts/player/player_motion.gd")
const PlayerS = preload("res://scripts/player/player.gd")
const VL = preload("res://scripts/village/village_layout.gd")

var index: int = 0
var home: Vector2
var alive: bool = true
var chasing: bool = false
var hp: int = 0
var max_hp: int = 0
var atk: int = 0
var def: int = 0
var dead_t: float = 0.0 # minuteur de mort, tenu par lisiere.gd
var _sprite: Sprite2D
var _solid: Dictionary = {}
var _bounds: Rect2i = VL.GROUND_RECT
var _t: float = 0.0
var _windup_t: float = -1.0 # -1 = pas de télégraphe
var _last_attack: float = -1.0 # début du télégraphe précédent, -1 = aucun
var _flash_t: float = 0.0

# Nœuds lus ici : setup peut précéder _ready (simulateur headless).
func setup(home_pos: Vector2, texture: Texture2D, shadow: Texture2D, solid: Dictionary, stats: Dictionary, bounds: Rect2i = VL.GROUND_RECT) -> void:
	_sprite = $Sprite
	_sprite.texture = texture
	$Ombre.texture = shadow
	_solid = solid
	_bounds = bounds
	home = home_pos
	max_hp = stats["hp"]
	atk = stats["atk"]
	def = stats["def"]
	respawn()

# Rend vrai quand un coup touche le joueur (fin de télégraphe, cible à portée).
func step(delta: float, target: Vector2, target_ok: bool) -> bool:
	_t += delta
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			modulate.a = 1.0
	var dist: float = position.distance_to(target)
	if _windup_t >= 0.0:
		_windup_t += delta
		if _windup_t >= BA.MOB_TELEGRAPH_DURATION_SEC:
			_windup_t = -1.0
			_sprite.modulate = Color.WHITE
			if target_ok and dist <= BA.MOB_MELEE_RANGE_PX:
				return true
			_log("rate", {"source": index})
		return false
	var was: bool = chasing
	chasing = CombatS.mob_chasing(chasing, dist, target_ok)
	if chasing != was:
		_log("poursuite" if chasing else "abandon", {"index": index})
	if chasing:
		if dist <= BA.MOB_MELEE_RANGE_PX:
			if _last_attack < 0.0 or _t - _last_attack >= CombatS.mob_attack_period():
				_windup_t = 0.0
				_last_attack = _t
				_sprite.modulate = CombatS.WINDUP_MODULATE
		else:
			_advance(target, delta)
	elif position != home:
		_advance(home, delta)
		if position.distance_to(home) < 1.0:
			position = home
			_set_hp(max_hp)
	return false

# Rend vrai si le coup tue.
func take_hit(dmg: int) -> bool:
	_set_hp(hp - dmg)
	modulate.a = CombatS.MOB_HIT_ALPHA
	_flash_t = CombatS.MOB_HIT_SEC
	if hp > 0:
		return false
	alive = false
	visible = false
	chasing = false
	_windup_t = -1.0
	_sprite.modulate = Color.WHITE
	return true

func respawn() -> void:
	position = home
	alive = true
	visible = true
	chasing = false
	dead_t = 0.0
	_t = 0.0
	_windup_t = -1.0
	_last_attack = -1.0
	_flash_t = 0.0
	modulate.a = 1.0
	_sprite.modulate = Color.WHITE
	_set_hp(max_hp)

func _advance(target: Vector2, delta: float) -> void:
	var dir: Vector2 = (target - position).normalized()
	if absf(dir.x) >= PlayerS.FLIP_MIN_X:
		_sprite.flip_h = dir.x < 0.0
	position = PM.move(position, dir * BA.MOB_BASE_MSPD * delta, _solid, _bounds)

func _set_hp(value: int) -> void:
	if value != hp:
		hp = value
		queue_redraw()

func _draw() -> void:
	if not alive or hp >= max_hp:
		return
	var bar: Vector2i = CombatS.BAR_SIZE
	var origin: Vector2 = Vector2(-bar.x / 2.0, CombatS.BAR_Y)
	draw_rect(Rect2(origin, bar), CombatS.BAR_BG, true, -1.0, false)
	draw_rect(Rect2(origin, Vector2(CombatS.bar_fill_px(hp, max_hp), bar.y)), CombatS.BAR_MOB, true, -1.0, false)

# Événements seulement ; build debug seulement.
func _log(event: String, extra: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	var d: Dictionary = {"event": event}
	d.merge(extra)
	print("[COMBAT] " + JSON.stringify(d))
