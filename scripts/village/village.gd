extends Node2D
# Village de Clair-Foyer (rendu seul, SOCLE §A3, §A4 ; Volet D §4, §6) : tuiles, Grand Âtre, PNJ, jour / nuit.
# Construit une seule fois par setup ; refresh ne recalcule que les activités, les ancres et la lumière.
# Aucune écriture dans l'état de la partie. Couleurs et énergies : constantes techniques provisoires.

const VL = preload("res://scripts/village/village_layout.gd")
const BD = preload("res://balance/balance_d.gd")
const ClockS = preload("res://autoload/Clock.gd")
const NpcScene = preload("res://scenes/village/npc.tscn")
const SG = preload("res://scripts/segment/segment_gen.gd")
const UiStyle = preload("res://scripts/ui/ui_style.gd")

const REFRESH_SEC: float = 60.0
const PHASE_COLOR: Dictionary = {BD.DayPhase.DAWN: Color(0.82, 0.76, 0.8), BD.DayPhase.DAY: Color(1, 1, 1),
	BD.DayPhase.DUSK: Color(0.78, 0.64, 0.62), BD.DayPhase.NIGHT: Color(0.3, 0.33, 0.5)}
const PHASE_LIGHT_ENERGY: Dictionary = {BD.DayPhase.DAWN: 0.6, BD.DayPhase.DAY: 0.3, BD.DayPhase.DUSK: 0.8, BD.DayPhase.NIGHT: 1.1}
const FLICKER: Array[Vector2] = [Vector2(0.06, 7.3), Vector2(0.04, 12.9)] # [amplitude, pulsation rad/s]
const TILE_SORT_ORIGIN: int = 8 # bas de la tuile
const FLAT_SORT_ORIGIN: int = -8 # haut de la tuile : touffes toujours sous un PNJ debout dans la cellule
const SHADOW_SIZE: Vector2i = Vector2i(12, 4)
const SHADOW_ALPHA: float = 0.35
const BRAZIER_LIGHT_SCALE: float = 1.5 # Brasero = copie réduite de l'Âtre. validé sur Fold (jalon 11)
const NPC_PICK_RADIUS_PX: float = 10.0 # saisie d'un PNJ au doigt (jalon 19) ; technique, PROPOSÉ

@onready var _day: CanvasModulate = $Jour
@onready var _ground: TileMapLayer = $Sol
@onready var _paths: TileMapLayer = $Chemins
@onready var _entities: Node2D = $Entites
@onready var _buildings: TileMapLayer = $Entites/Batiments
@onready var _deco: TileMapLayer = $Entites/Deco
@onready var _torch: Sprite2D = $Entites/Atre/Torche
@onready var _light: PointLight2D = $Entites/Atre/Lumiere
@onready var _player: Node2D = $Entites/Joueur # player.gd
@onready var _segment: Node2D = $Entites/Segment # segment.gd

var hour_override: int = -1 # debug (--hour=H) : rendu et ancres seulement
var _data: Dictionary = {}
var _tiles: Dictionary = {} # nom -> [source_id, atlas_coords]
var _village: Dictionary = {}
var _npcs: Array[Node2D] = []
var _acts: Array = []
var _base_energy: float = 0.0
var _t: float = 0.0
var _brazier_light: PointLight2D
# Grand Âtre (jalon 21) : de quoi recalculer le décor au nouveau rayon sans reconstruire le village.
var _seed: int = 0
var _blocked: Dictionary = {} # bâti + chemins + props
var _deco_map: Dictionary = {} # sortie de VL.deco au rayon courant
var _solid: Dictionary = {} # partagé avec le Joueur et le Segment : modifié en place, jamais réaffecté
# Surbrillance du bâtiment visé au saisir-déposer (jalon 21), créée une fois.
var _target: Node2D
var _target_label: Label
var _target_rect: Rect2
var _target_color: Color

