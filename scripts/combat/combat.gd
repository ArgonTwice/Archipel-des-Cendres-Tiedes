class_name Combat
extends RefCounted
# Combat de la lisière (SOCLE §A1, §A3, §A9) : fonctions statiques pures, testables sous --script.
# Formules et valeurs de jeu lues dans BalanceA / BalanceC, rythme des monstres compris (n°25).
# Restent ici l'arme de départ (proposition d'Antho, non traitée par Argon) et les constantes techniques de rendu.

const BA = preload("res://balance/balance_a.gd")
const BC = preload("res://balance/balance_c.gd")
const VL = preload("res://scripts/village/village_layout.gd")

# Arme de départ : Épée & Écu, Commun, ilvl 1, 3 pièces Enclume (Foyer), sans affixe. PROPOSÉ, à valider (jalon 10)
const START_WEAPON_TYPE: int = BC.WeaponType.SWORD_SHIELD
const START_WEAPON_RARITY: int = 0
const START_WEAPON_ILVL: int = 1
const START_WEAPON_SCHOOLS: Array[int] = [BC.SchoolId.FOYER, BC.SchoolId.FOYER, BC.SchoolId.FOYER]

# Rendu, techniques. PROPOSÉ, à valider (jalon 10)
const BAR_SIZE: Vector2i = Vector2i(12, 2)
const BAR_Y: int = -19
const BAR_BG: Color = Color(0, 0, 0, 0.6)
const BAR_PLAYER: Color = Color(0.40, 0.85, 0.30)
const BAR_MOB: Color = Color(0.90, 0.25, 0.20)
const WINDUP_MODULATE: Color = Color(1, 0.45, 0.45)
const MOB_HIT_ALPHA: float = 0.4
const MOB_HIT_SEC: float = 0.10
const PLAYER_HIT_MODULATE: Color = Color(1, 0.4, 0.4)
const PLAYER_HIT_SEC: float = 0.15

# Fondu d'évacuation à la mort du joueur : noir, retour devant l'Âtre sous le noir, retour. validé par Antho (G4, jalon 10 bis)
const EVAC_FADE_OUT_SEC: float = 0.40
const EVAC_HOLD_SEC: float = 0.30
const EVAC_FADE_IN_SEC: float = 0.40
const EVAC_COLOR: Color = Color(0, 0, 0)

static func starting_weapon_atk() -> float:
	return BC.compute_weapon_atk(START_WEAPON_ILVL, START_WEAPON_RARITY, START_WEAPON_SCHOOLS)

static func starting_weapon_range() -> float:
	return BC.WEAPON_SPECS[START_WEAPON_TYPE]["range_px"]

static func attack_period() -> float:
	var ranged: bool = BC.WEAPON_SPECS[START_WEAPON_TYPE]["is_ranged"]
	return 1.0 / (BA.WEAPON_BASE_ATTACK_SPEED_RANGED if ranged else BA.WEAPON_BASE_ATTACK_SPEED_MELEE)

static func mob_attack_period() -> float:
	return 1.0 / BA.MOB_BASE_ATTACK_SPEED

# Opacité du noir t secondes après la mort ; 0 hors évacuation.
static func evac_alpha(t: float) -> float:
	if t < 0.0:
		return 0.0
	if t < EVAC_FADE_OUT_SEC:
		return t / EVAC_FADE_OUT_SEC
	if t < EVAC_FADE_OUT_SEC + EVAC_HOLD_SEC:
		return 1.0
	if t < evac_duration():
		return 1.0 - (t - EVAC_FADE_OUT_SEC - EVAC_HOLD_SEC) / EVAC_FADE_IN_SEC
	return 0.0

static func evac_duration() -> float:
	return EVAC_FADE_OUT_SEC + EVAC_HOLD_SEC + EVAC_FADE_IN_SEC

