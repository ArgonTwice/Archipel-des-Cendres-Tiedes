extends Node2D
# Village de Clair-Foyer (rendu seul, SOCLE §A3, §A4 ; Volet D §4, §6) : tuiles, Grand Âtre, PNJ, jour / nuit.
# Construit une seule fois par setup ; refresh ne recalcule que les activités, les ancres et la lumière.
# Aucune écriture dans l'état de la partie. Couleurs et énergies : constantes techniques provisoires.

const VL = preload("res://scripts/village/village_layout.gd")
const BD = preload("res://balance/balance_d.gd")
const ClockS = preload("res://autoload/Clock.gd")
const NpcScene = preload("res://scenes/village/npc.tscn")

const REFRESH_SEC: float = 60.0
const PHASE_COLOR: Dictionary = {BD.DayPhase.DAWN: Color(0.82, 0.76, 0.8), BD.DayPhase.DAY: Color(1, 1, 1),
	BD.DayPhase.DUSK: Color(0.78, 0.64, 0.62), BD.DayPhase.NIGHT: Color(0.3, 0.33, 0.5)}
const PHASE_LIGHT_ENERGY: Dictionary = {BD.DayPhase.DAWN: 0.6, BD.DayPhase.DAY: 0.3, BD.DayPhase.DUSK: 0.8, BD.DayPhase.NIGHT: 1.1}
const FLICKER: Array[Vector2] = [Vector2(0.06, 7.3), Vector2(0.04, 12.9)] # [amplitude, pulsation rad/s]
const TILE_SORT_ORIGIN: int = 8 # bas de la tuile
const FLAT_SORT_ORIGIN: int = -8 # haut de la tuile : touffes toujours sous un PNJ debout dans la cellule
const SHADOW_SIZE: Vector2i = Vector2i(12, 4)
const SHADOW_ALPHA: float = 0.35

@onready var _day: CanvasModulate = $Jour
@onready var _ground: TileMapLayer = $Sol
@onready var _paths: TileMapLayer = $Chemins
@onready var _entities: Node2D = $Entites
@onready var _buildings: TileMapLayer = $Entites/Batiments
@onready var _deco: TileMapLayer = $Entites/Deco
@onready var _torch: Sprite2D = $Entites/Atre/Torche
@onready var _light: PointLight2D = $Entites/Atre/Lumiere
@onready var _player: Node2D = $Entites/Joueur # player.gd
@onready var _lisiere: Node2D = $Entites/Lisiere # lisiere.gd

var hour_override: int = -1 # debug (--hour=H) : rendu et ancres seulement
var _data: Dictionary = {}
var _tiles: Dictionary = {} # nom -> [source_id, atlas_coords]
var _village: Dictionary = {}
var _npcs: Array[Node2D] = []
var _acts: Array = []
var _base_energy: float = 0.0
var _t: float = 0.0

func setup(world_seed: int, village: Dictionary, now_utc: int) -> void:
	_data = VL.load_data()
	var ts: TileSet = _build_tileset()
	for layer: TileMapLayer in [_ground, _paths, _buildings, _deco]:
		layer.tile_set = ts
	var sites: Dictionary = _data["sites"]
	var patterns: Dictionary = _data["patterns"]
	for y in range(VL.GROUND_RECT.position.y, VL.GROUND_RECT.end.y):
		for x in range(VL.GROUND_RECT.position.x, VL.GROUND_RECT.end.x):
			_paint(_ground, Vector2i(x, y), "herbe")
	var p: Dictionary = VL.paths(sites, patterns)
	for c: Vector2i in p["cells"]:
		_paint(_paths, c, "chemin")
	for key: String in sites:
		var tiles: Dictionary = VL.site_tiles(sites[key], patterns)
		for c: Vector2i in tiles:
			# Le dallage de l'Âtre est un sol : sur Chemins, sinon son tri y le ferait passer devant la torche.
			_paint(_paths if key == "ATRE" else _buildings, c, tiles[c])
	var blocked: Dictionary = VL.built_cells(sites, patterns)
	blocked.merge(p["cells"])
	for prop: Dictionary in _data["props"]:
		_paint(_deco, VL.v2i(prop["cell"]), prop["tile"])
		blocked[VL.v2i(prop["cell"])] = true
	var deco: Dictionary = VL.deco(world_seed, blocked)
	for c: Vector2i in deco:
		var names: Array = _data["trees"] if deco[c][0] == "tree" else _data["tufts"]
		_paint(_deco, c, names[deco[c][1] % names.size()])
	var shadow: ImageTexture = _shadow_texture()
	$Entites/Atre/Ombre.texture = shadow
	_torch.texture = _tile_texture("torche")
	var solid: Dictionary = VL.solid_cells(sites, patterns, _data["props"], deco)
	_player.setup(VL.cell_center(VL.PLAYER_SPAWN_CELL), _tile_texture(_data["player_sprite"]), shadow, solid)
	var lis: Dictionary = _data["lisiere"]
	_lisiere.setup(world_seed, village.get("isolat", 0), _player, solid, lis["spawns"], _tile_texture(lis["mob_sprite"]), shadow)
	_village = village
	var npcs: Array = village.get("npcs", [])
	var hour: int = _hour(now_utc)
	_acts = _activities(hour)
	var anchors: Array[Vector2] = VL.anchors(_acts, npcs, sites)
	for i in npcs.size():
		var npc: Node2D = NpcScene.instantiate()
		_entities.add_child(npc)
		npc.setup(i, world_seed, _tile_texture(_data["npc_sprites"][i]), shadow, anchors[i], _acts[i] != "SLEEP")
		_npcs.append(npc)
	_apply_phase(hour)
	_log("setup", hour, anchors)
	var timer: Timer = Timer.new()
	timer.wait_time = REFRESH_SEC
	timer.timeout.connect(func() -> void: refresh(_village, ClockS.now_utc()))
	add_child(timer)
	timer.start()

