extends RefCounted
# Mode debug (build debug seulement) : actions de test sur un state passé en argument. Statiques pures.
# Chaque action rend {"action", "avant", "apres"} pour le log [DEBUG], ou {} si elle ne change rien ; l'appelant écrit
# ensuite par le chemin normal (main.gd._sync). Aucune valeur de jeu ici : les plafonds sont lus dans BalanceA / BalanceB.

const BA = preload("res://balance/balance_a.gd")
const BB = preload("res://balance/balance_b.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const ForgeS = preload("res://scripts/loot/forge.gd")

const DEBUG_ORE: int = 20 # outil de test, pas une valeur de jeu (5 crafts)
const DEBUG_GOLD: int = 100 # outil de test, pas une valeur de jeu

static func entry(action: String, before: Variant, after: Variant) -> Dictionary:
	return {"action": action, "avant": before, "apres": after}

# Le tick du jour est rejoué au prochain sync (Dag.resume : au plus 1 tick, last_tick_day remis à aujourd'hui).
static func tick_day(state: Dictionary) -> Dictionary:
	var v: Dictionary = state["village"]
	v["last_tick_day"] -= 1
	return entry("tick_du_jour", v["last_tick_day"] + 1, v["last_tick_day"])

# Ancre reculée du plafond du hors-ligne : le prochain sync compte OFFLINE_MAX_HOURS (borné par Clock.offline_hours).
static func absence(state: Dictionary) -> Dictionary:
	var v: Dictionary = state["village"]
	var before: int = v["last_save_utc"]
	v["last_save_utc"] -= int(BB.OFFLINE_MAX_HOURS * 3600.0)
	return entry("absence", before, v["last_save_utc"])

static func cendre_max(state: Dictionary) -> Dictionary:
	var p: Dictionary = state["player"]
	var before: int = p["cendre"]
	p["cendre"] = BA.LANTERN_CENDRE_CAP[0]
	return entry("cendre_max", before, p["cendre"])

static func bag_full(player: Dictionary) -> bool:
	return player["shard_bag"].size() >= BA.LANTERN_SHARD_BAG_CAP[0]

# Même ilvl qu'un Éclat gagné au prochain départ (segment.gd._begin).
static func add_shard(state: Dictionary, elite: bool) -> Dictionary:
	var p: Dictionary = state["player"]
	if bag_full(p):
		return {}
	var ilvl: int = BA.get_segment_mob_level(state["village"]["isolat"], ProgressionS.combat_level(p), p.get("elite_kills", 0))
	p["shard_bag"].append({"elite": elite, "ilvl": ilvl})
	return entry("eclat_elite" if elite else "eclat", p["shard_bag"].size() - 1, p["shard_bag"].size())

static func add_ore(state: Dictionary) -> Dictionary:
	var p: Dictionary = state["player"]
	var before: int = ForgeS.ore(p)
	p["chest"][ForgeS.ORE] = before + DEBUG_ORE
	return entry("minerai", before, ForgeS.ore(p))

static func add_gold(state: Dictionary) -> Dictionary:
	var v: Dictionary = state["village"]
	v["player_gold"] += DEBUG_GOLD
	return entry("or", v["player_gold"] - DEBUG_GOLD, v["player_gold"])

# XP cumulée au seuil du niveau suivant ; rien au niveau maximal.
static func level_up(state: Dictionary, voc: String) -> Dictionary:
	var xp: Dictionary = state["player"]["voc_xp"]
	var level: int = ProgressionS.level_of(xp[voc])
	if level >= BA.MAX_VOCATION_LEVEL:
		return {}
	xp[voc] = BA.get_cumulative_xp(level + 1)
	return entry("niveau_" + voc.to_lower(), level, level + 1)

# En mémoire seulement : l'appelant relance la saturation par segment.gd._after_gain.
static func saturate(expedition: RefCounted) -> Dictionary:
	var before: int = expedition.cendre
	expedition.cendre = maxi(before, BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET)
	return entry("saturation", before, expedition.cendre)
