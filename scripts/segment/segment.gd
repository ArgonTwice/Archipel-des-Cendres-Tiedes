extends Node2D
# Segment de Brume de la tranche (SOCLE §A4, volet E §3) : 3 nœuds au sud du village, reliés par des passages en fondu.
# Un seul nœud actif (INHERIT), les autres DISABLED. Expédition en mémoire : rien n'est écrit dans l'état de la partie.
# Ordre dans une image : Joueur._process, puis Segment._process, puis le nœud actif (enfant de Segment).

signal expedition_changed(shown: bool, cendre: int, shards: int)

const SG = preload("res://scripts/segment/segment_gen.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const ExpeditionS = preload("res://scripts/segment/expedition.gd")
const LisiereS = preload("res://scripts/combat/lisiere.gd")

var expedition: ExpeditionS = null
var active: int = SG.VILLAGE
var last_end: String = "" # raison de la dernière fin d'expédition ("retour" | "mort")
var _player: Node2D # player.gd
var _nodes: Array[Node2D] = []
var _maps: Array[Dictionary] = []
var _village_solid: Dictionary = {}
var _passages: Dictionary = SG.passages()
var _world_seed: int = 0
var _isolat: int = 0
var _count: int = 0 # expéditions de la session, non sauvegardé
var _vitrified: bool = false
var _saturated: bool = false

func setup(world_seed: int, isolat: int, player: Node2D, village_solid: Dictionary, mob_texture: Texture2D,
		mist_texture: Texture2D, shadow: Texture2D, brazier: Node2D = null) -> void:
	_world_seed = world_seed
	_isolat = isolat
	_player = player
	_village_solid = village_solid
	for i in SG.NODE_FIRST_ROW.size():
		var map: Dictionary = SG.node_map(world_seed, i)
		_maps.append(map)
		var node: Node2D = LisiereS.new()
		node.name = "Noeud%d" % i
		node.y_sort_enabled = true
		add_child(node)
		var spawns: Array = []
		for c: Vector2i in map["mobs"]:
			spawns.append([c.x, c.y])
		node.setup(world_seed, isolat, player, SG.solid_cells(map), spawns, mob_texture, shadow, map["rect"], map["safe"])
		var mist: Array[Vector2i] = []
		mist.assign(map["mist"])
		node.add_mist_nodes(mist, mist_texture, shadow)
		node.killed.connect(_on_killed)
		node.gathered.connect(_on_gathered)
		node.process_mode = Node.PROCESS_MODE_DISABLED
		_nodes.append(node)
	if brazier != null:
		brazier.position = VL.cell_center(SG.brazier_cell())
		add_child(brazier)

func maps() -> Array[Dictionary]:
	return _maps

func nodes() -> Array[Node2D]:
	return _nodes

func active_node() -> Node2D:
	return _nodes[active] if active >= 0 else null

func _process(_delta: float) -> void:
	if not _player.in_fade():
		var cell: Vector2i = CombatS.cell_of(_player.position)
		if _passages.has(cell):
			var to: int = _passages[cell][0]
			var at: Vector2 = VL.cell_center(_passages[cell][1])
			if to == SG.VILLAGE:
				_player.travel(at, _village_solid, VL.GROUND_RECT)
			else:
				_player.travel(at, SG.solid_cells(_maps[to]), _maps[to]["rect"])
	var now: int = SG.node_index(CombatS.cell_of(_player.position))
	if now == active:
		return
	if active == SG.VILLAGE:
		_begin()
	elif now == SG.VILLAGE:
		_end("mort" if _player.is_evacuating() else "retour")
	active = now
	for i in _nodes.size():
		_nodes[i].process_mode = Node.PROCESS_MODE_INHERIT if i == active else Node.PROCESS_MODE_DISABLED

func _begin() -> void:
	expedition = ExpeditionS.new(_world_seed, _count)
	_count += 1
	_vitrified = false
	_saturated = false
	for node: Node2D in _nodes:
		node.reset()
	_log("debut", {"index": _count - 1})
	expedition_changed.emit(true, 0, 0)

func _end(reason: String) -> void:
	_log("fin", {"raison": reason, "cendre": expedition.cendre, "eclats": expedition.shards, "xp": expedition.xp,
		"kills": expedition.kills, "noeuds": expedition.gathers})
	last_end = reason
	expedition = null
	expedition_changed.emit(false, 0, 0)

func _on_killed(_index: int) -> void:
	if expedition == null or not expedition.normals_open():
		return # déjà dissipé
	expedition.on_kill(_isolat)
	_after_gain()

func _on_gathered(_index: int) -> void:
	if expedition == null or not expedition.mist_open():
		return
	expedition.on_gather(_isolat)
	_after_gain()

# Saturation de Brume (volet E §3) : nœuds vitrifiés dès qu'un nœud ne tient plus dans le reste, normaux dissipés
# dès qu'un kill ne tient plus. L'éveil de l'Élite viendra avec les aptitudes (jalon 12).
func _after_gain() -> void:
	expedition_changed.emit(true, expedition.cendre, expedition.shards)
	if not _vitrified and not expedition.mist_open():
		_vitrified = true
		for node: Node2D in _nodes:
			node.vitrify()
		_log("vitrification", {"cendre": expedition.cendre})
	if not _saturated and not expedition.normals_open():
		_saturated = true
		for node: Node2D in _nodes:
			node.dissipate()
		_log("saturation", {"cendre": expedition.cendre})
		_log("eveil_elite_reporte", {})

# Événements seulement ; build debug seulement.
func _log(event: String, extra: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	var d: Dictionary = {"event": event}
	d.merge(extra)
	print("[EXPEDITION] " + JSON.stringify(d))
