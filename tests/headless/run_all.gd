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
const PlayerMotionS = preload("res://scripts/player/player_motion.gd")
const StickS = preload("res://scripts/ui/touch_stick.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const LisiereS = preload("res://scripts/combat/lisiere.gd")
const SegGenS = preload("res://scripts/segment/segment_gen.gd")
const SegmentS = preload("res://scripts/segment/segment.gd")
const ExpeditionS = preload("res://scripts/segment/expedition.gd")
const MistS = preload("res://scripts/segment/mist_node.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const EquipmentS = preload("res://scripts/loot/equipment.gd")
const PurifS = preload("res://scripts/loot/purification.gd")
const BF = preload("res://balance/balance_f.gd")
const SG = preload("res://scripts/segment/segment_gen.gd")
const ForgeS = preload("res://scripts/loot/forge.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")
const UiS = preload("res://scripts/ui/ui_layer.gd")
const VText = preload("res://scripts/ui/village_text.gd")
const AssignS = preload("res://scripts/village/assignment.gd")
const UiStyle = preload("res://scripts/ui/ui_style.gd")
const DebugS = preload("res://scripts/debug/debug_tools.gd")
const AtreS = preload("res://scripts/village/atre.gd")
const ShopUpS = preload("res://scripts/village/shop_upgrade.gd")
const LISIERE_SPAWNS_10: Array = [[0, 16], [0, 20], [0, 24]] # banc d'essai du jalon 10, retiré du village au jalon 11
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
# Jalon 9 : cellules pleines, déplacement, esquive, joystick, scènes. Jumeau Python : prep_jalon_9.py.
func _solid9(vd: Dictionary, built: Dictionary, p: Dictionary, world_seed: int) -> Dictionary:
	var blocked: Dictionary = built.duplicate()
	blocked.merge(p["cells"])
	for prop: Dictionary in vd["props"]:
		blocked[VL.v2i(prop["cell"])] = true
	return VL.solid_cells(vd["sites"], vd["patterns"], vd["props"], VL.deco(world_seed, blocked))

func _jalon_9(vd: Dictionary, built: Dictionary, p: Dictionary) -> void:
	var atre: Dictionary = VL.site_tiles(vd["sites"]["ATRE"], vd["patterns"])
	var solid1: Dictionary = {}
	for c: Array in [[1, 393], [42, 379]]:
		var solid: Dictionary = _solid9(vd, built, p, c[0])
		if c[0] == 1:
			solid1 = solid
		var bad: String = ""
		for cell: Vector2i in p["cells"]:
			if solid.has(cell):
				bad += "chemin %s " % str(cell)
		for key: String in vd["sites"]:
			if vd["sites"][key].has("access") and solid.has(VL.v2i(vd["sites"][key]["access"])):
				bad += "acces %s " % key
		for cell: Vector2i in atre:
			if cell != Vector2i.ZERO and solid.has(cell):
				bad += "dallage %s " % str(cell)
		_check("solid: graine %d -> %d cellules, ni chemin, ni accès, ni dallage hors (0, 0), torche pleine" % c,
			solid.size() == c[1] and bad == "" and solid.has(Vector2i.ZERO), "%d %s" % [solid.size(), bad])
	var spawn: Vector2 = VL.cell_center(VL.PLAYER_SPAWN_CELL)
	_check("spawn: (0, 32), libre", spawn == Vector2(0, 32) and not PlayerMotionS.overlaps(spawn, solid1), str(spawn))
	for c: Array in [[Vector2(0, 32), Vector2(0, -48), Vector2(0, 11)], [Vector2(-24, -24), Vector2(-48, 0), Vector2(-52, -24)],
			[Vector2(-24, -24), Vector2(-48, 16), Vector2(-52, -8)], [Vector2(0, 400), Vector2(0, 48), Vector2(0, 421)],
			[Vector2(0, 32), Vector2(10, 5), Vector2(10, 37)], [Vector2(0, 160), Vector2(0, 48), Vector2(0, 208)],
			[Vector2(0, 176), Vector2(16, 0), Vector2(4, 176)], [Vector2(0, 32), Vector2.ZERO, Vector2(0, 32)]]:
		var got: Vector2 = PlayerMotionS.move(c[0], c[1], solid1)
		_check("move: %s + %s -> %s" % c, got == c[2], str(got))
	var walk: Vector2 = spawn
	for i in 60:
		walk = PlayerMotionS.move(walk, Vector2(BA.PLAYER_BASE_MSPD / 60.0, 0), solid1)
	_check("marche: 60 x 1/60 s depuis (0, 32) -> (140, 32)", walk.distance_to(Vector2(140, 32)) <= 0.01, str(walk))
	for c: Array in [[0.0, 0.0], [0.125, 24.0], [0.25, 48.0], [0.4, 48.0]]:
		_check("esquive: dodge_progress(%.3f) == %.0f" % c, is_equal_approx(PlayerMotionS.dodge_progress(c[0]), c[1]), str(PlayerMotionS.dodge_progress(c[0])))
	var dist: float = 0.0
	var t9: float = 0.0
	for i in 20:
		dist += PlayerMotionS.dodge_progress(t9 + 1.0 / 60.0) - PlayerMotionS.dodge_progress(t9)
		t9 += 1.0 / 60.0
	_check("esquive: somme sur 20 pas de 1/60 s == 48", absf(dist - 48.0) <= 1e-4, str(dist))
	for c: Array in [[0.0, true], [0.19, true], [0.20, false], [0.25, false]]:
		_check("esquive: in_iframes(%.2f) == %s" % [c[0], str(c[1])], PlayerMotionS.in_iframes(c[0]) == c[1])
	for c: Array in [[0.0, -1.0, true], [1.79, 0.0, false], [1.80, 0.0, true], [5.0, 3.0, true]]:
		_check("esquive: can_dodge(%.2f, %.0f) == %s" % [c[0], c[1], str(c[2])], PlayerMotionS.can_dodge(c[0], c[1]) == c[2])
	# Joystick
	_check("stick: dir (0,0)->(3,0) == ZERO", StickS.stick_dir(Vector2.ZERO, Vector2(3, 0)) == Vector2.ZERO)
	_check("stick: dir (0,0)->(4,0) == (1, 0)", StickS.stick_dir(Vector2.ZERO, Vector2(4, 0)) == Vector2(1, 0))
	_check("stick: dir (0,0)->(3,4) == (0,6 ; 0,8)", StickS.stick_dir(Vector2.ZERO, Vector2(3, 4)).distance_to(Vector2(0.6, 0.8)) <= 1e-6)
	_check("stick: dir (10,10)->(10,-10) == (0, -1)", StickS.stick_dir(Vector2(10, 10), Vector2(10, -10)) == Vector2(0, -1))
	_check("stick: follow (0,0),(12,16) -> (0, 0)", StickS.follow_origin(Vector2.ZERO, Vector2(12, 16)) == Vector2.ZERO)
	_check("stick: follow (0,0),(30,40) -> (18, 24)", StickS.follow_origin(Vector2.ZERO, Vector2(30, 40)).distance_to(Vector2(18, 24)) <= 1e-5, str(StickS.follow_origin(Vector2.ZERO, Vector2(30, 40))))
	_check("stick: follow (100,100),(100,60) -> (100, 80)", StickS.follow_origin(Vector2(100, 100), Vector2(100, 60)) == Vector2(100, 80))
	for c: Array in [[0.20, Vector2.ZERO, Vector2(16, 0), true], [0.21, Vector2.ZERO, Vector2(16, 0), false], [0.10, Vector2.ZERO, Vector2(15, 0), false],
			[0.10, Vector2.ZERO, Vector2(0, -16), true], [0.05, Vector2(5, 5), Vector2(5, 5), false]]:
		_check("stick: is_swipe(%.2f, %s, %s) == %s" % [c[0], str(c[1]), str(c[2]), str(c[3])], StickS.is_swipe(c[0], c[1], c[2]) == c[3])
	# Intégration joueur
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(spawn, null, null, solid1)
	pl.set_move_dir(Vector2(1, 0))
	for i in 60:
		pl._process(1.0 / 60.0)
	_check("joueur: 60 images vers la droite -> x 140, y 32", absf(pl.position.x - 140.0) <= 0.01 and pl.position.y == 32.0, str(pl.position))
	pl.free()
	pl = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(spawn, null, null, solid1)
	var ok1: bool = pl.dodge(Vector2(0, -1))
	for i in 20:
		pl._process(1.0 / 60.0)
	_check("joueur: esquive vers le haut -> x 0, 11 <= y < 12 (torche)", ok1 and pl.position.x == 0.0 and pl.position.y >= 11.0 and pl.position.y < 12.0, str(pl.position))
	_check("joueur: esquive immédiate refusée", not pl.dodge(Vector2(0, -1)))
	for i in 87:
		pl._process(1.0 / 60.0)
	_check("joueur: 107 images (1,783 s) -> esquive refusée", not pl.dodge(Vector2(0, 1)))
	for i in 4:
		pl._process(1.0 / 60.0)
	_check("joueur: 111 images (1,85 s) -> esquive acceptée", pl.dodge(Vector2(0, 1)))
	pl.free()
	pl = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(spawn, null, null, solid1)
	var flips: Array = []
	for d: Vector2 in [Vector2(1, 0), Vector2(-0.1, -0.99), Vector2(0.1, -0.99), Vector2(-0.6, 0.8), Vector2(0.2, 0.98), Vector2(0.5, 0.866)]:
		pl.set_move_dir(d)
		flips.append(pl.get_node("Sprite").flip_h)
	_check("joueur: miroir seulement si |dir.x| >= 0,5", flips == [false, false, false, true, true, false], str(flips))
	pl.free()
	# Intégration joystick
	var st: Node2D = StickS.new()
	root.add_child(st)
	var got: Array = []
	st.direction_changed.connect(func(d: Vector2) -> void: got.append(["dir", d]))
	st.swiped.connect(func(d: Vector2) -> void: got.append(["swipe", d]))
	st._unhandled_input(_touch(0, Vector2(100, 100), true))
	st._unhandled_input(_drag(0, Vector2(100, 80)))
	_check("stick: posé (100,100), glissé (100,80) -> dir (0, -1)", got == [["dir", Vector2(0, -1)]], str(got))
	got.clear()
	st._unhandled_input(_touch(0, Vector2(100, 80), false))
	_check("stick: relâché -> swiped (0, -1) puis dir ZERO", got == [["swipe", Vector2(0, -1)], ["dir", Vector2.ZERO]], str(got))
	got.clear()
	st._unhandled_input(_touch(0, Vector2(100, 100), true))
	st._unhandled_input(_drag(0, Vector2(102, 100)))
	var nonzero: bool = false
	for g: Array in got:
		nonzero = nonzero or (g[0] == "dir" and g[1] != Vector2.ZERO)
	_check("stick: glissé de 2 px -> aucune direction", not nonzero, str(got))
	st._unhandled_input(_drag(0, Vector2(120, 100)))
	got.clear()
	var cancel: InputEventScreenTouch = _touch(0, Vector2(120, 100), false)
	cancel.canceled = true
	st._unhandled_input(cancel)
	_check("stick: relâché annulé après 20 px -> aucun swiped", got == [["dir", Vector2.ZERO]], str(got))
	got.clear()
	st._unhandled_input(_touch(0, Vector2(100, 100), true))
	st._unhandled_input(_touch(1, Vector2(50, 50), true))
	st._unhandled_input(_drag(1, Vector2(50, 10)))
	st._unhandled_input(_touch(1, Vector2(50, 10), false))
	st._unhandled_input(_drag(0, Vector2(100, 120)))
	_check("stick: second doigt ignoré", got == [["dir", Vector2(0, 1)]], str(got))
	st.free()
	# Scènes et réglages
	var pl_state: SceneState = (load("res://scenes/player/player.tscn") as PackedScene).get_state()
	var pl_nodes: Array[String] = []
	for i in pl_state.get_node_count():
		pl_nodes.append(pl_state.get_node_name(i))
	_check("scenes: player.tscn = Joueur, Ombre, Sprite", pl_nodes == ["Joueur", "Ombre", "Sprite"], str(pl_nodes))
	var vil: Node = load("res://scenes/village/village.tscn").instantiate()
	_check("scenes: village.tscn contient Entites/Joueur", vil.get_node_or_null("Entites/Joueur") != null)
	vil.free()
	var uif: Node = load("res://scenes/ui/ui_folded.tscn").instantiate()
	var uiu: Node = load("res://scenes/ui/ui_unfolded.tscn").instantiate()
	_check("scenes: Stick dans ui_folded, pas dans ui_unfolded", uif.get_node_or_null("Stick") != null and uiu.find_child("Stick", true, false) == null)
	uif.free()
	uiu.free()
	_check("village.json: joueur hors des 5 sprites de PNJ", vd["tiles"].has("joueur") and vd["player_sprite"] == "joueur" and not vd["npc_sprites"].any(func(n: String) -> bool: return vd["tiles"][n] == vd["tiles"]["joueur"]))
	_check("projet: emulate_touch_from_mouse true", ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse") == true)

# Jalon 10 : combat de la lisière. Jumeau Python : prep_jalon_10.py.
# Jalon 13 : XP de vocation, niveaux, sauvegarde. Jumeau Python : prep_jalon_13.py.
func _jalon_13(solid1: Dictionary) -> void:
	var curve: Array = [1, 2, 3, 4, 5, 10, 50].map(func(l: int) -> int: return BA.get_cumulative_xp(l))
	_check("xp: cumul Nv 1 / 2 / 3 / 4 / 5 / 10 / 50 == 0 / 200 / 530 / 1 020 / 1 700 / 9 000 / 715 400", curve == [0, 200, 530, 1020, 1700, 9000, 715400], str(curve))
	var lv: Array = [0, 199, 200, 529, 530, 1019, 1020, 1699, 1700, 715399, 715400, 10000000].map(func(x: int) -> int: return ProgressionS.level_of(x))
	_check("progression: level_of 0 … 10 000 000 == 1 1 2 2 3 3 4 4 5 49 50 50", lv == [1, 1, 2, 2, 3, 3, 4, 4, 5, 49, 50, 50], str(lv))
	var stats: Array = []
	var dmg: Array = []
	for l in range(2, 6):
		var st: Dictionary = CombatS.player_stats(l, 10)
		stats.append([st["hp"], st["atk"], st["def"]])
		if l <= 4:
			dmg.append([CombatS.damage(st["atk"], 4, l, false), CombatS.damage(st["atk"], 4, l, false, BA.SKILL_1_DMG_MULT), CombatS.damage(st["atk"], 4, l, false, BA.SKILL_2_DMG_MULT)])
	_check("combat: player_stats(2…5, 10) == 118/24/6, 136/27/8, 154/29/9, 172/32/11", stats == [[118, 24, 6], [136, 27, 8], [154, 29, 9], [172, 32, 11]], str(stats))
	_check("combat: dégâts sur DEF 4 (auto / I / II) Nv 2 = 22/49/79, Nv 3 = 25/56/90, Nv 4 = 27/61/97", dmg == [[22, 49, 79], [25, 56, 90], [27, 61, 97]], str(dmg))
	# X1 : 40 kills puis l'Élite
	var p1: Dictionary = ProgressionS.new_player()
	var ex: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return p1)
	var ups: Array = []
	var n: Array[int] = [0]
	ex.leveled.connect(func(voc: String, level: int) -> void: ups.append([n[0], voc, level]))
	for k in 40:
		n[0] = k + 1
		ex.on_kill(0)
	n[0] = 41
	ex.on_elite(0)
	_check("X1: montées aux kills 7 (Nv 2), 18 (Nv 3), 34 (Nv 4), voc_xp 1 396 / 0 / 0, Nv 4, expedition.xp 1 396",
		ups == [[7, "COMBATTANT", 2], [18, "COMBATTANT", 3], [34, "COMBATTANT", 4]] and p1["voc_xp"] == {"COMBATTANT": 1396, "MINEUR": 0, "FORGERON": 0}
		and ProgressionS.combat_level(p1) == 4 and ex.xp == 1396, "%s %s %d" % [str(ups), str(p1), ex.xp])
	# X2 : rattrapage
	var p2: Dictionary = ProgressionS.new_player()
	p2["voc_xp"]["COMBATTANT"] = 1700
	var x2: Array = []
	for k in 6:
		var g: Dictionary = ProgressionS.gain(p2, "MINEUR", 63)
		x2.append([g["gained"], p2["voc_xp"]["MINEUR"], g["level_after"]])
	_check("X2: Combattant Nv 5, 6 gains Mineur de 63 -> 126 x5 puis 63, cumul 126 … 693, niveaux 1 2 2 2 3 3",
		x2 == [[126, 126, 1], [126, 252, 2], [126, 378, 2], [126, 504, 2], [126, 630, 3], [63, 693, 3]], str(x2))
	var cm: Array = [[5, 5], [4, 5], [2, 5], [49, 50], [50, 50]].map(func(c: Array) -> float: return BA.get_action_xp_catchup_mult(c[0], c[1]))
	_check("X3: rattrapage (5,5) 1, (4,5) 1, (2,5) 2, (49,50) 2, (50,50) 1", cm == [1.0, 1.0, 2.0, 2.0, 1.0], str(cm))
	# X4 : l'expédition de M1 (jalon 12)
	var p4: Dictionary = ProgressionS.new_player()
	ex = ExpeditionS.new(1, 0, func() -> Dictionary: return p4)
	for k in 12:
		ex.on_kill(0)
	for k in 7:
		ex.on_gather(0)
	ex.on_elite(0)
	var lv4: Array = ProgressionS.VOCATIONS.map(func(v: String) -> int: return ProgressionS.level_of(p4["voc_xp"][v]))
	_check("X4: 12 kills, 7 nœuds, l'Élite -> Combattant 556 (Nv 3), Mineur 441 (Nv 2), Forgeron 0 (Nv 1)",
		p4["voc_xp"] == {"COMBATTANT": 556, "MINEUR": 441, "FORGERON": 0} and lv4 == [3, 2, 1], "%s %s" % [str(p4), str(lv4)])
	# Montée en combat
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid1)
	pl.hp = 73
	pl.set_level(2)
	_check("joueur: Nv 1 à 73 PV, set_level(2) -> 91 / 118 PV, ATK 24, DEF 6", pl.level == 2 and pl.hp == 91 and pl.max_hp == 118 and pl.atk == 24 and pl.def == 6,
		"%d %d %d %d" % [pl.hp, pl.max_hp, pl.atk, pl.def])
	pl.free()
	# Sauvegarde
	_clean_saves()
	var ns: Dictionary = SaveS.new_state(7, D0, 0)
	_check("save: new_state contient player == new_player()", ns.get("player") == ProgressionS.new_player())
	ns["player"]["voc_xp"]["MINEUR"] = 441
	var saved: Dictionary = SaveS.save(ns, D0, TEST_SAVE_DIR)
	var back: Dictionary = SaveS.load_latest(TEST_SAVE_DIR)
	_check("save: save puis load_latest rendent le même voc_xp, export/import Base64 aussi",
		not saved.is_empty() and back["player"] == ns["player"] and SaveS.import_base64(SaveS.export_base64(back))["player"] == ns["player"])
	var old: Dictionary = back.duplicate(true)
	old.erase("player")
	var old_back: Dictionary = SaveS.unpack(SaveS.pack(old))
	_check("save: état sans player (jalon 12) valide, revient avec new_player(), village intact",
		not old_back.is_empty() and old_back["player"] == ProgressionS.new_player() and old_back["village"] == old["village"])
	var bad: Array = []
	var mutations: Array[Callable] = [func(d: Dictionary) -> void: d["voc_xp"].erase("FORGERON"), func(d: Dictionary) -> void: d["voc_xp"]["MINEUR"] = -1,
		func(d: Dictionary) -> void: d["voc_xp"]["MINEUR"] = 1.5, func(d: Dictionary) -> void: d.erase("voc_xp")]
	for mutate: Callable in mutations:
		var b: Dictionary = back.duplicate(true)
		mutate.call(b["player"])
		bad.append(SaveS.unpack(SaveS.pack(b)).is_empty())
	_check("save: vocation manquante, négative, non entière, voc_xp absent -> refusé", bad == [true, true, true, true], str(bad))
	# SaveManager : gain, sync, gain relu via le Callable, sync
	_clean_saves()
	var sm: Node = SaveS.new()
	sm.state = SaveS.save(SaveS.new_state(7, D0, 0), D0, TEST_SAVE_DIR)
	var main_ref: Callable = func() -> Dictionary: return sm.state["player"] # même lecture que main.gd._player_state
	ProgressionS.gain(sm.state["player"], "COMBATTANT", 30)
	sm.sync(D0 + 60, TEST_SAVE_DIR)
	ProgressionS.gain(main_ref.call(), "COMBATTANT", 30)
	sm.sync(D0 + 120, TEST_SAVE_DIR)
	var reloaded: int = SaveS.load_latest(TEST_SAVE_DIR)["player"]["voc_xp"]["COMBATTANT"]
	_check("SaveManager: gain, sync, gain via le Callable, sync -> load_latest Combattant 60", reloaded == 60, str(reloaded))
	sm.free()
	_clean_saves()
	# Référence périmée
	var cur: Array = [ProgressionS.new_player()]
	var a_dict: Dictionary = cur[0]
	ex = ExpeditionS.new(1, 0, func() -> Dictionary: return cur[0])
	ex.on_kill(0)
	cur[0] = a_dict.duplicate(true)
	ex.on_kill(0)
	_check("référence: après une copie profonde (sync), le 2e kill va dans B (60), A reste à 30",
		cur[0]["voc_xp"]["COMBATTANT"] == 60 and a_dict["voc_xp"]["COMBATTANT"] == 30, "%d %d" % [cur[0]["voc_xp"]["COMBATTANT"], a_dict["voc_xp"]["COMBATTANT"]])
	# Segment : kill de normal, kill de l'Élite, mort du joueur
	var ps: Dictionary = ProgressionS.new_player()
	var ctx: Array = _seg_ctx(solid1, Vector2(0, 6240), func() -> Dictionary: return ps)
	var sp: Node2D = ctx[0]
	var seg: Node2D = ctx[1]
	var ends: Array = []
	seg.expedition_ended.connect(func(r: String) -> void: ends.append(r))
	for f in 5:
		_seg_frame(sp, seg)
	var node2: Node2D = seg.nodes()[2]
	var victim: Node2D = node2.mobs()[0]
	while victim.alive:
		node2._strike(victim)
	var after_kill: int = ps["voc_xp"]["COMBATTANT"]
	seg.expedition.cendre = 78
	victim = node2.mobs()[1]
	while victim.alive:
		node2._strike(victim)
	var before_elite: int = ps["voc_xp"]["COMBATTANT"]
	var el: Node2D = node2.elite()
	while el.alive:
		node2._strike(el)
	var elite_gain: int = ps["voc_xp"]["COMBATTANT"] - before_elite
	sp.hp = 5
	sp.take_hit(9)
	for f in 90:
		_seg_frame(sp, seg)
	_check("segment: kill de normal +30, kill de l'Élite +196, après la mort du joueur l'XP reste (256), fin « mort » émise",
		after_kill == 30 and elite_gain == 196 and ps["voc_xp"]["COMBATTANT"] == 256 and ends == ["mort"], "%d %d %d %s" % [after_kill, elite_gain, ps["voc_xp"]["COMBATTANT"], str(ends)])
	_seg_free(ctx)

# Jalon 14 : Lanterne niveau 1, Cendre Vive et Éclats sauvegardés, gardés à la mort.
func _jalon_14(solid1: Dictionary) -> void:
	_check("lanterne: new_player() == voc_xp à 0, cendre 0, Sacoche vide",
		ProgressionS.new_player() == {"voc_xp": {"COMBATTANT": 0, "MINEUR": 0, "FORGERON": 0}, "cendre": 0, "shard_bag": [],
		"equipment": EquipmentS.new_equipment(), "purify_n": 0, "elite_kills": 0, "chest": {}, "crate": null, "forge_n": 0,
		"forge_pending": null}) # clés des jalons 15, 15 bis et 16
	# 40 kills puis l'Élite, joueur neuf
	var pa: Dictionary = ProgressionS.new_player()
	var ex: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return pa)
	for k in 40:
		ex.on_kill(0)
	ex.on_elite(0)
	_check("lanterne: 40 kills puis l'Élite -> Cendre 100, Éclats 1 (= expedition.shards), Combattant 1 396",
		pa["cendre"] == 100 and pa["shard_bag"].size() == 1 and ex.shards == 1 and pa["voc_xp"]["COMBATTANT"] == 1396, "%s %d" % [str(pa), ex.shards])
	# Lanterne à 140 : plafond 150, surplus perdu
	var pb: Dictionary = ProgressionS.new_player()
	pb["cendre"] = 140
	ex = ExpeditionS.new(1, 0, func() -> Dictionary: return pb)
	var full_at: int = -1
	for k in 40:
		ex.on_kill(0)
		if full_at < 0 and pb["cendre"] == 150:
			full_at = k + 1
	var after_kills: int = pb["cendre"]
	var lost_kills: int = 140 + 40 * BA.CENDRE_GAIN_NORMAL_MOB - after_kills
	ex.on_elite(0)
	var lost_elite: int = after_kills + BA.CENDRE_GAIN_ELITE_MOB - pb["cendre"]
	_check("lanterne: départ 140 -> 150 au 5e kill, 70 perdus sur les kills, 150 après l'Élite (20 perdus), expedition.cendre 100",
		full_at == 5 and after_kills == 150 and lost_kills == 70 and pb["cendre"] == 150 and lost_elite == 20 and ex.cendre == 100,
		"%d %d %d %d %d %d" % [full_at, after_kills, lost_kills, pb["cendre"], lost_elite, ex.cendre])
	# Sacoche pleine : même tirage qu'une Sacoche vide
	var pc: Dictionary = ProgressionS.new_player()
	pc["shard_bag"] = _bag(6, 0)
	ex = ExpeditionS.new(1, 0, func() -> Dictionary: return pc)
	for k in 40:
		ex.on_kill(0)
	var refused_kills: int = ex.shards_refused
	ex.on_elite(0)
	var pe: Dictionary = ProgressionS.new_player()
	var ex_empty: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return pe)
	var drops: Array = []
	for k in 40:
		drops.append(ex_empty.on_kill(0))
	drops.append(ex_empty.on_elite(0))
	_check("lanterne: Sacoche à 6 -> 6, expedition.shards 0, « sacoche_pleine » une fois (l'Élite) ; Sacoche vide : 1 Éclat au même tirage (l'Élite)",
		pc["shard_bag"].size() == 6 and ex.shards == 0 and refused_kills == 0 and ex.shards_refused == 1 and drops.count(true) == 1 and drops[40] == true and pe["shard_bag"].size() == 1,
		"%d %d %d %d %s" % [pc["shard_bag"].size(), ex.shards, refused_kills, ex.shards_refused, str(drops.count(true))])
	# Sauvegarde
	_clean_saves()
	var ns: Dictionary = SaveS.new_state(7, D0, 0)
	ns["player"]["cendre"] = 100
	ns["player"]["shard_bag"] = _bag(3, 0)
	SaveS.save(ns, D0, TEST_SAVE_DIR)
	var back: Dictionary = SaveS.load_latest(TEST_SAVE_DIR)
	_check("save: save puis load_latest rendent cendre 100 et 3 Éclats", back["player"]["cendre"] == 100 and back["player"]["shard_bag"] == _bag(3, 0), str(back["player"]))
	var old: Dictionary = back.duplicate(true)
	old["player"].erase("cendre")
	old["player"].erase("shard_bag")
	var old_back: Dictionary = SaveS.unpack(SaveS.pack(old))
	_check("save: player sans cendre ni Éclats (jalon 13) valide, revient avec 0 et Sacoche vide, voc_xp intact",
		not old_back.is_empty() and old_back["player"]["cendre"] == 0 and old_back["player"]["shard_bag"] == [] and old_back["player"]["voc_xp"] == back["player"]["voc_xp"])
	var bad: Array = []
	for c: Array in [["cendre", 151], ["shards", 7], ["cendre", -1], ["shards", -1], ["cendre", 1.5], ["shards", 2.0]]:
		var b: Dictionary = back.duplicate(true)
		b["player"][c[0]] = c[1]
		bad.append(SaveS.unpack(SaveS.pack(b)).is_empty())
	_check("save: cendre 151, shards 7, négatifs, non entiers -> refusé", bad == [true, true, true, true, true, true], str(bad))
	_clean_saves()
	# Segment : kill puis mort du joueur
	var ps: Dictionary = ProgressionS.new_player()
	var ctx: Array = _seg_ctx(solid1, Vector2(0, 6240), func() -> Dictionary: return ps)
	var sp: Node2D = ctx[0]
	var seg: Node2D = ctx[1]
	for f in 5:
		_seg_frame(sp, seg)
	var node2: Node2D = seg.nodes()[2]
	var victim: Node2D = node2.mobs()[0]
	while victim.alive:
		node2._strike(victim)
	var after_kill: int = ps["cendre"]
	ps["shard_bag"] = _bag(2, 0)
	sp.hp = 5
	sp.take_hit(9)
	for f in 90:
		_seg_frame(sp, seg)
	_check("segment: un kill ajoute 2 à la Lanterne ; après la mort du joueur, Cendre 2 et Éclats 2 gardés, expédition finie",
		after_kill == 2 and ps["cendre"] == 2 and ps["shard_bag"].size() == 2 and seg.expedition == null and seg.last_end == "mort", "%d %s %s" % [after_kill, str(ps), seg.last_end])
	_seg_free(ctx)

# Jalon 15 : purification des Éclats et équipement porté (Volet F). Références : jumeau Python d'Antho.
func _jalon_15(solid1: Dictionary) -> void:
	_check("xp: kill_xp(NORMAL, 1) == 33 et kill_xp(ELITE, 1) == 219 (floor)", CombatS.kill_xp("NORMAL", 1) == 33 and CombatS.kill_xp("ELITE", 1) == 219,
		"%d %d" % [CombatS.kill_xp("NORMAL", 1), CombatS.kill_xp("ELITE", 1)])
	var st: Dictionary = EquipmentS.starter_weapon()
	var start_schools: Array = []
	start_schools.assign(CombatS.START_WEAPON_SCHOOLS)
	_check("équipement: arme de départ == START_* de Combat (Épée & Écu, Commun, ilvl 1, Enclume 3/3, 0 affixe)",
		BF.STARTER_WEAPON_TYPE == CombatS.START_WEAPON_TYPE and st["rarity"] == CombatS.START_WEAPON_RARITY and st["ilvl"] == CombatS.START_WEAPON_ILVL
		and st["schools"] == start_schools and st["affixes"].is_empty() and st["slot"] == BF.EquipmentSlot.WEAPON)
	var same: bool = true
	for l in range(1, 6):
		var a: Dictionary = EquipmentS.player_stats(l, EquipmentS.new_equipment())
		var b: Dictionary = CombatS.player_stats(l, CombatS.starting_weapon_atk())
		same = same and a["hp"] == b["hp"] and a["atk"] == b["atk"] and a["def"] == b["def"]
	_check("équipement: player_stats(L, arme de départ) == Combat.player_stats pour L = 1..5", same)
	var s1: Dictionary = EquipmentS.player_stats(1, EquipmentS.new_equipment())
	_check("S1: arme de départ, Nv 1 -> 100 / 22 / 5, période 1/1,2, critique 0,05, ×1,5",
		s1["hp"] == 100 and s1["atk"] == 22 and s1["def"] == 5 and _approx(s1["period"], 1.0 / 1.2, 1e-9) and _approx(s1["crit_rate"], 0.05, 1e-9) and _approx(s1["crit_mult"], 1.5, 1e-9), str(s1))
	var w2: Dictionary = EquipmentS.starter_weapon()
	w2["affixes"] = [{"id": "FLAT_ATK", "units": 12.0}]
	var eq2: Array = [w2, _armor(1, [["FLAT_DEF", 12.0]]), _armor(2, [["FLAT_HP", 12.0]]), null]
	var s2: Dictionary = EquipmentS.player_stats(2, eq2)
	_check("S2: Nv 2, FLAT_ATK / FLAT_DEF / FLAT_HP 12 -> 154 / 30 / 13", s2["hp"] == 154 and s2["atk"] == 30 and s2["def"] == 13, str(s2))
	var w3: Dictionary = EquipmentS.starter_weapon()
	w3["affixes"] = [{"id": "PCT_CRIT_CHANCE", "units": 4.0}]
	var eq3: Array = [w3]
	for slot in range(1, 4):
		eq3.append(_armor(slot, [["PCT_CRIT_CHANCE", 4.0], ["PCT_ATK", 6.0]]))
	var s3: Dictionary = EquipmentS.player_stats(1, eq3)
	_check("S3: critique 0,17 (16 unités plafonnées à 12), ATK 24 (PCT_ATK 18), PV 100, DEF 5",
		_approx(s3["crit_rate"], 0.17, 1e-9) and s3["atk"] == 24 and s3["hp"] == 100 and s3["def"] == 5, str(s3))
	var sh: Array = [EquipmentS.shares(2, _f([0.0])), EquipmentS.shares(2, _f([1.0])), EquipmentS.shares(3, _f([1.0, 0.0, 0.0])), EquipmentS.shares(3, _f([0.0, 0.0, 0.0])),
		EquipmentS.shares(3, _f([0.5, 0.25, 0.25]))]
	var sh_want: Array = [[0.4, 0.6], [0.6, 0.4], [0.5, 0.25, 0.25], [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0], [0.4, 0.3, 0.3]]
	var sh_ok: bool = true
	for i in sh.size():
		sh_ok = sh_ok and _near_eps(sh[i], sh_want[i], 1e-9)
	_check("P1: shares(2, [0]) [0,4 0,6], (2, [1]) [0,6 0,4], (3, [1 0 0]) [0,5 0,25 0,25], (3, [0 0 0]) [1/3 ×3], (3, [0,5 0,25 0,25]) [0,4 0,3 0,3]", sh_ok, str(sh))
	var p2: Array[float] = EquipmentS.units_of(_s(["PCT_ATK", "FLAT_HP"]), _f([0.5, 0.5]), 1, 1)
	_check("P2: units_of(PCT_ATK, FLAT_HP ; 0,5 0,5 ; ilvl 1, Bon) == [6,0 10,92] (report du reliquat)", _near_eps(p2, [6.0, 10.92], 1e-6), str(p2))
	var p3: Array[float] = EquipmentS.units_of(_s(["PCT_ATK", "PCT_ASPD"]), _f([0.5, 0.5]), 1, 1)
	_check("P3: units_of(PCT_ATK, PCT_ASPD ; 0,5 0,5 ; ilvl 1, Bon) == [6,0 4,0] (reliquat perdu)", _near_eps(p3, [6.0, 4.0], 1e-6), str(p3))
	# T1 / T2 : références du jumeau
	var t1_want: Array = [
		[0, 0, "EEE", [["FLAT_ATK", 12.0]]], [0, 1, "EBE", [["FLAT_HP", 7.0044], ["FLAT_ATK", 6.6756]]], [1, 0, "", [["FLAT_HP", 12.0]]],
		[1, 1, "", [["FLAT_HP", 6.2489], ["FLAT_DEF", 7.4311]]], [2, 0, "", [["FLAT_DEF", 12.0]]], [0, 0, "EEE", [["FLAT_HP", 12.0]]],
		[3, 0, "", [["FLAT_DEF", 12.0]]], [1, 1, "", [["FLAT_ATK", 10.08], ["PCT_ASPD", 4.0]]], [1, 0, "", [["FLAT_DEF", 12.0]]],
		[1, 0, "", [["FLAT_ATK", 12.0]]], [3, 0, "", [["FLAT_HP", 12.0]]], [1, 1, "", [["FLAT_DEF", 6.9845], ["FLAT_ATK", 6.6955]]]]
	var t2_want: Array = [
		[0, 1, "EEE", [["PCT_ATK", 6.0], ["PCT_ASPD", 4.0]]], [0, 2, "EBE", [["FLAT_HP", 7.0020], ["FLAT_ATK", 4.7580], ["PCT_ASPD", 4.0]]],
		[1, 1, "", [["PCT_ATK", 6.0], ["FLAT_ATK", 10.92]]], [1, 2, "", [["FLAT_HP", 6.9163], ["FLAT_DEF", 4.8437], ["PCT_ASPD", 4.0]]],
		[2, 1, "", [["FLAT_DEF", 11.88], ["PCT_CRIT_DMG", 10.0]]], [0, 1, "EEE", [["PCT_ATK", 6.0], ["FLAT_ATK", 10.92]]]]
	_t1_want = t1_want
	_t2_want = t2_want
	for t: Array in [["T1", false, t1_want], ["T2", true, t2_want]]:
		var got: Array = []
		var ok: bool = true
		for n in t[2].size():
			var piece: Dictionary = EquipmentS.roll(1, n, t[1], 1)
			got.append(_piece_str(n, piece))
			ok = ok and _piece_is(piece, t[2][n])
		_check("%s: roll(1, n, %s, 1) pour n = 0 à %d == références du jumeau" % [t[0], "true" if t[1] else "false", t[2].size() - 1], ok, "\n" + "\n".join(got))
	# C1 : répartition sur 20 000 tirages
	var slots: Array[int] = [0, 0, 0, 0]
	var rar: Array[int] = [0, 0, 0]
	var weapons: int = 0
	var full: int = 0
	var common_pct: int = 0
	var n_draws: int = 20000
	for n in n_draws:
		var piece: Dictionary = EquipmentS.roll(7, n, false, 1)
		slots[piece["slot"]] += 1
		rar[piece["rarity"]] += 1
		if piece["slot"] == 0:
			weapons += 1
			if piece["schools"][0] == piece["schools"][1] and piece["schools"][1] == piece["schools"][2]:
				full += 1
		if piece["rarity"] == 0 and not BF.COMMON_ALLOWED_AFFIXES.has(piece["affixes"][0]["id"]):
			common_pct += 1
	var fr: Callable = func(c: int, total: int) -> float: return float(c) / total
	var c1_ok: bool = common_pct == 0 and absf(fr.call(full, weapons) - 0.49) <= 0.02
	for i in 4:
		c1_ok = c1_ok and absf(fr.call(slots[i], n_draws) - 0.25) <= 0.02
	for i in 3:
		c1_ok = c1_ok and absf(fr.call(rar[i], n_draws) - [0.65, 0.25, 0.10][i]) <= 0.02
	_check("C1: 20 000 tirages roll(7, n) -> emplacements 0,25, raretés 0,65 / 0,25 / 0,10, armes 3/3 0,49 (±0,02), aucun Commun en %", c1_ok,
		"%s %s %.4f %d" % [str(slots), str(rar), fr.call(full, weapons), common_pct])
	# Purification
	var pp: Dictionary = ProgressionS.new_player()
	pp["shard_bag"] = _bag(2, 1)
	var v1: Dictionary = PurifS.preview(1, pp)
	var v1b: Dictionary = PurifS.preview(1, pp)
	var unchanged: bool = pp["purify_n"] == 0 and pp["shard_bag"] == _bag(2, 1)
	var log1: Dictionary = PurifS.commit(pp, v1, true, "VILLAGE")
	var v2: Dictionary = PurifS.preview(1, pp)
	var eq_before: Array = pp["equipment"].duplicate(true)
	var log2: Dictionary = PurifS.commit(pp, v2, false, "VILLAGE")
	_check("purification: 1re = Éclat d'Élite (T2 n°0, équipée), 2e = normal n = 1 (T1 n°1, jetée) ; l'aperçu répété ne change rien",
		v1 == v1b and unchanged and log1["source"] == "ELITE" and _piece_is(v1, t2_want[0]) and pp["equipment"][0] == v1 and log2["source"] == "NORMAL"
		and log2["n"] == 1 and _piece_is(v2, t1_want[1]), "%s %s" % [str(log1), str(log2)])
	_check("purification: « Jeter » consomme l'Éclat sans toucher l'équipement", pp["equipment"] == eq_before and pp["shard_bag"] == _bag(1, 0) and pp["purify_n"] == 2)
	# Brasero : 2 par expédition, village sans limite
	var pb: Dictionary = ProgressionS.new_player()
	pb["shard_bag"] = _bag(4, 0)
	var ctx: Array = _seg_ctx(solid1, Vector2(0, 3984), func() -> Dictionary: return pb)
	var bp: Node2D = ctx[0]
	var seg: Node2D = ctx[1]
	for f in 3:
		_seg_frame(bp, seg)
	var places: Array = []
	for k in 3:
		var place: String = seg.purify_place(bp.position)
		places.append(place)
		if place != "":
			seg.on_purified(place)
			PurifS.commit(pb, PurifS.preview(1, pb), false, place)
	var village_place: String = seg.purify_place(Vector2(0, 32))
	_check("purification: au Brasero, 2 passent et la 3e est refusée ; au village, acceptée", places == ["BRASERO", "BRASERO", ""] and village_place == "VILLAGE"
		and pb["shard_bag"].size() == 2, "%s %s %d" % [str(places), village_place, pb["shard_bag"].size()])
	_seg_free(ctx)
	# Sauvegarde
	_clean_saves()
	var ns: Dictionary = SaveS.new_state(7, D0, 0)
	ns["player"]["equipment"][1] = EquipmentS.roll(1, 3, false, 1)
	ns["player"]["equipment"][0] = EquipmentS.roll(1, 1, false, 1)
	ns["player"]["shard_bag"] = _bag(3, 2)
	ns["player"]["purify_n"] = 9
	SaveS.save(ns, D0, TEST_SAVE_DIR)
	var back: Dictionary = SaveS.load_latest(TEST_SAVE_DIR)
	_check("save: equipment, Sacoche (2 d'Élite), purify_n rendus ; stats recalculées identiques (Array non typé de bytes_to_var)",
		back["player"]["equipment"] == ns["player"]["equipment"] and back["player"]["shard_bag"] == _bag(3, 2) and back["player"]["purify_n"] == 9
		and EquipmentS.player_stats(3, back["player"]["equipment"]) == EquipmentS.player_stats(3, ns["player"]["equipment"]),
		"%s" % str(EquipmentS.player_stats(3, back["player"]["equipment"])))
	var old: Dictionary = back.duplicate(true)
	for k: String in ["equipment", "shard_bag", "purify_n", "elite_kills"]:
		old["player"].erase(k)
	old["player"]["shards"] = 6
	var old_back: Dictionary = SaveS.unpack(SaveS.pack(old))
	_check("save: player du jalon 14 -> arme de départ, aucun Éclat d'Élite, purify_n 0, ses 6 Éclats en normaux",
		not old_back.is_empty() and old_back["player"]["equipment"] == EquipmentS.new_equipment() and old_back["player"]["shard_bag"] == _bag(6, 0)
		and old_back["player"]["purify_n"] == 0 and not old_back["player"].has("shards"))
	var bad: Array = []
	var muts: Array[Callable] = [
		func(p: Dictionary) -> void: p["shard_bag"] = _bag(5, 2),
		func(p: Dictionary) -> void: p["equipment"][1]["rarity"] = 3,
		func(p: Dictionary) -> void: p["equipment"][1]["ilvl"] = 13,
		func(p: Dictionary) -> void: p["equipment"][1]["affixes"][0]["id"] = "MOVE_SPEED",
		func(p: Dictionary) -> void: p["equipment"][0]["affixes"] = [{"id": "PCT_ASPD", "units": 4.5}],
		func(p: Dictionary) -> void: p["equipment"][2] = p["equipment"][1].duplicate(true)]
	for m: Callable in muts:
		var b: Dictionary = back.duplicate(true)
		m.call(b["player"])
		bad.append(SaveS.unpack(SaveS.pack(b)).is_empty())
	_check("save: shards 5 + élite 2, rarity 3, ilvl 13, affixe inconnu, units au-dessus du plafond, case 2 avec slot 1 -> refusé", bad == [true, true, true, true, true, true], str(bad))
	_clean_saves()
	# Expedition : Sacoche pleine sur la somme des deux compteurs
	var pf: Dictionary = ProgressionS.new_player()
	pf["shard_bag"] = _bag(4, 2)
	var exf: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return pf)
	for k in 40:
		exf.on_kill(0)
	var elite_drop: bool = exf.on_elite(0)
	var pg: Dictionary = ProgressionS.new_player()
	var exg: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return pg)
	for k in 40:
		exg.on_kill(0)
	var elite_drop_empty: bool = exg.on_elite(0)
	_check("expédition: Sacoche 4 + 2 pleine -> Éclat de l'Élite refusé (« sacoche_pleine »), même flux : Sacoche vide -> 1 Éclat d'Élite",
		not elite_drop and exf.shards_refused == 1 and pf["shard_bag"] == _bag(4, 2) and elite_drop_empty and pg["shard_bag"] == _bag(0, 1))

