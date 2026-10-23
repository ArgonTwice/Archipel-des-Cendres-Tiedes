class_name Economy
extends RefCounted
# Fonctions pures de l'économie (Volets B et D). Constantes lues dans BalanceA / BalanceB / BalanceD, rien en dur.
# Taxes, salaires, trésoreries : floor par boutique, appliqués dans scripts/offline_dag.gd.

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
	return npc_daily_tick(m, false, cadence, meal, house_lvl, [], 0.0)["moral"]

# Tick unique par day_index (Volet B §4). En grève : pas de travail, +MORAL_STRIKE_DAILY_ATRE_GAIN, sortie plafonnée.
static func npc_daily_tick(m: int, on_strike: bool, cadence: String, meal: String, house_lvl: int, trait_ids: Array[int], griffe_bonus: float) -> Dictionary:
	var meal_delta: float
	match meal:
		"EATEN": meal_delta = BB.MORAL_GAIN_DAILY_MEAL
		"MISSED": meal_delta = BB.MORAL_PENALTY_NO_MEAL
		"OFFLINE": meal_delta = BB.MORAL_GAIN_OFFLINE_MISSING_MEAL
		_: assert(false, "repas inconnu : " + meal)
	var bed: float = BB.MORAL_GAIN_SLEEP_BASE + BB.MORAL_GAIN_SLEEP_PER_HOUSE_LVL * (house_lvl - 1)
	var extra: float = meal_delta + bed + BD.get_npc_trait_moral_delta(trait_ids) + griffe_bonus
	var reversion: int = roundi((BB.MORAL_EQUILIBRIUM_TARGET - m) * BB.MORAL_ATRE_MEAN_REVERSION_RATE)
	if on_strike:
		var raw: int = m + roundi(BB.MORAL_STRIKE_DAILY_ATRE_GAIN + extra) + reversion
		if raw >= BB.MORAL_STRIKE_EXIT_THRESHOLD:
			return {"moral": int(BB.MORAL_STRIKE_EXIT_CAP_VALUE), "on_strike": false}
		return {"moral": clampi(raw, int(BB.MORAL_MIN), int(BB.MORAL_MAX)), "on_strike": true}
	var work: float = -BB.MORAL_DRAIN_PER_WORK_HOUR[cadence] * BB.MORAL_WORK_HOURS_PER_DAY
	var m2: int = clampi(m + roundi(work + extra) + reversion, int(BB.MORAL_MIN), int(BB.MORAL_MAX))
	return {"moral": m2, "on_strike": m2 < BB.MORAL_STRIKE_ENTER_THRESHOLD}

# Trait principal de chaque gérant seul ; non cumulable : le meilleur, plafonné.
static func griffe_moral_bonus(manager_traits: Array) -> float:
	var best: float = 0.0
	for traits: Array in manager_traits:
		if not traits.is_empty() and BD.GRIFFE_DEFS.has(traits[0]):
			best = maxf(best, BD.GRIFFE_DEFS[traits[0]]["client_moral_bonus"])
	return minf(best, BD.GRIFFE_CLIENT_MORAL_MAX_BONUS)

static func npc_rate(prod_base: float, stars: int, cadence: String, moral: int, on_strike: bool, tool_broken: bool, trait_ids: Array[int]) -> float:
	var m_moral: float = BB.MORAL_PROD_MULT_STRIKE if on_strike else moral_prod_mult(moral)
	var m_wear: float = BB.TOOL_BROKEN_PROD_MULT if tool_broken else 1.0
	return prod_base * (BB.APTITUDE_MULT_BASE + BB.APTITUDE_MULT_PER_STAR * stars) * BB.CADENCE_PROD_MULT[cadence] * m_moral * m_wear * BD.get_npc_trait_prod_mult(trait_ids)

static func daily_fixed_sink(shop_lvls: Array[int]) -> int:
	var total: int = 0
	for lvl: int in shop_lvls:
		total += lvl
	return BB.SHOP_DAILY_FIXED_SINK_PER_LVL * total

static func tool_wear_per_day(trait_ids: Array[int]) -> float:
	var mult: float = 1.0
	for t_id: int in trait_ids:
		mult *= BD.TRAIT_DEFS[t_id]["tool_wear_mult"]
	return BB.TOOL_WEAR_PER_WORK_HOUR * BB.MORAL_WORK_HOURS_PER_DAY * mult

static func moral_prod_mult(m: int) -> float:
	if m < BB.MORAL_STRIKE_ENTER_THRESHOLD:
		return BB.MORAL_PROD_MULT_STRIKE
	if m < BB.MORAL_LOW_PENALTY_THRESHOLD:
		return BB.MORAL_PROD_MULT_LOW
	if m < BB.MORAL_HIGH_BONUS_THRESHOLD:
		return BB.MORAL_PROD_MULT_NORMAL
	return BB.MORAL_PROD_MULT_HIGH
