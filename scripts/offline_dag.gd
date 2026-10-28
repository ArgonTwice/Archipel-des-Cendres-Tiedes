class_name OfflineDag
extends RefCounted
# DAG hors-ligne O(1) à 3 strates (Volet B §2, Volet D §7) : Extraction -> Transformation -> Vente.
# Fonctions statiques pures. Acyclique : usure et Moral produits ici s'appliquent à la session suivante.
# Chaque floor s'écrit _floor(x) = floori(x + 1e-9) (3,0 x 0,60 = 1,7999...).
#
# resolve(t_eff, isolat, mat, tavern, forge, npc_count) -> {"MAT": r, "TAVERN": r, "FORGE": r, "meals": int}
#   Boutique en entrée : stock, stock_max, target, rate (somme des npc_rate), p_base, budget_day, pot, tax_rate.
#   r : added, pot_prod, t_full, t_glean, consumed, before_sale, stock_final, price, sold,
#       revenue, wages, tax, treasury, pot_left, moral_bonus, fiche (pot_prod, t_full, t_glean, consumed à 0 pour MAT).
#   meals = min(npc_count, ventes de la Taverne).
#
# resume(village, now_utc) -> {"village": copie mise à jour, "t_eff": float, "ticked": bool, "fiches": Array[String],
#   "fixed_cost_paid": int, "tools_replaced": int, "dag": sortie de resolve}
#   village : last_save_utc, tz_offset_sec, last_tick_day, isolat, player_gold,
#     shops {MAT, TAVERN, FORGE : stock, lvl, posture, griffe_trait, pot, treasury},
#     npcs [post (EXTRACTION / TAVERN / FORGE / GUARD), stars, cadence, moral, on_strike, tool_broken,
#       tool_durability (0 à TOOL_DURABILITY_MAX ; brisé <=> <= 1e-9), traits, house_lvl, manages].
#   Ordre : a. t_eff, tick_due ; b. si tick : pots du jour, remplacement des outils brisés (stock et pot de la Forge) ;
#   c. rates ; d. resolve et application ; e. bonus de stock plein ; f. si tick : Moral, usure, frais fixes ;
#   g. last_save_utc = max(last_save_utc, now). Sans tick : ni remplacement, ni usure, ni frais.
#   g'. (fin de f, jalon 18) si tick : cadence_next / posture_next (clés optionnelles) deviennent cadence / posture, puis
#       sont effacées ; sans tick, elles restent. La journée écoulée est produite et fatiguée avec la cadence d'avant.
#   g''. (jalon 19) même boucle : post_next / stars_next deviennent post / stars. La gérance (manages) ne bouge jamais.
#       Passage en GUARD : cadence = NORMAL, cadence_next effacée (n°38 Q7b, GUARD_USES_NORMAL_CADENCE_DRAIN).

const BB = preload("res://balance/balance_b.gd")
const Eco = preload("res://scripts/economy.gd")
const ClockS = preload("res://autoload/Clock.gd")

const POST_SHOP: Dictionary = {"EXTRACTION": "MAT", "TAVERN": "TAVERN", "FORGE": "FORGE"}
const POST_PROD_BASE: Dictionary = {"EXTRACTION": BB.PROD_BASE_EXTRACTION_PER_HOUR, "TAVERN": BB.PROD_BASE_TAVERN_PER_HOUR, "FORGE": BB.PROD_BASE_FORGE_PER_HOUR}
const SHOP_BUDGET_KEY: Dictionary = {"MAT": "MATERIAUX", "TAVERN": "TAVERNE", "FORGE": "FORGE"}
const SHOP_ITEM: Dictionary = {"MAT": "FERRAILLE_BRUTE", "TAVERN": "BOUILLON_BRAISE", "FORGE": "OUTIL_SIMPLE"}

static func _floor(x: float) -> int:
	return floori(x + 1e-9)

# Strate 2 : atelier sur un stock amont avail ; max_meals < 0 = pas de plafond.
static func _workshop(t_eff: float, sh: Dictionary, avail: int, mat_cost: int, max_meals: int) -> Dictionary:
	var r: float = sh["rate"] * BB.OFFLINE_EFFICIENCY_FACTOR
	var t_full: float = minf(t_eff, avail / maxf(0.001, r * mat_cost))
	var t_glean: float = maxf(0.0, t_eff - t_full)
	var pot_prod: int = _floor(r * (t_full + BB.OFFLINE_GLANAGE_EFFICIENCY_FACTOR * t_glean))
	if max_meals >= 0:
		pot_prod = mini(max_meals, pot_prod)
	var added: int = mini(sh["stock_max"] - sh["stock"], pot_prod)
	var t_res: float = maxf(0.0, t_eff * (1.0 - float(added) / maxi(1, pot_prod)))
	return {"added": added, "pot_prod": pot_prod, "t_full": t_full, "t_glean": t_glean, "consumed": mini(avail, added * mat_cost),
		"before_sale": sh["stock"] + added, "moral_bonus": _floor(t_res * BB.OFFLINE_FULL_STOCK_MORAL_PER_HOUR)}

