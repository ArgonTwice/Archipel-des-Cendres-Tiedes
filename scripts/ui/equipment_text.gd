extends RefCounted
# Textes du panneau Équipement (Volet F, jalon 15) : jetons de genre FR, une décimale à la virgule. Statiques pures.

const BA = preload("res://balance/balance_a.gd")
const BB = preload("res://balance/balance_b.gd")
const BC = preload("res://balance/balance_c.gd")
const BF = preload("res://balance/balance_f.gd")
const EquipmentS = preload("res://scripts/loot/equipment.gd")

const SLOT_NAMES: Array[String] = ["Arme", "Casque", "Plastron", "Bottes"]
const SLOT_GENDER: Array[String] = ["", "M", "M", "FP"] # l'arme lit son genre dans WEAPON_SPECS
const SLOT_NOUN_GENDER: Array[String] = ["F", "M", "M", "FP"] # genre du nom d'emplacement (« l'Arme », « les Bottes »)
const RARITY_FORMS: Array[Dictionary] = [
	{"M": "Commun", "F": "Commune", "FP": "Communes"}, {"M": "Bon", "F": "Bonne", "FP": "Bonnes"}, {"M": "Rare", "F": "Rare", "FP": "Rares"}]
const SCHOOL_NAMES: Dictionary = {BC.SchoolId.FOYER: "Enclume", BC.SchoolId.BRASIER: "Brasier"}
const PCT_LABELS: Dictionary = {"PCT_ATK": "ATK d'arme", "PCT_ASPD": "cadence", "PCT_CRIT_CHANCE": "critique", "PCT_CRIT_DMG": "dégâts critiques"}

static func dec1(x: float) -> String:
	return ("%.1f" % x).replace(".", ",")

static func gender(slot: int) -> String:
	return BC.WEAPON_SPECS[BC.WeaponType.SWORD_SHIELD]["gender"] if slot == 0 else SLOT_GENDER[slot]

static func affix(a: Dictionary) -> String:
	var value: float = BC.AFFIX_DEFS[a["id"]]["unit_value"] * a["units"]
	match a["id"]:
		"FLAT_ATK":
			return "+%s ATK" % dec1(value)
		"FLAT_DEF":
			return "+%s DEF" % dec1(value)
		"FLAT_HP":
			return "+%d PV" % roundi(value)
	return "+%d %% %s" % [roundi(a["units"]), PCT_LABELS[a["id"]]]

static func schools(piece: Dictionary) -> String:
	var s: Array = piece["schools"]
	if s[0] == s[1] and s[1] == s[2]:
		return "%s 3/3" % SCHOOL_NAMES[s[0]]
	return " / ".join(s.map(func(x: int) -> String: return SCHOOL_NAMES[x]))

# « Arme : Épée & Écu Commune, ilvl 1 », « Enclume 3/3, ATK d'arme 10,4 » en retrait (jalon 17), puis un affixe par ligne en retrait.
static func piece_lines(slot: int, piece: Variant) -> PackedStringArray:
	if piece == null:
		return PackedStringArray(["%s : vide" % SLOT_NAMES[slot]])
	var rarity: String = RARITY_FORMS[piece["rarity"]][gender(slot)]
	var lines: PackedStringArray = ["%s : %s, ilvl %d" % [SLOT_NAMES[slot], rarity, piece["ilvl"]]]
	if slot == 0:
		lines[0] = "Arme : Épée & Écu %s, ilvl %d" % [rarity, piece["ilvl"]]
		lines.append("    %s, ATK d'arme %s" % [schools(piece), dec1(EquipmentS.weapon_atk(piece))])
	for a: Dictionary in piece["affixes"]:
		lines.append("    " + affix(a))
	return lines

static func equipment_lines(equipment: Array) -> PackedStringArray:
	var lines: PackedStringArray = []
	for slot in equipment.size():
		lines.append_array(piece_lines(slot, equipment[slot]))
	return lines