# player_ref : rend le dictionnaire courant du joueur (main.gd), transmis au Segment.
func setup(world_seed: int, village: Dictionary, now_utc: int, player_ref: Callable) -> void:
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
		_paint_deco(c, deco[c])
	_seed = world_seed
	_blocked = blocked
	_deco_map = deco
	_set_fog_radius()
	var shadow: ImageTexture = _shadow_texture()
	$Entites/Atre/Ombre.texture = shadow
	_torch.texture = _tile_texture("torche")
	var solid: Dictionary = VL.solid_cells(sites, patterns, _data["props"], deco)
	_solid = solid
	_build_target()
	_player.setup(VL.cell_center(VL.PLAYER_SPAWN_CELL), _tile_texture(_data["player_sprite"]), shadow, solid)
	_setup_segment(world_seed, village.get("isolat", 0), solid, shadow, player_ref)
	_village = village
	var npcs: Array = village.get("npcs", [])
	var hour: int = hour_at(now_utc)
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
	timer.autostart = true # démarre à l'entrée dans l'arbre (hors arbre sous le simulateur headless)
	add_child(timer)

func player() -> Node2D:
	return _player

# Fin du chantier (jalon 21), jamais sur size_changed : décor au rayon VL.atre_radius(), arbres disparus retirés de solid
# en place, brume repoussée. Les lisières du segment ne bougent pas (nœuds loin du village).
func set_atre_level() -> void:
	var deco: Dictionary = VL.deco(_seed, _blocked)
	for c: Vector2i in _deco_map:
		if _deco_map[c][0] == "tree" and not (deco.has(c) and deco[c][0] == "tree"):
			_solid.erase(c)
		if not deco.has(c):
			_deco.erase_cell(c)
	for c: Vector2i in deco:
		if _deco_map.get(c) != deco[c]:
			_paint_deco(c, deco[c])
			if deco[c][0] == "tree": # Âtre redescendu (debug, remise à zéro)
				_solid[c] = true
	_deco_map = deco
	_set_fog_radius()
	if _player.unstick() and OS.is_debug_build():
		print("[VILLAGE] " + JSON.stringify({"event": "joueur_ramene", "raison": "arbre revenu"}))

# Brume de la Cendre Grise (ShaderMaterial partagé par les calques) au bord du rayon de l'Âtre.
func _set_fog_radius() -> void:
	(_ground.material as ShaderMaterial).set_shader_parameter("radius_px", (VL.atre_radius() + 0.5) * VL.CELL)

func _paint_deco(c: Vector2i, d: Array) -> void:
	var names: Array = _data["trees"] if d[0] == "tree" else _data["tufts"]
	_paint(_deco, c, names[d[1] % names.size()])

# Surbrillance : rectangle des tuiles du site (couleur du rôle, remplissage atténué, contour), étiquette au-dessus à
# l'échelle 2 (zoom déplié 0,5 : taille de l'UI). Le mot porte le sens (« libre », « échange »).
func _build_target() -> void:
	_target = Node2D.new()
	_target.name = "Cible"
	_target.z_index = 10 # au-dessus des bâtiments et des PNJ
	_target.visible = false
	add_child(_target)
	_target.draw.connect(func() -> void:
		_target.draw_rect(_target_rect, Color(_target_color, UiStyle.HIGHLIGHT_FILL_ALPHA))
		_target.draw_rect(_target_rect, _target_color, false, UiStyle.HIGHLIGHT_LINE_PX))
	_target_label = Label.new()
	_target_label.scale = Vector2(2, 2)
	_target_label.add_theme_color_override("font_outline_color", UiStyle.HIGHLIGHT_TEXT_OUTLINE)
	_target_label.add_theme_constant_override("outline_size", 2)
	_target.add_child(_target_label)

func highlight_site(site: String, text: String, color: Color) -> void:
	_target_rect = site_rect(site)
	_target_color = color
	_target_label.text = text
	_target_label.add_theme_color_override("font_color", color)
	_target_label.reset_size()
	var w: Vector2 = _target_label.get_minimum_size() * _target_label.scale
	_target_label.position = Vector2(_target_rect.get_center().x - w.x / 2.0, _target_rect.position.y - w.y - 2.0)
	_target.visible = true
	_target.queue_redraw()

