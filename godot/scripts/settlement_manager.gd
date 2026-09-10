extends Node
class_name SettlementManager

signal settlement_changed(snapshot: Dictionary)
signal building_built(building_id: String, level: int)
signal building_upgraded(building_id: String, level: int)
signal worker_recruited(worker_id: int)
signal activity_changed(text: String)
signal state_imported(snapshot: Dictionary)

const BUILDING_ORDER := ["lumber_camp", "quarry", "fishing_hut", "hunting_lodge", "kennel"]
const BUILDING_NAMES := {
	"town_hall":"Ратуша", "lumber_camp":"Лесопилка", "quarry":"Каменоломня", "fishing_hut":"Рыбацкая хижина",
	"hunting_lodge":"Охотничья изба", "kennel":"Псарня",
}
const BUILD_COSTS := {
	"lumber_camp":{"wood":18,"stone":4}, "quarry":{"wood":12,"stone":10}, "fishing_hut":{"wood":16,"stone":3,"food":5},
	"hunting_lodge":{"wood":50,"stone":20,"food":10}, "kennel":{"wood":150,"food":80},
}
const UPGRADE_BASE_COSTS := {
	"town_hall":{"wood":28,"stone":18,"gold":2}, "lumber_camp":{"wood":22,"stone":8}, "quarry":{"wood":14,"stone":20}, "fishing_hut":{"wood":20,"stone":8,"food":8},
}
const MAX_BUILDING_LEVEL := 3
const WORKER_COST := {"food":8,"wood":5}

var buildings: Dictionary = {"town_hall":1,"lumber_camp":0,"quarry":0,"fishing_hut":0,"hunting_lodge":0,"kennel":0}
var worker_count := 0
var last_activity := "Развивай лагерь и нанимай рабочих."
var _resource_manager = null

func _ready() -> void:
	add_to_group("settlement_manager")
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	_emit_snapshot()
	activity_changed.emit(last_activity)

func get_building_level(building_id: String) -> int: return int(buildings.get(building_id,0))
func get_worker_capacity() -> int: return 2 + get_building_level("town_hall") * 2
func get_build_cost(building_id: String) -> Dictionary: return (BUILD_COSTS.get(building_id,{}) as Dictionary).duplicate(true)
func get_upgrade_cost(building_id: String) -> Dictionary:
	var base: Dictionary = UPGRADE_BASE_COSTS.get(building_id,{})
	if base.is_empty(): return {}
	var level := maxi(1,get_building_level(building_id))
	var result: Dictionary = {}
	for key in base.keys(): result[key] = int(base[key]) * level
	return result
func can_build(building_id: String) -> bool: return get_building_level(building_id) <= 0 and BUILD_COSTS.has(building_id) and _can_afford(get_build_cost(building_id))
func build(building_id: String) -> bool:
	if not BUILD_COSTS.has(building_id) or get_building_level(building_id)>0: return false
	if not _spend(get_build_cost(building_id)):
		_set_activity("Не хватает ресурсов для: %s" % _building_name(building_id)); return false
	buildings[building_id]=1
	_set_activity("Построено: %s" % _building_name(building_id))
	building_built.emit(building_id,1); _emit_snapshot(); _request_save(); return true
func can_upgrade(building_id: String) -> bool:
	var level:=get_building_level(building_id)
	return level>0 and level<MAX_BUILDING_LEVEL and UPGRADE_BASE_COSTS.has(building_id) and _can_afford(get_upgrade_cost(building_id))
func upgrade(building_id: String) -> bool:
	if not can_upgrade(building_id): return false
	if not _spend(get_upgrade_cost(building_id)):
		_set_activity("Не хватает ресурсов для улучшения: %s" % _building_name(building_id)); return false
	var level:=get_building_level(building_id)+1; buildings[building_id]=level
	_set_activity("%s улучшена до уровня %d" % [_building_name(building_id),level]); building_upgraded.emit(building_id,level); _emit_snapshot(); _request_save(); return true
func can_recruit_worker() -> bool: return worker_count < get_worker_capacity() and _can_afford(WORKER_COST)
func recruit_worker() -> bool:
	if worker_count>=get_worker_capacity(): _set_activity("Лимит рабочих достигнут. Улучши ратушу."); return false
	if not _spend(WORKER_COST): _set_activity("Не хватает еды и дерева для найма рабочего."); return false
	worker_count+=1; _set_activity("Нанят рабочий #%d" % worker_count); worker_recruited.emit(worker_count); _emit_snapshot(); _request_save(); return true
func get_snapshot() -> Dictionary: return {"buildings":buildings.duplicate(true),"workers":worker_count,"worker_capacity":get_worker_capacity(),"activity":last_activity}
func export_state() -> Dictionary: return {"buildings":buildings.duplicate(true),"worker_count":worker_count,"last_activity":last_activity}
func import_state(data: Dictionary) -> void:
	var saved: Dictionary=data.get("buildings",{})
	buildings={"town_hall":1,"lumber_camp":0,"quarry":0,"fishing_hut":0,"hunting_lodge":0,"kennel":0}
	for id in buildings.keys():
		var min_level:=1 if str(id)=="town_hall" else 0
		var max_level:=MAX_BUILDING_LEVEL if UPGRADE_BASE_COSTS.has(id) else 1
		buildings[id]=clampi(int(saved.get(id,min_level)),min_level,max_level)
	worker_count=clampi(int(data.get("worker_count",0)),0,get_worker_capacity())
	last_activity=str(data.get("last_activity",last_activity))
	var snapshot:=get_snapshot(); settlement_changed.emit(snapshot); activity_changed.emit(last_activity)
	for id in BUILDING_ORDER: building_upgraded.emit(id,get_building_level(id))
	for worker_id in range(1,worker_count+1): worker_recruited.emit(worker_id)
	state_imported.emit(snapshot)
func _can_afford(cost: Dictionary) -> bool: _bind_resource_manager(); return _resource_manager!=null and bool(_resource_manager.can_afford_stored(cost))
func _spend(cost: Dictionary) -> bool: _bind_resource_manager(); return _resource_manager!=null and bool(_resource_manager.spend_stored(cost))
func _bind_resource_manager() -> void:
	if _resource_manager==null or not is_instance_valid(_resource_manager): _resource_manager=get_tree().get_first_node_in_group("resource_manager")
func _building_name(id: String) -> String: return str(BUILDING_NAMES.get(id,id))
func _set_activity(text: String) -> void:
	last_activity=text; activity_changed.emit(text)
	if _resource_manager!=null and _resource_manager.has_method("report_activity"): _resource_manager.report_activity(text)
func _request_save() -> void:
	var saver=get_tree().get_first_node_in_group("save_manager")
	if saver!=null and saver.has_method("save_game"): saver.call_deferred("save_game")
func _emit_snapshot() -> void: settlement_changed.emit(get_snapshot())
func reset_for_test() -> void:
	buildings={"town_hall":1,"lumber_camp":0,"quarry":0,"fishing_hut":0,"hunting_lodge":0,"kennel":0}; worker_count=0; last_activity=""; _emit_snapshot()
