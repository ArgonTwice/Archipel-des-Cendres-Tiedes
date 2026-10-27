extends RefCounted
# Textes du panneau Équipement (Volet F, jalon 15) : jetons de genre FR, une décimale à la virgule. Statiques pures.

const BA = preload("res://balance/balance_a.gd")
const BC = preload("res://balance/balance_c.gd")
const EquipmentS = preload("res://scripts/loot/equipment.gd")

const SLOT_NAMES: Array[String] = ["Arme", "Casque", "Plastron", "Bottes"]
const SLOT_GENDER: Array[String] = ["", "M", "M", "FP"] # l'arme lit son genre dans WEAPON_SPECS
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

# « Arme : Épée & Écu Commune, ilvl 1, Enclume 3/3, ATK d'arme 10,4 », puis un affixe par ligne en retrait.
static func piece_lines(slot: int, piece: Variant) -> PackedStringArray:
	if piece == null:
		return PackedStringArray(["%s : vide" % SLOT_NAMES[slot]])
	var rarity: String = RARITY_FORMS[piece["rarity"]][gender(slot)]
	var head: String = "%s : %s, ilvl %d" % [SLOT_NAMES[slot], rarity, piece["ilvl"]]
	if slot == 0:
		head = "Arme : Épée & Écu %s, ilvl %d, %s, ATK d'arme %s" % [rarity, piece["ilvl"], schools(piece), dec1(EquipmentS.weapon_atk(piece))]
	var lines: PackedStringArray = [head]
	for a: Dictionary in piece["affixes"]:
		lines.append("    " + affix(a))
	return lines

static func equipment_lines(equipment: Array) -> PackedStringArray:
	var lines: PackedStringArray = []
	for slot in equipment.size():
		lines.append_array(piece_lines(slot, equipment[slot]))
	return lines

# « PV 154  ATK 30  DEF 13  Cadence 1,20/s  Critique 5 % ×1,5 »
static func stats_line(st: Dictionary) -> String:
	return "PV %d  ATK %d  DEF %d  Cadence %s/s  Critique %d %% ×%s" % [st["hp"], st["atk"], st["def"], ("%.2f" % (1.0 / st["period"])).replace(".", ","),
		roundi(st["crit_rate"] * 100.0), dec1(st["crit_mult"])]

# « PV +36  ATK +0  DEF +0 »
static func diff_line(before: Dictionary, after: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k: Array in [["PV", "hp"], ["ATK", "atk"], ["DEF", "def"]]:
		var d: int = after[k[1]] - before[k[1]]
		parts.append("%s %s%d" % [k[0], "+" if d >= 0 else "", d])
	return "  ".join(parts)
