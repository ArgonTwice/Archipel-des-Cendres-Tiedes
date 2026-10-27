extends Node2D
# Segment de Brume de la tranche (SOCLE §A4, volet E §3) : 3 nœuds au sud du village, reliés par des passages en fondu.
# Un seul nœud actif (INHERIT), les autres DISABLED. Expédition en mémoire, sauf l'XP de vocation (jalon 13), écrite
# dans le dictionnaire du joueur rendu par player_ref.
# Ordre dans une image : Joueur._process, puis Segment._process, puis le nœud actif (enfant de Segment).

signal expedition_changed(shown: bool, cendre: int, shards: int)
signal leveled(voc: String, level: int)
signal xp_changed
signal expedition_ended(reason: String) # main.gd écrit alors la sauvegarde, sans attendre un pliage

const SG = preload("res://scripts/segment/segment_gen.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const CombatS = preload("res://scripts/combat/combat.gd")
const ExpeditionS = preload("res://scripts/segment/expedition.gd")
const LisiereS = preload("res://scripts/combat/lisiere.gd")
const BA = preload("res://balance/balance_a.gd")
const ProgressionS = preload("res://scripts/progression.gd")
const BF = preload("res://balance/balance_f.gd")

var expedition: ExpeditionS = null
var active: int = SG.VILLAGE
var last_end: String = "" # raison de la dernière fin d'expédition ("retour" | "mort")
var _player: Node2D # player.gd
var _nodes: Array[Node2D] = []
var _maps: Array[Dictionary] = []
var _player_solids: Array[Dictionary] = [] # partagés avec le joueur : la cellule de l'Élite s'y ajoute tant qu'il dort
var _village_solid: Dictionary = {}
var _passages: Dictionary = SG.passages()
var _world_seed: int = 0
var _isolat: int = 0
var _count: int = 0 # expéditions de la session, non sauvegardé
var _vitrified: bool = false
var _saturated: bool = false
var _player_ref: Callable

func setup(world_seed: int, isolat: int, player: Node2D, village_solid: Dictionary, mob_texture: Texture2D,
		mist_texture: Texture2D, shadow: Texture2D, player_ref: Callable, brazier: Node2D = null, elite_texture: Texture2D = null) -> void:
	_world_seed = world_seed
	_player_ref = player_ref
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
		var base: Dictionary = SG.solid_cells(map)
		node.setup(world_seed, isolat, player, base, spawns, mob_texture, shadow, map["rect"], map["safe"])
		var mist: Array[Vector2i] = []
		mist.assign(map["mist"])
		node.add_mist_nodes(mist, mist_texture, shadow)
		var player_solid: Dictionary = base.duplicate()
		if i == BA.SEGMENT_ELITE_NODE_INDEX:
			node.add_elite(SG.elite_cell(), elite_texture, shadow)
			player_solid[SG.elite_cell()] = true
		_player_solids.append(player_solid)
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
				_player.travel(at, _player_solids[to], _maps[to]["rect"])
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
	expedition = ExpeditionS.new(_world_seed, _count, _player_ref)
	expedition.leveled.connect(_on_leveled)
	_count += 1
	_vitrified = false
	_saturated = false
	for node: Node2D in _nodes:
		node.reset()
	_player_solids[BA.SEGMENT_ELITE_NODE_INDEX][SG.elite_cell()] = true # l'Élite se rendort : sa cellule redevient pleine
	_log("debut", {"index": _count - 1})
	expedition_changed.emit(true, 0, 0)

func _end(reason: String) -> void:
	_log("fin", {"raison": reason, "cendre": expedition.cendre, "eclats": expedition.shards, "xp": expedition.xp,
		"kills": expedition.kills, "noeuds": expedition.gathers})
	last_end = reason
	expedition = null
	expedition_changed.emit(false, 0, 0)
	expedition_ended.emit(reason)

func _on_leveled(voc: String, level: int) -> void:
	_log("niveau", {"vocation": voc, "niveau": level, "xp": _player_ref.call()["voc_xp"][voc]})
	if voc == "COMBATTANT":
		_player.set_level(level)
	leveled.emit(voc, level)

func _on_killed(_index: int, role: String) -> void:
	if expedition == null:
		return
	if role == "ELITE":
		expedition.on_elite(_isolat)
		_log("mort_elite", {"cendre": expedition.cendre, "eclats": expedition.shards})
		expedition_changed.emit(true, expedition.cendre, expedition.shards)
		xp_changed.emit()
		return
	if not expedition.normals_open():
		return # déjà dissipé
	expedition.on_kill(_isolat)
	_after_gain()

func _on_gathered(_index: int) -> void:
	if expedition == null or not expedition.mist_open():
		return
	expedition.on_gather(_isolat)
	_after_gain()

# Purification d'Éclat (Volet F §1) : "VILLAGE" sans limite, "BRASERO" pendant une expédition dans la limite
# SHARD_PURIFY_BRAZIER_MAX_PER_RUN, "" ailleurs.
func purify_place(pos: Vector2) -> String:
	if CombatS.in_village(pos):
		return "VILLAGE"
	if expedition != null and SG.in_brazier_zone(CombatS.cell_of(pos)) and expedition.brazier_purified < BF.SHARD_PURIFY_BRAZIER_MAX_PER_RUN:
		return "BRASERO"
	return ""

func on_purified(place: String) -> void:
	if place == "BRASERO" and expedition != null:
		expedition.brazier_purified += 1

# Saturation de Brume (volet E §3) : nœuds vitrifiés dès qu'un nœud ne tient plus dans le reste, normaux dissipés
# dès qu'un kill ne tient plus ; l'Élite s'éveille alors et sa cellule est libérée.
func _after_gain() -> void:
	expedition_changed.emit(true, expedition.cendre, expedition.shards)
	xp_changed.emit()
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
		_nodes[BA.SEGMENT_ELITE_NODE_INDEX].wake_elite()
		_player_solids[BA.SEGMENT_ELITE_NODE_INDEX].erase(SG.elite_cell())
		_log("eveil_elite", {})

# Événements seulement ; build debug seulement.
func _log(event: String, extra: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	var d: Dictionary = {"event": event}
	d.merge(extra)
	print("[EXPEDITION] " + JSON.stringify(d))