# Jalon 15 bis : niveau des monstres dans l'isolat (n°37) et Éclats à ilvl. Références : Argon et Antho.
func _jalon_15b(solid1: Dictionary) -> void:
	var g1_in: Array = [[1, 0], [3, 0], [4, 0], [2, 1], [1, 5], [6, 1], [12, 3]]
	var g1: Array = []
	for c: Array in g1_in:
		g1.append(BA.get_segment_mob_level(0, c[0], c[1]))
	_check("G1: get_segment_mob_level(0, L, kills) (1,0) 1, (3,0) 1, (4,0) 4, (2,1) 2, (1,5) 1, (6,1) 6, (12,3) 10", g1 == [1, 1, 4, 2, 1, 6, 10], str(g1))
	var el6: Dictionary = CombatS.mob_stats(6, 0, "ELITE")
	var no6: Dictionary = CombatS.mob_stats(6, 0, "NORMAL")
	_check("G2: mob_stats(6, 0) Élite 1800 / 33 / 10, normal 240 / 21 / 10", el6 == {"hp": 1800, "atk": 33, "def": 10} and no6 == {"hp": 240, "atk": 21, "def": 10},
		"%s %s" % [str(el6), str(no6)])
	var g2: Array = [CombatS.damage(53, el6["def"], 6, false), CombatS.damage(53, el6["def"], 6, false, BA.SKILL_1_DMG_MULT),
		CombatS.damage(53, el6["def"], 6, false, BA.SKILL_2_DMG_MULT), CombatS.damage(el6["atk"], 15, 6, false)]
	_check("G2: joueur 213 / 53 / 15 Nv 6 contre l'Élite Nv 6 -> 48, 106, 170 ; l'Élite lui fait 29", g2 == [48, 106, 170, 29], str(g2))
	# G3 : Combattant 6, 1 Élite tué
	var ps: Dictionary = ProgressionS.new_player()
	ps["voc_xp"]["COMBATTANT"] = BA.get_cumulative_xp(7) - 1
	ps["elite_kills"] = 1
	var ctx: Array = _seg_ctx(solid1, Vector2(0, 6240), func() -> Dictionary: return ps)
	var sp: Node2D = ctx[0]
	var seg: Node2D = ctx[1]
	sp.set_level(6)
	_seg_frame(sp, seg)
	var node2: Node2D = seg.nodes()[2]
	var lv_start: Array = [seg.expedition.mob_level]
	for n: Node2D in seg.nodes():
		lv_start.append(n.mob_level())
	var el: Node2D = node2.elite()
	var mob: Node2D = node2.mobs()[0]
	var stats_ok: bool = [el.max_hp, el.atk, el.def] == [1800, 33, 10] and [mob.max_hp, mob.atk, mob.def] == [240, 21, 10]
	while mob.alive:
		node2._strike(mob)
	var lv_after_up: Array = [ProgressionS.combat_level(ps), sp.level, node2.mob_level(), el.max_hp, node2.mobs()[1].max_hp]
	sp.position = Vector2(0, 32)
	_seg_frame(sp, seg)
	var ended: bool = seg.expedition == null and seg.last_end == "retour"
	sp.position = Vector2(0, 6240)
	_seg_frame(sp, seg)
	var lv_next: Array = [seg.expedition.mob_level, node2.mob_level(), el.max_hp, el.hp]
	var el7: Dictionary = CombatS.mob_stats(7, 0, "ELITE")
	_check("G3: Combattant 6, 1 Élite tué -> segment 6 sur les 3 nœuds, Élite 1800 / 33 / 10, normal 240 / 21 / 10",
		lv_start == [6, 6, 6, 6] and stats_ok, "%s %s" % [str(lv_start), str([el.max_hp, el.atk, el.def, mob.max_hp, mob.atk, mob.def])])
	_check("G3: niveau 7 pendant l'expédition -> monstres au niveau 6 ; à l'expédition suivante, niveau 7",
		lv_after_up == [7, 7, 6, 1800, 240] and ended and lv_next == [7, 7, el7["hp"], el7["hp"]], "%s %s %s" % [str(lv_after_up), str(ended), str(lv_next)])
	_seg_free(ctx)
	# G4 : joueur neuf
	ctx = _seg_ctx(solid1, Vector2(0, 6240))
	_seg_frame(ctx[0], ctx[1])
	var el1: Dictionary = CombatS.mob_stats(1, 0, "ELITE")
	var no1: Dictionary = CombatS.mob_stats(1, 0, "NORMAL")
	var n2: Node2D = ctx[1].nodes()[2]
	_check("G4: joueur neuf -> segment au niveau 1 (== Combat.mob_level(0)), stats des jalons 10 à 15",
		ctx[1].expedition.mob_level == 1 and n2.mob_level() == CombatS.mob_level(0) and n2.elite().max_hp == el1["hp"] and n2.mobs()[0].max_hp == no1["hp"]
		and n2.mobs()[0].atk == no1["atk"], "%d %d %d" % [ctx[1].expedition.mob_level, n2.elite().max_hp, n2.mobs()[0].max_hp])
	_seg_free(ctx)
	# G5 : Éclat d'une expédition au niveau 6
	var pg: Dictionary = ProgressionS.new_player()
	var ex: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return pg, 6)
	ex.on_elite(0)
	var g5_want: Array = [[0, 0, "EEE", [["FLAT_ATK", 26.0]]], [0, 1, "EBE", [["FLAT_HP", 15.1762], ["FLAT_ATK", 14.4638]]],
		[1, 0, "", [["FLAT_HP", 26.0]]], [1, 1, "", [["FLAT_HP", 13.5393], ["FLAT_DEF", 16.1007]]]]
	_g5_want = g5_want
	var got: Array = []
	var g5_ok: bool = pg["shard_bag"] == _bag(0, 1, 6) and pg["elite_kills"] == 1
	for n in g5_want.size():
		var pn: Dictionary = ProgressionS.new_player()
		pn["shard_bag"] = _bag(1, 0, 6)
		pn["purify_n"] = n
		var piece: Dictionary = PurifS.preview(1, pn)
		got.append(_piece_str(n, piece))
		g5_ok = g5_ok and piece == EquipmentS.roll(1, n, false, 6) and _piece_is(piece, g5_want[n], 6)
	_check("G5: Éclat au niveau 6 -> shard_bag ilvl 6 ; roll(1, n, false, 6) pour n = 0 à 3 == références", g5_ok, str(pg["shard_bag"]) + "\n" + "\n".join(got))
	var foyer3: Array[int] = [BC.SchoolId.FOYER, BC.SchoolId.FOYER, BC.SchoolId.FOYER]
	var wa: float = BC.compute_weapon_atk(6, 0, foyer3)
	_check("G5: ATK d'arme Commune 3/3 à l'ilvl 6 == 33,6375", _approx(wa, 33.6375, 1e-9), "%.6f" % wa)
	# G6 : ordre de purification
	var po: Dictionary = ProgressionS.new_player()
	po["shard_bag"] = [{"elite": false, "ilvl": 1}, {"elite": false, "ilvl": 6}, {"elite": true, "ilvl": 1}]
	var bag_before: Array = po["shard_bag"].duplicate(true)
	PurifS.preview(1, po)
	var preview_kept: bool = po["shard_bag"] == bag_before and po["purify_n"] == 0
	var order: Array = []
	for k in 3:
		var lg: Dictionary = PurifS.commit(po, PurifS.preview(1, po), false, "VILLAGE")
		order.append([lg["source"], lg["ilvl"]])
	_check("G6: Sacoche [N1, N6, E1] -> Élite d'abord, puis ilvl 6, puis ilvl 1 ; l'aperçu ne retire rien",
		preview_kept and order == [["ELITE", 1], ["NORMAL", 6], ["NORMAL", 1]] and po["shard_bag"].is_empty(), str(order))
	# G7 : sauvegarde
	var st: Dictionary = SaveS.new_state(7, D0, 0)
	st["seq"] = 1 # new_state pose seq 0, refusé par unpack
	var p15: Dictionary = st["player"]
	p15.erase("shard_bag")
	p15.erase("elite_kills")
	p15["shards"] = 2
	p15["shards_elite"] = 1
	var back: Dictionary = SaveS.unpack(SaveS.pack(st))
	_check("G7: player du jalon 15 (shards 2, shards_elite 1) -> [E1, N1, N1], elite_kills 0, anciennes clés retirées",
		not back.is_empty() and back["player"]["shard_bag"] == _bag(2, 1) and back["player"]["elite_kills"] == 0 and not back["player"].has("shards")
		and not back["player"].has("shards_elite"), str(back.get("player", {})))
	var good: Dictionary = SaveS.new_state(7, D0, 0)
	good["seq"] = 1 # idem
	var bad: Array = []
	var muts: Array[Callable] = [
		func(p: Dictionary) -> void: p["shard_bag"] = _bag(7, 0),
		func(p: Dictionary) -> void: p["shard_bag"] = _bag(1, 0, 0),
		func(p: Dictionary) -> void: p["shard_bag"] = _bag(1, 0, 11),
		func(p: Dictionary) -> void: p["shard_bag"] = [{"elite": 1, "ilvl": 1}],
		func(p: Dictionary) -> void: p["elite_kills"] = -1]
	for m: Callable in muts:
		var b: Dictionary = good.duplicate(true)
		m.call(b["player"])
		bad.append(SaveS.unpack(SaveS.pack(b)).is_empty())
	_check("G7: 7 Éclats, ilvl 0, ilvl 11, elite non booléen, elite_kills négatif -> refusé ; état témoin accepté",
		bad == [true, true, true, true, true] and not SaveS.unpack(SaveS.pack(good)).is_empty(), str(bad))

# Jalon 16 : minerais, cargaison, coffre, caisse et Forge du village (Volet F §1, §2, §5). Références : jumeau Python d'Antho.
var _t1_want: Array = []
var _t2_want: Array = []
var _g5_want: Array = []

func _craft_refs(tag: String, slot_of: Callable, level: int, cendre: bool, want: Array, ilvl: int) -> void:
	var got: Array = []
	var ok: bool = true
	for n in want.size():
		var piece: Dictionary = EquipmentS.craft(1, n, slot_of.call(n), level, cendre, 0)
		got.append(_piece_str(n, piece) + (" SUP" if piece["superior"] else ""))
		ok = ok and _piece_is(piece, want[n], ilvl) and not piece["superior"]
	_check("%s: craft(1, n, %s, %d, %s) pour n = 0 à %d == références" % [tag, "n % 4", level, "true" if cendre else "false", want.size() - 1], ok, "\n" + "\n".join(got))

func _jalon_16(solid1: Dictionary) -> void:
	# K0 : découpage de roll()
	var k0: bool = true
	for t: Array in [[false, _t1_want, 1], [true, _t2_want, 1], [false, _g5_want, 6]]:
		for n in t[1].size():
			k0 = k0 and _piece_is(EquipmentS.roll(1, n, t[0], t[2]), t[1][n], t[2])
	_check("K0: roll() après le découpage en build_piece == T1, T2 et G5", k0 and _t1_want.size() == 12 and _t2_want.size() == 6 and _g5_want.size() == 4)
	# K1
	var k1: Array = []
	for lf: int in [1, 3, 5, 10]:
		k1.append(BF.get_craft_with_cendre_rarity_weights(lf))
	var caps: Array = []
	for lm: int in [1, 5, 10]:
		var pm: Dictionary = ProgressionS.new_player()
		pm["voc_xp"]["MINEUR"] = BA.get_cumulative_xp(lm)
		caps.append(ExpeditionS.cargo_cap_kg(pm))
	_check("K1: poids de craft Forgeron 1 / 3 / 5 / 10 == [65,25,10] / [61,27,12] / [57,29,14] / [47,34,19]",
		k1 == [[65, 25, 10], [61, 27, 12], [57, 29, 14], [47, 34, 19]], str(k1))
	_check("K1: cargaison max Mineur 1 / 5 / 10 == 25,0 / 25,8 / 26,8 kg", _near_eps(caps, [25.0, 25.8, 26.8], 1e-9), str(caps))
	# K2 à K4
	var by4: Callable = func(n: int) -> int: return n % 4
	_craft_refs("K2", by4, 1, true, [
		[0, 2, "BEB", [["FLAT_ATK", 8.3480], ["PCT_ATK", 6.0], ["FLAT_DEF", 4.2520]]], [1, 1, "", [["FLAT_HP", 7.9151], ["FLAT_DEF", 5.7649]]],
		[2, 0, "", [["FLAT_ATK", 12.0]]], [3, 0, "", [["FLAT_HP", 12.0]]], [0, 0, "EBE", [["FLAT_HP", 12.0]]],
		[1, 2, "", [["FLAT_DEF", 6.4904], ["FLAT_HP", 5.2696], ["PCT_ASPD", 4.0]]]], 1)
	_craft_refs("K3", by4, 5, true, [
		[0, 2, "BEB", [["FLAT_ATK", 16.1394], ["PCT_ATK", 6.0], ["FLAT_DEF", 8.2206]]], [1, 2, "", [["FLAT_HP", 6.1620], ["FLAT_DEF", 8.9950], ["FLAT_ATK", 14.5390]]],
		[2, 0, "", [["FLAT_ATK", 23.2]]], [3, 0, "", [["FLAT_HP", 23.2]]], [0, 0, "EBE", [["FLAT_HP", 23.2]]],
		[1, 2, "", [["FLAT_DEF", 12.5482], ["FLAT_HP", 10.1878], ["PCT_ASPD", 4.0]]]], 5)
	_craft_refs("K4", by4, 5, false, [
		[0, 0, "BEE", [["FLAT_ATK", 23.2]]], [1, 0, "", [["FLAT_ATK", 23.2]]], [2, 0, "", [["FLAT_ATK", 23.2]]],
		[3, 0, "", [["FLAT_ATK", 23.2]]], [0, 0, "EEE", [["FLAT_HP", 23.2]]], [1, 0, "", [["FLAT_ATK", 23.2]]]], 5)
	# K5 : Qualité Supérieure
	var sup: Array = []
	var k5_got: Array = []
	for n in 10:
		var piece: Dictionary = EquipmentS.craft(1, n, 2, 1, true, 0)
		sup.append(piece["superior"])
		k5_got.append(_piece_str(n, piece) + (" SUP" if piece["superior"] else ""))
	var p8: Dictionary = EquipmentS.craft(1, 8, 2, 1, true, 0)
	var p9: Dictionary = EquipmentS.craft(1, 9, 2, 1, true, 0)
	_check("K5: craft(1, n, 2, 1, true) : n = 0 à 7 non Supérieures ; n = 8 et 9 Supérieures, Plastron Bon ilvl 3 == références",
		sup == [false, false, false, false, false, false, false, false, true, true]
		and _piece_is(p8, [2, 1, "", [["FLAT_DEF", 10.3080], ["FLAT_ATK", 9.7560]]], 3) and _piece_is(p9, [2, 1, "", [["PCT_ATK", 6.0], ["FLAT_DEF", 16.0160]]], 3),
		"\n" + "\n".join(k5_got))
	# C2 : 20 000 crafts
	var rar: Array[int] = [0, 0, 0]
	var n_sup: int = 0
	var n_draws: int = 20000
	for n in n_draws:
		var piece: Dictionary = EquipmentS.craft(7, n, 1, 5, true, 0)
		rar[piece["rarity"]] += 1
		n_sup += int(piece["superior"])
	var fr: Array = [float(rar[0]) / n_draws, float(rar[1]) / n_draws, float(rar[2]) / n_draws, float(n_sup) / n_draws]
	_check("C2: 20 000 craft(7, n, 1, 5, true) -> raretés 0,57 / 0,29 / 0,14, Supérieure 0,20 (±0,02)",
		absf(fr[0] - 0.57) <= 0.02 and absf(fr[1] - 0.29) <= 0.02 and absf(fr[2] - 0.14) <= 0.02 and absf(fr[3] - 0.20) <= 0.02, str(fr))
	# Cargaison : 13 nœuds, Mineur 1 ; jumeau B dont la cargaison est vidée avant chaque nœud
	var pa: Dictionary = ProgressionS.new_player()
	var pb: Dictionary = ProgressionS.new_player()
	var ea: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return pa)
	var eb: ExpeditionS = ExpeditionS.new(1, 0, func() -> Dictionary: return pb)
	var cargo12: int = -1
	for k in 13:
		ea.cendre = 0 # budget de saturation hors sujet ici : 13 nœuds dépassent les 80 d'une expédition
		eb.cendre = 0
		eb.cargo = 0
		ea.on_gather(0)
		eb.on_gather(0)
		if k == 11:
			cargo12 = ea.cargo
	_check("cargaison: Mineur 1, 12 nœuds -> 24, le 13e +1 (1 perdu) ; XP, Cendre et Éclats == jumeau sans plafond",
		cargo12 == 24 and ea.cargo == 25 and ea.xp == eb.xp and pa["cendre"] == pb["cendre"] and pa["shard_bag"] == pb["shard_bag"]
		and pa["voc_xp"] == pb["voc_xp"], "%d %d %d %d %d %d" % [cargo12, ea.cargo, ea.xp, eb.xp, pa["cendre"], pb["cendre"]])
	# Retour : coffre
	var pr: Dictionary = ProgressionS.new_player()
	var ctx: Array = _seg_ctx(solid1, Vector2(0, 6240), func() -> Dictionary: return pr)
	var sp: Node2D = ctx[0]
	var seg: Node2D = ctx[1]
	_seg_frame(sp, seg)
	seg.expedition.cargo = 24
	sp.position = Vector2(0, 32)
	_seg_frame(sp, seg)
	sp.position = Vector2(0, 6240)
	_seg_frame(sp, seg)
	_check("cargaison: retour au village -> coffre 24, cargaison de l'expédition suivante 0, aucune caisse",
		pr["chest"] == {"MINERAI_FER_BRAISE": 24} and seg.expedition.cargo == 0 and pr["crate"] == null, "%s %d" % [str(pr["chest"]), seg.expedition.cargo])
	_seg_free(ctx)
	# Caisse
	var pc: Dictionary = ProgressionS.new_player()
	var r1: Rect2i = SG.node_rect(1)
	var at1: Vector2 = VL.cell_center(r1.position + Vector2i(r1.size.x / 2, r1.size.y / 2))
	ctx = _seg_ctx(solid1, at1, func() -> Dictionary: return pc)
	sp = ctx[0]
	seg = ctx[1]
	_seg_frame(sp, seg)
	var active1: int = seg.active
	seg.expedition.cargo = 6
	var cell1: Vector2i = CombatS.cell_of(sp.position)
	sp.hp = 5
	sp.take_hit(9)
	var crate1: Variant = pc["crate"].duplicate(true) if pc["crate"] != null else null
	for f in 90:
		_seg_frame(sp, seg)
	var after_death1: String = seg.last_end
	sp.position = Vector2(0, 6240)
	_seg_frame(sp, seg)
	seg.expedition.cargo = 4
	var cell2: Vector2i = CombatS.cell_of(sp.position)
	sp.hp = 5
	sp.take_hit(9)
	var crate2: Variant = pc["crate"].duplicate(true) if pc["crate"] != null else null
	for f in 90:
		_seg_frame(sp, seg)
	_check("caisse: mort avec cargo 6 au nœud 1 -> {node 1, cellule de la mort, 6} ; fin « mort »",
		active1 == 1 and crate1 == {"node": 1, "cell": [cell1.x, cell1.y], "items": {"MINERAI_FER_BRAISE": 6}} and after_death1 == "mort", str(crate1))
	_check("caisse: nouvelle mort avec cargo 4 au nœud 2 -> {node 2, cellule de la mort, 10}, caisse visible au nœud 2",
		crate2 == {"node": 2, "cell": [cell2.x, cell2.y], "items": {"MINERAI_FER_BRAISE": 10}} and seg._crate.visible and seg._crate.get_parent() == seg.nodes()[2],
		str(crate2))
	sp.position = VL.cell_center(cell2)
	sp.hp = sp.max_hp
	_seg_frame(sp, seg)
	seg.expedition.cargo = 5 # place 20
	_seg_frame(sp, seg)
	var took_all: Array = [seg.expedition.cargo, pc["crate"], seg._crate.visible]
	pc["crate"] = {"node": 2, "cell": [cell2.x, cell2.y], "items": {"MINERAI_FER_BRAISE": 10}}
	seg._place_crate()
	seg.expedition.cargo = 22 # place 3
	_seg_frame(sp, seg)
	_check("caisse: ramassage avec 20 de place -> prend 10, caisse null ; avec 3 de place -> prend 3, reste 7",
		took_all == [15, null, false] and seg.expedition.cargo == 25 and pc["crate"] != null and pc["crate"]["items"]["MINERAI_FER_BRAISE"] == 7,
		"%s %d %s" % [str(took_all), seg.expedition.cargo, str(pc["crate"])])
	_seg_free(ctx)
	# Forge
	var pf: Dictionary = ProgressionS.new_player()
	pf["chest"] = {"MINERAI_FER_BRAISE": 8}
	pf["cendre"] = 30
	pf["voc_xp"]["COMBATTANT"] = BA.get_cumulative_xp(6)
	var ok1: bool = ForgeS.can_craft(pf, true, true)
	var r: Dictionary = ForgeS.craft(1, pf, 0, true, 0)
	var xp1: int = pf["voc_xp"]["FORGERON"]
	var pending_ok: bool = pf["forge_pending"] == EquipmentS.craft(1, 0, 0, 1, true, 0) \
		and _piece_is(pf["forge_pending"], [0, 2, "BEB", [["FLAT_ATK", 8.3480], ["PCT_ATK", 6.0], ["FLAT_DEF", 4.2520]]], 1)
	_check("forge: chest 8, cendre 30, Forgeron 1, Combattant 6 -> chest 4, cendre 5, forge_n 1, Forgeron +252 (126 × 2), pièce K2 n = 0 en attente",
		ok1 and pf["chest"]["MINERAI_FER_BRAISE"] == 4 and pf["cendre"] == 5 and pf["forge_n"] == 1 and xp1 == 252 and r["gain"]["gained"] == 252 and pending_ok
		and r["log"]["n"] == 0 and r["log"]["forgeron"] == 1, "%s %d" % [str(pf["chest"]), xp1])
	var busy: bool = ForgeS.can_craft(pf, false, true)
	ForgeS.choose(pf, true)
	var equipped: bool = pf["forge_pending"] == null and pf["equipment"][0]["rarity"] == 2 and pf["equipment"][0]["superior"] == false
	var refused_cendre: bool = not ForgeS.can_craft(pf, true, true)
	var refused_out: bool = not ForgeS.can_craft(pf, false, false)
	var ok2: bool = ForgeS.can_craft(pf, false, true)
	var r2: Dictionary = ForgeS.craft(1, pf, 1, false, 0)
	_check("forge: carte en attente -> refusé ; Équiper vide forge_pending ; 2e craft avec Cendre refusé (cendre 5), hors du village refusé, sans Cendre accepté -> +50 XP",
		not busy and equipped and refused_cendre and refused_out and ok2 and r2["gain"]["gained"] == 50 and pf["chest"]["MINERAI_FER_BRAISE"] == 0 and pf["cendre"] == 5
		and pf["forge_pending"]["rarity"] == 0 and not pf["forge_pending"]["superior"], "%d %s" % [r2["gain"]["gained"], str(pf["chest"])])
	# Sauvegarde
	_clean_saves()
	var ns: Dictionary = SaveS.new_state(7, D0, 0)
	ns["player"]["chest"] = {"MINERAI_FER_BRAISE": 12}
	ns["player"]["crate"] = {"node": 1, "cell": [3, 210], "items": {"MINERAI_FER_BRAISE": 6}}
	ns["player"]["forge_n"] = 4
	ns["player"]["forge_pending"] = EquipmentS.craft(1, 8, 2, 1, true, 0)
	SaveS.save(ns, D0, TEST_SAVE_DIR)
	var back: Dictionary = SaveS.load_latest(TEST_SAVE_DIR)
	_check("save: save puis load_latest rendent chest, crate, forge_n et forge_pending (Supérieure)",
		not back.is_empty() and back["player"]["chest"] == ns["player"]["chest"] and back["player"]["crate"] == ns["player"]["crate"] and back["player"]["forge_n"] == 4
		and back["player"]["forge_pending"] == ns["player"]["forge_pending"], str(back.get("player", {}).get("crate")))
	var old: Dictionary = back.duplicate(true)
	for k: String in ["chest", "crate", "forge_n", "forge_pending"]:
		old["player"].erase(k)
	var old_back: Dictionary = SaveS.unpack(SaveS.pack(old))
	_check("save: player du jalon 15 bis -> chest {}, crate null, forge_n 0, forge_pending null",
		not old_back.is_empty() and old_back["player"]["chest"] == {} and old_back["player"]["crate"] == null and old_back["player"]["forge_n"] == 0
		and old_back["player"]["forge_pending"] == null)
	var bad: Array = []
	var muts: Array[Callable] = [
		func(p: Dictionary) -> void: p["chest"] = {"MINERAI_FER_BRAISE": -1},
		func(p: Dictionary) -> void: p["crate"]["node"] = 3,
		func(p: Dictionary) -> void: p["crate"]["items"] = {"MINERAI_FER_BRAISE": 0},
		func(p: Dictionary) -> void: p["forge_pending"]["rarity"] = 5]
	for m: Callable in muts:
		var b: Dictionary = back.duplicate(true)
		m.call(b["player"])
		bad.append(SaveS.unpack(SaveS.pack(b)).is_empty())
	_check("save: chest négatif, crate de node 3, crate vide, forge_pending invalide -> refusé", bad == [true, true, true, true], str(bad))
	_clean_saves()

# Jalon 16 bis : Forge lisible (textes de forge_help et forge_block_reason, carte de résultat). Références : prompt d'Antho.
func _jalon_16b() -> void:
	var help: Array = [EqText.forge_help(true, 1, 126), EqText.forge_help(false, 1, 25), EqText.forge_help(true, 5, 252)]
	for h: PackedStringArray in help:
		print("      " + " | ".join(h))
	_check("forge_help(true, 1, 126) == 5 lignes de référence", help[0] == PackedStringArray(["Coût : 4 minerais + 25 Cendre",
		"Rareté : Commun 65 %, Bon 25 %, Rare 10 %", "Qualité Supérieure : 20 % de chance, +2 ilvl", "Pièce d'ilvl 1 (niveau de ton Forgeron)",
		"+126 XP de Forgeron"]))
	_check("forge_help(false, 1, 25) == 5 lignes de référence", help[1] == PackedStringArray(["Coût : 4 minerais", "Rareté : toujours Commun",
		"Qualité Supérieure : jamais", "Pièce d'ilvl 1 (niveau de ton Forgeron)", "+25 XP de Forgeron"]))
	_check("forge_help(true, 5, 252) : Commun 57 %, Bon 29 %, Rare 14 %, ilvl 5, +252 XP (rattrapage ×2)",
		help[2][1] == "Rareté : Commun 57 %, Bon 29 %, Rare 14 %" and help[2][3] == "Pièce d'ilvl 5 (niveau de ton Forgeron)"
		and help[2][4] == "+252 XP de Forgeron (rattrapage ×2)")
	var reasons: Array = [EqText.forge_block_reason(false, 8, 30, true, false), EqText.forge_block_reason(true, 2, 30, true, false),
		EqText.forge_block_reason(true, 3, 30, false, false), EqText.forge_block_reason(true, 8, 15, true, false),
		EqText.forge_block_reason(true, 8, 15, false, false), EqText.forge_block_reason(true, 8, 30, true, true)]
	print("      " + str(reasons))
	_check("forge_block_reason : village, 2 minerais, 1 minerai, 10 Cendre, \"\", choix en attente", reasons == ["Forge au village seulement",
		"Il manque 2 minerais", "Il manque 1 minerai", "Il manque 10 Cendre", "", "Choisis d'abord : Équiper ou Jeter"], str(reasons))
	_check("forge_cendre_row(100) (remplace forge_reserve, jalon 20 bis)", EqText.forge_cendre_row(100)
		== PackedStringArray(["Cendre 100/150", "25 Cendre par pièce, mode Avec Cendre"]), str(EqText.forge_cendre_row(100)))
	# Aperçu : même rattrapage que craft (Forgeron 1, Combattant 6 : +252 au test « forge » du jalon 16)
	var pf: Dictionary = ProgressionS.new_player()
	pf["voc_xp"]["COMBATTANT"] = BA.get_cumulative_xp(6)
	var prev: Array = [ForgeS.xp_preview(pf, true, 0), ForgeS.xp_preview(pf, false, 0), ForgeS.piece_level(pf, 0), ForgeS.piece_level(pf, 1)]
	pf["chest"] = {"MINERAI_FER_BRAISE": 4}
	pf["cendre"] = 25
	var xp_before: Dictionary = pf["voc_xp"].duplicate()
	var got: int = ForgeS.craft(1, pf, 0, true, 0)["gain"]["gained"]
	_check("forge: xp_preview 252 / 50 == gain du craft, sans rien modifier ; piece_level 1, borné à 11 en isolat 1",
		prev == [252, 50, 1, 11] and got == 252 and xp_before["FORGERON"] == 0, str(prev))
	# Carte de résultat (scène dépliée réelle)
	var ui: CanvasLayer = load("res://scenes/ui/ui_unfolded.tscn").instantiate()
	root.add_child(ui)
	ui.notification(Node.NOTIFICATION_READY) # root hors de l'arbre pendant _initialize : ni @onready ni _ready sans cette notification
	# Carte en 2 colonnes (jalon 20 bis) : tête = 1re ligne de la carte, Supérieure = étiquette de la tête, verdict calculé dedans
	var head: Label = ui.get_node("Margin/VBox/Monde/Apercu/Box").get_child(0).find_children("*", "Label", true, false)[0]
	var sup: Label = ui.get_node("Margin/VBox/Monde/Apercu/Box").get_child(0).find_child("Tag", true, false)
	var verdict: Label = ui.get_node("Margin/VBox/Monde/Apercu/Box/Verdict")
	var st: Dictionary = {"hp": 100, "atk": 22, "def": 5, "period": 1.0 / 1.2, "crit_rate": 0.05, "crit_mult": 1.5}
	var st_up: Dictionary = st.duplicate()
	st_up["atk"] = 30
	var st_down: Dictionary = st.duplicate()
	st_down["hp"] = 90
	ui.show_preview(EquipmentS.craft(1, 8, 2, 1, true, 0), null, st, st_up, true)
	var card1: Array = [head.text.get_slice("\n", 0), sup.text != "", verdict.text, verdict.get_theme_color("font_color")]
	ui.show_preview(EquipmentS.craft(1, 0, 2, 1, true, 0), null, st, st_down, false)
	var card2: Array = [head.text.get_slice("\n", 0), sup.text, verdict.text, verdict.get_theme_color("font_color")]
	_check("carte: K5 n = 8 forgée -> « Pièce forgée », Supérieure en étiquette ambrée, verdict vert ; n = 0 purifiée -> sans étiquette, verdict vermillon",
		card1 == ["Pièce forgée", true, "Meilleure que l'équipée", Color("#009E73")]
		and card2 == ["Pièce purifiée", "", "Moins bonne que l'équipée", Color("#D55E00")]
		and sup.get_theme_color("font_color") == Color("#E69F00"), str(card1) + str(card2))
	var cmp: Array = []
	for m: Dictionary in [{"atk": 30}, {"hp": 90}, {"atk": 30, "def": 4}, {}, {"period": 1.0 / 1.3}, {"crit_rate": 0.04}]:
		var after_st: Dictionary = st.duplicate()
		after_st.merge(m, true)
		cmp.append(EqText.compare(st, after_st))
	_check("compare: ATK +8 -> 1 ; PV -10 -> -1 ; ATK +8 DEF -1 -> 0 ; identique -> 0 ; cadence plus rapide -> 1 ; critique -1 % -> -1", cmp == [1, -1, 0, 0, 1, -1], str(cmp))
	ui.set_forge_enabled(func(_c: bool) -> String: return "Il manque 2 minerais")
	var reason: Label = ui.get_node(UiS.PAGES + "Forge/Raison")
	var grey: bool = reason.visible and reason.text == "Il manque 2 minerais" and ui.get_node(UiS.PAGES + "Forge/Boutons").get_child(0).disabled
	ui.set_forge_enabled(func(_c: bool) -> String: return "")
	_check("panneau: raison visible sous les boutons grisés, masquée quand le craft est possible",
		grey and not reason.visible and not ui.get_node(UiS.PAGES + "Forge/Boutons").get_child(0).disabled)
	ui.free()

