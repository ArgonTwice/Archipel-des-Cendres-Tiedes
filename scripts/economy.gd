class_name Economy
extends RefCounted
# Fonctions pures de l'économie (Volets B et D). Constantes lues dans BalanceA / BalanceB / BalanceD, rien en dur.
# Taxes, salaires, trésoreries : floor par boutique et par vente (à coder avec le DAG).
# Grève (Volet-B-valide.md §4) : hors périmètre, elle a besoin d'un état par PNJ.

const BA = preload("res://balance/balance_a.gd")
const BB = preload("res://balance/balance_b.gd")
const BD = preload("res://balance/balance_d.gd")

# price_mult_max : BalanceD.GRIFFE_DEFS[trait]["price_mult_max_override"] pour une boutique à Griffe.
static func sell_price(p_base: int, isolat: int, stock: int, target: int, price_mult_max: float = BB.PRICE_MULT_MAX) -> int:
	assert(target > 0)
	var r: float = float(stock) / float(target)
	var mult: float = clampf(BB.PRICE_ELASTICITY_INTERCEPT - BB.PRICE_ELASTICITY_SLOPE * r, BB.PRICE_MULT_MIN, price_mult_max)
	return maxi(1, roundi(p_base * BB.ISOLAT_GOLD_MULTIPLIERS[isolat] * mult))

static func buyback_price(sell: int) -> int:
	return maxi(1, floori(sell * BB.SHOP_BUYBACK_DISCOUNT_RATIO))

# griffe_trait : trait principal du gérant (BalanceD.TraitId), -1 sans Griffe.
static func stock_max(is_material: bool, lvl: int, griffe_trait: int = -1) -> int:
	var base: int
	if is_material:
		base = BB.SHOP_STOCK_MAX_MAT_BASE + BB.SHOP_STOCK_MAX_MAT_PER_LVL * (lvl - 1)
	else:
		base = BB.SHOP_STOCK_MAX_PROD_BASE + BB.SHOP_STOCK_MAX_PROD_PER_LVL * (lvl - 1)
	if BD.GRIFFE_DEFS.has(griffe_trait):
		return floori(base * BD.GRIFFE_DEFS[griffe_trait]["stock_max_mult"] + 1e-6) # 60 x 1,15 = 68,999...
	return base

# posture : "SOLIDAIRE" | "EQUILIBRE" | "EXPORTATION".
static func stock_target(p_stock_max: int, posture: String) -> int:
	return roundi(BB.POSTURE_TARGET_STOCK_RATIO[posture] * p_stock_max)

# cadence : "PAISIBLE" | "NORMAL" | "FORGE_ARDENTE" ; meal : "EATEN" | "MISSED" | "OFFLINE".
static func moral_tick(m: int, cadence: String, meal: String, house_lvl: int) -> int:
	var work: float = -BB.MORAL_DRAIN_PER_WORK_HOUR[cadence] * BB.MORAL_WORK_HOURS_PER_DAY
	var meal_delta: float
	match meal:
		"EATEN": meal_delta = BB.MORAL_GAIN_DAILY_MEAL
		"MISSED": meal_delta = BB.MORAL_PENALTY_NO_MEAL
		"OFFLINE": meal_delta = BB.MORAL_GAIN_OFFLINE_MISSING_MEAL
		_: assert(false, "repas inconnu : " + meal)
	var bed: float = BB.MORAL_GAIN_SLEEP_BASE + BB.MORAL_GAIN_SLEEP_PER_HOUSE_LVL * (house_lvl - 1)
	var reversion: int = roundi((BB.MORAL_EQUILIBRIUM_TARGET - m) * BB.MORAL_ATRE_MEAN_REVERSION_RATE)
	return clampi(m + roundi(work + meal_delta + bed) + reversion, int(BB.MORAL_MIN), int(BB.MORAL_MAX))

static func moral_prod_mult(m: int) -> float:
	if m < BB.MORAL_STRIKE_ENTER_THRESHOLD:
		return BB.MORAL_PROD_MULT_STRIKE
	if m < BB.MORAL_LOW_PENALTY_THRESHOLD:
		return BB.MORAL_PROD_MULT_LOW
	if m < BB.MORAL_HIGH_BONUS_THRESHOLD:
		return BB.MORAL_PROD_MULT_NORMAL
	return BB.MORAL_PROD_MULT_HIGH
