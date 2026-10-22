class_name IcModel
extends RefCounted
# Modèle IC du Volet A, 4 emplacements (Arme, Casque, Plastron, Bottes).

const BA = preload("res://balance/balance_a.gd")
const BC = preload("res://balance/balance_c.gd")

static func budget(level: int, rarity: String) -> float:
	return (BA.LOOT_BUDGET_BASE + BA.LOOT_BUDGET_PER_ILVL * (level - 1)) * BA.RARITY_BUDGET_MULT[rarity]

static func ic(level: int, rarity: String, alpha: float, bonus_33: float) -> float:
	var b: float = budget(level, rarity)
	var slots: float = BA.PLAYER_EQUIPMENT_SLOTS_COUNT
	var atk: float = BA.PLAYER_BASE_ATK + BA.PLAYER_ATK_PER_LVL * (level - 1) \
		+ (BA.WEAPON_BASE_ATK_START + BA.WEAPON_BASE_ATK_PER_ILVL * (level - 1)) * BA.WEAPON_RARITY_ATK_MULT[rarity] * (1.0 + bonus_33) \
		+ slots * b * alpha * BC.AFFIX_DEFS["FLAT_ATK"]["unit_value"]
	var hp: float = BA.PLAYER_BASE_HP + BA.PLAYER_HP_PER_LVL * (level - 1) + slots * b * (1.0 - alpha) * BC.AFFIX_DEFS["FLAT_HP"]["unit_value"]
	var def: float = BA.PLAYER_BASE_DEF + BA.PLAYER_DEF_PER_LVL * (level - 1)
	var k: float = BA.ARMOR_K_BASE + BA.ARMOR_K_PER_LVL * level
	var u: float = 0.0
	if rarity == "LEGENDARY":
		u = BA.LEGENDARY_UNIQUE_BONUS_PER_PIECE * BA.LEGENDARY_MAX_EQUIPPED_UNIQUES
	var dps: float = atk * BA.WEAPON_BASE_ATTACK_SPEED_MELEE * (1.0 + BA.PLAYER_BASE_CRIT_RATE * (BA.PLAYER_BASE_CRIT_DMG - 1.0)) * (1.0 + u)
	var ehp: float = hp * (def + k) / k
	return sqrt(dps * ehp)

# Maximum sur alpha de 0,00 à 1,00 par pas de 0,01.
static func best_ic(level: int, rarity: String, bonus_33: float) -> float:
	var best: float = 0.0
	for i in 101:
		best = maxf(best, ic(level, rarity, i / 100.0, bonus_33))
	return best
