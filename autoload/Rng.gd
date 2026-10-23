extends Node
# Autoload « Rng » : FNV-1a 64 bits + PCG32 maison. Aucun appel à randi()/randf()/RandomNumberGenerator.
# Entropie : Crypto.generate_random_bytes (ni randi ni RandomNumberGenerator), une seule fois par nouvelle partie (entropy_seed).
# int GDScript = int64 signé ; la doc de int garantit le bouclage au débordement.
# La doc ne précise pas si >> est arithmétique ou logique sur les négatifs : tout >> est donc masqué.
# Les littéraux > 2^63 ne sont pas documentés : on les assemble depuis deux moitiés de 32 bits.

const FNV_OFFSET_BASIS: int = (0xcbf29ce4 << 32) | 0x84222325
const FNV_PRIME: int = 0x100000001b3
# VERROUILLÉ : changer cette valeur casse toutes les graines (cartes, loot, PNJ, sauvegardes).
const DEFAULT_STREAM: int = 54

static func fnv1a64(text: String) -> int:
	var h: int = FNV_OFFSET_BASIS
	for b: int in text.to_utf8_buffer():
		h = (h ^ b) * FNV_PRIME
	return h

# Seule source d'entropie, une fois par nouvelle partie ; tout le reste dérive de world_seed par make_rng.
static func entropy_seed() -> int:
	return Crypto.new().generate_random_bytes(8).decode_s64(0)

# Un RNG indépendant par système, initialisé par hash(world_seed + node_id).
static func make_rng(world_seed: int, node_id: String) -> Pcg32:
	return Pcg32.new(fnv1a64(str(world_seed) + node_id), DEFAULT_STREAM)

class Pcg32 extends RefCounted:
	const MULT: int = 6364136223846793005
	var _state: int = 0
	var _inc: int = 0

	func _init(seed_value: int, stream: int) -> void:
		_inc = (stream << 1) | 1
		_step()
		_state += seed_value
		_step()

	func _step() -> void:
		_state = _state * MULT + _inc

	func next_u32() -> int:
		var old: int = _state
		_step()
		var xorshifted: int = ((((old >> 18) & 0x3FFFFFFFFFFF) ^ old) >> 27) & 0xFFFFFFFF
		var rot: int = (old >> 59) & 31
		return ((xorshifted >> rot) | (xorshifted << ((32 - rot) & 31))) & 0xFFFFFFFF

	func next_float() -> float:
		return next_u32() / 4294967296.0

	# Inclusif, sans biais : rejet des valeurs sous le seuil.
	func range_int(min_value: int, max_value: int) -> int:
		var bound: int = max_value - min_value + 1
		assert(bound > 0 and bound <= 0x100000000)
		var threshold: int = (0x100000000 - bound) % bound
		var r: int = next_u32()
		while r < threshold:
			r = next_u32()
		return min_value + r % bound
