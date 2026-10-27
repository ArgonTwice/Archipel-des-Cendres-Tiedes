extends RefCounted
# Pièces d'équipement (Volet F §1 à §4) : tirage déterministe d'un Éclat purifié ou d'un craft de Forge (jalon 16),
# partage du budget B, stats portées.
# Pièce = {"slot": int (BalanceF.EquipmentSlot), "rarity": int (0..2), "ilvl": int, "schools": Array (3 SchoolId pour
# l'arme, vide pour une armure), "affixes": Array de {"id": String, "units": float}, "superior": bool (craft seulement)}.
# L'arme est une Épée & Écu. Statiques pures.

const BA = preload("res://balance/balance_a.gd")
const BC = preload("res://balance/balance_c.gd")
const BF = preload("res://balance/balance_f.gd")
const RngS = preload("res://autoload/Rng.gd")

const SLOTS: int = 4
const MAX_ILVL: int = 12

static func starter_weapon() -> Dictionary:
	return {"slot": BF.EquipmentSlot.WEAPON, "rarity": BF.STARTER_WEAPON_RARITY_INDEX, "ilvl": BF.STARTER_WEAPON_ILVL,
		"schools": [BF.STARTER_WEAPON_SCHOOL, BF.STARTER_WEAPON_SCHOOL, BF.STARTER_WEAPON_SCHOOL], "affixes": []}

static func new_equipment() -> Array:
	return [starter_weapon(), null, null, null]

# r tiré dans [0, somme − 1], puis parcours dans l'ordre.
static func weighted_index(rng: RefCounted, weights: Array) -> int:
	var total: int = 0
	for w: int in weights:
		total += w
	var r: int = rng.range_int(0, total - 1)
	for i in weights.size():
		if r < weights[i]:
			return i
		r -= weights[i]
	return weights.size() - 1

# Ordre de déclaration des clés.
static func weighted_key(rng: RefCounted, pool: Dictionary) -> Variant:
	return pool.keys()[weighted_index(rng, pool.values())]

static func affix_count(rarity: int) -> int:
	return BA.RARITY_AFFIX_COUNT[BC.RARITY_KEYS[rarity]]

static func roll(world_seed: int, n: int, elite: bool, ilvl: int) -> Dictionary:
	var rng: RefCounted = RngS.make_rng(world_seed, "loot/purif/%d" % n)
	var slot: int = weighted_index(rng, BF.SLOT_DROP_WEIGHTS)
	var rarity: int = weighted_index(rng, BF.SHARD_ELITE_RARITY_WEIGHTS if elite else BF.SHARD_NORMAL_RARITY_WEIGHTS)
	return build_piece(rng, slot, rarity, ilvl)

# Forge du village (Volet F §2) : tirages rareté (avec Cendre seulement), Supérieure (idem), puis build_piece.
# Supérieure sans plafond d'ilvl (n°35 : ilvl 12 au plus en tranche).
static func craft(world_seed: int, n: int, slot: int, forgeron_level: int, cendre: bool, isolat: int) -> Dictionary:
	var rng: RefCounted = RngS.make_rng(world_seed, "loot/forge/%d" % n)
	var r: Vector2i = BA.ISOLAT_LEVEL_RANGES[isolat]
	var lf: int = clampi(forgeron_level, r.x, r.y)
	var rarity: int = weighted_index(rng, BF.get_craft_with_cendre_rarity_weights(lf)) if cendre else 0
	var superior: bool = cendre and rng.next_float() < BA.SUPERIOR_CHANCE_BASE
	var piece: Dictionary = build_piece(rng, slot, rarity, lf + (BA.SUPERIOR_QUALITY_ILVL_BONUS if superior else 0))
	piece["superior"] = superior
	return piece

