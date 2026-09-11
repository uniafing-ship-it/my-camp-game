extends Node3D
class_name UnitManager

signal units_changed(snapshot: Dictionary)
signal activity_changed(text: String)

const UnitScript = preload("res://scripts/camp_unit.gd")
const CAMP_HEAL_RADIUS := 12.0

var counts: Dictionary = {"foot":0, "hunter":0, "dog":0}
var last_activity := "Собери отряд для защиты лагеря."
var _resource_manager = null
var _settlement_manager = null
var _progression_manager = null
var _meta_progression_manager = null
var _spawn_serial := 0
var _heal_accum := 0.0

func _ready() -> void:
	add_to_group("unit_manager")
	call_deferred("_bind")

func _process(delta: float) -> void:
	_heal_accum += delta
	if _heal_accum < 1.0:
		return
	var ticks := mini(4, int(floor(_heal_accum)))
	_heal_accum -= float(ticks)
	_bind_managers()
	var heal_per_tick := 1 + _settlement_level("infirmary")
	for unit in get_tree().get_nodes_in_group("camp_defenders"):
		if not (unit is Node3D) or not is_instance_valid(unit):
			continue
		if unit.has_method("is_alive") and not bool(unit.is_alive()):
			continue
		if (unit as Node3D).global_position.length() > CAMP_HEAL_RADIUS:
			continue
		unit.health = mini(int(unit.max_health), int(unit.health) + heal_per_tick * ticks)

func _bind() -> void:
	_bind_managers()
	if _progression_manager != null and _progression_manager.has_signal("research_completed"):
		var research_cb := Callable(self, "_on_research_completed")
		if not _progression_manager.is_connected("research_completed", research_cb):
			_progression_manager.connect("research_completed", research_cb)
	if _settlement_manager != null:
		for signal_name in ["building_built", "building_upgraded"]:
			if _settlement_manager.has_signal(signal_name):
				var cb := Callable(self, "_on_building_changed")
				if not _settlement_manager.is_connected(signal_name, cb):
					_settlement_manager.connect(signal_name, cb)
		if _settlement_manager.has_signal("state_imported"):
			var import_cb := Callable(self, "_on_settlement_imported")
			if not _settlement_manager.is_connected("state_imported", import_cb):
				_settlement_manager.connect("state_imported", import_cb)
	_emit()

func get_count(kind: String) -> int:
	return int(counts.get(kind, 0))

func get_capacity(kind: String) -> int:
	_bind_managers()
	match kind:
		"foot":
			return 12 + 4 * _settlement_level("barracks")
		"hunter":
			var level := _settlement_level("hunting_lodge")
			return 1 + 2 * level if level > 0 else 0
		"dog":
			var level := _settlement_level("kennel")
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
	if kind == "hunter" and _settlement_level("hunting_lodge") <= 0:
		return false
	if kind == "dog" and _settlement_level("kennel") <= 0:
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
	_configure_unit(unit, kind)
	_spawn_serial += 1
	var angle := TAU * float(_spawn_serial % 12) / 12.0
	unit.position = Vector3(cos(angle) * 4.2, 0.1, sin(angle) * 4.2)
	unit.died.connect(_on_unit_died)
	add_child(unit)

func _configure_unit(unit: Node, kind: String) -> void:
	_bind_managers()
	var hp_bonus := _unit_hp_bonus()
	var training := _settlement_level("training_ground")
	var flat_damage := _meta_flat_damage_bonus()
	var damage_multiplier := _meta_damage_multiplier()
	match kind:
		"foot":
			unit.max_health = 48 + hp_bonus
			unit.attack_damage = maxi(1, int(round(float(12 + training * 6 + flat_damage) * damage_multiplier)))
			unit.attack_range = 1.8
			unit.attack_interval = maxf(0.4, 0.82 * pow(0.95, training))
		"hunter":
			unit.max_health = 36 + hp_bonus
			unit.attack_damage = maxi(1, int(round(float(9 + int(floor(float(training) / 2.0)) * 4 + flat_damage) * damage_multiplier)))
			unit.attack_range = 7.2
			unit.attack_interval = 1.15
			unit.scan_radius = 21.0
		"dog":
			unit.max_health = 30 + hp_bonus
			unit.attack_damage = maxi(1, int(round(float(10 + maxi(0, _settlement_level("kennel") - 1) * 4 + _dog_damage_bonus() + flat_damage) * damage_multiplier)))
			unit.move_speed = 5.0
			unit.attack_range = 1.4
			unit.attack_interval = 0.65