func _ui_ready(path: String) -> CanvasLayer:
	var ui: CanvasLayer = load(path).instantiate()
	root.add_child(ui)
	ui.notification(Node.NOTIFICATION_READY) # root hors de l'arbre pendant _initialize (voir _jalon_16b)
	# Hors arbre, un Button garde le style lu à sa construction : sa variation de thème (Onglet) n'est lue qu'au THEME_CHANGED.
	ui.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)
	return ui

# Atlas de l'icône : [chemin de la planche, région].
func _icon_of(tex: Texture2D) -> Array:
	return [tex.atlas.resource_path, tex.region] if tex is AtlasTexture else []

# Jalon 17 : bandeau à icônes, fenêtre unique et 4 onglets. Références : prompt d'Antho (maquette-jalon17.png, prep_jalon_17.py).
func _jalon_17() -> void:
	var p: Dictionary = ProgressionS.new_player()
	p["cendre"] = 75
	p["shard_bag"] = _bag(1, 1)
	var hud: Array = [EqText.hud_values(0, p, 12, null, true), EqText.hud_values(0, p, 12, [8.0, 30.0], true),
		EqText.hud_values(0, p, 12, null, false), EqText.hud_values(0, p, 12, [8.0, 30.0], false)]
	for h: Array in hud:
		print("      " + str(h))
	_check("hud_values: plié village, plié Brume, déplié village, déplié Brume (1 Éclat d'Élite sans effet)", hud == [
		[["cendre", "75/150"], ["eclats", "2/6"]],
		[["cendre", "75/150"], ["eclats", "2/6"], ["minerai", "8/30"]],
		[["or", "0"], ["cendre", "75/150"], ["eclats", "2/6"], ["minerai", "12"]],
		[["or", "0"], ["cendre", "75/150"], ["eclats", "2/6"], ["minerai", "8/30"]]], str(hud))
	var weapon: PackedStringArray = EqText.piece_lines(0, p["equipment"][0])
	print("      " + " | ".join(weapon))
	_check("piece_lines(arme): « Arme : Épée & Écu Commune, ilvl 1 » puis « Enclume 3/3, ATK d'arme 10,4 » en retrait",
		weapon[0] == "Arme : Épée & Écu Commune, ilvl 1" and weapon[1] == "    Enclume 3/3, ATK d'arme 10,4", str(weapon))
	var st: PackedStringArray = EqText.stats_lines({"hp": 154, "atk": 30, "def": 13, "period": 1.0 / 1.2, "crit_rate": 0.05, "crit_mult": 1.5})
	_check("stats_lines: 2 lignes", st == PackedStringArray(["PV 154  ATK 30  DEF 13", "Cadence 1,20/s  Critique 5 % ×1,5"]), str(st))
	var p0: Dictionary = p.duplicate(true)
	p0["shard_bag"] = []
	# sacoche_lines remplacée au jalon 20 par cendre_row / shards_row / ore_row (mêmes fixtures)
	var sac: Array = [EqText.cendre_row(p["cendre"]), EqText.shards_row(p["shard_bag"]), EqText.ore_row(12), EqText.shards_row(p0["shard_bag"]), EqText.ore_row(1)]
	print("      " + str(sac))
	_check("Sacoche (jalon 20) : (2 Éclats dont 1 d'Élite, 12 minerais) et (0 Éclat, 1 minerai)", sac == [
		PackedStringArray(["Cendre 75/150", "Lanterne niveau 1"]), PackedStringArray(["Éclats 2/6, dont 1 d'Élite", "Purification au village ou au Brasero"]),
		PackedStringArray(["Coffre : 12 minerais", "4 minerais par pièce à la Forge"]), PackedStringArray(["Éclats 0/6", "Purification au village ou au Brasero"]),
		PackedStringArray(["Coffre : 1 minerai", "4 minerais par pièce à la Forge"])], str(sac))
	var why: Array = [EqText.purify_block_reason(false, false, 0, 2, false), EqText.purify_block_reason(false, true, 2, 2, false),
		EqText.purify_block_reason(true, false, 0, 0, false), EqText.purify_block_reason(false, true, 1, 2, false),
		EqText.purify_block_reason(true, false, 0, 2, true)]
	print("      " + str(why))
	_check("purify_block_reason: village ou Brasero, quota, Sacoche vide, \"\", choix en attente", why == ["Purification au village ou au Brasero",
		"Déjà 2 purifications au Brasero cette expédition", "Sacoche vide", "", "Choisis d'abord : Équiper ou Jeter"], str(why))
	# Scènes réelles
	var uf: CanvasLayer = _ui_ready("res://scenes/ui/ui_folded.tscn")
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var hud_want: Dictionary = {"Or": ["res://assets/icons/hud/coin_05d.png", Rect2(1, 1, 14, 15)],
		"Cendre": ["res://assets/icons/hud/campfire_16x16.png", Rect2(2, 0, 12, 16)],
		"Eclats": ["res://assets/icons/hud/item_gem_quartz.png", Rect2(1, 1, 14, 14)],
		"Minerai": ["res://assets/icons/hud/Stones_ores_gems_without_grass.png", Rect2(0, 22, 15, 10)]}
	var bad: String = ""
	for k: String in hud_want:
		if _icon_of(uu.get_node("Margin/VBox/Hud/Ligne/%s/Icone" % k).texture) != hud_want[k]:
			bad += "déplié " + k + " "
		if k != "Or" and _icon_of(uf.get_node("Margin/VBox/Hud/Ligne/%s/Icone" % k).texture) != hud_want[k]:
			bad += "plié " + k + " "
	var td: String = "res://assets/tiles/kenney_tiny_dungeon/tilemap_packed.png"
	var tt: String = "res://assets/tiles/kenney_tiny_town/tilemap_packed.png"
	var tab_want: Dictionary = {"Perso": [td, Rect2(64, 144, 16, 16)], "Sacoche": [tt, Rect2(176, 128, 16, 16)],
		"Forge": [td, Rect2(32, 96, 16, 16)], "PNJ": [td, Rect2(48, 128, 16, 16)], "Village": [tt, Rect2(128, 128, 16, 16)],
		"Options": [tt, Rect2(176, 96, 16, 16)]} # PNJ et Village : jalon 18
	var tabs: Array[Button] = []
	var order: Array = []
	for b: Node in uu.get_node("Margin/VBox/Onglets").get_children():
		order.append(String(b.name))
	if order != tab_want.keys():
		bad += "ordre " + str(order) + " "
	for k: String in tab_want:
		var b: Button = uu.get_node("Margin/VBox/Onglets/" + k)
		tabs.append(b)
		if _icon_of(b.icon) != tab_want[k] or b.text != "" or b.expand_icon:
			bad += "onglet " + k + " "
	_check("icônes: 4 du bandeau (fichier et région, Or absent du plié) et 6 onglets dans l'ordre (TD 112, TT 107, TD 74, TD 99, TT 104, TT 83), sans texte", bad == "", bad)
	var kyrise: Label = uu.get_node("Credits").get_node_or_null("Margin/VBox/Kyrise")
	_check("credits: ligne Kyrise", kyrise != null and kyrise.text
		== "Icône de l'Or : Kyrise's Free 16x16 RPG Icon Pack, par Kyrise, CC BY 4.0 (creativecommons.org/licenses/by/4.0)")
	var gone: String = ""
	for n: String in ["Gold", "Vocations", "Lanterne", "Expedition"]:
		if uf.find_child(n, true, false) != null or uu.find_child(n, true, false) != null:
			gone += n + " "
	_check("scenes: plié sans couple Or ni onglet ; Gold, Vocations, Lanterne, Expedition absents des deux couches",
		uf.find_child("Or", true, false) == null and uf.find_child("Onglets", true, false) == null and gone == "", gone)
	_check("scenes: déplié, 6 onglets (jalon 18) et une seule Fenetre", uu.get_node("Margin/VBox/Onglets").get_child_count() == 6
		and uu.find_children("Fenetre", "", true, false).size() == 1)
	# Jauge de saturation et bandeau en expédition
	var gauge: ProgressBar = uf.get_node("Margin/VBox/Jauge")
	uf.show_player(p, 12)
	var g: Array = [gauge.visible]
	uf.show_expedition(true, 40, 1, 8.0, 30.0)
	g.append_array([gauge.visible, gauge.ratio, uf.get_node("Margin/VBox/Hud/Ligne/Minerai").visible, uf.get_node("Margin/VBox/Hud/Ligne/Minerai/Valeur").text])
	uf.show_expedition(false, 0, 0, 0.0, 0.0)
	g.append_array([gauge.visible, uf.get_node("Margin/VBox/Hud/Ligne/Minerai").visible])
	print("      jauge " + str(g) + " ; max_value %d" % gauge.max_value)
	_check("jauge: masquée hors expédition, 40 / SEGMENT_PRE_ELITE_CENDRE_BUDGET en expédition, minerai 8/30 au bandeau plié",
		g == [false, true, 40.0 / BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET, true, "8/30", false, false], str(g))
	# Menu
	var win: Control = uu.get_node("Margin/VBox/Monde/Fenetre")
	var title: Label = uu.get_node("Margin/VBox/Monde/Fenetre/Box/Barre/Ligne/Titre")
	var page: Callable = func() -> String:
		for c: Control in uu.get_node(UiS.PAGES).get_children():
			if c.visible:
				return c.name
		return ""
	var m: Array = [[win.visible, page.call()]]
	tabs[2].button_pressed = true
	m.append([win.visible, page.call(), title.text])
	tabs[0].button_pressed = true
	m.append([win.visible, page.call(), title.text, tabs[2].button_pressed])
	var st0: Dictionary = {"hp": 100, "atk": 22, "def": 5, "period": 1.0 / 1.2, "crit_rate": 0.05, "crit_mult": 1.5}
	uu.show_preview(EquipmentS.craft(1, 8, 2, 1, true, 0), null, st0, st0, true)
	m.append([win.visible, tabs[0].disabled, tabs[5].disabled])
	uu.hide_preview()
	m.append([win.visible, page.call(), tabs[0].disabled])
	uu.get_node("Margin/VBox/Monde/Fenetre/Box/Barre/Ligne/Fermer").pressed.emit()
	m.append([win.visible, tabs[0].button_pressed])
	tabs[5].button_pressed = true
	uu.get_node(UiS.PAGES + "Options/CreditsButton").pressed.emit()
	m.append([win.visible, title.text, uu.get_node("Credits").visible])
	tabs[5].button_pressed = false
	m.append([win.visible])
	print("      menu " + str(m))
	_check("menu: aucun onglet, Forge, Perso (un seul), carte -> fenêtre masquée et onglets grisés, retour à Perso, « × » referme, Options -> Crédits, 2e appui referme",
		m == [[false, ""], [true, "Forge", "Forge"], [true, "Perso", "Perso", false], [false, true, true], [true, "Perso", false],
		[false, false], [true, "Options", true], [false]], str(m))
	# Gabarit, zone 308 × 408
	uu.fit_window(408.0)
	var bandeau: float = uu.get_node("Margin/VBox/Hud").get_combined_minimum_size().y
	var jauge: float = uu.get_node("Margin/VBox/Jauge").get_combined_minimum_size().y
	var onglets: float = 0.0 # hauteur de l'HBox = bouton le plus haut ; get_minimum_size : le cache combiné reste périmé hors arbre
	for b: Button in tabs:
		onglets = maxf(onglets, b.get_minimum_size().y)
	var win_h: float = -win.offset_top
	var win_top: float = 408.0 - onglets - win_h # bas de Monde = haut des onglets
	print("      gabarit bandeau %d, jauge %d, onglets %d, fenêtre %d (y %d à %d)" % [bandeau, jauge, onglets, win_h, win_top, win_top + win_h])
	_check("gabarit 308 × 408: bandeau 20, onglets 20, fenêtre 204 au-dessus des onglets, sans recouvrir bandeau ni jauge",
		bandeau == 20.0 and onglets == 20.0 and win_h == 204.0 and win.anchor_top == 1.0 and win.offset_bottom == 0.0
		and win_top >= bandeau + jauge, "%d %d %d" % [bandeau, onglets, win_h])
	uf.free()
	uu.free()

