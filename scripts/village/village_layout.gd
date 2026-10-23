class_name VillageLayout
extends RefCounted
# Disposition et horaires du village (rendu seul) : fonctions statiques pures, testables sous --script.
# Repère : tuiles, centre de la tuile (0, 0) = Grand Âtre = origine du monde, y vers le bas.
# Constantes techniques et provisoires (rendu), aucune valeur d'équilibrage.

const BD = preload("res://balance/balance_d.gd")
const RngS = preload("res://autoload/Rng.gd")

const DATA_PATH: String = "res://data/village/village.json"
const CELL: int = 16
const GROUND_RECT: Rect2i = Rect2i(-20, -26, 41, 53) # couvre le déplié : 19,25 x 25,5 tuiles autour de l'Âtre
const TREE_PCT: int = 18
const TUFT_PCT: int = 6
const ROAD_X: int = 0
const ROAD_Y: Vector2i = Vector2i(11, 26) # route vers l'isolat, bornes incluses
const VEILLEE_RADIUS_PX: float = 28.0
const SHARED_SPACING_PX: float = 12.0
const WORK_SITE: Dictionary = {"EXTRACTION": "GISEMENT", "TAVERN": "TAVERN", "FORGE": "FORGE", "GUARD": "GATE"}
const NEIGHBORS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)] # haut, bas, gauche, droite

static func load_data() -> Dictionary:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return v if v is Dictionary else {}

# Niveau 1 tant que l'état de la partie ne porte pas de niveau d'Âtre.
static func atre_radius() -> int:
	return BD.ATRE_RADIUS_TILES[0]

static func in_radius(cell: Vector2i, r: int) -> bool:
	return cell.x * cell.x + cell.y * cell.y <= r * r

static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL)

static func v2i(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))