# Strate 3 : ventes au prix du stock cible, bornées par le stock, le rythme du budget du jour et le pot restant.
static func _sell(t_eff: float, isolat: int, sh: Dictionary, r: Dictionary) -> void:
	var price: int = Eco.sell_price(sh["p_base"], isolat, sh["target"], sh["target"])
	var p: int = maxi(1, price)
	var pace: int = _floor(sh["budget_day"] / (BB.OFFLINE_EFFICIENCY_FACTOR * BB.OFFLINE_MAX_HOURS * p) * BB.OFFLINE_EFFICIENCY_FACTOR * t_eff)
	var sold: int = mini(r["before_sale"], mini(pace, int(sh["pot"]) / p))
	var revenue: int = sold * price
	var wages: int = _floor(revenue * BB.SHOP_REVENUE_NPC_WAGE_SHARE)
	var tax: int = _floor(revenue * sh["tax_rate"])
	r["price"] = price
	r["sold"] = sold
	r["revenue"] = revenue
	r["wages"] = wages
	r["tax"] = tax
	r["treasury"] = revenue - wages - tax
	r["pot_left"] = sh["pot"] - revenue
	r["stock_final"] = r["before_sale"] - sold
	r["fiche"] = r["stock_final"] < BB.RUPTURE_FICHE_STOCK_RATIO_THRESHOLD * sh["target"]

static func resolve(t_eff: float, isolat: int, mat: Dictionary, tavern: Dictionary, forge: Dictionary, npc_count: int = 0) -> Dictionary:
	# Strate 1 : Matériaux
	var r1: float = mat["rate"] * BB.OFFLINE_EFFICIENCY_FACTOR
	var space1: int = mat["stock_max"] - mat["stock"]
	var added1: int = mini(space1, _floor(r1 * t_eff))
	var avail1: int = mat["stock"] + added1
	var t_res1: float = maxf(0.0, t_eff - space1 / maxf(0.001, r1))
	# Strate 2 : Taverne servie en priorité, la Forge prend le reste
	var rt: Dictionary = _workshop(t_eff, tavern, avail1, BB.CRAFT_MAT_COST_BROTH, BB.STRATE1_TAVERNE_PRIORITY_MAX_MEALS)
	var rf: Dictionary = _workshop(t_eff, forge, avail1 - rt["consumed"], BB.CRAFT_MAT_COST_SIMPLE_TOOL, -1)
	var rm: Dictionary = {"added": added1, "pot_prod": 0, "t_full": 0.0, "t_glean": 0.0, "consumed": 0,
		"before_sale": avail1 - rt["consumed"] - rf["consumed"], "moral_bonus": _floor(t_res1 * BB.OFFLINE_FULL_STOCK_MORAL_PER_HOUR)}
	# Strate 3 : ventes
	_sell(t_eff, isolat, mat, rm)
	_sell(t_eff, isolat, tavern, rt)
	_sell(t_eff, isolat, forge, rf)
	if rt["t_glean"] > 0.0 or rf["t_glean"] > 0.0:
		rm["fiche"] = true
	return {"MAT": rm, "TAVERN": rt, "FORGE": rf, "meals": mini(npc_count, rt["sold"])}

# Réglage différé (jalon 18) : value devient d[field + "_next"], ou efface l'attente si value est la valeur en cours.
static func set_next(d: Dictionary, field: String, value: String) -> void:
	if value == d[field]:
		d.erase(field + "_next")
	else:
		d[field + "_next"] = value

static func _apply_next(d: Dictionary, field: String) -> void:
	if d.has(field + "_next"):
		d[field] = d[field + "_next"]
		d.erase(field + "_next")