# Jalon 18 : onglets PNJ et Village, réglages différés. Références : sortie de prep_jalon_18.py (fixtures reprises telles quelles).
func _jalon_18() -> void:
	var pool_names: Dictionary = VText.load_names()
	var names: Dictionary = pool_names.duplicate()
	# Noms des fixtures du jumeau ; en jeu, names["npcs"] vient de la graine (VText.with_identities, Z7)
	names["npcs"] = [{"name": "Gaspard", "g": "M"}, {"name": "Margaux", "g": "F"}, {"name": "Ulric", "g": "M"}, {"name": "Thibaut", "g": "M"},
		{"name": "Odile", "g": "F"}]
	var sprites: Array = VL.load_data()["npc_sprites"]
	var ids: Array = VText.npc_identities(18, pool_names, sprites)
	var genders_ok: bool = true
	var distinct_ok: bool = true
	var sets: Dictionary = {}
	for sd in 200:
		var who: Array = VText.npc_identities(sd, pool_names, sprites)
		var five: Array = who.map(func(x: Dictionary) -> String: return x["name"])
		genders_ok = genders_ok and who[0]["g"] == "M" and who[1]["g"] == "F" and who[2]["g"] == "M"
		for x: Dictionary in who:
			genders_ok = genders_ok and x["name"] in pool_names["name_pool"][x["g"]]
		var uniq: Dictionary = {}
		for n: String in five:
			uniq[n] = true
		distinct_ok = distinct_ok and uniq.size() == 5
		five.sort()
		sets[str(five)] = true
	var g34: Dictionary = {}
	for sd in 200:
		var who: Array = VText.npc_identities(sd, pool_names, sprites)
		g34[who[3]["g"]] = true
		g34[who[4]["g"]] = true
	var first5: Array = ids.map(func(x: Dictionary) -> String: return x["name"])
	var other5: Array = VText.npc_identities(19, pool_names, sprites).map(func(x: Dictionary) -> String: return x["name"])
	print("      noms graine 18 %s, graine 19 %s, %d villages distincts sur 200, genres des chevaliers %s" % [str(first5), str(other5), sets.size(), str(g34.keys())])
	_check("noms: sprites TD 86 / 99 / 87 -> M / F / M, chevaliers libres (M et F tirés), 5 noms distincts par village sur 200 graines, même graine = mêmes noms, 18 != 19",
		sprites.slice(0, 3) == ["pnj_mineur", "pnj_aubergiste", "pnj_forgeron"] and genders_ok and distinct_ok and g34.size() == 2
		and VText.npc_identities(18, pool_names, sprites) == ids and first5 != other5 and sets.size() == 200, "%s %s %d" % [genders_ok, distinct_ok, sets.size()])
	var traits_ok: bool = true
	for sd in 20:
		var before: Array = NewGameS.village(sd, D0, 0)["npcs"].map(func(n: Dictionary) -> Array: return n["traits"])
		VText.npc_identities(sd, pool_names, sprites)
		var after: Array = NewGameS.village(sd, D0, 0)["npcs"].map(func(n: Dictionary) -> Array: return n["traits"])
		for i in NewGameS.START_POSTS.size():
			traits_ok = traits_ok and before[i] == after[i] and after[i] == NewGameS.draw_traits(RngS.make_rng(sd, "npc/%d" % i))
	_check("noms: RNG « npc/name/i » à part, traits identiques avant / après et égaux au tirage « npc/i » (20 graines)", traits_ok)
	var font: Font = load(FONT_PATH)
	var widest: String = ""
	var missing: String = ""
	for g: String in ["M", "F"]:
		for n: String in pool_names["name_pool"][g]:
			for ch: String in n:
				if not font.has_char(ch.unicode_at(0)):
					missing += ch
			var head: String = "%s : Extraction, 2 étoiles, %s" % [n, "gérant" if g == "M" else "gérante"]
			if font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x > font.get_string_size(widest, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x:
				widest = head
	var ww: float = font.get_string_size(widest, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	print("      en-tête le plus large : « %s » %d px" % [widest, ww])
	_check("noms: tous les glyphes dans Silkscreen, en-tête le plus large <= 296 px (borne du jumeau)", missing == "" and ww <= 296.0, missing + " %d" % ww)
	var fx: Array = [
		[0, {"post": "EXTRACTION", "stars": 2, "cadence": "NORMAL", "moral": 80, "on_strike": false, "tool_broken": false, "tool_durability": 64.0, "traits": [1, 4], "manages": "MAT"}, 10],
		[1, {"post": "TAVERN", "stars": 2, "cadence": "FORGE_ARDENTE", "cadence_next": "PAISIBLE", "moral": 49, "on_strike": false, "tool_broken": true, "tool_durability": 0.0, "traits": [5], "manages": "TAVERN"}, 23],
		[2, {"post": "FORGE", "stars": 1, "cadence": "NORMAL", "moral": 15, "on_strike": true, "tool_broken": false, "tool_durability": 99.5, "traits": [3, 1], "manages": "FORGE"}, 10],
		[4, {"post": "GUARD", "stars": 2, "cadence": "NORMAL", "moral": 85, "on_strike": false, "tool_broken": false, "tool_durability": 100.0, "traits": [0, 4], "manages": ""}, 23]]
	var want_npc: Array = [
		["Gaspard : Extraction, 2 étoiles, gérant", "Traits : Costaud, Bosseur", "Griffe : Charpente Renforcée (stock max ×1,15)", "Moral 80/100 : production ×1,00", "Maintenant : au travail", "Outil : 64 %"],
		["Margaux : Taverne, 2 étoiles, gérante", "Traits : Bout-en-train", "Griffe : Auberge Chaleureuse (+2 Moral par jour à tous)", "Moral 49/100 : production ×0,75", "Maintenant : endormie", "Outil : brisé, production ×0,60"],
		["Ulric : Forge, 1 étoile, gérant", "Traits : Tête-en-l'air, Costaud", "Griffe : Tarif Étourdi (prix max ×1,15)", "Moral 15/100 : en grève, ne travaille pas", "Maintenant : se réchauffe à l'Âtre", "Outil : 100 %"],
		["Odile : Garde, 2 étoiles", "Traits : Noctambule, Bosseuse", "Moral 85/100", "Maintenant : au travail"]]
	var bad: String = ""
	for k in fx.size():
		var traits: Array[int] = []
		traits.assign(fx[k][1]["traits"])
		fx[k][1]["traits"] = traits
		var got: PackedStringArray = VText.npc_lines(fx[k][1], fx[k][0], fx[k][2], names)
		print("      (%d, %dh) %s" % [fx[k][0], fx[k][2], str(got)])
		if got != PackedStringArray(want_npc[k]):
			bad += "%d " % fx[k][0]
	_check("npc_lines: 4 fixtures du jumeau (gérant / gérante, étoiles, Moral 80 / 49 / grève / garde, outil 64 / brisé / 99,5, endormie, Âtre, Noctambule)", bad == "", bad)
	var cad: Array = [VText.cadence_help("PAISIBLE", "", names), VText.cadence_help("NORMAL", "", names), VText.cadence_help("FORGE_ARDENTE", "", names),
		VText.cadence_help("FORGE_ARDENTE", "PAISIBLE", names), VText.cadence_help("NORMAL", "NORMAL", names)]
	print("      " + str(cad))
	_check("cadence_help: 3 sans attente, « Demain : Paisible », attente égale = sans attente", cad == ["Paisible : production ×0,80, Moral -6/jour",
		"Normal : production ×1,00, Moral -12/jour", "Forge ardente : production ×1,30, Moral -24/jour",
		"Demain : Paisible (production ×0,80, Moral -6/jour)", "Normal : production ×1,00, Moral -12/jour"], str(cad))
	var gr: Array = []
	for t in 6:
		gr.append(VText.griffe_text(t, names))
	_check("griffe_text: 6 enseignes", gr == ["Lanterne de Veille (24 h/24, +3 Lien par fiche)", "Charpente Renforcée (stock max ×1,15)",
		"Comptoir Méticuleux (+4 Lien par cadeau)", "Tarif Étourdi (prix max ×1,15)", "Service Express (+3 Lien au Coup de feu)",
		"Auberge Chaleureuse (+2 Moral par jour à tous)"], str(gr))
	var sx: Array = [
		["MAT", {"stock": 0, "lvl": 1, "posture": "EQUILIBRE", "griffe_trait": 1, "treasury": 150}, 0, 0],
		["TAVERN", {"stock": 12, "lvl": 1, "posture": "SOLIDAIRE", "posture_next": "EXPORTATION", "griffe_trait": 5, "treasury": 37}, 0, 1],
		["FORGE", {"stock": 3, "lvl": 1, "posture": "EXPORTATION", "griffe_trait": 3, "treasury": 0}, 0, 2],
		["MAT", {"stock": 0, "lvl": 1, "posture": "EQUILIBRE", "griffe_trait": 1, "treasury": 150}, 2, 0],
		["TAVERN", {"stock": 12, "lvl": 1, "posture": "SOLIDAIRE", "griffe_trait": 5, "treasury": 37}, 2, 1]]
	var want_shop: Array = [
		["Gérant : Gaspard", "Stock 0 / cible 41 / max 69", "Prix 3 Or, rachat 1 Or", "Trésorerie 150 Or", "Équilibre : cible 60 % du stock, taxe 20 %"],
		["Gérante : Margaux", "Stock 12 / cible 12 / max 30", "Prix 8 Or, rachat 4 Or", "Trésorerie 37 Or", "Demain : Exportation (cible 85 % du stock, taxe 30 %)"],
		["Gérant : Ulric", "Stock 3 / cible 26 / max 30", "Prix 14 Or, rachat 8 Or", "Trésorerie 0 Or", "Exportation : cible 85 % du stock, taxe 30 %"],
		["Gérant : Gaspard", "Stock 0 / cible 41 / max 69", "Prix 3 Or, rachat 1 Or", "Trésorerie 150 Or", "Équilibre : cible 60 % du stock, taxe 20 %"],
		["Gérante : Margaux", "Stock 12 / cible 12 / max 30", "Prix 10 Or, rachat 6 Or", "Trésorerie 37 Or", "Solidaire : cible 40 % du stock, taxe 10 %"]]
	bad = ""
	for k in sx.size():
		var got: PackedStringArray = VText.shop_lines(sx[k][0], sx[k][1], sx[k][2], sx[k][3], names)
		got.append(VText.posture_help(sx[k][1]["posture"], sx[k][1].get("posture_next", ""), names))
		print("      (%s, isolat %d) %s" % [sx[k][0], sx[k][2], str(got)])
		if got != PackedStringArray(want_shop[k]):
			bad += "%d " % k
	_check("shop_lines + posture_help: 5 fixtures du jumeau", bad == "", bad)
	var pos: Array = [VText.posture_help("SOLIDAIRE", "", names), VText.posture_help("EQUILIBRE", "", names), VText.posture_help("EXPORTATION", "", names)]
	_check("posture_help: 3 sans attente", pos == ["Solidaire : cible 40 % du stock, taxe 10 %", "Équilibre : cible 60 % du stock, taxe 20 %",
		"Exportation : cible 85 % du stock, taxe 30 %"], str(pos))
	# atre_lines remplacée au jalon 19 bis par atre_head / atre_detail (_jalon_19b)
	# DAG : réglage différé, effet au prochain tick
	var day: int = 86400
	var v0: Dictionary = NewGameS.village(18, D0, 0)
	var vk: Dictionary = v0.duplicate(true)
	Dag.set_next(vk["npcs"][0], "cadence", "FORGE_ARDENTE")
	Dag.set_next(vk["shops"]["MAT"], "posture", "EXPORTATION")
	var same: Dictionary = Dag.resume(vk, D0 + 3600)
	_check("dag: reprise le même jour -> cadence NORMAL et posture EQUILIBRE, clés conservées", not same["ticked"]
		and same["village"]["npcs"][0]["cadence"] == "NORMAL" and same["village"]["npcs"][0]["cadence_next"] == "FORGE_ARDENTE"
		and same["village"]["shops"]["MAT"]["posture"] == "EQUILIBRE" and same["village"]["shops"]["MAT"]["posture_next"] == "EXPORTATION")
	var ctrl: Dictionary = Dag.resume(v0, D0 + day + 3600)
	var nxt: Dictionary = Dag.resume(vk, D0 + day + 3600)
	var n0: Dictionary = nxt["village"]["npcs"][0]
	var m_before: int = ctrl["village"]["npcs"][0]["moral"]
	var back: Dictionary = nxt["village"].duplicate(true)
	back["npcs"][0]["cadence"] = "NORMAL"
	back["shops"]["MAT"]["posture"] = "EQUILIBRE"
	print("      tick : Moral %d (témoin %d), cadence %s, posture %s, clés %s / %s" % [n0["moral"], m_before, n0["cadence"],
		nxt["village"]["shops"]["MAT"]["posture"], n0.has("cadence_next"), nxt["village"]["shops"]["MAT"].has("posture_next")])
	_check("dag: tick du lendemain calculé en NORMAL / EQUILIBRE (identique au témoin sans clé), puis FORGE_ARDENTE / EXPORTATION, clés effacées",
		nxt["ticked"] and back == ctrl["village"] and nxt["dag"] == ctrl["dag"] and n0["cadence"] == "FORGE_ARDENTE" and not n0.has("cadence_next")
		and nxt["village"]["shops"]["MAT"]["posture"] == "EXPORTATION" and not nxt["village"]["shops"]["MAT"].has("posture_next"))
	# Moral du témoin = Eco.npc_daily_tick en NORMAL, depuis le Moral d'avant tick (bonus de stock plein compris)
	var pre: Dictionary = v0.duplicate(true)
	var pre_r: Dictionary = Dag.resume(pre, D0 + day + 3600)
	var npc0: Dictionary = v0["npcs"][0]
	var t0: Array[int] = []
	t0.assign(npc0["traits"])
	var mgr: Array = []
	for n: Dictionary in v0["npcs"]:
		if n["manages"] != "":
			mgr.append(n["traits"])
	var m_in: int = mini(npc0["moral"] + pre_r["dag"]["MAT"]["moral_bonus"], int(BB.MORAL_MAX))
	var want_m: int = Eco.npc_daily_tick(m_in, false, "NORMAL", "EATEN" if 0 < pre_r["dag"]["meals"] else "OFFLINE", npc0["house_lvl"], t0, Eco.griffe_moral_bonus(mgr))["moral"]
	_check("dag: Moral du PNJ 0 au tick = Eco.npc_daily_tick(... \"NORMAL\" ...)", n0["moral"] == want_m, "%d %d" % [n0["moral"], want_m])
	# La reprise suivante utilise la nouvelle posture et la nouvelle cadence
	var v_new: Dictionary = ctrl["village"].duplicate(true)
	v_new["npcs"][0]["cadence"] = "FORGE_ARDENTE"
	v_new["shops"]["MAT"]["posture"] = "EXPORTATION"
	_check("dag: reprise suivante = celle d'un village réglé directement", Dag.resume(nxt["village"], D0 + day + 7200) == Dag.resume(v_new, D0 + day + 7200))
	var eq: Dictionary = v0.duplicate(true)
	Dag.set_next(eq["npcs"][0], "cadence", "FORGE_ARDENTE")
	Dag.set_next(eq["npcs"][0], "cadence", "NORMAL")
	var raw: Dictionary = v0.duplicate(true)
	raw["npcs"][0]["cadence_next"] = "NORMAL"
	var raw_r: Dictionary = Dag.resume(raw, D0 + day + 3600)
	_check("dag: choisir la valeur en cours efface l'attente ; clé égale à la cadence -> effacée au tick, sans effet",
		not eq["npcs"][0].has("cadence_next") and raw_r["village"] == ctrl["village"])
	var st: Dictionary = SaveS.new_state(18, D0, 0)
	st["seq"] = 1 # new_state part de 0 ; une sauvegarde écrite a seq >= 1
	st["village"]["npcs"][0]["cadence_next"] = "TURBO"
	st["village"]["npcs"][1]["cadence_next"] = "PAISIBLE"
	st["village"]["shops"]["MAT"]["posture_next"] = "PANIQUE"
	var un: Dictionary = SaveS.unpack(SaveS.pack(st))
	_check("unpack: cadence_next TURBO et posture_next PANIQUE effacées, PAISIBLE gardée", not un.is_empty()
		and not un["village"]["npcs"][0].has("cadence_next") and un["village"]["npcs"][1]["cadence_next"] == "PAISIBLE"
		and not un["village"]["shops"]["MAT"].has("posture_next"))
	# Scène réelle
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var cards: Array = uu.get_node(UiS.PAGES + "PNJ").get_children().filter(func(c: Node) -> bool: return c is VBoxContainer)
	var rows: int = 0
	for c: Node in cards: # jalon 19 : chaque fiche a sa rangée de cadence, visible pour un producteur du jour
		rows += int(c.find_child("Cadence", true, false).visible)
	var shops: Array = uu.get_node(UiS.PAGES + "Village").find_children("Posture", "HBoxContainer", true, false) # jalon 19 bis : dans les fiches
	var prow: int = shops.filter(func(r: HBoxContainer) -> bool: return r.get_child_count() == 3).size()
	_check("scenes: 5 cartes PNJ, 3 rangées de cadence, 3 blocs de boutique à 3 postures", cards.size() == 5 and rows == 3 and shops.size() == 3 and prow == 3,
		"%d %d %d %d" % [cards.size(), rows, shops.size(), prow])
	var emitted: Array = []
	uu.cadence_chosen.connect(func(i: int, c: String) -> void: emitted.append([i, c]))
	uu.posture_chosen.connect(func(k: String, p: String) -> void: emitted.append([k, p]))
	var row0: Node = cards[0].find_child("Cadence", true, false)
	row0.get_child(2).pressed.emit()
	shops[0].get_child(0).pressed.emit()
	_check("scenes: Forge ardente de la carte 0 -> cadence_chosen(0, FORGE_ARDENTE) ; Solidaire de Matériaux -> posture_chosen(MAT, SOLIDAIRE)",
		emitted == [[0, "FORGE_ARDENTE"], ["MAT", "SOLIDAIRE"]], str(emitted))
	vk["npcs"][0]["cadence_next"] = "PAISIBLE"
	uu.show_village(vk, 10, false, "Réglages au village seulement")
	var reason: Label = uu.get_node(UiS.PAGES + "PNJ/Raison")
	var grey: bool = true
	for b: Button in row0.get_children():
		grey = grey and b.disabled
	var lit: Array = row0.get_children().map(func(b: Button) -> bool: return b.button_pressed)
	var help0: String = cards[0].find_child("AideCadence", true, false).text
	_check("scenes: can_set faux -> boutons grisés, raison en tête des 2 pages ; bouton allumé = attente, aide « Demain : Paisible »",
		grey and reason.visible and reason.text == "Réglages au village seulement" and uu.get_node(UiS.PAGES + "Village/Raison").visible
		and lit == [true, false, false] and help0 == "Demain : Paisible (production ×0,80, Moral -6/jour)", "%s %s %s" % [grey, str(lit), help0])
	var lit_style: bool = row0.get_child(0).get_theme_stylebox("disabled") == row0.get_child(0).get_theme_stylebox("pressed") 		and row0.get_child(1).get_theme_stylebox("disabled") != row0.get_child(1).get_theme_stylebox("pressed")
	uu.show_village(vk, 10, true, "")
	_check("scenes: grisé, le bouton choisi garde le fond « pressed », les autres non (AC4)", lit_style)
	_check("scenes: can_set vrai -> boutons actifs, raison masquée", not row0.get_child(0).disabled and not reason.visible)
	uu.free()

# Jalon 19 : aptitudes, changement de poste, auto-assignation (n°38). Références : sortie de prep_jalon_19.py.
func _moves_str(moves: Array) -> String:
	return str(moves.map(func(m: Dictionary) -> String: return "(%d, %s, %s, %.2f)" % [m["pnj"], m["de"], m["vers"], m["gain"]]))

# Tick du jumeau (apply_tick) : seulement post_next / stars_next, stocks inchangés.
func _apply_posts(v: Dictionary) -> void:
	for n: Dictionary in v["npcs"]:
		if n.has("post_next"):
			n["post"] = n["post_next"]
			n["stars"] = n["stars_next"]
			n.erase("post_next")
			n.erase("stars_next")

func _jalon_19() -> void:
	var names: Dictionary = VText.load_names()
	names["npcs"] = [{"name": "Gaspard", "g": "M"}, {"name": "Margaux", "g": "F"}, {"name": "Ulric", "g": "M"}, {"name": "Thibaut", "g": "M"},
		{"name": "Odile", "g": "F"}]
	var s1: Array[int] = []
	var s2: Array[int] = []
	for p: int in BD.VERTICAL_SLICE_POST_SLOTS_BY_ATRE_LVL[1]:
		s1.append(BD.VERTICAL_SLICE_POST_SLOTS_BY_ATRE_LVL[1][p])
		s2.append(BD.VERTICAL_SLICE_POST_SLOTS_BY_ATRE_LVL[2][p])
	_check("n38: sommes des postes par type = ATRE_WORK_POSTS_CAP[0] et [1] (6 et 10)", _sum_ints(s1) == BD.ATRE_WORK_POSTS_CAP[0]
		and _sum_ints(s2) == BD.ATRE_WORK_POSTS_CAP[1], "%d %d" % [_sum_ints(s1), _sum_ints(s2)])
	# Aptitudes
	var want_apt: Dictionary = {
		1: [[2, 0, 1, 0, 1, 1], [0, 0, 2, 0, 0, 1], [0, 2, 0, 1, 1, 0], [0, 0, 0, 1, 0, 2], [1, 0, 0, 0, 0, 2]],
		2: [[2, 1, 1, 1, 0, 0], [1, 0, 2, 1, 0, 0], [0, 2, 0, 0, 1, 0], [0, 0, 1, 1, 1, 2], [0, 1, 0, 1, 1, 2]],
		3: [[2, 1, 1, 1, 0, 1], [1, 0, 2, 0, 0, 0], [0, 2, 1, 0, 0, 1], [0, 1, 1, 1, 0, 2], [1, 0, 1, 0, 0, 2]]}
	for sd: int in want_apt:
		var got: Array = []
		for i in 5:
			var a: Dictionary = AssignS.aptitudes(sd, i)
			got.append(AssignS.posts().map(func(p: String) -> int: return a[p]))
		print("      aptitudes graine %d : %s" % [sd, str(got)])
		_check("aptitudes: graine %d, 5 PNJ x 6 postes = jumeau" % sd, got == want_apt[sd], str(got))
	_check("aptitudes: ordre de BD.JobPostType", AssignS.posts() == ["EXTRACTION", "FORGE", "TAVERN", "GATHER", "MERCHANT", "GUARD"], str(AssignS.posts()))
	var sec: Array[int] = []
	for sd in 200:
		for i in 5:
			var a: Dictionary = AssignS.aptitudes(sd, i)
			for p: String in AssignS.posts():
				if p != AssignS.favorite(i):
					sec.append(a[p])
	var share: float = float(_sum_ints(sec)) / sec.size()
	_check("aptitudes: 200 graines, secondaires dans {0, 1}, part de 1 étoile 0,400 ± 0,03", sec.all(func(x: int) -> bool: return x == 0 or x == 1)
		and absf(share - 0.40) < 0.03, "%.3f" % share)
	var traits_ok: bool = true
	for sd in 20:
		var before: Array = NewGameS.village(sd, D0, 0)["npcs"].map(func(n: Dictionary) -> Array: return n["traits"])
		for i in 5:
			AssignS.aptitudes(sd, i)
		var after: Array = NewGameS.village(sd, D0, 0)["npcs"].map(func(n: Dictionary) -> Array: return n["traits"])
		traits_ok = traits_ok and before == after
	_check("aptitudes: RNG « npc/apt/i » à part, traits identiques avant / après (20 graines)", traits_ok)
	var tr1: Array = NewGameS.village(1, D0, 0)["npcs"].map(func(n: Dictionary) -> Array: return n["traits"])
	_check("traits: graine 1 = jumeau [[2], [4], [2], [1, 4], [0, 5]]", str(tr1) == "[[2], [4], [2], [1, 4], [0, 5]]", str(tr1))
	# Auto-assignation, jour 1, stocks à 0
	var want_auto: Dictionary = {1: "[\"(4, GUARD, EXTRACTION, 0.35)\"]", 2: "[]", 3: "[\"(4, GUARD, EXTRACTION, 0.51)\"]"}
	var want_slots: Dictionary = {1: "Extraction 2/2, Forge 1/1, Taverne 1/1, Garde 1/2", 2: "Extraction 1/2, Forge 1/1, Taverne 1/1, Garde 2/2",
		3: "Extraction 2/2, Forge 1/1, Taverne 1/1, Garde 1/2"}
	for sd: int in want_auto:
		var v: Dictionary = NewGameS.village(sd, D0, 0)
		var got: String = _moves_str(AssignS.auto_assign(v, sd, 100, 1))
		var line: String = VText.slots_line(v, 1, names)
		var again: Array = AssignS.auto_assign(v, sd, 100, 1)
		print("      auto graine %d : %s ; %s" % [sd, got, line])
		_check("auto: graine %d, jour 1 = jumeau, occupation, 2e passage le même jour sans effet" % sd, got == want_auto[sd] and line == want_slots[sd]
			and again.is_empty(), "%s %s %s" % [got, line, str(again)])
	var v1: Dictionary = NewGameS.village(1, D0, 0)
	AssignS.auto_assign(v1, 1, 100, 1)
	var n4: Dictionary = v1["npcs"][4]
	_check("auto: le déplacé reçoit post_next, stars_next (aptitude) et assign_day, sans verrou", n4["post_next"] == "EXTRACTION" and n4["stars_next"] == 1
		and n4["assign_day"] == 100 and not n4.get("locked", false) and n4["post"] == "GUARD", str(n4))
	var went: int = 0
	for sd in 200:
		if AssignS.auto_assign(NewGameS.village(sd, D0, 0), sd, 100, 1).any(func(m: Dictionary) -> bool: return m["de"] == "GUARD"):
			went += 1
	_check("auto: un garde part le jour 1 dans 126/200 villages (jumeau)", went == 126, str(went))
	_apply_posts(v1)
	var mat: Dictionary = v1["shops"]["MAT"]
	mat["stock"] = Eco.stock_max(true, mat["lvl"], mat["griffe_trait"])
	var full: Array = AssignS.auto_assign(v1, 1, 101, 1)
	print("      graine 1, Matériaux plein le lendemain : %s" % _moves_str(full))
	_check("auto: Matériaux plein -> [(4, EXTRACTION, GUARD, 1.17)], le gérant reste", _moves_str(full) == "[\"(4, EXTRACTION, GUARD, 1.17)\"]"
		and absf(full[0]["gain"] - 1.17) < 1e-4 and v1["npcs"][0]["post"] == "EXTRACTION" and not v1["npcs"][0].has("post_next"), _moves_str(full))
	var lk: Dictionary = NewGameS.village(1, D0, 0)
	lk["npcs"][4]["locked"] = true
	_check("auto: un PNJ verrouillé ne bouge pas", AssignS.auto_assign(lk, 1, 100, 1).is_empty())
	# Saisir-déposer, graine 1
	var v: Dictionary = NewGameS.village(1, D0, 0)
	var r1: Dictionary = AssignS.move(v, 1, 3, "EXTRACTION", 1)
	var r2: Dictionary = AssignS.move(v, 1, 4, "EXTRACTION", 1)
	var r3: Dictionary = AssignS.move(v, 1, 4, "EXTRACTION", 1)
	print("      move : %s %s %s ; %s" % [str(r1), str(r2), str(r3), VText.slots_line(v, 1, names)])
	_check("move: garde 3 -> Extraction « move », garde 4 -> Extraction « swap » avec 0, 2e fois « same »", r1 == {"kind": "move", "other": -1}
		and r2 == {"kind": "swap", "other": 0} and r3 == {"kind": "same", "other": -1}
		and VText.slots_line(v, 1, names) == "Extraction 2/2, Forge 1/1, Taverne 1/1, Garde 1/2", "%s %s %s" % [r1, r2, r3])
	var pl: Array = [VText.post_lines(v["npcs"][0], names), VText.post_lines(v["npcs"][3], names), VText.post_lines(v["npcs"][4], names)]
	print("      lignes de poste 0, 3, 4 : %s" % str(pl))
	_check("move: lignes de poste des PNJ 0, 3 et 4 = jumeau", pl == [PackedStringArray(["Demain : Garde, 1 étoile", "Poste : verrouillé"]),
		PackedStringArray(["Demain : Extraction, 0 étoile", "Poste : verrouillé"]), PackedStringArray(["Demain : Extraction, 1 étoile", "Poste : verrouillé"])], str(pl))
	_check("move: le gérant échangé garde sa gérance", v["npcs"][0]["manages"] == "MAT")
	var day: int = 86400
	var same_day: Dictionary = Dag.resume(v, D0 + 3600)
	var ticked: Dictionary = Dag.resume(v, D0 + day + 3600)
	var after: Array = ticked["village"]["npcs"].map(func(n: Dictionary) -> Array: return [n["post"], n["stars"], n.get("locked", false)])
	print("      après le tick : %s" % str(after))
	_check("move: après le tick = jumeau [(GUARD, 1, v), (TAVERN, 2), (FORGE, 2), (EXTRACTION, 0, v), (EXTRACTION, 1, v)]",
		after == [["GUARD", 1, true], ["TAVERN", 2, false], ["FORGE", 2, false], ["EXTRACTION", 0, true], ["EXTRACTION", 1, true]], str(after))
	_check("move: un poste qui revient au poste du jour efface l'attente", (func() -> bool:
		var w: Dictionary = NewGameS.village(1, D0, 0)
		AssignS.move(w, 1, 3, "EXTRACTION", 1)
		AssignS.move(w, 1, 3, "GUARD", 1)
		return not w["npcs"][3].has("post_next") and not w["npcs"][3].has("stars_next") and w["npcs"][3]["locked"]).call())
	# DAG
	_check("dag: sans tick, post_next / stars_next restent et rien ne bouge", not same_day["ticked"] and same_day["village"]["npcs"][3]["post"] == "GUARD"
		and same_day["village"]["npcs"][3]["post_next"] == "EXTRACTION" and same_day["village"]["npcs"][3]["stars_next"] == 0)
	var ctrl: Dictionary = Dag.resume(NewGameS.village(1, D0, 0), D0 + day + 3600)
	var manages_ok: bool = true
	for i in 5:
		manages_ok = manages_ok and ticked["village"]["npcs"][i]["manages"] == NewGameS.START_POSTS[i][1]
		manages_ok = manages_ok and not ticked["village"]["npcs"][i].has("post_next") and not ticked["village"]["npcs"][i].has("stars_next")
	_check("dag: au tick, journée produite avec les postes d'avant (dag = témoin), clés effacées, manages inchangé",
		ticked["dag"] == ctrl["dag"] and manages_ok)
	var cad: Dictionary = NewGameS.village(1, D0, 0)
	AssignS.move(cad, 1, 3, "EXTRACTION", 1)
	Dag.set_next(cad["npcs"][3], "cadence", "PAISIBLE")
	var cad_r: Dictionary = Dag.resume(cad, D0 + day + 3600)["village"]["npcs"][3]
	_check("dag: post_next et cadence_next appliqués au même tick", cad_r["post"] == "EXTRACTION" and cad_r["cadence"] == "PAISIBLE" and not cad_r.has("cadence_next"))
	var direct: Dictionary = ctrl["village"].duplicate(true)
	for i in 5:
		direct["npcs"][i]["post"] = after[i][0]
		direct["npcs"][i]["stars"] = after[i][1]
		if after[i][2]:
			direct["npcs"][i]["locked"] = true
	var nxt: Dictionary = Dag.resume(ticked["village"], D0 + day + 7200)
	_check("dag: reprise suivante = village réglé directement (le garde 3 produit en Extraction avec stars_next = 0, npc_rate)",
		nxt == Dag.resume(direct, D0 + day + 7200) and nxt["dag"]["MAT"]["added"] != Dag.resume(ctrl["village"], D0 + day + 7200)["dag"]["MAT"]["added"],
		"%d" % nxt["dag"]["MAT"]["added"])
	# Producteur passé garde (n°38 Q7b) : cadence NORMAL au tick, puis fatigue Normale
	var gv: Dictionary = NewGameS.village(1, D0, 0)
	gv["npcs"][0]["cadence"] = "FORGE_ARDENTE"
	gv["npcs"][1]["cadence"] = "FORGE_ARDENTE"
	gv["npcs"][1]["cadence_next"] = "PAISIBLE"
	AssignS.move(gv, 1, 0, "GUARD", 1)
	AssignS.move(gv, 1, 1, "GUARD", 1)
	var g1: Dictionary = Dag.resume(gv, D0 + day + 3600)["village"]
	var gn: Array = [g1["npcs"][0], g1["npcs"][1]]
	_check("garde: FORGE_ARDENTE (et FORGE_ARDENTE + cadence_next PAISIBLE) passés garde -> cadence NORMAL, cadence_next effacée au tick",
		gn.all(func(n: Dictionary) -> bool: return n["post"] == "GUARD" and n["cadence"] == "NORMAL" and not n.has("cadence_next")),
		str(gn.map(func(n: Dictionary) -> Array: return [n["post"], n["cadence"], n.has("cadence_next")])))
	var g2: Dictionary = Dag.resume(g1, D0 + 2 * day + 3600)
	var gt: Array[int] = []
	gt.assign(g1["npcs"][0]["traits"])
	var gm: Array = []
	for n: Dictionary in g1["npcs"]:
		if n["manages"] != "":
			gm.append(n["traits"])
	var meal: String = "EATEN" if 0 < g2["dag"]["meals"] else "OFFLINE"
	var tick_of: Callable = func(c: String) -> int:
		return Eco.npc_daily_tick(g1["npcs"][0]["moral"], g1["npcs"][0]["on_strike"], c, meal, g1["npcs"][0]["house_lvl"], gt, Eco.griffe_moral_bonus(gm))["moral"]
	print("      garde 0 au tick suivant : Moral %d (Normale %d, Forge ardente %d)" % [g2["village"]["npcs"][0]["moral"], tick_of.call("NORMAL"), tick_of.call("FORGE_ARDENTE")])
	_check("garde: le tick suivant applique la fatigue Normale", g2["village"]["npcs"][0]["moral"] == tick_of.call("NORMAL")
		and tick_of.call("NORMAL") != tick_of.call("FORGE_ARDENTE"))
	# unpack
	var st: Dictionary = SaveS.new_state(1, D0, 0)
	st["seq"] = 1
	st["village"]["npcs"][0]["post_next"] = "GATHER"
	st["village"]["npcs"][0]["stars_next"] = 1
	st["village"]["npcs"][1]["post_next"] = "FORGE"
	st["village"]["npcs"][2]["locked"] = "oui"
	st["village"]["npcs"][3]["post_next"] = "EXTRACTION"
	st["village"]["npcs"][3]["stars_next"] = 0
	st["village"]["npcs"][3]["locked"] = true
	st["village"]["npcs"][3]["assign_day"] = 100
	st["village"]["npcs"][4]["assign_day"] = "hier"
	var un: Dictionary = SaveS.unpack(SaveS.pack(st))
	var un_n: Array = [] if un.is_empty() else un["village"]["npcs"]
	_check("unpack: post_next GATHER, stars_next manquant, locked « oui », assign_day texte -> effacés ; clés valides gardées", not un.is_empty()
		and not un_n[0].has("post_next") and not un_n[0].has("stars_next") and not un_n[1].has("post_next") and not un_n[2].has("locked")
		and un_n[3]["post_next"] == "EXTRACTION" and un_n[3]["stars_next"] == 0 and un_n[3]["locked"] and un_n[3]["assign_day"] == 100
		and not un_n[4].has("assign_day"), str(un_n))
	# Sites
	var vd: Dictionary = VL.load_data()
	var probe: Array = [[Vector2i(-5, 0), "FORGE", "FORGE"], [Vector2i(5, 0), "MAT", "EXTRACTION"], [Vector2i(5, 8), "GISEMENT", "EXTRACTION"],
		[Vector2i(0, -4), "TAVERN", "TAVERN"], [Vector2i(0, 10), "GATE", "GUARD"], [Vector2i(-8, -4), "HOUSE0", ""], [Vector2i(0, 0), "ATRE", ""],
		[Vector2i(0, 3), "", ""], [Vector2i(12, 12), "", ""]]
	var bad: String = ""
	for c: Array in probe:
		var site: String = VL.site_at(c[0], vd["sites"], vd["patterns"])
		if site != c[1] or VL.SITE_POST.get(site, "") != c[2]:
			bad += "%s=%s " % [c[0], site]
	_check("site_at: 9 cellules du jumeau et leur poste", bad == "", bad)
	# Textes
	var apt: Array = []
	for i in 5:
		apt.append(VText.apt_lines(AssignS.aptitudes(1, i), AssignS.favorite(i), names))
	print("      aptitudes graine 1 : %s" % str(apt))
	_check("apt_lines: PNJ 0 et 2 de la graine 1 = jumeau", apt[0] == PackedStringArray(["Aptitudes : Extraction 2, Forge 0, Taverne 1, Garde 1",
		"Collecte 0, Négoce 1 (fermés) ; favori : Extraction"]) and apt[2] == PackedStringArray(["Aptitudes : Extraction 0, Forge 2, Taverne 0, Garde 0",
		"Collecte 1, Négoce 1 (fermés) ; favori : Forge"]), str(apt[0]) + str(apt[2]))
	var toasts: Array = [VText.move_toast(0, "FORGE", {"kind": "move", "other": -1}, names), VText.move_toast(0, "FORGE", {"kind": "swap", "other": 2}, names),
		VText.move_toast(0, "FORGE", {"kind": "same", "other": -1}, names)]
	_check("toasts: « Gaspard : Forge demain », « Gaspard et Ulric échangent demain », « Gaspard : poste verrouillé »",
		toasts == ["Gaspard : Forge demain", "Gaspard et Ulric échangent demain", "Gaspard : poste verrouillé"], str(toasts))
	var a1: Dictionary = NewGameS.village(1, D0, 0)
	AssignS.auto_assign(a1, 1, 100, 1)
	_check("post_lines: « Demain : Extraction, 1 étoile (auto) », « Poste : libre (auto) »", VText.post_lines(a1["npcs"][4], names)
		== PackedStringArray(["Demain : Extraction, 1 étoile (auto)", "Poste : libre (auto)"]), str(VText.post_lines(a1["npcs"][4], names)))
	var font: Font = load(FONT_PATH)
	var all: Array[String] = ["Astuce : fais glisser un PNJ sur un bâtiment", "Gaspard et Ulric échangent demain", "Poste : libre (auto)",
		"Demain : Extraction, 1 étoile (auto)", VText.slots_line(NewGameS.village(1, D0, 0), 1, names)]
	for ls: PackedStringArray in apt:
		all.append_array(ls)
	var widest: String = ""
	for t: String in all:
		if font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x > font.get_string_size(widest, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x:
			widest = t
	var ww: float = font.get_string_size(widest, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	print("      ligne la plus large : « %s » %d px" % [widest, ww])
	_check("largeurs: lignes du jalon 19 <= 296 px", ww <= 296.0, "%d" % ww)
	# Scène réelle
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	uu.set_world_seed(1)
	var cards: Array = uu.get_node(UiS.PAGES + "PNJ").get_children().filter(func(c: Node) -> bool: return c is VBoxContainer)
	var rows: Array = []
	for c: Node in cards:
		rows.append_array(c.find_children("Postes", "HBoxContainer", true, false))
	_check("scenes: 5 rangées de 4 boutons de poste (Extraction, Forge, Taverne, Garde), astuce en tête de la page PNJ", rows.size() == 5
		and rows.all(func(r: Node) -> bool: return r.get_child_count() == 4)
		and rows[0].get_children().map(func(b: Button) -> String: return b.text) == ["Extraction", "Forge", "Taverne", "Garde"]
		and uu.get_node(UiS.PAGES + "PNJ").get_children().any(func(n: Node) -> bool: return n is Label and n.text == "Astuce : fais glisser un PNJ sur un bâtiment"),
		"%d" % rows.size())
	var sv: Dictionary = NewGameS.village(1, D0, 0)
	AssignS.move(sv, 1, 3, "EXTRACTION", 1)
	uu.show_village(sv, 10, true, "")
	var frees: Array = cards.map(func(c: Node) -> Button: return c.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "Libérer")[0])
	var lit3: Array = rows[3].get_children().map(func(b: Button) -> bool: return b.button_pressed)
	_check("scenes: « Libérer » visible seulement pour le PNJ verrouillé ; poste effectif allumé (3 : Extraction)",
		frees.map(func(b: Button) -> bool: return b.visible) == [false, false, false, true, false] and lit3 == [true, false, false, false], str(lit3))
	var emitted: Array = []
	uu.post_chosen.connect(func(i: int, p: String) -> void: emitted.append([i, p]))
	uu.npc_freed.connect(func(i: int) -> void: emitted.append([i, "libre"]))
	rows[0].get_child(1).pressed.emit()
	frees[3].pressed.emit()
	_check("scenes: Forge de la carte 0 -> post_chosen(0, FORGE) ; Libérer de la carte 3 -> npc_freed(3)", emitted == [[0, "FORGE"], [3, "libre"]], str(emitted))
	var cad_rows: Array = cards.map(func(c: Node) -> bool: return c.find_child("Cadence", true, false).visible)
	_check("scenes: la rangée de cadence suit le poste du jour (gardes 3 et 4 : masquée)", cad_rows == [true, true, true, false, false], str(cad_rows))
	# Liste façon Kairosoft (Z8) : une ligne par PNJ, une fiche ouverte à la fois
	var heads: Array = cards.map(func(c: Node) -> Button: return c.find_child("Tete", false, false))
	var details: Array = cards.map(func(c: Node) -> Control: return c.find_child("Detail", false, false))
	var closed: bool = details.all(func(d: Control) -> bool: return not d.visible)
	heads[0].button_pressed = true
	var one: Array = details.map(func(d: Control) -> bool: return d.visible)
	heads[2].button_pressed = true
	var two: Array = details.map(func(d: Control) -> bool: return d.visible)
	heads[2].button_pressed = false
	_check("liste: fiches fermées au départ, une seule ouverte à la fois, 2e appui referme", closed and one == [true, false, false, false, false]
		and two == [false, false, true, false, false] and details.all(func(d: Control) -> bool: return not d.visible), "%s %s" % [one, two])
	var tiles: Dictionary = VL.load_data()["tiles"]
	var icons_ok: bool = true
	for i in 5:
		icons_ok = icons_ok and _icon_of(heads[i].icon) == ["res://assets/tiles/kenney_tiny_dungeon/tilemap_packed.png",
			UiStyle.tile_region(int(tiles[VL.load_data()["npc_sprites"][i]][1]))]
	_check("liste: sprite du PNJ en icône, « nom \\n poste » ; boutons de poste avec l'aptitude", icons_ok
		and heads[3].text.split("\n")[1] == "Garde, 2 étoiles" and rows[3].get_children().map(func(b: Button) -> String: return b.text)
		== ["Extraction 0", "Forge 0", "Taverne 0", "Garde 2"] and cards[3].find_child("Demain", true, false).text.begins_with("Demain : Extraction, 0 étoile"),
		heads[3].text + str(rows[3].get_children().map(func(b: Button) -> String: return b.text)))
	var row_w: float = 6.0
	for b: Button in rows[0].get_children():
		row_w += font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 4.0
	_check("largeurs: rangée « Extraction 2 … Garde 1 » <= 296 px (formule du jumeau)", row_w <= 296.0, "%d" % row_w)
	var stops: Array = uu.get_node("Margin/VBox/Monde/Fenetre/Box/Defile").find_children("*", "Control", true, false).filter(
		func(c: Control) -> bool: return c.mouse_filter == Control.MOUSE_FILTER_STOP)
	_check("défilement tactile: aucun Control en STOP dans la fenêtre défilante (le glissé atteint le ScrollContainer)", stops.is_empty(),
		str(stops.map(func(c: Control) -> String: return c.name)))
	uu.show_village(sv, 10, false, "Réglages au village seulement")
	var grey: bool = frees[3].disabled
	for r: Node in rows:
		for b: Button in r.get_children():
			grey = grey and b.disabled
	_check("scenes: hors du village, boutons de poste et Libérer grisés, raison affichée, bouton choisi visible", grey
		and uu.get_node(UiS.PAGES + "PNJ/Raison").visible and rows[3].get_child(0).button_pressed
		and rows[3].get_child(0).get_theme_stylebox("disabled") == rows[3].get_child(0).get_theme_stylebox("pressed"))
	var atre_txt: String = uu.find_child("Occupation", true, false).text # jalon 19 bis : fiche du Grand Âtre
	_check("scenes: onglet Village, occupation des postes (fiche du Grand Âtre)", atre_txt == "Extraction 2/2, Forge 1/1, Taverne 1/1, Garde 1/2", atre_txt)
	uu.free()

# Jalon 19 bis : Moral coloré, onglet Village en lignes dépliables. Références : prompt d'Antho (sortie de prep_jalon_19bis.py).
func _jalon_19b() -> void:
	var names: Dictionary = VText.load_names()
	names["npcs"] = [{"name": "Gaspard", "g": "M"}, {"name": "Margaux", "g": "F"}, {"name": "Ulric", "g": "M"}, {"name": "Thibaut", "g": "M"},
		{"name": "Odile", "g": "F"}]
	var bands: Array = [[19, false, "STRIKE"], [20, false, "LOW"], [49, false, "LOW"], [50, false, "NORMAL"], [84, false, "NORMAL"], [85, false, "HIGH"],
		[100, false, "HIGH"], [35, true, "STRIKE"], [0, true, "STRIKE"]]
	var got_b: Array = bands.map(func(b: Array) -> String: return VText.moral_band(b[0], b[1]))
	_check("moral_band: 9 bornes du jumeau", got_b == bands.map(func(b: Array) -> String: return b[2]), str(got_b))
	var tags: Array = [VText.moral_tag({"moral": 80, "on_strike": false}), VText.moral_tag({"moral": 15, "on_strike": true}),
		VText.moral_tag({"moral": 100, "on_strike": false})]
	_check("moral_tag: « Moral 80 », « En grève », « Moral 100 »", tags == ["Moral 80", "En grève", "Moral 100"], str(tags))
	var sh: Array = [VText.shop_head("MAT", {"stock": 0, "lvl": 1, "posture": "EQUILIBRE", "griffe_trait": 1}, names),
		VText.shop_head("TAVERN", {"stock": 12, "lvl": 1, "posture": "SOLIDAIRE", "posture_next": "EXPORTATION", "griffe_trait": 5}, names),
		VText.shop_head("FORGE", {"stock": 3, "lvl": 1, "posture": "EXPORTATION", "griffe_trait": 3}, names)]
	print("      shop_head : %s" % str(sh))
	_check("shop_head: 3 fixtures du jumeau", sh == [PackedStringArray(["Matériaux, niveau 1", "Stock 0/69, Équilibre"]),
		PackedStringArray(["Taverne, niveau 1", "Stock 12/30, Solidaire, demain Exportation"]), PackedStringArray(["Forge, niveau 1", "Stock 3/30, Exportation"])], str(sh))
	var ah: PackedStringArray = VText.atre_head(1, 5)
	_check("atre_head(1, 5) et atre_detail(1)", ah == PackedStringArray(["Grand Âtre, niveau 1", "PNJ 5/5, postes occupés 5/6"])
		and VText.atre_detail(1) == "Rayon 12 tuiles autour de l'Âtre", str(ah) + VText.atre_detail(1))
	# Largeurs des têtes : pire cas du jumeau, borne 264 px
	var font: Font = load(FONT_PATH)
	var fw: Callable = func(t: String) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var worst: float = fw.call("Stock 999/999, Solidaire, demain Exportation")
	var longest: String = ""
	for g: String in ["M", "F"]:
		for n: String in names["name_pool"][g]:
			if fw.call(n) > fw.call(longest):
				longest = n
	var name_tag: float = fw.call(longest) + fw.call("Moral 100")
	var heads: Array[String] = ["Grand Âtre, niveau 1", "PNJ 5/5, postes occupés 5/6", "Taverne, niveau 1", "Matériaux, niveau 1", "Rayon 12 tuiles autour de l'Âtre"]
	var widest: float = heads.map(func(t: String) -> float: return fw.call(t)).max()
	print("      têtes : pire stock %d px, « %s » + « Moral 100 » %d px, autres <= %d px" % [worst, longest, name_tag, widest])
	_check("largeurs: têtes Village et nom + Moral <= 264 px", worst <= 264.0 and name_tag <= 264.0 and widest <= 264.0, "%d %d %d" % [worst, name_tag, widest])
	# UI instanciée
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	uu.set_world_seed(1)
	var pnj: Node = uu.get_node(UiS.PAGES + "PNJ")
	var vil: Node = uu.get_node(UiS.PAGES + "Village")
	var vcards: Array = vil.get_children().filter(func(c: Node) -> bool: return c is VBoxContainer)
	var vheads: Array = vcards.map(func(c: Node) -> Button: return c.find_child("Tete", false, false))
	var vdet: Array = vcards.map(func(c: Node) -> Control: return c.find_child("Detail", false, false))
	var grp: ButtonGroup = vheads[0].button_group
	var closed: bool = vdet.all(func(d: Control) -> bool: return not d.visible)
	vheads[1].button_pressed = true
	vheads[2].button_pressed = true
	var open: Array = vdet.map(func(d: Control) -> bool: return d.visible)
	vheads[2].button_pressed = false
	var pnj_grp: ButtonGroup = pnj.get_children().filter(func(c: Node) -> bool: return c is VBoxContainer)[0].find_child("Tete", false, false).button_group
	_check("village: 4 cartes (Âtre, Matériaux, Taverne, Forge), ButtonGroup à part allow_unpress, fermées au départ, une ouverte à la fois",
		vcards.size() == 4 and vheads.all(func(h: Button) -> bool: return h.button_group == grp) and grp.allow_unpress and grp != pnj_grp
		and closed and open == [false, false, true, false], "%d %s" % [vcards.size(), str(open)])
	var td: String = "res://assets/tiles/kenney_tiny_dungeon/tilemap_packed.png"
	var tiles: Dictionary = VL.load_data()["tiles"]
	var icons: Array = vheads.map(func(h: Button) -> Array: return _icon_of(h.icon))
	_check("village: icônes feu (image 0 du bandeau, 16 px), roche, tonneau, enclume", UiStyle.ICONS["ATRE"][1] == Rect2(0, 0, 16, 16)
		and icons == [[UiStyle.ICONS["cendre"][0].resource_path, Rect2(0, 0, 16, 16)],
		[td, UiStyle.tile_region(int(tiles["roche"][1]))], [td, UiStyle.tile_region(int(tiles["tonneau"][1]))], [td, UiStyle.tile_region(int(tiles["enclume"][1]))]], str(icons))
	var morals: Array = pnj.find_children("Moral", "Label", true, false)
	_check("pnj: 5 étiquettes Moral, enfants de la tête, mouse_filter IGNORE", morals.size() == 5
		and morals.all(func(l: Label) -> bool: return l.mouse_filter == Control.MOUSE_FILTER_IGNORE and l.get_parent().name == "Tete"))
	var v: Dictionary = NewGameS.village(1, D0, 0)
	v["npcs"][1]["moral"] = 49
	v["npcs"][2]["moral"] = 15
	v["npcs"][2]["on_strike"] = true
	v["npcs"][3]["moral"] = 90
	v["shops"]["TAVERN"]["posture_next"] = "EXPORTATION"
	var n_pnj: int = pnj.find_children("*", "", true, false).size()
	var n_vil: int = vil.find_children("*", "", true, false).size()
	uu.show_village(v, 10, true, "")
	uu.show_village(v, 10, true, "")
	_check("show_village x2 : aucun nœud créé dans PNJ ni Village", pnj.find_children("*", "", true, false).size() == n_pnj
		and vil.find_children("*", "", true, false).size() == n_vil)
	var mt: Array = morals.map(func(l: Label) -> String: return l.text)
	var mc: Array = morals.map(func(l: Label) -> Color: return l.get_theme_color("font_color"))
	print("      étiquettes Moral : %s" % str(mt))
	_check("pnj: Moral 49 orange, grève vermillon « En grève », 90 vert, 80 blanc", mt[1] == "Moral 49" and mt[2] == "En grève" and mt[3] == "Moral 90"
		and mc[1] == UiStyle.MORAL_COLORS["LOW"] and mc[2] == UiStyle.MORAL_COLORS["STRIKE"] and mc[3] == UiStyle.MORAL_COLORS["HIGH"]
		and mc[0] == UiStyle.MORAL_COLORS[VText.moral_band(v["npcs"][0]["moral"], false)], str(mt))
	var tav: String = vheads[2].text
	var tav_help: String = vcards[2].find_child("Posture", true, false).get_parent().get_child(-1).text
	_check("village: têtes Âtre et Taverne (« demain Exportation » sur la tête et dans l'aide), occupation dans la fiche Âtre",
		vheads[0].text == "Grand Âtre, niveau 1\nPNJ 5/5, postes occupés 5/6" and tav.ends_with(", demain Exportation") and tav_help.begins_with("Demain : Exportation")
		and vcards[0].find_child("Occupation", true, false).text == "Extraction 1/2, Forge 1/1, Taverne 1/1, Garde 2/2", tav + " | " + tav_help)
	uu.free()

# Jalon 20 : charte d'interface (ui_style.gd), Perso et Sacoche en lignes. Références : sortie de prep_jalon_20.py.
func _jalon_20() -> void:
	var nb: String = " "
	var nums: Array = [EqText.num(0), EqText.num(999), EqText.num(1000), EqText.num(715400), EqText.num(42600)]
	_check("num: 0, 999, 1 000, 715 400, 42 600 (U+00A0)", nums == ["0", "999", "1" + nb + "000", "715" + nb + "400", "42" + nb + "600"], str(nums))
	var v0: Dictionary = {"COMBATTANT": 0, "MINEUR": 0, "FORGERON": 0}
	var v1: Dictionary = {"COMBATTANT": BA.get_cumulative_xp(6) + 1000, "MINEUR": BA.get_cumulative_xp(3) + 10, "FORGERON": BA.get_cumulative_xp(2)}
	var vh: Array = []
	for v: Dictionary in [v0, v1]:
		for voc: String in ProgressionS.VOCATIONS:
			vh.append([EqText.voc_head(voc, v), EqText.voc_tag(voc, v)])
	for h: Array in vh:
		print("      " + str(h))
	_check("voc_head + voc_tag: 6 fixtures du jumeau", vh == [
		[PackedStringArray(["Combattant, niveau 1", "0 / 200 XP"]), ""], [PackedStringArray(["Mineur, niveau 1", "0 / 200 XP"]), ""],
		[PackedStringArray(["Forgeron, niveau 1", "0 / 200 XP"]), ""],
		[PackedStringArray(["Combattant, niveau 6", "1" + nb + "000 / 1" + nb + "150 XP"]), ""],
		[PackedStringArray(["Mineur, niveau 3", "10 / 490 XP"]), "Rattrapage ×2"], [PackedStringArray(["Forgeron, niveau 2", "0 / 330 XP"]), "Rattrapage ×2"]], str(vh))
	var pf: Array = [[0, {"rarity": 0, "ilvl": 1}], [1, {"rarity": 1, "ilvl": 3, "superior": true}], [2, null], [3, {"rarity": 2, "ilvl": 12, "superior": true}]]
	var ph: Array = pf.map(func(f: Array) -> Array: return [EqText.piece_head(f[0], f[1]), EqText.piece_tag(f[0], f[1])])
	for h: Array in ph:
		print("      " + str(h))
	_check("piece_head + piece_tag: 4 fixtures du jumeau", ph == [[PackedStringArray(["Arme : Épée & Écu", "Commune, ilvl 1"]), ""],
		[PackedStringArray(["Casque", "Bon, ilvl 3"]), "Supérieur"], [PackedStringArray(["Plastron", "Vide"]), ""],
		[PackedStringArray(["Bottes", "Rares, ilvl 12"]), "Supérieures"]], str(ph))
	var ed: Array = [0, 1, 2, 3].map(func(s: int) -> String: return EqText.empty_detail(s))
	_check("empty_detail: Forge-la / -le / -le / -les à la Forge, ou purifie un Éclat", ed == ["Forge-la à la Forge, ou purifie un Éclat",
		"Forge-le à la Forge, ou purifie un Éclat", "Forge-le à la Forge, ou purifie un Éclat", "Forge-les à la Forge, ou purifie un Éclat"], str(ed))
	var w0: Dictionary = EquipmentS.new_equipment()[0]
	var want_d: PackedStringArray = []
	for l: String in EqText.piece_lines(0, w0).slice(1):
		want_d.append(l.substr(4))
	_check("piece_detail(0, arme de départ) = piece_lines(0).slice(1) sans retrait", EqText.piece_detail(0, w0) == want_d
		and not EqText.piece_detail(0, w0)[0].begins_with(" "), str(EqText.piece_detail(0, w0)))
	var bag: Array = [{"elite": false, "ilvl": 3}, {"elite": true, "ilvl": 6}, {"elite": false, "ilvl": 3}, {"elite": false, "ilvl": 4}, {"elite": true, "ilvl": 6}]
	var rows: Array = [EqText.cendre_row(120), EqText.shards_row(bag), EqText.shards_detail(bag), EqText.ore_row(12), EqText.shards_row([]),
		EqText.shards_detail([]), EqText.ore_row(1)]
	for r: PackedStringArray in rows:
		print("      " + str(r))
	_check("Sacoche: 7 fixtures du jumeau", rows == [PackedStringArray(["Cendre 120/150", "Lanterne niveau 1"]),
		PackedStringArray(["Éclats 5/6, dont 2 d'Élite", "Purification au village ou au Brasero"]),
		PackedStringArray(["2 Éclats d'Élite, ilvl 6 (en premier)", "1 Éclat, ilvl 4", "2 Éclats, ilvl 3"]),
		PackedStringArray(["Coffre : 12 minerais", "4 minerais par pièce à la Forge"]),
		PackedStringArray(["Éclats 0/6", "Purification au village ou au Brasero"]), PackedStringArray(["Sacoche vide"]),
		PackedStringArray(["Coffre : 1 minerai", "4 minerais par pièce à la Forge"])], str(rows))
	var pn: Dictionary = {"shard_bag": bag}
	_check("shards_detail: 1re ligne = groupe de l'Éclat que Purification.next_index purifie", bag[PurifS.next_index(pn)]["elite"]
		and bag[PurifS.next_index(pn)]["ilvl"] == 6 and EqText.shards_detail(bag)[0].begins_with("2 Éclats d'Élite, ilvl 6"))
	# UiStyle
	_check("UiStyle: rôles = anciennes constantes (SECTION, raison, attente, Supérieure, fond, marge, verdict, Moral)",
		UiStyle.TITLE == Color("#56B4E9") and UiStyle.MUTED == Color(1, 1, 1, 0.6) and UiStyle.NEXT == Color("#009E73")
		and UiStyle.SUPERIOR == Color("#E69F00") and UiStyle.DETAIL_BG == Color(1, 1, 1, 0.06) and UiStyle.DETAIL_MARGIN_PX == 4
		and UiStyle.VERDICT_COLORS == {1: Color("#009E73"), -1: Color("#D55E00"), 0: Color(1, 1, 1)}
		and UiStyle.MORAL_COLORS == {"STRIKE": Color("#D55E00"), "LOW": Color("#E69F00"), "NORMAL": Color(1, 1, 1), "HIGH": Color("#009E73")}
		and UiStyle.GOOD == Color("#009E73") and UiStyle.BAD == Color("#D55E00") and UiStyle.ALERT == Color("#E69F00") and UiStyle.TEXT == Color(1, 1, 1))
	_check("UiStyle: school_color(FOYER) == #E69F00 (lu dans BalanceC)", UiStyle.school_color(BC.SchoolId.FOYER) == Color("#E69F00"))
	var hard: String = ""
	for path: String in ["res://scripts/ui/ui_layer.gd", "res://scripts/ui/village_text.gd"]:
		var src: String = FileAccess.get_file_as_string(path)
		if src.contains("Color(\"") or src.contains("Color(1, 1, 1"):
			hard += path + " "
	_check("UiStyle: aucune couleur en dur dans ui_layer.gd ni village_text.gd", hard == "", hard)
	var tiles: Dictionary = VL.load_data()["tiles"]
	var td_ok: bool = (UiStyle.ICONS["MAT"][1] == UiStyle.tile_region(int(tiles["roche"][1])) and UiStyle.ICONS["TAVERN"][1] == UiStyle.tile_region(int(tiles["tonneau"][1]))
		and UiStyle.ICONS["FORGE"][1] == UiStyle.tile_region(int(tiles["enclume"][1])) and UiStyle.ICONS["COMBATTANT"][1] == UiStyle.tile_region(112)
		and UiStyle.ICONS["FORGERON"][1] == UiStyle.tile_region(74))
	var items: Array = ["MINEUR", "SLOT_0", "SLOT_1", "SLOT_2", "SLOT_3"].map(func(k: String) -> String: return UiStyle.ICONS[k][0].resource_path.get_file())
	_check("UiStyle: tuiles roche / tonneau / enclume = village.json, Combattant TD 112, Forgeron TD 74, 5 icônes DB32 16 × 16",
		td_ok and items == ["pickaxe_iron.png", "sword_iron.png", "armor_helmet_iron.png", "armor_chest_iron.png", "armor_boots_iron.png"]
		and ["MINEUR", "SLOT_0", "SLOT_1", "SLOT_2", "SLOT_3"].all(func(k: String) -> bool: return UiStyle.ICONS[k][0].get_size() == Vector2(16, 16)), str(items))
	# Largeurs (pires cas du jumeau)
	var font: Font = load(FONT_PATH)
	var fw: Callable = func(t: String) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var heads: Array = [["Combattant, niveau 50", "Rattrapage ×2"], ["Forgeron, niveau 50", "Rattrapage ×2"],
		["%s / %s XP" % [EqText.num(BA.XP_MASTERY_STEP - 1), EqText.num(BA.XP_MASTERY_STEP)], ""], ["Arme : Épée & Écu", "Supérieure"],
		["Communes, ilvl 12", ""], ["Éclats 15/15, dont 15 d'Élite", ""], ["Purification au village ou au Brasero", ""], ["Coffre : 9999 minerais", ""],
		["4 minerais par pièce à la Forge", ""]]
	var hw: float = heads.map(func(h: Array) -> float: return fw.call(h[0]) + (8.0 + fw.call(h[1]) if h[1] != "" else 0.0)).max()
	var dw: float = ["15 Éclats d'Élite, ilvl 12 (en premier)", EqText.empty_detail(3), "Enclume / Brasier / Enclume", "+12 % dégâts critiques",
		EqText.piece_detail(0, w0)[0]].map(func(t: String) -> float: return fw.call(t)).max()
	print("      largeurs : têtes + étiquette <= %d px, fiches <= %d px" % [hw, dw])
	_check("largeurs: têtes + étiquette <= 264 px, fiches <= 288 px", hw <= 264.0 and dw <= 288.0, "%d %d" % [hw, dw])
	# UI instanciée
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var perso: Node = uu.get_node(UiS.PAGES + "Perso")
	var sac: Node = uu.get_node(UiS.PAGES + "Sacoche")
	var lines: Array = perso.get_children().filter(func(c: Node) -> bool: return c is PanelContainer)
	var cards: Array = perso.get_children().filter(func(c: Node) -> bool: return c is VBoxContainer)
	var heads_b: Array = cards.map(func(c: Node) -> Button: return c.find_child("Tete", false, false))
	var dets: Array = cards.map(func(c: Node) -> Control: return c.find_child("Detail", false, false))
	var closed: bool = dets.all(func(d: Control) -> bool: return not d.visible)
	heads_b[0].button_pressed = true
	heads_b[2].button_pressed = true
	var open: Array = dets.map(func(d: Control) -> bool: return d.visible)
	heads_b[2].button_pressed = false
	var icons: Array = lines.map(func(l: Node) -> Array: return _icon_of(l.find_children("*", "TextureRect", true, false)[0].texture))
	_check("perso: 3 lignes de vocation (Combattant, Mineur, Forgeron), 4 cartes fermées, une ouverte à la fois, ButtonGroup propre",
		lines.size() == 3 and cards.size() == 4 and closed and open == [false, false, true, false] and heads_b[0].button_group.allow_unpress
		and icons == ["COMBATTANT", "MINEUR", "FORGERON"].map(func(k: String) -> Array: return [UiStyle.ICONS[k][0].resource_path, UiStyle.ICONS[k][1]]),
		"%d %d %s" % [lines.size(), cards.size(), str(open)])
	var tags: Array = perso.find_children("Tag", "Label", true, false) + sac.find_children("Tag", "Label", true, false)
	_check("perso + sacoche: 3 + 4 + 3 étiquettes, toutes en mouse_filter IGNORE", tags.size() == 10
		and tags.all(func(t: Label) -> bool: return t.mouse_filter == Control.MOUSE_FILTER_IGNORE), str(tags.size()))
	var p: Dictionary = ProgressionS.new_player()
	p["voc_xp"] = v1.duplicate()
	p["cendre"] = 120
	p["shard_bag"] = bag
	p["equipment"][0]["schools"] = [BC.SchoolId.FOYER, BC.SchoolId.FOYER, BC.SchoolId.FOYER]
	p["equipment"][1] = {"slot": 1, "rarity": 1, "ilvl": 3, "superior": true, "affixes": []}
	var st: Dictionary = EquipmentS.player_stats(ProgressionS.combat_level(p), p["equipment"])
	var n_p: int = perso.find_children("*", "", true, false).size()
	var n_s: int = sac.find_children("*", "", true, false).size()
	for k in 2:
		uu.show_perso(p, st)
		uu.show_player(p, 12)
	_check("show_perso + show_player x2 : aucun nœud créé dans Perso ni Sacoche", perso.find_children("*", "", true, false).size() == n_p
		and sac.find_children("*", "", true, false).size() == n_s)
	var vtags: Array = lines.map(func(l: Node) -> String: return l.find_child("Tag", true, false).text)
	var vtext: String = lines[0].find_children("*", "Label", true, false)[0].text
	var stag: Label = cards[1].find_child("Tag", true, false)
	var ecoles: Label = cards[0].find_child("Ecoles", true, false)
	print("      vocations %s / %s ; casque « %s » ; Écoles « %s »" % [vtext.replace("\n", " | "), str(vtags), stag.text, ecoles.text])
	_check("perso: rattrapage en GOOD, Supérieur en SUPERIOR, ligne d'Écoles Enclume 3/3 en school_color(FOYER), Plastron vide",
		vtags == ["", "Rattrapage ×2", "Rattrapage ×2"] and lines[1].find_child("Tag", true, false).get_theme_color("font_color") == UiStyle.GOOD
		and stag.text == "Supérieur" and stag.get_theme_color("font_color") == UiStyle.SUPERIOR
		and ecoles.text.begins_with("Enclume 3/3") and ecoles.get_theme_color("font_color") == UiStyle.school_color(BC.SchoolId.FOYER)
		and heads_b[2].text == "Plastron\nVide" and cards[2].find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == EqText.empty_detail(2)),
		vtext)
	p["equipment"][0]["schools"] = [BC.SchoolId.FOYER, BC.SchoolId.BRASIER, BC.SchoolId.FOYER]
	uu.show_perso(p, st)
	_check("perso: Écoles mêlées -> ligne en TEXT", ecoles.text.begins_with("Enclume / Brasier / Enclume") and ecoles.get_theme_color("font_color") == UiStyle.TEXT, ecoles.text)
	var order: Array = sac.get_children().map(func(c: Node) -> String: return c.get_class() if not c is Button else String(c.name))
	var shead: Button = sac.find_child("Tete", true, false)
	var scard: Array = sac.get_child(1).get_children().map(func(c: Node) -> String: return String(c.name))
	var srow: Array = sac.get_child(1).get_child(0).get_children().map(func(c: Node) -> String: return String(c.name))
	_check("sacoche: Cendre, Éclats (rangée [tête | Purifier], Raison, fiche ; Z11), coffre ; textes du jumeau", order == ["PanelContainer", "VBoxContainer", "PanelContainer"]
		and scard == ["Rangee", "Raison", "Detail"] and srow == ["Tete", "Purifier"]
		and shead.text == "Éclats 5/6, dont 2 d'Élite\nPurification au village ou au Brasero" and not sac.find_child("Detail", true, false).visible
		and sac.get_child(0).find_children("*", "Label", true, false)[0].text == "Cendre 120/150\nLanterne niveau 1"
		and sac.get_child(2).find_children("*", "Label", true, false)[0].text == "Coffre : 12 minerais\n4 minerais par pièce à la Forge", str(order))
	var stops: Array = uu.get_node("Margin/VBox/Monde/Fenetre/Box/Defile").find_children("*", "Control", true, false).filter(
		func(c: Control) -> bool: return c.mouse_filter == Control.MOUSE_FILTER_STOP)
	_check("défilement tactile: aucun Control en STOP dans Perso et Sacoche non plus", stops.is_empty(), str(stops.map(func(c: Control) -> String: return c.name)))
	uu.free()

# Jalon 20 bis : Forge, carte d'Aperçu en 2 colonnes, Purifier et Crédits à la charte. Références : sortie de prep_jalon_20bis.py.
func _jalon_20b() -> void:
	_check("forge_cendre_row(100)", EqText.forge_cendre_row(100) == PackedStringArray(["Cendre 100/150", "25 Cendre par pièce, mode Avec Cendre"]))
	var fb: Array = [EqText.forge_button(0, {"rarity": 0, "ilvl": 1}), EqText.forge_button(1, null), EqText.forge_button(2, {"rarity": 1, "ilvl": 3}),
		EqText.forge_button(3, {"rarity": 2, "ilvl": 12})]
	for x: PackedStringArray in fb:
		print("      " + str(x))
	_check("forge_button: 4 fixtures du jumeau", fb == [PackedStringArray(["Forger l'Arme", "Équipée : Commune, ilvl 1"]),
		PackedStringArray(["Forger le Casque", "Emplacement vide"]), PackedStringArray(["Forger le Plastron", "Équipé : Bon, ilvl 3"]),
		PackedStringArray(["Forger les Bottes", "Équipées : Rares, ilvl 12"])], str(fb))
	var ph: Array = [[EqText.preview_head(false, 0), EqText.piece_tag(0, {"superior": false})], [EqText.preview_head(true, 3), EqText.piece_tag(3, {"superior": true})]]
	_check("preview_head + piece_tag: (purifiée, Arme, \"\") et (forgée, Bottes, Supérieures)", ph == [[PackedStringArray(["Pièce purifiée", "Arme"]), ""],
		[PackedStringArray(["Pièce forgée", "Bottes"]), "Supérieures"]], str(ph))
	_check("column_head: « Bonne, ilvl 6 » et « Vide »", [EqText.column_head(0, {"rarity": 1, "ilvl": 6}), EqText.column_head(2, null)] == ["Bonne, ilvl 6", "Vide"])
	var F: int = BC.SchoolId.FOYER
	var sm: Array = [EqText.piece_summary(0, {"rarity": 1, "ilvl": 5, "schools": [F, F, F]}), EqText.piece_summary(2, {"rarity": 1, "ilvl": 8}),
		EqText.piece_summary(2, null)]
	_check("piece_summary (Z11): « Bonne, ilvl 5, Enclume 3/3 », « Bon, ilvl 8 », « Vide »", sm == ["Bonne, ilvl 5, Enclume 3/3", "Bon, ilvl 8", "Vide"], str(sm))
	var b0: Dictionary = {"hp": 154, "atk": 30, "def": 13, "period": 1.0 / 1.20, "crit_rate": 0.05, "crit_mult": 1.5}
	var a1: Dictionary = {"hp": 154, "atk": 33, "def": 12, "period": 1.0 / 1.25, "crit_rate": 0.08, "crit_mult": 1.5}
	var a2: Dictionary = {"hp": 190, "atk": 30, "def": 13, "period": 1.0 / 1.20, "crit_rate": 0.05, "crit_mult": 1.6}
	var d1: Array = EqText.diff_parts(b0, a1)
	var d2: Array = EqText.diff_parts(b0, a2)
	print("      " + str(d1))
	print("      " + str(d2))
	_check("diff_parts: arme (mixte)", d1 == [["PV +0", 0], ["ATK +3", 1], ["DEF -1", -1], ["Cadence +0,05/s", 1], ["Critique +3 %", 1], ["Dégâts crit. +0,0", 0]], str(d1))
	_check("diff_parts: armure (meilleure)", d2 == [["PV +36", 1], ["ATK +0", 0], ["DEF +0", 0], ["Cadence +0,00/s", 0], ["Critique +0 %", 0], ["Dégâts crit. +0,1", 1]], str(d2))
	_check("verdict inchangé: arme mixte -> 0, armure -> 1", EqText.compare(b0, a1) == 0 and EqText.compare(b0, a2) == 1)
	# Largeurs (pires cas du jumeau)
	var font: Font = load(FONT_PATH)
	var fw: Callable = func(t: String) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var heads: Array = []
	for x: PackedStringArray in fb + [EqText.forge_cendre_row(150), PackedStringArray(["Équipées : Communes, ilvl 12"])]:
		heads.append_array(Array(x))
	var hw: float = heads.map(func(t: String) -> float: return fw.call(t)).max()
	var cw: float = ["Communes, ilvl 12", "ATK d'arme 10,4", "+12 % dégâts critiques", "+12,5 DEF", "Enclume 3/3", "Nouvelle", "Équipée"].map(
		func(t: String) -> float: return fw.call(t)).max()
	var worst: Array = ["PV -999", "ATK -999", "DEF -999", "Cadence -0,99/s", "Critique -99 %", "Dégâts crit. -9,9"]
	var rw: Array = [0, 3].map(func(i: int) -> float: return fw.call(worst[i]) + fw.call(worst[i + 1]) + fw.call(worst[i + 2]) + 16.0)
	print("      largeurs : boutons et têtes %d px, colonnes %d px, rangées d'écarts %s px, Écoles mêlées %d px" % [hw, cw, str(rw.map(func(x: float) -> int: return roundi(x))),
		fw.call("Enclume / Brasier / Enclume")])
	_check("largeurs: boutons et têtes <= 264, colonnes <= 144, rangées d'écarts <= 296", hw <= 264.0 and cw <= 144.0 and rw.max() <= 296.0, "%d %d %s" % [hw, cw, str(rw)])
	var colw: Callable = func(ts: Array) -> float: return ts.map(func(t: String) -> float: return fw.call(t)).max()
	var tw: float = (colw.call(["Si tu équipes", "Dégâts crit.", "Cadence", "Critique"]) + colw.call(["Équipée", "Nouvelle", "9999", "9,99/s", "99 %", "×9,9"]) * 2.0
		+ colw.call(["Écart", "+0,99/s", "-999", "-99 %", "-9,9", "+9,9"]) + 3.0 * 8.0)
	var sw: float = fw.call("Nouvelle") + 8.0 + fw.call("Communes, ilvl 12")
	print("      tableau Si tu équipes %d px, résumé de pièce (hors arme) %d px" % [tw, sw])
	_check("largeurs (Z11): tableau Si tu équipes et résumé de pièce <= 296", tw <= 296.0 and sw <= 296.0, "%d %d" % [tw, sw])
	# UI instanciée
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var forge: Node = uu.get_node(UiS.PAGES + "Forge")
	var flines: Array = forge.get_children().filter(func(c: Node) -> bool: return c is PanelContainer)
	var modes: Array = forge.find_child("Mode", true, false).get_children()
	var fbtn: Array = uu.get_node(UiS.PAGES + "Forge/Boutons").get_children()
	var p: Dictionary = ProgressionS.new_player()
	p["cendre"] = 10
	p["shard_bag"] = [{"elite": false, "ilvl": 3}, {"elite": true, "ilvl": 6}, {"elite": false, "ilvl": 4}]
	uu.set_forge_help_source(func(c: bool) -> PackedStringArray: return EqText.forge_help(c, 1, 50))
	uu.show_forge(8, 10, p["equipment"])
	uu.set_forge_enabled(func(c: bool) -> String: return EqText.forge_block_reason(true, 8, 10, c, false))
	var help: Label = forge.find_child("Mode", true, false).get_parent().get_child(-1)
	var reason: Label = uu.get_node(UiS.PAGES + "Forge/Raison")
	var before: Array = [modes[1].button_pressed, help.text.get_slice("\n", 1), reason.text]
	modes[0].pressed.emit()
	modes[0].button_pressed = true
	var after: Array = [modes[1].button_pressed, help.text.get_slice("\n", 1), reason.text, reason.visible]
	print("      forge %s -> %s ; boutons %s" % [str(before), str(after), str(fbtn.map(func(b: Button) -> String: return b.text.replace("\n", " | ")))])
	_check("forge: 2 lignes, 2 boutons de mode (Avec enfoncé), 4 boutons Forger à icône sur 2 lignes dans Boutons", flines.size() == 2 and modes.size() == 2
		and before[0] and modes.map(func(b: Button) -> String: return b.text) == ["Sans Cendre", "Avec Cendre (25)"] and fbtn.size() == 4
		and fbtn.all(func(b: Button) -> bool: return b.icon != null and b.text.get_slice_count("\n") == 2 and not b.toggle_mode and b.alignment == HORIZONTAL_ALIGNMENT_LEFT)
		and fbtn[0].text == "Forger l'Arme\nÉquipée : Commune, ilvl 1", str(fbtn.map(func(b: Button) -> String: return b.text)))
	_check("forge: passer en Sans Cendre change l'aide (toujours Commun) et la raison (plus de manque de Cendre)", before[1].begins_with("Rareté : Commun ")
		and before[2] == "Il manque 15 Cendre" and after == [false, "Rareté : toujours Commun", "", false], str(before) + str(after))
	var box: Node = uu.get_node("Margin/VBox/Monde/Apercu/Box")
	var n_box: int = box.get_child_count()
	var w: Dictionary = EquipmentS.new_equipment()[0].duplicate(true)
	w["rarity"] = 1
	w["ilvl"] = 6
	uu.show_preview(w, EquipmentS.new_equipment()[0], b0, a1, false)
	var pcs: Array = box.get_node("Pieces").get_children().map(func(l: Label) -> String: return l.text)
	var cells: Array = box.get_node("Stats").get_children()
	var table: Array = []
	for r in 7:
		table.append(cells.slice(r * 4, r * 4 + 4).map(func(l: Label) -> String: return l.text))
	print("      aperçu %s" % str(pcs))
	for row: Array in table:
		print("      " + str(row))
	var mixed: Array = [cells[7].get_theme_color("font_color"), cells[11].get_theme_color("font_color"), cells[15].get_theme_color("font_color")]
	var armor: Dictionary = EquipmentS.craft(1, 8, 2, 1, true, 0)
	uu.show_preview(armor, null, b0, a2, true)
	var tag: Label = box.get_child(0).find_child("Tag", true, false)
	_check("aperçu (Z11): 2 appels sans nœud créé, tête / Verdict / Pieces / Stats / Choix, une ligne par pièce, tableau Si tu équipes",
		box.get_child_count() == n_box and box.get_children().map(func(c: Node) -> String: return c.get_class() if c.name.begins_with("@") else String(c.name))
		== ["PanelContainer", "Verdict", "Pieces", "Stats", "Choix"] and pcs == ["Nouvelle", "Bonne, ilvl 6, Enclume 3/3", "Équipée", "Commune, ilvl 1, Enclume 3/3"]
		and table == [["Si tu équipes", "Équipée", "Nouvelle", "Écart"], ["PV", "154", "154", "+0"], ["ATK", "30", "33", "+3"], ["DEF", "13", "12", "-1"],
		["Cadence", "1,20/s", "1,25/s", "+0,05/s"], ["Critique", "5 %", "8 %", "+3 %"], ["Dégâts crit.", "×1,5", "×1,5", "+0,0"]], str(pcs) + str(table))
	_check("aperçu: PV +0 en TEXT, ATK +3 en GOOD, DEF -1 en BAD ; armure Supérieure forgée : étiquette en SUPERIOR, verdict meilleure",
		mixed == [UiStyle.TEXT, UiStyle.GOOD, UiStyle.BAD] and tag.text == EqText.piece_tag(armor["slot"], armor) and tag.text != ""
		and tag.get_theme_color("font_color") == UiStyle.SUPERIOR and uu.get_node("Margin/VBox/Monde/Apercu/Box/Verdict").text == EqText.VERDICTS[1], str(mixed))
	uu.show_player(p, 8)
	var purify: Button = uu.get_node(UiS.PAGES + "Sacoche").find_child("Purifier", true, false)
	var credits: Button = uu.get_node(UiS.PAGES + "Options/CreditsButton")
	var shead: Button = purify.get_parent().get_child(0)
	purify.pressed.emit()
	var head_w: float = shead.get_minimum_size().x + 2.0 + purify.get_minimum_size().x
	print("      rangée Éclats : tête %d + Purifier %d = %d px" % [shead.get_minimum_size().x, purify.get_minimum_size().x, head_w])
	_check("Purifier (Z11) : à droite de la ligne Éclats, appui sans ouvrir la fiche, rangée <= 296 px", not shead.button_pressed and head_w <= 296.0, str(head_w))
	_check("Purifier (bouton simple sans icône) et Crédits (icône, 2 lignes)", purify.icon == null and credits.icon != null
		and purify.text == "Purifier" and credits.text == "Crédits\nLicences des assets"
		and _icon_of(credits.icon) == [UiStyle.TT.resource_path, UiStyle.ICONS["TAB_OPTIONS"][1]], purify.text)
	var tabs: Array = uu.get_node("Margin/VBox/Onglets").get_children()
	var rep: Control = uu.find_child("Report", true, false)
	var back: Array = []
	uu.hide_preview() # carte laissée ouverte par les tests d'aperçu : onglets grisés
	tabs[5].button_pressed = true
	uu.get_node("Credits").visible = true
	rep.visible = true
	for k in 4:
		back.append([uu.go_back(), uu.get_node("Credits").visible, rep.visible, tabs[5].button_pressed])
	tabs[2].button_pressed = true
	uu.show_preview(armor, null, b0, a2, true)
	back.append([uu.go_back(), uu.get_node("Margin/VBox/Monde/Apercu").visible])
	uu.hide_preview()
	tabs[2].button_pressed = false
	_check("Retour (Z11, choix B): Crédits, puis Rapport, puis onglet, puis rien ; la carte Équiper / Jeter ne se ferme pas",
		back == [[true, false, true, true], [true, false, false, true], [true, false, false, false], [false, false, false, false], [false, true]], str(back))
	var stops: Array = uu.get_node("Margin/VBox/Monde/Fenetre/Box/Defile").find_children("*", "Control", true, false).filter(
		func(c: Control) -> bool: return c.mouse_filter == Control.MOUSE_FILTER_STOP)
	_check("défilement tactile: aucun Control en STOP dans la Forge non plus", stops.is_empty(), str(stops.map(func(c: Control) -> String: return c.name)))
	uu.free()

# Mode debug (build debug seulement) : actions sur un state de test, jamais sur une vraie sauvegarde.
func _mode_debug() -> void:
	_clean_saves()
	var sm: Node = SaveS.new()
	sm.state = SaveS.save(SaveS.new_state(7, D0, 0), D0, TEST_SAVE_DIR)
	var now: int = D0 + 60
	var npc: Dictionary = sm.state["village"]["npcs"].filter(func(n: Dictionary) -> bool: return Dag.POST_SHOP.has(n["post"]))[0]
	var want: String = "PAISIBLE" if npc["cadence"] != "PAISIBLE" else "NORMAL"
	Dag.set_next(npc, "cadence", want)
	var idx: int = sm.state["village"]["npcs"].find(npc)
	var d: Dictionary = DebugS.tick_day(sm.state)
	var due: bool = SaveS.catch_up_due(sm.state["village"], now)
	var r: Dictionary = sm.sync(now, TEST_SAVE_DIR)
	var v: Dictionary = sm.state["village"]
	_check("debug tick du jour: catch_up_due vrai, après sync last_tick_day = aujourd'hui, cadence demandée la veille appliquée, log avant/après",
		due and not r.is_empty() and r["ticked"] and v["last_tick_day"] == ClockS.day_index(now, v["tz_offset_sec"])
		and v["npcs"][idx]["cadence"] == want and not v["npcs"][idx].has("cadence_next") and d["avant"] == d["apres"] + 1, str(d))
	DebugS.absence(sm.state)
	var hours: float = ClockS.offline_hours(sm.state["village"]["last_save_utc"], now + 60)
	var r2: Dictionary = sm.sync(now + 60, TEST_SAVE_DIR)
	_check("debug +12 h: offline_hours = OFFLINE_MAX_HOURS (plafond), Rapport de reprise à 12 h", hours == BB.OFFLINE_MAX_HOURS
		and not r2.is_empty() and r2["t_eff"] == BB.OFFLINE_MAX_HOURS, str(hours))
	var st: Dictionary = sm.state.duplicate(true)
	var gold: int = st["village"]["player_gold"]
	DebugS.cendre_max(st)
	var shards: Array = []
	for k in BA.LANTERN_SHARD_BAG_CAP[0] + 1:
		shards.append(not DebugS.add_shard(st, k % 2 == 1).is_empty())
	var ore: Dictionary = DebugS.add_ore(st)
	DebugS.add_gold(st)
	var lvl: int = BA.get_segment_mob_level(st["village"]["isolat"], ProgressionS.combat_level(st["player"]), 0)
	_check("debug ressources: Cendre 150, Éclats bornés à 6 (7e refusé, ilvl du segment), minerai +20, Or +100, state valide",
		st["player"]["cendre"] == BA.LANTERN_CENDRE_CAP[0] and st["player"]["shard_bag"].size() == 6 and shards == [true, true, true, true, true, true, false]
		and st["player"]["shard_bag"].all(func(x: Dictionary) -> bool: return x["ilvl"] == lvl) and st["player"]["shard_bag"][1]["elite"]
		and ore["apres"] == ore["avant"] + 20 and ForgeS.ore(st["player"]) == 20 and st["village"]["player_gold"] == gold + 100 and SaveS._is_valid(st), str(shards))
	var xp: Dictionary = st["player"]["voc_xp"]
	var l0: int = ProgressionS.level_of(xp["MINEUR"])
	var up: Dictionary = DebugS.level_up(st, "MINEUR")
	xp["FORGERON"] = BA.get_cumulative_xp(BA.MAX_VOCATION_LEVEL)
	var top: Dictionary = DebugS.level_up(st, "FORGERON")
	_check("debug +1 niveau: Mineur N -> N+1 ; Forgeron 50 inchangé ; state valide", ProgressionS.level_of(xp["MINEUR"]) == l0 + 1
		and up["apres"] == l0 + 1 and top.is_empty() and xp["FORGERON"] == BA.get_cumulative_xp(BA.MAX_VOCATION_LEVEL) and SaveS._is_valid(st), str(up))
	sm.free()
	_clean_saves()
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, {})
	pl.debug_invincible = true
	var hit_inv: bool = pl.take_hit(9)
	var hp_inv: int = pl.hp
	pl.debug_invincible = false
	var hit: bool = pl.take_hit(9)
	var fresh: Node2D = load("res://scenes/player/player.tscn").instantiate()
	_check("debug invincible: take_hit faux, PV inchangés ; coupé : take_hit vrai, PV -9 ; faux à la création", not hit_inv and hp_inv == 100
		and hit and pl.hp == 91 and not fresh.debug_invincible, "%d %d" % [hp_inv, pl.hp])
	fresh.free()
	pl.free()
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var opts: Node = uu.get_node(UiS.PAGES + "Options")
	var n: int = opts.find_children("*", "", true, false).size()
	uu.build_debug(false)
	uu.build_debug(true) # déjà créée en build debug : rien de plus
	var titles: Array = opts.get_children().filter(func(c: Node) -> bool: return c is Label and c.get_theme_color("font_color") == UiStyle.TITLE).map(
		func(l: Label) -> String: return l.text)
	_check("debug section: build_debug(false) ne crée rien ; en build debug, Debug sous Crédits avec 6 groupes", opts.find_children("*", "", true, false).size() == n
		and opts.get_child(0).name == "CreditsButton" and titles == ["Debug", "Temps", "Ressources", "Progression", "Remise à zéro", "Combat", "Sauvegarde"], str(titles))
	var btns: Array = opts.get_children().filter(func(c: Node) -> bool: return c is Button and c.name != "CreditsButton")
	uu.set_debug_state(false, false, false)
	var off: Array = btns.map(func(b: Button) -> bool: return b.disabled)
	var reasons: Array = opts.get_children().filter(func(c: Node) -> bool: return c is Label and c.visible and c.get_theme_color("font_color") == UiStyle.REASON).map(
		func(l: Label) -> String: return l.text)
	uu.set_debug_state(true, false, true)
	var full: Array = btns.map(func(b: Button) -> bool: return b.disabled)
	print("      debug %s ; Brume %s %s ; village Sacoche pleine %s" % [str(btns.map(func(b: Button) -> String: return b.text)), str(off), str(reasons), str(full)])
	_check("debug grisé: en Brume, Temps / Ressources / Progression grisés « Au village seulement » ; Saturation grisée hors Brume ; +1 Éclat grisés Sacoche pleine",
		btns.size() == 20 and off == [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, true, false]
		and reasons == ["Au village seulement", "Au village seulement", "Au village seulement", "Au village seulement", "En Brume seulement"]
		and full == [false, false, false, false, true, true, false, false, false, false, false, false, false, false, false, false, false, false, true, false], str(off) + str(full))
	uu.free()

func _row_texts(rows: Array) -> Array:
	return rows.map(func(r: Dictionary) -> String: return r["text"])

# Jalon 20 ter : Rapport de veillée en lignes fixes, toasts à icône, jauge pleine en BAD, Écoles de l'arme seules en couleur.
# Références : sortie de prep_jalon_20ter.py.
func _jalon_20t() -> void:
	var view: Callable = func(rs: Array) -> Array: return rs.map(func(r: Dictionary) -> Array: return [r["key"], r["text"], r["role"], r["tag"]])
	var r1: Dictionary = {"t_eff": 7.2, "gold_delta": 120, "ticked": true, "fixed_cost_paid": 3, "tools_replaced": 1, "strikes": 1, "fiches": [{}, {}]}
	var r2: Dictionary = {"t_eff": 12.0, "gold_delta": -8, "ticked": false, "fixed_cost_paid": 0, "tools_replaced": 0, "strikes": 0, "fiches": []}
	var r3: Dictionary = {"t_eff": 0.5, "gold_delta": 0, "ticked": false, "fixed_cost_paid": 0, "tools_replaced": 0, "strikes": 0, "fiches": []}
	var ng: Dictionary = {"new_game": true}
	var v1: Array = view.call(VeilleeReportS.rows(r1, false))
	print("      R1 déplié " + str(v1))
	print("      R1 plié " + str(view.call(VeilleeReportS.rows(r1, true))))
	print("      R2 déplié " + str(view.call(VeilleeReportS.rows(r2, false))))
	print("      R3 déplié " + str(view.call(VeilleeReportS.rows(r3, false))))
	print("      nouvelle partie " + str(view.call(VeilleeReportS.rows(ng, false))))
	_check("rows R1 déplié", v1 == [["absence", "Absence : 7 h 12", "TEXT", ""], ["or", "Or : +120", "GOOD", ""], ["frais", "Frais fixes du jour : 3 Or", "TEXT", ""],
		["outils", "Outils remplacés : 1", "TEXT", ""], ["greve", "PNJ en grève : 1", "BAD", ""], ["fiches", "Fiches de rupture : 2", "TEXT", ""]], str(v1))
	_check("rows R1 plié (absence et Or seulement)", view.call(VeilleeReportS.rows(r1, true)) == v1.slice(0, 2))
	_check("rows R2 : plafond, Or négatif", view.call(VeilleeReportS.rows(r2, false)) == [["absence", "Absence : 12 h 00", "TEXT", "plafond"], ["or", "Or : -8", "BAD", ""]])
	_check("rows R3 : Or nul en TEXT", view.call(VeilleeReportS.rows(r3, false)) == [["absence", "Absence : 0 h 30", "TEXT", ""], ["or", "Or : +0", "TEXT", ""]])
	_check("rows nouvelle partie", view.call(VeilleeReportS.rows(ng, false)) == [["new_game", "Nouvelle partie : Clair-Foyer", "TEXT", ""]]
		and view.call(VeilleeReportS.rows(ng, true)) == [["new_game", "Nouvelle partie : Clair-Foyer", "TEXT", ""]])
	var big: Array = [VeilleeReportS.rows({"t_eff": 1.0, "gold_delta": 1234, "ticked": false, "fixed_cost_paid": 0, "tools_replaced": 0, "strikes": 0, "fiches": []}, true)[1]["text"],
		VeilleeReportS.rows({"t_eff": 1.0, "gold_delta": -1234, "ticked": false, "fixed_cost_paid": 0, "tools_replaced": 0, "strikes": 0, "fiches": []}, true)[1]["text"]]
	_check("Or : +1 234 et -1 234 (U+00A0)", big == ["Or : +1\u00a0234", "Or : -1\u00a0234"], str(big))
	var w0: Dictionary = EquipmentS.new_equipment()[0]
	var first: String = EqText.piece_detail(0, w0)[0]
	_check("weapon_lines(arme de départ) == les 2 morceaux de la 1re ligne de piece_detail", EqText.weapon_lines(w0) == PackedStringArray(first.split(", ", true, 1)),
		str(EqText.weapon_lines(w0)))
	# Largeurs (pires cas du jumeau)
	var font: Font = load(FONT_PATH)
	var fw: Callable = func(t: String) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var fold: Array = [["Absence : 12 h 00", "plafond"], ["Or : -12\u00a0345", ""], ["Nouvelle partie : Clair-Foyer", ""], ["Combattant niveau 50 !", ""],
		["L'Élite s'éveille !", ""], ["Touche pour fermer", ""]]
	var fws: Array = fold.map(func(f: Array) -> int: return roundi(fw.call(f[0]) + (8.0 + fw.call(f[1]) if f[1] != "" else 0.0)))
	var dw: float = ["Frais fixes du jour : 1\u00a0234 Or", "Fiches de rupture : 99", "Outils remplacés : 99", "PNJ en grève : 30"].map(func(t: String) -> float: return fw.call(t)).max()
	print("      largeurs plié %s ; déplié %d px" % [str(fws), dw])
	_check("largeurs: plié <= 152 px, déplié <= 264 px", fws.max() <= 152 and dw <= 264.0, "%s %d" % [str(fws), dw])
	# UI instanciée, plié puis déplié
	for path: String in ["res://scenes/ui/ui_folded.tscn", "res://scenes/ui/ui_unfolded.tscn"]:
		var ui: CanvasLayer = _ui_ready(path)
		var lines: Node = ui.find_child("Report", true, false).get_node("Lines")
		var n: int = lines.get_child_count()
		var seen: Array = []
		for r: Dictionary in [r1, r2, ng]:
			ui.show_report(r)
			var vis: Array = lines.get_children().filter(func(c: Node) -> bool: return c is PanelContainer and c.visible).map(
				func(c: Node) -> String: return c.find_children("*", "Label", true, false)[0].text)
			seen.append(vis == _row_texts(VeilleeReportS.rows(r, ui.compact)))
		ui.show_report(r1)
		var gold_row: Node = lines.get_children().filter(func(c: Node) -> bool: return c is PanelContainer and c.visible)[1]
		var name: String = "plié" if ui.compact else "déplié"
		_check("rapport %s: 3 show_report sans nœud créé, lignes visibles = rows, Or +120 en GOOD, « Touche pour fermer » en MUTED" % name,
			lines.get_child_count() == n and seen == [true, true, true] and gold_row.find_children("*", "Label", true, false)[0].get_theme_color("font_color") == UiStyle.GOOD
			and lines.get_child(-1).text == "Touche pour fermer" and lines.get_child(-1).get_theme_color("font_color") == UiStyle.MUTED, str(seen))
		var toast: Control = ui.get_node("Margin/VBox/Monde/Messages/Toast")
		ui.show_level_up("MINEUR", 4)
		var t1: Array = [toast.visible, toast.get_node("Icone").visible, _icon_of(toast.get_node("Icone").texture), toast.get_node("Texte").text]
		ui.show_toast("Debug : +1 Éclat")
		var t2: Array = [toast.get_node("Icone").visible, toast.get_node("Texte").text]
		_check("toast %s: montée de niveau avec l'icône MINEUR ; debug sans icône" % name, t1 == [true, true, _icon_of(UiStyle.icon("MINEUR")), "Mineur niveau 4 !"]
			and t2 == [false, "Debug : +1 Éclat"], str(t1) + str(t2))
		var gauge: ProgressBar = ui.get_node("Margin/VBox/Jauge")
		ui.show_expedition(true, BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET - 1, 0, 0.0, 30.0)
		var c79: Color = (gauge.get_theme_stylebox("fill") as StyleBoxFlat).bg_color
		ui.show_expedition(true, BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET, 0, 0.0, 30.0)
		var c80: Color = (gauge.get_theme_stylebox("fill") as StyleBoxFlat).bg_color
		ui.show_expedition(false, 0, 0, 0.0, 0.0)
		_check("jauge %s: 79/80 en TEXT, 80/80 en BAD" % name, c79 == UiStyle.TEXT and c80 == UiStyle.BAD, "%s %s" % [c79, c80])
		ui.show_elite_awake()
		_check("toast %s: « L'Élite s'éveille ! » avec l'icône ELITE (TD 110 = tuile elite de village.json)" % name, toast.get_node("Texte").text == "L'Élite s'éveille !"
			and toast.get_node("Icone").visible and UiStyle.ICONS["ELITE"][1] == UiStyle.tile_region(int(VL.load_data()["tiles"]["elite"][1])))
		if not ui.compact:
			var p: Dictionary = ProgressionS.new_player()
			p["equipment"][0]["schools"] = [BC.SchoolId.FOYER, BC.SchoolId.FOYER, BC.SchoolId.FOYER]
			ui.show_perso(p, EquipmentS.player_stats(1, p["equipment"]))
			var card: Node = ui.get_node(UiS.PAGES + "Perso").get_children().filter(func(c: Node) -> bool: return c is VBoxContainer)[0]
			var ecoles: Label = card.find_child("Ecoles", true, false)
			var atk: Label = ecoles.get_parent().get_child(ecoles.get_index() + 2) # après Bonus (jalon 20 quater)
			_check("perso: Enclume 3/3 en school_color(FOYER), ligne d'ATK d'arme en TEXT", ecoles.text == "Enclume 3/3"
				and ecoles.get_theme_color("font_color") == UiStyle.school_color(BC.SchoolId.FOYER) and atk.text.begins_with("ATK d'arme ")
				and atk.get_theme_color("font_color") == UiStyle.TEXT, ecoles.text + " | " + atk.text)
		ui.free()

# Jalon 20 quater : École de l'Arme expliquée dans la Forge et dans Perso. Références : sortie de prep_jalon_20quater.py.
func _jalon_20q() -> void:
	var help: PackedStringArray = EqText.school_help()
	for l: String in help:
		print("      " + l)
	_check("school_help : 5 lignes de référence", help == PackedStringArray(["École de la Lame : Enclume 70 %, Brasier 30 %",
		"Garde et Pommeau : École de la Lame à 70 %", "Bonus 3/3 : +3,5 % d'ATK d'arme (49 % des armes)",
		"Affixes : Brasier vise l'ATK, Enclume les PV et la DEF", "Casque, Plastron, Bottes : sans École"]), str(help))
	var F: int = BC.SchoolId.FOYER
	var Br: int = BC.SchoolId.BRASIER
	var w0: Dictionary = EquipmentS.new_equipment()[0]
	var wb: Dictionary = w0.duplicate(true)
	wb["schools"] = [Br, Br, Br]
	var wm: Dictionary = w0.duplicate(true)
	wm["schools"] = [F, Br, F]
	var bl: Array = [EqText.school_bonus_line(w0), EqText.school_bonus_line(wb), EqText.school_bonus_line(wm)]
	for x: Array in bl:
		print("      " + str(x))
	_check("school_bonus_line : arme de départ Enclume 3/3 et Brasier 3/3 en TEXT, Écoles mêlées en MUTED", w0["schools"] == [F, F, F]
		and bl[0] == ["Bonus 3/3 : +3,5 % d'ATK d'arme", "TEXT"] and bl[1] == bl[0]
		and bl[2] == ["Pas de bonus 3/3 : +3,5 % d'ATK d'arme si Lame, Garde et Pommeau ont la même École", "MUTED"], str(bl))
	# La ligne Affixes reste vraie tant que les poids d'Argon ne changent pas
	var share: Callable = func(sid: int, keys: Array, pool: Array) -> float:
		var wt: Dictionary = BC.SCHOOL_COMBAT_AFFIX_WEIGHTS[sid]
		var num: float = 0.0
		var den: float = 0.0
		for k: String in pool:
			den += wt[k]
			if k in keys:
				num += wt[k]
		return num / den
	var shares: Array = []
	for pool: Array in [BC.SCHOOL_COMBAT_AFFIX_WEIGHTS[F].keys(), Array(BF.COMMON_ALLOWED_AFFIXES)]:
		shares.append([share.call(Br, ["FLAT_ATK", "PCT_ATK"], pool), share.call(F, ["FLAT_ATK", "PCT_ATK"], pool),
			share.call(F, ["FLAT_HP", "FLAT_DEF"], pool), share.call(Br, ["FLAT_HP", "FLAT_DEF"], pool)])
	print("      affixes (ATK Brasier, ATK Enclume, PV+DEF Enclume, PV+DEF Brasier) : " + str(shares.map(func(x: Array) -> Array: return x.map(func(v: float) -> int: return roundi(v * 100.0)))))
	_check("ligne Affixes vraie : ATK Brasier > Enclume et PV+DEF Enclume > Brasier, tirage complet et Commun (si ce test tombe, revoir la ligne)",
		shares.all(func(x: Array) -> bool: return x[0] > x[1] and x[2] > x[3]), str(shares))
	var font: Font = load(FONT_PATH)
	var fw: Callable = func(t: String) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var forge_w: float = (Array(help) + ["École de l'Arme"]).map(func(t: String) -> float: return fw.call(t)).max()
	var b3: float = fw.call(bl[0][0])
	var mixed: float = fw.call(bl[2][0])
	print("      largeurs : Forge %d px, Bonus 3/3 %d px, ligne mêlée %d px (sur 2 lignes)" % [forge_w, b3, mixed])
	_check("largeurs : Forge <= 288, Bonus 3/3 <= 288, ligne mêlée <= 2 x 288", forge_w <= 288.0 and b3 <= 288.0 and mixed <= 576.0, "%d %d %d" % [forge_w, b3, mixed])
	# UI instanciée
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var forge: Node = uu.get_node(UiS.PAGES + "Forge")
	var title: Label = forge.get_child(-2)
	var text: Label = forge.get_child(-1)
	var n: int = forge.get_child_count()
	var p: Dictionary = ProgressionS.new_player()
	uu.set_forge_help_source(func(c: bool) -> PackedStringArray: return EqText.forge_help(c, 1, 50))
	uu.show_forge(8, 100, p["equipment"])
	var modes: Array = forge.find_child("Mode", true, false).get_children()
	for k in [0, 1]:
		modes[k].button_pressed = true
		modes[k].pressed.emit()
	_check("Forge : « École de l'Arme » et son texte en derniers, en MUTED ; show_forge et 2 bascules sans nœud créé ni texte changé",
		title.text == "École de l'Arme" and title.get_theme_color("font_color") == UiStyle.TITLE and text.text == "\n".join(help)
		and text.get_theme_color("font_color") == UiStyle.MUTED and forge.get_child_count() == n and forge.get_child(-1) == text
		and forge.get_child(-3).name == "Raison", "%d %d" % [n, forge.get_child_count()])
	var card: Node = uu.get_node(UiS.PAGES + "Perso").get_children().filter(func(c: Node) -> bool: return c is VBoxContainer)[0]
	var box: Node = card.find_child("Ecoles", true, false).get_parent()
	var nb: int = box.get_child_count()
	var st: Dictionary = EquipmentS.player_stats(1, p["equipment"])
	uu.show_perso(p, st)
	var bonus: Label = box.get_node("Bonus")
	var s1: Array = [bonus.visible, bonus.text, bonus.get_theme_color("font_color"), bonus.get_index() == box.get_node("Ecoles").get_index() + 1]
	p["equipment"][0]["schools"] = [F, Br, F]
	uu.show_perso(p, st)
	uu.show_perso(p, st)
	var s2: Array = [bonus.text, bonus.get_theme_color("font_color"), box.get_node("Ecoles").get_theme_color("font_color")]
	var others: int = uu.get_node(UiS.PAGES + "Perso").find_children("Bonus", "Label", true, false).size()
	_check("Perso : Bonus sous les Écoles, arme seulement ; 3/3 en TEXT, mêlée en MUTED (Écoles en TEXT) ; 3 show_perso sans nœud créé",
		s1 == [true, "Bonus 3/3 : +3,5 % d'ATK d'arme", UiStyle.TEXT, true] and s2 == [bl[2][0], UiStyle.MUTED, UiStyle.TEXT]
		and box.get_child_count() == nb and others == 1, str(s1) + str(s2))
	uu.free()

# Jalon 21 : Grand Âtre niveau 2 par chantier, surbrillance du bâtiment visé. Références : sortie de prep_jalon_21.py.
func _jalon_21() -> void:
	var names: Dictionary = VText.load_names()
	var c1: Dictionary = AtreS.cost(1)
	print("      coût Nv1 -> Nv2 : " + str(c1))
	_check("Âtre: coût Nv1 -> Nv2 = 600 Or, 40 minerais, 40 Matériaux, 240 min", c1 == {"gold": 600, "ore": 40, "mat": 40, "minutes": 240}, str(c1))
	var t0: int = 1793268300 # 2026-10-29 10:05 UTC (11 h 05 à Paris)
	var t1: int = 1793311800 # 2026-10-29 22:10 UTC (23 h 10 à Paris)
	var vf: Callable = func(gold: int, mat: int, extra: Dictionary = {}) -> Dictionary:
		var v: Dictionary = {"player_gold": gold, "tz_offset_sec": 3600, "shops": {"MAT": {"stock": mat, "lvl": 1, "griffe_trait": -1}}}
		v.merge(extra)
		return v
	var cases: Array = [[vf.call(700, 50), 45, false, t0, "Chantier au village seulement"], [vf.call(0, 0), 0, true, t0, "Il manque 600 Or"],
		[vf.call(480, 0), 0, true, t0, "Il manque 120 Or"], [vf.call(600, 0), 39, true, t0, "Il manque 1 minerai"],
		[vf.call(600, 0), 28, true, t0, "Il manque 12 minerais"], [vf.call(650, 35), 40, true, t0, "Il manque 5 Matériaux en stock"],
		[vf.call(600, 40), 40, true, t0, ""], [vf.call(0, 0, {"atre_chantier_end": t0 + 14400}), 0, true, t0, "Chantier en cours, fini à 15 h 05"],
		[vf.call(0, 0, {"atre_chantier_end": t1 + 14400}), 0, true, t1, "Chantier en cours, fini demain à 3 h 10"],
		[vf.call(9999, 69, {"atre_lvl": 2}), 99, true, t0, "Niveau maximal"]]
	var got: Array = cases.map(func(c: Array) -> String: return AtreS.block_reason(c[0], c[1], c[2], c[3]))
	for g: String in got:
		print("      raison « %s »" % g)
	_check("Âtre: 10 raisons du jumeau (lieu, chantier, niveau maximal, Or, minerais, Matériaux)", got == cases.map(func(c: Array) -> String: return c[4]), str(got))
	var v: Dictionary = vf.call(700, 50)
	var pl: Dictionary = ProgressionS.new_player()
	pl["chest"][ForgeS.ORE] = 45
	var log: Dictionary = AtreS.start(v, pl, t0)
	print("      après start : Or %d, minerais %d, Matériaux %d ; %s" % [v["player_gold"], ForgeS.ore(pl), v["shops"]["MAT"]["stock"], str(log)])
	_check("Âtre: start : Or 700 -> 100, minerais 45 -> 5, Matériaux 50 -> 10, fin = T0 + 14 400 s, raison « Chantier en cours »",
		[v["player_gold"], ForgeS.ore(pl), v["shops"]["MAT"]["stock"], v["atre_chantier_end"]] == [100, 5, 10, t0 + 14400]
		and log == {"event": "chantier", "niveau": 2, "fin": t0 + 14400} and AtreS.block_reason(v, 5, true, t0) == "Chantier en cours, fini à 15 h 05", str(log))
	var fin: Array = [AtreS.finish_if_due(v, t0 + 14399), AtreS.level(v), AtreS.finish_if_due(v, t0 - 86400), AtreS.level(v)]
	fin.append_array([AtreS.finish_if_due(v, t0 + 14400), AtreS.level(v), v.has("atre_chantier_end"), AtreS.finish_if_due(v, t0 + 99999), AtreS.level(v)])
	_check("Âtre: finish_if_due : 1 s avant rien, horloge reculée rien, à la fin pile Nv2 et clé effacée, 2e appel sans effet",
		fin == [false, 1, false, 1, true, 2, false, false, 2], str(fin))
	var sc: Array = [[{"atre_lvl": 2}, {"atre_lvl": 2}], [{"atre_lvl": 3}, {}], [{"atre_lvl": 0}, {}], [{"atre_lvl": "2"}, {}],
		[{"atre_chantier_end": t0}, {"atre_chantier_end": t0}], [{"atre_chantier_end": -5}, {}], [{"atre_chantier_end": 1.5}, {}],
		[{"atre_lvl": 2, "atre_chantier_end": t0}, {"atre_lvl": 2}], [{}, {}]]
	var san: Array = sc.map(func(c: Array) -> Dictionary:
		var d: Dictionary = c[0].duplicate()
		AtreS.sanitize(d)
		return d)
	_check("Âtre: sanitize, 9 cas", san == sc.map(func(c: Array) -> Dictionary: return c[1]), str(san))
	# Sauvegarde : clés optionnelles relues à l'identique, atre_lvl 3 effacé
	var st: Dictionary = SaveS.new_state(7, D0, 0)
	st["village"]["atre_lvl"] = 2
	var st2: Dictionary = SaveS.new_state(7, D0, 0)
	st2["village"]["atre_chantier_end"] = D0 + 14400
	var st3: Dictionary = SaveS.new_state(7, D0, 0)
	st3["village"]["atre_lvl"] = 3
	for x: Dictionary in [st, st2, st3]:
		x["seq"] = 1 # posé par save() en jeu
	var back: Array = [SaveS.unpack(SaveS.pack(st))["village"].get("atre_lvl"), SaveS.unpack(SaveS.pack(st2))["village"].get("atre_chantier_end"),
		SaveS.unpack(SaveS.pack(st3))["village"].has("atre_lvl")]
	_check("save: atre_lvl 2 et chantier relus à l'identique, atre_lvl 3 effacé au chargement", back == [2, D0 + 14400, false], str(back))
	# Textes
	var tx: Array = [VText.atre_head(1, 5), VText.atre_head(2, 5), VText.atre_detail(2), VText.upgrade_effect(1), VText.upgrade_button(1, names), VText.atre_toast(2)]
	for t: Variant in tx:
		print("      " + str(t))
	_check("textes: atre_head Nv1 inchangé, Nv2 PNJ 5/5 postes 5/10, atre_detail(2), upgrade_effect(1), upgrade_button(1), toast", tx == [
		PackedStringArray(["Grand Âtre, niveau 1", "PNJ 5/5, postes occupés 5/6"]), PackedStringArray(["Grand Âtre, niveau 2", "PNJ 5/5, postes occupés 5/10"]),
		"Rayon 18 tuiles autour de l'Âtre", "Niveau 2 : rayon 18 tuiles, 10 postes",
		PackedStringArray(["Agrandir le Grand Âtre", "600 Or, 40 minerais, 40 Matériaux, 4 h"]), "Grand Âtre niveau 2 !"], str(tx))
	# Décor au rayon 18 (bâti + chemins + props, comme village.gd)
	var vd: Dictionary = VL.load_data()
	var blocked: Dictionary = VL.built_cells(vd["sites"], vd["patterns"])
	blocked.merge(VL.paths(vd["sites"], vd["patterns"])["cells"])
	for prop: Dictionary in vd["props"]:
		blocked[VL.v2i(prop["cell"])] = true
	var count: Callable = func(d: Dictionary) -> Array:
		var n: Array = [0, 0]
		for c: Vector2i in d:
			n[0 if d[c][0] == "tree" else 1] += 1
		return n
	var deco_out: Array = []
	var cells: Array = []
	for sd: int in [1, 42]:
		VL.atre_level = 1
		var d1: Dictionary = VL.deco(sd, blocked)
		cells.append(CombatS.village_cells().size())
		VL.atre_level = 2
		var d2: Dictionary = VL.deco(sd, blocked)
		cells.append(CombatS.village_cells().size())
		var gone: Array = d1.keys().filter(func(c: Vector2i) -> bool: return d1[c][0] == "tree" and not (d2.has(c) and d2[c][0] == "tree"))
		var tufts: Array = d2.keys().filter(func(c: Vector2i) -> bool: return d2[c][0] == "tuft" and not (d1.has(c) and d1[c][0] == "tuft"))
		var by_yx: Callable = func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x)
		gone.sort_custom(by_yx)
		tufts.sort_custom(by_yx)
		var ring: bool = d2.keys().all(func(c: Vector2i) -> bool: return d1.get(c) == d2[c] or (c.x * c.x + c.y * c.y > 144 and c.x * c.x + c.y * c.y <= 324)) \
			and d1.keys().all(func(c: Vector2i) -> bool: return d2.get(c) == d1[c] or (c.x * c.x + c.y * c.y > 144 and c.x * c.x + c.y * c.y <= 324))
		var no_new_tree: bool = d2.keys().all(func(c: Vector2i) -> bool: return d2[c][0] != "tree" or (d1.has(c) and c.x * c.x + c.y * c.y > 324))
		deco_out.append([sd, count.call(d1), count.call(d2), gone.size(), tufts.size(), gone[0], tufts[0], ring, no_new_tree])
		print("      graine %d : Nv1 %s -> Nv2 %s ; %d arbres retirés, %d touffes ajoutées ; 1er arbre retiré %s, 1re touffe ajoutée %s" % deco_out[-1].slice(0, 7))
	VL.atre_level = 1
	_check("décor: graine 1 Nv1 326/13 -> Nv2 204/47, 122 retirés, 34 touffes, (-8, -16) et (-6, -16) ; graine 42 312/17 -> 202/50, 110 et 33 ; anneau 12 < d <= 18 seulement, aucun arbre nouveau",
		deco_out == [[1, [326, 13], [204, 47], 122, 34, Vector2i(-8, -16), Vector2i(-6, -16), true, true],
		[42, [312, 17], [202, 50], 110, 33, Vector2i(0, -17), Vector2i(0, -17), true, true]], str(deco_out))
	_check("Combat.village_cells : 441 au Nv1, 1 009 au Nv2 ; VL.atre_level remis à 1", cells == [441, 1009, 441, 1009] and VL.atre_radius() == 12, str(cells))
	# Auto-assignation au Nv2, jour 1
	var want: Dictionary = {1: ["[\"(4, GUARD, EXTRACTION, 0.35)\"]", "Extraction 2/3, Forge 1/2, Taverne 1/2, Garde 1/3"],
		2: ["[\"(4, GUARD, FORGE, 0.61)\", \"(3, GUARD, TAVERN, 0.45)\"]", "Extraction 1/3, Forge 2/2, Taverne 2/2, Garde 0/3"],
		3: ["[\"(4, GUARD, EXTRACTION, 0.51)\", \"(3, GUARD, FORGE, 0.45)\"]", "Extraction 2/3, Forge 2/2, Taverne 1/2, Garde 0/3"]}
	var auto: Dictionary = {}
	for sd: int in want:
		var va: Dictionary = NewGameS.village(sd, D0, 0)
		auto[sd] = [_moves_str(AssignS.auto_assign(va, sd, 100, 2)), VText.slots_line(va, 2, names)]
		print("      auto Nv2 graine %d : %s ; %s" % [sd, auto[sd][0], auto[sd][1]])
	_check("auto Nv2: graines 1, 2, 3, jour 1 = jumeau (n°38 : graine 2, les 2 gardes en Forge et en Taverne)", auto == want, str(auto))
	# Surbrillance
	var vh: Dictionary = NewGameS.village(1, D0, 0)
	var hints: Array = [[3, "FORGE", 1], [3, "FORGE", 2], [3, "MAT", 1], [3, "GISEMENT", 1], [3, "MAT", 2], [0, "GATE", 1], [3, "GATE", 1], [3, "HOUSE0", 1], [3, "", 1]].map(
		func(h: Array) -> Array: return VText.drop_hint(vh, h[0], h[1], h[2], names))
	_check("drop_hint : 9 cas du jumeau", hints == [["Forge 1/1, échange", "ALERT"], ["Forge 1/2, libre", "GOOD"], ["Extraction 1/2, libre", "GOOD"],
		["Extraction 1/2, libre", "GOOD"], ["Extraction 1/3, libre", "GOOD"], ["Garde 2/2, échange", "ALERT"], [], [], []], str(hints))
	# UI instanciée : carte Grand Âtre
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var page: Node = uu.get_node(UiS.PAGES + "Village")
	var btn: Button = page.find_child("Agrandir", true, false)
	var card: Node = btn.get_parent()
	var titles: Array = card.find_children("*", "Label", false, false).filter(func(l: Label) -> bool: return l.text == "Agrandir")
	var tag: Label = card.get_parent().get_parent().find_child("Tag", true, false) # fiche -> Detail -> carte
	var vn: Dictionary = NewGameS.village(1, D0, 0)
	uu.show_village(vn, 10, true, "")
	var n: int = page.find_children("*", "", true, false).size()
	uu.set_atre_reason(AtreS.block_reason(vn, 0, true, D0))
	var reason: Label = card.get_child(btn.get_index() + 1)
	var s0: Array = [btn.disabled, reason.visible, reason.text, btn.text]
	vn["player_gold"] = 600
	vn["shops"]["MAT"]["stock"] = 40
	uu.set_atre_reason(AtreS.block_reason(vn, 40, true, D0))
	var s1: Array = [btn.disabled, reason.visible]
	AtreS.start(vn, pl, D0)
	uu.show_village(vn, 10, true, "")
	var s2: String = tag.text
	AtreS.finish_if_due(vn, D0 + 14400)
	uu.show_village(vn, 10, true, "")
	var s3: Array = [btn.visible, titles[0].visible, tag.text, page.find_children("*", "", true, false).size() == n]
	print("      carte Âtre %s %s « %s » %s" % [str(s0), str(s1), s2, str(s3)])
	_check("carte Âtre: section Agrandir une fois ; grisé « Il manque 600 Or » puis actif ; étiquette « Chantier » ; cachée au Nv2 ; aucun nœud créé par show_village",
		titles.size() == 1 and s0 == [true, true, "Il manque 600 Or", "Agrandir le Grand Âtre\n600 Or, 40 minerais, 40 Matériaux, 4 h"] and s1 == [false, false]
		and s2 == "Chantier" and s3 == [false, false, "", true] and tag.get_theme_color("font_color") == UiStyle.NEXT, str(s0) + str(s3))
	uu.free()
	# village.gd : arbres retirés de solid en place, brume repoussée, surbrillance
	var vil: Node2D = load("res://scenes/village/village.tscn").instantiate()
	root.add_child(vil)
	vil.propagate_notification(Node.NOTIFICATION_READY)
	VL.atre_level = 1
	vil.setup(1, {}, D0, func() -> Dictionary: return ProgressionS.new_player()) # sans PNJ : leurs nœuds ne sont prêts que dans l'arbre
	var psolid: Dictionary = vil.player()._solid
	var mat: ShaderMaterial = vil.get_node("Sol").material
	var before: Array = [psolid.has(Vector2i(-8, -16)), mat.get_shader_parameter("radius_px")]
	VL.atre_level = 2
	vil.set_atre_level()
	var after: Array = [psolid.has(Vector2i(-8, -16)), mat.get_shader_parameter("radius_px"), vil.player()._solid == psolid and is_same(vil.player()._solid, psolid)]
	VL.atre_level = 1
	var rects: Array = ["MAT", "GISEMENT", "FORGE", "TAVERN", "GATE"].map(func(s: String) -> Rect2: return vil.site_rect(s))
	vil.highlight_site("FORGE", "Forge 1/2, libre", UiStyle.GOOD)
	var cible: Node2D = vil.get_node("Cible")
	var h1: Array = [cible.visible, cible.get_child(0).text, cible.get_child(0).scale]
	vil.clear_highlight()
	_check("village.gd: (-8, -16) pleine puis libre au Nv2 (même dictionnaire chez le Joueur), radius_px 200 puis 296",
		before == [true, 200.0] and after == [false, 296.0, true], str(before) + str(after))
	_check("surbrillance: rectangles des 5 sites = jumeau ; Cible visible avec l'étiquette à l'échelle 2, puis masquée",
		rects == [Rect2(56, -56, 48, 48), Rect2(72, 88, 32, 32), Rect2(-104, -56, 48, 48), Rect2(-24, -120, 48, 48), Rect2(-24, 168, 48, 16)]
		and h1 == [true, "Forge 1/2, libre", Vector2(2, 2)] and not cible.visible, str(rects) + str(h1))
	vil.free()

