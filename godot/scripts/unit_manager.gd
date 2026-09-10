extends Node3D
class_name UnitManager

signal units_changed(snapshot: Dictionary)
signal activity_changed(text: String)

const UnitScript = preload("res://scripts/camp_unit.gd")

var counts: Dictionary = {"foot":0, "hunter":0, "dog":0}
var last_activity := "Собери отряд для защиты лагеря."
var _resource_manager = null
var _settlement_manager = null
var _progression_manager = null
var _spawn_serial := 0

func _ready() -> void:
	add_to_group("unit_manager")
	call_deferred("_bind")

func _bind() -> void:
	_bind_managers()
	if _progression_manager != null and _progression_manager.has_signal("research_completed"):
		var research_cb := Callable(self, "_on_research_completed")
		if not _progression_manager.is_connected("research_completed", research_cb):
			_progression_manager.connect("research_completed", research_cb)
	_emit()

func get_count(kind: String) -> int:
	return int(counts.get(kind, 0))

func get_capacity(kind: String) -> int:
	_bind_managers()
	match kind:
		"foot":
			return 12
		"hunter":
			var level := int(_settlement_manager.get_building_level("hunting_lodge")) if _settlement_manager else 0
			return 1 + 2 * level if level > 0 else 0
		"dog":
			var level := int(_settlement_manager.get_building_level("kennel")) if _settlement_manager else 0
			return 2 + 3 * level if level > 0 else 0
	return 0

func get_recruit_cost(kind: String) -> Dictionary:
	var current := get_count(kind)
	match kind:
		"foot":
			return {"food":25 + current * 12, "stone":15 + current * 10, "gold":current * 5}
		"hunter":
			return {"food":20 + current * 10, "wood":30 + current * 10}
		"dog":
			var pelt_base := 1 if _has_research("hounds") else 2
			return {"food":12 + current * 6, "pelts":pelt_base + current}
	return {}

func can_recruit(kind: String) -> bool:
	_bind_managers()
	if get_count(kind) >= get_capacity(kind):
		return false
	if kind == "hunter" and (_settlement_manager == null or int(_settlement_manager.get_building_level("hunting_lodge")) <= 0):
		return false
	if kind == "dog" and (_settlement_manager == null or int(_settlement_manager.get_building_level("kennel")) <= 0):
		return false
	return _resource_manager != null and bool(_resource_manager.can_afford_stored(get_recruit_cost(kind)))

func recruit(kind: String) -> bool:
	if not can_recruit(kind):
		_set_activity("Нельзя нанять: %s" % _unit_name(kind))
		return false
	if not bool(_resource_manager.spend_stored(get_recruit_cost(kind))):
		return false
	counts[kind] = get_count(kind) + 1
	_spawn_unit(kind)
	_set_activity("Нанят: %s" % _unit_name(kind))
	_emit()
	_request_save()
	return true

func export_state() -> Dictionary:
	return {"counts":counts.duplicate(true), "last_activity":last_activity}

func import_state(data: Dictionary) -> void:
	_clear_units()
	var saved: Dictionary = data.get("counts", {})
	for kind in counts.keys():
		counts[kind] = clampi(int(saved.get(kind, 0)), 0, get_capacity(str(kind)))
	last_activity = str(data.get("last_activity", last_activity))
	for kind in ["foot", "hunter", "dog"]:
		for _i in range(get_count(kind)):
			_spawn_unit(kind)
	_emit()

func _spawn_unit(kind: String) -> void:
	var unit = UnitScript.new()
	unit.unit_kind = kind
	match kind:
		"foot":
			unit.max_health = 48 + _unit_hp_bonus()
			unit.attack_damage = 12
			unit.attack_range = 1.8
			unit.attack_interval = 0.82
		"hunter":
			unit.max_health = 36 + _unit_hp_bonus()
			unit.attack_damage = 9
			unit.attack_range = 7.2
			unit.attack_interval = 1.15
			unit.scan_radius = 21.0
		"dog":
			unit.max_health = 30 + _unit_hp_bonus()
			unit.attack_damage = 10 + _dog_damage_bonus()
			unit.move_speed = 5.0
			unit.attack_range = 1.4
			unit.attack_interval = 0.65
	_spawn_serial += 1
	var angle := TAU * float(_spawn_serial % 12) / 12.0
	unit.position = Vector3(cos(angle) * 4.2, 0.1, sin(angle) * 4.2)
	unit.died.connect(_on_unit_died)
	add_child(unit)

func _on_unit_died(kind: String, _unit: Node) -> void:
	counts[kind] = maxi(0, get_count(kind) - 1)
	_set_activity("Потерян: %s" % _unit_name(kind))
	_emit()

func _on_research_completed(research_id: String) -> void:
	if research_id != "armor" and research_id != "hounds":
		return
	for unit in get_tree().get_nodes_in_group("camp_defenders"):
		if unit == null or not is_instance_valid(unit):
			continue
		if research_id == "armor":
			unit.max_health = int(unit.max_health) + 3
			unit.health = int(unit.health) + 3
		elif str(unit.unit_kind) == "dog":
			unit.attack_damage = int(unit.attack_damage) + 2
	_emit()

func _clear_units() -> void:
	for node in get_tree().get_nodes_in_group("camp_defenders"):
		if node != null and is_instance_valid(node):
			node.queue_free()

func _unit_hp_bonus() -> int:
	return int(_progression_manager.get_unit_hp_bonus()) if _progression_manager != null and _progression_manager.has_method("get_unit_hp_bonus") else 0

func _dog_damage_bonus() -> int:
	return int(_progression_manager.get_dog_damage_bonus()) if _progression_manager != null and _progression_manager.has_method("get_dog_damage_bonus") else 0

func _has_research(research_id: String) -> bool:
	_bind_managers()
	return _progression_manager != null and _progression_manager.has_method("has_research") and bool(_progression_manager.has_research(research_id))

func _bind_managers() -> void:
	if _resource_manager == null or not is_instance_valid(_resource_manager):
		_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if _settlement_manager == null or not is_instance_valid(_settlement_manager):
		_settlement_manager = get_tree().get_first_node_in_group("settlement_manager")
	if _progression_manager == null or not is_instance_valid(_progression_manager):
		_progression_manager = get_tree().get_first_node_in_group("progression_manager")

func _set_activity(text: String) -> void:
	last_activity = text
	activity_changed.emit(text)
	if _resource_manager != null and _resource_manager.has_method("report_activity"):
		_resource_manager.report_activity(text)

func _unit_name(kind: String) -> String:
	match kind:
		"foot": return "воин"
		"hunter": return "охотник"
		"dog": return "пёс"
	return kind

func _request_save() -> void:
	var saver = get_tree().get_first_node_in_group("save_manager")
	if saver != null and saver.has_method("save_game"):
		saver.call_deferred("save_game")

func _emit() -> void:
	units_changed.emit({"counts":counts.duplicate(true), "capacities":{"foot":get_capacity("foot"), "hunter":get_capacity("hunter"), "dog":get_capacity("dog")}, "activity":last_activity})

func reset_for_test() -> void:
	_clear_units()
	counts = {"foot":0, "hunter":0, "dog":0}
	last_activity = ""
	_emit()