func _refresh_existing_units() -> void:
	_bind_managers()
	for unit in get_tree().get_nodes_in_group("camp_defenders") + get_tree().get_nodes_in_group("expedition_reserved_units"):
		if unit == null or not is_instance_valid(unit):
			continue
		var old_health := int(unit.health)
		_configure_unit(unit, str(unit.unit_kind))
		unit.health = mini(old_health, int(unit.max_health))
	_emit()

func refresh_meta_effects() -> void:
	_refresh_existing_units()

func _on_unit_died(kind: String, _unit: Node) -> void:
	counts[kind] = maxi(0, get_count(kind) - 1)
	_set_activity("Потерян: %s" % _unit_name(kind))
	_emit()

func _on_research_completed(research_id: String) -> void:
	if research_id == "armor" or research_id == "hounds":
		_refresh_existing_units()

func _on_building_changed(building_id: String, _level: int) -> void:
	if building_id in ["barracks", "infirmary", "training_ground", "kennel", "hunting_lodge"]:
		_refresh_existing_units()

func _on_settlement_imported(_snapshot: Dictionary) -> void:
	_refresh_existing_units()

func _clear_units() -> void:
	for node in get_tree().get_nodes_in_group("camp_defenders") + get_tree().get_nodes_in_group("expedition_reserved_units"):
		if node != null and is_instance_valid(node):
			node.queue_free()

func _unit_hp_bonus() -> int:
	var research_bonus := int(_progression_manager.get_unit_hp_bonus()) if _progression_manager != null and _progression_manager.has_method("get_unit_hp_bonus") else 0
	return research_bonus + 2 * _settlement_level("infirmary")

func _dog_damage_bonus() -> int:
	return int(_progression_manager.get_dog_damage_bonus()) if _progression_manager != null and _progression_manager.has_method("get_dog_damage_bonus") else 0

func _meta_flat_damage_bonus() -> int:
	return int(_meta_progression_manager.get_flat_damage_bonus()) if _meta_progression_manager != null and _meta_progression_manager.has_method("get_flat_damage_bonus") else 0

func _meta_damage_multiplier() -> float:
	return float(_meta_progression_manager.get_damage_multiplier()) if _meta_progression_manager != null and _meta_progression_manager.has_method("get_damage_multiplier") else 1.0

func _has_research(research_id: String) -> bool:
	_bind_managers()
	return _progression_manager != null and _progression_manager.has_method("has_research") and bool(_progression_manager.has_research(research_id))

func _settlement_level(building_id: String) -> int:
	_bind_managers()
	return int(_settlement_manager.get_building_level(building_id)) if _settlement_manager != null else 0

func _bind_managers() -> void:
	if _resource_manager == null or not is_instance_valid(_resource_manager):
		_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if _settlement_manager == null or not is_instance_valid(_settlement_manager):
		_settlement_manager = get_tree().get_first_node_in_group("settlement_manager")
	if _progression_manager == null or not is_instance_valid(_progression_manager):
		_progression_manager = get_tree().get_first_node_in_group("progression_manager")
	if _meta_progression_manager == null or not is_instance_valid(_meta_progression_manager):
		_meta_progression_manager = get_tree().get_first_node_in_group("meta_progression_manager")

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
	units_changed.emit({
		"counts":counts.duplicate(true),
		"capacities":{"foot":get_capacity("foot"), "hunter":get_capacity("hunter"), "dog":get_capacity("dog")},
		"infirmary_heal_rate":1 + _settlement_level("infirmary"),
		"training_level":_settlement_level("training_ground"),
		"activity":last_activity,
	})

func reset_for_test() -> void:
	_clear_units()
	counts = {"foot":0, "hunter":0, "dog":0}
	last_activity = ""
	_heal_accum = 0.0
	_emit()
