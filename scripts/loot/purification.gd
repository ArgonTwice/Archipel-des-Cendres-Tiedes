extends RefCounted
# Purification d'un Éclat (Volet F §1) : 1 Éclat -> 1 pièce, aperçu sans effet sur l'état, puis Équiper ou Jeter.
# Le tirage est nommé par purify_n : fermer l'aperçu ou relancer l'appli redonne la même pièce. Statiques pures.

const EquipmentS = preload("res://scripts/loot/equipment.gd")

# Éclat purifié : l'Élite d'abord, puis l'ilvl le plus haut, puis le premier de la Sacoche ; -1 si vide (jalon 15 bis).
static func next_index(player: Dictionary) -> int:
	var bag: Array = player["shard_bag"]
	var best: int = -1
	for i in bag.size():
		if best < 0 or (bag[i]["elite"] and not bag[best]["elite"]) or (bag[i]["elite"] == bag[best]["elite"] and bag[i]["ilvl"] > bag[best]["ilvl"]):
			best = i
	return best

static func has_shard(player: Dictionary) -> bool:
	return not player["shard_bag"].is_empty()

# L'ilvl de la pièce est celui de l'Éclat.
static func preview(world_seed: int, player: Dictionary) -> Dictionary:
	var shard: Dictionary = player["shard_bag"][next_index(player)]
	return EquipmentS.roll(world_seed, player["purify_n"], shard["elite"], shard["ilvl"])

# Consomme l'Éclat et avance purify_n ; equip : la pièce remplace celle de son emplacement (pas encore d'inventaire,
# l'ancienne disparaît. PROPOSÉ, à valider (jalon 15)). Rend le log « purification ».
static func commit(player: Dictionary, piece: Dictionary, equip: bool, place: String) -> Dictionary:
	var elite: bool = player["shard_bag"].pop_at(next_index(player))["elite"]
	var n: int = player["purify_n"]
	player["purify_n"] += 1
	if equip:
		player["equipment"][piece["slot"]] = piece.duplicate(true)
	var affixes: Array = []
	for a: Dictionary in piece["affixes"]:
		affixes.append([a["id"], snappedf(a["units"], 0.0001)])
	return {"event": "purification", "n": n, "source": "ELITE" if elite else "NORMAL", "lieu": place, "slot": piece["slot"],
		"rarete": piece["rarity"], "ilvl": piece["ilvl"], "ecoles": piece["schools"], "affixes": affixes, "choix": "equiper" if equip else "jeter"}
