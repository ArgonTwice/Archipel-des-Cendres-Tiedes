extends Control
# Boutons d'aptitude du mode plié (Volet A §4) : I en bas à droite, II au-dessus, droitier (gaucher hors périmètre).
# Des Button : un deuxième doigt atteint un Control (viewport.cpp, gui.touch_focus par index ; base_button.cpp traite
# InputEventScreenTouch de tout index) et le Button consomme le posé, qui n'atteint jamais le joystick.
# Constantes techniques, toutes validées sur Fold (jalon 12).

const SKILL_BUTTON_SIZE_PX: int = 28 # 10 mm à l'échelle 6
const MARGIN_PX: int = 8
const COOLDOWN_ALPHA: float = 0.4
const READY_ALPHA: float = 0.75
const IDLE_BG: Color = Color(0, 0, 0, 0.55)
const ARMED_BG: Color = Color(1, 1, 1, 0.45)
const LABELS: Array[String] = ["I", "II"]

var _player: Node2D # player.gd
var _buttons: Array[Button] = []
var _styles: Array[StyleBoxFlat] = []

func _ready() -> void:
	for i in 2:
		var b: Button = get_node("Aptitude%d" % (i + 1))
		var top: int = -(MARGIN_PX + SKILL_BUTTON_SIZE_PX) * (i + 1)
		b.offset_left = -MARGIN_PX - SKILL_BUTTON_SIZE_PX
		b.offset_right = -MARGIN_PX
		b.offset_top = top
		b.offset_bottom = top + SKILL_BUTTON_SIZE_PX
		var st: StyleBoxFlat = StyleBoxFlat.new()
		st.set_corner_radius_all(SKILL_BUTTON_SIZE_PX / 2)
		st.bg_color = IDLE_BG
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(state, st)
		_buttons.append(b)
		_styles.append(st)

func setup(player: Node2D) -> void:
	_player = player
	for i in 2:
		_buttons[i].button_down.connect(_player.request_skill.bind(i))

func _process(_delta: float) -> void:
	if _player == null:
		return
	for i in 2:
		var cd: float = _player.skill_cd(i)
		var b: Button = _buttons[i]
		b.text = str(ceili(cd)) if cd > 0.0 else LABELS[i]
		b.modulate.a = COOLDOWN_ALPHA if cd > 0.0 else (1.0 if _player.skill_queued(i) else READY_ALPHA)
		_styles[i].bg_color = ARMED_BG if _player.skill_queued(i) else IDLE_BG