# Jalon 22 : agrandissement des boutiques par chantier. Références : sortie de prep_jalon_22.py.
func _jalon_22() -> void:
	var names: Dictionary = VText.load_names()
	var costs: Array = [ShopUpS.cost(1), ShopUpS.cost(2), ShopUpS.cost(5), ShopUpS.cost(9)]
	var total: int = 0
	for l: int in range(1, ShopUpS.MAX_LEVEL):
		total += ShopUpS.cost(l)["gold"]
	print("      coûts Nv1, Nv2, Nv5, Nv9 : %s ; total 1 -> 10 : %d Or" % [str(costs), total])
	_check("boutiques: cost(1) 250/15/60, cost(2) 1 000/30/240, cost(5) plafonné à 1 440 min, cost(9) 20 250/135/1 440, total 71 250 Or",
		costs == [{"gold": 250, "mat": 15, "minutes": 60}, {"gold": 1000, "mat": 30, "minutes": 240}, {"gold": 6250, "mat": 75, "minutes": 1440},
		{"gold": 20250, "mat": 135, "minutes": 1440}] and total == 71250, str(costs))
	var t0: int = 1793268300 # 2026-10-29 10:05 UTC (11 h 05 à Paris)
	var t1: int = 1793311800 # 2026-10-29 22:10 UTC (23 h 10 à Paris)
	var vf: Callable = func(gold: int, mat: int, lvls: Array = [1, 1, 1], griffes: Array = [-1, -1, -1]) -> Dictionary:
		var v: Dictionary = {"player_gold": gold, "tz_offset_sec": 3600, "atre_lvl": 1, "shops": {}}
		var keys: Array = ["MAT", "TAVERN", "FORGE"]
		for i in 3:
			v["shops"][keys[i]] = {"stock": mat if keys[i] == "MAT" else 0, "lvl": lvls[i], "posture": "EQUILIBRE", "griffe_trait": griffes[i]}
		return v
	var va: Dictionary = vf.call(250, 15)
	va["atre_chantier_end"] = t0 + 600
	var cases: Array = [[vf.call(0, 0), "FORGE", false, "Chantier au village seulement"], [vf.call(0, 0), "FORGE", true, "Il manque 250 Or"],
		[vf.call(200, 0), "FORGE", true, "Il manque 50 Or"], [vf.call(250, 10), "FORGE", true, "Il manque 5 Matériaux en stock"],
		[vf.call(250, 15), "FORGE", true, ""], [vf.call(250, 15), "MAT", true, ""], [vf.call(999, 60, [1, 1, 2]), "FORGE", true, "Il manque 1 Or"],
		[vf.call(0, 0, [1, 1, 3]), "FORGE", true, "Il manque 2\u00a0250 Or"], [vf.call(99999, 60, [1, 1, 10]), "FORGE", true, "Niveau maximal"],
		[va, "FORGE", true, ""]]
	var got: Array = cases.map(func(c: Array) -> String: return ShopUpS.block_reason(c[0], c[1], c[2], t0, names))
	for g: String in got:
		print("      raison « %s »" % g)
	_check("boutiques: 10 raisons du jumeau (lieu, Or, séparateur, Matériaux, Matériaux se paie elle-même, niveau maximal, Âtre en chantier ne bloque pas)",
		got == cases.map(func(c: Array) -> String: return c[3]), str(got))
	var v: Dictionary = vf.call(300, 20)
	var log: Dictionary = ShopUpS.start(v, "FORGE", t0)
	print("      après start : Or %d, Matériaux %d ; %s" % [v["player_gold"], v["shops"]["MAT"]["stock"], str(log)])
	var during: Array = [ShopUpS.block_reason(v, "FORGE", true, t0, names), ShopUpS.block_reason(v, "TAVERN", true, t0, names)]
	_check("boutiques: start Forge : Or 300 -> 50, Matériaux 20 -> 5, fin = T0 + 3 600 ; « Chantier en cours, fini à 12 h 05 » ; Taverne « Il manque 200 Or »",
		[v["player_gold"], v["shops"]["MAT"]["stock"], v["shops"]["FORGE"]["chantier_end"]] == [50, 5, t0 + 3600]
		and log == {"event": "chantier_boutique", "boutique": "FORGE", "niveau": 2, "fin": t0 + 3600}
		and during == ["Chantier en cours, fini à 12 h 05", "Il manque 200 Or"], str(log) + str(during))
	var fin: Array = [ShopUpS.finish_if_due(v, "FORGE", t0 + 3599), v["shops"]["FORGE"]["lvl"], ShopUpS.finish_if_due(v, "FORGE", t0 - 86400)]
	fin.append_array([ShopUpS.finish_if_due(v, "FORGE", t0 + 3600), v["shops"]["FORGE"]["lvl"], v["shops"]["FORGE"].has("chantier_end"),
		ShopUpS.finish_if_due(v, "FORGE", t0 + 7200), v["shops"]["FORGE"]["lvl"]])
	var sinks: Array = [Eco.stock_max(false, v["shops"]["FORGE"]["lvl"]), Eco.daily_fixed_sink([1, 1, 2] as Array[int]), Eco.daily_fixed_sink([1, 1, 1] as Array[int])]
	_check("boutiques: finish_if_due : 1 s avant rien, horloge reculée rien, à la fin pile Nv2 et clé effacée, 2e appel sans effet ; stock max 50, frais 32 (24 avant)",
		fin == [false, 1, false, true, 2, false, false, 2] and sinks == [50, 32, 24], str(fin) + str(sinks))
	var v2: Dictionary = vf.call(1000, 60, [1, 1, 2])
	ShopUpS.start(v2, "FORGE", t1)
	var vm: Dictionary = vf.call(250, 15)
	ShopUpS.start(vm, "MAT", t0)
	var mats: Array = [vm["shops"]["MAT"]["stock"], ShopUpS.finish_if_due(vm, "MAT", t0 + 3600), Eco.stock_max(true, vm["shops"]["MAT"]["lvl"])]
	_check("boutiques: Nv2 -> 3 lancé à 23 h 10 « fini demain à 3 h 10 » ; Matériaux paie son chantier (15 -> 0), stock max 100 à la fin",
		ShopUpS.block_reason(v2, "FORGE", true, t1, names) == "Chantier en cours, fini demain à 3 h 10" and mats == [0, true, 100], str(mats))
	var one: Callable = func(end: Variant, lvl: int = 1) -> bool:
		var x: Dictionary = vf.call(0, 0, [1, 1, lvl])
		x["shops"]["FORGE"]["chantier_end"] = end
		ShopUpS.sanitize(x)
		return x["shops"]["FORGE"].has("chantier_end") and x["shops"]["FORGE"]["lvl"] == lvl
	var san: Array = [one.call(t0), one.call("12"), one.call(0), one.call(-5), one.call(1.5), one.call(t0, 10), one.call(t0, 9)]
	_check("boutiques: sanitize, 7 cas (gardé, texte, 0, négatif, float, Nv10, Nv9)", san == [true, false, false, false, false, false, true], str(san))
	# Sauvegarde : Forge Nv2, puis chantier en cours
	var st: Dictionary = SaveS.new_state(7, D0, 0)
	st["village"]["shops"]["FORGE"]["lvl"] = 2
	var st2: Dictionary = SaveS.new_state(7, D0, 0)
	st2["village"]["shops"]["FORGE"]["chantier_end"] = D0 + 3600
	for x: Dictionary in [st, st2]:
		x["seq"] = 1 # posé par save() en jeu
	_check("save: Forge Nv2 et chantier en cours relus à l'identique", SaveS.unpack(SaveS.pack(st)) == st and SaveS.unpack(SaveS.pack(st2)) == st2)
	# Textes
	var sh: Dictionary = {"stock": 0, "lvl": 1, "griffe_trait": -1}
	var shc: Dictionary = {"stock": 0, "lvl": 1, "griffe_trait": BD.TraitId.COSTAUD}
	var tx: Array = [VText.shop_upgrade_effect("MAT", sh), VText.shop_upgrade_effect("FORGE", sh), VText.shop_upgrade_effect("MAT", shc),
		VText.shop_upgrade_button(1, names), VText.shop_upgrade_button(2, names)[1], VText.shop_upgrade_button(3, names)[1],
		VText.shop_upgrade_button(9, names)[1], VText.shop_toast("FORGE", 2, names), VText.upgrade_button(1, names)]
	for t: Variant in tx:
		print("      " + str(t))
	_check("textes: shop_upgrade_effect (MAT, FORGE, MAT Costaud), shop_upgrade_button(1, 2, 3, 9), shop_toast ; upgrade_button de l'Âtre inchangé", tx == [
		"Niveau 2 : stock max 100, frais 16 Or/jour", "Niveau 2 : stock max 50, frais 16 Or/jour", "Niveau 2 : stock max 115, frais 16 Or/jour",
		PackedStringArray(["Agrandir la boutique", "250 Or, 15 Matériaux, 1 h"]), "1\u00a0000 Or, 30 Matériaux, 4 h", "2\u00a0250 Or, 45 Matériaux, 9 h",
		"20\u00a0250 Or, 135 Matériaux, 24 h", "Forge niveau 2 !", PackedStringArray(["Agrandir le Grand Âtre", "600 Or, 40 minerais, 40 Matériaux, 4 h"])], str(tx))
	# Villages de départ : stock max Nv1 -> Nv2, Griffe comprise
	var seeds: Dictionary = {}
	for sd: int in [1, 2, 3, 42]:
		var vs: Dictionary = NewGameS.village(sd, D0, 0)
		seeds[sd] = ["MAT", "TAVERN", "FORGE"].map(func(k: String) -> Array:
			var g: int = vs["shops"][k]["griffe_trait"]
			return [g, Eco.stock_max(k == "MAT", 1, g), Eco.stock_max(k == "MAT", 2, g)])
		print("      graine %d : %s" % [sd, str(seeds[sd])])
	var T: Dictionary = BD.TraitId
	_check("graines 1, 2, 3, 42 : Griffes et stock max Nv1 -> Nv2 = jumeau", seeds == {
		1: [[T.PERFECTIONNISTE, 60, 100], [T.BOSSEUR, 30, 50], [T.PERFECTIONNISTE, 30, 50]],
		2: [[T.TETE_EN_L_AIR, 60, 100], [T.COSTAUD, 34, 57], [T.BOSSEUR, 30, 50]],
		3: [[T.PERFECTIONNISTE, 60, 100], [T.COSTAUD, 34, 57], [T.NOCTAMBULE, 30, 50]],
		42: [[T.COSTAUD, 69, 115], [T.PERFECTIONNISTE, 30, 50], [T.BOUT_EN_TRAIN, 30, 50]]}, str(seeds))
	var prices: Array = [1, 2].map(func(l: int) -> int:
		return Eco.sell_price(BB.ITEM_BASE_GOLD[Dag.SHOP_ITEM["FORGE"]], 0, 30, Eco.stock_target(Eco.stock_max(false, l), "EQUILIBRE")))
	_check("prix Forge, stock 30, Équilibré, isolat 0 : 10 Or au Nv1, 12 Or au Nv2", prices == [10, 12], str(prices))
	# UI instanciée : sections Agrandir des boutiques
	var uu: CanvasLayer = _ui_ready("res://scenes/ui/ui_unfolded.tscn")
	var page: Node = uu.get_node(UiS.PAGES + "Village")
	var btns: Array = page.find_children("Agrandir", "Button", true, false)
	var by: Dictionary = {}
	for k in 3:
		var b: Button = btns[k + 1]
		var box: Node = b.get_parent()
		by[Dag.SHOP_ITEM.keys()[k]] = {"button": b, "reason": box.get_child(b.get_index() + 1), "title": box.get_child(b.get_index() - 2),
			"tag": box.get_parent().get_parent().find_child("Tag", true, false)}
	var vn: Dictionary = NewGameS.village(1, D0, 0)
	uu.show_village(vn, 10, true, "")
	var n: int = page.find_children("*", "", true, false).size()
	var reasons: Callable = func() -> Dictionary:
		var r: Dictionary = {}
		for k: String in vn["shops"]:
			r[k] = ShopUpS.block_reason(vn, k, true, D0, names)
		return r
	uu.set_shop_reasons(reasons.call())
	var f: Dictionary = by["FORGE"]
	var u0: Array = [btns.size(), f["title"].text, f["button"].disabled, f["reason"].visible, f["reason"].text, f["button"].text, f["reason"].get_theme_color("font_color") == UiStyle.REASON]
	vn["player_gold"] = 300
	vn["shops"]["MAT"]["stock"] = 60
	uu.set_shop_reasons(reasons.call())
	var u1: Array = [f["button"].disabled, f["reason"].visible]
	ShopUpS.start(vn, "FORGE", D0)
	uu.show_village(vn, 10, true, "")
	var u2: Array = ["MAT", "TAVERN", "FORGE"].map(func(k: String) -> String: return by[k]["tag"].text)
	vn["shops"]["TAVERN"]["lvl"] = 10
	uu.show_village(vn, 10, true, "")
	var u3: Array = [by["TAVERN"]["button"].visible, by["TAVERN"]["title"].visible, by["FORGE"]["button"].visible, page.find_children("*", "", true, false).size() == n]
	print("      cartes boutiques %s %s %s %s" % [str(u0), str(u1), str(u2), str(u3)])
	_check("cartes boutiques: une section Agrandir par boutique ; grisé « Il manque 250 Or » en REASON puis actif ; « Chantier » sur la seule Forge ; cachée au Nv10 ; aucun nœud créé",
		u0 == [4, "Agrandir", true, true, "Il manque 250 Or", "Agrandir la boutique\n250 Or, 15 Matériaux, 1 h", true] and u1 == [false, false]
		and u2 == ["", "", "Chantier"] and u3 == [false, false, true, true] and by["FORGE"]["tag"].get_theme_color("font_color") == UiStyle.NEXT, str(u0) + str(u3))
	uu.free()
	# Debug : « Finir le chantier » finit l'Âtre et la Forge
	var sd2: Dictionary = {"village": vf.call(0, 0)}
	sd2["village"]["atre_chantier_end"] = t0 + 14400
	sd2["village"]["shops"]["FORGE"]["chantier_end"] = t0 + 3600
	var d: Dictionary = DebugS.finish_chantier(sd2, t0)
	# Debug : remises à zéro, une par section
	var sz: Dictionary = SaveS.new_state(7, D0, 0)
	var fresh: Dictionary = SaveS.new_state(7, D0, 0)
	var pz: Dictionary = sz["player"]
	pz["voc_xp"]["COMBATTANT"] = 5000
	pz["cendre"] = 80
	pz["chest"][ForgeS.ORE] = 40
	pz["shard_bag"].append({"elite": false, "ilvl": 3})
	pz["equipment"][0] = null
	var vz: Dictionary = sz["village"]
	vz["player_gold"] = 900
	vz["atre_lvl"] = 2
	vz["atre_chantier_end"] = D0 + 60
	vz["shops"]["FORGE"]["lvl"] = 3
	vz["shops"]["TAVERN"]["chantier_end"] = D0 + 60
	vz["shops"]["MAT"]["stock"] = 55
	vz["npcs"][1]["moral"] = 10
	vz["npcs"][4]["post"] = "FORGE" # Nv2 : Forge 2/2 ; Âtre redescendu : Forge 2/1
	var npc0: Dictionary = vz["npcs"][0]
	DebugS.reset_player(sz)
	var z1: bool = is_same(sz["player"], pz) and pz == fresh["player"] and vz["player_gold"] == 900
	DebugS.reset_resources(sz)
	var z2: bool = vz["player_gold"] == 0 and vz["shops"]["MAT"]["stock"] == 0 and vz["shops"]["FORGE"]["lvl"] == 3
	DebugS.reset_buildings(sz)
	var z3: bool = not vz.has("atre_lvl") and not vz.has("atre_chantier_end") and vz["shops"].values().all(func(s: Dictionary) -> bool: return s["lvl"] == 1 and not s.has("chantier_end"))
	var fit: Dictionary = DebugS.fit_posts(sz)
	var occ: Dictionary = AssignS.occupancy(vz)
	var z4: bool = fit["avant"] == [[4, "FORGE", "EXTRACTION"]] and occ["FORGE"] == 1 and not vz["npcs"][4].has("locked") and DebugS.fit_posts(sz).is_empty()
	DebugS.reset_npcs(sz)
	var z5: bool = vz["npcs"] == fresh["village"]["npcs"] and is_same(vz["npcs"][0], npc0)
	_check("debug: Joueur, Ressources, Bâtiments, PNJ à zéro et Postes au plafond (Forge 2/1 -> PNJ 4 en Extraction, verrou rendu), chacun sa section",
		[z1, z2, z3, z4, z5] == [true, true, true, true, true], str([z1, z2, z3, z4, z5]) + str(fit) + str(occ))
	# Bâtiments à zéro : l'Âtre redescend, un arbre revient sous les pieds du joueur -> retour devant l'Âtre
	var vil: Node2D = load("res://scenes/village/village.tscn").instantiate()
	root.add_child(vil)
	vil.propagate_notification(Node.NOTIFICATION_READY)
	VL.atre_level = 2
	vil.setup(1, {}, D0, func() -> Dictionary: return ProgressionS.new_player())
	var pv: Node2D = vil.player()
	var spawn: Vector2 = VL.cell_center(VL.PLAYER_SPAWN_CELL)
	pv.position = VL.cell_center(Vector2i(-8, -16)) # arbre du Nv1 retiré au Nv2 (graine 1, jalon 21)
	var free_at: bool = not PlayerMotionS.overlaps(pv.position, pv._solid)
	VL.atre_level = 1
	vil.set_atre_level()
	var back: Array = [pv._solid.has(Vector2i(-8, -16)), pv.position == spawn, PlayerMotionS.overlaps(pv.position, pv._solid)]
	var far: Vector2 = VL.cell_center(Vector2i(3, 5))
	pv.position = far
	VL.atre_level = 2
	vil.set_atre_level()
	VL.atre_level = 1
	vil.set_atre_level()
	var stay: bool = pv.position == far
	vil.free()
	_check("Âtre redescendu : l'arbre (-8, -16) revient plein, le joueur dessus est ramené devant l'Âtre ; ailleurs il ne bouge pas",
		free_at and back == [true, true, false] and stay, str(back) + str(stay))
	_check("debug: Finir le chantier fixe les fins de l'Âtre et de la Forge à now ; rien sans chantier",
		[sd2["village"]["atre_chantier_end"], sd2["village"]["shops"]["FORGE"]["chantier_end"]] == [t0, t0]
		and d == {"action": "fin_chantier", "avant": ["ATRE", "FORGE"], "apres": t0} and DebugS.finish_chantier({"village": vf.call(0, 0)}, t0).is_empty(), str(d))

