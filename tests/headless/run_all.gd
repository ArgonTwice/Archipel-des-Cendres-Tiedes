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
const SaveS = preload("res://autoload/SaveManager.gd")
const NewGameS = preload("res://scripts/new_game.gd")
const FoldModeS = preload("res://scripts/ui/fold_mode.gd")
const VeilleeReportS = preload("res://scripts/ui/veillee_report.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const NpcS = preload("res://scripts/village/npc.gd")
const FONT_PATH: String = "res://assets/fonts/silkscreen/Silkscreen-Regular.ttf"
const OFL_PATH: String = "res://assets/fonts/silkscreen/OFL.txt"
const THEME_PATH: String = "res://assets/ui/theme.tres"
const TEST_SAVE_DIR: String = "user://test_saves/"
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
	return {"post": post, "stars": 2, "cadence": "NORMAL", "moral": moral, "on_strike": false, "tool_broken": false, "tool_durability": BB.TOOL_DURABILITY_MAX, "traits": [], "house_lvl": 1, "manages": manages}

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

func _durs(v: Dictionary) -> Array[float]:
	var out: Array[float] = []
	for npc: Dictionary in v["npcs"]:
		out.append(npc["tool_durability"])
	return out

func _floats(values: Array) -> Array[float]:
	var out: Array[float] = []
	out.assign(values)
	return out

func _shop_vals(v: Dictionary, key: String) -> Array[int]:
	return _bonds([v["shops"]["MAT"][key], v["shops"]["TAVERN"][key], v["shops"]["FORGE"][key]])

func _dag_vals(out: Dictionary, key: String) -> Array[int]:
	return _bonds([out["dag"]["MAT"][key], out["dag"]["TAVERN"][key], out["dag"]["FORGE"][key]])

func _draws(world_seed: int) -> Array:
	var out: Array = []
	for i in 5:
		out.append(NewGameS.draw_traits(RngS.make_rng(world_seed, "npc/%d" % i)))
	return out

# Fichiers .gd sous dir, parcours récursif, triés.
func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f: String in DirAccess.get_files_at(dir):
		if f.get_extension() == "gd":
			out.append(dir.path_join(f))
	for sub: String in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(sub)))
	out.sort()
	return out

func _clean_saves() -> void:
	for f: String in SaveS.SLOT_FILES:
		if FileAccess.file_exists(TEST_SAVE_DIR.path_join(f)):
			DirAccess.remove_absolute(TEST_SAVE_DIR.path_join(f))

