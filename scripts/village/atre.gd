extends RefCounted
# Grand Âtre (jalon 21, Volet D §6, Volet B §3 et §5) : niveau et chantier d'agrandissement. Statiques pures.
# Clés optionnelles du village : atre_lvl (absent = 1), atre_chantier_end (UTC de fin, absent sans chantier).
# Règles validées par Antho (Z15) : tout est payé au lancement (Or du village, minerais du coffre, Matériaux du stock de la
# boutique MAT), le chantier ne s'annule pas, il finit quand now_utc >= fin (horloge qui recule : rien ne bouge),
# en session comme au lancement suivant ; effets immédiats à la fin.

const BB = preload("res://balance/balance_b.gd")
const BD = preload("res://balance/balance_d.gd")
const ForgeS = preload("res://scripts/loot/forge.gd")

const NAMES_PATH: String = "res://data/village/npcs.json"

static func level(village: Dictionary) -> int:
	return village.get("atre_lvl", 1)

# Coût du niveau lvl -> lvl + 1 (BalanceD), durée du chantier (BalanceB, Nv2 seul en tranche).
static func cost(lvl: int) -> Dictionary:
	return {"gold": BD.compute_atre_upgrade_gold_cost(lvl), "ore": BD.compute_atre_upgrade_mineral_cost(lvl),
		"mat": BD.compute_atre_upgrade_tier0_cost(lvl), "minutes": int(BB.CHANTIER_ATRE_LVL2_MIN)}

# Première raison qui grise « Agrandir », "" si le chantier peut partir : lieu, chantier, niveau maximal, Or, minerais, Matériaux.
static func block_reason(village: Dictionary, ore: int, in_village: bool, now_utc: int) -> String:
	if not in_village:
		return "Chantier au village seulement"
	if village.has("atre_chantier_end"):
		return "Chantier en cours, " + end_text(village["atre_chantier_end"], now_utc, village["tz_offset_sec"])
	if level(village) >= BD.VERTICAL_SLICE_MAX_ATRE_LEVEL:
		return "Niveau maximal"
	var c: Dictionary = cost(level(village))
	if village["player_gold"] < c["gold"]:
		return "Il manque %d Or" % (c["gold"] - village["player_gold"])
	if ore < c["ore"]:
		var n: int = c["ore"] - ore
		return "Il manque %d minerai%s" % [n, "s" if n > 1 else ""]
	var stock: int = village["shops"]["MAT"]["stock"]
	if stock < c["mat"]:
		var names: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NAMES_PATH))
		return "Il manque %d %s en stock" % [c["mat"] - stock, names["shops"]["MAT"]]
	return ""

# « fini à 15 h 05 », « fini demain à 3 h 10 » : date civile locale (pas le day_index de 4 h).
static func end_text(end_utc: int, now_utc: int, tz: int) -> String:
	var t: int = posmod(end_utc + tz, 86400)
	var tomorrow: bool = floori((end_utc + tz) / 86400.0) > floori((now_utc + tz) / 86400.0)
	return "fini %sà %d h %02d" % ["demain " if tomorrow else "", t / 3600, t % 3600 / 60]

# Paie et pose la fin ; l'appelant vérifie block_reason == "" avant. Rend le log du chantier.
static func start(village: Dictionary, player: Dictionary, now_utc: int) -> Dictionary:
	var c: Dictionary = cost(level(village))
	village["player_gold"] -= c["gold"]
	player["chest"][ForgeS.ORE] = ForgeS.ore(player) - c["ore"]
	village["shops"]["MAT"]["stock"] -= c["mat"]
	village["atre_chantier_end"] = now_utc + c["minutes"] * 60
	return {"event": "chantier", "niveau": level(village) + 1, "fin": village["atre_chantier_end"]}

static func finish_if_due(village: Dictionary, now_utc: int) -> bool:
	if not village.has("atre_chantier_end") or now_utc < village["atre_chantier_end"]:
		return false
	village["atre_lvl"] = level(village) + 1
	village.erase("atre_chantier_end")
	return true

# Chargement (SaveManager.unpack) : valeur invalide effacée, comme les clés _next.
static func sanitize(village: Dictionary) -> void:
	var lvl: Variant = village.get("atre_lvl")
	if village.has("atre_lvl") and not (typeof(lvl) == TYPE_INT and lvl >= 1 and lvl <= BD.VERTICAL_SLICE_MAX_ATRE_LEVEL):
		village.erase("atre_lvl")
	var end: Variant = village.get("atre_chantier_end")
	if village.has("atre_chantier_end") and not (typeof(end) == TYPE_INT and end > 0 and level(village) < BD.VERTICAL_SLICE_MAX_ATRE_LEVEL):
		village.erase("atre_chantier_end")
