extends RefCounted
# Vocations du joueur (Volet A §1 à §4, SOCLE §A9) : XP cumulée depuis le niveau 1 ; le niveau s'en déduit.
# Lanterne niveau 1 (Volet A §5, jalon 14) : Cendre Vive et Sacoche (shard_bag = liste de {"elite", "ilvl"}, jalon 15 bis)
# gardées entre les expéditions. Équipement porté et compteur de purifications (Volet F, jalon 15) ; Élites tués dans
# l'isolat (n°37). Coffre du village, caisse de cargaison perdue et Forge (jalon 16). Statiques pures.

const BA = preload("res://balance/balance_a.gd")
const EquipmentS = preload("res://scripts/loot/equipment.gd")

const VOCATIONS: Array[String] = ["COMBATTANT", "MINEUR", "FORGERON"]
const VOCATION_NAMES: Dictionary = {"COMBATTANT": "Combattant", "MINEUR": "Mineur", "FORGERON": "Forgeron"}

static func new_player() -> Dictionary:
	return {"voc_xp": {"COMBATTANT": 0, "MINEUR": 0, "FORGERON": 0}, "cendre": 0, "shard_bag": [],
		"equipment": EquipmentS.new_equipment(), "purify_n": 0, "elite_kills": 0,
		"chest": {}, "crate": null, "forge_n": 0, "forge_pending": null}

# Plafonné à MAX_VOCATION_LEVEL : la Maîtrise est hors jalon.
static func level_of(xp: int) -> int:
	var level: int = 1
	while level < BA.MAX_VOCATION_LEVEL and BA.get_cumulative_xp(level + 1) <= xp:
		level += 1
	return level

static func combat_level(player: Dictionary) -> int:
	return level_of(player["voc_xp"]["COMBATTANT"])

static func top_level(player: Dictionary) -> int:
	var top: int = 1
	for voc: String in VOCATIONS:
		top = maxi(top, level_of(player["voc_xp"][voc]))
	return top

# base_xp : XP de l'action après M_isolat. Rattrapage ×2 face à la plus haute vocation. Modifie player en place.
static func gain(player: Dictionary, voc: String, base_xp: int) -> Dictionary:
	var before: int = level_of(player["voc_xp"][voc])
	var gained: int = gain_preview(player, voc, base_xp)
	player["voc_xp"][voc] += gained
	return {"gained": gained, "level_before": before, "level_after": level_of(player["voc_xp"][voc])}

# XP que gain() ajouterait, rattrapage compris, sans rien modifier.
static func gain_preview(player: Dictionary, voc: String, base_xp: int) -> int:
	return floori(base_xp * BA.get_action_xp_catchup_mult(level_of(player["voc_xp"][voc]), top_level(player))) # floor : Volet F

# XP dans le niveau et XP requise pour le passer.
static func level_progress(xp: int) -> Vector2i:
	var level: int = level_of(xp)
	return Vector2i(xp - BA.get_cumulative_xp(level), BA.get_xp_required(level))
