extends Node
# Autoload « SaveManager » : graine + delta, double fichier tournant, export/import Base64.
# État : {"format": int, "seq": int, "world_seed": int, "village": Dictionary (format de OfflineDag.resume),
# "player": {"voc_xp": {vocation: int}} (jalon 13, clé optionnelle : absente avant, ajoutée au chargement)}.
# Le delta est l'état mutable complet ; rien de ce qui se régénère depuis world_seed n'y entre.
# Fichier = SHA-256(payload) + payload, payload = var_to_bytes(état). Hash vérifié avant décodage, jamais d'objets.
# seq impair -> save_a.dat, pair -> save_b.dat : une écriture n'écrase que l'emplacement le plus ancien.

const Dag = preload("res://scripts/offline_dag.gd")
const ClockS = preload("res://autoload/Clock.gd")
const RngS = preload("res://autoload/Rng.gd")
const NewGameS = preload("res://scripts/new_game.gd")
const BB = preload("res://balance/balance_b.gd")
const ProgressionS = preload("res://scripts/progression.gd")

const SAVE_FORMAT_VERSION: int = 1
const SLOT_FILES: Array[String] = ["save_a.dat", "save_b.dat"]
const HASH_SIZE: int = 32
const DEFAULT_DIR: String = "user://"
const VILLAGE_KEYS: Array[String] = ["last_save_utc", "tz_offset_sec", "last_tick_day", "isolat", "player_gold", "shops", "npcs"]

signal synced(report: Dictionary)

var state: Dictionary = {}

# Android : pause (arrière-plan), reprise et fermeture. Le pliage / dépliage appelle sync depuis main.gd.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_RESUMED:
		var r: Dictionary = sync(ClockS.now_utc())
		if not r.is_empty():
			synced.emit(r)

func start(now_utc: int, dir: String = DEFAULT_DIR) -> Dictionary:
	var r: Dictionary = boot(now_utc, dir)
	if not r.is_empty():
		state = r["state"]
	return r

# Sans simulation en session (hors jalon), le temps de session est compté comme hors-ligne à la prochaine reprise.
# Reprendre à chaque pliage perdrait les arrondis du DAG (12 reprises de 30 min = 0 Or contre 11 Or en une reprise de 6 h) :
# hors rattrapage dû, sync écrit l'état à son ANCRE (last_save_utc inchangé) et rend {}.
func sync(now_utc: int, dir: String = DEFAULT_DIR) -> Dictionary:
	if state.is_empty():
		return {}
	if catch_up_due(state["village"], now_utc):
		var st: Dictionary = state.duplicate(true)
		var gold_before: int = st["village"]["player_gold"]
		var out: Dictionary = Dag.resume(st["village"], now_utc)
		st["village"] = out["village"]
		var saved: Dictionary = save(st, now_utc, dir)
		if saved.is_empty(): # state inchangé : le prochain sync refait la reprise, rien n'est compté deux fois
			return {}
		state = saved
		return _report(saved, out, gold_before)
	var anchored: Dictionary = save(state, state["village"]["last_save_utc"], dir)
	if not anchored.is_empty():
		state = anchored
	return {}

# Nouveau jour de tick, ou absence au plafond du hors-ligne.
static func catch_up_due(village: Dictionary, now_utc: int) -> bool:
	return ClockS.day_index(now_utc, village["tz_offset_sec"]) > village["last_tick_day"] \
		or ClockS.offline_hours(village["last_save_utc"], now_utc) >= BB.OFFLINE_MAX_HOURS

static func _sha256(data: PackedByteArray) -> PackedByteArray:
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish()

static func pack(s: Dictionary) -> PackedByteArray:
	var payload: PackedByteArray = var_to_bytes(s)
	return _sha256(payload) + payload

