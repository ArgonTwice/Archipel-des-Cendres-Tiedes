class_name PlayerMotion
extends RefCounted
# Déplacement du Porte-Braise (SOCLE §A3) : fonctions statiques pures, testables sous --script.
# Collisions par cellules, sans moteur physique : déterministe, et rien ne traverse un mur même si une image dure longtemps.
# Valeurs de jeu lues dans BalanceA ; HALF_PX et STEP_PX sont techniques.

const VL = preload("res://scripts/village/village_layout.gd")
const BA = preload("res://balance/balance_a.gd")

const HALF_PX: Vector2 = Vector2(4, 3) # boîte des pieds 8 x 6 centrée sur l'origine du nœud ; à valider (jalon 9)
const STEP_PX: float = 1.0 # à valider (jalon 9)

# Boîte [p - HALF_PX, p + HALF_PX[ ; la cellule c couvre [16c - 8, 16c + 8[. Hors de GROUND_RECT = bord du monde.
static func overlaps(p: Vector2, solid: Dictionary) -> bool:
	var half: float = VL.CELL / 2.0
	var x0: int = floori((p.x - HALF_PX.x + half) / VL.CELL)
	var x1: int = ceili((p.x + HALF_PX.x + half) / VL.CELL) - 1
	var y0: int = floori((p.y - HALF_PX.y + half) / VL.CELL)
	var y1: int = ceili((p.y + HALF_PX.y + half) / VL.CELL) - 1
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var c: Vector2i = Vector2i(x, y)
			if solid.has(c) or not VL.GROUND_RECT.has_point(c):
				return true
	return false

# Axe x puis axe y, par pas de STEP_PX au plus ; un pas qui chevauche arrête l'axe et le reste est perdu (glissement).
static func move(p: Vector2, motion: Vector2, solid: Dictionary) -> Vector2:
	for axis: int in [Vector2.AXIS_X, Vector2.AXIS_Y]:
		var rest: float = motion[axis]
		while rest != 0.0:
			var step: float = clampf(rest, -STEP_PX, STEP_PX)
			var q: Vector2 = p
			q[axis] += step
			if overlaps(q, solid):
				break
			p = q
			rest -= step
	return p

# Distance parcourue t secondes après le début de l'esquive (vitesse constante).
static func dodge_progress(t: float) -> float:
	return BA.DODGE_DISTANCE_PX * clampf(t / BA.DODGE_DURATION_SEC, 0.0, 1.0)

static func in_iframes(t: float) -> bool:
	return t >= 0.0 and t < BA.DODGE_IFRAME_SEC

# Recharge comptée de départ à départ ; last_start < 0 : aucune esquive encore.
static func can_dodge(now: float, last_start: float) -> bool:
	return last_start < 0.0 or now - last_start >= BA.DODGE_COOLDOWN_SEC