# Jalon 17 bis : feu de camp animé (4 images de 125 ms). Références : prompt d'Antho (prep_jalon_17bis.py).
func _jalon_17b() -> void:
	var xs: Array = []
	var other: bool = true
	for ms: int in [0, 124, 125, 249, 250, 375, 499, 500, 1000, 1124, 1125]:
		var r: Rect2 = UiS.fire_region(ms)
		xs.append(int(r.position.x))
		other = other and r.position.y == 0.0 and r.size == Vector2(12, 16)
	print("      fire_region x " + str(xs))
	_check("fire_region: x = 2, 2, 18, 18, 34, 50, 50, 2, 2, 2, 18 ; y 0, 12 × 16", xs == [2, 2, 18, 18, 34, 50, 50, 2, 2, 2, 18] and other, str(xs))
	for path: String in ["res://scenes/ui/ui_folded.tscn", "res://scenes/ui/ui_unfolded.tscn"]:
		var ui: CanvasLayer = _ui_ready(path)
		var fire: AtlasTexture = ui.get_node("Margin/VBox/Hud/Ligne/Cendre/Icone").texture
		var still: Array = []
		for k: String in ["Eclats", "Minerai"] + ([] if ui.compact else ["Or"]):
			still.append(ui.get_node("Margin/VBox/Hud/Ligne/%s/Icone" % k).texture.region)
		var changed: Array[int] = [0]
		fire.changed.connect(func() -> void: changed[0] += 1)
		ui._animate_fire(250)
		var r250: Array = [fire.region, fire.atlas.resource_path, changed[0]]
		ui._animate_fire(260)
		var r260: int = changed[0]
		ui._animate_fire(0)
		var after: Array = []
		for k: String in ["Eclats", "Minerai"] + ([] if ui.compact else ["Or"]):
			after.append(ui.get_node("Margin/VBox/Hud/Ligne/%s/Icone" % k).texture.region)
		print("      %s %s, 260 -> changed %d, 0 -> %s" % [path.get_file(), str(r250), r260, str(fire.region)])
		_check("feu %s: 250 -> (34, 0, 12, 16) sur campfire_16x16.png ; 260 même image, aucun changed ; 0 -> (2, 0, 12, 16) ; autres icônes fixes" % path.get_file(),
			r250 == [Rect2(34, 0, 12, 16), "res://assets/icons/hud/campfire_16x16.png", 1] and r260 == 1 and fire.region == Rect2(2, 0, 12, 16)
			and after == still, str(r250))
		ui.free()

