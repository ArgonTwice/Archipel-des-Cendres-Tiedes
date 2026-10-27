extends RefCounted
# Forge du village (Volet F §2, jalon 16) : 4 minerais (+ 25 Cendre en option) -> une pièce de l'emplacement choisi
# et de l'XP de Forgeron. Pas d'aperçu avant de payer : la pièce attend dans forge_pending jusqu'au choix. Statiques pures.

const BA = preload("res://balance/balance_a.gd")
const BB = preload("res://balance/balance_b.gd")
const BF = preload("res://balance/balance_f.gd")
const EquipmentS = preload("res://scripts/loot/equipment.gd")
const ProgressionS = preload("res://scripts/progression.gd")

const ORE: String = BF.MIST_NODE_MINERAL_ITEM_ID

static func ore(player: Dictionary) -> int:
	return player["chest"].get(ORE, 0)

static func can_craft(player: Dictionary, cendre: bool, at_village: bool) -> bool:
	return at_village and player["forge_pending"] == null and ore(player) >= BB.CRAFT_MINERAL_COST_EQUIPMENT \
		and (not cendre or player["cendre"] >= BA.CENDRE_COST_STANDARD_CRAFT)

# Tirage au niveau de Forgeron avant le gain, paiement, XP (rattrapage), pièce en attente. Rend le log « craft » et
# le gain de Progression.gain (toast de niveau).
static func craft(world_seed: int, player: Dictionary, slot: int, cendre: bool, isolat: int) -> Dictionary:
	var lf: int = ProgressionS.level_of(player["voc_xp"]["FORGERON"])
	var n: int = player["forge_n"]
	var piece: Dictionary = EquipmentS.craft(world_seed, n, slot, lf, cendre, isolat)
	player["chest"][ORE] = ore(player) - BB.CRAFT_MINERAL_COST_EQUIPMENT
	if cendre:
		player["cendre"] -= BA.CENDRE_COST_STANDARD_CRAFT
	player["forge_n"] = n + 1
	var base: int = BA.XP_CRAFT_WITH_CENDRE if cendre else BA.XP_CRAFT_NO_CENDRE
	var g: Dictionary = ProgressionS.gain(player, "FORGERON", floori(base * BA.ISOLAT_XP_MULTIPLIERS[isolat]))
	player["forge_pending"] = piece
	var affixes: Array = []
	for a: Dictionary in piece["affixes"]:
		affixes.append([a["id"], snappedf(a["units"], 0.0001)])
	return {"log": {"event": "craft", "n": n, "slot": slot, "cendre": cendre, "forgeron": lf, "rarete": piece["rarity"], "ilvl": piece["ilvl"],
		"superieure": piece["superior"], "ecoles": piece["schools"], "affixes": affixes, "xp": g["gained"]}, "gain": g}

# Équiper ou Jeter vide forge_pending ; l'ancienne pièce de l'emplacement disparaît (pas d'inventaire, comme au jalon 15).
static func choose(player: Dictionary, equip: bool) -> Dictionary:
	var piece: Dictionary = player["forge_pending"]
	if equip:
		player["equipment"][piece["slot"]] = piece.duplicate(true)
	player["forge_pending"] = null
	return {"event": "craft_choix", "slot": piece["slot"], "choix": "equiper" if equip else "jeter"}
