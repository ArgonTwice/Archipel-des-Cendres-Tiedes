class_name Expedition
extends RefCounted
# Une expédition dans le segment de Brume (volet E §3) : Cendre Vive, Éclats, XP, en mémoire seulement.
# Saturation : une action n'est disponible que si son gain tient dans le reste du budget ; jamais de gain partiel.

const BA = preload("res://balance/balance_a.gd")
const RngS = preload("res://autoload/Rng.gd")
const CombatS = preload("res://scripts/combat/combat.gd")

var cendre: int = 0
var shards: int = 0
var kills: int = 0
var gathers: int = 0
var xp: int = 0
var _rng: RngS.Pcg32

# index : numéro de l'expédition dans la session (0, 1, 2…), non sauvegardé.
func _init(world_seed: int, index: int) -> void:
	_rng = RngS.make_rng(world_seed, "loot/eclats/%d" % index)

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
	xp += CombatS.kill_xp("NORMAL", isolat)
	cendre += BA.CENDRE_GAIN_NORMAL_MOB
	return _shard(BA.SHARD_DROP_CHANCE_NORMAL)

func on_gather(isolat: int) -> bool:
	assert(mist_open())
	gathers += 1
	xp += roundi(BA.XP_GATHER_MIST_NODE * BA.ISOLAT_XP_MULTIPLIERS[isolat])
	cendre += BA.CENDRE_GAIN_MIST_NODE
	return _shard(BA.SHARD_DROP_CHANCE_MIST_NODE)

# Le tirage a lieu même Sacoche pleine : le flux ne dépend pas du plafond.
func _shard(chance: float) -> bool:
	var drop: bool = _rng.next_float() < chance
	if drop and shards < BA.LANTERN_SHARD_BAG_CAP[0]:
		shards += 1
		return true
	return false
