extends Node
class_name SettlementManager

signal settlement_changed(snapshot: Dictionary)
signal building_built(building_id: String, level: int)
signal building_upgraded(building_id: String, level: int)
signal worker_recruited(worker_id: int)
signal activity_changed(text: String)

const BUILDING_ORDER := ["lumber_camp", "quarry", "fishing_hut"]
const BUILDING_NAMES := {
	"town_hall": "Ратуша",
	"lumber_camp": "Лесопилка",
	"quarry": "Каменоломня",
	"fishing_hut": "Рыбацкая хижина",
}
const BUILD_COSTS := {
	"lumber_camp": {"wood": 18, "stone": 4},
	"quarry": {"wood": 12, "stone": 10},
	"fishing_hut": {"wood": 16, "stone": 3, "food": 5},
}
const UPGRADE_BASE_COSTS := {
	"town_hall": {"wood": 28, "stone": 18, "gold": 2},
	"lumber_camp": {"wood": 22, "stone": 8},
	"quarry": {"wood": 14, "stone": 20},
	"fishing_hut": {"wood": 20, "stone": 8, "food": 8},
}
const MAX_BUILDING_LEVEL := 3
const WORKER_COST := {"food": 8, "wood": 5}

var buildings: Dictionary = {
	"town_hall": 1,
	"lumber_camp": 0,
	"quarry": 0,
	"fishing_hut": 0,
}
var worker_count: int = 0
var last_activity: String = "Развивай лагерь и нанимай рабочих."
var _resource_manager = null

func _ready() -> void:
	add_to_group("settlement_manager")
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	_emit_snapshot()
	activity_changed.emit(last_activity)

func get_building_level(building_id: String) -> int:
	return int(buildings.get(building_id, 0))

func get_worker_capacity() -> int:
	return 2 + get_building_level("town_hall") * 2

func get_build_cost(building_id: String) -> Dictionary:
	var source = BUILD_COSTS.get(building_id, {})
	return (source as Dictionary).duplicate(true)

func get_upgrade_cost(building_id: String) -> Dictionary:
	var base: Dictionary = UPGRADE_BASE_COSTS.get(building_id, {})
	if base.is_empty():
		return {}
	var level := maxi(1, get_building_level(building_id))
	var result: Dictionary = {}
	for key in base.keys():
		result[key] = int(base[key]) * level
	return result

func can_build(building_id: String) -> bool:
	if get_building_level(building_id) > 0:
		return false
	return _can_afford(get_build_cost(building_id))

func build(building_id: String) -> bool:
	if not BUILD_COSTS.has(building_id) or get_building_level(building_id) > 0:
		return false
	var cost := get_build_cost(building_id)
	if not _spend(cost):
		_set_activity("Не хватает ресурсов для: %s" % _building_name(building_id))
		return false
	buildings[building_id] = 1
	_set_activity("Построено: %s" % _building_name(building_id))
	building_built.emit(building_id, 1)
	_emit_snapshot()
	return true

func can_upgrade(building_id: String) -> bool:
	var level := get_building_level(building_id)
	if level <= 0 or level >= MAX_BUILDING_LEVEL:
		return false
	return _can_afford(get_upgrade_cost(building_id))

func upgrade(building_id: String) -> bool:
	var level := get_building_level(building_id)
	if level <= 0 or level >= MAX_BUILDING_LEVEL:
		return false
	var cost := get_upgrade_cost(building_id)
	if not _spend(cost):
		_set_activity("Не хватает ресурсов для улучшения: %s" % _building_name(building_id))
		return false
	level += 1
	buildings[building_id] = level
	_set_activity("%s улучшена до уровня %d" % [_building_name(building_id), level])
	building_upgraded.emit(building_id, level)
	_emit_snapshot()
	return true

func can_recruit_worker() -> bool:
	if worker_count >= get_worker_capacity():
		return false
	return _can_afford(WORKER_COST)

func recruit_worker() -> bool:
	if worker_count >= get_worker_capacity():
		_set_activity("Лимит рабочих достигнут. Улучши ратушу.")
		return false
	if not _spend(WORKER_COST):
		_set_activity("Не хватает еды и дерева для найма рабочего.")
		return false
	worker_count += 1
	_set_activity("Нанят рабочий #%d" % worker_count)
	worker_recruited.emit(worker_count)
	_emit_snapshot()
	return true

func get_snapshot() -> Dictionary:
	return {
		"buildings": buildings.duplicate(true),
		"workers": worker_count,
		"worker_capacity": get_worker_capacity(),
		"activity": last_activity,
	}

func _can_afford(cost: Dictionary) -> bool:
	_bind_resource_manager()
	return _resource_manager != null and _resource_manager.has_method("can_afford_stored") and bool(_resource_manager.can_afford_stored(cost))

func _spend(cost: Dictionary) -> bool:
	_bind_resource_manager()
	return _resource_manager != null and _resource_manager.has_method("spend_stored") and bool(_resource_manager.spend_stored(cost))

func _bind_resource_manager() -> void:
	if _resource_manager == null:
		_resource_manager = get_tree().get_first_node_in_group("resource_manager")

func _building_name(building_id: String) -> String:
	return str(BUILDING_NAMES.get(building_id, building_id))

func _set_activity(text: String) -> void:
	last_activity = text
	activity_changed.emit(text)
	if _resource_manager != null and _resource_manager.has_method("report_activity"):
		_resource_manager.report_activity(text)

func _emit_snapshot() -> void:
	settlement_changed.emit(get_snapshot())

func reset_for_test() -> void:
	buildings = {"town_hall": 1, "lumber_camp": 0, "quarry": 0, "fishing_hut": 0}
	worker_count = 0
	last_activity = ""
	_emit_snapshot()
