extends SceneTree
# godot --headless --script res://tests/headless/run_all.gd
const BA = preload("res://balance/balance_a.gd")
const RngS = preload("res://autoload/Rng.gd")
const ClockS = preload("res://autoload/Clock.gd")
const BB = preload("res://balance/balance_b.gd")
const BC = preload("res://balance/balance_c.gd")
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
	# Garde-fou
	var ba_script: Script = load("res://balance/balance_a.gd") # BA.get_script_constant_map() est refusé par le parseur (appel non statique sur une classe)
	_check("garde-fou: BalanceA sans WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS", not ba_script.get_script_constant_map().has("WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS"))
	print("--- %s (%d echec(s))" %["TOUS PASS" if _fails == 0 else "ECHEC", _fails])
	quit(1 if _fails > 0 else 0)
