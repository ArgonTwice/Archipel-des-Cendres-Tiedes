extends RefCounted
# Vocations du joueur (Volet A §1 à §4, SOCLE §A9) : XP cumulée depuis le niveau 1, seule donnée sauvegardée ;
# le niveau s'en déduit. Statiques pures.

const BA = preload("res://balance/balance_a.gd")

const VOCATIONS: Array[String] = ["COMBATTANT", "MINEUR", "FORGERON"]
const VOCATION_NAMES: Dictionary = {"COMBATTANT": "Combattant", "MINEUR": "Mineur", "FORGERON": "Forgeron"}

static func new_player() -> Dictionary:
	return {"voc_xp": {"COMBATTANT": 0, "MINEUR": 0, "FORGERON": 0}}

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
	var gained: int = roundi(base_xp * BA.get_action_xp_catchup_mult(before, top_level(player)))
	player["voc_xp"][voc] += gained
	return {"gained": gained, "level_before": before, "level_after": level_of(player["voc_xp"][voc])}

# XP dans le niveau et XP requise pour le passer.
static func level_progress(xp: int) -> Vector2i:
	var level: int = level_of(xp)
	return Vector2i(xp - BA.get_cumulative_xp(level), BA.get_xp_required(level))
