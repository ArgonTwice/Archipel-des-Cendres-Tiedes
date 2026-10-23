extends Node
# Autoload « SaveManager » : graine + delta, double fichier tournant, export/import Base64.
# État : {"format": int, "seq": int, "world_seed": int, "village": Dictionary (format de OfflineDag.resume)}.
# Le delta est l'état mutable complet ; rien de ce qui se régénère depuis world_seed n'y entre.
# Fichier = SHA-256(payload) + payload, payload = var_to_bytes(état). Hash vérifié avant décodage, jamais d'objets.
# seq impair -> save_a.dat, pair -> save_b.dat : une écriture n'écrase que l'emplacement le plus ancien.

const Dag = preload("res://scripts/offline_dag.gd")
const ClockS = preload("res://autoload/Clock.gd")

const SAVE_FORMAT_VERSION: int = 1
const SLOT_FILES: Array[String] = ["save_a.dat", "save_b.dat"]
const HASH_SIZE: int = 32
const DEFAULT_DIR: String = "user://"
const VILLAGE_KEYS: Array[String] = ["last_save_utc", "tz_offset_sec", "last_tick_day", "isolat", "player_gold", "shops", "npcs"]

var state: Dictionary = {}

# Android : NOTIFICATION_APPLICATION_PAUSED à la mise en arrière-plan. Le pliage / dépliage arrive avec le jalon UI.
func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST) and not state.is_empty():
		var saved: Dictionary = save(state, ClockS.now_utc())
		if not saved.is_empty(): # en cas d'échec, l'état en mémoire est conservé
			state = saved

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
	return typeof(v["shops"]) == TYPE_DICTIONARY and v["shops"].has_all(["MAT", "TAVERN", "FORGE"]) and typeof(v["npcs"]) == TYPE_ARRAY

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

# Reprise : dernier état valide, DAG hors-ligne, puis écriture. {} si aucune sauvegarde (nouvelle partie hors périmètre).
static func boot(now_utc: int, dir: String = DEFAULT_DIR) -> Dictionary:
	var st: Dictionary = load_latest(dir)
	if st.is_empty():
		return {}
	var out: Dictionary = Dag.resume(st["village"], now_utc)
	st["village"] = out["village"]
	var saved: Dictionary = save(st, now_utc, dir)
	return {"state": saved, "t_eff": out["t_eff"], "ticked": out["ticked"], "fiches": out["fiches"],
		"fixed_cost_paid": out["fixed_cost_paid"], "tools_replaced": out["tools_replaced"]}