# Sacoche : e Éclats d'Élite puis n normaux, à l'ilvl donné (ordre de la conversion de SaveManager).
func _bag(n: int, e: int, ilvl: int = 1) -> Array:
	var bag: Array = []
	for i in e:
		bag.append({"elite": true, "ilvl": ilvl})
	for i in n:
		bag.append({"elite": false, "ilvl": ilvl})
	return bag

func _armor(slot: int, affixes: Array) -> Dictionary:
	var a: Array = []
	for x: Array in affixes:
		a.append({"id": x[0], "units": x[1]})
	return {"slot": slot, "rarity": 2, "ilvl": 1, "schools": [], "affixes": a}

func _f(values: Array) -> Array[float]:
	var out: Array[float] = []
	out.assign(values)
	return out

func _s(values: Array) -> Array[String]:
	var out: Array[String] = []
	out.assign(values)
	return out

func _near_eps(a: Array, b: Array, eps: float) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not _approx(a[i], b[i], eps):
			return false
	return true

# want = [slot, rareté, Écoles ("EEE", "EBE"… ou "" pour une armure), [[id, units à 1e-4]]].
func _piece_is(piece: Dictionary, want: Array, ilvl: int = 1) -> bool:
	if piece["slot"] != want[0] or piece["rarity"] != want[1] or piece["ilvl"] != ilvl or _schools_str(piece) != want[2] or piece["affixes"].size() != want[3].size():
		return false
	for k in want[3].size():
		if piece["affixes"][k]["id"] != want[3][k][0] or not _approx(piece["affixes"][k]["units"], want[3][k][1], 1e-4):
			return false
	return true

func _schools_str(piece: Dictionary) -> String:
	var s: String = ""
	for x: int in piece["schools"]:
		s += "E" if x == BC.SchoolId.FOYER else "B"
	return s

func _piece_str(n: int, piece: Dictionary) -> String:
	var a: PackedStringArray = []
	for x: Dictionary in piece["affixes"]:
		a.append("%s %.4f" % [x["id"], x["units"]])
	return "%2d %-10s %s ilvl %d %s [%s]" % [n, ["WEAPON", "HELMET", "CHESTPLATE", "BOOTS"][piece["slot"]], BC.RARITY_KEYS[piece["rarity"]], piece["ilvl"],
		"/".join(_schools_str(piece).split("", false)), ", ".join(a)]

# Joueur neuf local, relu par l'Expedition comme le fait main.gd avec SaveManager.state.
func _fresh_ref() -> Callable:
	var p: Dictionary = ProgressionS.new_player()
	return func() -> Dictionary: return p

func _approx(a: float, b: float, eps: float) -> bool:
	return absf(a - b) <= eps

func _jalon_10(vd: Dictionary, built: Dictionary, p: Dictionary) -> void:
	var foyer3: Array[int] = [BC.SchoolId.FOYER, BC.SchoolId.FOYER, BC.SchoolId.FOYER]
	var mixed: Array[int] = [BC.SchoolId.FOYER, BC.SchoolId.FOYER, BC.SchoolId.SPORE]
	_check("combat: starting_weapon_atk == 10,35", _approx(CombatS.starting_weapon_atk(), 10.35, 1e-9), str(CombatS.starting_weapon_atk()))
	_check("combat: compute_weapon_atk(1, 0, sans 3/3) == 10,0", _approx(BC.compute_weapon_atk(1, 0, mixed), 10.0, 1e-9))
	_check("combat: starting_weapon_range == 24 (n°29, 40 au jalon 10)", CombatS.starting_weapon_range() == 24.0)
	_check("combat: attack_period == 0,8333...", _approx(CombatS.attack_period(), 1.0 / 1.2, 1e-12), str(CombatS.attack_period()))
	var w10: float = BC.compute_weapon_atk(10, 0, foyer3)
	_check("combat: compute_weapon_atk(10, 0, 3/3 Foyer) == 52,2675", _approx(w10, 52.2675, 1e-9), str(w10))
	for c: Array in [[1, 10.35, {"hp": 100, "atk": 22, "def": 5}], [10, w10, {"hp": 262, "atk": 86, "def": 18}]]:
		_check("combat: player_stats(%d, %s) == %s" % [c[0], str(c[1]), str(c[2])], CombatS.player_stats(c[0], c[1]) == c[2], str(CombatS.player_stats(c[0], c[1])))
	_check("combat: mob_level(0) == 1, mob_level(4) == 41", CombatS.mob_level(0) == 1 and CombatS.mob_level(4) == 41)
	for c: Array in [[1, 0, "NORMAL", {"hp": 95, "atk": 10, "def": 4}], [10, 0, "NORMAL", {"hp": 356, "atk": 29, "def": 14}],
			[10, 0, "ELITE", {"hp": 2670, "atk": 47, "def": 14}], [1, 0, "BOSS", {"hp": 3610, "atk": 24, "def": 4}], [50, 4, "BOSS", {"hp": 92172, "atk": 452, "def": 100}]]:
		_check("combat: mob_stats(%d, %d, %s) == %s" % c, CombatS.mob_stats(c[0], c[1], c[2]) == c[3], str(CombatS.mob_stats(c[0], c[1], c[2])))
	_check("combat: mitigation(4, 1) == 0,0625", _approx(CombatS.mitigation(4, 1), 0.0625, 1e-12))
	_check("combat: mitigation(5, 1) == 0,076923", _approx(CombatS.mitigation(5, 1), 0.076923, 1e-6))
	for c: Array in [[22, 4, 1, false, 1.0, 20], [22, 4, 1, true, 1.0, 30], [10, 5, 1, false, 1.0, 9], [86, 14, 10, false, 1.0, 78],
			[86, 14, 10, true, 1.0, 117], [22, 4, 1, false, 2.2, 45], [22, 4, 1, false, 3.5, 72]]:
		var dm: int = CombatS.damage(c[0], c[1], c[2], c[3], c[4])
		_check("combat: damage(%d, %d, %d, %s, %s) == %d" % [c[0], c[1], c[2], str(c[3]), str(c[4]), c[5]], dm == c[5], str(dm))
	# ELITE 1 : 220 avec roundi, 219 en floor (jalon 15)
	for c: Array in [["NORMAL", 0, 30], ["ELITE", 1, 219], ["BOSS", 4, 666]]:
		_check("combat: kill_xp(%s, %d) == %d" % c, CombatS.kill_xp(c[0], c[1]) == c[2], str(CombatS.kill_xp(c[0], c[1])))
	for c: Array in [[95, 95, 12], [75, 95, 10], [1, 95, 1], [0, 95, 0], [91, 100, 11], [-5, 95, 0]]:
		_check("combat: bar_fill_px(%d, %d) == %d" % c, CombatS.bar_fill_px(c[0], c[1]) == c[2], str(CombatS.bar_fill_px(c[0], c[1])))
	for c: Array in [[Vector2(0, 192), true], [Vector2(0, 199.9), true], [Vector2(0, 200), false], [Vector2(0, 32), true],
			[Vector2(120, 120), true], [Vector2(136, 136), false], [Vector2(0, 216), false]]:
		_check("combat: in_village(%s) == %s" % [str(c[0]), str(c[1])], CombatS.in_village(c[0]) == c[1])
	var pts: Array[Vector2] = [Vector2(0, 40), Vector2(30, 0), Vector2(-30, 0), Vector2(100, 0)]
	var none: Array[Vector2] = []
	_check("combat: nearest_in_range portée 40 == 1, portée 29 == -1, vide == -1",
		CombatS.nearest_in_range(Vector2.ZERO, pts, 40) == 1 and CombatS.nearest_in_range(Vector2.ZERO, pts, 29) == -1 and CombatS.nearest_in_range(Vector2.ZERO, none, 40) == -1)
	for c: Array in [[false, 96.0, true, true], [false, 97.0, true, false], [true, 144.0, true, true], [true, 145.0, true, false], [true, 10.0, false, false]]:
		_check("combat: mob_chasing(%s, %.0f, %s) == %s" % [str(c[0]), c[1], str(c[2]), str(c[3])], CombatS.mob_chasing(c[0], c[1], c[2]) == c[3])
	# Cellules
	var vc: Dictionary = CombatS.village_cells()
	_check("combat: village_cells == 441", vc.size() == 441, str(vc.size()))
	var solid1: Dictionary = _solid9(vd, built, p, 1)
	var mob1: Dictionary = solid1.duplicate()
	mob1.merge(vc)
	var mob42: Dictionary = _solid9(vd, built, p, 42).duplicate()
	mob42.merge(vc)
	_check("combat: solid monstres graine 1 == 767 (joueur 393), graine 42 == 753", mob1.size() == 767 and solid1.size() == 393 and mob42.size() == 753, "%d %d %d" % [mob1.size(), solid1.size(), mob42.size()])
	var bad_spawn: String = ""
	for sp: Array in LISIERE_SPAWNS_10:
		var sc: Vector2 = VL.cell_center(VL.v2i(sp))
		if PlayerMotionS.overlaps(sc, mob1) or CombatS.in_village(sc):
			bad_spawn += str(sc) + " "
	_check("combat: 3 spawns libres pour les monstres, hors du village", LISIERE_SPAWNS_10.size() == 3 and bad_spawn == "", bad_spawn)
	var at_edge: Vector2 = PlayerMotionS.move(Vector2(0, 256), Vector2(0, -100), mob1)
	_check("combat: move((0, 256), (0, -100), solid monstres) == (0, 203)", at_edge == Vector2(0, 203), str(at_edge))
	# RNG
	var rng: RngS.Pcg32 = RngS.make_rng(1, "combat/joueur")
	var crits: Array[int] = []
	var first: float = -1.0
	for i in 40:
		var f: float = rng.next_float()
		if i == 0:
			first = f
		if f < BA.PLAYER_BASE_CRIT_RATE:
			crits.append(i)
	_check("combat: rng combat/joueur graine 1, critiques [11, 19, 26, 28, 39], premier 0,977992", crits == [11, 19, 26, 28, 39] and _approx(first, 0.977992, 1e-6), "%s %f" % [str(crits), first])
	# Monstre seul
	var stats1: Dictionary = CombatS.mob_stats(1, 0, "NORMAL")
	var mob: Node2D = load("res://scenes/combat/mob.tscn").instantiate()
	root.add_child(mob)
	mob.setup(Vector2(0, 256), null, null, mob1, stats1)
	var hits: Array[int] = []
	for i in 26:
		if mob.step(1.0 / 60.0, Vector2(0, 240), true):
			hits.append(i + 1)
	_check("monstre: télégraphe au 1er appel, coup au 26e", hits == [26], str(hits))
	mob.respawn()
	hits.clear()
	var moved: bool = false
	for i in 26:
		if mob.step(1.0 / 60.0, Vector2(0, 240) if i < 9 else Vector2(0, 200), true):
			hits.append(i + 1)
		moved = moved or mob.position != Vector2(0, 256)
	_check("monstre: cible partie au 10e appel -> rate, immobile pendant le télégraphe", hits.is_empty() and not moved, "%s %s" % [str(hits), str(mob.position)])
	mob.respawn()
	var deaths: Array = []
	for i in 5:
		deaths.append(mob.take_hit(20))
	_check("monstre: 4 coups de 20 -> vivant, 5e -> mort, invisible", deaths == [false, false, false, false, true] and not mob.visible and not mob.alive, str(deaths))
	mob.respawn()
	_check("monstre: respawn -> 95 PV, visible, (0, 256)", mob.hp == 95 and mob.visible and mob.alive and mob.position == Vector2(0, 256))
	mob.free()
	# Joueur seul
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid1)
	var r1: bool = pl.take_hit(9)
	_check("joueur: take_hit(9) -> vrai, PV 91", r1 and pl.hp == 91, str(pl.hp))
	pl.dodge(Vector2(1, 0))
	pl._process(1.0 / 60.0)
	var r2: bool = pl.take_hit(9)
	_check("joueur: esquive + 1 image -> take_hit faux, PV 91", not r2 and pl.hp == 91, str(pl.hp))
	for i in 12:
		pl._process(1.0 / 60.0)
	var r3: bool = pl.take_hit(9)
	_check("joueur: 13 images -> take_hit vrai, PV 82", r3 and pl.hp == 82, str(pl.hp))
	pl.free()
	_evacuation_10b(solid1)
	pl = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid1)
	pl.hp = 50
	pl.position = Vector2(0, 32)
	pl._process(1.0 / 60.0)
	_check("joueur: dans le village -> PV 100", pl.hp == 100, str(pl.hp))
	pl.set_move_dir(Vector2(1, 0))
	pl._process(1.0 / 60.0)
	var cs1: bool = pl.can_strike()
	pl.set_move_dir(Vector2.ZERO)
	pl._process(1.0 / 60.0)
	var cs2: bool = pl.can_strike()
	pl.dodge(Vector2(1, 0))
	pl._process(1.0 / 60.0)
	_check("joueur: can_strike vrai en marche et à l'arrêt, faux en esquive", cs1 and cs2 and not pl.can_strike())
	pl.free()
	# Intégration S1 et S3
	var s1: Dictionary = _s1(vd, solid1, 1.0 / 60.0, 260, -1)
	_check("S1: coups du joueur aux images 14, 64, 115, 166, 217 (portée 24)", s1["strikes"] == [14, 64, 115, 166, 217], str(s1["strikes"]))
	_check("S1: PV du monstre 0 : 75, 55, 35, 15, -5 ; aucun critique ; mort à l'image 217", s1["mob_hp"] == [75, 55, 35, 15, -5] and s1["crits"] == 0 and s1["mob_death"] == 217, "%s %d %d" % [str(s1["mob_hp"]), s1["crits"], s1["mob_death"]])
	var wt: Array = s1["windups"]
	var wt_ok: bool = wt.size() == 4
	if wt_ok:
		for k in 4:
			wt_ok = wt_ok and _approx(wt[k], [0.3667, 1.3667, 2.3833, 3.4][k], 1e-3)
	_check("S1: télégraphes à 0,3667 / 1,3667 / 2,3833 / 3,4 s", wt_ok, str(wt))
	_check("S1: coups reçus aux images 47, 107, 168 -> PV 91, 82, 73", s1["received"] == [47, 107, 168] and s1["player_hp"] == [91, 82, 73], "%s %s" % [str(s1["received"]), str(s1["player_hp"])])
	_check("S1: après 260 images, PV 73, monstre 0 mort en (0 ; 231,5), 1 et 2 à 95 PV en (0, 320) et (0, 384), jamais en poursuite",
		s1["final_hp"] == 73 and not s1["alive"][0] and s1["pos"][0].distance_to(Vector2(0, 231.5)) <= 0.01 and s1["alive"][1] and s1["alive"][2]
		and s1["hp"][1] == 95 and s1["hp"][2] == 95 and s1["pos"][1] == Vector2(0, 320) and s1["pos"][2] == Vector2(0, 384) and not s1["chased12"], str(s1))
	for c: Array in [[1.0 / 30.0, 130], [1.0 / 120.0, 520]]:
		var sx: Dictionary = _s1(vd, solid1, c[0], c[1], -1)
		_check("S1: delta 1/%d sur %d images -> 5 coups, 3 reçus, PV 73" % [roundi(1.0 / c[0]), c[1]], sx["strikes"].size() == 5 and sx["received"].size() == 3 and sx["final_hp"] == 73, str(sx))
	var s3a: Dictionary = _s1(vd, solid1, 1.0 / 60.0, 1416, 261)
	_check("S3: PV 100 à l'image 261", s3a["hp_261"] == 100, str(s3a["hp_261"]))
	_check("S3: monstre 0 toujours mort après 1 416 images", not s3a["alive"][0])
	var s3b: Dictionary = _s1(vd, solid1, 1.0 / 60.0, 1417, 261)
	_check("S3: monstre 0 vivant à 95 PV en (0, 256) après 1 417 images, réapparition à l'image 1 417", s3b["alive"][0] and s3b["hp"][0] == 95 and s3b["pos"][0] == Vector2(0, 256) and s3b["respawn"] == 1417, str(s3b))
	var s1l: Dictionary = _s1(vd, solid1, 1.0 / 60.0, 2700, -1)
	_check("S1 prolongé à 2 700 images : monstre 0 toujours mort", not s1l["alive"][0])
	_k1(solid1)
	# Scènes
	var mob_state: SceneState = (load("res://scenes/combat/mob.tscn") as PackedScene).get_state()
	var mob_nodes: Array[String] = []
	for i in mob_state.get_node_count():
		mob_nodes.append(mob_state.get_node_name(i))
	_check("scenes: mob.tscn = Monstre, Ombre, Sprite", mob_nodes == ["Monstre", "Ombre", "Sprite"], str(mob_nodes))
	var vil: Node = load("res://scenes/village/village.tscn").instantiate()
	var lis: Node2D = vil.get_node_or_null("Entites/Segment")
	_check("scenes: village.tscn contient Entites/Segment, y_sort_enabled", lis != null and lis.y_sort_enabled)
	_check("scenes: village.gd sans set_combat_active, Segment en PROCESS_MODE_INHERIT", not vil.has_method("set_combat_active") and lis.process_mode == Node.PROCESS_MODE_INHERIT)
	vil.free()
	_jalon_10b(vd, solid1)
	var mi: Array = vd["tiles"]["monstre"]
	var clash: bool = mi == vd["tiles"]["joueur"]
	for n: String in vd["npc_sprites"]:
		clash = clash or vd["tiles"][n] == mi
	_check("village.json: monstre ni joueur ni PNJ, segment mob_sprite monstre", not clash and vd["segment"]["mob_sprite"] == "monstre")
	_jalon_11(vd, solid1)

# Jalon 11 bis : K1 = S1, mais le joueur marche vers le sud des images 1 à 60 (auto-attaque en marche).
func _k1(solid: Dictionary) -> void:
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid)
	var lis: Node2D = LisiereS.new()
	root.add_child(lis)
	lis.setup(1, 0, pl, solid, LISIERE_SPAWNS_10, null, null)
	var mobs: Array[Node2D] = lis.mobs()
	var prev: Array[int] = [95, 95, 95]
	var prev_pl: int = pl.hp
	var strikes: Array = []
	var received: Array[int] = []
	var moving_51: bool = false
	var death2: int = -1
	pl.set_move_dir(Vector2(0, 1))
	for f in range(1, 261):
		if f == 61:
			pl.set_move_dir(Vector2.ZERO)
		pl._process(1.0 / 60.0)
		lis._process(1.0 / 60.0)
		for i in 3:
			if mobs[i].hp < prev[i]:
				strikes.append([f, i, maxi(mobs[i].hp, 0)])
				if f == 55:
					moving_51 = pl.state == pl.State.MOVE
			prev[i] = mobs[i].hp
		if death2 < 0 and not mobs[2].alive:
			death2 = f
		if pl.hp < prev_pl:
			received.append(f)
		prev_pl = pl.hp
	_check("K1: coups (5, 0, 75) (55, 2, 75) (106, 2, 55) (157, 2, 35) (208, 2, 15) (259, 2, 0), celui de l'image 55 en marche",
		strikes == [[5, 0, 75], [55, 2, 75], [106, 2, 55], [157, 2, 35], [208, 2, 15], [259, 2, 0]] and moving_51, "%s %s" % [str(strikes), str(moving_51)])
	_check("K1: coups reçus 79, 119, 139, 140, 180, 200, 201, 241 ; PV 28 ; monstre 2 mort à l'image 259 ; joueur en (0, 356,0003)",
		received == [79, 119, 139, 140, 180, 200, 201, 241] and pl.hp == 28 and death2 == 259 and pl.position.distance_to(Vector2(0, 356.0003)) <= 1e-3,
		"%s %d %d %s" % [str(received), pl.hp, death2, str(pl.position)])
	lis.free()
	pl.free()

# Jalon 11 : segment de Brume, expédition, saturation. Jumeau Python : prep_jalon_11.py.
func _jalon_11(vd: Dictionary, solid1: Dictionary) -> void:
	# BalanceA (n°26, n°27, volet E)
	_check("balanceA: bloc segment (n°26, n°27)", BA.SEGMENT_NODES_COUNT_VERTICAL_SLICE == 3 and BA.SEGMENT_NODE_NORMAL_MOBS == [6, 6, 12]
		and BA.SEGMENT_NODE_MIST_NODES == [4, 4, 0] and BA.SEGMENT_ELITE_NODE_INDEX == 2 and BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET == 80
		and BA.SEGMENT_STD_RUN_CENDRE_CAP == 100 and BA.SIM_ROUTINE_A_NORMAL_MOBS == [6, 6, 12] and BA.SIM_ROUTINE_A_MIST_NODES == [2, 2, 0]
		and BA.SIM_ROUTINE_B_NORMAL_MOBS == [2, 6, 0] and BA.SIM_ROUTINE_B_MIST_NODES == [4, 4, 0]
		and BA.ARENA_INTER_WAVE_REST_SEC == 5.0 and BA.ARENA_INTER_WAVE_HEAL_RATIO == 0.25) # 0,50 au n°27, 0,25 au n°29
	_check("balanceA: 24 normaux et 8 nœuds de Brume sur le segment", _sum_ints(BA.SEGMENT_NODE_NORMAL_MOBS) == 24 and _sum_ints(BA.SEGMENT_NODE_MIST_NODES) == 8)
	_check("balanceA: SEGMENT_STD_RUN_CENDRE_CAP == SEGMENT_PRE_ELITE_CENDRE_BUDGET + CENDRE_GAIN_ELITE_MOB", BA.SEGMENT_STD_RUN_CENDRE_CAP == BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET + BA.CENDRE_GAIN_ELITE_MOB)
	var waves: Array = [BA.ARENA_WAVE_1_SPAWN_SEC, BA.ARENA_WAVE_2_SPAWN_SEC, BA.ARENA_WAVE_3_SPAWN_SEC]
	var wave_ok: bool = true
	var gaps: Array[float] = []
	for w in 3:
		var t: Array = waves[w]
		wave_ok = wave_ok and t.size() == BA.ARENA_WAVE_NORMAL_MOBS[w] + BA.ARENA_WAVE_ELITE_MOBS[w]
		var gap: float = INF
		for k in t.size():
			wave_ok = wave_ok and t[k] < BA.ARENA_WAVE_DURATION_SEC
			if k > 0:
				gap = minf(gap, t[k] - t[k - 1])
		gaps.append(gap)
	_check("balanceA: arène 5 / 7 / 1 apparitions (n°29), écarts min 3,0 et 3,0 s, toutes < 30 s",
		wave_ok and waves[0].size() == 5 and waves[1].size() == 7 and waves[2].size() == 1 and gaps[0] == 3.0 and gaps[1] == 3.0
		and BA.ARENA_WAVE_1_SPAWN_SEC == [0.0, 3.0, 8.0, 14.0, 20.0] and BA.ARENA_WAVE_2_SPAWN_SEC == [0.0, 3.0, 7.0, 11.0, 15.0, 19.0, 23.0], str(gaps))
	# Profils A et B (1 expédition standard)
	var crafts: Dictionary = {"A": 2, "B": 4}
	var fiche: Dictionary = {"A": BA.XP_BOARD_FICHE_COMBAT, "B": BA.XP_BOARD_FICHE_ARTISAN}
	var mobs_r: Dictionary = {"A": BA.SIM_ROUTINE_A_NORMAL_MOBS, "B": BA.SIM_ROUTINE_B_NORMAL_MOBS}
	var mist_r: Dictionary = {"A": BA.SIM_ROUTINE_A_MIST_NODES, "B": BA.SIM_ROUTINE_B_MIST_NODES}
	for r: String in ["A", "B"]:
		var kills: int = _sum_ints(mobs_r[r])
		var nodes: int = _sum_ints(mist_r[r])
		var xp: int = kills * BA.XP_KILL_NORMAL + nodes * BA.XP_GATHER_MIST_NODE + BA.XP_KILL_ELITE + fiche[r] + crafts[r] * BA.XP_CRAFT_WITH_CENDRE
		var cendre: int = kills * BA.CENDRE_GAIN_NORMAL_MOB + nodes * BA.CENDRE_GAIN_MIST_NODE + BA.CENDRE_GAIN_ELITE_MOB
		var shards: float = kills * BA.SHARD_DROP_CHANCE_NORMAL + nodes * BA.SHARD_DROP_CHANCE_MIST_NODE + BA.SHARD_DROP_CHANCE_ELITE
		var cost: int = crafts[r] * BA.CENDRE_COST_STANDARD_CRAFT
		_check("profil %s: XP 1 680, Cendre 100, Éclats 3,0, crafts %d <= 100" % [r, cost], xp == 1680 and cendre == 100 and _approx(shards, 3.0, 1e-9) and cost <= cendre,
			"%d %d %f %d" % [xp, cendre, shards, cost])
	# PlayerMotion borné
	_check("move: overlaps((0, 1632), {}, node_rect(0)) faux, overlaps((0, 1632), {}) vrai",
		not PlayerMotionS.overlaps(Vector2(0, 1632), {}, SegGenS.node_rect(0)) and PlayerMotionS.overlaps(Vector2(0, 1632), {}))
	# SegmentGen : références du jumeau
	var m0: Dictionary = SegGenS.node_map(1, 0)
	var rows0: Array[int] = []
	for k in SegGenS.slot_count(0):
		rows0.append(SegGenS.slot_row(k, SegGenS.slot_count(0)))
	_check("segment graine 1 nœud 0: lignes, 6 monstres, 4 nœuds, 853 arbres, 857 pleines",
		rows0 == [12, 20, 28, 36, 44, 52, 60, 68, 76, 84]
		and m0["mobs"] == [Vector2i(-13, 120), Vector2i(8, 128), Vector2i(-7, 144), Vector2i(-12, 160), Vector2i(-4, 168), Vector2i(5, 184)]
		and m0["mist"] == [Vector2i(5, 112), Vector2i(-11, 136), Vector2i(-9, 152), Vector2i(5, 176)]
		and m0["trees"].size() == 853 and SegGenS.solid_cells(m0).size() == 857, "%s %s %s %d" % [str(rows0), str(m0["mobs"]), str(m0["mist"]), m0["trees"].size()])
	var m1: Dictionary = SegGenS.node_map(1, 1)
	_check("segment graine 1 nœud 1: Brasero (0, 248), 29 sûres, 6 monstres, 4 nœuds, 852 arbres, 857 / 885 pleines",
		m1.get("brazier") == Vector2i(0, 248) and m1["safe"].size() == 29
		and m1["mobs"] == [Vector2i(-9, 211), Vector2i(13, 218), Vector2i(6, 233), Vector2i(13, 240), Vector2i(-14, 255), Vector2i(6, 284)]
		and m1["mist"] == [Vector2i(-14, 226), Vector2i(-11, 262), Vector2i(14, 269), Vector2i(7, 277)]
		and m1["trees"].size() == 852 and SegGenS.solid_cells(m1).size() == 857 and SegGenS.mob_solid_cells(m1).size() == 885,
		"%s %s %d %d" % [str(m1["mobs"]), str(m1["mist"]), m1["trees"].size(), SegGenS.mob_solid_cells(m1).size()])
	var m2: Dictionary = SegGenS.node_map(1, 2)
	_check("segment graine 1 nœud 2: 12 monstres, aucun nœud, 844 arbres, (0, 395) arbre",
		m2["mobs"] == [Vector2i(-11, 311), Vector2i(12, 318), Vector2i(-10, 324), Vector2i(-4, 331), Vector2i(13, 338), Vector2i(-14, 344),
			Vector2i(-5, 351), Vector2i(-8, 358), Vector2i(-11, 364), Vector2i(11, 371), Vector2i(5, 378), Vector2i(-4, 384)]
		and m2["mist"].is_empty() and m2["trees"].size() == 844 and m2["trees"].has(Vector2i(0, 395)), "%s %d" % [str(m2["mobs"]), m2["trees"].size()])
	var g0: Dictionary = SegGenS.node_map(42, 0)
	var g1: Dictionary = SegGenS.node_map(42, 1)
	var g2: Dictionary = SegGenS.node_map(42, 2)
	_check("segment graine 42: nœud 0 contenu et 819 arbres, nœud 1 841 / 846, nœud 2 824",
		g0["mobs"] == [Vector2i(8, 120), Vector2i(14, 128), Vector2i(4, 152), Vector2i(-13, 160), Vector2i(13, 168), Vector2i(10, 184)]
		and g0["mist"] == [Vector2i(9, 112), Vector2i(14, 136), Vector2i(6, 144), Vector2i(-8, 176)] and g0["trees"].size() == 819
		and g1["trees"].size() == 841 and SegGenS.solid_cells(g1).size() == 846 and g2["trees"].size() == 824,
		"%s %s %d %d %d %d" % [str(g0["mobs"]), str(g0["mist"]), g0["trees"].size(), g1["trees"].size(), SegGenS.solid_cells(g1).size(), g2["trees"].size()])
	# Accessibilité et isolement des monstres
	var min_gap: Array[float] = []
	for seed: int in [1, 42]:
		for i in 3:
			var m: Dictionary = SegGenS.node_map(seed, i)
			var solid: Dictionary = SegGenS.solid_cells(m)
			var rect: Rect2i = m["rect"]
			var start: Vector2i = Vector2i(0, rect.position.y + 2)
			var seen: Dictionary = {start: true}
			var queue: Array[Vector2i] = [start]
			while not queue.is_empty():
				var c: Vector2i = queue.pop_front()
				for d: Vector2i in VL.NEIGHBORS:
					var n: Vector2i = c + d
					if rect.has_point(n) and not solid.has(n) and not seen.has(n):
						seen[n] = true
						queue.append(n)
			var bad: String = ""
			for c: Vector2i in m["mobs"]:
				if not seen.has(c):
					bad += "monstre %s " % str(c)
			for c: Vector2i in m["mist"]:
				var near: bool = false
				for d: Vector2i in VL.NEIGHBORS:
					near = near or seen.has(c + d)
				if not near:
					bad += "brume %s " % str(c)
			for c: Vector2i in m["passages"]:
				if not seen.has(c):
					bad += "passage %s " % str(c)
			var gap: float = INF
			for a in m["mobs"].size():
				for b in range(a + 1, m["mobs"].size()):
					gap = minf(gap, VL.cell_center(m["mobs"][a]).distance_to(VL.cell_center(m["mobs"][b])))
			if seed == 1:
				min_gap.append(snappedf(gap, 0.1))
			_check("segment graine %d nœud %d: monstres, nœuds de Brume et passages accessibles ; monstres à plus de 96 px" % [seed, i], bad == "" and gap > 96.0, "%s %f" % [bad, gap])
	_check("segment graine 1: écarts min 181,0 / 158,4 / 107,3 px", min_gap.size() == 3 and _approx(min_gap[0], 181.0, 0.05) and _approx(min_gap[1], 158.4, 0.05) and _approx(min_gap[2], 107.3, 0.05), str(min_gap))
	var pass_ok: bool = SegGenS.passages() == {Vector2i(0, 26): [0, Vector2i(0, 102)], Vector2i(0, 100): [-1, Vector2i(0, 24)], Vector2i(0, 195): [1, Vector2i(0, 202)],
		Vector2i(0, 200): [0, Vector2i(0, 193)], Vector2i(0, 295): [2, Vector2i(0, 302)], Vector2i(0, 300): [1, Vector2i(0, 293)]}
	_check("segment: passages() == table de l'étape 3", pass_ok, str(SegGenS.passages()))
	_check("segment: node_index (0, 26) -1, (0, 100) 0, (0, 295) 1, (0, 396) -1", SegGenS.node_index(Vector2i(0, 26)) == -1 and SegGenS.node_index(Vector2i(0, 100)) == 0
		and SegGenS.node_index(Vector2i(0, 295)) == 1 and SegGenS.node_index(Vector2i(0, 396)) == -1)
	_check("segment: in_brazier_zone (0, 251) (2, 250) vrais, (0, 252) (3, 250) faux", SegGenS.in_brazier_zone(Vector2i(0, 251)) and SegGenS.in_brazier_zone(Vector2i(2, 250))
		and not SegGenS.in_brazier_zone(Vector2i(0, 252)) and not SegGenS.in_brazier_zone(Vector2i(3, 250)))
	_check("combat: in_safe_zone (0, 32) et (0, 3968) vrais, (0, 3200) faux", CombatS.in_safe_zone(Vector2(0, 32)) and CombatS.in_safe_zone(Vector2(0, 3968)) and not CombatS.in_safe_zone(Vector2(0, 3200)))
	# Expedition
	var rng0: RngS.Pcg32 = RngS.make_rng(1, "loot/eclats/0")
	var draws: Array[float] = []
	var want: Array[float] = [0.697933, 0.510035, 0.840335, 0.677033, 0.077122, 0.299925, 0.98673, 0.081554, 0.246956, 0.506639, 0.763717, 0.567947]
	var draws_ok: bool = true
	for k in 12:
		draws.append(rng0.next_float())
		draws_ok = draws_ok and _approx(draws[k], want[k], 1e-6)
	_check("expédition: 12 premiers tirages de loot/eclats/0, 1er de loot/eclats/1 == 0,177019", draws_ok and _approx(RngS.make_rng(1, "loot/eclats/1").next_float(), 0.177019, 1e-6), str(draws))
	var ex: ExpeditionS = ExpeditionS.new(1, 0, _fresh_ref())
	var n_kills: int = 0
	var mist_closed_at: int = -1
	while ex.normals_open():
		ex.on_kill(0)
		n_kills += 1
		if mist_closed_at < 0 and not ex.mist_open():
			mist_closed_at = n_kills
	_check("expédition: kills seuls -> 40, Cendre 80, 0 Éclat, XP 1 200, nœuds fermés au 37e kill (Cendre 74)",
		n_kills == 40 and ex.cendre == 80 and ex.shards == 0 and ex.xp == 1200 and mist_closed_at == 37, "%d %d %d %d %d" % [n_kills, ex.cendre, ex.shards, ex.xp, mist_closed_at])
	ex = ExpeditionS.new(1, 0, _fresh_ref())
	for k in 8:
		ex.on_gather(0)
	var after8: Array = [ex.cendre, ex.shards, ex.mist_open()]
	for k in 8:
		ex.on_kill(0)
	_check("expédition: 8 nœuds -> Cendre 64, 2 Éclats, nœuds ouverts ; + 8 kills -> Cendre 80, 2 Éclats, XP 744",
		after8 == [64, 2, true] and ex.cendre == 80 and ex.shards == 2 and ex.xp == 744 and not ex.normals_open(), "%s %d %d %d" % [str(after8), ex.cendre, ex.shards, ex.xp])
	ex = ExpeditionS.new(1, 0, _fresh_ref())
	for k in 10:
		ex.on_gather(0)
	_check("expédition: 10 nœuds -> Cendre 80, normaux fermés", ex.cendre == 80 and not ex.normals_open())
	# Récolte, contrôleur seul
	var r1: Array = _gather_alone(Vector2(64, 1792), 200)
	_check("récolte: joueur à 16 px -> GATHERED à la 91e image, signal 1 fois", r1[0] == 91 and r1[1] == 1, str(r1))
	var r2: Array = _gather_alone(Vector2(55, 1792), 200)
	_check("récolte: joueur à 25 px -> toujours AVAILABLE après 200 images", r2[0] == -1 and r2[1] == 0, str(r2))
	# Passages, avec Segment
	var ctx: Array = _seg_ctx(solid1, Vector2(0, 416))
	var pl: Node2D = ctx[0]
	var seg: Node2D = ctx[1]
	var tp: Array[int] = [0]
	var changes: Array = []
	pl.teleported.connect(func() -> void: tp[0] += 1)
	seg.expedition_changed.connect(func(s: bool, c: int, e: int, _kg: float, _cap: float) -> void: changes.append([s, c, e]))
	_seg_frame(pl, seg)
	var fade1: bool = pl.in_fade()
	var still: bool = true
	for f in range(2, 26):
		_seg_frame(pl, seg)
		still = still and pl.position == Vector2(0, 416)
	_check("passage: image 1 détecté (fondu), images 1 à 25 en (0, 416)", fade1 and still, str(pl.position))
	_seg_frame(pl, seg)
	_check("passage: image 26 en (0, 1632), nœud 0 actif, expédition 0, teleported 1 fois, expedition_changed(true, 0, 0)",
		pl.position == Vector2(0, 1632) and seg.active == 0 and seg.expedition != null and tp[0] == 1 and changes == [[true, 0, 0]],
		"%s %d %d %s" % [str(pl.position), seg.active, tp[0], str(changes)])
	var fade_66: bool = false
	for f in range(27, 68):
		_seg_frame(pl, seg)
		if f == 66:
			fade_66 = pl.in_fade()
	_check("passage: fondu fini à l'image 67", fade_66 and not pl.in_fade())
	pl.position = Vector2(0, 1600)
	for f in 26:
		_seg_frame(pl, seg)
	_check("passage nord: 25 images plus tard en (0, 384), nœud -1, fin « retour »", pl.position == Vector2(0, 384) and seg.active == -1 and seg.last_end == "retour" and seg.expedition == null,
		"%s %d %s" % [str(pl.position), seg.active, seg.last_end])
	_seg_free(ctx)
	ctx = _seg_ctx(solid1, Vector2(0, 416))
	pl = ctx[0]
	seg = ctx[1]
	for f in 67: # fondu d'arrivée fini : invulnérable avant
		_seg_frame(pl, seg)
	pl.hp = 5
	pl.take_hit(9)
	for f in 25:
		_seg_frame(pl, seg)
	_check("mort au nœud 0: 25 images plus tard en (0, 32), PV 100, fin « mort », bounds et solid du village",
		pl.position == Vector2(0, 32) and pl.hp == 100 and seg.last_end == "mort" and pl.bounds() == VL.GROUND_RECT and pl._solid == solid1,
		"%s %d %s %s" % [str(pl.position), pl.hp, seg.last_end, str(pl.bounds())])
	_seg_free(ctx)
	# Récolte avec Segment
	ctx = _seg_ctx(solid1, Vector2(0, 416))
	pl = ctx[0]
	seg = ctx[1]
	for f in 67:
		_seg_frame(pl, seg)
	pl.position = Vector2(64, 1792)
	for f in 91:
		_seg_frame(pl, seg)
	var ex1: ExpeditionS = seg.expedition
	_check("récolte avec Segment: Cendre 8, XP 63, 0 Éclat", ex1.cendre == 8 and ex1.xp == 63 and ex1.shards == 0, "%d %d %d" % [ex1.cendre, ex1.xp, ex1.shards])
	_seg_free(ctx)
	# Saturation
	ctx = _seg_ctx(solid1, Vector2(0, 416))
	pl = ctx[0]
	seg = ctx[1]
	for f in 67:
		_seg_frame(pl, seg)
	seg.expedition.cendre = 78
	var awake: Array[int] = [0]
	seg.elite_awakened.connect(func() -> void: awake[0] += 1)
	var node0: Node2D = seg.nodes()[0]
	var target: Node2D = node0.mobs()[0]
	while target.alive:
		node0._strike(target)
	var all_dead: bool = true
	for n: Node2D in seg.nodes():
		for m: Node2D in n.mobs():
			if m.role == "NORMAL":
				all_dead = all_dead and not m.alive and not m.visible
	for f in 1300:
		_seg_frame(pl, seg)
	var none_back: bool = true
	var all_vitrified: bool = true
	for n: Node2D in seg.nodes():
		for m: Node2D in n.mobs():
			if m.role == "NORMAL":
				none_back = none_back and not m.alive
		for mn: Node2D in n.mist_nodes():
			all_vitrified = all_vitrified and mn.state == MistS.State.VITRIFIED
	_check("saturation: un kill à 78 -> Cendre 80, normaux des 3 nœuds morts et invisibles (l'Élite s'éveille), aucune réapparition après 1 300 images, nœuds VITRIFIED",
		seg.expedition.cendre == 80 and all_dead and none_back and all_vitrified, "%d %s %s %s" % [seg.expedition.cendre, str(all_dead), str(none_back), str(all_vitrified)])
	seg._after_gain()
	_check("saturation: elite_awakened émis une seule fois par expédition (toast, jalon 20 ter)", awake[0] == 1, str(awake[0]))
	_seg_free(ctx)
	# Brasero
	var pb: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pb)
	pb.setup(Vector2(0, 3984), null, null, {})
	pb.hp = 40
	pb._process(1.0 / 60.0)
	_check("Brasero: 40 PV en (0, 3984) -> 100 après une image", pb.hp == 100, str(pb.hp))
	pb.free()
	_jalon_12(vd, solid1)
	_jalon_12b(solid1)
	_jalon_13(solid1)
	_jalon_14(solid1)
	_jalon_15(solid1)
	_jalon_15b(solid1)
	_jalon_16(solid1)
	_jalon_16b()
	_jalon_17()
	_jalon_17b()
	_jalon_18()
	_jalon_19()
	_jalon_19b()
	_jalon_20()
	_jalon_20b()
	_mode_debug()
	_jalon_20t()
	_jalon_20q()
	_jalon_21()
	_jalon_22()
	# Scènes et données
	var vil: Node = load("res://scenes/village/village.tscn").instantiate()
	var sg: Node2D = vil.get_node_or_null("Entites/Segment")
	_check("scenes: Entites/Segment (y_sort_enabled), plus d'Entites/Lisiere", sg != null and sg.y_sort_enabled and vil.get_node_or_null("Entites/Lisiere") == null)
	vil.free()
	_check("village.json: sans lisiere, avec segment et la tuile noeud_brume", not vd.has("lisiere") and vd.has("segment") and vd["segment"]["mist_sprite"] == "noeud_brume" and vd["tiles"].has("noeud_brume"))

