extends RefCounted
# Textes des onglets PNJ et Village (jalon 18) : nombres lus dans BalanceB / BalanceD ou calculés par Economy et VillageLayout.
# names : data/village/npcs.json (réservoir de noms par jeton de genre "M" / "F", libellés), chargé une fois par load_names ;
# names["npcs"] (nom et genre par index de PNJ) est posé par with_identities. Statiques pures.

const BB = preload("res://balance/balance_b.gd")
const BD = preload("res://balance/balance_d.gd")
const Eco = preload("res://scripts/economy.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const Dag = preload("res://scripts/offline_dag.gd")
const RngS = preload("res://autoload/Rng.gd")

const NAMES_PATH: String = "res://data/village/npcs.json"
const ACTIVITY: Dictionary = {"WORK": "au travail", "MEAL": "au repas", "VEILLEE": "à la veillée", "STRIKE": "se réchauffe à l'Âtre"}

static func load_names() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(NAMES_PATH))

# Noms procéduraux (Z7, jalon 18) : un RNG par PNJ (« npc/name/i », jamais « npc/i » : les traits des sauvegardes ne bougent pas).
# Genre imposé par le sprite (names["sprite_genders"]), libre sinon ; aucun nom en double dans le village. Rien n'est sauvegardé.
static func npc_identities(world_seed: int, names: Dictionary, sprites: Array) -> Array:
	var out: Array = []
	var taken: Dictionary = {}
	for i in sprites.size():
		var g: String = names["sprite_genders"].get(sprites[i], "")
		var pool: Array = []
		for pg: String in (["M", "F"] if g == "" else [g]):
			for n: String in names["name_pool"][pg]:
				if not taken.has(n):
					pool.append({"name": n, "g": pg})
		var who: Dictionary = pool[RngS.make_rng(world_seed, "npc/name/%d" % i).range_int(0, pool.size() - 1)]
		taken[who["name"]] = true
		out.append(who)
	return out

static func with_identities(names: Dictionary, world_seed: int, sprites: Array) -> Dictionary:
	var d: Dictionary = names.duplicate()
	d["npcs"] = npc_identities(world_seed, names, sprites)
	return d

static func dec2(x: float) -> String:
	return ("%.2f" % x).replace(".", ",")

static func _gendered(pair: Array, g: String) -> String:
	return pair[0] if g == "M" else pair[1]

static func _manager(g: String) -> String:
	return "gérant" if g == "M" else "gérante"

# « Charpente Renforcée (stock max ×1,15) » : enseigne de la Griffe (Volet D §3) et son effet.
static func griffe_text(trait_id: int, names: Dictionary) -> String:
	var key: String = BD.TraitId.find_key(trait_id)
	var effect: String
	match trait_id:
		BD.TraitId.NOCTAMBULE:
			effect = "24 h/24, +%d Lien par fiche" % BD.GRIFFE_NOCTAMBULE_FICHE_BOND_BONUS
		BD.TraitId.COSTAUD:
			effect = "stock max ×" + dec2(BD.GRIFFE_COSTAUD_STOCK_MAX_MULT)
		BD.TraitId.PERFECTIONNISTE:
			effect = "+%d Lien par cadeau" % BD.GRIFFE_PERFECTIONNISTE_GIFT_BOND_BONUS
		BD.TraitId.TETE_EN_L_AIR:
			effect = "prix max ×" + dec2(BD.GRIFFE_TETE_EN_L_AIR_PRICE_MULT_MAX)
		BD.TraitId.BOSSEUR:
			effect = "+%d Lien au Coup de feu" % BD.GRIFFE_BOSSEUR_COUNTER_BOND_BONUS
		BD.TraitId.BOUT_EN_TRAIN:
			effect = "+%d Moral par jour à tous" % roundi(BD.GRIFFE_BOUT_EN_TRAIN_CLIENT_MORAL_BONUS)
	return "%s (%s)" % [names["griffes"][key], effect]

