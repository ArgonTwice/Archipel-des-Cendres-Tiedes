class_name NewGame
extends RefCounted
# Nouvelle partie (Volet B §1, §3, §4 ; Volet D §2, §3) : village de départ au format de OfflineDag.resume.
# Fonctions statiques pures, déterministes depuis world_seed : un RNG par PNJ, make_rng(world_seed, "npc/%d").
# Les autoloads ne sont pas chargés sous --script : Rng, Clock et OfflineDag sont préchargés.

const BB = preload("res://balance/balance_b.gd")
const BD = preload("res://balance/balance_d.gd")
const RngS = preload("res://autoload/Rng.gd")
const ClockS = preload("res://autoload/Clock.gd")
const Dag = preload("res://scripts/offline_dag.gd")

# [post, manages], dans l'ordre des repas et des remplacements d'outils.
const START_POSTS: Array = [["EXTRACTION", "MAT"], ["TAVERN", "TAVERN"], ["FORGE", "FORGE"], ["GUARD", ""], ["GUARD", ""]]

static func weighted_pick(rng: RngS.Pcg32, weights: Dictionary) -> int:
	var keys: Array = weights.keys()
	keys.sort()
	var total: int = 0
	for k: int in keys:
		total += weights[k]
	var r: int = rng.range_int(0, total - 1)
	for k: int in keys:
		if r < weights[k]:
			return k
		r -= weights[k]
	return keys[-1] # inatteignable : r < total

# [t1] ou [t1, t2] ; t1 est le trait principal (Griffe).
static func draw_traits(rng: RngS.Pcg32) -> Array[int]:
	var n: int = weighted_pick(rng, BD.TRAIT_COUNT_WEIGHTS)
	var t1: int = weighted_pick(rng, BD.TRAIT_DRAW_WEIGHTS)
	var out: Array[int] = [t1]
	if n == 2:
		var rest: Dictionary = BD.TRAIT_DRAW_WEIGHTS.duplicate()
		rest.erase(t1)
		for t: int in BD.TRAIT_INCOMPATIBILITIES[t1]:
			rest.erase(t)
		out.append(weighted_pick(rng, rest))
	return out

static func village(world_seed: int, now_utc: int, tz_offset_sec: int) -> Dictionary:
	var npcs: Array = []
	var griffe: Dictionary = {}
	for i in START_POSTS.size():
		var traits: Array[int] = draw_traits(RngS.make_rng(world_seed, "npc/%d" % i))
		var manages: String = START_POSTS[i][1]
		if manages != "":
			griffe[manages] = traits[0]
		npcs.append({"post": START_POSTS[i][0], "stars": BB.STARTING_NPC_MAIN_APTITUDE_STARS, "cadence": "NORMAL", "moral": int(BB.MORAL_EQUILIBRIUM_TARGET),
			"on_strike": false, "tool_broken": false, "tool_durability": BB.TOOL_DURABILITY_MAX, "traits": traits, "house_lvl": 1, "manages": manages})
	var shops: Dictionary = {}
	for key: String in Dag.SHOP_BUDGET_KEY:
		shops[key] = {"stock": 0, "lvl": 1, "posture": "EQUILIBRE", "griffe_trait": griffe[key],
			"pot": roundi(BB.DAILY_CLIENT_BUDGET_BASE_GOLD[Dag.SHOP_BUDGET_KEY[key]] * BB.ISOLAT_GOLD_MULTIPLIERS[0]), "treasury": BB.SHOP_INITIAL_TREASURY_GOLD}
	return {"last_save_utc": now_utc, "tz_offset_sec": tz_offset_sec, "last_tick_day": ClockS.day_index(now_utc, tz_offset_sec), "isolat": 0,
		"player_gold": BB.PLAYER_STARTING_GOLD, "shops": shops, "npcs": npcs}

# Décalage du fuseau système en secondes, positif à l'est d'UTC, heure d'été comprise ("bias" en minutes).
static func system_tz_offset_sec() -> int:
	return int(Time.get_time_zone_from_system()["bias"]) * 60
