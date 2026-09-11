extends Node
class_name SaveManager

signal save_completed(success: bool, unix_time: int)
signal load_completed(found: bool)

const SAVE_PATH := "user://my_camp_game_stage7.json"
const SAVE_VERSION := 2
@export var autosave_interval: float = 10.0
var last_save_unix := 0
var last_load_found := false
var _autosave_left := 10.0
var _loading := false

func _ready() -> void:
	add_to_group("save_manager")
	_autosave_left = autosave_interval
	call_deferred("_load_initial")
func _process(delta: float) -> void:
	if _loading: return
	_autosave_left -= delta
	if _autosave_left <= 0.0:
		_autosave_left = autosave_interval
		save_game()
func _load_initial() -> void:
	_loading = true
	await get_tree().process_frame
	await get_tree().process_frame
	last_load_found = load_game()
	_loading = false
	load_completed.emit(last_load_found)

func save_game() -> bool:
	var resources=get_tree().get_first_node_in_group("resource_manager")
	var settlement=get_tree().get_first_node_in_group("settlement_manager")
	var progression=get_tree().get_first_node_in_group("progression_manager")
	var meta=get_tree().get_first_node_in_group("meta_progression_manager")
	var parity=get_tree().get_first_node_in_group("stage10_settlement_parity")
	var wave=get_tree().get_first_node_in_group("raid_manager")
	var player=get_tree().get_first_node_in_group("player_combat")
	var units=get_tree().get_first_node_in_group("unit_manager")
	if resources==null or settlement==null or progression==null or wave==null or player==null or units==null:
		save_completed.emit(false,last_save_unix); return false
	var data := {
		"version":SAVE_VERSION,
		"timestamp":Time.get_unix_time_from_system(),
		"resources":resources.export_state(),
		"settlement":settlement.export_state(),
		"progression":progression.export_state(),
		"wave":wave.export_state(),
		"player":player.export_state(),
		"units":units.export_state(),
	}
	if meta != null and meta.has_method("export_state"):
		data["meta"] = meta.export_state()
	if parity != null and parity.has_method("export_state"):
		data["stage10"] = parity.export_state()
	var file:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file==null:
		save_completed.emit(false,last_save_unix); return false
	file.store_string(JSON.stringify(data)); file.close(); last_save_unix=int(data["timestamp"]); save_completed.emit(true,last_save_unix); return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if file==null: return false
	var parsed=JSON.parse_string(file.get_as_text()); file.close()
	if not (parsed is Dictionary): return false
	var data:Dictionary=parsed
	if int(data.get("version",0))!=SAVE_VERSION: return false
	var resources=get_tree().get_first_node_in_group("resource_manager")
	var settlement=get_tree().get_first_node_in_group("settlement_manager")
	var progression=get_tree().get_first_node_in_group("progression_manager")
	var meta=get_tree().get_first_node_in_group("meta_progression_manager")
	var parity=get_tree().get_first_node_in_group("stage10_settlement_parity")
	var wave=get_tree().get_first_node_in_group("raid_manager")
	var player=get_tree().get_first_node_in_group("player_combat")
	var units=get_tree().get_first_node_in_group("unit_manager")
	if resources==null or settlement==null or progression==null or wave==null or player==null or units==null: return false
	resources.import_state(data.get("resources",{}))
	settlement.import_state(data.get("settlement",{}))
	progression.import_state(data.get("progression",{}))
	units.import_state(data.get("units",{}))
	wave.import_state(data.get("wave",{}))
	player.import_state(data.get("player",{}))
	if meta != null and meta.has_method("import_state"):
		meta.import_state(data.get("meta",{}))
	if parity != null and parity.has_method("import_state"):
		parity.import_state(data.get("stage10",{}))
	last_save_unix=int(data.get("timestamp",0)); return true

func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH)) == OK
func get_status_text() -> String:
	return "Автосохранение каждые %dс" % int(autosave_interval) if last_save_unix<=0 else "Сохранено"
func reset_for_test() -> void:
	last_save_unix=0; last_load_found=false; _autosave_left=autosave_interval