# Article défini par jetons de genre et de nombre, élidé devant une voyelle : « l'Arme », « le Casque », « les Bottes ».
static func with_article(slot: int) -> String:
	var g: String = SLOT_NOUN_GENDER[slot]
	if g.ends_with("P"):
		return "les " + SLOT_NAMES[slot]
	if "AEIOUÉÈ".contains(SLOT_NAMES[slot].left(1)):
		return "l'" + SLOT_NAMES[slot]
	return ("la " if g == "F" else "le ") + SLOT_NAMES[slot]

# « PV 154  ATK 30  DEF 13 », « Cadence 1,20/s  Critique 5 % ×1,5 »
static func stats_lines(st: Dictionary) -> PackedStringArray:
	return PackedStringArray(["PV %d  ATK %d  DEF %d" % [st["hp"], st["atk"], st["def"]],
		"Cadence %s/s  Critique %d %% ×%s" % [("%.2f" % (1.0 / st["period"])).replace(".", ","), roundi(st["crit_rate"] * 100.0), dec1(st["crit_mult"])]])

# « PV +36  ATK +0  DEF +0 »
static func diff_line(before: Dictionary, after: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k: Array in [["PV", "hp"], ["ATK", "atk"], ["DEF", "def"]]:
		var d: int = after[k[1]] - before[k[1]]
		parts.append("%s %s%d" % [k[0], "+" if d >= 0 else "", d])
	return "  ".join(parts)

# Forge (jalon 16 bis) : aide avant de forger. forgeron_level déjà borné à l'isolat, xp_gain = gain réel (Forge.xp_preview) ;
# sans isolat, le rattrapage est le seul facteur qui atteint CATCHUP_ACTION_XP_MULT (isolat ≤ ×1,48).
static func forge_help(cendre: bool, forgeron_level: int, xp_gain: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	var ore: String = "Coût : %s" % plural(BB.CRAFT_MINERAL_COST_EQUIPMENT, "minerai")
	var base: int = BA.XP_CRAFT_WITH_CENDRE if cendre else BA.XP_CRAFT_NO_CENDRE
	if cendre:
		var w: Array[int] = BF.get_craft_with_cendre_rarity_weights(forgeron_level) # somme 100 : poids = %
		var parts: PackedStringArray = []
		for r in w.size():
			parts.append("%s %d %%" % [RARITY_FORMS[r]["M"], w[r]])
		lines.append("%s + %d Cendre" % [ore, BA.CENDRE_COST_STANDARD_CRAFT])
		lines.append("Rareté : " + ", ".join(parts))
		lines.append("Qualité Supérieure : %d %% de chance, +%d ilvl" % [roundi(BA.SUPERIOR_CHANCE_BASE * 100.0), BA.SUPERIOR_QUALITY_ILVL_BONUS])
	else:
		lines.append(ore)
		lines.append("Rareté : toujours " + RARITY_FORMS[0]["M"])
		lines.append("Qualité Supérieure : jamais")
	lines.append("Pièce d'ilvl %d (niveau de ton Forgeron)" % forgeron_level)
	var xp: String = "+%d XP de Forgeron" % xp_gain
	if xp_gain >= floori(base * BA.CATCHUP_ACTION_XP_MULT):
		xp += " (rattrapage ×%d)" % roundi(BA.CATCHUP_ACTION_XP_MULT)
	lines.append(xp)
	return lines

# Première raison qui grise les boutons de la Forge, "" si le craft est possible.
static func forge_block_reason(in_village: bool, ore: int, cendre_have: int, cendre: bool, pending: bool) -> String:
	if not in_village:
		return "Forge au village seulement"
	if ore < BB.CRAFT_MINERAL_COST_EQUIPMENT:
		return "Il manque " + plural(BB.CRAFT_MINERAL_COST_EQUIPMENT - ore, "minerai")
	if cendre and cendre_have < BA.CENDRE_COST_STANDARD_CRAFT:
		return "Il manque %d Cendre" % (BA.CENDRE_COST_STANDARD_CRAFT - cendre_have)
	if pending:
		return "Choisis d'abord : Équiper ou Jeter"
	return ""

# « Tu as : 12 minerais, 100 Cendre »
static func forge_reserve(ore: int, cendre_have: int) -> String:
	return "Tu as : %s, %d Cendre" % [plural(ore, "minerai"), cendre_have]

# Bandeau (jalon 17) : paires [clé, texte] dans l'ordre d'affichage. cargo : [kg portés, capacité] en expédition, null sinon.
# Plié : sans Or, minerai seulement en expédition. Déplié : minerai du coffre au village, cargaison en Brume.
static func hud_values(gold: int, player: Dictionary, ore: int, cargo: Variant, compact: bool) -> Array:
	var out: Array = []
	if not compact:
		out.append(["or", str(gold)])
	out.append(["cendre", "%d/%d" % [player["cendre"], BA.LANTERN_CENDRE_CAP[0]]])
	out.append(["eclats", "%d/%d" % [player["shard_bag"].size(), BA.LANTERN_SHARD_BAG_CAP[0]]])
	if cargo != null:
		out.append(["minerai", "%s/%s" % [kg(cargo[0]), kg(cargo[1])]])
	elif not compact:
		out.append(["minerai", str(ore)])
	return out

# À l'unité, ou à 0,1 près si non entier : « 25 », « 25,8 ».
static func kg(x: float) -> String:
	var r: float = snappedf(x, 0.1)
	return str(roundi(r)) if is_equal_approx(r, roundf(r)) else dec1(r)

# Onglet Sacoche (jalon 17) : Lanterne, Éclats (dont d'Élite), coffre.
static func sacoche_lines(player: Dictionary, ore: int) -> PackedStringArray:
	var elite: int = 0
	for s: Dictionary in player["shard_bag"]:
		elite += int(s["elite"])
	var shards: String = "Éclats : %d/%d" % [player["shard_bag"].size(), BA.LANTERN_SHARD_BAG_CAP[0]]
	if elite > 0:
		shards += ", dont %d d'Élite" % elite
	return PackedStringArray(["Lanterne : Cendre %d/%d" % [player["cendre"], BA.LANTERN_CENDRE_CAP[0]], shards, "Coffre : " + plural(ore, "minerai")])

# Première raison qui grise « Purifier un Éclat », "" si la purification est possible. at_brazier : Brasero sous le
# joueur pendant une expédition ; brazier_used : purifications déjà faites au Brasero dans cette expédition.
static func purify_block_reason(in_village: bool, at_brazier: bool, brazier_used: int, shards: int, pending: bool) -> String:
	if not in_village and not at_brazier:
		return "Purification au village ou au Brasero"
	if not in_village and brazier_used >= BF.SHARD_PURIFY_BRAZIER_MAX_PER_RUN:
		return "Déjà %d purifications au Brasero cette expédition" % BF.SHARD_PURIFY_BRAZIER_MAX_PER_RUN
	if shards < BF.SHARD_PURIFY_COST_SHARDS:
		return "Sacoche vide"
	if pending:
		return "Choisis d'abord : Équiper ou Jeter"
	return ""

# « 1 minerai », « 0 minerai », « 2 minerais »
static func plural(n: int, noun: String) -> String:
	return "%d %s%s" % [n, noun, "s" if n > 1 else ""]

# Verdict de la carte (jalon 16 bis) : 1 si aucune stat ne baisse et une monte, -1 si aucune ne monte et une baisse,
# 0 sinon (mixte ou identique). Pas de score pondéré : aucune formule d'équilibrage côté interface. Cadence : période plus courte = mieux.
static func compare(before: Dictionary, after: Dictionary) -> int:
	var up: bool = false
	var down: bool = false
	for k: String in ["hp", "atk", "def", "period", "crit_rate", "crit_mult"]:
		var d: float = (before[k] - after[k]) if k == "period" else (after[k] - before[k])
		up = up or d > 1e-9
		down = down or d < -1e-9
	return 0 if up == down else (1 if up else -1)

const VERDICTS: Dictionary = {1: "Meilleure que l'équipée", -1: "Moins bonne que l'équipée", 0: "Ni meilleure ni moins bonne : compare les stats"}
