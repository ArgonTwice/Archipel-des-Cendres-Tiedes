extends Node2D
# Combat et récolte d'un nœud (SOCLE §A1, §A3, §A4 ; volet E) : monstres, auto-attaque à l'arrêt, nœuds de Brume.
# Tout vit en mémoire : rien n'est écrit dans l'état de la partie. Ordre des opérations = jumeau Python (jalons 10, 11).

signal killed(index: int, role: String)
signal gathered(index: int)

const BA = preload("res://balance/balance_a.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const RngS = preload("res://autoload/Rng.gd")
const MobScene = preload("res://scenes/combat/mob.tscn")
const MistScene = preload("res://scenes/segment/mist_node.tscn")
const MistS = preload("res://scripts/segment/mist_node.gd")
const PlayerS = preload("res://scripts/player/player.gd")

const DENSITY_INDEX: int = 0

var _player: Node2D # player.gd
var _mobs: Array[Node2D] = []
var _mist: Array[Node2D] = []
var _rng: RngS.Pcg32
var _isolat: int = 0
var _mob_level: int = 1
var _dissipated: bool = false
var _elite: Node2D = null
var _mob_solid: Dictionary = {}
var _bounds: Rect2i = VL.GROUND_RECT

# solid : celui du joueur, copié ; les cellules du rayon de l'Âtre et mob_extra (zone sûre du Brasero) s'y ajoutent
# pour les monstres. bounds : bord du monde des monstres.
func setup(world_seed: int, isolat: int, player: Node2D, solid: Dictionary, spawns: Array, texture: Texture2D, shadow: Texture2D,
		bounds: Rect2i = VL.GROUND_RECT, mob_extra: Dictionary = {}) -> void:
	_player = player
	_isolat = isolat
	_mob_level = CombatS.mob_level(isolat)
	_rng = RngS.make_rng(world_seed, "combat/joueur")
	_mob_solid = solid.duplicate()
	_mob_solid.merge(CombatS.village_cells())
	_mob_solid.merge(mob_extra)
	_bounds = bounds
	for i in spawns.size():
		_add_mob(VL.cell_center(VL.v2i(spawns[i])), "NORMAL", texture, shadow)

# Élite porteur de braise (volet E §3) : endormi jusqu'à la saturation, jamais de réapparition dans l'expédition.
func add_elite(cell: Vector2i, texture: Texture2D, shadow: Texture2D) -> Node2D:
	_elite = _add_mob(VL.cell_center(cell), "ELITE", texture, shadow)
	_elite.sleep()
	return _elite

func elite() -> Node2D:
	return _elite

func wake_elite() -> void:
	if _elite != null and _elite.alive:
		_elite.wake()
		_log("eveil_elite", {"index": _elite.index})

func _add_mob(home: Vector2, role: String, texture: Texture2D, shadow: Texture2D) -> Node2D:
	var mob: Node2D = MobScene.instantiate()
	add_child(mob)
	mob.index = _mobs.size()
	mob.role = role
	mob.setup(home, texture, shadow, _mob_solid, CombatS.mob_stats(_mob_level, DENSITY_INDEX, role), _bounds)
	_mobs.append(mob)
	return mob

func add_mist_nodes(cells: Array[Vector2i], texture: Texture2D, shadow: Texture2D) -> void:
	for c: Vector2i in cells:
		var node: Node2D = MistScene.instantiate()
		add_child(node)
		node.index = _mist.size()
		node.setup(c, texture, shadow)
		_mist.append(node)

func mobs() -> Array[Node2D]:
	return _mobs

func mist_nodes() -> Array[Node2D]:
	return _mist

# Niveau du segment figé au départ de l'expédition (n°37) : stats des monstres et de l'Élite, dégâts reçus.
func set_mob_level(level: int) -> void:
	_mob_level = level
	for mob: Node2D in _mobs:
		mob.set_stats(CombatS.mob_stats(level, DENSITY_INDEX, mob.role))

func mob_level() -> int:
	return _mob_level

# Saturation (volet E) : normaux dissipés, plus aucune réapparition. L'Élite n'est pas dissipé.
func dissipate() -> void:
	_dissipated = true
	for mob: Node2D in _mobs:
		if mob.alive and mob.role != "ELITE":
			mob.alive = false
			mob.visible = false
	_log("dissipation", {})

func vitrify() -> void:
	for node: Node2D in _mist:
		if node.state == MistS.State.AVAILABLE:
			node.set_state(MistS.State.VITRIFIED)

# Début d'expédition : monstres et nœuds remis à neuf.
func reset() -> void:
	_dissipated = false
	for mob: Node2D in _mobs:
		if mob == _elite:
			mob.sleep()
		else:
			mob.respawn()
	for node: Node2D in _mist:
		node.set_state(MistS.State.AVAILABLE)

# Règle d'or (SOCLE §A1) : jamais de cible en zone sûre (village, Brasero), ni pendant un fondu.
func _target_ok() -> bool:
	return not CombatS.in_safe_zone(_player.position) and not _player.in_fade()

func _process(delta: float) -> void:
	var target_ok: bool = _target_ok()
	for mob: Node2D in _mobs:
		if mob.dormant:
			continue
		if not mob.alive:
			if _dissipated or mob.role == "ELITE":
				continue
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
	var alive: Array[Node2D] = []
	var points: Array[Vector2] = []
	var chased: bool = false
	for mob: Node2D in _mobs:
		if mob.alive and not mob.dormant:
			alive.append(mob)
			points.append(mob.position)
			chased = chased or mob.chasing
	_player.show_range(chased and not _player.in_fade())
	var j: int = CombatS.nearest_in_range(_player.position, points, CombatS.starting_weapon_range())
	if j >= 0 and _player.can_strike():
		_strike(alive[j])
	_gather(delta, j >= 0)

# Un créneau de frappe : l'aptitude armée et prête part à la place de l'auto (1 d'abord), même tirage de critique ;
# seuls les coups d'auto réduisent les recharges (Volet A §4, facteur de cycle 1,689).
func _strike(target: Node2D) -> void:
	var skill: int = _player.take_ready_skill()
	var crit: bool = CombatS.is_crit(_rng, _player.crit_rate)
	var m_comp: float = 1.0
	if skill >= 0:
		m_comp = [BA.SKILL_1_DMG_MULT, BA.SKILL_2_DMG_MULT][skill]
	var dmg: int = CombatS.damage(_player.atk, target.def, _player.level, crit, m_comp, 1.0, _player.crit_mult)
	_player.strike(target.position)
	var dead: bool = target.take_hit(dmg)
	if skill >= 0:
		_player.on_skill_fired(skill)
		_log("aptitude", {"index": skill, "cible": target.index, "degats": dmg, "critique": crit, "pv": target.hp})
	else:
		_player.on_auto_hit()
		_log("coup", {"cible": target.index, "degats": dmg, "critique": crit, "pv": target.hp})
	if dead:
		_log("mort_monstre", {"index": target.index, "role": target.role, "xp": CombatS.kill_xp(target.role, _isolat)})
		killed.emit(target.index, target.role)

# Récolte à l'arrêt, hors fondu, sans monstre à portée de l'arme : le nœud disponible le plus proche progresse,
# tous les autres retombent à 0.
func _gather(delta: float, mob_in_range: bool) -> void:
	var best: int = -1
	if _player.state == PlayerS.State.IDLE and not _player.in_fade() and not mob_in_range:
		var best_d: float = INF
		for node: Node2D in _mist:
			var d: float = _player.position.distance_to(node.position)
			if node.state == MistS.State.AVAILABLE and d <= MistS.GATHER_RANGE_PX and d < best_d:
				best = node.index
				best_d = d
	for node: Node2D in _mist:
		if node.index != best:
			node.set_progress(0.0)
	if best < 0:
		return
	var node: Node2D = _mist[best]
	node.set_progress(node.progress + delta)
	if node.progress >= MistS.GATHER_SEC:
		node.set_state(MistS.State.GATHERED)
		_log("recolte", {"index": best})
		gathered.emit(best)

# Événements seulement ; build debug seulement.
func _log(event: String, extra: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	var d: Dictionary = {"event": event}
	d.merge(extra)
	print("[COMBAT] " + JSON.stringify(d))
