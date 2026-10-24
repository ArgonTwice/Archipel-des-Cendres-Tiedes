class_name SegmentGen
extends RefCounted
# Cartes du segment de Brume de la tranche (SOCLE §A4, volet E §3) : fonctions statiques pures, testables sous --script.
# Un RNG par nœud (segment/noeud/i) ; l'ordre des tirages est celui du jumeau Python (prep_jalon_11.py).
# Contenu (monstres, nœuds de Brume) lu dans BalanceA ; tailles et placement = level design technique.

const BA = preload("res://balance/balance_a.gd")
const VL = preload("res://scripts/village/village_layout.gd")
const RngS = preload("res://autoload/Rng.gd")

const NODE_SIZE: Vector2i = Vector2i(41, 96) # couvre la vue dépliée (38,5 x 51 tuiles). PROPOSÉ, à valider (jalon 11)
const NODE_FIRST_ROW: Array[int] = [100, 200, 300] # technique : nœuds loin du village. PROPOSÉ, à valider (jalon 11)
const CONTENT_ROWS: Vector2i = Vector2i(8, 87) # lignes locales du contenu, bornes incluses. PROPOSÉ, à valider (jalon 11)
const CONTENT_X: Vector2i = Vector2i(4, 14) # |x| du contenu. PROPOSÉ, à valider (jalon 11)
const BRAZIER_NODE: int = 1 # PROPOSÉ, à valider (jalon 11)
const BRAZIER_RADIUS_CELLS: int = 3 # PROPOSÉ, à valider (jalon 11)
const NODE_TYPES: Array[int] = [BA.SegmentNodeType.NODE_OUTSKIRTS, BA.SegmentNodeType.NODE_BRAZIER_CROSSROADS, BA.SegmentNodeType.NODE_ELITE_LAIR]
const VILLAGE: int = -1
const ELITE_ROW: int = 91 # ligne locale de l'Élite, dans l'allée centrale déjà dégagée. PROPOSÉ, à valider (jalon 12)

static func node_rect(i: int) -> Rect2i:
	return Rect2i(-NODE_SIZE.x / 2, NODE_FIRST_ROW[i], NODE_SIZE.x, NODE_SIZE.y)

static func node_index(cell: Vector2i) -> int:
	for i in NODE_FIRST_ROW.size():
		if node_rect(i).has_point(cell):
			return i
	return VILLAGE

# Ligne locale du créneau k sur s créneaux, répartis sur CONTENT_ROWS.
static func slot_row(k: int, s: int) -> int:
	var span: int = CONTENT_ROWS.y - CONTENT_ROWS.x + 1
	return CONTENT_ROWS.x + (2 * k + 1) * span / (2 * s)

static func slot_count(i: int) -> int:
	return BA.SEGMENT_NODE_NORMAL_MOBS[i] + BA.SEGMENT_NODE_MIST_NODES[i] + (1 if i == BRAZIER_NODE else 0)

# Le Brasero ne dépend pas de la graine : créneau du milieu du nœud BRAZIER_NODE.
static func brazier_cell() -> Vector2i:
	var s: int = slot_count(BRAZIER_NODE)
	return Vector2i(0, NODE_FIRST_ROW[BRAZIER_NODE] + slot_row(s / 2, s))

# L'Élite ne consomme aucun tirage ni aucune cellule : les cartes du jalon 11 ne changent pas.
static func elite_cell() -> Vector2i:
	return Vector2i(0, NODE_FIRST_ROW[BA.SEGMENT_ELITE_NODE_INDEX] + ELITE_ROW)

static func in_brazier_zone(cell: Vector2i) -> bool:
	return (cell - brazier_cell()).length_squared() <= BRAZIER_RADIUS_CELLS * BRAZIER_RADIUS_CELLS

