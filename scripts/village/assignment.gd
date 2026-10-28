class_name Assignment
extends RefCounted
# Postes des PNJ (jalon 19, SOCLE §A3 et §A6, Volet D §6, n°38) : aptitudes, changement de poste, auto-assignation.
# Statiques pures. Aptitudes déduites de la graine (RNG « npc/apt/i ») : rien n'est sauvegardé. Postes en chaînes,
# dans l'ordre de BD.JobPostType. Clés optionnelles du PNJ : post_next / stars_next (toujours ensemble, appliquées au
# prochain tick par OfflineDag.resume), locked (placé par le joueur, exclu de l'auto-assignation), assign_day.

const BB = preload("res://balance/balance_b.gd")
const BD = preload("res://balance/balance_d.gd")
const RngS = preload("res://autoload/Rng.gd")
const NewGameS = preload("res://scripts/new_game.gd")
const Eco = preload("res://scripts/economy.gd")
const Dag = preload("res://scripts/offline_dag.gd")

const EPS: float = 1e-9

static func posts() -> Array:
	return BD.JobPostType.keys()

static func active_posts() -> Array[String]:
	var out: Array[String] = []
	for p: int in BD.VERTICAL_SLICE_ACTIVE_JOB_POSTS:
		out.append(BD.JobPostType.find_key(p))
	return out

static func slots(lvl: int, post: String) -> int:
	return BD.VERTICAL_SLICE_POST_SLOTS_BY_ATRE_LVL[lvl][BD.JobPostType[post]]

# {post: étoiles} : poste de départ = aptitude principale, les 5 autres tirées dans l'ordre de JobPostType.
static func aptitudes(world_seed: int, index: int) -> Dictionary:
	var rng: RngS.Pcg32 = RngS.make_rng(world_seed, "npc/apt/%d" % index)
	var out: Dictionary = {}
	for p: String in posts():
		out[p] = BB.STARTING_NPC_MAIN_APTITUDE_STARS if p == favorite(index) else NewGameS.weighted_pick(rng, BD.STARTING_NPC_SECONDARY_STAR_WEIGHTS)
	return out

static func favorite(index: int) -> String:
	return NewGameS.START_POSTS[index][0]

static func effective_post(npc: Dictionary) -> String:
	return npc.get("post_next", npc["post"])

static func occupancy(village: Dictionary) -> Dictionary:
	var occ: Dictionary = {}
	for p: String in active_posts():
		occ[p] = 0
	for npc: Dictionary in village["npcs"]:
		occ[effective_post(npc)] += 1
	return occ

static func score(village: Dictionary, index: int, post: String, apt: Dictionary) -> float:
	var npc: Dictionary = village["npcs"][index]
	var matching: bool = false
	for t: int in npc["traits"]:
		matching = matching or BD.TRAIT_FAVORED_POSTS[t].has(BD.JobPostType[post])
	var stock: int = 0
	var s_max: int = 0
	if Dag.POST_SHOP.has(post):
		var key: String = Dag.POST_SHOP[post]
		var shop: Dictionary = village["shops"][key]
		stock = shop["stock"]
		s_max = Eco.stock_max(key == "MAT", shop["lvl"], shop["griffe_trait"])
	return BD.compute_auto_assign_score(apt[post], post == favorite(index), matching, stock, s_max, post == "GUARD")

# Attente vers post ; revenir au poste du jour efface l'attente.
static func _set_next(npc: Dictionary, post: String, apt: Dictionary) -> void:
	if post == npc["post"]:
		npc.erase("post_next")
		npc.erase("stars_next")
	else:
		npc["post_next"] = post
		npc["stars_next"] = apt[post]

# Saisir-déposer ou bouton de poste : le PNJ est verrouillé. Poste plein : échange avec un occupant (non verrouillé
# d'abord, puis le plus petit index), verrouillé lui aussi. -> {"kind": "same" / "move" / "swap", "other": j ou -1}.
static func move(village: Dictionary, world_seed: int, index: int, post: String, lvl: int) -> Dictionary:
	var npc: Dictionary = village["npcs"][index]
	var cur: String = effective_post(npc)
	npc["locked"] = true
	if post == cur:
		return {"kind": "same", "other": -1}
	if occupancy(village)[post] < slots(lvl, post):
		_set_next(npc, post, aptitudes(world_seed, index))
		return {"kind": "move", "other": -1}
	var other: int = -1
	for j in village["npcs"].size():
		var m: Dictionary = village["npcs"][j]
		if j != index and effective_post(m) == post and (other < 0 or (village["npcs"][other].get("locked", false) and not m.get("locked", false))):
			other = j
	_set_next(village["npcs"][other], cur, aptitudes(world_seed, other))
	village["npcs"][other]["locked"] = true
	_set_next(npc, post, aptitudes(world_seed, index))
	return {"kind": "swap", "other": other}

# PNJ libres, 1 changement par PNJ et par day_index, places libres seulement, gain >= AUTO_ASSIGN_MIN_SCORE_GAIN.
# Chaque passe applique le plus grand gain (égalité : plus petit index, puis ordre de JobPostType), puis recommence.
# -> [{"pnj", "de", "vers", "gain"}].
static func auto_assign(village: Dictionary, world_seed: int, today: int, lvl: int) -> Array:
	var moves: Array = []
	while true:
		var occ: Dictionary = occupancy(village)
		var best: Dictionary = {}
		for i in village["npcs"].size():
			var npc: Dictionary = village["npcs"][i]
			if npc.get("locked", false) or npc.get("assign_day", -1) == today:
				continue
			var apt: Dictionary = aptitudes(world_seed, i)
			var cur: String = effective_post(npc)
			var s_cur: float = score(village, i, cur, apt)
			for p: String in active_posts():
				if p == cur or occ[p] >= slots(lvl, p):
					continue
				var gain: float = score(village, i, p, apt) - s_cur
				if gain >= BD.AUTO_ASSIGN_MIN_SCORE_GAIN - EPS and (best.is_empty() or gain > best["gain"] + EPS):
					best = {"pnj": i, "de": cur, "vers": p, "gain": gain}
		if best.is_empty():
			return moves
		var n: Dictionary = village["npcs"][best["pnj"]]
		_set_next(n, best["vers"], aptitudes(world_seed, best["pnj"]))
		n["assign_day"] = today
		moves.append(best)
	return moves # inatteignable