static func resume(village: Dictionary, now_utc: int) -> Dictionary:
	var v: Dictionary = village.duplicate(true)
	var t_eff: float = ClockS.offline_hours(v["last_save_utc"], now_utc)
	var today: int = ClockS.day_index(now_utc, v["tz_offset_sec"])
	var tick_due: bool = today > v["last_tick_day"] # au plus 1 tick : au-delà de 12 h, stase douce
	var inputs: Dictionary = {}
	for key: String in SHOP_BUDGET_KEY:
		var shop: Dictionary = v["shops"][key]
		var budget: int = roundi(BB.DAILY_CLIENT_BUDGET_BASE_GOLD[SHOP_BUDGET_KEY[key]] * BB.ISOLAT_GOLD_MULTIPLIERS[v["isolat"]])
		if tick_due:
			shop["pot"] = budget
		var s_max: int = Eco.stock_max(key == "MAT", shop["lvl"], shop["griffe_trait"])
		inputs[key] = {"stock_max": s_max, "target": Eco.stock_target(s_max, shop["posture"]), "rate": 0.0,
			"p_base": BB.ITEM_BASE_GOLD[SHOP_ITEM[key]], "budget_day": budget, "tax_rate": BB.POSTURE_VILLAGE_TAX_RATE[shop["posture"]]}
	# b. Remplacement des outils brisés des producteurs, achetés à la Forge au prix du stock cible
	var tools_replaced: int = 0
	if tick_due:
		var forge: Dictionary = v["shops"]["FORGE"]
		var f_in: Dictionary = inputs["FORGE"]
		var price: int = Eco.sell_price(BB.ITEM_BASE_GOLD["OUTIL_SIMPLE"], v["isolat"], f_in["target"], f_in["target"])
		for npc: Dictionary in v["npcs"]:
			if POST_SHOP.has(npc["post"]) and npc["tool_broken"] and forge["stock"] >= 1 and forge["pot"] >= price:
				var wages: int = floori(price * BB.SHOP_REVENUE_NPC_WAGE_SHARE)
				var tax: int = floori(price * f_in["tax_rate"])
				forge["stock"] -= 1
				forge["pot"] -= price
				v["player_gold"] += tax
				forge["treasury"] += price - wages - tax
				npc["tool_durability"] = BB.TOOL_DURABILITY_MAX
				npc["tool_broken"] = false
				tools_replaced += 1
	# c. Rates après remplacement
	for key: String in SHOP_BUDGET_KEY:
		inputs[key]["stock"] = v["shops"][key]["stock"]
		inputs[key]["pot"] = v["shops"][key]["pot"]
	for npc: Dictionary in v["npcs"]:
		if POST_SHOP.has(npc["post"]):
			var traits: Array[int] = []
			traits.assign(npc["traits"])
			inputs[POST_SHOP[npc["post"]]]["rate"] += Eco.npc_rate(POST_PROD_BASE[npc["post"]], npc["stars"], npc["cadence"], npc["moral"], npc["on_strike"], npc["tool_broken"], traits)
	var res: Dictionary = resolve(t_eff, v["isolat"], inputs["MAT"], inputs["TAVERN"], inputs["FORGE"], v["npcs"].size())
	var fiches: Array[String] = []
	for key: String in SHOP_BUDGET_KEY:
		var shop: Dictionary = v["shops"][key]
		var r: Dictionary = res[key]
		shop["stock"] = r["stock_final"]
		shop["pot"] = r["pot_left"]
		shop["treasury"] += r["treasury"]
		v["player_gold"] += r["tax"]
		if r["fiche"]:
			fiches.append(key)
	var manager_traits: Array = []
	for npc: Dictionary in v["npcs"]:
		if POST_SHOP.has(npc["post"]) and not npc["on_strike"]:
			npc["moral"] = mini(npc["moral"] + res[POST_SHOP[npc["post"]]]["moral_bonus"], int(BB.MORAL_MAX))
		if npc["manages"] != "":
			manager_traits.append(npc["traits"])
	# f. Tick unique : Moral, usure (producteurs qui ont travaillé avant le tick), puis frais fixes sans dette
	var fixed_cost_paid: int = 0
	if tick_due:
		var griffe: float = Eco.griffe_moral_bonus(manager_traits)
		for i in v["npcs"].size():
			var npc: Dictionary = v["npcs"][i]
			var traits: Array[int] = []
			traits.assign(npc["traits"])
			var worked: bool = POST_SHOP.has(npc["post"]) and not npc["on_strike"]
			var tick: Dictionary = Eco.npc_daily_tick(npc["moral"], npc["on_strike"], npc["cadence"], "EATEN" if i < res["meals"] else "OFFLINE", npc["house_lvl"], traits, griffe)
			npc["moral"] = tick["moral"]
			npc["on_strike"] = tick["on_strike"]
			if worked:
				npc["tool_durability"] = maxf(0.0, npc["tool_durability"] - Eco.tool_wear_per_day(traits))
				npc["tool_broken"] = npc["tool_durability"] <= 1e-9
		var lvls: Array[int] = [v["shops"]["MAT"]["lvl"], v["shops"]["TAVERN"]["lvl"], v["shops"]["FORGE"]["lvl"]]
		fixed_cost_paid = mini(v["player_gold"], Eco.daily_fixed_sink(lvls))
		v["player_gold"] -= fixed_cost_paid
		v["last_tick_day"] = today
		for npc: Dictionary in v["npcs"]:
			var to_guard: bool = npc.get("post_next", "") == "GUARD"
			_apply_next(npc, "cadence")
			_apply_next(npc, "post")
			_apply_next(npc, "stars")
			if to_guard:
				npc["cadence"] = "NORMAL"
		for key: String in SHOP_BUDGET_KEY:
			_apply_next(v["shops"][key], "posture")
	v["last_save_utc"] = maxi(v["last_save_utc"], now_utc)
	return {"village": v, "t_eff": t_eff, "ticked": tick_due, "fiches": fiches, "fixed_cost_paid": fixed_cost_paid, "tools_replaced": tools_replaced, "dag": res}
