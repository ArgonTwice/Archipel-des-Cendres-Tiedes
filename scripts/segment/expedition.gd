class_name Expedition
extends RefCounted
# Une expédition dans le segment de Brume (volet E §3) : l'XP de vocation (jalon 13), la Cendre Vive et les Éclats
# (Lanterne, jalon 14) vont dans l'état du joueur, sauvegardé ; le compteur de l'expédition reste en mémoire.
# Saturation : une action n'est disponible que si son gain tient dans le reste du budget ; jamais de gain partiel.

const BA = preload("res://balance/balance_a.gd")
const RngS = preload("res://autoload/Rng.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const BB = preload("res://balance/balance_b.gd")
const BF = preload("res://balance/balance_f.gd")

signal leveled(voc: String, level: int)

var cendre: int = 0
var shards: int = 0
var kills: int = 0
var gathers: int = 0
var xp: int = 0 # total de l'expédition, pour le log
var shards_refused: int = 0 # Éclats tombés Sacoche pleine
var brazier_purified: int = 0 # purifications au Brasero dans cette expédition (jalon 15)
var mob_level: int = 1 # niveau du segment, figé au départ (n°37) : ilvl des Éclats ramassés
var cargo: int = 0 # unités de minerai portées (jalon 16) : au coffre au retour, dans la caisse à la mort
var _rng: RngS.Pcg32
var _player_ref: Callable

# index : numéro de l'expédition dans la session (0, 1, 2…), non sauvegardé.
# player_ref rend le dictionnaire courant du joueur, relu à chaque gain : SaveManager.sync remplace l'état à chaque
# pliage, une référence gardée deviendrait périmée.
func _init(world_seed: int, index: int, player_ref: Callable, level: int = 1) -> void:
	_rng = RngS.make_rng(world_seed, "loot/eclats/%d" % index)
	_player_ref = player_ref
	mob_level = level

func remaining() -> int:
	return BA.SEGMENT_PRE_ELITE_CENDRE_BUDGET - cendre

func normals_open() -> bool:
	return BA.CENDRE_GAIN_NORMAL_MOB <= remaining()

func mist_open() -> bool:
	return BA.CENDRE_GAIN_MIST_NODE <= remaining()

# Rend vrai si un Éclat tombe.
func on_kill(isolat: int) -> bool:
	assert(normals_open())
	kills += 1
	_gain("COMBATTANT", CombatS.kill_xp("NORMAL", isolat))
	_cendre(BA.CENDRE_GAIN_NORMAL_MOB)
	return _shard(BA.SHARD_DROP_CHANCE_NORMAL, false)

func on_gather(isolat: int) -> bool:
	assert(mist_open())
	gathers += 1
	_gain("MINEUR", floori(BA.XP_GATHER_MIST_NODE * BA.ISOLAT_XP_MULTIPLIERS[isolat]))
	_cendre(BA.CENDRE_GAIN_MIST_NODE)
	var dropped: bool = _shard(BA.SHARD_DROP_CHANCE_MIST_NODE, false)
	var added: int = mini(BF.MIST_NODE_MINERAL_YIELD, cargo_room())
	cargo += added
	if added < BF.MIST_NODE_MINERAL_YIELD: # validé sur Fold (jalon 16)
		_log("cargaison_pleine", {"perdu": BF.MIST_NODE_MINERAL_YIELD - added})
	return dropped

# Cargaison max (Volet A §5) au niveau de Mineur courant, en kg.
static func cargo_cap_kg(player: Dictionary) -> float:
	return BA.PLAYER_BASE_CARGO_KG + BA.PLAYER_CARGO_KG_PER_MINER_LVL * (ProgressionS.level_of(player["voc_xp"]["MINEUR"]) - 1)

static func ore_kg() -> float:
	return BB.ITEM_WEIGHT_KG[BF.MIST_NODE_MINERAL_ITEM_ID]

# Place restante en unités entières (1e-9 : 25 + 0,2 × 5 ne doit pas tomber à 25,999…).
func cargo_room() -> int:
	return maxi(0, floori((cargo_cap_kg(_player_ref.call()) - cargo * ore_kg()) / ore_kg() + 1e-9))

# Élite porteur de braise : la Cendre ne dépasse jamais SEGMENT_STD_RUN_CENDRE_CAP ; Éclat garanti (chance 1,0).
func on_elite(isolat: int) -> bool:
	assert(cendre + BA.CENDRE_GAIN_ELITE_MOB <= BA.SEGMENT_STD_RUN_CENDRE_CAP)
	kills += 1
	var p: Dictionary = _player_ref.call()
	p["elite_kills"] = p.get("elite_kills", 0) + 1
	_gain("COMBATTANT", CombatS.kill_xp("ELITE", isolat))
	_cendre(BA.CENDRE_GAIN_ELITE_MOB)
	return _shard(BA.SHARD_DROP_CHANCE_ELITE, true)

func _gain(voc: String, base_xp: int) -> void:
	var g: Dictionary = ProgressionS.gain(_player_ref.call(), voc, base_xp)
	xp += g["gained"]
	if g["level_after"] > g["level_before"]:
		leveled.emit(voc, g["level_after"])

# Compteur de l'expédition (budget, saturation) et Lanterne, plafonnée : le surplus est perdu.
func _cendre(amount: int) -> void:
	cendre += amount
	var p: Dictionary = _player_ref.call()
	var added: int = mini(amount, BA.LANTERN_CENDRE_CAP[0] - p["cendre"])
	p["cendre"] += added
	if added < amount:
		_log("lanterne_pleine", {"perdu": amount - added})

# Le tirage a lieu même Sacoche pleine : le flux ne dépend pas du plafond. La Sacoche (Éclats normaux + d'Élite)
# plafonne, pas l'expédition ; chaque Éclat garde le niveau du segment (jalon 15 bis).
func _shard(chance: float, elite: bool) -> bool:
	if _rng.next_float() >= chance:
		return false
	var p: Dictionary = _player_ref.call()
	if p["shard_bag"].size() >= BA.LANTERN_SHARD_BAG_CAP[0]:
		shards_refused += 1
		_log("sacoche_pleine", {})
		return false
	p["shard_bag"].append({"elite": elite, "ilvl": mob_level})
	shards += 1
	return true

# Événements seulement ; build debug seulement.
func _log(event: String, extra: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	var d: Dictionary = {"event": event}
	d.merge(extra)
	print("[EXPEDITION] " + JSON.stringify(d))
