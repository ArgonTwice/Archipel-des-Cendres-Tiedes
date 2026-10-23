class_name VeilleeReport
extends RefCounted
# Rapport de veillée (SOCLE §A4) : lignes affichées au lancement et au retour.
# report : sortie de SaveManager.boot / sync. compact (plié) : absence et Or seulement.

const BB = preload("res://balance/balance_b.gd")

static func lines(report: Dictionary, compact: bool) -> PackedStringArray:
	var out: PackedStringArray = []
	if report.get("new_game", false):
		out.append("Nouvelle partie : Clair-Foyer.")
		return out
	var m: int = roundi(report["t_eff"] * 60.0)
	var absence: String = "Absence comptée : %d h %02d" % [m / 60, m % 60]
	if report["t_eff"] >= BB.OFFLINE_MAX_HOURS:
		absence += " (plafond)"
	out.append(absence)
	out.append("Or : %+d" % report["gold_delta"])
	if compact:
		return out
	if report["ticked"]:
		out.append("Frais fixes du jour : %d Or" % report["fixed_cost_paid"])
	if report["tools_replaced"] > 0:
		out.append("Outils remplacés : %d" % report["tools_replaced"])
	if report["strikes"] > 0:
		out.append("PNJ en grève : %d" % report["strikes"])
	if not report["fiches"].is_empty():
		out.append("Fiches de rupture : %d" % report["fiches"].size())
	return out
