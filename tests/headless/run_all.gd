extends SceneTree
# godot --headless --script res://tests/headless/run_all.gd
const BA = preload("res://balance/balance_a.gd")
const RngS = preload("res://autoload/Rng.gd")
const ClockS = preload("res://autoload/Clock.gd")
const BB = preload("res://balance/balance_b.gd")
const BC = preload("res://balance/balance_c.gd")
const BD = preload("res://balance/balance_d.gd")
const Eco = preload("res://scripts/economy.gd")
const Dag = preload("res://scripts/offline_dag.gd")
const Ic = preload("res://tests/headless/ic_model.gd")
const D0: int = 1792627200 # 2026-10-22 00:00:00 UTC
var _fails: int = 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	print("%s  %s%s" % ["PASS" if ok else "FAIL", name, "" if ok or detail == "" else " -- " + detail])
	if not ok:
		_fails += 1

func _u64(hi: int, lo: int) -> int:
	return (hi << 32) | lo

func _seq(world_seed: int, node: String, n: int) -> Array[int]:
	var r: RngS.Pcg32 = RngS.make_rng(world_seed, node)
	var out: Array[int] = []
	for i in n:
		out.append(r.next_u32())
	return out

func _moral_after(m: int, cadence: String, ticks: int) -> int:
	for i in ticks:
		m = Eco.moral_tick(m, cadence, "EATEN", 1)
	return m

func _sum(weights: Dictionary) -> int:
	var t: int = 0
	for v: int in weights.values():
		t += v
	return t

func _bonds(values: Array) -> Array[int]:
	var out: Array[int] = []
	out.assign(values)
	return out

func _shop(stock: int, s_max: int, target: int, rate: float, p_base: int, budget: int, pot: int) -> Dictionary:
	return {"stock": stock, "stock_max": s_max, "target": target, "rate": rate, "p_base": p_base, "budget_day": budget, "pot": pot, "tax_rate": 0.20}

# Écarts entre une sortie de resolve et [boutique ("" = racine), clé, attendu] ; "" si tout tombe.
func _diff(res: Dictionary, want: Array) -> String:
	var bad: String = ""
	for w: Array in want:
		var got: Variant = res[w[1]] if w[0] == "" else res[w[0]][w[1]]
		var ok: bool = absf(got - w[2]) <= 1e-4 if w[2] is float else got == w[2]
		if not ok:
			bad += "%s.%s=%s (attendu %s) " % [w[0], w[1], str(got), str(w[2])]
	return bad

func _ticks(m: int, strike: bool, cadence: String, meal: String, traits: Array, griffe: float, n: int) -> Dictionary:
	var t: Dictionary = {"moral": m, "on_strike": strike}
	for i in n:
		t = Eco.npc_daily_tick(t["moral"], t["on_strike"], cadence, meal, 1, _bonds(traits), griffe)
	return t

func _npc(post: String, moral: int, manages: String) -> Dictionary:
	return {"post": post, "stars": 2, "cadence": "NORMAL", "moral": moral, "on_strike": false, "tool_broken": false, "traits": [], "house_lvl": 1, "manages": manages}

# Village B : 3 gérants producteurs + 2 gardes, 2 étoiles, NORMAL, Moral 80, stocks vides, niveau 1 EQUILIBRE sans Griffe.
func _village(last_save: int) -> Dictionary:
	var shops: Dictionary = {}
	for k: String in ["MAT", "TAVERN", "FORGE"]:
		shops[k] = {"stock": 0, "lvl": 1, "posture": "EQUILIBRE", "griffe_trait": -1, "pot": 0, "treasury": 150}
	shops["MAT"]["pot"] = 8
	shops["TAVERN"]["pot"] = 48
	shops["FORGE"]["pot"] = 144
	var npcs: Array = [_npc("EXTRACTION", 80, "MAT"), _npc("TAVERN", 80, "TAVERN"), _npc("FORGE", 80, "FORGE"), _npc("GUARD", 80, ""), _npc("GUARD", 80, "")]
	return {"last_save_utc": last_save, "tz_offset_sec": 0, "last_tick_day": ClockS.day_index(last_save, 0), "isolat": 0, "player_gold": 0, "shops": shops, "npcs": npcs}