# Cellule -> nom de tuile, pour un site (les "" du motif ne sont pas bâtis).
static func site_tiles(site: Dictionary, patterns: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var o: Vector2i = v2i(site["origin"])
	var rows: Array = patterns[site["pattern"]]
	for y in rows.size():
		for x in rows[y].size():
			if rows[y][x] != "":
				out[o + Vector2i(x, y)] = rows[y][x]
	return out

static func built_cells(sites: Dictionary, patterns: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in sites:
		out.merge(site_tiles(sites[key], patterns))
	return out

# {"cells": cellule -> true, "lengths": site -> longueur}. BFS 4-voisins par site avec accès, dans l'ordre des sites ;
# but = cellule 4-voisine du dallage de l'Âtre (hors dallage) ou cellule d'un chemin déjà tracé, testé à la sortie de file.
static func paths(sites: Dictionary, patterns: Dictionary) -> Dictionary:
	var built: Dictionary = built_cells(sites, patterns)
	var dallage: Dictionary = site_tiles(sites["ATRE"], patterns)
	var cells: Dictionary = {}
	var lengths: Dictionary = {}
	for key: String in sites:
		if not sites[key].has("access"):
			continue
		var start: Vector2i = v2i(sites[key]["access"])
		var parent: Dictionary = {start: start}
		var queue: Array[Vector2i] = [start]
		var goal: Vector2i = start
		var found: bool = false
		while not queue.is_empty():
			var c: Vector2i = queue.pop_front()
			if cells.has(c) or _touches(c, dallage):
				goal = c
				found = true
				break
			for d: Vector2i in NEIGHBORS:
				var n: Vector2i = c + d
				if GROUND_RECT.has_point(n) and not built.has(n) and not parent.has(n):
					parent[n] = c
					queue.append(n)
		var n_cells: int = 0
		if found:
			var c: Vector2i = goal
			while true:
				cells[c] = true
				n_cells += 1
				if c == start:
					break
				c = parent[c]
		lengths[key] = n_cells
	for y in range(ROAD_Y.x, ROAD_Y.y + 1):
		cells[Vector2i(ROAD_X, y)] = true
	return {"cells": cells, "lengths": lengths}

static func _touches(c: Vector2i, dallage: Dictionary) -> bool:
	if dallage.has(c):
		return false
	for d: Vector2i in NEIGHBORS:
		if dallage.has(c + d):
			return true
	return false

# Cellule -> [type ("tree" | "tuft"), r]. Un tirage par cellule de GROUND_RECT, même bloquée : le flux ne dépend pas
# de la disposition. RNG à part ("village/deco"), sans effet sur la partie.
static func deco(world_seed: int, blocked: Dictionary) -> Dictionary:
	var rng: RngS.Pcg32 = RngS.make_rng(world_seed, "village/deco")
	var out: Dictionary = {}
	var r_atre: int = atre_radius()
	for y in range(GROUND_RECT.position.y, GROUND_RECT.end.y):
		for x in range(GROUND_RECT.position.x, GROUND_RECT.end.x):
			var c: Vector2i = Vector2i(x, y)
			var r: int = rng.range_int(0, 99)
			if blocked.has(c):
				continue
			var inside: bool = in_radius(c, r_atre)
			if not inside and r < TREE_PCT:
				out[c] = ["tree", r]
			elif inside and r < TUFT_PCT:
				out[c] = ["tuft", r]
	return out

static func local_hour(now_utc: int, tz_offset_sec: int) -> int:
	return posmod(now_utc + tz_offset_sec, 86400) / 3600

static func day_phase(hour: int) -> int:
	var p: Dictionary = BD.PHASE_START_HOUR_LOCAL
	if hour >= p[BD.DayPhase.NIGHT] or hour < p[BD.DayPhase.DAWN]:
		return BD.DayPhase.NIGHT
	if hour < p[BD.DayPhase.DAY]:
		return BD.DayPhase.DAWN
	if hour < p[BD.DayPhase.DUSK]:
		return BD.DayPhase.DAY
	return BD.DayPhase.DUSK

# Créneau [a, b[ ; a > b : passe minuit.
static func in_slot(hour: int, slot: Vector2i) -> bool:
	if slot.x <= slot.y:
		return slot.x <= hour and hour < slot.y
	return hour >= slot.x or hour < slot.y

# Grève douce (SOCLE §A6) : STRIKE remplace WORK seulement ; repas, veillée et sommeil inchangés.
static func activity(hour: int, nocturnal: bool, on_strike: bool) -> String:
	var schedule: Dictionary = BD.SCHEDULE_NOCTURNAL if nocturnal else BD.SCHEDULE_DIURNAL
	var acts: Dictionary = {"work_block_1": "WORK", "work_block_2": "WORK", "meal_break": "MEAL", "social_veillee": "VEILLEE", "sleep": "SLEEP"}
	for slot: String in acts:
		if in_slot(hour, schedule[slot]):
			return "STRIKE" if on_strike and acts[slot] == "WORK" else acts[slot]
	return "SLEEP" # inatteignable : les créneaux couvrent les 24 h

static func npc_activity(hour: int, npc: Dictionary) -> String:
	return activity(hour, BD.TraitId.NOCTAMBULE in npc["traits"], npc["on_strike"])

# Ancre d'un PNJ en pixels de monde, avant décalage des PNJ qui partagent le même accès.
static func anchor(act: String, npc_index: int, npc: Dictionary, sites: Dictionary) -> Vector2:
	match act:
		"WORK":
			return cell_center(v2i(sites[WORK_SITE[npc["post"]]]["access"]))
		"MEAL":
			return cell_center(v2i(sites["TAVERN"]["access"]))
		"SLEEP":
			return cell_center(v2i(sites["HOUSE%d" % npc_index]["access"]))
	var a: float = TAU * npc_index / 5.0 - PI / 2.0 # VEILLEE, STRIKE : cercle autour de l'Âtre
	return Vector2(cos(a), sin(a)) * VEILLEE_RADIUS_PX

# Ancres de tous les PNJ ; même ancre partagée par n PNJ : décalage horizontal (k - (n - 1) / 2) x 12 px.
static func anchors(acts: Array, npcs: Array, sites: Dictionary) -> Array[Vector2]:
	var base: Array[Vector2] = []
	for i in npcs.size():
		base.append(anchor(acts[i], i, npcs[i], sites))
	var out: Array[Vector2] = []
	for i in base.size():
		var same: Array[int] = []
		for j in base.size():
			if base[j] == base[i]:
				same.append(j)
		out.append(base[i] + Vector2((same.find(i) - (same.size() - 1) / 2.0) * SHARED_SPACING_PX, 0.0))
	return out