# Cellule de passage -> [nœud d'arrivée (VILLAGE = -1), cellule d'arrivée] : 2 lignes à l'intérieur de l'arrivée.
static func passages() -> Dictionary:
	var out: Dictionary = {Vector2i(0, VL.GROUND_RECT.end.y - 1): [0, Vector2i(0, NODE_FIRST_ROW[0] + 2)]}
	for i in NODE_FIRST_ROW.size():
		var r: Rect2i = node_rect(i)
		out[Vector2i(0, r.position.y)] = [i - 1, Vector2i(0, VL.GROUND_RECT.end.y - 3) if i == 0 else Vector2i(0, node_rect(i - 1).end.y - 3)]
		if i < NODE_FIRST_ROW.size() - 1:
			out[Vector2i(0, r.end.y - 1)] = [i + 1, Vector2i(0, NODE_FIRST_ROW[i + 1] + 2)]
	return out

static func node_map(world_seed: int, i: int) -> Dictionary:
	var rng: RngS.Pcg32 = RngS.make_rng(world_seed, "segment/noeud/%d" % i)
	var rect: Rect2i = node_rect(i)
	# b) contenu mélangé (Fisher-Yates)
	var kinds: Array[String] = []
	for k in BA.SEGMENT_NODE_NORMAL_MOBS[i]:
		kinds.append("mob")
	for k in BA.SEGMENT_NODE_MIST_NODES[i]:
		kinds.append("mist")
	for k in range(kinds.size() - 1, 0, -1):
		var j: int = rng.range_int(0, k)
		var tmp: String = kinds[k]
		kinds[k] = kinds[j]
		kinds[j] = tmp
	# c) créneaux, Brasero au milieu
	var s: int = slot_count(i)
	var content: Array = [] # [kind, ligne locale]
	var out: Dictionary = {"rect": rect, "mobs": [] as Array[Vector2i], "mist": [] as Array[Vector2i], "safe": {}, "trees": {}, "passages": {}}
	var next: int = 0
	for k in s:
		var row: int = slot_row(k, s)
		if i == BRAZIER_NODE and k == s / 2:
			out["brazier"] = Vector2i(0, rect.position.y + row)
		else:
			content.append([kinds[next], row])
			next += 1
	# d) côté puis distance à l'axe
	var cleared: Dictionary = {}
	for c: Array in content:
		var side: int = rng.range_int(0, 1)
		var mag: int = rng.range_int(CONTENT_X.x, CONTENT_X.y)
		var cell: Vector2i = Vector2i(mag if side == 0 else -mag, rect.position.y + c[1])
		out["mobs" if c[0] == "mob" else "mist"].append(cell)
		# e) carré 3 x 3 et bande jusqu'à l'axe
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				cleared[cell + Vector2i(dx, dy)] = true
		for x in range(mini(cell.x, 0), maxi(cell.x, 0) + 1):
			cleared[Vector2i(x, cell.y)] = true
	for y in range(rect.position.y + 1, rect.end.y - 1):
		for x in range(-1, 2):
			cleared[Vector2i(x, y)] = true
	if out.has("brazier"):
		var r: int = BRAZIER_RADIUS_CELLS
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dx * dx + dy * dy <= r * r:
					var sc: Vector2i = out["brazier"] + Vector2i(dx, dy)
					out["safe"][sc] = true
					cleared[sc] = true
	# f) passages
	out["passages"][Vector2i(0, rect.position.y)] = true
	if i < NODE_FIRST_ROW.size() - 1:
		out["passages"][Vector2i(0, rect.end.y - 1)] = true
	# g) un tirage par cellule, même dégagée
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c: Vector2i = Vector2i(x, y)
			var r: int = rng.range_int(0, 99)
			var border: bool = x == rect.position.x or x == rect.end.x - 1 or y == rect.position.y or y == rect.end.y - 1
			if border:
				if not out["passages"].has(c):
					out["trees"][c] = r
			elif r < VL.TREE_PCT and not cleared.has(c):
				out["trees"][c] = r
	return out

# Cellules pleines du joueur : arbres, nœuds de Brume, Brasero (plein, comme la torche de l'Âtre).
static func solid_cells(map: Dictionary) -> Dictionary:
	var out: Dictionary = map["trees"].duplicate()
	for c: Vector2i in map["mist"]:
		out[c] = true
	if map.has("brazier"):
		out[map["brazier"]] = true
	return out

# Cellules pleines des monstres : celles du joueur + la zone sûre du Brasero.
static func mob_solid_cells(map: Dictionary) -> Dictionary:
	var out: Dictionary = solid_cells(map)
	out.merge(map["safe"])
	return out
