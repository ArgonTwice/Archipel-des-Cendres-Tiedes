extends RefCounted
# Agrandissement des boutiques (jalon 22, Volet B §3 et §5, SOCLE §A7) : chantier par boutique, niveaux 1 à 10. Statiques pures.
# Clé optionnelle shops[key].chantier_end (UTC de fin, absente sans chantier) ; lvl existe déjà dans chaque boutique.
# Règles validées par Antho (Z16) : celles du Grand Âtre (Or du village, Tier 0 du stock de la boutique Matériaux, tout payé au
# lancement, non annulable, fin quand now_utc >= fin), un chantier par bâtiment, boutique ouverte pendant son chantier (SOCLE §A7).

const BB = preload("res://balance/balance_b.gd")
const AtreS = preload("res://scripts/village/atre.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")

const MAX_LEVEL: int = 10 # SOCLE §A7, à reporter dans balance_b.gd au prochain delta Argon

# Coût du niveau lvl -> lvl + 1, L = niveau de départ : Or 250 L², Tier 0 15 L, min(1440, 60 L²) minutes.
static func cost(lvl: int) -> Dictionary:
	return {"gold": BB.SHOP_UPGRADE_COST_QUAD_BASE * lvl * lvl, "mat": BB.SHOP_TIER0_UPGRADE_MAT_PER_LVL * lvl,
		"minutes": int(minf(BB.CHANTIER_MAX_DURATION_MIN, BB.CHANTIER_UPGRADE_QUAD_BASE_MIN * lvl * lvl))}

# Première raison qui grise « Agrandir la boutique », "" si le chantier peut partir. Le chantier d'un autre bâtiment ne bloque pas.
static func block_reason(village: Dictionary, key: String, in_village: bool, now_utc: int, names: Dictionary) -> String:
	var shop: Dictionary = village["shops"][key]
	if not in_village:
		return "Chantier au village seulement"
	if shop.has("chantier_end"):
		return "Chantier en cours, " + AtreS.end_text(shop["chantier_end"], now_utc, village["tz_offset_sec"])
	if shop["lvl"] >= MAX_LEVEL:
		return "Niveau maximal"
	var c: Dictionary = cost(shop["lvl"])
	if village["player_gold"] < c["gold"]:
		return "Il manque %s Or" % EqText.num(c["gold"] - village["player_gold"])
	var stock: int = village["shops"]["MAT"]["stock"]
	if stock < c["mat"]:
		return "Il manque %d %s en stock" % [c["mat"] - stock, names["shops"]["MAT"]]
	return ""

# Paie et pose la fin ; l'appelant vérifie block_reason == "" avant. Rend le log du chantier.
static func start(village: Dictionary, key: String, now_utc: int) -> Dictionary:
	var shop: Dictionary = village["shops"][key]
	var c: Dictionary = cost(shop["lvl"])
	village["player_gold"] -= c["gold"]
	village["shops"]["MAT"]["stock"] -= c["mat"]
	shop["chantier_end"] = now_utc + c["minutes"] * 60
	return {"event": "chantier_boutique", "boutique": key, "niveau": shop["lvl"] + 1, "fin": shop["chantier_end"]}

static func finish_if_due(village: Dictionary, key: String, now_utc: int) -> bool:
	var shop: Dictionary = village["shops"][key]
	if not shop.has("chantier_end") or now_utc < shop["chantier_end"]:
		return false
	shop["lvl"] += 1
	shop.erase("chantier_end")
	return true

# Chargement (SaveManager.unpack) : chantier_end invalide ou au niveau maximal effacé ; lvl n'est pas touché.
static func sanitize(village: Dictionary) -> void:
	for shop: Dictionary in village["shops"].values():
		var end: Variant = shop.get("chantier_end")
		if shop.has("chantier_end") and not (typeof(end) == TYPE_INT and end > 0 and shop["lvl"] < MAX_LEVEL):
			shop.erase("chantier_end")
