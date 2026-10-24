extends Node2D
# Nœud de Brume (volet E §3) : récolté à l'arrêt, au contact. Sa cellule reste pleine dans tous les états.
# Piloté par lisiere.gd (progression), jamais par son propre _process.

const CombatS = preload("res://scripts/combat/combat.gd")
const VL = preload("res://scripts/village/village_layout.gd")

enum State { AVAILABLE, GATHERED, VITRIFIED }

const GATHER_SEC: float = 1.5 # PROPOSÉ, à valider (jalon 11)
const GATHER_RANGE_PX: float = 24.0 # centre à centre ; joueur collé à la cellule = 12 à 16 px. PROPOSÉ, à valider (jalon 11)
const GATHERED_ALPHA: float = 0.35 # PROPOSÉ, à valider (jalon 11)
const VITRIFIED_MODULATE: Color = Color(0.5, 0.5, 0.55) # PROPOSÉ, à valider (jalon 11)
const BAR_GATHER: Color = Color(0.55, 0.75, 0.95) # PROPOSÉ, à valider (jalon 11)

var index: int = 0
var cell: Vector2i
var state: int = State.AVAILABLE
var progress: float = 0.0
var _sprite: Sprite2D

# Nœuds lus ici : setup peut précéder _ready (simulateur headless).
func setup(c: Vector2i, texture: Texture2D, shadow: Texture2D) -> void:
	_sprite = $Sprite
	_sprite.texture = texture
	$Ombre.texture = shadow
	cell = c
	position = VL.cell_center(c)
	set_state(State.AVAILABLE)

func set_state(s: int) -> void:
	state = s
	progress = 0.0
	_sprite.modulate = VITRIFIED_MODULATE if s == State.VITRIFIED else Color.WHITE
	modulate.a = GATHERED_ALPHA if s == State.GATHERED else 1.0
	queue_redraw()

func set_progress(p: float) -> void:
	if p != progress:
		progress = p
		queue_redraw()

func _draw() -> void:
	if state != State.AVAILABLE or progress <= 0.0:
		return
	var bar: Vector2i = CombatS.BAR_SIZE
	var origin: Vector2 = Vector2(-bar.x / 2.0, CombatS.BAR_Y + 8)
	draw_rect(Rect2(origin, bar), CombatS.BAR_BG, true, -1.0, false)
	var fill: int = clampi(ceili(bar.x * progress / GATHER_SEC), 0, bar.x)
	draw_rect(Rect2(origin, Vector2(fill, bar.y)), BAR_GATHER, true, -1.0, false)
