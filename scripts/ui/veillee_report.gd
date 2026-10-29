class_name VeilleeReport
extends RefCounted
# Rapport de veillée (SOCLE §A4) : lignes affichées au lancement et au retour.
# report : sortie de SaveManager.boot / sync. compact (plié) : absence et Or seulement.

const BB = preload("res://balance/balance_b.gd")
const EqText = preload("res://scripts/ui/equipment_text.gd")

# Clés fixes (jalon 20 ter) : une _line créée par clé dans chaque couche, masquée si la clé est absente de rows.
const KEYS: Array[String] = ["new_game", "absence", "or", "frais", "outils", "greve", "fiches"]
const ICONS: Dictionary = {"new_game": "ATRE", "absence": "ATRE", "or": "or", "frais": "or", "outils": "FORGE", "greve": "TAB_PNJ",
	"fiches": "TAB_VILLAGE"}

static func _row(key: String, text: String, role: String = "TEXT", tag: String = "") -> Dictionary:
	return {"key": key, "icon": ICONS[key], "text": text, "role": role, "tag": tag}

# Lignes dans l'ordre de KEYS : {key, icon (notion de UiStyle.ICONS), text, role (couleur du texte), tag (en MUTED)}.
static func rows(report: Dictionary, compact: bool) -> Array:
	if report.get("new_game", false):
		return [_row("new_game", "Nouvelle partie : Clair-Foyer")]
	var m: int = roundi(report["t_eff"] * 60.0)
	var gold: int = report["gold_delta"]
	var out: Array = [_row("absence", "Absence : %d h %02d" % [m / 60, m % 60], "TEXT", "plafond" if report["t_eff"] >= BB.OFFLINE_MAX_HOURS else ""),
		_row("or", "Or : %s%s" % ["+" if gold >= 0 else "-", EqText.num(absi(gold))], "GOOD" if gold > 0 else ("BAD" if gold < 0 else "TEXT"))]
	if compact:
		return out
	if report["ticked"]:
		out.append(_row("frais", "Frais fixes du jour : %s Or" % EqText.num(report["fixed_cost_paid"])))
	if report["tools_replaced"] > 0:
		out.append(_row("outils", "Outils remplacés : %d" % report["tools_replaced"]))
	if report["strikes"] > 0:
		out.append(_row("greve", "PNJ en grève : %d" % report["strikes"], "BAD"))
	if not report["fiches"].is_empty():
		out.append(_row("fiches", "Fiches de rupture : %d" % report["fiches"].size()))
	return out