# Tirages c à e (jalon 15) : Écoles de l'arme, affixes, parts du budget.
static func build_piece(rng: RefCounted, slot: int, rarity: int, ilvl: int) -> Dictionary:
	var schools: Array = []
	if slot == BF.EquipmentSlot.WEAPON:
		var blade: int = weighted_key(rng, BC.VERTICAL_SLICE_DROP_WEIGHTS)
		var other: int = BC.VERTICAL_SLICE_SCHOOLS[1] if blade == BC.VERTICAL_SLICE_SCHOOLS[0] else BC.VERTICAL_SLICE_SCHOOLS[0]
		schools = [blade]
		for part in 2: # Garde, puis Pommeau
			schools.append(blade if rng.next_float() < BC.DROP_PART_SAME_SCHOOL_PROB else other)
	var k_count: int = affix_count(rarity)
	var ids: Array[String] = []
	for k in k_count:
		var source: Dictionary = BC.SCHOOL_COMBAT_AFFIX_WEIGHTS[schools[BC.AFFIX_SLOT_TO_PART_MAP[k]]] if slot == BF.EquipmentSlot.WEAPON \
			else BC.ARMOR_COMBAT_AFFIX_WEIGHTS
		var pool: Dictionary = {}
		for id: String in source:
			if not ids.has(id) and (k_count != 1 or BF.COMMON_ALLOWED_AFFIXES.has(id)):
				pool[id] = source[id]
		ids.append(weighted_key(rng, pool))
	var draws: Array[float] = []
	for d in {1: 0, 2: 1, 3: 3}[k_count]:
		draws.append(rng.next_float())
	var units: Array[float] = units_of(ids, shares(k_count, draws), ilvl, rarity)
	var affixes: Array = []
	for k in k_count:
		affixes.append({"id": ids[k], "units": units[k]})
	return {"slot": slot, "rarity": rarity, "ilvl": ilvl, "schools": schools, "affixes": affixes}

static func shares(k_count: int, draws: Array[float]) -> Array[float]:
	var smax: Dictionary = BC.MAX_AFFIX_BUDGET_SHARE_BY_COUNT
	var smin: float = BF.AFFIX_MIN_BUDGET_SHARE
	if k_count == 1:
		return [1.0]
	if k_count == 2:
		var s0: float = (1.0 - smax[2]) + (2.0 * smax[2] - 1.0) * draws[0]
		return [s0, 1.0 - s0]
	var t: float = draws[0] + draws[1] + draws[2]
	if t == 0.0:
		return [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0]
	var s: Array[float] = []
	for w: float in draws:
		s.append(smin + (1.0 - 3.0 * smin) * w / t)
	var m: int = 0
	for i in range(1, 3):
		if s[i] > s[m]:
			m = i
	if s[m] > smax[3]:
		var e: float = s[m] - smax[3]
		s[m] = smax[3]
		for i in 3:
			if i != m:
				s[i] += e / 2.0
	return s

# Reliquat de budget reporté sur le premier affixe sous son plafond (K ≥ 2), le reste est perdu.
static func units_of(ids: Array[String], piece_shares: Array[float], ilvl: int, rarity: int) -> Array[float]:
	var budget: float = BC.get_piece_budget(ilvl, rarity)
	var units: Array[float] = []
	var costs: Array[float] = []
	var rest: float = 0.0
	for k in ids.size():
		var bk: float = piece_shares[k] * budget
		var c: float = BC.get_affix_point_cost(ids[k], 1.0, ilvl)
		var u: float = minf(bk / c, BC.AFFIX_DEFS[ids[k]]["cap_per_piece_units"])
		units.append(u)
		costs.append(c)
		rest += bk - u * c
	if ids.size() >= 2 and rest > 0.0:
		for k in ids.size():
			var cap: float = BC.AFFIX_DEFS[ids[k]]["cap_per_piece_units"]
			if units[k] < cap:
				units[k] = minf(units[k] + rest / costs[k], cap)
				break
	return units

# bytes_to_var rend des Array non typés : compute_weapon_atk veut un Array[int].
static func weapon_atk(weapon: Dictionary) -> float:
	var schools: Array[int] = []
	for s: int in weapon["schools"]:
		schools.append(s)
	return BC.compute_weapon_atk(weapon["ilvl"], weapon["rarity"], schools)

