extends RefCounted
# Mode debug (build debug seulement) : actions de test sur un state passé en argument. Statiques pures.
# Chaque action rend {"action", "avant", "apres"} pour le log [DEBUG], ou {} si elle ne change rien ; l'appelant écrit
# ensuite par le chemin normal (main.gd._sync). Aucune valeur de jeu ici : les plafonds sont lus dans BalanceA / BalanceB.

const BA = preload("res://balance/balance_a.gd")
const BB = preload("res://balance/balance_b.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const ForgeS = preload("res://scripts/loot/forge.gd")
const Eco = preload("res://scripts/economy.gd")
const NewGameS = preload("res://scripts/new_game.gd")
const AssignS = preload("res://scripts/village/assignment.gd")

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

# Tous les chantiers en cours (Âtre, jalon 21 ; boutiques, jalon 22) : fin = maintenant, puis chemin normal (finish_if_due
# dans main._process). Entrée : liste des bâtiments.
static func finish_chantier(state: Dictionary, now_utc: int) -> Dictionary:
	var v: Dictionary = state["village"]
	var done: Array[String] = []
	if v.has("atre_chantier_end"):
		v["atre_chantier_end"] = now_utc
		done.append("ATRE")
	for key: String in v["shops"]:
		if v["shops"][key].has("chantier_end"):
			v["shops"][key]["chantier_end"] = now_utc
			done.append(key)
	if done.is_empty():
		return {}
	return entry("fin_chantier", done, now_utc)

# Remises à zéro (après Z16, une par section, choix d'Antho). Dictionnaires modifiés en place (références partagées).
# Joueur : XP 0, arme de départ, Sacoche, coffre, Cendre (ProgressionS.new_player).
static func reset_player(state: Dictionary) -> Dictionary:
	var p: Dictionary = state["player"]
	var before: Dictionary = p["voc_xp"].duplicate()
	p.clear()
	p.merge(ProgressionS.new_player())
	return entry("zero_joueur", before, p["voc_xp"].duplicate())

# Ressources : Or du joueur et stock de la boutique Matériaux à 0.
static func reset_resources(state: Dictionary) -> Dictionary:
	var v: Dictionary = state["village"]
	var before: Array = [v["player_gold"], v["shops"]["MAT"]["stock"]]
	v["player_gold"] = 0
	v["shops"]["MAT"]["stock"] = 0
	return entry("zero_ressources", before, [0, 0])

# Bâtiments : Grand Âtre et boutiques au niveau 1, chantiers annulés.
static func reset_buildings(state: Dictionary) -> Dictionary:
	var v: Dictionary = state["village"]
	var before: Array = [v.get("atre_lvl", 1)] + v["shops"].values().map(func(s: Dictionary) -> int: return s["lvl"])
	v.erase("atre_lvl")
	v.erase("atre_chantier_end")
	for shop: Dictionary in v["shops"].values():
		shop["lvl"] = 1
		shop.erase("chantier_end")
	return entry("zero_batiments", before, [1, 1, 1, 1])

# PNJ : ceux d'une partie neuve de la même graine (poste, étoiles, Moral, outils, verrous effacés). Heure et graine gardées.
static func reset_npcs(state: Dictionary) -> Dictionary:
	var v: Dictionary = state["village"]
	var fresh: Array = NewGameS.village(state["world_seed"], v["last_save_utc"], v["tz_offset_sec"])["npcs"]
	for i in v["npcs"].size():
		v["npcs"][i].clear()
		v["npcs"][i].merge(fresh[i])
	return entry("zero_pnj", v["npcs"].size(), fresh.size())

# Postes au-delà des places du niveau de l'Âtre (Âtre redescendu) : le PNJ de plus grand index part demain vers le premier
# poste libre (Assignment.move, verrou rendu tel quel). -> liste des PNJ déplacés.
static func fit_posts(state: Dictionary) -> Dictionary:
	var v: Dictionary = state["village"]
	var lvl: int = v.get("atre_lvl", 1)
	var moved: Array = []
	for i in range(v["npcs"].size() - 1, -1, -1):
		var post: String = AssignS.effective_post(v["npcs"][i])
		var occ: Dictionary = AssignS.occupancy(v)
		if occ[post] <= AssignS.slots(lvl, post):
			continue
		for to: String in AssignS.active_posts():
			if occ[to] < AssignS.slots(lvl, to):
				var locked: bool = v["npcs"][i].get("locked", false)
				AssignS.move(v, state["world_seed"], i, to, lvl)
				if not locked:
					v["npcs"][i].erase("locked")
				moved.append([i, post, to])
				break
	if moved.is_empty():
		return {}
	return entry("postes", moved, AssignS.occupancy(v))

# Stock de la boutique Matériaux au maximum (Griffe comprise).
static func materials_max(state: Dictionary) -> Dictionary:
	var shop: Dictionary = state["village"]["shops"]["MAT"]
	var before: int = shop["stock"]
	shop["stock"] = Eco.stock_max(true, shop["lvl"], shop["griffe_trait"])
	return entry("materiaux_max", before, shop["stock"])

# En mémoire seulement : l'appelant relance la saturation par segment.gd._after_gain.
static func saturate(expedition: RefCounted) -> Dictionary:
	var before: int = expedition.cendre
	expedition.cendre = maxi(before, BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET)
	return entry("saturation", before, expedition.cendre)
