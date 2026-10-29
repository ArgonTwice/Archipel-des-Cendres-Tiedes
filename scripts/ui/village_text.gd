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
const AssignS = preload("res://scripts/village/assignment.gd")

const AtreS = preload("res://scripts/village/atre.gd")
const ShopUpS = preload("res://scripts/village/shop_upgrade.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")
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

static func stars_text(s: int) -> String:
	return "%d %s" % [s, "étoile" if s <= 1 else "étoiles"]

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
	var head: String = "%s : %s, %s" % [who["name"], names["posts"][npc["post"]], stars_text(npc["stars"])]
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
	return PackedStringArray(["%s : %s" % ["Gérant" if who["g"] == "M" else "Gérante", who["name"]],
		"Stock %d / cible %d / max %d" % [shop["stock"], target, s_max], "Prix %d Or, rachat %d Or" % [price, Eco.buyback_price(price)],
		"Trésorerie %d Or" % shop["treasury"]])

# Ligne d'un onglet Village (jalon 19 bis) : 2 lignes de tête, détail dans la carte dépliée.
static func atre_head(lvl: int, npc_count: int) -> PackedStringArray:
	return PackedStringArray(["Grand Âtre, niveau %d" % lvl,
		"PNJ %d/%d, postes occupés %d/%d" % [npc_count, mini(BD.ATRE_NPC_CAP[lvl - 1], BD.VERTICAL_SLICE_NPC_CAP), npc_count, BD.ATRE_WORK_POSTS_CAP[lvl - 1]]])

static func atre_detail(lvl: int) -> String:
	return "Rayon %d tuiles autour de l'Âtre" % BD.ATRE_RADIUS_TILES[lvl - 1]

# Agrandir (jalon 21) : « Niveau 2 : rayon 18 tuiles, 10 postes ».
static func upgrade_effect(lvl: int) -> String:
	return "Niveau %d : rayon %d tuiles, %d postes" % [lvl + 1, BD.ATRE_RADIUS_TILES[lvl], BD.ATRE_WORK_POSTS_CAP[lvl]]

# « Agrandir le Grand Âtre », « 600 Or, 40 minerais, 40 Matériaux, 4 h ».
static func upgrade_button(lvl: int, names: Dictionary) -> PackedStringArray:
	var c: Dictionary = AtreS.cost(lvl)
	return PackedStringArray(["Agrandir le Grand Âtre", "%d Or, %d minerai%s, %d %s, %s" % [c["gold"], c["ore"], "s" if c["ore"] > 1 else "",
		c["mat"], names["shops"]["MAT"], duration(c["minutes"])]])

# Durée d'un chantier : « 45 min », « 4 h », « 1 h 30 ».
static func duration(m: int) -> String:
	return "%d min" % m if m < 60 else ("%d h" % (m / 60) if m % 60 == 0 else "%d h %02d" % [m / 60, m % 60])

static func atre_toast(lvl: int) -> String:
	return "Grand Âtre niveau %d !" % lvl

# Agrandir une boutique (jalon 22) : « Niveau 2 : stock max 100, frais 16 Or/jour » (Griffe comprise, frais de cette boutique).
static func shop_upgrade_effect(key: String, shop: Dictionary) -> String:
	var lvl: int = shop["lvl"] + 1
	return "Niveau %d : stock max %d, frais %d Or/jour" % [lvl, Eco.stock_max(key == "MAT", lvl, shop["griffe_trait"]), BB.SHOP_DAILY_FIXED_SINK_PER_LVL * lvl]

# « Agrandir la boutique », « 250 Or, 15 Matériaux, 1 h ».
static func shop_upgrade_button(lvl: int, names: Dictionary) -> PackedStringArray:
	var c: Dictionary = ShopUpS.cost(lvl)
	return PackedStringArray(["Agrandir la boutique", "%s Or, %d %s, %s" % [EqText.num(c["gold"]), c["mat"], names["shops"]["MAT"], duration(c["minutes"])]])

static func shop_toast(key: String, lvl: int, names: Dictionary) -> String:
	return "%s niveau %d !" % [names["shops"][key], lvl]