func _morals(v: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for npc: Dictionary in v["npcs"]:
		out.append(npc["moral"])
	return out

func _parts(a: int, b: int, c: int) -> Array[int]:
	return [a, b, c]

# Monstre lié à l'élément de l'arme : résistance ; lié à l'autre élément : avantage ; neutre : 1,0.
func _elem_expectation(weapon_elem: String, weights: Dictionary) -> float:
	var e: float = 0.0
	for k: String in weights:
		var m: float = 1.0
		if k != "NEUTRAL":
			m = BA.ELEM_RESIST_MULT if k == weapon_elem + "_BOUND" else BA.ELEM_ADVANTAGE_MULT
		e += m * weights[k] / float(_sum(weights))
	return e

func _initialize() -> void:
	# XP
	_check("xp: cumul Nv50 == 715400", BA.get_cumulative_xp(50) == 715400, str(BA.get_cumulative_xp(50)))
	_check("xp: required(1) == 200", BA.get_xp_required(1) == 200, str(BA.get_xp_required(1)))
	_check("xp: required(49) == 40280", BA.get_xp_required(49) == 40280, str(BA.get_xp_required(49)))
	# Rattrapage
	for c: Array in [[47, 50, 2.0], [48, 50, 2.0], [10, 12, 1.0], [9, 12, 2.0], [12, 12, 1.0]]:
		var m: float = BA.get_action_xp_catchup_mult(c[0], c[1])
		_check("rattrapage (%d, %d) == %.1f" % [c[0], c[1], c[2]], is_equal_approx(m, c[2]), str(m))
	# Kappa de greffe
	var in_range: bool = true
	for b: float in [0.0, 1.0, 10.0, 50.0, 100.0, 1000.0]:
		for p: float in [0.0, 1.0, 30.0, 60.0, 500.0, 5000.0]:
			for s: float in [0.0, 0.5, 1.0, 20.0, 100.0, 10000.0]:
				var k: float = BA.get_graft_kappa(b, p, s)
				if k < 0.0 or k > 1.0:
					in_range = false
	_check("greffe: kappa dans [0, 1]", in_range)
	_check("greffe: kappa == 1.0 si somme autres == 0", BA.get_graft_kappa(100.0, 40.0, 0.0) == 1.0)
	# Reset 04:00 local
	var d_before: int = ClockS.day_index(D0 + 3 * 3600 + 59 * 60 + 59, 0)
	var d_reset: int = ClockS.day_index(D0 + 4 * 3600, 0)
	var d_late: int = ClockS.day_index(D0 + 23 * 3600 + 59 * 60 + 59, 0)
	_check("reset: 03:59:59 et 04:00:00 consecutifs", d_reset == d_before + 1, "%d %d" % [d_before, d_reset])
	_check("reset: 04:00:00 et 23:59:59 identiques", d_reset == d_late, "%d %d" % [d_reset, d_late])
	# Rng
	_check("rng: fnv1a64(\"\")", RngS.fnv1a64("") == _u64(0xcbf29ce4, 0x84222325))
	_check("rng: fnv1a64(\"a\")", RngS.fnv1a64("a") == _u64(0xaf63dc4c, 0x8601ec8c))
	var pcg: RngS.Pcg32 = RngS.Pcg32.new(42, 54)
	var expected: Array[int] = [0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e]
	var got: Array[int] = []
	for i in 6:
		got.append(pcg.next_u32())
	_check("rng: pcg32(42, 54) 6 sorties de reference", got == expected, str(got))
	_check("rng: meme (seed, node) = meme suite de 1000", _seq(1234, "carte/n1", 1000) == _seq(1234, "carte/n1", 1000))
	_check("rng: node_id different = suite differente", _seq(1234, "carte/n1", 1000) != _seq(1234, "carte/n2", 1000))
	var counts: Array[int] = []
	counts.resize(10)
	counts.fill(0)
	var r: RngS.Pcg32 = RngS.make_rng(7, "test/range")
	for i in 100000:
		counts[r.range_int(0, 9)] += 1
	var even: bool = true
	for n: int in counts:
		if n < 9000 or n > 11000:
			even = false
	_check("rng: range_int(0, 9) sur 100000, chaque valeur 9-11 %", even, str(counts))
	var fl: bool = true
	for i in 10000:
		var f: float = r.next_float()
		if f < 0.0 or f >= 1.0:
			fl = false
	_check("rng: next_float dans [0, 1)", fl)
	# Clock
	var t: int = 1000000
	_check("clock: recul de 30 s -> 0", ClockS.offline_hours(t, t - 30) == 0.0)
	_check("clock: recul de 120 s -> 0 (gel doux)", ClockS.offline_hours(t, t - 120) == 0.0)
	_check("clock: 6 h -> 6.0", is_equal_approx(ClockS.offline_hours(t, t + 6 * 3600), 6.0))
	_check("clock: 48 h -> 12.0 (plafond)", is_equal_approx(ClockS.offline_hours(t, t + 48 * 3600), 12.0))
	# Constantes (Volet B)
	_check("const: ISOLAT_GOLD_MULTIPLIERS == ISOLAT_XP_MULTIPLIERS", BB.ISOLAT_GOLD_MULTIPLIERS == BA.ISOLAT_XP_MULTIPLIERS)
	_check("const: XP_VILLAGE_COUNTER_EVENT == 87", BA.XP_VILLAGE_COUNTER_EVENT == 87)
	# Prix
	var arb_ok: bool = true
	var arb_bad: String = ""
	for item: String in BB.ITEM_BASE_GOLD:
		for iso in 5:
			var high: int = Eco.sell_price(BB.ITEM_BASE_GOLD[item], iso, 0, 100)
			var low: int = Eco.sell_price(BB.ITEM_BASE_GOLD[item], iso, 200, 100)
			if Eco.buyback_price(high) > low:
				arb_ok = false
				arb_bad = "%s iso %d : rachat(%d) > %d" % [item, iso, high, low]
	_check("prix: anti-arbitrage rachat(x1,25) <= vente(x0,75), 10 objets x 5 isolats", arb_ok, arb_bad)
	var eq_sell: int = Eco.sell_price(BB.ITEM_BASE_GOLD["EQUIP_FORGE"], 0, 100, 100)
	var mi_sell: int = Eco.sell_price(BB.ITEM_BASE_GOLD["MINERAI_FER_BRAISE"], 0, 100, 100)
	_check("prix: EQUIP_FORGE 48 -> vente 48, rachat 28", eq_sell == 48 and Eco.buyback_price(eq_sell) == 28, "%d %d" % [eq_sell, Eco.buyback_price(eq_sell)])
	_check("prix: MINERAI_FER_BRAISE 8 -> vente 8, rachat 4", mi_sell == 8 and Eco.buyback_price(mi_sell) == 4, "%d %d" % [mi_sell, Eco.buyback_price(mi_sell)])
	# Moral
	_check("moral: NORMAL/EATEN/maison 1, 80 -> 80", Eco.moral_tick(80, "NORMAL", "EATEN", 1) == 80)
	_check("moral: NORMAL, 40 ticks depuis 50 -> 79", _moral_after(50, "NORMAL", 40) == 79, str(_moral_after(50, "NORMAL", 40)))
	_check("moral: NORMAL, 40 ticks depuis 90 -> 81", _moral_after(90, "NORMAL", 40) == 81, str(_moral_after(90, "NORMAL", 40)))
	_check("moral: FORGE_ARDENTE, 40 ticks depuis 80 -> 34", _moral_after(80, "FORGE_ARDENTE", 40) == 34, str(_moral_after(80, "FORGE_ARDENTE", 40)))
	_check("moral: prod_mult(34) == 0.75", is_equal_approx(Eco.moral_prod_mult(34), 0.75))
	# IC (split 50/50)
	var want_half: Array = [[1, 1.3579], [25, 1.3791], [50, 1.3811]]
	for w: Array in want_half:
		var ratio: float = Ic.ic(w[0], "LEGENDARY", 0.5, 0.0) / Ic.ic(w[0], "COMMON", 0.5, 0.0)
		_check("ic: alpha 0,5, L=%d, ratio == %.4f (+-0,0005)" % [w[0], w[1]], absf(ratio - w[1]) <= 0.0005, "%.6f" % ratio)
	# IC (split optimal)
	var want_best: Array = [[1, 1.3602], [25, 1.3818], [50, 1.3835]]
	for w: Array in want_best:
		var ratio: float = Ic.best_ic(w[0], "LEGENDARY", 0.0) / Ic.best_ic(w[0], "COMMON", 0.0)
		_check("ic: optimal, L=%d, ratio == %.4f (+-0,0005) et <= 1,40" % [w[0], w[1]], absf(ratio - w[1]) <= 0.0005 and ratio <= 1.40, "%.6f" % ratio)
	# IC 3/3 (bonus côté Légendaire seulement)
	var want_33: Array = [[1, 1.3679], [25, 1.3948], [50, 1.3969]]
	for w: Array in want_33:
		var ratio: float = Ic.best_ic(w[0], "LEGENDARY", BC.SCHOOL_SET_3_WEAPON_ATK_BONUS) / Ic.best_ic(w[0], "COMMON", 0.0)
		_check("ic 3/3: L=%d, ratio == %.4f (+-0,0005) et <= 1,40" % [w[0], w[1]], absf(ratio - w[1]) <= 0.0005 and ratio <= 1.40, "%.6f" % ratio)
	# Volet C : poids
	for iso: int in BC.ISOLAT_SCHOOL_DROP_WEIGHTS:
		_check("poids: ISOLAT_SCHOOL_DROP_WEIGHTS[%d] somme 100" % iso, _sum(BC.ISOLAT_SCHOOL_DROP_WEIGHTS[iso]) == 100, str(_sum(BC.ISOLAT_SCHOOL_DROP_WEIGHTS[iso])))
	_check("poids: VERTICAL_SLICE_DROP_WEIGHTS somme 100", _sum(BC.VERTICAL_SLICE_DROP_WEIGHTS) == 100, str(_sum(BC.VERTICAL_SLICE_DROP_WEIGHTS)))
	for s: int in BC.SCHOOL_COMBAT_AFFIX_WEIGHTS:
		_check("poids: SCHOOL_COMBAT_AFFIX_WEIGHTS[%s] somme 100" % BC.SchoolId.keys()[s], _sum(BC.SCHOOL_COMBAT_AFFIX_WEIGHTS[s]) == 100, str(_sum(BC.SCHOOL_COMBAT_AFFIX_WEIGHTS[s])))
	_check("poids: ARMOR_COMBAT_AFFIX_WEIGHTS somme 100", _sum(BC.ARMOR_COMBAT_AFFIX_WEIGHTS) == 100, str(_sum(BC.ARMOR_COMBAT_AFFIX_WEIGHTS)))
	# Volet C : identité offensive
	for s: int in BC.SCHOOL_DATA:
		var w: Dictionary = BC.SCHOOL_COMBAT_AFFIX_WEIGHTS[s]
		var off: float = (w["FLAT_ATK"] + w["PCT_ATK"] + w["PCT_ASPD"] + w["PCT_CRIT_CHANCE"] + w["PCT_CRIT_DMG"]) / 100.0
		_check("identite: %s part offensive == %.2f" % [BC.SchoolId.keys()[s], BC.SCHOOL_DATA[s]["offensive_share"]], is_equal_approx(off, BC.SCHOOL_DATA[s]["offensive_share"]), "%.4f" % off)
	# Volet C : pièces
	var share: float = 0.0
	for f: float in BC.WEAPON_PART_ATK_SHARE:
		share += f
	_check("pieces: somme WEAPON_PART_ATK_SHARE == 1,0", is_equal_approx(share, 1.0), "%.6f" % share)
	var p2: float = BC.DROP_PART_SAME_SCHOOL_PROB * BC.DROP_PART_SAME_SCHOOL_PROB
	_check("pieces: DROP_PART_SAME_SCHOOL_PROB^2 == 0,49", absf(p2 - 0.49) <= 1e-9, "%.12f" % p2)
	# Volet C : ATK_arme
	var F: int = BC.SchoolId.FOYER
	var Br: int = BC.SchoolId.BRASIER
	for c: Array in [[1, 0, _parts(F, F, F), 10.35], [50, 2, _parts(F, F, Br), 258.16], [50, 2, _parts(Br, Br, Br), 267.1956]]:
		var atk: float = BC.compute_weapon_atk(c[0], c[1], c[2])
		_check("atk_arme(%d, %d, %s) == %s" % [c[0], c[1], str(c[2]), str(c[3])], absf(atk - c[3]) <= 1e-6, "%.8f" % atk)
	# Volet C : budget
	var b50: float = BC.get_piece_budget(50, 2)
	_check("budget: get_piece_budget(50, 2) == 190,976", absf(b50 - 190.976) <= 1e-6, "%.8f" % b50)
	var s50: float = BC.get_level_scale_s(50)
	_check("budget: get_level_scale_s(50) == 12,4333 (+-1e-4)", absf(s50 - 12.4333) <= 1e-4, "%.8f" % s50)
	var pc: float = BC.get_affix_point_cost("PCT_ATK", 6.0, 50)
	_check("budget: get_affix_point_cost(PCT_ATK, 6, 50) == 34,316 (+-1e-3)", absf(pc - 34.316) <= 1e-3, "%.8f" % pc)
	for c: Array in [[0, 1.00], [1, 0.60], [2, 0.50], [4, 0.45]]:
		var m: float = BC.get_max_affix_budget_share(c[0])
		_check("budget: get_max_affix_budget_share(%d) == %.2f" % [c[0], c[1]], is_equal_approx(m, c[1]), str(m))
	# Volet C : remontage
	for c: Array in [[0, 0, 24], [4, 0, 36], [4, 5, 18]]:
		var g: int = BC.compute_part_swap_gold_cost(c[0], c[1])
		_check("remontage: compute_part_swap_gold_cost(%d, %d) == %d" % [c[0], c[1], c[2]], g == c[2], str(g))
	# Volet C : éléments (isolat 2, arme Braise et arme Givre)
	for s: int in [BC.SchoolId.BRASIER, BC.SchoolId.ABYSSE]:
		var e: float = _elem_expectation(BC.SCHOOL_DATA[s]["implicit_element"], BC.ISOLAT_MONSTER_ELEMENT_WEIGHTS[2])
		_check("elements: E(M_elem) isolat 2, arme %s == 1,0125" % BC.SCHOOL_DATA[s]["implicit_element"], absf(e - 1.0125) <= 1e-9, "%.12f" % e)
	# Volet D : traits
	_check("traits: TRAIT_DRAW_WEIGHTS somme 100", _sum(BD.TRAIT_DRAW_WEIGHTS) == 100, str(_sum(BD.TRAIT_DRAW_WEIGHTS)))
	_check("traits: TRAIT_COUNT_WEIGHTS somme 100", _sum(BD.TRAIT_COUNT_WEIGHTS) == 100, str(_sum(BD.TRAIT_COUNT_WEIGHTS)))
	var sym: bool = true
	for a: int in BD.TRAIT_INCOMPATIBILITIES:
		for b: int in BD.TRAIT_INCOMPATIBILITIES:
			if (b in BD.TRAIT_INCOMPATIBILITIES[a]) != (a in BD.TRAIT_INCOMPATIBILITIES[b]):
				sym = false
	_check("traits: TRAIT_INCOMPATIBILITIES symetrique", sym)
	var combos: Array = []
	for a: int in BD.TraitId.values():
		combos.append(_bonds([a]))
		for b: int in BD.TraitId.values():
			if b > a and not (b in BD.TRAIT_INCOMPATIBILITIES[a]):
				combos.append(_bonds([a, b]))
	_check("traits: 18 combinaisons valides", combos.size() == 18, str(combos.size()))
	var p_min: float = INF
	var p_max: float = -INF
	var m_min: float = INF
	var m_max: float = -INF
	for c: Array[int] in combos:
		p_min = minf(p_min, BD.get_npc_trait_prod_mult(c))
		p_max = maxf(p_max, BD.get_npc_trait_prod_mult(c))
		m_min = minf(m_min, BD.get_npc_trait_moral_delta(c))
		m_max = maxf(m_max, BD.get_npc_trait_moral_delta(c))
	_check("traits: prod_mult min 0,90 max 1,155 (+-1e-9)", absf(p_min - 0.90) <= 1e-9 and absf(p_max - 1.155) <= 1e-9, "%.12f %.12f" % [p_min, p_max])
	_check("traits: moral_delta min -1 max +4", m_min == -1.0 and m_max == 4.0, "%.2f %.2f" % [m_min, m_max])
	# Volet D : Lien
	var bond_in: Array[int] = [-5, 0, 99, 100, 249, 250, 449, 450, 700, 999, 1000, 1500]
	var bond_want: Array[int] = [0, 0, 0, 1, 1, 2, 2, 3, 4, 4, 5, 5]
	var bond_got: Array[int] = []
	for v: int in bond_in:
		bond_got.append(BD.get_bond_tier(v))
	_check("lien: get_bond_tier sur 12 valeurs de reference", bond_got == bond_want, str(bond_got))
	# Volet D : synergie
	for c: Array in [[[250, 250], 100.0, 1], [[250, 250, 250], 100.0, 3], [[250, 249, 1000], 50.0, 1], [[300, 300, 300], 20.0, 3], [[1000, 1000, 1000], 19.9, 0], [[250, 250, 250, 250], 100.0, 3], [[], 100.0, 0]]:
		var n: int = BD.count_active_follower_synergy_pairs(_bonds(c[0]), c[1])
		_check("synergie: (%s, %s) == %d" % [str(c[0]), str(c[1]), c[2]], n == c[2], str(n))
	# Volet D : Grand Atre
	for c: Array in [[1, 600, 40], [2, 2400, 80], [3, 5400, 120], [4, 9600, 160]]:
		var g: int = BD.compute_atre_upgrade_gold_cost(c[0])
		var mi: int = BD.compute_atre_upgrade_mineral_cost(c[0])
		var t0: int = BD.compute_atre_upgrade_tier0_cost(c[0])
		_check("atre: depuis Nv%d -> %d Or, %d minerai, %d tier 0" % [c[0], c[1], c[2], c[2]], g == c[1] and mi == c[2] and t0 == c[2], "%d %d %d" % [g, mi, t0])
	_check("atre: ATRE_RADIUS_TILES", BD.ATRE_RADIUS_TILES == [12, 18, 24, 30, 36], str(BD.ATRE_RADIUS_TILES))
	_check("atre: ATRE_WORK_POSTS_CAP", BD.ATRE_WORK_POSTS_CAP == [6, 10, 16, 23, 30], str(BD.ATRE_WORK_POSTS_CAP))
	_check("atre: ATRE_NPC_CAP", BD.ATRE_NPC_CAP == [5, 10, 16, 23, 30], str(BD.ATRE_NPC_CAP))
	# Volet D : Lanterne-Mere
	_check("lanterne: LANTERN_UPGRADE_BRAISE_COST", BD.LANTERN_UPGRADE_BRAISE_COST == [0, 90, 300, 600, 1050], str(BD.LANTERN_UPGRADE_BRAISE_COST))
	_check("lanterne: LANTERN_UPGRADE_COAL_COST", BD.LANTERN_UPGRADE_COAL_COST == [0, 10, 25, 50, 80], str(BD.LANTERN_UPGRADE_COAL_COST))
	_check("lanterne: LANTERN_UPGRADE_GOLD_COST tout a 0", BD.LANTERN_UPGRADE_GOLD_COST == [0, 0, 0, 0, 0], str(BD.LANTERN_UPGRADE_GOLD_COST))
	_check("lanterne: LANTERN_REQ_MAX_VOC_LEVEL", BD.LANTERN_REQ_MAX_VOC_LEVEL == [1, 5, 15, 25, 35], str(BD.LANTERN_REQ_MAX_VOC_LEVEL))
	_check("lanterne: LANTERN_REQ_ISOLAT", BD.LANTERN_REQ_ISOLAT == [1, 1, 2, 3, 4], str(BD.LANTERN_REQ_ISOLAT))
	# Volet D : auto-assignation
	for c: Array in [[0, 60, false, 2.00], [30, 60, false, 1.25], [60, 60, false, 0.10], [10, 0, false, 1.00], [5, 60, true, 1.00]]:
		var need: float = BD.compute_village_need(c[0], c[1], c[2])
		_check("besoin: compute_village_need(%d, %d, %s) == %.2f" % [c[0], c[1], str(c[2]), c[3]], absf(need - c[3]) <= 1e-9, "%.12f" % need)
	for c: Array in [[2, true, true, 0, 60, false, 2.50], [5, false, false, 30, 60, false, 2.00]]:
		var sc: float = BD.compute_auto_assign_score(c[0], c[1], c[2], c[3], c[4], c[5])
		_check("score: compute_auto_assign_score(%d, %s, %s, %d, %d, %s) == %.2f" % [c[0], str(c[1]), str(c[2]), c[3], c[4], str(c[5]), c[6]], absf(sc - c[6]) <= 1e-9, "%.12f" % sc)
	# Volet D : Griffe Tete-en-l'air
	var tea_max: float = BD.GRIFFE_DEFS[BD.TraitId.TETE_EN_L_AIR]["price_mult_max_override"]
	var g_sell: int = Eco.sell_price(48, 0, 0, 1, tea_max)
	_check("griffe: Tete-en-l'air 48 -> vente 55, rachat 33", g_sell == 55 and Eco.buyback_price(g_sell) == 33, "%d %d" % [g_sell, Eco.buyback_price(g_sell)])
	var gain_max: int = -1000000
	for item: String in BB.ITEM_BASE_GOLD:
		for iso in 5:
			var p: int = BB.ITEM_BASE_GOLD[item]
			gain_max = maxi(gain_max, Eco.buyback_price(Eco.sell_price(p, iso, 0, 1, tea_max)) - Eco.sell_price(p, iso, 2, 1))
	_check("griffe: anti-arbitrage plafond 1,15, gain max == -1", gain_max == -1, str(gain_max))
	# Volet D : stocks
	_check("stock: stock_max(mat, 1) == 60", Eco.stock_max(true, 1) == 60, str(Eco.stock_max(true, 1)))
	_check("stock: stock_max(prod, 1) == 30", Eco.stock_max(false, 1) == 30, str(Eco.stock_max(false, 1)))
	var cos: int = BD.TraitId.COSTAUD
	for c: Array in [[true, [69, 115, 161]], [false, [34, 57, 80]]]:
		var got_s: Array[int] = []
		for lvl in [1, 2, 3]:
			got_s.append(Eco.stock_max(c[0], lvl, cos))
		_check("stock: Griffe Costaud %s Nv1-3 == %s" % ["materiaux" if c[0] else "produits", str(c[1])], got_s == _bonds(c[1]), str(got_s))
	_check("stock: Griffe Bosseur materiaux Nv1 == 60", Eco.stock_max(true, 1, BD.TraitId.BOSSEUR) == 60, str(Eco.stock_max(true, 1, BD.TraitId.BOSSEUR)))
	_check("stock: stock_target(60, EQUILIBRE) == 36", Eco.stock_target(60, "EQUILIBRE") == 36, str(Eco.stock_target(60, "EQUILIBRE")))
	_check("stock: stock_target(30, EQUILIBRE) == 18", Eco.stock_target(30, "EQUILIBRE") == 18, str(Eco.stock_target(30, "EQUILIBRE")))
	# Jalon 2 : npc_rate
	var CO: int = BD.TraitId.COSTAUD
	var BO: int = BD.TraitId.BOSSEUR
	var TE: int = BD.TraitId.TETE_EN_L_AIR
	var BE: int = BD.TraitId.BOUT_EN_TRAIN
	for c: Array in [["extraction 2* NORMAL 80", BB.PROD_BASE_EXTRACTION_PER_HOUR, 2, "NORMAL", 80, false, false, [], 5.0],
			["extraction 1* NORMAL 80", BB.PROD_BASE_EXTRACTION_PER_HOUR, 1, "NORMAL", 80, false, false, [], 4.0],
			["extraction 1* FORGE_ARDENTE 34 [COSTAUD, BOSSEUR]", BB.PROD_BASE_EXTRACTION_PER_HOUR, 1, "FORGE_ARDENTE", 34, false, false, [CO, BO], 4.5045],
			["forge 2* NORMAL 90 outil brise", BB.PROD_BASE_FORGE_PER_HOUR, 2, "NORMAL", 90, false, true, [], 1.725],
			["extraction en greve", BB.PROD_BASE_EXTRACTION_PER_HOUR, 2, "NORMAL", 80, true, false, [], 0.0]]:
		var rate: float = Eco.npc_rate(c[1], c[2], c[3], c[4], c[5], c[6], _bonds(c[7]))
		_check("npc_rate: %s == %s" % [c[0], str(c[8])], absf(rate - c[8]) <= 1e-9, "%.12f" % rate)
	# Jalon 2 : grève (scénario 5 du Volet B)
	var st: Dictionary = {"moral": 80, "on_strike": false}
	var seq: Array[int] = []
	var strikes: Array[bool] = []
	for i in 7:
		st = Eco.npc_daily_tick(st["moral"], st["on_strike"], "FORGE_ARDENTE", "MISSED", 1, [], 0.0)
		seq.append(st["moral"])
		strikes.append(st["on_strike"])
	_check("greve: FORGE_ARDENTE/MISSED depuis 80 == 54 35 20 9 50 32 18", seq == _bonds([54, 35, 20, 9, 50, 32, 18]), str(seq))
	_check("greve: en greve aux ticks 4 et 7 seulement", strikes == [false, false, false, true, false, false, true], str(strikes))
	var out0: Dictionary = _ticks(0, true, "FORGE_ARDENTE", "MISSED", [BO], 0.0, 1)
	_check("greve: depuis 0 en greve [BOSSEUR] -> 50, sortie", out0["moral"] == 50 and not out0["on_strike"], str(out0))
	# Jalon 2 : points fixes (60 ticks depuis 80, EATEN, maison 1)
	for c: Array in [["NORMAL [BOSSEUR]", "NORMAL", [BO], 0.0, 78], ["NORMAL [TETE_EN_L_AIR, BOUT_EN_TRAIN]", "NORMAL", [TE, BE], 0.0, 94],
			["NORMAL Griffe +2", "NORMAL", [], 2.0, 86], ["FORGE_ARDENTE Griffe +2", "FORGE_ARDENTE", [], 2.0, 42],
			["FORGE_ARDENTE [TETE_EN_L_AIR, BOUT_EN_TRAIN]", "FORGE_ARDENTE", [TE, BE], 0.0, 50], ["FORGE_ARDENTE [TETE_EN_L_AIR, BOUT_EN_TRAIN] Griffe +2", "FORGE_ARDENTE", [TE, BE], 2.0, 58]]:
		var fp: Dictionary = _ticks(80, false, c[1], "EATEN", c[2], c[3], 60)
		_check("point fixe: %s == %d" % [c[0], c[4]], fp["moral"] == c[4] and not fp["on_strike"], str(fp))
	var off: int = _ticks(80, false, "NORMAL", "OFFLINE", [], 0.0, 1)["moral"]
	_check("moral: NORMAL OFFLINE depuis 80 -> 74 (1 tick)", off == 74, str(off))
	# Jalon 2 : griffe_moral_bonus
	_check("griffe moral: un gerant [BOUT_EN_TRAIN] -> 2", Eco.griffe_moral_bonus([[BE]]) == 2.0, str(Eco.griffe_moral_bonus([[BE]])))
	_check("griffe moral: deux gerants [BOUT_EN_TRAIN] -> 2", Eco.griffe_moral_bonus([[BE], [BE]]) == 2.0, str(Eco.griffe_moral_bonus([[BE], [BE]])))
	_check("griffe moral: [COSTAUD, BOUT_EN_TRAIN] -> 0", Eco.griffe_moral_bonus([[CO, BE]]) == 0.0, str(Eco.griffe_moral_bonus([[CO, BE]])))
	# Jalon 2 : DAG A (exemple 3.3 du Volet B)
	var a_mat: Dictionary = _shop(6, 60, 36, 4.0, 2, 0, 0)
	var a_tav: Dictionary = _shop(0, 30, 18, 0.0, 8, 0, 0)
	var a_for: Dictionary = _shop(4, 30, 18, 2.5, 12, 144, 144)
	for c: Array in [[1.0, 2, 1.0, 0.0, 1, 2, 6, false, 1, 4, 12, 2], [6.0, 14, 6.0, 0.0, 9, 18, 2, true, 6, 7, 72, 14], [12.0, 28, 11.3333, 0.6667, 17, 34, 0, true, 12, 9, 144, 28]]:
		var ra: Dictionary = Dag.resolve(c[0], 0, a_mat, a_tav, a_for)
		var bad: String = _diff(ra, [["MAT", "added", c[1]], ["FORGE", "t_full", c[2]], ["FORGE", "t_glean", c[3]], ["FORGE", "added", c[4]], ["FORGE", "consumed", c[5]],
			["MAT", "stock_final", c[6]], ["MAT", "fiche", c[7]], ["FORGE", "sold", c[8]], ["FORGE", "stock_final", c[9]], ["FORGE", "revenue", c[10]], ["FORGE", "tax", c[11]]])
		var dispo1: int = a_mat["stock"] + ra["MAT"]["added"]
		if dispo1 != c[1] + 6:
			bad += "dispo1=%d " % dispo1
		_check("dag A: t_eff %d h" % int(c[0]), bad == "", bad)
	var t48: float = ClockS.offline_hours(D0, D0 + 48 * 3600)
	_check("dag A: 48 h -> t_eff 12, resultat identique a 12 h", t48 == 12.0 and Dag.resolve(t48, 0, a_mat, a_tav, a_for) == Dag.resolve(12.0, 0, a_mat, a_tav, a_for), str(t48))
	# Jalon 2 : DAG B (village de la tranche, 12 h, stocks vides)
	var rb: Dictionary = Dag.resolve(12.0, 0, _shop(0, 60, 36, 5.0, 2, 8, 8), _shop(0, 30, 18, 3.0, 8, 48, 48), _shop(0, 30, 18, 2.5, 12, 144, 144), 5)
	var bad_b: String = _diff(rb, [["MAT", "added", 36], ["MAT", "moral_bonus", 0],
		["TAVERN", "t_full", 10.0], ["TAVERN", "t_glean", 2.0], ["TAVERN", "added", 6], ["TAVERN", "consumed", 12],
		["FORGE", "t_full", 8.0], ["FORGE", "t_glean", 4.0], ["FORGE", "added", 13], ["FORGE", "consumed", 24],
		["MAT", "stock_final", 0], ["MAT", "sold", 0], ["MAT", "fiche", true],
		["TAVERN", "sold", 6], ["TAVERN", "price", 8], ["TAVERN", "revenue", 48], ["TAVERN", "wages", 21], ["TAVERN", "tax", 9], ["TAVERN", "treasury", 18], ["TAVERN", "stock_final", 0], ["TAVERN", "fiche", true],
		["FORGE", "sold", 12], ["FORGE", "price", 12], ["FORGE", "revenue", 144], ["FORGE", "wages", 64], ["FORGE", "tax", 28], ["FORGE", "treasury", 52], ["FORGE", "stock_final", 1], ["FORGE", "fiche", true],
		["", "meals", 5]])
	_check("dag B: village de la tranche, 12 h", bad_b == "", bad_b)
	# Jalon 2 : DAG C (extracteur en grève)
	var rc: Dictionary = Dag.resolve(12.0, 0, _shop(0, 60, 36, 0.0, 2, 8, 8), _shop(0, 30, 18, 3.0, 8, 48, 48), _shop(0, 30, 18, 2.5, 12, 144, 144), 5)
	var bad_c: String = _diff(rc, [["TAVERN", "t_glean", 12.0], ["TAVERN", "added", 5], ["TAVERN", "consumed", 0], ["FORGE", "added", 4],
		["TAVERN", "sold", 5], ["FORGE", "sold", 4], ["", "meals", 5]])
	_check("dag C: extracteur en greve, 5 bouillons pour 5 PNJ", bad_c == "", bad_c)
	# Jalon 2 : DAG D (stocks presque pleins)
	var rd: Dictionary = Dag.resolve(12.0, 0, _shop(55, 60, 36, 5.0, 2, 8, 8), _shop(0, 30, 18, 3.0, 8, 48, 48), _shop(28, 30, 18, 2.5, 12, 144, 144), 5)
	var bad_d: String = _diff(rd, [["MAT", "added", 5], ["MAT", "moral_bonus", 20], ["TAVERN", "added", 6], ["TAVERN", "moral_bonus", 0],
		["FORGE", "pot_prod", 18], ["FORGE", "added", 2], ["FORGE", "consumed", 4], ["FORGE", "moral_bonus", 21],
		["MAT", "before_sale", 44], ["MAT", "sold", 4], ["MAT", "revenue", 8], ["MAT", "tax", 1], ["MAT", "stock_final", 40], ["MAT", "fiche", false],
		["FORGE", "sold", 12], ["FORGE", "stock_final", 18], ["FORGE", "fiche", false]])
	_check("dag D: stocks presque pleins", bad_d == "", bad_d)
	# Jalon 2 : DAG E (isolat 2, pot Forge entamé)
	var re: Dictionary = Dag.resolve(12.0, 2, _shop(0, 60, 36, 5.0, 2, 10, 10), _shop(0, 30, 18, 3.0, 8, 60, 60), _shop(0, 30, 18, 2.5, 12, 179, 100), 5)
	var bad_e: String = _diff(re, [["TAVERN", "price", 10], ["TAVERN", "sold", 6], ["TAVERN", "revenue", 60], ["TAVERN", "tax", 12],
		["FORGE", "price", 15], ["FORGE", "sold", 6], ["FORGE", "revenue", 90], ["FORGE", "wages", 40], ["FORGE", "tax", 18], ["FORGE", "treasury", 32], ["FORGE", "pot_left", 10], ["FORGE", "stock_final", 7]])
	_check("dag E: isolat 2, pot Forge 100", bad_e == "", bad_e)
	# Jalon 2 : DAG F (t_eff 0)
	var rf: Dictionary = Dag.resolve(0.0, 0, _shop(10, 60, 36, 5.0, 2, 8, 8), _shop(3, 30, 18, 3.0, 8, 48, 48), _shop(5, 30, 18, 2.5, 12, 144, 144), 5)
	var bad_f: String = _diff(rf, [["MAT", "added", 0], ["TAVERN", "added", 0], ["FORGE", "added", 0], ["MAT", "sold", 0], ["TAVERN", "sold", 0], ["FORGE", "sold", 0],
		["MAT", "fiche", false], ["", "meals", 0]])
	_check("dag F: t_eff 0", bad_f == "", bad_f)
	# Jalon 2 : resume, absence de 7 jours, extracteur en grève
	var t10: int = D0 + 10 * 3600
	var vs: Dictionary = _village(t10)
	vs["npcs"][0]["moral"] = 10
	vs["npcs"][0]["on_strike"] = true
	var out7: Dictionary = Dag.resume(vs, t10 + 7 * 86400)
	var v7: Dictionary = out7["village"]
	_check("resume: 7 j -> t_eff 12 et un seul tick", out7["t_eff"] == 12.0 and out7["ticked"] and v7["last_tick_day"] == ClockS.day_index(t10 + 7 * 86400, 0), "%s %s %d" % [str(out7["t_eff"]), str(out7["ticked"]), v7["last_tick_day"]])
	_check("resume: extracteur EATEN -> 50, sortie de greve ; 4 autres a 80", _morals(v7) == _bonds([50, 80, 80, 80, 80]) and not v7["npcs"][0]["on_strike"], str(_morals(v7)))
	_check("resume: entree non modifiee", vs["npcs"][0]["moral"] == 10 and vs["last_save_utc"] == t10)
	# Jalon 2 : resume, village B sur 7 jours
	var vb: Dictionary = Dag.resume(_village(t10), t10 + 7 * 86400)["village"]
	_check("resume B: 5 PNJ a 80", _morals(vb) == _bonds([80, 80, 80, 80, 80]), str(_morals(vb)))
	_check("resume B: player_gold +37", vb["player_gold"] == 37, str(vb["player_gold"]))
	var tre: Array[int] = _bonds([vb["shops"]["MAT"]["treasury"], vb["shops"]["TAVERN"]["treasury"], vb["shops"]["FORGE"]["treasury"]])
	_check("resume B: tresoreries 150 / 168 / 202", tre == _bonds([150, 168, 202]), str(tre))
	# Jalon 2 : resume, gérant de la Taverne Bout-en-train
	var vg: Dictionary = _village(t10)
	vg["npcs"][1]["traits"] = [BE]
	var mg: Array[int] = _morals(Dag.resume(vg, t10 + 7 * 86400)["village"])
	_check("resume: gerant Taverne [BOUT_EN_TRAIN] 84, 4 autres 82", mg == _bonds([82, 84, 82, 82, 82]), str(mg))
	# Jalon 2 : resume, nuit et horloge
	var on: Dictionary = Dag.resume(_village(D0 + 23 * 3600), D0 + 27 * 3600)
	_check("resume: 23 h -> 27 h, t_eff 4, aucun tick", is_equal_approx(on["t_eff"], 4.0) and not on["ticked"], "%s %s" % [str(on["t_eff"]), str(on["ticked"])])
	var om: Dictionary = Dag.resume(_village(D0 + 23 * 3600), D0 + 29 * 3600)
	_check("resume: 23 h -> 29 h, un tick", om["ticked"])
	var vback: Dictionary = _village(D0 + 30 * 3600)
	var ob2: Dictionary = Dag.resume(vback, D0 + 28 * 3600)
	_check("resume: horloge reculee de 2 h, t_eff 0, aucun tick, village inchange", ob2["t_eff"] == 0.0 and not ob2["ticked"] and ob2["village"] == vback, "%s %s" % [str(ob2["t_eff"]), str(ob2["ticked"])])
	# Garde-fou
	var ba_script: Script = load("res://balance/balance_a.gd") # BA.get_script_constant_map() est refusé par le parseur (appel non statique sur une classe)
	_check("garde-fou: BalanceA sans WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS", not ba_script.get_script_constant_map().has("WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS"))
	print("--- %s (%d echec(s))" %["TOUS PASS" if _fails == 0 else "ECHEC", _fails])
	quit(1 if _fails > 0 else 0)
