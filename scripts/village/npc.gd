extends Node2D
# PNJ du village (rendu seul) : marche en ligne droite vers son ancre quand elle change, sinon flâne autour.
# Aucune IA, aucun pathfinding, aucune écriture dans SaveManager.state. Tirages : Rng "village/anim/%d".

const RngS = preload("res://autoload/Rng.gd")

const SPEED_PX_S: float = 12.0
const PAUSE_SEC: Vector2 = Vector2(2.0, 5.0)
const WANDER_PX: int = 6
const BOB_PX: int = 1
const BOB_PERIOD_SEC: float = 0.3
const BODY_OFFSET: Vector2 = Vector2(0, -8) # centre du sprite (offset de npc.tscn)

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Sprite2D = $Ombre

var _rng: RngS.Pcg32
var _anchor: Vector2
var _tween: Tween
var _moving: bool = false
var _bob_t: float = 0.0

func setup(index: int, world_seed: int, texture: Texture2D, shadow: Texture2D, anchor: Vector2, shown: bool) -> void:
	_rng = RngS.make_rng(world_seed, "village/anim/%d" % index)
	_sprite.texture = texture
	_shadow.texture = shadow
	_anchor = anchor
	position = anchor
	visible = shown
	_wander()

func set_anchor(anchor: Vector2, shown: bool) -> void:
	visible = shown
	if anchor == _anchor:
		return
	_anchor = anchor
	_walk_to(anchor)

# Saisi au doigt (jalon 19) : le centre du sprite suit le doigt, sans Tween.
func hold_at(pos: Vector2) -> void:
	_kill()
	position = pos - BODY_OFFSET

# Relâché : rejoint son ancre à pied.
func release() -> void:
	_walk_to(_anchor)

# Sautillement (sprites Kenney à une image) : en marche, BOB_PX vers le haut une demi-période sur deux ; au repos, 0.
static func bob_offset(t: float, moving: bool) -> int:
	if not moving:
		return 0
	return -BOB_PX if posmod(int(floor(t / (BOB_PERIOD_SEC / 2.0))), 2) == 0 else 0

func _process(delta: float) -> void:
	_bob_t += delta
	_sprite.position.y = bob_offset(_bob_t, _moving)

# Pause de 2 à 5 s, puis petit pas autour de l'ancre ; rien ne bouge au repos.
func _wander() -> void:
	_kill()
	_tween = create_tween()
	_tween.tween_interval(PAUSE_SEC.x + _rng.next_float() * (PAUSE_SEC.y - PAUSE_SEC.x))
	_tween.tween_callback(func() -> void:
		_walk_to(_anchor + Vector2(_rng.range_int(-WANDER_PX, WANDER_PX), _rng.range_int(-WANDER_PX, WANDER_PX))))

func _walk_to(target: Vector2) -> void:
	_kill()
	var d: Vector2 = target - position
	if d.x != 0.0:
		_sprite.flip_h = d.x < 0.0
	_moving = true
	_bob_t = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "position", target, d.length() / SPEED_PX_S).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(_wander)

func _kill() -> void:
	_moving = false
	if _tween != null:
		_tween.kill()