static func player_stats(level: int, weapon_atk: float) -> Dictionary:
	return {"hp": floori(BA.PLAYER_BASE_HP + BA.PLAYER_HP_PER_LVL * (level - 1)),
		"atk": floori(BA.PLAYER_BASE_ATK + BA.PLAYER_ATK_PER_LVL * (level - 1) + weapon_atk),
		"def": floori(BA.PLAYER_BASE_DEF + BA.PLAYER_DEF_PER_LVL * (level - 1))}

static func mob_level(isolat: int) -> int:
	return BA.ISOLAT_LEVEL_RANGES[isolat].x

static func mob_stats(level: int, density_index: int, role: String) -> Dictionary:
	var d: float = BA.DENSITY_STAT_MULTIPLIERS[density_index]
	return {"hp": floori((BA.MOB_BASE_HP + BA.MOB_HP_PER_LVL * (level - 1)) * d * BA.MOB_ROLE_HP_MULT[role]),
		"atk": floori((BA.MOB_BASE_ATK + BA.MOB_ATK_PER_LVL * (level - 1)) * d * BA.MOB_ROLE_ATK_MULT[role]),
		"def": floori((BA.MOB_BASE_DEF + BA.MOB_DEF_PER_LVL * (level - 1)) * d)}

static func mitigation(def_target: float, level_attacker: int) -> float:
	return def_target / (def_target + BA.ARMOR_K_BASE + BA.ARMOR_K_PER_LVL * level_attacker)

static func damage(atk: float, def_target: float, level_attacker: int, crit: bool, m_comp: float = 1.0, m_elem: float = 1.0) -> int:
	var m_crit: float = BA.PLAYER_BASE_CRIT_DMG if crit else 1.0
	return floori(atk * m_comp * (1.0 - mitigation(def_target, level_attacker)) * m_elem * m_crit)

static func is_crit(rng: RefCounted) -> bool:
	return rng.next_float() < BA.PLAYER_BASE_CRIT_RATE

static func kill_xp(role: String, isolat: int) -> int:
	var base: Dictionary = {"NORMAL": BA.XP_KILL_NORMAL, "ELITE": BA.XP_KILL_ELITE, "BOSS": BA.XP_KILL_BOSS}
	return roundi(base[role] * BA.ISOLAT_XP_MULTIPLIERS[isolat])

static func bar_fill_px(hp: int, max_hp: int) -> int:
	return clampi(ceili(float(BAR_SIZE.x) * hp / max_hp), 0, BAR_SIZE.x)

static func cell_of(p: Vector2) -> Vector2i:
	var half: float = VL.CELL / 2.0
	return Vector2i(floori((p.x + half) / VL.CELL), floori((p.y + half) / VL.CELL))

# Règle d'or (SOCLE §A1) : le rayon de l'Âtre est le village.
static func in_village(p: Vector2) -> bool:
	return VL.in_radius(cell_of(p), VL.atre_radius())

# Toutes les cellules du rayon : pleines pour les monstres.
static func village_cells() -> Dictionary:
	var r: int = VL.atre_radius()
	var out: Dictionary = {}
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if VL.in_radius(Vector2i(x, y), r):
				out[Vector2i(x, y)] = true
	return out

# Indice du point le plus proche à portée (incluse), égalité -> plus petit indice ; -1 si aucun.
static func nearest_in_range(from: Vector2, points: Array[Vector2], range_px: float) -> int:
	var best: int = -1
	var best_d: float = INF
	for i in points.size():
		var d: float = from.distance_to(points[i])
		if d <= range_px and d < best_d:
			best = i
			best_d = d
	return best

# Poursuite avec hystérésis : repère à MOB_AGGRO_RANGE_PX, abandonne au-delà de MOB_LEASH_RANGE_PX.
static func mob_chasing(chasing: bool, dist: float, target_ok: bool) -> bool:
	if not target_ok:
		return false
	return dist <= (BA.MOB_LEASH_RANGE_PX if chasing else BA.MOB_AGGRO_RANGE_PX)