static func player_stats(level: int, equipment: Array) -> Dictionary:
	var u: Dictionary = {}
	for piece: Variant in equipment:
		if piece == null:
			continue
		for a: Dictionary in piece["affixes"]:
			u[a["id"]] = u.get(a["id"], 0.0) + a["units"]
	var v: Callable = func(id: String) -> float:
		return BC.AFFIX_DEFS[id]["unit_value"] * minf(u.get(id, 0.0), BC.AFFIX_DEFS[id]["cap_global_units"])
	return {"hp": floori(BA.PLAYER_BASE_HP + BA.PLAYER_HP_PER_LVL * (level - 1) + floorf(v.call("FLAT_HP"))),
		"atk": floori(BA.PLAYER_BASE_ATK + BA.PLAYER_ATK_PER_LVL * (level - 1) + weapon_atk(equipment[0]) * (1.0 + v.call("PCT_ATK")) + v.call("FLAT_ATK")),
		"def": floori(BA.PLAYER_BASE_DEF + BA.PLAYER_DEF_PER_LVL * (level - 1) + v.call("FLAT_DEF")),
		"period": 1.0 / (BA.WEAPON_BASE_ATTACK_SPEED_MELEE * (1.0 + v.call("PCT_ASPD"))),
		"crit_rate": minf(BA.PLAYER_BASE_CRIT_RATE + v.call("PCT_CRIT_CHANCE"), BA.PLAYER_MAX_CRIT_RATE),
		"crit_mult": BA.PLAYER_BASE_CRIT_DMG + v.call("PCT_CRIT_DMG")}

# Validation d'une pièce chargée (SaveManager) : case slot, champs typés, affixes de combat distincts sous plafond.
static func is_valid_piece(p: Variant, slot: int) -> bool:
	if typeof(p) != TYPE_DICTIONARY or not p.has_all(["slot", "rarity", "ilvl", "schools", "affixes"]):
		return false
	if typeof(p["slot"]) != TYPE_INT or p["slot"] != slot or typeof(p["rarity"]) != TYPE_INT or p["rarity"] < 0 or p["rarity"] > BC.VERTICAL_SLICE_MAX_RARITY_INDEX:
		return false
	if typeof(p["ilvl"]) != TYPE_INT or p["ilvl"] < 1 or p["ilvl"] > MAX_ILVL or typeof(p["schools"]) != TYPE_ARRAY or typeof(p["affixes"]) != TYPE_ARRAY:
		return false
	if p.has("superior") and typeof(p["superior"]) != TYPE_BOOL:
		return false
	if slot == BF.EquipmentSlot.WEAPON:
		if p["schools"].size() != 3:
			return false
		for s: Variant in p["schools"]:
			if typeof(s) != TYPE_INT or not BC.VERTICAL_SLICE_SCHOOLS.has(s):
				return false
	elif not p["schools"].is_empty():
		return false
	if p["affixes"].size() > affix_count(p["rarity"]):
		return false
	var seen: Array = []
	for a: Variant in p["affixes"]:
		if typeof(a) != TYPE_DICTIONARY or typeof(a.get("id")) != TYPE_STRING or typeof(a.get("units")) != TYPE_FLOAT:
			return false
		if not BC.ARMOR_COMBAT_AFFIX_WEIGHTS.has(a["id"]) or seen.has(a["id"]):
			return false
		if a["units"] <= 0.0 or a["units"] > BC.AFFIX_DEFS[a["id"]]["cap_per_piece_units"]:
			return false
		seen.append(a["id"])
	return true

static func is_valid_equipment(eq: Variant) -> bool:
	if typeof(eq) != TYPE_ARRAY or eq.size() != SLOTS or eq[0] == null:
		return false
	for i in SLOTS:
		if eq[i] != null and not is_valid_piece(eq[i], i):
			return false
	return true
