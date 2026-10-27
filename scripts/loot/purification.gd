extends RefCounted
# Purification d'un Éclat (Volet F §1) : 1 Éclat -> 1 pièce, aperçu sans effet sur l'état, puis Équiper ou Jeter.
# Le tirage est nommé par purify_n : fermer l'aperçu ou relancer l'appli redonne la même pièce. Statiques pures.

const BA = preload("res://balance/balance_a.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const EquipmentS = preload("res://scripts/loot/equipment.gd")

# Éclats d'Élite d'abord. PROPOSÉ, à valider (jalon 15)
static func next_is_elite(player: Dictionary) -> bool:
	return player["shards_elite"] > 0

static func has_shard(player: Dictionary) -> bool:
	return player["shards"] + player["shards_elite"] > 0

static func ilvl_for(isolat: int) -> int:
	var r: Vector2i = BA.ISOLAT_LEVEL_RANGES[isolat]
	return clampi(CombatS.mob_level(isolat), r.x, r.y)

static func preview(world_seed: int, player: Dictionary, isolat: int) -> Dictionary:
	return EquipmentS.roll(world_seed, player["purify_n"], next_is_elite(player), ilvl_for(isolat))

# Consomme l'Éclat et avance purify_n ; equip : la pièce remplace celle de son emplacement (pas encore d'inventaire,
# l'ancienne disparaît. PROPOSÉ, à valider (jalon 15)). Rend le log « purification ».
static func commit(player: Dictionary, piece: Dictionary, equip: bool, place: String) -> Dictionary:
	var elite: bool = next_is_elite(player)
	if elite:
		player["shards_elite"] -= 1
	else:
		player["shards"] -= 1
	var n: int = player["purify_n"]
	player["purify_n"] += 1
	if equip:
		player["equipment"][piece["slot"]] = piece.duplicate(true)
	var affixes: Array = []
	for a: Dictionary in piece["affixes"]:
		affixes.append([a["id"], snappedf(a["units"], 0.0001)])
	return {"event": "purification", "n": n, "source": "ELITE" if elite else "NORMAL", "lieu": place, "slot": piece["slot"],
		"rarete": piece["rarity"], "ilvl": piece["ilvl"], "ecoles": piece["schools"], "affixes": affixes, "choix": "equiper" if equip else "jeter"}
