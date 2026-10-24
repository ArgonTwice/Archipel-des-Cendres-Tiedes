extends Node2D
# Lisière de Clair-Foyer (SOCLE §A1, §A3) : monstres de la route sud et auto-attaque du joueur à l'arrêt.
# Tout vit en mémoire : rien n'est écrit dans l'état de la partie. Ordre des opérations = jumeau Python (jalon 10).

const BA = preload("res://balance/balance_a.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const RngS = preload("res://autoload/Rng.gd")
const MobScene = preload("res://scenes/combat/mob.tscn")

const ROLE: String = "NORMAL"
const DENSITY_INDEX: int = 0

var _player: Node2D # player.gd
var _mobs: Array[Node2D] = []
var _rng: RngS.Pcg32
var _isolat: int = 0
var _mob_level: int = 1

# solid : celui du joueur, copié ; les cellules du rayon de l'Âtre s'y ajoutent pour les monstres.
func setup(world_seed: int, isolat: int, player: Node2D, solid: Dictionary, spawns: Array, texture: Texture2D, shadow: Texture2D) -> void:
	_player = player
	_isolat = isolat
	_mob_level = CombatS.mob_level(isolat)
	_rng = RngS.make_rng(world_seed, "combat/joueur")
	var mob_solid: Dictionary = solid.duplicate()
	mob_solid.merge(CombatS.village_cells())
	var stats: Dictionary = CombatS.mob_stats(_mob_level, DENSITY_INDEX, ROLE)
	for i in spawns.size():
		var mob: Node2D = MobScene.instantiate()
		add_child(mob)
		mob.index = i
		mob.setup(VL.cell_center(VL.v2i(spawns[i])), texture, shadow, mob_solid, stats)
		_mobs.append(mob)

# Règle d'or (SOCLE §A1) : jamais de cible dans le village ; ni pendant l'évacuation.
func _target_ok() -> bool:
	return not CombatS.in_village(_player.position) and not _player.is_evacuating()

func mobs() -> Array[Node2D]:
	return _mobs

func _process(delta: float) -> void:
	var target_ok: bool = _target_ok()
	for mob: Node2D in _mobs:
		if not mob.alive:
			mob.dead_t += delta
			if mob.dead_t >= BA.MOB_RESPAWN_DELAY_SEC and _player.position.distance_to(mob.home) > BA.MOB_AGGRO_RANGE_PX:
				mob.respawn()
				_log("reapparition", {"index": mob.index})
			continue
		if mob.step(delta, _player.position, target_ok):
			var dmg: int = CombatS.damage(mob.atk, _player.def, _mob_level, BA.MOB_CAN_CRIT) # aucun tirage : les monstres ne font jamais de critique
			if _player.take_hit(dmg):
				_log("coup_recu", {"source": mob.index, "degats": dmg, "pv": _player.hp})
			else:
				_log("esquive", {"source": mob.index})
			target_ok = _target_ok() # une mort lance l'évacuation
	if not _player.can_strike():
		return
	var alive: Array[Node2D] = []
	var points: Array[Vector2] = []
	for mob: Node2D in _mobs:
		if mob.alive:
			alive.append(mob)
			points.append(mob.position)
	var j: int = CombatS.nearest_in_range(_player.position, points, CombatS.starting_weapon_range())
	if j < 0:
		return
	var target: Node2D = alive[j]
	var crit: bool = CombatS.is_crit(_rng)
	var dmg: int = CombatS.damage(_player.atk, target.def, _player.level, crit)
	_player.strike(target.position)
	var killed: bool = target.take_hit(dmg)
	_log("coup", {"cible": target.index, "degats": dmg, "critique": crit, "pv": target.hp})
	if killed:
		_log("mort_monstre", {"index": target.index, "xp": CombatS.kill_xp(ROLE, _isolat)})

# Événements seulement ; build debug seulement.
func _log(event: String, extra: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	var d: Dictionary = {"event": event}
	d.merge(extra)
	print("[COMBAT] " + JSON.stringify(d))
