extends SceneTree
# godot --headless --script res://tests/headless/run_all.gd
const BA = preload("res://balance/balance_a.gd")
const RngS = preload("res://autoload/Rng.gd")
const ClockS = preload("res://autoload/Clock.gd")
const BB = preload("res://balance/balance_b.gd")
const BC = preload("res://balance/balance_c.gd")
const BD = preload("res://balance/balance_d.gd")
const Eco = preload("res://scripts/economy.gd")
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
	# Garde-fou
	var ba_script: Script = load("res://balance/balance_a.gd") # BA.get_script_constant_map() est refusé par le parseur (appel non statique sur une classe)
	_check("garde-fou: BalanceA sans WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS", not ba_script.get_script_constant_map().has("WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS"))
	print("--- %s (%d echec(s))" %["TOUS PASS" if _fails == 0 else "ECHEC", _fails])
	quit(1 if _fails > 0 else 0)
