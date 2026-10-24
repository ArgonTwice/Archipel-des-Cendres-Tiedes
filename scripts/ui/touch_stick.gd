extends Node2D
# Joystick flottant du mode plié (SOCLE §A3, §A4) : glisser = bouger, relâcher = à l'arrêt, balayage = esquive.
# Node2D sous UI_Folded : aucun Control n'avale les touches de l'UI. Un seul doigt suivi, le premier posé.
# Positions en pixels de viewport (208 x 328 en plié). Constantes techniques, toutes à valider (jalon 9).

signal direction_changed(dir: Vector2)
signal swiped(dir: Vector2)
signal was_reset

const DEAD_ZONE_PX: float = 4.0 # 1,5 mm sur le Fold 8 ; à valider (jalon 9)
const STICK_RADIUS_PX: float = 20.0 # 7,3 mm ; au-delà, la base suit le doigt ; à valider (jalon 9)
const SWIPE_MIN_PX: float = 16.0 # 5,8 mm ; à valider (jalon 9)
const SWIPE_MAX_SEC: float = 0.20 # à valider (jalon 9)
const KNOB_RADIUS_PX: float = 4.0 # à valider (jalon 9)
const RING_COLOR: Color = Color(1, 1, 1, 0.25) # à valider (jalon 9)
const KNOB_COLOR: Color = Color(1, 1, 1, 0.5) # à valider (jalon 9)

var _index: int = -1 # doigt suivi, -1 = aucun
var _start: Vector2
var _origin: Vector2
var _finger: Vector2
var _start_usec: int = 0
var _dir: Vector2 = Vector2.ZERO

static func stick_dir(origin: Vector2, finger: Vector2) -> Vector2:
	var d: Vector2 = finger - origin
	return Vector2.ZERO if d.length() < DEAD_ZONE_PX else d.normalized()

static func follow_origin(origin: Vector2, finger: Vector2) -> Vector2:
	var d: Vector2 = finger - origin
	return origin if d.length() <= STICK_RADIUS_PX else finger - d.normalized() * STICK_RADIUS_PX

static func is_swipe(duration_sec: float, start: Vector2, end: Vector2) -> bool:
	return duration_sec <= SWIPE_MAX_SEC and (end - start).length() >= SWIPE_MIN_PX

# Le doigt suivi est lu ici, avant l'UI : un glissé qui passe sur le Rapport (mouse_filter STOP) y serait consommé
# (viewport.cpp, _gui_input_event) et n'atteindrait jamais _unhandled_input.
func _input(event: InputEvent) -> void:
	if _index < 0 or not (event is InputEventScreenDrag or (event is InputEventScreenTouch and not event.pressed)):
		return
	if event.index == _index:
		_handle(event)
		get_viewport().set_input_as_handled()

# Les posés arrivent ici : un posé sur le Rapport est consommé par l'UI et ne démarre pas le joystick.
func _unhandled_input(event: InputEvent) -> void:
	_handle(event)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset()

# Oublie le doigt : un doigt resté posé n'est jamais repris, il faut un nouveau posé.
func reset() -> void:
	_index = -1
	_dir = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	was_reset.emit()
	queue_redraw()

func _handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _index < 0:
				_index = event.index
				_start = event.position
				_origin = _start
				_finger = _start
				_start_usec = Time.get_ticks_usec()
				queue_redraw()
		elif event.index == _index:
			var held: float = (Time.get_ticks_usec() - _start_usec) / 1e6
			if not event.canceled and is_swipe(held, _start, event.position):
				swiped.emit((event.position - _start).normalized())
			_index = -1
			_dir = Vector2.ZERO
			direction_changed.emit(Vector2.ZERO)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _index:
		_finger = event.position
		_origin = follow_origin(_origin, _finger)
		var d: Vector2 = stick_dir(_origin, _finger)
		if d != _dir:
			_dir = d
			direction_changed.emit(d)
		queue_redraw()

func _draw() -> void:
	if _index < 0:
		return
	draw_arc(_origin, STICK_RADIUS_PX, 0.0, TAU, 32, RING_COLOR, -1.0, false)
	draw_circle(_origin + (_finger - _origin).limit_length(STICK_RADIUS_PX), KNOB_RADIUS_PX, KNOB_COLOR, true, -1.0, false)