# En-tête, traits, Griffe (gérant), Moral, activité (VL.npc_activity), outil (producteur).
static func npc_lines(npc: Dictionary, index: int, hour: int, names: Dictionary) -> PackedStringArray:
	var who: Dictionary = names["npcs"][index]
	var g: String = who["g"]
	var producer: bool = Dag.POST_SHOP.has(npc["post"])
	var stars: int = npc["stars"]
	var head: String = "%s : %s, %d %s" % [who["name"], names["posts"][npc["post"]], stars, "étoile" if stars <= 1 else "étoiles"]
	if npc["manages"] != "":
		head += ", " + _manager(g)
	var traits: PackedStringArray = []
	for t: int in npc["traits"]:
		traits.append(_gendered(names["traits"][BD.TraitId.find_key(t)], g))
	var lines: PackedStringArray = [head, "Traits : " + ", ".join(traits)]
	if npc["manages"] != "":
		lines.append("Griffe : " + griffe_text(npc["traits"][0], names))
	var moral: String = "Moral %d/%d" % [npc["moral"], int(BB.MORAL_MAX)]
	if npc["on_strike"]:
		moral += " : en grève, ne travaille pas"
	elif producer:
		moral += " : production ×" + dec2(Eco.moral_prod_mult(npc["moral"]))
	lines.append(moral)
	var act: String = VL.npc_activity(hour, npc)
	lines.append("Maintenant : " + (_gendered(["endormi", "endormie"], g) if act == "SLEEP" else ACTIVITY[act]))
	if producer:
		lines.append("Outil : brisé, production ×" + dec2(BB.TOOL_BROKEN_PROD_MULT) if npc["tool_broken"] else "Outil : %d %%" % roundi(npc["tool_durability"]))
	return lines

static func _cadence_effect(c: String) -> String:
	return "production ×%s, Moral -%d/jour" % [dec2(BB.CADENCE_PROD_MULT[c]), roundi(BB.MORAL_DRAIN_PER_WORK_HOUR[c] * BB.MORAL_WORK_HOURS_PER_DAY)]

# pending : cadence_next ("" sans attente), effet au prochain jour.
static func cadence_help(cadence: String, pending: String, names: Dictionary) -> String:
	if pending != "" and pending != cadence:
		return "Demain : %s (%s)" % [names["cadences"][pending], _cadence_effect(pending)]
	return "%s : %s" % [names["cadences"][cadence], _cadence_effect(cadence)]

static func _posture_effect(p: String) -> String:
	return "cible %d %% du stock, taxe %d %%" % [roundi(BB.POSTURE_TARGET_STOCK_RATIO[p] * 100.0), roundi(BB.POSTURE_VILLAGE_TAX_RATE[p] * 100.0)]

static func posture_help(posture: String, pending: String, names: Dictionary) -> String:
	if pending != "" and pending != posture:
		return "Demain : %s (%s)" % [names["postures"][pending], _posture_effect(pending)]
	return "%s : %s" % [names["postures"][posture], _posture_effect(posture)]

# Stock, cible, max (Griffe comprise), prix au stock actuel et rachat ; manager_index : PNJ dont manages == key.
static func shop_lines(key: String, shop: Dictionary, isolat: int, manager_index: int, names: Dictionary) -> PackedStringArray:
	var who: Dictionary = names["npcs"][manager_index]
	var s_max: int = Eco.stock_max(key == "MAT", shop["lvl"], shop["griffe_trait"])
	var target: int = Eco.stock_target(s_max, shop["posture"])
	var p_max: float = BD.GRIFFE_DEFS[shop["griffe_trait"]]["price_mult_max_override"] if BD.GRIFFE_DEFS.has(shop["griffe_trait"]) else BB.PRICE_MULT_MAX
	var price: int = Eco.sell_price(BB.ITEM_BASE_GOLD[Dag.SHOP_ITEM[key]], isolat, shop["stock"], target, p_max)
	return PackedStringArray(["%s, niveau %d (%s : %s)" % [names["shops"][key], shop["lvl"], _manager(who["g"]), who["name"]],
		"Stock %d / cible %d / max %d" % [shop["stock"], target, s_max], "Prix %d Or, rachat %d Or" % [price, Eco.buyback_price(price)],
		"Trésorerie %d Or" % shop["treasury"]])

static func atre_lines(lvl: int, npc_count: int) -> PackedStringArray:
	return PackedStringArray(["Grand Âtre niveau %d : rayon %d tuiles" % [lvl, BD.ATRE_RADIUS_TILES[lvl - 1]],
		"PNJ %d/%d, postes occupés %d/%d" % [npc_count, BD.ATRE_NPC_CAP[lvl - 1], npc_count, BD.ATRE_WORK_POSTS_CAP[lvl - 1]]])