static func unpack(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() < HASH_SIZE + 1:
		return {}
	var payload: PackedByteArray = bytes.slice(HASH_SIZE)
	if _sha256(payload) != bytes.slice(0, HASH_SIZE):
		return {}
	var v: Variant = bytes_to_var(payload)
	if typeof(v) != TYPE_DICTIONARY or not _is_valid(v):
		return {}
	if not v.has("player"):
		v["player"] = ProgressionS.new_player()
	return v

# Aucune migration : un autre format est refusé.
static func _is_valid(s: Dictionary) -> bool:
	if typeof(s.get("format")) != TYPE_INT or s["format"] != SAVE_FORMAT_VERSION:
		return false
	if typeof(s.get("seq")) != TYPE_INT or s["seq"] < 1 or typeof(s.get("world_seed")) != TYPE_INT:
		return false
	if typeof(s.get("village")) != TYPE_DICTIONARY or not s["village"].has_all(VILLAGE_KEYS):
		return false
	var v: Dictionary = s["village"]
	if typeof(v["shops"]) != TYPE_DICTIONARY or not v["shops"].has_all(["MAT", "TAVERN", "FORGE"]) or typeof(v["npcs"]) != TYPE_ARRAY:
		return false
	return not s.has("player") or _is_valid_player(s["player"])

static func _is_valid_player(p: Variant) -> bool:
	if typeof(p) != TYPE_DICTIONARY or typeof(p.get("voc_xp")) != TYPE_DICTIONARY:
		return false
	for voc: String in ProgressionS.VOCATIONS:
		var xp: Variant = p["voc_xp"].get(voc)
		if typeof(xp) != TYPE_INT or xp < 0:
			return false
	return true

static func slot_path(seq: int, dir: String = DEFAULT_DIR) -> String:
	return dir.path_join(SLOT_FILES[0 if seq % 2 == 1 else 1])

static func load_latest(dir: String = DEFAULT_DIR) -> Dictionary:
	var best: Dictionary = {}
	for f: String in SLOT_FILES:
		var path: String = dir.path_join(f)
		if not FileAccess.file_exists(path): # absent = vide, sans message d'erreur du moteur
			continue
		var s: Dictionary = unpack(FileAccess.get_file_as_bytes(path))
		if not s.is_empty() and (best.is_empty() or s["seq"] > best["seq"]):
			best = s
	return best

static func save(s: Dictionary, now_utc: int, dir: String = DEFAULT_DIR) -> Dictionary:
	if not DirAccess.dir_exists_absolute(dir):
		var err: Error = DirAccess.make_dir_recursive_absolute(dir)
		if err != OK:
			push_error("SaveManager : dossier %s (%s)" % [dir, error_string(err)])
			return {}
	var copy: Dictionary = s.duplicate(true)
	var prev: Dictionary = load_latest(dir)
	copy["seq"] = (0 if prev.is_empty() else int(prev["seq"])) + 1
	copy["village"]["last_save_utc"] = maxi(copy["village"]["last_save_utc"], now_utc)
	var bytes: PackedByteArray = pack(copy)
	var path: String = slot_path(copy["seq"], dir)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager : ouverture de %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return {}
	var ok: bool = file.store_buffer(bytes) # bool depuis Godot 4.4
	var write_err: Error = file.get_error()
	file.close()
	if not ok:
		push_error("SaveManager : écriture de %s (%s)" % [path, error_string(write_err)])
		return {}
	if FileAccess.get_file_as_bytes(path) != bytes:
		push_error("SaveManager : relecture de %s différente (%s)" % [path, error_string(FileAccess.get_open_error())])
		return {}
	return copy

static func export_base64(s: Dictionary) -> String:
	return Marshalls.raw_to_base64(pack(s))

# Rien n'est écrit : l'appelant fait save(importé, now), qui écrase l'emplacement le plus ancien.
static func import_base64(text: String) -> Dictionary:
	return unpack(Marshalls.base64_to_raw(text.strip_edges()))

# seq 0 : save() pose le seq.
static func new_state(world_seed: int, now_utc: int, tz_offset_sec: int) -> Dictionary:
	return {"format": SAVE_FORMAT_VERSION, "seq": 0, "world_seed": world_seed, "village": NewGameS.village(world_seed, now_utc, tz_offset_sec),
		"player": ProgressionS.new_player()}

# Reprise : dernier état valide, DAG hors-ligne, puis écriture. Aucune sauvegarde : nouvelle partie.
# Fichier présent mais illisible : {} et rien n'est écrit (le joueur ne perd pas sa partie sur une erreur).
static func boot(now_utc: int, dir: String = DEFAULT_DIR) -> Dictionary:
	var st: Dictionary = load_latest(dir)
	if st.is_empty():
		for f: String in SLOT_FILES:
			if FileAccess.file_exists(dir.path_join(f)):
				push_error("SaveManager : sauvegarde illisible, rien n'est écrit (%s)" % dir.path_join(f))
				return {}
		var created: Dictionary = save(new_state(RngS.entropy_seed(), now_utc, NewGameS.system_tz_offset_sec()), now_utc, dir)
		if created.is_empty():
			return {}
		return {"state": created, "t_eff": 0.0, "ticked": false, "fiches": [], "fixed_cost_paid": 0, "tools_replaced": 0, "new_game": true,
			"gold_delta": 0, "strikes": 0}
	var gold_before: int = st["village"]["player_gold"]
	var out: Dictionary = Dag.resume(st["village"], now_utc)
	st["village"] = out["village"]
	return _report(save(st, now_utc, dir), out, gold_before)

# Rapport de reprise commun à boot et sync (Rapport de veillée, SOCLE §A4).
static func _report(saved: Dictionary, out: Dictionary, gold_before: int) -> Dictionary:
	var strikes: int = 0
	for npc: Dictionary in out["village"]["npcs"]:
		if npc["on_strike"]:
			strikes += 1
	return {"state": saved, "t_eff": out["t_eff"], "ticked": out["ticked"], "fiches": out["fiches"],
		"fixed_cost_paid": out["fixed_cost_paid"], "tools_replaced": out["tools_replaced"], "new_game": false,
		"gold_delta": out["village"]["player_gold"] - gold_before, "strikes": strikes}