func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()

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
	_check("resume B: player_gold +13 (taxes 37 - frais 24)", vb["player_gold"] == 13, str(vb["player_gold"]))
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
	# Jalon 3 : frais fixes et usure
	for c: Array in [[[1, 1, 1], 24], [[2, 1, 3], 48], [[1, 2, 2], 40], [[], 0]]:
		var fc: int = Eco.daily_fixed_sink(_bonds(c[0]))
		_check("frais: daily_fixed_sink(%s) == %d" % [str(c[0]), c[1]], fc == c[1], str(fc))
	var PE: int = BD.TraitId.PERFECTIONNISTE
	for c: Array in [["[]", [], 20.0], ["[PERFECTIONNISTE]", [PE], 15.0], ["[PERFECTIONNISTE, COSTAUD]", [PE, CO], 15.0], ["[BOUT_EN_TRAIN]", [BE], 20.0]]:
		var wr: float = Eco.tool_wear_per_day(_bonds(c[1]))
		_check("usure: tool_wear_per_day(%s) == %.1f" % [c[0], c[2]], absf(wr - c[2]) <= 1e-9, str(wr))
	var w7: int = t10 + 7 * 86400
	# R1 : village B
	var o1: Dictionary = Dag.resume(_village(t10), w7)
	var v1: Dictionary = o1["village"]
	_check("R1: player_gold 13, frais 24, 0 outil remplace", v1["player_gold"] == 13 and o1["fixed_cost_paid"] == 24 and o1["tools_replaced"] == 0, "%d %d %d" % [v1["player_gold"], o1["fixed_cost_paid"], o1["tools_replaced"]])
	_check("R1: durabilites 80 / 80 / 80 / 100 / 100", _durs(v1) == _floats([80.0, 80.0, 80.0, 100.0, 100.0]), str(_durs(v1)))
	_check("R1: tresoreries 150 / 168 / 202, Moral 5 x 80", _shop_vals(v1, "treasury") == _bonds([150, 168, 202]) and _morals(v1) == _bonds([80, 80, 80, 80, 80]), "%s %s" % [str(_shop_vals(v1, "treasury")), str(_morals(v1))])
	# R2 : frais plafonnés par l'Or
	var i2: Dictionary = _village(t10)
	i2["npcs"][0]["moral"] = 10
	i2["npcs"][0]["on_strike"] = true
	var o2: Dictionary = Dag.resume(i2, w7)
	var v2: Dictionary = o2["village"]
	_check("R2: frais 17, player_gold 0", o2["fixed_cost_paid"] == 17 and v2["player_gold"] == 0, "%d %d" % [o2["fixed_cost_paid"], v2["player_gold"]])
	_check("R2: durabilites 100 / 80 / 80 / 100 / 100, Moral 50 / 80 / 80 / 80 / 80", _durs(v2) == _floats([100.0, 80.0, 80.0, 100.0, 100.0]) and _morals(v2) == _bonds([50, 80, 80, 80, 80]), "%s %s" % [str(_durs(v2)), str(_morals(v2))])
	# R3 : niveaux 2 / 1 / 3, 500 Or
	var i3: Dictionary = _village(t10)
	i3["shops"]["MAT"]["lvl"] = 2
	i3["shops"]["FORGE"]["lvl"] = 3
	i3["player_gold"] = 500
	var o3: Dictionary = Dag.resume(i3, w7)
	_check("R3: frais 48, player_gold 489", o3["fixed_cost_paid"] == 48 and o3["village"]["player_gold"] == 489, "%d %d" % [o3["fixed_cost_paid"], o3["village"]["player_gold"]])
	# R4 : outil de l'extracteur brisé, stock Forge 3
	var i4: Dictionary = _village(t10)
	i4["npcs"][0]["tool_durability"] = 0.0
	i4["npcs"][0]["tool_broken"] = true
	i4["shops"]["FORGE"]["stock"] = 3
	var o4: Dictionary = Dag.resume(i4, w7)
	var v4: Dictionary = o4["village"]
	_check("R4: 1 outil remplace, extracteur a 80 non brise", o4["tools_replaced"] == 1 and v4["npcs"][0]["tool_durability"] == 80.0 and not v4["npcs"][0]["tool_broken"], "%d %s" % [o4["tools_replaced"], str(v4["npcs"][0]["tool_durability"])])
	var bad4: String = _diff(o4["dag"], [["MAT", "added", 36], ["FORGE", "before_sale", 15], ["FORGE", "sold", 11], ["FORGE", "tax", 26]])
	_check("R4: DAG MAT +36, Forge 15 avant vente, 11 ventes (pot 132), taxe 26", bad4 == "", bad4)
	_check("R4: stock Forge 4, player_gold 13, tresorerie Forge 202", v4["shops"]["FORGE"]["stock"] == 4 and v4["player_gold"] == 13 and v4["shops"]["FORGE"]["treasury"] == 202, "%d %d %d" % [v4["shops"]["FORGE"]["stock"], v4["player_gold"], v4["shops"]["FORGE"]["treasury"]])
	# R5 : outil de l'extracteur brisé, stock Forge 0
	var i5: Dictionary = _village(t10)
	i5["npcs"][0]["tool_durability"] = 0.0
	i5["npcs"][0]["tool_broken"] = true
	var o5: Dictionary = Dag.resume(i5, w7)
	var v5: Dictionary = o5["village"]
	_check("R5: 0 outil remplace, extracteur toujours brise a 0", o5["tools_replaced"] == 0 and v5["npcs"][0]["tool_broken"] and v5["npcs"][0]["tool_durability"] == 0.0, "%d %s" % [o5["tools_replaced"], str(v5["npcs"][0]["tool_durability"])])
	var bad5: String = _diff(o5["dag"], [["MAT", "added", 21], ["FORGE", "added", 7], ["FORGE", "sold", 7]])
	_check("R5: DAG MAT +21 (rate 3,0), Forge +7, 7 ventes", bad5 == "", bad5)
	_check("R5: pot Forge 60, tresorerie Forge 181, player_gold 1", v5["shops"]["FORGE"]["pot"] == 60 and v5["shops"]["FORGE"]["treasury"] == 181 and v5["player_gold"] == 1, "%d %d %d" % [v5["shops"]["FORGE"]["pot"], v5["shops"]["FORGE"]["treasury"], v5["player_gold"]])
	# R6 : stock Forge 1, extracteur et forgeron brisés
	var i6: Dictionary = _village(t10)
	for n: int in [0, 2]:
		i6["npcs"][n]["tool_durability"] = 0.0
		i6["npcs"][n]["tool_broken"] = true
	i6["shops"]["FORGE"]["stock"] = 1
	var o6: Dictionary = Dag.resume(i6, w7)
	var v6: Dictionary = o6["village"]
	_check("R6: 1 outil remplace (extracteur), durabilites 80 / 80 / 0 / 100 / 100, forgeron brise", o6["tools_replaced"] == 1 and _durs(v6) == _floats([80.0, 80.0, 0.0, 100.0, 100.0]) and v6["npcs"][2]["tool_broken"], "%d %s" % [o6["tools_replaced"], str(_durs(v6))])
	_check("R6: stocks 0 / 0 / 0, tresoreries 154 / 168 / 197, player_gold 12", _shop_vals(v6, "stock") == _bonds([0, 0, 0]) and _shop_vals(v6, "treasury") == _bonds([154, 168, 197]) and v6["player_gold"] == 12, "%s %s %d" % [str(_shop_vals(v6, "stock")), str(_shop_vals(v6, "treasury")), v6["player_gold"]])
	# R7 : gérant de la Forge Perfectionniste à durabilité 30
	var i7: Dictionary = _village(t10)
	i7["npcs"][2]["traits"] = [PE]
	i7["npcs"][2]["tool_durability"] = 30.0
	var v7b: Dictionary = Dag.resume(i7, w7)["village"]
	_check("R7: forgeron [PERFECTIONNISTE] 30 -> 15, non brise, Moral 81", v7b["npcs"][2]["tool_durability"] == 15.0 and not v7b["npcs"][2]["tool_broken"] and v7b["npcs"][2]["moral"] == 81, "%s %d" % [str(v7b["npcs"][2]["tool_durability"]), v7b["npcs"][2]["moral"]])
	# R8 : sans tick
	var i8: Dictionary = _village(D0 + 23 * 3600)
	i8["player_gold"] = 100
	i8["npcs"][0]["tool_durability"] = 0.0
	i8["npcs"][0]["tool_broken"] = true
	i8["shops"]["FORGE"]["stock"] = 3
	var o8: Dictionary = Dag.resume(i8, D0 + 27 * 3600)
	var v8: Dictionary = o8["village"]
	_check("R8: sans tick, frais 0, 0 outil remplace, extracteur brise", not o8["ticked"] and o8["fixed_cost_paid"] == 0 and o8["tools_replaced"] == 0 and v8["npcs"][0]["tool_broken"], "%s %d %d" % [str(o8["ticked"]), o8["fixed_cost_paid"], o8["tools_replaced"]])
	_check("R8: player_gold 112, stocks 0 / 2 / 0", v8["player_gold"] == 112 and _shop_vals(v8, "stock") == _bonds([0, 2, 0]), "%d %s" % [v8["player_gold"], str(_shop_vals(v8, "stock"))])
	# R9 : 7 retours quotidiens
	var v9: Dictionary = _village(t10)
	var g9: Array[int] = []
	var d9: Array[float] = []
	var p9: Array[int] = []
	var s9: Array[int] = []
	var tr9: Array[int] = []
	var same9: bool = true
	var broken5: bool = false
	for d in range(1, 8):
		var o9: Dictionary = Dag.resume(v9, t10 + d * 86400)
		v9 = o9["village"]
		g9.append(v9["player_gold"])
		d9.append(v9["npcs"][0]["tool_durability"])
		p9.append(o9["tools_replaced"])
		s9.append(v9["shops"]["FORGE"]["stock"])
		tr9.append(v9["shops"]["FORGE"]["treasury"])
		same9 = same9 and v9["npcs"][1]["tool_durability"] == d9[-1] and v9["npcs"][2]["tool_durability"] == d9[-1]
		if d == 5:
			broken5 = v9["npcs"][0]["tool_broken"] and v9["npcs"][1]["tool_broken"] and v9["npcs"][2]["tool_broken"]
	_check("R9: player_gold 13 / 26 / 39 / 52 / 65 / 77 / 90", g9 == _bonds([13, 26, 39, 52, 65, 77, 90]), str(g9))
	_check("R9: durabilite des 3 producteurs 80 / 60 / 40 / 20 / 0 (brises) / 80 / 60", d9 == _floats([80.0, 60.0, 40.0, 20.0, 0.0, 80.0, 60.0]) and same9 and broken5, "%s %s %s" % [str(d9), str(same9), str(broken5)])
	_check("R9: outils remplaces 0 / 0 / 0 / 0 / 0 / 3 / 0", p9 == _bonds([0, 0, 0, 0, 0, 3, 0]), str(p9))
	_check("R9: stock Forge 1 / 2 / 3 / 4 / 5 / 6 / 7", s9 == _bonds([1, 2, 3, 4, 5, 6, 7]), str(s9))
	_check("R9: tresorerie Forge 202 / 254 / 306 / 358 / 410 / 464 / 516", tr9 == _bonds([202, 254, 306, 358, 410, 464, 516]), str(tr9))
	# Jalon 3 : SaveManager
	_clean_saves()
	var S: Dictionary = {"format": 1, "seq": 1, "world_seed": RngS.fnv1a64("archipel"), "village": _village(t10)}
	var rt: Dictionary = SaveS.unpack(SaveS.pack(S))
	_check("save: unpack(pack(S)) == S", rt == S)
	_check("save: types conserves (tool_durability float, player_gold int)", typeof(rt["village"]["npcs"][0]["tool_durability"]) == TYPE_FLOAT and typeof(rt["village"]["player_gold"]) == TYPE_INT)
	_check("save: pack deterministe", SaveS.pack(S) == SaveS.pack(rt))
	_check("save: graine, _seq(world_seed, map, 100) identique apres aller-retour", _seq(rt["world_seed"], "map", 100) == _seq(S["world_seed"], "map", 100))
	var seqs: Array[int] = []
	var slots: Array[String] = []
	for i in 3:
		var sv: Dictionary = SaveS.save(S, t10, TEST_SAVE_DIR)
		seqs.append(sv["seq"])
		slots.append(SaveS.slot_path(sv["seq"], TEST_SAVE_DIR).get_file())
	var path_a: String = TEST_SAVE_DIR.path_join("save_a.dat")
	var path_b: String = TEST_SAVE_DIR.path_join("save_b.dat")
	var in_a: int = SaveS.unpack(FileAccess.get_file_as_bytes(path_a)).get("seq", -1)
	var in_b: int = SaveS.unpack(FileAccess.get_file_as_bytes(path_b)).get("seq", -1)
	_check("save: rotation seq 1 / 2 / 3 dans save_a / save_b / save_a", seqs == _bonds([1, 2, 3]) and slots == ["save_a.dat", "save_b.dat", "save_a.dat"] and in_a == 3 and in_b == 2, "%s %s %d %d" % [str(seqs), str(slots), in_a, in_b])
	_check("save: load_latest rend seq 3", SaveS.load_latest(TEST_SAVE_DIR).get("seq", -1) == 3)
	var bytes_a: PackedByteArray = FileAccess.get_file_as_bytes(path_a)
	bytes_a[SaveS.HASH_SIZE + 5] ^= 0xFF
	_write_bytes(path_a, bytes_a)
	_check("save: save_a corrompu -> load_latest rend seq 2", SaveS.load_latest(TEST_SAVE_DIR).get("seq", -1) == 2)
	_write_bytes(path_b, FileAccess.get_file_as_bytes(path_b).slice(0, 10))
	_check("save: save_b tronque a 10 octets en plus -> {}", SaveS.load_latest(TEST_SAVE_DIR).is_empty())
	var s_fmt: Dictionary = S.duplicate(true)
	s_fmt["format"] = 2
	var s_seq0: Dictionary = S.duplicate(true)
	s_seq0["seq"] = 0
	_check("save: format 2 refuse, seq 0 refuse", SaveS.unpack(SaveS.pack(s_fmt)).is_empty() and SaveS.unpack(SaveS.pack(s_seq0)).is_empty())
	_clean_saves()
	var s_clk: Dictionary = S.duplicate(true)
	s_clk["village"]["last_save_utc"] = D0 + 7200
	var keep: int = SaveS.save(s_clk, D0 + 3600, TEST_SAVE_DIR)["village"]["last_save_utc"]
	var adv: int = SaveS.save(s_clk, D0 + 10800, TEST_SAVE_DIR)["village"]["last_save_utc"]
	_check("save: horloge, now plus ancien garde 7200, now plus recent ecrit 10800", keep == D0 + 7200 and adv == D0 + 10800, "%d %d" % [keep - D0, adv - D0])
	var b64: String = SaveS.export_base64(S)
	_check("base64: import(export(S)) == S", SaveS.import_base64(b64) == S)
	var mid: int = b64.length() / 2
	var b64_bad: String = b64.substr(0, mid) + ("B" if b64[mid] == "A" else "A") + b64.substr(mid + 1)
	_check("base64: un caractere du milieu remplace -> {}", SaveS.import_base64(b64_bad).is_empty())
	_check("base64: \"pas du base64\" -> {}", SaveS.import_base64("pas du base64").is_empty())
	_clean_saves()
	SaveS.save(S, t10, TEST_SAVE_DIR)
	var bt: Dictionary = SaveS.boot(w7, TEST_SAVE_DIR)
	var bv: Dictionary = bt["state"]["village"]
	_check("boot: village == resume(S.village, T10 + 7 j), player_gold 13, seq 2", bv == Dag.resume(S["village"], w7)["village"] and bv["player_gold"] == 13 and bt["state"]["seq"] == 2, "%d %d" % [bv["player_gold"], bt["state"]["seq"]])
	_check("boot: load_latest rend le meme etat", SaveS.load_latest(TEST_SAVE_DIR) == bt["state"])
	var bt2: Dictionary = SaveS.boot(w7, TEST_SAVE_DIR)
	_check("boot: deuxieme boot au meme instant, t_eff 0, aucun tick, player_gold 13", bt2["t_eff"] == 0.0 and not bt2["ticked"] and bt2["state"]["village"]["player_gold"] == 13, "%s %s %d" % [str(bt2["t_eff"]), str(bt2["ticked"]), bt2["state"]["village"]["player_gold"]])
	var bt3: Dictionary = SaveS.boot(w7 - 7200, TEST_SAVE_DIR)
	_check("boot: horloge reculee de 2 h, t_eff 0, aucun tick, last_save_utc reste T10 + 7 j", bt3["t_eff"] == 0.0 and not bt3["ticked"] and bt3["state"]["village"]["last_save_utc"] == w7, "%s %s %d" % [str(bt3["t_eff"]), str(bt3["ticked"]), bt3["state"]["village"]["last_save_utc"] - w7])
	_clean_saves()
	# Jalon 4 : nouvelle partie
	var SEED: int = RngS.fnv1a64("archipel")
	var NO: int = BD.TraitId.NOCTAMBULE
	_check("rng: jumeau make_rng(SEED, npc/0), 10 next_u32", SEED == -6068549941476399303 and _seq(SEED, "npc/0", 10) == _bonds([583857294, 2374001034, 2949803476, 1535391990, 4081604712, 2003029350, 1108202908, 3117921484, 105880901, 304449250]), str(_seq(SEED, "npc/0", 10)))
	for c: Array in [["SEED", SEED, [[CO, TE], [BO], [PE], [PE, CO], [PE, CO]]], ["graine 0", 0, [[NO], [NO, BO], [PE], [PE, BE], [CO, BO]]], ["graine 42", 42, [[CO, BO], [PE, BE], [BE], [PE], [NO]]]]:
		var got_t: Array = _draws(c[1])
		_check("traits: %s, PNJ 0 a 4" % c[0], got_t == c[2], str(got_t))
	var n2: int = 0
	var principal: Array[int] = [0, 0, 0, 0, 0, 0]
	var dup: int = 0
	var incompat: int = 0
	var pairs: Dictionary = {}
	for s in 10000:
		var tr: Array[int] = NewGameS.draw_traits(RngS.make_rng(s, "npc/0"))
		principal[tr[0]] += 1
		if tr.size() == 2:
			n2 += 1
			dup += 1 if tr[0] == tr[1] else 0
			incompat += 1 if tr[1] in BD.TRAIT_INCOMPATIBILITIES[tr[0]] else 0
			pairs["%d-%d" % [mini(tr[0], tr[1]), maxi(tr[0], tr[1])]] = true
	_check("tirage: graines 0-9999, 5128 PNJ a 2 traits", n2 == 5128, str(n2))
	_check("tirage: trait principal 1491 / 2004 / 1499 / 1512 / 2019 / 1475", principal == _bonds([1491, 2004, 1499, 1512, 2019, 1475]), str(principal))
	_check("tirage: 0 doublon, 0 paire incompatible, 12 paires distinctes", dup == 0 and incompat == 0 and pairs.size() == 12, "%d %d %d" % [dup, incompat, pairs.size()])
	var V: Dictionary = NewGameS.village(SEED, t10, 0)
	var posts: Array = []
	var mans: Array = []
	var npc_ok: bool = true
	for npc: Dictionary in V["npcs"]:
		posts.append(npc["post"])
		mans.append(npc["manages"])
		npc_ok = npc_ok and npc["stars"] == 2 and npc["cadence"] == "NORMAL" and npc["moral"] == 80 and npc["house_lvl"] == 1 \
			and typeof(npc["tool_durability"]) == TYPE_FLOAT and npc["tool_durability"] == 100.0 and not npc["tool_broken"] and not npc["on_strike"]
	_check("village: posts et gerants", posts == ["EXTRACTION", "TAVERN", "FORGE", "GUARD", "GUARD"] and mans == ["MAT", "TAVERN", "FORGE", "", ""], "%s %s" % [str(posts), str(mans)])
	_check("village: 5 x 2*, NORMAL, Moral 80, maison 1, durabilite 100,0 float, ni outil brise ni greve", npc_ok)
	_check("village: griffe MAT COSTAUD, TAVERN BOSSEUR, FORGE PERFECTIONNISTE", _shop_vals(V, "griffe_trait") == _bonds([CO, BO, PE]), str(_shop_vals(V, "griffe_trait")))
	var smax: Array[int] = []
	var tgt: Array[int] = []
	for k: String in ["MAT", "TAVERN", "FORGE"]:
		smax.append(Eco.stock_max(k == "MAT", V["shops"][k]["lvl"], V["shops"][k]["griffe_trait"]))
		tgt.append(Eco.stock_target(smax[-1], V["shops"][k]["posture"]))
	_check("village: stock_max 69 / 30 / 30, cibles 41 / 18 / 18", smax == _bonds([69, 30, 30]) and tgt == _bonds([41, 18, 18]), "%s %s" % [str(smax), str(tgt)])
	_check("village: stocks 0 / 0 / 0, pots 8 / 48 / 144, tresoreries 150 x 3", _shop_vals(V, "stock") == _bonds([0, 0, 0]) and _shop_vals(V, "pot") == _bonds([8, 48, 144]) and _shop_vals(V, "treasury") == _bonds([150, 150, 150]), "%s %s %s" % [str(_shop_vals(V, "stock")), str(_shop_vals(V, "pot")), str(_shop_vals(V, "treasury"))])
	_check("village: player_gold 0, isolat 0, last_save_utc T10, last_tick_day 20748", V["player_gold"] == 0 and V["isolat"] == 0 and V["last_save_utc"] == t10 and V["last_tick_day"] == 20748, "%d %d %d %d" % [V["player_gold"], V["isolat"], V["last_save_utc"] - t10, V["last_tick_day"]])
	_check("village: deterministe, graine 0 differente", NewGameS.village(SEED, t10, 0) == V and NewGameS.village(0, t10, 0) != V)
	var tzd: Array[int] = []
	for tz: int in [0, 7200, -36000]:
		tzd.append(NewGameS.village(SEED, t10, tz)["last_tick_day"])
	_check("village: last_tick_day 20748 / 20748 / 20747 pour tz 0 / 7200 / -36000", tzd == _bonds([20748, 20748, 20747]), str(tzd))
	var ns: Dictionary = SaveS.new_state(SEED, t10, 0)
	ns["seq"] = 1
	_check("village: new_state seq 1 valide pour SaveManager, aller-retour pack/unpack", SaveS._is_valid(ns) and SaveS.unpack(SaveS.pack(ns)) == ns)
	var n0: Dictionary = Dag.resume(V, t10)
	_check("depart: resume au meme instant, pas de tick, t_eff 0, village identique", not n0["ticked"] and n0["t_eff"] == 0.0 and n0["village"] == V)
	var n6: Dictionary = Dag.resume(V, t10 + 6 * 3600)
	var v6n: Dictionary = n6["village"]
	_check("depart: +6 h, pas de tick, t_eff 6, DAG added 17 / 6 / 3, sold 0 / 3 / 3, tax 0 / 4 / 7, meals 3", not n6["ticked"] and n6["t_eff"] == 6.0 and _dag_vals(n6, "added") == _bonds([17, 6, 3]) and _dag_vals(n6, "sold") == _bonds([0, 3, 3]) and _dag_vals(n6, "tax") == _bonds([0, 4, 7]) and n6["dag"]["meals"] == 3,
		"%s %s %s %d" % [str(_dag_vals(n6, "added")), str(_dag_vals(n6, "sold")), str(_dag_vals(n6, "tax")), n6["dag"]["meals"]])
	_check("depart: +6 h, player_gold 11, stocks 0 / 3 / 0, pots 8 / 24 / 108, tresoreries 150 / 160 / 163", v6n["player_gold"] == 11 and _shop_vals(v6n, "stock") == _bonds([0, 3, 0]) and _shop_vals(v6n, "pot") == _bonds([8, 24, 108]) and _shop_vals(v6n, "treasury") == _bonds([150, 160, 163]),
		"%d %s %s %s" % [v6n["player_gold"], str(_shop_vals(v6n, "stock")), str(_shop_vals(v6n, "pot")), str(_shop_vals(v6n, "treasury"))])
	_check("depart: +6 h, Moral 5 x 80, durabilites 5 x 100", _morals(v6n) == _bonds([80, 80, 80, 80, 80]) and _durs(v6n) == _floats([100.0, 100.0, 100.0, 100.0, 100.0]), "%s %s" % [str(_morals(v6n)), str(_durs(v6n))])
	var n24: Dictionary = Dag.resume(V, t10 + 86400)
	var v24: Dictionary = n24["village"]
	_check("depart: +24 h, tick, t_eff 12, DAG added 34 / 6 / 12, sold 0 / 6 / 12, tax 0 / 9 / 28, meals 5", n24["ticked"] and n24["t_eff"] == 12.0 and _dag_vals(n24, "added") == _bonds([34, 6, 12]) and _dag_vals(n24, "sold") == _bonds([0, 6, 12]) and _dag_vals(n24, "tax") == _bonds([0, 9, 28]) and n24["dag"]["meals"] == 5,
		"%s %s %s %d" % [str(_dag_vals(n24, "added")), str(_dag_vals(n24, "sold")), str(_dag_vals(n24, "tax")), n24["dag"]["meals"]])
	_check("depart: +24 h, frais 24, player_gold 13, stocks 0 x 3, pots 8 / 0 / 0, tresoreries 150 / 168 / 202", n24["fixed_cost_paid"] == 24 and v24["player_gold"] == 13 and _shop_vals(v24, "stock") == _bonds([0, 0, 0]) and _shop_vals(v24, "pot") == _bonds([8, 0, 0]) and _shop_vals(v24, "treasury") == _bonds([150, 168, 202]),
		"%d %d %s %s %s" % [n24["fixed_cost_paid"], v24["player_gold"], str(_shop_vals(v24, "stock")), str(_shop_vals(v24, "pot")), str(_shop_vals(v24, "treasury"))])
	_check("depart: +24 h, Moral 82 / 79 / 81 / 81 / 81, durabilites 80 / 80 / 85 / 100 / 100", _morals(v24) == _bonds([82, 79, 81, 81, 81]) and _durs(v24) == _floats([80.0, 80.0, 85.0, 100.0, 100.0]), "%s %s" % [str(_morals(v24)), str(_durs(v24))])
	var vd: Dictionary = V
	var gd: Array[int] = []
	for d in range(1, 8):
		vd = Dag.resume(vd, t10 + d * 86400)["village"]
		gd.append(vd["player_gold"])
	_check("depart: 7 retours quotidiens, player_gold 13 / 26 / 39 / 52 / 65 / 78 / 91", gd == _bonds([13, 26, 39, 52, 65, 78, 91]), str(gd))
	_check("depart: Moral au 7e jour 86 / 78 / 82 / 82 / 82", _morals(vd) == _bonds([86, 78, 82, 82, 82]), str(_morals(vd)))
	var v359: Dictionary = NewGameS.village(SEED, D0 + 3 * 3600 + 59 * 60, 0)
	var n401: Dictionary = Dag.resume(v359, D0 + 4 * 3600 + 60)
	_check("depart: cree a 3 h 59, repris a 4 h 01 : jour 20747 -> 20748, tick, frais 0, pots 8 / 48 / 144", v359["last_tick_day"] == 20747 and n401["village"]["last_tick_day"] == 20748 and n401["ticked"] and n401["fixed_cost_paid"] == 0 and n401["village"]["player_gold"] == 0 and _shop_vals(n401["village"], "pot") == _bonds([8, 48, 144]),
		"%d %d %s %d %s" % [v359["last_tick_day"], n401["village"]["last_tick_day"], str(n401["ticked"]), n401["fixed_cost_paid"], str(_shop_vals(n401["village"], "pot"))])
	var e1: Variant = RngS.entropy_seed()
	var e2: Variant = RngS.entropy_seed()
	_check("rng: entropy_seed int, deux appels differents", typeof(e1) == TYPE_INT and e1 != e2)
	_clean_saves()
	var nb: Dictionary = SaveS.boot(t10, TEST_SAVE_DIR)
	var nbs: Dictionary = nb["state"]
	_check("boot: dossier vide -> nouvelle partie, seq 1, save_a.dat", nb["new_game"] and nbs["seq"] == 1 and FileAccess.file_exists(TEST_SAVE_DIR.path_join("save_a.dat")), "%s %d" % [str(nb["new_game"]), nbs["seq"]])
	_check("boot: nouvelle partie, world_seed int, Or de depart, fuseau systeme, 5 PNJ, last_save_utc == now",
		typeof(nbs["world_seed"]) == TYPE_INT and nbs["village"]["player_gold"] == BB.PLAYER_STARTING_GOLD and nbs["village"]["tz_offset_sec"] == NewGameS.system_tz_offset_sec() and nbs["village"]["npcs"].size() == 5 and nbs["village"]["last_save_utc"] == t10)
	var nb2: Dictionary = SaveS.boot(t10, TEST_SAVE_DIR)
	var same_v: Dictionary = nb2["state"]["village"].duplicate(true)
	same_v["last_save_utc"] = nbs["village"]["last_save_utc"]
	_check("boot: deuxieme boot, reprise, meme graine, seq 2, t_eff 0, aucun tick, village inchange", not nb2["new_game"] and nb2["state"]["world_seed"] == nbs["world_seed"] and nb2["state"]["seq"] == 2 and nb2["t_eff"] == 0.0 and not nb2["ticked"] and same_v == nbs["village"],
		"%s %d %s %s" % [str(nb2["new_game"]), nb2["state"]["seq"], str(nb2["t_eff"]), str(nb2["ticked"])])
	_clean_saves()
	_write_bytes(TEST_SAVE_DIR.path_join("save_a.dat"), PackedByteArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
	var nb3: Dictionary = SaveS.boot(t10, TEST_SAVE_DIR)
	_check("boot: seul un save_a.dat de 10 octets -> {}, fichier intact, pas de save_b.dat", nb3.is_empty() and FileAccess.get_file_as_bytes(TEST_SAVE_DIR.path_join("save_a.dat")).size() == 10 and not FileAccess.file_exists(TEST_SAVE_DIR.path_join("save_b.dat")))
	_clean_saves()
	# Jalon 5 : plié / déplié
	for c: Array in [[Vector2i(1080, 2520), true], [Vector2i(1968, 2184), false], [Vector2i(540, 1260), true], [Vector2i(984, 1092), false], [Vector2i(1000, 1450), true], [Vector2i(1000, 1449), false]]:
		_check("fold: is_folded(%dx%d) == %s" % [c[0].x, c[0].y, str(c[1])], FoldModeS.is_folded(c[0]) == c[1])
	_check("fold: zoom_for plie (1, 1), deplie (0,5 ; 0,5), TWEEN_SEC <= 0,2", FoldModeS.zoom_for(true) == Vector2(1, 1) and FoldModeS.zoom_for(false) == Vector2(0.5, 0.5) and FoldModeS.TWEEN_SEC <= 0.2)
	var lf: CanvasLayer = CanvasLayer.new()
	var lu: CanvasLayer = CanvasLayer.new()
	FoldModeS.apply(true, lf, lu)
	var ok_folded: bool = lf.visible and lf.process_mode == Node.PROCESS_MODE_INHERIT and not lu.visible and lu.process_mode == Node.PROCESS_MODE_DISABLED
	FoldModeS.apply(false, lf, lu)
	var ok_unfolded: bool = not lf.visible and lf.process_mode == Node.PROCESS_MODE_DISABLED and lu.visible and lu.process_mode == Node.PROCESS_MODE_INHERIT
	_check("fold: apply plie (visible, INHERIT) / (cache, DISABLED), deplie l'inverse", ok_folded and ok_unfolded)
	lf.free()
	lu.free()
	# Jalon 5 : rattrapage dû
	var cu: Array[bool] = []
	for dt: int in [3600, 11 * 3600 + 59 * 60, 12 * 3600, -3600]:
		cu.append(SaveS.catch_up_due(V, t10 + dt))
	_check("catch_up_due: +1 h faux, +11 h 59 faux, +12 h vrai, -1 h faux", cu == [false, false, true, false], str(cu))
	var v3h: Dictionary = NewGameS.village(SEED, D0 + 3 * 3600, 0)
	_check("catch_up_due: cree a 3 h, 3 h 59 faux, 4 h 01 vrai (nouveau jour)", not SaveS.catch_up_due(v3h, D0 + 3 * 3600 + 59 * 60) and SaveS.catch_up_due(v3h, D0 + 4 * 3600 + 60))
	# Jalon 5 : Rapport de veillée
	var rep6: Dictionary = Dag.resume(V, t10 + 6 * 3600)
	rep6["gold_delta"] = rep6["village"]["player_gold"] - V["player_gold"]
	rep6["strikes"] = 0
	_check("rapport: +6 h, fiches [MAT, FORGE], gold_delta 11", rep6["fiches"] == ["MAT", "FORGE"] and rep6["gold_delta"] == 11, "%s %d" % [str(rep6["fiches"]), rep6["gold_delta"]])
	var l6: PackedStringArray = VeilleeReportS.lines(rep6, false)
	_check("rapport: +6 h deplie", l6 == PackedStringArray(["Absence comptée : 6 h 00", "Or : +11", "Fiches de rupture : 2"]), str(l6))
	_check("rapport: +6 h plie", VeilleeReportS.lines(rep6, true) == PackedStringArray(["Absence comptée : 6 h 00", "Or : +11"]), str(VeilleeReportS.lines(rep6, true)))
	var rep24: Dictionary = Dag.resume(V, t10 + 86400)
	rep24["gold_delta"] = rep24["village"]["player_gold"] - V["player_gold"]
	rep24["strikes"] = 0
	var l24: PackedStringArray = VeilleeReportS.lines(rep24, false)
	_check("rapport: +24 h deplie", l24 == PackedStringArray(["Absence comptée : 12 h 00 (plafond)", "Or : +13", "Frais fixes du jour : 24 Or", "Fiches de rupture : 3"]), str(l24))
	_check("rapport: +24 h plie", VeilleeReportS.lines(rep24, true) == PackedStringArray(["Absence comptée : 12 h 00 (plafond)", "Or : +13"]), str(VeilleeReportS.lines(rep24, true)))
	_check("rapport: nouvelle partie", VeilleeReportS.lines({"new_game": true}, true) == PackedStringArray(["Nouvelle partie : Clair-Foyer."]) and VeilleeReportS.lines({"new_game": true}, false) == PackedStringArray(["Nouvelle partie : Clair-Foyer."]))
	var syn: Dictionary = {"new_game": false, "t_eff": 2.5, "ticked": true, "fixed_cost_paid": 0, "tools_replaced": 2, "fiches": ["MAT"], "gold_delta": -3, "strikes": 1}
	var lsyn: PackedStringArray = VeilleeReportS.lines(syn, false)
	_check("rapport: synthetique", lsyn == PackedStringArray(["Absence comptée : 2 h 30", "Or : -3", "Frais fixes du jour : 0 Or", "Outils remplacés : 2", "PNJ en grève : 1", "Fiches de rupture : 1"]), str(lsyn))
	# Jalon 5 : rapport de boot
	_clean_saves()
	SaveS.save(SaveS.new_state(SEED, t10, 0), t10, TEST_SAVE_DIR)
	var br: Dictionary = SaveS.boot(t10 + 6 * 3600, TEST_SAVE_DIR)
	_check("boot rapport: gold_delta 11, strikes 0, fiches [MAT, FORGE], t_eff 6, reprise", br["gold_delta"] == 11 and br["strikes"] == 0 and br["fiches"] == ["MAT", "FORGE"] and br["t_eff"] == 6.0 and not br["new_game"],
		"%d %d %s %s" % [br["gold_delta"], br["strikes"], str(br["fiches"]), str(br["t_eff"])])
	_clean_saves()
	var be: Dictionary = SaveS.boot(t10, TEST_SAVE_DIR)
	_check("boot rapport: dossier vide, gold_delta 0, strikes 0", be["gold_delta"] == 0 and be["strikes"] == 0)
	# Jalon 5 : sync
	_clean_saves()
	var sm = SaveS.new() # non typé : sync, start et state viennent du script
	_check("sync: state vide -> {}, aucun fichier", sm.sync(t10, TEST_SAVE_DIR).is_empty() and not FileAccess.file_exists(TEST_SAVE_DIR.path_join("save_a.dat")) and not FileAccess.file_exists(TEST_SAVE_DIR.path_join("save_b.dat")))
	SaveS.save(SaveS.new_state(SEED, t10, 0), t10, TEST_SAVE_DIR)
	var rs: Dictionary = sm.start(t10, TEST_SAVE_DIR)
	_check("sync: start -> reprise, t_eff 0, state non vide", not rs["new_game"] and rs["t_eff"] == 0.0 and not sm.state.is_empty())
	var seq0: int = sm.state["seq"]
	var a30: Dictionary = sm.sync(t10 + 1800, TEST_SAVE_DIR)
	var seq1: int = sm.state["seq"]
	var a60: Dictionary = sm.sync(t10 + 3600, TEST_SAVE_DIR)
	_check("sync: +30 min et +1 h -> {}, seq +1 a chaque appel, last_save_utc reste T10, load_latest == state",
		a30.is_empty() and a60.is_empty() and seq1 == seq0 + 1 and sm.state["seq"] == seq0 + 2 and sm.state["village"]["last_save_utc"] == t10 and SaveS.load_latest(TEST_SAVE_DIR) == sm.state,
		"%d %d %d %d" % [seq0, seq1, sm.state["seq"], sm.state["village"]["last_save_utc"] - t10])
	var banc: Dictionary = SaveS.boot(t10 + 6 * 3600, TEST_SAVE_DIR)
	_check("sync: ancre prouvee, boot +6 h -> t_eff 6, player_gold 11", banc["t_eff"] == 6.0 and banc["state"]["village"]["player_gold"] == 11, "%s %d" % [str(banc["t_eff"]), banc["state"]["village"]["player_gold"]])
	sm.free()
	_clean_saves()
	var sm2 = SaveS.new()
	SaveS.save(SaveS.new_state(SEED, t10, 0), t10, TEST_SAVE_DIR)
	sm2.start(t10, TEST_SAVE_DIR)
	var rc12: Dictionary = sm2.sync(t10 + 12 * 3600, TEST_SAVE_DIR)
	_check("sync: rattrapage +12 h, t_eff 12, pas de tick, gold_delta 37, fiches x 3, strikes 0", not rc12.is_empty() and rc12["t_eff"] == 12.0 and not rc12["ticked"] and rc12["gold_delta"] == 37 and rc12["fiches"] == ["MAT", "TAVERN", "FORGE"] and rc12["strikes"] == 0,
		str(rc12.get("t_eff")) + " " + str(rc12.get("gold_delta")) + " " + str(rc12.get("fiches")))
	_check("sync: last_save_utc == T10 + 12 h, puis +12 h 01 -> {} (ancre)", sm2.state["village"]["last_save_utc"] == t10 + 12 * 3600 and sm2.sync(t10 + 12 * 3600 + 60, TEST_SAVE_DIR).is_empty())
	sm2.free()
	_clean_saves()
	# Jalon 5 : police
	_check("police: SHA-256 Silkscreen-Regular.ttf", SaveS._sha256(FileAccess.get_file_as_bytes(FONT_PATH)).hex_encode() == "c845473330b94c2079ce9af01c51ac8ba2d99c24f4d14c039843bbb8e642ebd8")
	_check("police: SHA-256 OFL.txt", SaveS._sha256(FileAccess.get_file_as_bytes(OFL_PATH)).hex_encode() == "86c5e9c9382cdcc5948704fdfe60f2aa164a719746931219a42736ecd9cefbd3")
	var ff: FontFile = FontFile.new()
	_check("police: load_dynamic_font == OK", ff.load_dynamic_font(FONT_PATH) == OK)
	var missing: String = ""
	for ch: String in "ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸŒÆàâäçéèêëîïôöùûüÿœæ«»’…–—€0123456789:+-(). ":
		if not ff.has_char(ch.unicode_at(0)):
			missing += ch
	_check("police: glyphes accentues, ponctuation et chiffres", missing == "", missing)
	_check("police: premiere ligne de OFL.txt", FileAccess.get_file_as_string(OFL_PATH).split("\n")[0].strip_edges() == "Copyright 2001 The Silkscreen Project Authors (https://github.com/googlefonts/silkscreen)")
	# Jalon 5 : thème
	var th: Theme = load(THEME_PATH)
	var line_h: int = int(th.default_font.get_height(8)) + th.get_constant("line_spacing", "Label")
	_check("theme: default_font_size 8, ligne de Label 11 px, gui/theme/custom", th.default_font_size == 8 and line_h == 11 and ProjectSettings.get_setting("gui/theme/custom") == THEME_PATH, "%d %d" % [th.default_font_size, line_h])
	# Jalon 5 : scènes
	var uf = load("res://scenes/ui/ui_folded.tscn").instantiate()
	var uu = load("res://scenes/ui/ui_unfolded.tscn").instantiate()
	_check("scenes: ui_folded / ui_unfolded en CanvasLayer, compact true / false", uf is CanvasLayer and uu is CanvasLayer and uf.compact and not uu.compact)
	_check("scenes: bouton Credits dans ui_unfolded seulement", uu.get_node_or_null("Margin/VBox/CreditsButton") is Button and uf.get_node_or_null("Margin/VBox/CreditsButton") == null)
	uf.free()
	uu.free()
	var cr: Node = load("res://scenes/ui/credits.tscn").instantiate()
	_check("scenes: credits.tscn s'instancie", cr != null)
	cr.free()
	var main_state: SceneState = (load("res://scenes/main.tscn") as PackedScene).get_state()
	var main_nodes: Array[String] = []
	for i in main_state.get_node_count():
		main_nodes.append(main_state.get_node_name(i))
	_check("scenes: main.tscn contient Camera2D, UI_Folded, UI_Unfolded, World", main_nodes.has("Camera2D") and main_nodes.has("UI_Folded") and main_nodes.has("UI_Unfolded") and main_nodes.has("World"), str(main_nodes))
	# Jalon 6 : compilation de chaque script
	for root: String in ["res://scripts", "res://autoload", "res://balance"]:
		for path: String in _gd_files(root):
			var scr: Script = load(path)
			_check("compilation: %s" % path, scr != null and (scr as GDScript).can_instantiate())
	# Jalon 6 : échelle entière
	var base6: Vector2i = FoldModeS.base_size()
	_check("fold: base_size == (180, 320)", base6 == Vector2i(180, 320), str(base6))
	for c: Array in [[Vector2i(1080, 2520), 6], [Vector2i(1968, 2184), 6], [Vector2i(540, 1260), 3], [Vector2i(984, 1092), 3], [Vector2i(100, 100), 1]]:
		var sc6: int = FoldModeS.integer_scale(c[0], Vector2i(180, 320))
		_check("fold: integer_scale(%dx%d) == %d" % [c[0].x, c[0].y, c[1]], sc6 == c[1], str(sc6))
	# Jalon 6 : preset Android
	var cfg: ConfigFile = ConfigFile.new()
	var cfg_err: Error = cfg.load("res://export_presets.cfg")
	var sec: String = ""
	for s6: String in cfg.get_sections():
		if s6.begins_with("preset.") and not s6.ends_with(".options") and cfg.get_value(s6, "name", "") == "Android":
			sec = s6
	_check("preset: export_presets.cfg charge, section Android trouvee", cfg_err == OK and sec != "", "%s %s" % [error_string(cfg_err), sec])
	if sec != "":
		var opt: String = sec + ".options"
		_check("preset: platform, filtres, chemin d'export", cfg.get_value(sec, "platform") == "Android" and cfg.get_value(sec, "export_filter") == "all_resources"
			and "assets/fonts/silkscreen/OFL.txt" in cfg.get_value(sec, "include_filter", "") and "tests/*" in cfg.get_value(sec, "exclude_filter", "")
			and cfg.get_value(sec, "export_path") == "build/archipel-debug.apk")
		_check("preset: sans Gradle, arm64-v8a seule", cfg.get_value(opt, "gradle_build/use_gradle_build") == false and cfg.get_value(opt, "architectures/arm64-v8a") == true
			and cfg.get_value(opt, "architectures/armeabi-v7a") == false and cfg.get_value(opt, "architectures/x86") == false and cfg.get_value(opt, "architectures/x86_64") == false)
		_check("preset: app_category Game (2), package com.amicussoft.archipel, signe", cfg.get_value(opt, "package/app_category") == 2
			and cfg.get_value(opt, "package/unique_name") == "com.amicussoft.archipel" and cfg.get_value(opt, "package/signed") == true)
		var ks_bad: String = ""
		for k: String in cfg.get_section_keys(opt):
			if k.begins_with("keystore/") and str(cfg.get_value(opt, k)) != "":
				ks_bad += k + " "
		_check("preset: champs keystore/* vides", ks_bad == "", ks_bad)
	# Jalon 6 : réglages du projet et .gitignore
	_check("projet: orientation portrait (1) et resizable true", ProjectSettings.get_setting("display/window/handheld/orientation") == 1 and ProjectSettings.get_setting("display/window/size/resizable") == true)
	var ignore_lines: PackedStringArray = FileAccess.get_file_as_string("res://.gitignore").replace("\r", "").split("\n")
	var ignore_missing: String = ""
	for ig: String in [".godot/", "build/*", "!build/.gdignore", "*.apk", "*.keystore", "*.jks", "export_credentials.cfg"]:
		if not ig in ignore_lines:
			ignore_missing += ig + " "
	_check(".gitignore: .godot/, build/* sauf build/.gdignore, *.apk, *.keystore, *.jks, export_credentials.cfg", ignore_missing == "", ignore_missing)
	# Jalon 8 : build/ hors import et export Godot
	_check("build/.gdignore présent", FileAccess.file_exists("res://build/.gdignore"))
	# Jalon 7 : échelle d'interface 6 en plié et déplié
	for c: Array in [[Vector2i(1248, 1972), true], [Vector2i(1848, 2448), false]]:
		_check("fold: is_folded(%dx%d) == %s (Fold 8)" % [c[0].x, c[0].y, str(c[1])], FoldModeS.is_folded(c[0]) == c[1])
	for c: Array in [[Vector2i(1248, 1972), true, 6], [Vector2i(1848, 2448), false, 6], [Vector2i(1080, 2520), true, 6], [Vector2i(1968, 2184), false, 6], [Vector2i(540, 1260), true, 3], [Vector2i(984, 1092), false, 3]]:
		var us: int = FoldModeS.ui_scale(c[0], c[1])
		_check("fold: ui_scale(%dx%d, %s) == %d" % [c[0].x, c[0].y, "plie" if c[1] else "deplie", c[2]], us == c[2], str(us))
	for c: Array in [[Vector2i(1248, 1972), 6, Vector2i(208, 328)], [Vector2i(1848, 2448), 6, Vector2i(308, 408)], [Vector2i(540, 1260), 3, Vector2i(180, 420)], [Vector2i(984, 1092), 3, Vector2i(328, 364)]]:
		var cs: Vector2i = FoldModeS.content_size(c[0], c[1])
		_check("fold: content_size(%dx%d, %d) == %dx%d" % [c[0].x, c[0].y, c[1], c[2].x, c[2].y], cs == c[2], str(cs))
	for c: Array in [[Vector2i(1248, 1972), 6, Rect2i(0, 100, 1248, 1872), [0, 17, 0, 0]], [Vector2i(1848, 2448), 6, Rect2i(0, 0, 1848, 2448), [0, 0, 0, 0]],
			[Vector2i(1848, 2448), 6, Rect2i(30, 90, 1788, 2310), [5, 15, 5, 8]], [Vector2i(540, 1260), 3, Rect2i(0, 0, 540, 1260), [0, 0, 0, 0]]]:
		var sm7: PackedInt32Array = FoldModeS.safe_margins(c[0], c[1], c[2])
		_check("fold: safe_margins(%dx%d, %d, %s) == %s" % [c[0].x, c[0].y, c[1], str(c[2]), str(c[3])], sm7 == PackedInt32Array(c[3]), str(sm7))
	_check("fold: FOLDED_MIN_ASPECT 1,45, UNFOLDED_MIN_SIZE (240, 360), ZOOM_UNFOLDED (0,5 ; 0,5)", FoldModeS.FOLDED_MIN_ASPECT == 1.45 and FoldModeS.UNFOLDED_MIN_SIZE == Vector2i(240, 360) and FoldModeS.ZOOM_UNFOLDED == Vector2(0.5, 0.5))
	var cr7: Node = load("res://scenes/ui/credits.tscn").instantiate()
	var sb7: StyleBox = (cr7 as Control).get_theme_stylebox("panel")
	_check("credits: StyleBoxFlat opaque (bg_color.a == 1)", sb7 is StyleBoxFlat and (sb7 as StyleBoxFlat).bg_color.a == 1.0)
	cr7.free()
	# Jalon 8 : assets Kenney
	for a: Array in [["kenney_tiny_town/tilemap_packed.png", "3a54d99ecde790d4fdea207a3644cf130fc56fa838f1beb1507c185a95b8e902"],
			["kenney_tiny_town/License.txt", "c483c167cc3bdfe17c15f957ff847d409f64d81b410b28783636cf3b2b7814c5"],
			["kenney_tiny_dungeon/tilemap_packed.png", "d24e60a41e4ac7a745c0304dfde121143688557f40215f23221c29cfe683825f"],
			["kenney_tiny_dungeon/License.txt", "9f574a2f1f636a3db8a0665ba90212f34e2b5e61ecb533d77c05237766374111"]]:
		var h8: String = SaveS._sha256(FileAccess.get_file_as_bytes("res://assets/tiles/" + a[0])).hex_encode()
		_check("assets: SHA-256 %s" % a[0], h8 == a[1], h8)
	for pack: String in ["kenney_tiny_town", "kenney_tiny_dungeon"]:
		var lic: String = FileAccess.get_file_as_string("res://assets/tiles/%s/License.txt" % pack)
		_check("assets: %s/License.txt CC0" % pack, "Creative Commons Zero" in lic or "CC0" in lic)
	var assets_md: String = FileAccess.get_file_as_string("res://ASSETS.md")
	_check("assets: ASSETS.md cite les 2 PNG", "assets/tiles/kenney_tiny_town/tilemap_packed.png" in assets_md and "assets/tiles/kenney_tiny_dungeon/tilemap_packed.png" in assets_md)
	# Jalon 8 : village.json
	var vd8: Dictionary = VL.load_data()
	_check("village.json: se lit", not vd8.is_empty())
	var bad_idx: String = ""
	for tn: String in vd8["tiles"]:
		var tex8: Texture2D = load(vd8["atlases"][vd8["tiles"][tn][0]])
		if int(vd8["tiles"][tn][1]) >= (tex8.get_width() / 16) * (tex8.get_height() / 16):
			bad_idx += tn + " "
	_check("village.json: index de tuile < colonnes x rangees de l'atlas", bad_idx == "", bad_idx)
	var unknown: String = ""
	var used_names: Array = vd8["npc_sprites"] + vd8["trees"] + vd8["tufts"]
	for pn: String in vd8["patterns"]:
		for row: Array in vd8["patterns"][pn]:
			used_names.append_array(row)
	for pr: Dictionary in vd8["props"]:
		used_names.append(pr["tile"])
	for s8: String in vd8["sites"]:
		if not vd8["patterns"].has(vd8["sites"][s8]["pattern"]):
			unknown += "motif:" + vd8["sites"][s8]["pattern"] + " "
	for un: String in used_names:
		if un != "" and not vd8["tiles"].has(un):
			unknown += un + " "
	_check("village.json: motifs, props et sprites existent", unknown == "", unknown)
	var houses: int = 0
	for s8: String in vd8["sites"]:
		if s8.begins_with("HOUSE"):
			houses += 1
	_check("village.json: 5 npc_sprites, 5 maisons == VERTICAL_SLICE_NPC_CAP", vd8["npc_sprites"].size() == 5 and houses == BD.VERTICAL_SLICE_NPC_CAP, "%d %d" % [vd8["npc_sprites"].size(), houses])
	var shop_keys: Array = []
	for s8: String in vd8["sites"]:
		if Dag.SHOP_BUDGET_KEY.has(s8):
			shop_keys.append(s8)
	shop_keys.sort()
	var dag_keys: Array = Dag.SHOP_BUDGET_KEY.keys()
	dag_keys.sort()
	_check("village.json: sites TAVERN, FORGE, MAT == cles de SHOP_BUDGET_KEY", shop_keys == dag_keys, str(shop_keys))
	# Jalon 8 : disposition
	var sites8: Dictionary = vd8["sites"]
	var built8: Dictionary = VL.built_cells(sites8, vd8["patterns"])
	var n_tiles8: int = 0
	var out_r: String = ""
	var on_built: String = ""
	for s8: String in sites8:
		var st8: Dictionary = VL.site_tiles(sites8[s8], vd8["patterns"])
		n_tiles8 += st8.size()
		for c: Vector2i in st8:
			if not VL.in_radius(c, 12):
				out_r += str(c)
		if sites8[s8].has("access"):
			var ac: Vector2i = VL.v2i(sites8[s8]["access"])
			if not VL.in_radius(ac, 12):
				out_r += str(ac)
			if built8.has(ac):
				on_built += s8 + " "
	_check("disposition: bati et acces dans le rayon 12", out_r == "", out_r)
	_check("disposition: aucun chevauchement, 72 cellules baties", n_tiles8 == built8.size() and built8.size() == 72, "%d %d" % [n_tiles8, built8.size()])
	_check("disposition: aucun acces sur du bati", on_built == "", on_built)
	# Jalon 8 : chemins
	var p8: Dictionary = VL.paths(sites8, vd8["patterns"])
	var want_len: Dictionary = {"TAVERN": 3, "FORGE": 4, "MAT": 4, "GATE": 9, "HOUSE0": 8, "HOUSE1": 8, "HOUSE2": 9, "HOUSE3": 9, "HOUSE4": 5, "GISEMENT": 5}
	_check("chemins: longueurs TAVERN 3 ... GISEMENT 5, dans l'ordre des sites", p8["lengths"] == want_len and p8["lengths"].keys() == want_len.keys(), str(p8["lengths"]))
	var path_on_built: int = 0
	for c: Vector2i in p8["cells"]:
		if built8.has(c):
			path_on_built += 1
	_check("chemins: 74 cellules route comprise, aucune sur du bati", p8["cells"].size() == 74 and path_on_built == 0, "%d %d" % [p8["cells"].size(), path_on_built])
	var bad_prop: String = ""
	for pr: Dictionary in vd8["props"]:
		var pc8: Vector2i = VL.v2i(pr["cell"])
		if built8.has(pc8) or p8["cells"].has(pc8):
			bad_prop += str(pc8)
		for s8: String in sites8:
			if sites8[s8].has("access") and VL.v2i(sites8[s8]["access"]) == pc8:
				bad_prop += str(pc8)
	_check("chemins: props hors bati, acces et chemins", bad_prop == "", bad_prop)
	# Jalon 8 : déco (blocked = bâti + chemins, sans props)
	var blocked8: Dictionary = built8.duplicate()
	blocked8.merge(p8["cells"])
	for c: Array in [[1, 326, 13, Vector2i(-18, -26), 3, Vector2i(1, -8), 2], [42, 312, 18, Vector2i(-18, -26), 4, Vector2i(0, -10), 3]]:
		var dc8: Dictionary = VL.deco(c[0], blocked8)
		var counts8: Dictionary = {"tree": 0, "tuft": 0}
		var first8: Dictionary = {}
		var on_blocked: int = 0
		for y in range(VL.GROUND_RECT.position.y, VL.GROUND_RECT.end.y):
			for x in range(VL.GROUND_RECT.position.x, VL.GROUND_RECT.end.x):
				var cell: Vector2i = Vector2i(x, y)
				if dc8.has(cell):
					counts8[dc8[cell][0]] += 1
					if not first8.has(dc8[cell][0]):
						first8[dc8[cell][0]] = [cell, dc8[cell][1]]
					if blocked8.has(cell):
						on_blocked += 1
		_check("deco: graine %d -> %d arbres, %d touffes, premier arbre %s r %d, premiere touffe %s r %d, rien sur bloque" % c,
			counts8["tree"] == c[1] and counts8["tuft"] == c[2] and first8.get("tree") == [c[3], c[4]] and first8.get("tuft") == [c[5], c[6]] and on_blocked == 0,
			"%s %s %d" % [str(counts8), str(first8), on_blocked])
	_check("deco: meme graine = meme resultat", VL.deco(7, blocked8) == VL.deco(7, blocked8))
	# Jalon 8 : heure locale, phase, activité, ancres
	for c: Array in [[0, 0, 0], [0, 7200, 2], [82859, 0, 23], [0, -3600, 23]]:
		_check("local_hour(%d, %d) == %d" % c, VL.local_hour(c[0], c[1]) == c[2], str(VL.local_hour(c[0], c[1])))
	for c: Array in [[5, BD.DayPhase.NIGHT], [6, BD.DayPhase.DAWN], [7, BD.DayPhase.DAWN], [8, BD.DayPhase.DAY], [18, BD.DayPhase.DAY], [19, BD.DayPhase.DUSK], [21, BD.DayPhase.DUSK], [22, BD.DayPhase.NIGHT]]:
		_check("day_phase(%d) == %s" % [c[0], BD.DayPhase.find_key(c[1])], VL.day_phase(c[0]) == c[1])
	for c: Array in [[false, false, {7: "SLEEP", 8: "WORK", 12: "WORK", 13: "MEAL", 14: "WORK", 18: "WORK", 19: "VEILLEE", 21: "VEILLEE", 22: "SLEEP", 3: "SLEEP"}],
			[true, false, {19: "SLEEP", 20: "WORK", 0: "WORK", 1: "MEAL", 2: "WORK", 6: "WORK", 7: "VEILLEE", 9: "VEILLEE", 10: "SLEEP"}],
			[false, true, {8: "STRIKE", 13: "MEAL", 23: "SLEEP"}]]:
		var got8: Dictionary = {}
		for h: int in c[2]:
			got8[h] = VL.activity(h, c[0], c[1])
		_check("activity %s: %s" % ["nocturne" if c[0] else ("greve" if c[1] else "diurne"), str(c[2])], got8 == c[2], str(got8))
	var guard: Dictionary = {"post": "GUARD", "traits": [], "on_strike": false}
	var anc8: Array[Vector2] = VL.anchors(["WORK", "WORK"], [guard, guard], sites8)
	_check("anchor: 2 gardes en WORK -> acces GATE (0, 10), -6 et +6 px", anc8 == [Vector2(-6, 160), Vector2(6, 160)], str(anc8))
	var v0: Vector2 = VL.anchor("VEILLEE", 0, guard, sites8)
	_check("anchor: VEILLEE du PNJ 0 -> (0, -28)", v0.is_equal_approx(Vector2(0, -28)), str(v0))
	# Jalon 8 : scènes
	var vs8: Node = load("res://scenes/village/village.tscn").instantiate()
	var np8: Node = load("res://scenes/village/npc.tscn").instantiate()
	var vnodes: String = ""
	for nn: String in ["Jour", "Sol", "Chemins", "Entites", "Entites/Batiments", "Entites/Deco", "Entites/Atre"]:
		if vs8 == null or vs8.get_node_or_null(nn) == null:
			vnodes += nn + " "
	_check("scenes: village.tscn et npc.tscn s'instancient, Jour, Sol, Chemins, Entites, Batiments, Deco, Atre", vs8 != null and np8 != null and vnodes == "", vnodes)
	vs8.free()
	np8.free()
	var world_scene: String = ""
	for i in main_state.get_node_count():
		if main_state.get_node_name(i) == "World" and main_state.get_node_instance(i) != null:
			world_scene = main_state.get_node_instance(i).resource_path
	_check("scenes: World de main.tscn est une instance de village.tscn", world_scene == "res://scenes/village/village.tscn", world_scene)
	_check("scenes: debug_grid.gd n'existe plus", not FileAccess.file_exists("res://scripts/ui/debug_grid.gd"))
	var cr8: Node = load("res://scenes/ui/credits.tscn").instantiate()
	var kl: Label = cr8.get_node_or_null("Margin/VBox/Kenney")
	_check("credits: ligne Kenney", kl != null and kl.text == "Tuiles et personnages : Kenney (kenney.nl), CC0")
	cr8.free()
	# Jalon 8 : sautillement des PNJ
	_check("npc: BOB_PX 1, BOB_PERIOD_SEC 0,3", NpcS.BOB_PX == 1 and NpcS.BOB_PERIOD_SEC == 0.3)
	for tb: float in [0.0, 0.07, 0.15, 0.3, 12.34]:
		_check("npc: bob_offset(%.2f, repos) == 0" % tb, NpcS.bob_offset(tb, false) == 0)
	for c: Array in [[0.0, -1], [0.15, 0], [0.30, -1]]:
		_check("npc: bob_offset(%.2f, marche) == %d" % [c[0], c[1]], NpcS.bob_offset(c[0], true) == c[1], str(NpcS.bob_offset(c[0], true)))
	# Garde-fou
	var ba_script: Script = load("res://balance/balance_a.gd") # BA.get_script_constant_map() est refusé par le parseur (appel non statique sur une classe)
	_check("garde-fou: BalanceA sans WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS", not ba_script.get_script_constant_map().has("WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS"))
	print("--- %s (%d echec(s))" %["TOUS PASS" if _fails == 0 else "ECHEC", _fails])
	quit(1 if _fails > 0 else 0)