func player() -> Node2D:
	return _player

# Combat gelé en déplié (SOCLE §A3 : déplié = gérer).
func set_combat_active(on: bool) -> void:
	_lisiere.set_active(on)

func refresh(village: Dictionary, now_utc: int) -> void:
	if _data.is_empty():
		return
	_village = village
	var hour: int = _hour(now_utc)
	_apply_phase(hour)
	if _npcs.is_empty():
		return
	var acts: Array = _activities(hour)
	var anchors: Array[Vector2] = VL.anchors(acts, village["npcs"], _data["sites"])
	for i in _npcs.size():
		_npcs[i].set_anchor(anchors[i], acts[i] != "SLEEP")
	if acts != _acts:
		_acts = acts
		_log("activite", hour, anchors)

func _process(delta: float) -> void:
	_t += delta
	var k: float = 1.0
	for f: Vector2 in FLICKER:
		k += f.x * sin(_t * f.y)
	_light.energy = _base_energy * k

func _hour(now_utc: int) -> int:
	return hour_override if hour_override >= 0 else VL.local_hour(now_utc, _village.get("tz_offset_sec", 0))

func _activities(hour: int) -> Array:
	var out: Array = []
	for npc: Dictionary in _village.get("npcs", []):
		out.append(VL.npc_activity(hour, npc))
	return out

func _apply_phase(hour: int) -> void:
	var phase: int = VL.day_phase(hour)
	_day.color = PHASE_COLOR[phase]
	_base_energy = PHASE_LIGHT_ENERGY[phase]

# Un TileSetAtlasSource par atlas, une tuile créée par nom de village.json.
func _build_tileset() -> TileSet:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(VL.CELL, VL.CELL)
	var sources: Dictionary = {}
	for atlas: String in _data["atlases"]:
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = load(_data["atlases"][atlas])
		src.texture_region_size = Vector2i(VL.CELL, VL.CELL)
		sources[atlas] = [ts.add_source(src), src]
	for tile_name: String in _data["tiles"]:
		var t: Array = _data["tiles"][tile_name]
		var src: TileSetAtlasSource = sources[t[0]][1]
		var cols: int = src.texture.get_width() / VL.CELL
		var coords: Vector2i = Vector2i(int(t[1]) % cols, int(t[1]) / cols)
		if not src.has_tile(coords):
			src.create_tile(coords)
		src.get_tile_data(coords, 0).y_sort_origin = FLAT_SORT_ORIGIN if tile_name in _data["tufts"] else TILE_SORT_ORIGIN
		_tiles[tile_name] = [sources[t[0]][0], coords]
	return ts

func _paint(layer: TileMapLayer, cell: Vector2i, tile_name: String) -> void:
	layer.set_cell(cell, _tiles[tile_name][0], _tiles[tile_name][1])

func _tile_texture(tile_name: String) -> AtlasTexture:
	var t: Array = _data["tiles"][tile_name]
	var tex: AtlasTexture = AtlasTexture.new()
	tex.atlas = load(_data["atlases"][t[0]])
	var cols: int = tex.atlas.get_width() / VL.CELL
	tex.region = Rect2(Vector2(int(t[1]) % cols, int(t[1]) / cols) * VL.CELL, Vector2(VL.CELL, VL.CELL))
	return tex

# Ellipse pleine, noire, alpha 0,35, pixels nets ; générée une fois, partagée par les PNJ et la torche.
static func _shadow_texture() -> ImageTexture:
	var img: Image = Image.create_empty(SHADOW_SIZE.x, SHADOW_SIZE.y, false, Image.FORMAT_RGBA8)
	var r: Vector2 = Vector2(SHADOW_SIZE) / 2.0
	for y in SHADOW_SIZE.y:
		for x in SHADOW_SIZE.x:
			var d: Vector2 = (Vector2(x, y) + Vector2(0.5, 0.5) - r) / r
			if d.length_squared() <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, SHADOW_ALPHA))
	return ImageTexture.create_from_image(img)

func _log(event: String, hour: int, anchors: Array[Vector2]) -> void:
	if not OS.is_debug_build():
		return
	var pnj: Array = []
	for i in _npcs.size():
		pnj.append([i, _village["npcs"][i]["post"], _acts[i], [anchors[i].x, anchors[i].y], _acts[i] != "SLEEP"])
	print("[VILLAGE] " + JSON.stringify({"event": event, "heure": hour, "phase": BD.DayPhase.find_key(VL.day_phase(hour)), "pnj": pnj}))