func clear_highlight() -> void:
	if _target != null:
		_target.visible = false

# Rectangle monde des tuiles d'un site (tuile (0, 0) centrée sur l'origine).
func site_rect(site: String) -> Rect2:
	var tiles: Dictionary = VL.site_tiles(_data["sites"][site], _data["patterns"])
	var lo: Vector2i = tiles.keys()[0]
	var hi: Vector2i = lo
	for c: Vector2i in tiles:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	return Rect2(Vector2(lo) * VL.CELL - Vector2(VL.CELL, VL.CELL) / 2.0, Vector2(hi - lo + Vector2i.ONE) * VL.CELL)

func segment() -> Node2D:
	return _segment

# Rectangle du lieu où se trouve pos : sol du village ou nœud de Brume.
func rect_at(pos: Vector2) -> Rect2i:
	var i: int = SG.node_index(Vector2i(floori((pos.x + VL.CELL / 2.0) / VL.CELL), floori((pos.y + VL.CELL / 2.0) / VL.CELL)))
	return VL.GROUND_RECT if i == SG.VILLAGE else SG.node_rect(i)

# Segment de Brume : sol et arbres des 3 nœuds (même shader que le village), Brasero = copie réduite de l'Âtre.
func _setup_segment(world_seed: int, isolat: int, village_solid: Dictionary, shadow: Texture2D, player_ref: Callable) -> void:
	var seg: Dictionary = _data["segment"]
	var names: Array = _data["trees"]
	for i in SG.NODE_FIRST_ROW.size():
		var map: Dictionary = SG.node_map(world_seed, i)
		var r: Rect2i = map["rect"]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				_paint(_ground, Vector2i(x, y), "herbe")
		for c: Vector2i in map["trees"]:
			_paint(_deco, c, names[map["trees"][c] % names.size()])
	var brazier: Node2D = $Entites/Atre.duplicate()
	brazier.name = "Brasero"
	_brazier_light = brazier.get_node("Lumiere")
	_brazier_light.texture_scale = BRAZIER_LIGHT_SCALE
	_segment.setup(world_seed, isolat, _player, village_solid, _tile_texture(seg["mob_sprite"]), _tile_texture(seg["mist_sprite"]), shadow, player_ref, brazier,
		_tile_texture(seg["elite_sprite"]), _tile_texture(seg["crate_sprite"]))

func refresh(village: Dictionary, now_utc: int) -> void:
	if _data.is_empty():
		return
	_village = village
	var hour: int = hour_at(now_utc)
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
	if _brazier_light != null:
		_brazier_light.energy = _light.energy

# Saisir-déposer (jalon 19) : PNJ visible le plus proche de pos (centre du sprite), -1 sinon. Un PNJ endormi est caché.
func npc_at(pos: Vector2, radius: float = NPC_PICK_RADIUS_PX) -> int:
	var best: int = -1
	var best_d: float = radius
	for i in _npcs.size():
		var d: float = (_npcs[i].position + _npcs[i].BODY_OFFSET).distance_to(pos)
		if _npcs[i].visible and d <= best_d:
			best = i
			best_d = d
	return best

func drag_npc(i: int, pos: Vector2) -> void:
	_npcs[i].hold_at(pos)

func release_npc(i: int) -> void:
	_npcs[i].release()

# Site sous pos (cellule comptée comme rect_at : tuile (0, 0) centrée sur l'origine) ; "" hors de tout site.
func site_at(pos: Vector2) -> String:
	var half: float = VL.CELL / 2.0
	return VL.site_at(Vector2i(floori((pos.x + half) / VL.CELL), floori((pos.y + half) / VL.CELL)), _data["sites"], _data["patterns"])

func hour_at(now_utc: int) -> int:
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