# Surbrillance du bâtiment visé (jalon 21) : [texte, rôle] ou [] (herbe, maison, Âtre, ou poste de demain du PNJ saisi).
static func drop_hint(village: Dictionary, index: int, site: String, lvl: int, names: Dictionary) -> Array:
	var post: String = VL.SITE_POST.get(site, "")
	if post == "" or post == AssignS.effective_post(village["npcs"][index]):
		return []
	var occ: int = AssignS.occupancy(village)[post]
	var cap: int = AssignS.slots(lvl, post)
	if occ < cap:
		return ["%s %d/%d, libre" % [names["posts"][post], occ, cap], "GOOD"]
	return ["%s %d/%d, échange" % [names["posts"][post], occ, cap], "ALERT"]

# « Stock 12/30, Solidaire, demain Exportation » : max Griffe comprise, posture en attente si elle diffère.
static func shop_head(key: String, shop: Dictionary, names: Dictionary) -> PackedStringArray:
	var s_max: int = Eco.stock_max(key == "MAT", shop["lvl"], shop["griffe_trait"])
	var line: String = "Stock %d/%d, %s" % [shop["stock"], s_max, names["postures"][shop["posture"]]]
	var pending: String = shop.get("posture_next", "")
	if pending != "" and pending != shop["posture"]:
		line += ", demain " + names["postures"][pending]
	return PackedStringArray(["%s, niveau %d" % [names["shops"][key], shop["lvl"]], line])

# Bande de production du Moral (seuils de Economy.moral_prod_mult) : STRIKE, LOW, NORMAL, HIGH.
static func moral_band(moral: int, on_strike: bool) -> String:
	if on_strike or moral < BB.MORAL_STRIKE_ENTER_THRESHOLD:
		return "STRIKE"
	if moral < BB.MORAL_LOW_PENALTY_THRESHOLD:
		return "LOW"
	if moral < BB.MORAL_HIGH_BONUS_THRESHOLD:
		return "NORMAL"
	return "HIGH"

static func moral_tag(npc: Dictionary) -> String:
	return "En grève" if npc["on_strike"] else "Moral %d" % npc["moral"]

# Postes (jalon 19) : aptitudes des 4 postes ouverts, puis Collecte, Négoce (fermés) et favori.
static func apt_lines(apt: Dictionary, favorite: String, names: Dictionary) -> PackedStringArray:
	var open: PackedStringArray = []
	for p: String in AssignS.active_posts():
		open.append("%s %d" % [names["posts"][p], apt[p]])
	return PackedStringArray(["Aptitudes : " + ", ".join(open),
		"%s %d, %s %d (fermés) ; favori : %s" % [names["posts"]["GATHER"], apt["GATHER"], names["posts"]["MERCHANT"], apt["MERCHANT"], names["posts"][favorite]]])

# « Demain : … » si un poste est en attente, « (auto) » s'il vient de l'auto-assignation ; puis le verrou.
static func post_lines(npc: Dictionary, names: Dictionary) -> PackedStringArray:
	var locked: bool = npc.get("locked", false)
	var out: PackedStringArray = []
	if npc.has("post_next"):
		out.append("Demain : %s, %s%s" % [names["posts"][npc["post_next"]], stars_text(npc["stars_next"]), "" if locked else " (auto)"])
	out.append("Poste : verrouillé" if locked else "Poste : libre (auto)")
	return out

# « Extraction 1/2, Forge 1/1, Taverne 1/1, Garde 2/2 » d'après les postes effectifs.
static func slots_line(village: Dictionary, lvl: int, names: Dictionary) -> String:
	var occ: Dictionary = AssignS.occupancy(village)
	var parts: PackedStringArray = []
	for p: String in AssignS.active_posts():
		parts.append("%s %d/%d" % [names["posts"][p], occ[p], AssignS.slots(lvl, p)])
	return ", ".join(parts)

# Toast après un changement de poste ; result : sortie de Assignment.move.
static func move_toast(index: int, post: String, result: Dictionary, names: Dictionary) -> String:
	var who: String = names["npcs"][index]["name"]
	match result["kind"]:
		"swap":
			return "%s et %s échangent demain" % [who, names["npcs"][result["other"]]["name"]]
		"same":
			return "%s : poste verrouillé" % who
	return "%s : %s demain" % [who, names["posts"][post]]