# Jalon 12 : portées du n°29, aptitudes, Élite, repère de portée. Jumeau Python : prep_jalon_12.py.
func _jalon_12(vd: Dictionary, solid1: Dictionary) -> void:
	var ranges: Array = []
	var others_ok: bool = true
	var keys: Dictionary = {}
	for t: int in BC.WEAPON_SPECS:
		ranges.append(BC.WEAPON_SPECS[t]["range_px"])
		keys[t] = BC.WEAPON_SPECS[t].keys()
	var ref: Dictionary = {BC.WeaponType.SWORD_SHIELD: [false, BC.SchoolId.FOYER, "M" if false else "F"], BC.WeaponType.HUNTING_BOW: [true, BC.SchoolId.SPORE, "M"]}
	for t: int in ref:
		others_ok = others_ok and BC.WEAPON_SPECS[t]["is_ranged"] == ref[t][0] and BC.WEAPON_SPECS[t]["favored_school"] == ref[t][1] and BC.WEAPON_SPECS[t]["gender"] == ref[t][2]
	_check("balanceC: portées du n°29 = 24 / 28 / 36 / 80 / 92, autres champs inchangés", ranges == [24.0, 28.0, 36.0, 80.0, 92.0] and others_ok
		and BC.WEAPON_SPECS[BC.WeaponType.CLEAVER_AXE]["favored_school"] == BC.SchoolId.BRASIER and BC.WEAPON_SPECS[BC.WeaponType.WINCH_CROSSBOW]["is_ranged"] == true, str(ranges))
	for c: Array in [[2.2, false, 45], [2.2, true, 68], [3.5, false, 72], [3.5, true, 108]]:
		var dm: int = CombatS.damage(22, 4, 1, c[1], c[0])
		_check("aptitude: damage(22, 4, 1, %s, %.1f) == %d" % [str(c[1]), c[0], c[2]], dm == c[2], str(dm))
	# Lisière + évacuation (10 bis) : le joueur frappe une fois à l'image 14
	var a1: Dictionary = _skill_run(solid1, 0, 260, true)
	_check("A1: aptitude 1 à l'image 14 (45, monstre à 50), autos 64 / 115 / 166 (30 / 10 / 0), reçus 47 / 107, PV 82, mort à 166, recharge 1,3 à l'image 260, 2e demande ignorée",
		a1["hits"] == [[14, "aptitude", 45, 50], [64, "auto", 20, 30], [115, "auto", 20, 10], [166, "auto", 20, 0]] and a1["received"] == [47, 107] and a1["hp"] == 82
		and a1["death"] == 166 and _approx(a1["cd"], 1.3, 1e-6) and a1["skills"] == 1, str(a1))
	var a2: Dictionary = _skill_run(solid1, 1, 260, false)
	_check("A2: aptitude 2 à l'image 14 (72, monstre à 23), autos 64 / 115, mort à 115, PV du joueur 82",
		a2["hits"] == [[14, "aptitude", 72, 23], [64, "auto", 20, 3], [115, "auto", 20, 0]] and a2["death"] == 115 and a2["hp"] == 82, str(a2))
	var pd: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pd)
	pd.setup(Vector2(0, 216), null, null, solid1)
	pd.request_skill(0)
	var armed: bool = pd.skill_queued(0)
	pd.hp = 5
	pd.take_hit(9)
	_check("aptitude: armée puis oubliée à la mort", armed and not pd.skill_queued(0) and pd.take_ready_skill() == -1)
	pd.free()
	var ex: ExpeditionS = ExpeditionS.new(1, 0, _fresh_ref())
	for k in 40:
		ex.on_kill(0)
	ex.on_elite(0)
	_check("expédition: 40 kills puis l'Élite -> Cendre 100 == SEGMENT_STD_RUN_CENDRE_CAP, 1 Éclat, XP 1 396",
		ex.cendre == 100 and ex.cendre == BA.SEGMENT_STD_RUN_CENDRE_CAP and ex.shards == 1 and ex.xp == 1396, "%d %d %d" % [ex.cendre, ex.shards, ex.xp])
	_check("combat: mob_stats(1, 0, ELITE) == 712 / 16 / 4", CombatS.mob_stats(1, 0, "ELITE") == {"hp": 712, "atk": 16, "def": 4})
	# Élite dans le Segment
	var ctx: Array = _seg_ctx(solid1, Vector2(0, 6240))
	var pl: Node2D = ctx[0]
	var seg: Node2D = ctx[1]
	var node2: Node2D = seg.nodes()[2]
	var el: Node2D = node2.elite()
	_check("Élite: en (0, 6256), 712 PV, dormant, cellule pleine pour le joueur", el != null and el.position == Vector2(0, 6256) and el.hp == 712 and el.dormant
		and seg._player_solids[2].has(SegGenS.elite_cell()), "%s %d" % [str(el.position), el.hp])
	for f in 120:
		_seg_frame(pl, seg)
	_check("Élite: dormant à 16 px pendant 120 images -> ni cible ni poursuivant, PV intacts", seg.active == 2 and el.hp == 712 and not el.chasing and pl.hp == 100 and el.dormant,
		"%d %d %s %d" % [seg.active, el.hp, str(el.chasing), pl.hp])
	seg.expedition.cendre = 78
	var victim: Node2D = node2.mobs()[0]
	while victim.alive:
		node2._strike(victim)
	pl.position = el.position + Vector2(0, -64)
	for f in 5:
		_seg_frame(pl, seg)
	_check("Élite: saturation -> éveillé, cellule libérée, poursuit le joueur à 64 px", not el.dormant and el.chasing and not seg._player_solids[2].has(SegGenS.elite_cell()) and seg.expedition.cendre == 80,
		"%s %s %d" % [str(el.dormant), str(el.chasing), seg.expedition.cendre])
	while el.alive:
		node2._strike(el)
	_check("Élite: son kill -> Cendre 100", seg.expedition.cendre == 100, str(seg.expedition.cendre))
	for n: Node2D in seg.nodes():
		n.reset()
	_check("Élite: après reset, dormant, 712 PV, à son point de départ", el.dormant and el.alive and el.hp == 712 and el.position == Vector2(0, 6256))
	_seg_free(ctx)
	# Repère de portée
	var pr: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pr)
	pr.setup(Vector2(0, 216), null, null, solid1)
	var lr: Node2D = LisiereS.new()
	root.add_child(lr)
	lr.setup(1, 0, pr, solid1, LISIERE_SPAWNS_10, null, null)
	var at0: bool = pr.range_shown()
	for f in 30:
		pr._process(1.0 / 60.0)
		lr._process(1.0 / 60.0)
	var at30: bool = pr.range_shown()
	pr.hp = 5
	pr.take_hit(9)
	pr._process(1.0 / 60.0)
	lr._process(1.0 / 60.0)
	_check("repère: faux au départ, vrai à l'image 30 (poursuite), faux en fondu", not at0 and at30 and not pr.range_shown())
	lr.free()
	pr.free()
	# Boutons d'aptitude : un posé sur un bouton ne démarre pas le joystick
	# Le routage GUI (posé consommé par le bouton, jamais vu par le joystick) n'existe pas sous _initialize : un témoin
	# hors bouton n'y démarre pas non plus le joystick. Il est vérifié dans le jeu réel (sonde PC, L4a).
	var ui: CanvasLayer = load("res://scenes/ui/ui_folded.tscn").instantiate()
	var b1: Button = ui.get_node_or_null("Aptitudes/Aptitude1")
	var b2: Button = ui.get_node_or_null("Aptitudes/Aptitude2")
	_check("scenes: UI_Folded a les 2 boutons d'aptitude (Button, mouse_filter STOP), conteneur Aptitudes en IGNORE",
		b1 != null and b2 != null and b1.mouse_filter == Control.MOUSE_FILTER_STOP and b2.mouse_filter == Control.MOUSE_FILTER_STOP
		and ui.get_node("Aptitudes").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var sb: GDScript = load("res://scripts/ui/skill_buttons.gd")
	_check("scenes: SKILL_BUTTON_SIZE_PX 28, marge 8", sb.get_script_constant_map()["SKILL_BUTTON_SIZE_PX"] == 28 and sb.get_script_constant_map()["MARGIN_PX"] == 8)
	ui.free()

# Jalon 12 bis : Fauchage de Braise de l'Élite (n°31, n°32). Jumeau Python : prep_jalon_12bis.py.
func _jalon_12b(solid1: Dictionary) -> void:
	var melee: float = 0.0
	for t: int in BC.WEAPON_SPECS:
		if not BC.WEAPON_SPECS[t]["is_ranged"]:
			melee = maxf(melee, BC.WEAPON_SPECS[t]["range_px"])
	_check("balanceA: ELITE_ATTACK_TRIGGER_RANGE_PX 36 == plus longue mêlée de BalanceC, ELITE_MELEE_AOE_RADIUS_PX 40 au-delà",
		BA.ELITE_ATTACK_TRIGGER_RANGE_PX == 36.0 and BA.ELITE_MELEE_AOE_RADIUS_PX == 40.0 and BA.ELITE_ATTACK_TRIGGER_RANGE_PX == melee
		and BA.ELITE_MELEE_AOE_RADIUS_PX > BA.ELITE_ATTACK_TRIGGER_RANGE_PX, str(melee))
	_check("combat: mob_trigger_range NORMAL 16 / ELITE 36, mob_hit_range NORMAL 16 / ELITE 40",
		CombatS.mob_trigger_range("NORMAL") == 16.0 and CombatS.mob_trigger_range("ELITE") == 36.0
		and CombatS.mob_hit_range("NORMAL") == 16.0 and CombatS.mob_hit_range("ELITE") == 40.0)
	var e1: Dictionary = _elite_run(solid1, Vector2(0, 216), 600, 0, 0)
	_check("E1: Élite arrêté en (0, 251,3333) à 35,333 px, télégraphes 0,0833 / 1,0833 / 2,1, aucun coup du joueur, reçus 30 / 90 / 151 / 212 / 273 / 334 / 395 / 456 (14 chacun), mort à 456",
		_approx(e1["stop"].x, 0.0, 1e-3) and _approx(e1["stop"].y, 251.3333, 1e-3) and _approx(e1["stop_dist"], 35.333, 1e-3) and e1["moved_after_stop"] == false
		and _near(e1["windups"].slice(0, 3), [0.0833, 1.0833, 2.1]) and e1["strikes"] == []
		and e1["received"] == [30, 90, 151, 212, 273, 334, 395, 456] and e1["player_hp"].slice(0, 7) == [86, 72, 58, 44, 30, 16, 2] and e1["death"] == 456, str(e1))
	var e2: Dictionary = _elite_run(solid1, Vector2(0, 216), 80, 11, 24)
	_check("E2: 1er impact raté (joueur à 53,163 px), 0 coup reçu, PV 100, joueur en (23,0988, 203,4506), 2e télégraphe à 1,0833 (Élite à 35,663 px)",
		e2["misses"].size() >= 1 and _approx(e2["misses"][0], 53.163, 1e-3) and e2["received"] == [] and e2["final_hp"] == 100
		and _approx(e2["player"].x, 23.0988, 1e-3) and _approx(e2["player"].y, 203.4506, 1e-3)
		and e2["windups"].size() >= 2 and _approx(e2["windups"][1], 1.0833, 1e-4) and _approx(e2["windup_dists"][1], 35.663, 1e-3), str(e2))
	var e3: Dictionary = _elite_run(solid1, Vector2(0, 232), 130, 0, 0)
	_check("E3: à 24 px, télégraphes 0,0167 / 1,0167 / 2,0333, frappes 1 / 51 / 102 (692 / 672 / 652), reçus 26 / 86, PV 72",
		_near(e3["windups"], [0.0167, 1.0167, 2.0333]) and e3["strikes"] == [[1, 692], [51, 672], [102, 652]] and e3["received"] == [26, 86] and e3["final_hp"] == 72, str(e3))
	# Repère au sol : disque de l'Élite pendant son télégraphe seulement, jamais sur un normal
	var pr: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pr)
	pr.setup(Vector2(0, 216), null, null, solid1)
	var lr: Node2D = LisiereS.new()
	root.add_child(lr)
	lr.setup(1, 0, pr, solid1, [[0, 20]], null, null)
	var el: Node2D = lr.add_elite(Vector2i(0, 16), null, null)
	lr.wake_elite()
	var normal: Node2D = lr.mobs()[0]
	var during: bool = true
	var outside: bool = true
	var seen: bool = false
	var normal_never: bool = true
	for f in range(1, 61):
		pr._process(1.0 / 60.0)
		lr._process(1.0 / 60.0)
		var windup: bool = el._windup_t >= 0.0
		seen = seen or el.aoe_shown()
		during = during and (el.aoe_shown() if windup else true)
		outside = outside and (true if windup else not el.aoe_shown())
		normal_never = normal_never and not normal.aoe_shown()
	_check("repère: disque de l'Élite tant que dure son télégraphe, absent sinon, jamais sur un normal", seen and during and outside and normal_never)
	lr.free()
	pr.free()

func _near(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not _approx(a[i], b[i], 1e-4):
			return false
	return true

# Lisière (graine 1, isolat 0, sans spawn) + Élite éveillé en (0, 256), joueur en pos, marche (1, -1) des images walk_from à walk_to.
func _elite_run(solid: Dictionary, pos: Vector2, frames: int, walk_from: int, walk_to: int) -> Dictionary:
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(pos, null, null, solid)
	var lis: Node2D = LisiereS.new()
	root.add_child(lis)
	lis.setup(1, 0, pl, solid, [], null, null)
	var el: Node2D = lis.add_elite(Vector2i(0, 16), null, null)
	lis.wake_elite()
	var out: Dictionary = {"windups": [], "windup_dists": [], "strikes": [], "received": [], "player_hp": [], "misses": [], "death": -1,
		"stop": Vector2.ZERO, "stop_dist": -1.0, "moved_after_stop": false}
	var prev_el: int = el.hp
	var prev_pl: int = pl.hp
	var prev_attack: float = -1.0
	var prev_windup: bool = false
	for f in range(1, frames + 1):
		if walk_to > 0 and f == walk_from:
			pl.set_move_dir(Vector2(1, -1).normalized())
		if walk_to > 0 and f == walk_to + 1:
			pl.set_move_dir(Vector2.ZERO)
		pl._process(1.0 / 60.0)
		lis._process(1.0 / 60.0)
		var d: float = el.position.distance_to(pl.position)
		if el._last_attack != prev_attack:
			out["windups"].append(snappedf(el._last_attack, 0.0001))
			out["windup_dists"].append(d)
			if out["stop_dist"] < 0.0:
				out["stop"] = el.position
				out["stop_dist"] = d
		elif out["stop_dist"] >= 0.0 and out["death"] < 0 and el.position != out["stop"]: # avant l'évacuation seulement
			out["moved_after_stop"] = true
		prev_attack = el._last_attack
		var windup: bool = el._windup_t >= 0.0
		if prev_windup and not windup and pl.hp == prev_pl:
			out["misses"].append(d)
		prev_windup = windup
		if el.hp < prev_el:
			out["strikes"].append([f, el.hp])
		prev_el = el.hp
		if pl.hp < prev_pl:
			out["received"].append(f)
			out["player_hp"].append(pl.hp)
			if pl.hp <= 0 and out["death"] < 0:
				out["death"] = f
		prev_pl = pl.hp
	out["final_hp"] = pl.hp
	out["player"] = pl.position
	lis.free()
	pl.free()
	return out

# S1 + request_skill(i) avant l'image 1 (et, si again, une 2e demande à l'image 15).
func _skill_run(solid: Dictionary, skill: int, frames: int, again: bool) -> Dictionary:
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid)
	var lis: Node2D = LisiereS.new()
	root.add_child(lis)
	lis.setup(1, 0, pl, solid, LISIERE_SPAWNS_10, null, null)
	var m0: Node2D = lis.mobs()[0]
	var out: Dictionary = {"hits": [], "received": [], "death": -1, "skills": 0}
	var prev: int = m0.hp
	var prev_pl: int = pl.hp
	pl.request_skill(skill)
	for f in range(1, frames + 1):
		if again and f == 15:
			pl.request_skill(skill)
		var cd_before: float = pl.skill_cd(skill)
		pl._process(1.0 / 60.0)
		lis._process(1.0 / 60.0)
		if m0.hp < prev:
			var fired: bool = pl.skill_cd(skill) > cd_before
			if fired:
				out["skills"] += 1
			out["hits"].append([f, "aptitude" if fired else "auto", prev - m0.hp, maxi(m0.hp, 0)])
		prev = m0.hp
		if out["death"] < 0 and not m0.alive:
			out["death"] = f
		if pl.hp < prev_pl:
			out["received"].append(f)
		prev_pl = pl.hp
	out["hp"] = pl.hp
	out["cd"] = pl.skill_cd(skill)
	lis.free()
	pl.free()
	return out

# Contrôleur seul (graine 1, nœud 0, sans monstre), un nœud de Brume en (5, 112), joueur immobile en pos.
# Rend [image de la récolte (-1 si aucune), nombre de signaux gathered].
func _gather_alone(pos: Vector2, frames: int) -> Array:
	var m0: Dictionary = SegGenS.node_map(1, 0)
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(pos, null, null, {})
	var lis: Node2D = LisiereS.new()
	root.add_child(lis)
	lis.setup(1, 0, pl, SegGenS.solid_cells(m0), [], null, null, SegGenS.node_rect(0))
	var cells: Array[Vector2i] = [Vector2i(5, 112)]
	lis.add_mist_nodes(cells, null, null)
	var count: Array[int] = [0]
	lis.gathered.connect(func(_i: int) -> void: count[0] += 1)
	var at: int = -1
	for f in range(1, frames + 1):
		pl._process(1.0 / 60.0)
		lis._process(1.0 / 60.0)
		if at < 0 and lis.mist_nodes()[0].state == MistS.State.GATHERED:
			at = f
	lis.free()
	pl.free()
	return [at, count[0]]

# Joueur et Segment (graine 1, isolat 0), sans textures.
func _seg_ctx(village_solid: Dictionary, pos: Vector2, player_ref: Callable = Callable()) -> Array:
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(pos, null, null, village_solid)
	var seg: Node2D = SegmentS.new()
	root.add_child(seg)
	seg.setup(1, 0, pl, village_solid, null, null, null, player_ref if player_ref.is_valid() else _fresh_ref())
	return [pl, seg]

# Une image : Joueur, puis Segment, puis le nœud actif.
func _seg_frame(pl: Node2D, seg: Node2D) -> void:
	pl._process(1.0 / 60.0)
	seg._process(1.0 / 60.0)
	var a: Node2D = seg.active_node()
	if a != null:
		a._process(1.0 / 60.0)

func _seg_free(ctx: Array) -> void:
	ctx[1].free()
	ctx[0].free()

# Jalon 10 bis : mort = évacuation (fondu), sans téléportation immédiate.
func _evacuation_10b(solid: Dictionary) -> void:
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid)
	var started: Array[int] = [0]
	pl.evacuation_started.connect(func() -> void: started[0] += 1)
	pl.hp = 5
	var killed: bool = pl.take_hit(9)
	_check("évacuation: take_hit(9) à 5 PV -> vrai, signal 1 fois, is_evacuating, toujours en (0, 216)",
		killed and started[0] == 1 and pl.is_evacuating() and pl.position == Vector2(0, 216), "%s %d %s" % [str(killed), started[0], str(pl.position)])
	_check("évacuation: take_hit faux, can_strike faux, dodge faux", not pl.take_hit(9) and not pl.can_strike() and not pl.dodge(Vector2(1, 0)))
	pl.set_move_dir(Vector2(1, 0))
	for i in 24:
		pl._process(1.0 / 60.0)
	_check("évacuation: 24 images -> toujours (0, 216)", pl.position == Vector2(0, 216), str(pl.position))
	for i in 2:
		pl._process(1.0 / 60.0)
	_check("évacuation: 26 images -> (0, 32), PV 100", pl.position == Vector2(0, 32) and pl.hp == 100, "%s %d" % [str(pl.position), pl.hp])
	for i in 34:
		pl._process(1.0 / 60.0)
	var mid: bool = pl.is_evacuating() and pl.fade_alpha() > 0.0
	for i in 10:
		pl._process(1.0 / 60.0)
	_check("évacuation: 60 images en cours (noir > 0), 70 images finie (noir 0), signal toujours 1 fois",
		mid and not pl.is_evacuating() and pl.fade_alpha() == 0.0 and started[0] == 1, "%s %s %f %d" % [str(mid), str(pl.is_evacuating()), pl.fade_alpha(), started[0]])
	pl.free()

func _jalon_10b(vd: Dictionary, solid1: Dictionary) -> void:
	# BalanceA (n°25)
	_check("balanceA: rythme des monstres (n°25)", BA.MOB_BASE_MSPD == 70.0 and BA.MOB_AGGRO_RANGE_PX == 96.0 and BA.MOB_LEASH_RANGE_PX == 144.0
		and BA.MOB_MELEE_RANGE_PX == 16.0 and BA.MOB_TELEGRAPH_DURATION_SEC == 0.40 and BA.MOB_BASE_ATTACK_SPEED == 1.00
		and BA.MOB_RESPAWN_DELAY_SEC == 20.0 and BA.MOB_CAN_CRIT == false)
	_check("balanceA: UNFOLDED_* (n°25)", BA.UNFOLDED_OUTSIDE_ATRE_TIMESCALE_DEFAULT == 1.00 and BA.UNFOLDED_COMBAT_LOCK_CAMERA_ON_PLAYER == true and BA.UNFOLDED_COMBAT_DISABLE_JOYSTICK == true)
	var ba_map: Dictionary = (load("res://balance/balance_a.gd") as Script).get_script_constant_map()
	_check("balanceA: SegmentNodeType 0 à 4", ba_map["SegmentNodeType"].values() == [0, 1, 2, 3, 4], str(ba_map["SegmentNodeType"]))
	_check("balanceA: arène 3 vagues, 12 normaux, 1 Élite", BA.ARENA_WAVE_COUNT == 3 and BA.ARENA_WAVE_DURATION_SEC == 30.0
		and _sum_ints(BA.ARENA_WAVE_NORMAL_MOBS) == 12 and _sum_ints(BA.ARENA_WAVE_ELITE_MOBS) == 1)
	_check("balanceA: STD_RUN_ROUTINE_A_NORMAL_MOBS absent", not ba_map.has("STD_RUN_ROUTINE_A_NORMAL_MOBS")) # SEGMENT_NODES_COUNT_VERTICAL_SLICE entré au jalon 11 (n°26)
	var cb_map: Dictionary = (load("res://scripts/combat/combat.gd") as Script).get_script_constant_map()
	_check("combat: plus de MOB_MSPD ni MOB_WINDUP_SEC, mob_attack_period == 1,0", not cb_map.has("MOB_MSPD") and not cb_map.has("MOB_WINDUP_SEC") and CombatS.mob_attack_period() == 1.0)
	# Fondu
	for c: Array in [[0.0, 0.0], [0.2, 0.5], [0.4, 1.0], [0.55, 1.0], [0.9, 0.5], [1.1, 0.0], [2.0, 0.0]]:
		_check("fondu: evac_alpha(%.2f) == %.1f" % c, _approx(CombatS.evac_alpha(c[0]), c[1], 1e-6), str(CombatS.evac_alpha(c[0])))
	_check("fondu: evac_duration == 1,1", _approx(CombatS.evac_duration(), 1.1, 1e-9))
	# Caméra
	var MainS: Script = load("res://scripts/main.gd")
	for c: Array in [[true, Vector2(3.4, 5.6), Vector2(3, 6)], [false, Vector2(0, 32), Vector2.ZERO], [false, Vector2(0, 216), Vector2(0, 216)], [false, Vector2(0, 199.9), Vector2.ZERO]]:
		var got: Vector2 = MainS.camera_target(c[0], c[1])
		_check("camera_target(%s, %s) == %s" % [str(c[0]), str(c[1]), str(c[2])], got == c[2], str(got))
	# Lisière + évacuation : le coup de l'image 47 tue, les monstres rentrent
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid1)
	var lis: Node2D = LisiereS.new()
	root.add_child(lis)
	lis.setup(1, 0, pl, solid1, LISIERE_SPAWNS_10, null, null)
	var m0: Node2D = lis.mobs()[0]
	var death_frame: int = -1
	for f in range(1, 168):
		if f == 23:
			pl.hp = 5
		pl._process(1.0 / 60.0)
		lis._process(1.0 / 60.0)
		if death_frame < 0 and pl.is_evacuating():
			death_frame = f
	_check("lisière + évacuation: mort à l'image 47 ; à 167, monstre 0 rentré en (0, 256), 95 PV, sans poursuite ; joueur (0, 32), 100 PV, évacuation finie",
		death_frame == 47 and not m0.chasing and m0.position == Vector2(0, 256) and m0.hp == 95 and pl.position == Vector2(0, 32) and pl.hp == 100 and not pl.is_evacuating(),
		"%d %s %s %d %s %d %s" % [death_frame, str(m0.chasing), str(m0.position), m0.hp, str(pl.position), pl.hp, str(pl.is_evacuating())])
	lis.free()
	pl.free()
	# Scène
	var main_state: SceneState = (load("res://scenes/main.tscn") as PackedScene).get_state()
	var black_ok: bool = false
	for i in main_state.get_node_count():
		if main_state.get_node_name(i) == "Noir" and str(main_state.get_node_path(i)) == "./Fondu/Noir":
			var props: Dictionary = {}
			for k in main_state.get_node_property_count(i):
				props[main_state.get_node_property_name(i, k)] = main_state.get_node_property_value(i, k)
			black_ok = props.get("mouse_filter") == Control.MOUSE_FILTER_IGNORE and props.get("color", Color.WHITE).a == 0.0
	_check("scenes: main.tscn contient Fondu/Noir, mouse_filter IGNORE, alpha 0", black_ok)

func _sum_ints(a: Array[int]) -> int:
	var t: int = 0
	for v: int in a:
		t += v
	return t

# Joueur immobile en (0, 216), graine 1, isolat 0 ; à chaque image joueur._process puis lisiere._process.
# teleport > 0 : joueur.position = (0, 32) avant l'image teleport.
func _s1(vd: Dictionary, solid: Dictionary, dt: float, frames: int, teleport: int) -> Dictionary:
	var pl: Node2D = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(pl)
	pl.setup(Vector2(0, 216), null, null, solid)
	var lis: Node2D = LisiereS.new()
	root.add_child(lis)
	lis.setup(1, 0, pl, solid, LISIERE_SPAWNS_10, null, null)
	var mobs: Array[Node2D] = lis.mobs()
	var out: Dictionary = {"strikes": [], "mob_hp": [], "crits": 0, "mob_death": -1, "windups": [], "received": [], "player_hp": [], "chased12": false, "hp_261": -1, "respawn": -1}
	var prev_mob: int = mobs[0].hp
	var prev_pl: int = pl.hp
	var was_alive: bool = true
	var prev_attack: float = -1.0
	for f in range(1, frames + 1):
		if f == teleport:
			pl.position = Vector2(0, 32)
		pl._process(dt)
		lis._process(dt)
		var m0: Node2D = mobs[0]
		if m0.hp < prev_mob:
			out["strikes"].append(f)
			out["mob_hp"].append(m0.hp)
			if prev_mob - m0.hp != 20:
				out["crits"] += 1
		prev_mob = m0.hp
		if was_alive and not m0.alive:
			out["mob_death"] = f
		if not was_alive and m0.alive:
			out["respawn"] = f
		was_alive = m0.alive
		if m0._last_attack != prev_attack: # début de télégraphe (relevé aussi quand le monstre meurt dans la même image)
			out["windups"].append(snappedf(m0._last_attack, 0.0001))
		prev_attack = m0._last_attack
		if pl.hp < prev_pl:
			out["received"].append(f)
			out["player_hp"].append(pl.hp)
		prev_pl = pl.hp
		out["chased12"] = out["chased12"] or mobs[1].chasing or mobs[2].chasing
		if f == teleport:
			out["hp_261"] = pl.hp
	out["final_hp"] = pl.hp
	out["alive"] = mobs.map(func(m: Node2D) -> bool: return m.alive)
	out["hp"] = mobs.map(func(m: Node2D) -> int: return m.hp)
	out["pos"] = mobs.map(func(m: Node2D) -> Vector2: return m.position)
	lis.free()
	pl.free()
	return out

func _touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e: InputEventScreenTouch = InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	return e

func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var e: InputEventScreenDrag = InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	return e

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
	var S: Dictionary = {"format": 1, "seq": 1, "world_seed": RngS.fnv1a64("archipel"), "village": _village(t10), "player": ProgressionS.new_player()} # player : jalon 13
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
	var l6: Array = _row_texts(VeilleeReportS.rows(rep6, false))
	_check("rapport: +6 h deplie", l6 == ["Absence : 6 h 00", "Or : +11", "Fiches de rupture : 2"], str(l6))
	_check("rapport: +6 h plie", _row_texts(VeilleeReportS.rows(rep6, true)) == ["Absence : 6 h 00", "Or : +11"], str(_row_texts(VeilleeReportS.rows(rep6, true))))
	var rep24: Dictionary = Dag.resume(V, t10 + 86400)
	rep24["gold_delta"] = rep24["village"]["player_gold"] - V["player_gold"]
	rep24["strikes"] = 0
	var l24: Array = _row_texts(VeilleeReportS.rows(rep24, false))
	_check("rapport: +24 h deplie (tag plafond)", l24 == ["Absence : 12 h 00", "Or : +13", "Frais fixes du jour : 24 Or", "Fiches de rupture : 3"]
		and VeilleeReportS.rows(rep24, false)[0]["tag"] == "plafond", str(l24))
	_check("rapport: +24 h plie", _row_texts(VeilleeReportS.rows(rep24, true)) == ["Absence : 12 h 00", "Or : +13"], str(_row_texts(VeilleeReportS.rows(rep24, true))))
	_check("rapport: nouvelle partie", _row_texts(VeilleeReportS.rows({"new_game": true}, true)) == ["Nouvelle partie : Clair-Foyer"]
		and _row_texts(VeilleeReportS.rows({"new_game": true}, false)) == ["Nouvelle partie : Clair-Foyer"])
	var syn: Dictionary = {"new_game": false, "t_eff": 2.5, "ticked": true, "fixed_cost_paid": 0, "tools_replaced": 2, "fiches": ["MAT"], "gold_delta": -3, "strikes": 1}
	var lsyn: Array = _row_texts(VeilleeReportS.rows(syn, false))
	_check("rapport: synthetique", lsyn == ["Absence : 2 h 30", "Or : -3", "Frais fixes du jour : 0 Or", "Outils remplacés : 2", "PNJ en grève : 1", "Fiches de rupture : 1"], str(lsyn))
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
	_check("scenes: bouton Credits dans ui_unfolded seulement", uu.get_node_or_null(UiS.PAGES + "Options/CreditsButton") is Button and uf.find_child("CreditsButton", true, false) == null)
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
	_jalon_9(vd8, built8, p8)
	_jalon_10(vd8, built8, p8)
	# Jalon 12 ter : icône du projet
	var icons: Dictionary = {"icon": 192, "icon_foreground": 432, "icon_background": 432}
	var imgs: Dictionary = {}
	for k: String in icons:
		var tex: Texture2D = load("res://assets/icon/%s.png" % k)
		imgs[k] = tex.get_image() if tex != null else null
		_check("icône: %s.png se charge, %d × %d" % [k, icons[k], icons[k]], imgs[k] != null and imgs[k].get_size() == Vector2i(icons[k], icons[k]))
	_check("icône: application/config/icon == res://assets/icon/icon.png", ProjectSettings.get_setting("application/config/icon") == "res://assets/icon/icon.png")
	_check("icône: icon.png (0, 0) == Color8(34, 30, 30), icon_foreground.png (0, 0) transparent",
		imgs["icon"] != null and imgs["icon"].get_pixel(0, 0).to_rgba32() == Color8(34, 30, 30).to_rgba32()
		and imgs["icon_foreground"] != null and imgs["icon_foreground"].get_pixel(0, 0).a == 0.0)
	# Garde-fou
	var ba_script: Script = load("res://balance/balance_a.gd") # BA.get_script_constant_map() est refusé par le parseur (appel non statique sur une classe)
	_check("garde-fou: BalanceA sans WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS", not ba_script.get_script_constant_map().has("WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS"))
	print("--- %s (%d echec(s))" %["TOUS PASS" if _fails == 0 else "ECHEC", _fails])
	quit(1 if _fails > 0 else 0)
