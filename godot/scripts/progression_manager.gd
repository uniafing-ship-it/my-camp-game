extends Node
class_name ProgressionManager

signal progression_changed(snapshot: Dictionary)
signal quest_completed(quest_id: String, reward: Dictionary)
signal research_completed(research_id: String)
signal activity_changed(text: String)

const BASE_CARRY_CAPACITY := 30
const RESEARCH := {
	"axes": {"name":"ЗАТОЧЕННЫЕ ТОПОРЫ", "description":"+1 ко всей добыче", "cost":{"gold":30,"wood":100}},
	"bags": {"name":"КРЕПКИЕ МЕШКИ", "description":"+6 к рюкзаку", "cost":{"gold":25,"wood":80}},
	"armor": {"name":"КЛЁПАНАЯ БРОНЯ", "description":"+3 здоровья бойцам", "cost":{"gold":40,"stone":120}},
	"arrows": {"name":"ЭЛЬФИЙСКИЕ СТРЕЛЫ", "description":"+1 к базовому урону башен", "cost":{"gold":60,"stone":150}},
	"walls": {"name":"КАМЕННАЯ КЛАДКА", "description":"стены замедляют врагов сильнее", "cost":{"gold":50,"stone":200}},
	"hounds": {"name":"БОЕВЫЕ ПСЫ", "description":"псы +2 урона, найм дешевле по шкурам", "cost":{"gold":45,"pelts":5}},
}
const RESEARCH_ORDER := ["axes", "bags", "armor", "arrows", "walls", "hounds"]
const QUESTS := [
	{"id":"wood30", "title":"Сдай на склад 30 🌲", "type":"gathered", "key":"wood", "target":30, "reward":{"food":10}},
	{"id":"lumber", "title":"Построй ЛЕСОПИЛКУ", "type":"building", "key":"lumber_camp", "target":1, "reward":{"wood":30}},
	{"id":"food20", "title":"Собери 20 🍓 (кусты/охота)", "type":"gathered", "key":"food", "target":20, "reward":{"gold":10}},
	{"id":"bear1", "title":"Убей медведя 🐻", "type":"animal", "key":"bear", "target":1, "reward":{"gold":10}},
	{"id":"workers2", "title":"Найми 2 крестьян", "type":"workers", "key":"", "target":2, "reward":{"stone":30}},
	{"id":"boar1", "title":"Убей кабана 🐗", "type":"animal", "key":"boar", "target":1, "reward":{"food":20}},
	{"id":"carc3", "title":"Разделай 3 туши 🔪", "type":"carcasses", "key":"", "target":3, "reward":{"gold":20}},
	{"id":"deer1", "title":"Убей оленя 🦌", "type":"animal", "key":"deer", "target":1, "reward":{"food":20}},
]

var researched: Array[String] = []
var quest_index: int = 0
var gathered: Dictionary = {"wood":0, "stone":0, "food":0, "gold":0, "pelts":0}
var kills: int = 0
var upgrades: int = 0
var animal_kills: Dictionary = {"bear":0, "boar":0, "deer":0, "rabbit":0}
var carcasses_skinned: int = 0
var last_activity: String = "Выполняй задания и открывай исследования."

var _resource_manager = null
var _settlement_manager = null
var _wildlife_manager = null
var _scan_accum := 0.0

func _ready() -> void:
	add_to_group("progression_manager")
	call_deferred("_bind")

func _process(delta: float) -> void:
	_scan_accum += delta
	if _scan_accum >= 0.45:
		_scan_accum = 0.0
		_bind_dynamic_sources()
		_bind_wildlife()
		_update_quest()

func _bind() -> void:
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	_settlement_manager = get_tree().get_first_node_in_group("settlement_manager")
	if _settlement_manager != null:
		var upgrade_cb := Callable(self, "_on_building_upgraded")
		if _settlement_manager.has_signal("building_upgraded") and not _settlement_manager.is_connected("building_upgraded", upgrade_cb):
			_settlement_manager.connect("building_upgraded", upgrade_cb)
		var settlement_cb := Callable(self, "_on_settlement_changed")
		if _settlement_manager.has_signal("settlement_changed") and not _settlement_manager.is_connected("settlement_changed", settlement_cb):
			_settlement_manager.connect("settlement_changed", settlement_cb)
	_bind_dynamic_sources()
	_bind_wildlife()
	_apply_research_effects()
	_emit_snapshot()

func _bind_dynamic_sources() -> void:
	for node in get_tree().get_nodes_in_group("harvestables"):
		if node == null or not is_instance_valid(node) or not node.has_signal("harvested"):
			continue
		var harvest_cb := Callable(self, "_on_harvested")
		if not node.is_connected("harvested", harvest_cb):
			node.connect("harvested", harvest_cb)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy) or not enemy.has_signal("died"):
			continue
		var enemy_cb := Callable(self, "_on_enemy_died")
		if not enemy.is_connected("died", enemy_cb):
			enemy.connect("died", enemy_cb)

func _bind_wildlife() -> void:
	if _wildlife_manager == null or not is_instance_valid(_wildlife_manager):
		_wildlife_manager = get_tree().get_first_node_in_group("wildlife_manager")
	if _wildlife_manager == null:
		return
	var kill_cb := Callable(self, "_on_animal_killed")
	if _wildlife_manager.has_signal("animal_killed") and not _wildlife_manager.is_connected("animal_killed", kill_cb):
		_wildlife_manager.connect("animal_killed", kill_cb)
	var carcass_cb := Callable(self, "_on_carcass_skinned")
	if _wildlife_manager.has_signal("carcass_skinned") and not _wildlife_manager.is_connected("carcass_skinned", carcass_cb):
		_wildlife_manager.connect("carcass_skinned", carcass_cb)

func _on_harvested(resource_type: String, amount: int, _remaining: int) -> void:
	if amount <= 0 or not gathered.has(resource_type):
		return
	gathered[resource_type] = int(gathered[resource_type]) + amount
	_update_quest()
	_emit_snapshot()

func _on_enemy_died(_enemy: Node) -> void:
	kills += 1
	_update_quest()
	_emit_snapshot()

func _on_animal_killed(kind: String, food: int, pelts: int) -> void:
	if animal_kills.has(kind):
		animal_kills[kind] = int(animal_kills[kind]) + 1
	gathered["food"] = int(gathered["food"]) + maxi(0, food)
	gathered["pelts"] = int(gathered["pelts"]) + maxi(0, pelts)
	_update_quest()
	_emit_snapshot()

func _on_carcass_skinned(_kind: String) -> void:
	carcasses_skinned += 1
	_update_quest()
	_emit_snapshot()

func _on_building_upgraded(_building_id: String, _level: int) -> void:
	upgrades += 1
	_emit_snapshot()

func _on_settlement_changed(_snapshot: Dictionary) -> void:
	_update_quest()
	_emit_snapshot()

func can_research(research_id: String) -> bool:
	if researched.has(research_id) or not RESEARCH.has(research_id):
		return false
	_bind_managers()
	var cost: Dictionary = RESEARCH[research_id]["cost"]
	return _resource_manager != null and bool(_resource_manager.can_afford_stored(cost))

func research(research_id: String) -> bool:
	if not can_research(research_id):
		return false
	var cost: Dictionary = RESEARCH[research_id]["cost"]
	if not bool(_resource_manager.spend_stored(cost)):
		return false
	researched.append(research_id)
	_apply_research_effects()
	last_activity = "Изучено: %s" % str(RESEARCH[research_id]["name"])
	activity_changed.emit(last_activity)
	research_completed.emit(research_id)
	_emit_snapshot()
	_request_save()
	return true

func has_research(research_id: String) -> bool:
	return researched.has(research_id)

func get_harvest_bonus(_resource_type: String = "") -> int:
	return 1 if researched.has("axes") else 0

func get_carry_bonus() -> int:
	return 6 if researched.has("bags") else 0

func get_unit_hp_bonus() -> int:
	return 3 if researched.has("armor") else 0

func get_tower_damage_bonus() -> int:
	return 1 if researched.has("arrows") else 0

func get_wall_slow_bonus() -> float:
	return 0.1 if researched.has("walls") else 0.0

func get_dog_damage_bonus() -> int:
	return 2 if researched.has("hounds") else 0

func get_research_snapshot() -> Array:
	var result: Array = []
	for research_id in RESEARCH_ORDER:
		var item: Dictionary = RESEARCH[research_id]
		result.append({
			"id": research_id,
			"name": item["name"],
			"description": item["description"],
			"cost": (item["cost"] as Dictionary).duplicate(true),
			"owned": researched.has(research_id),
			"can_buy": can_research(research_id),
		})
	return result

func get_current_quest() -> Dictionary:
	if quest_index >= QUESTS.size():
		return {"complete":true, "title":"Доступная цепочка заданий выполнена", "progress":"Следующие задания откроются с переносом новых систем", "reward":{}}
	var quest: Dictionary = QUESTS[quest_index]
	var value := _quest_value(quest)
	var target := int(quest["target"])
	return {
		"complete": false,
		"id": str(quest["id"]),
		"title": str(quest["title"]),
		"progress": "%d/%d" % [mini(value, target), target],
		"value": value,
		"target": target,
		"reward": (quest["reward"] as Dictionary).duplicate(true),
	}

func get_snapshot() -> Dictionary:
	return {
		"researched": researched.duplicate(),
		"quest_index": quest_index,
		"quest": get_current_quest(),
		"gathered": gathered.duplicate(true),
		"kills": kills,
		"upgrades": upgrades,
		"animal_kills": animal_kills.duplicate(true),
		"carcasses_skinned": carcasses_skinned,
		"last_activity": last_activity,
	}

func export_state() -> Dictionary:
	return get_snapshot()

func import_state(data: Dictionary) -> void:
	researched.clear()
	for value in data.get("researched", []):
		var research_id := str(value)
		if RESEARCH.has(research_id):
			researched.append(research_id)
	quest_index = clampi(int(data.get("quest_index", 0)), 0, QUESTS.size())
	var saved_gathered: Dictionary = data.get("gathered", {})
	for key in gathered.keys():
		gathered[key] = maxi(0, int(saved_gathered.get(key, 0)))
	kills = maxi(0, int(data.get("kills", 0)))
	upgrades = maxi(0, int(data.get("upgrades", 0)))
	var saved_animal_kills: Dictionary = data.get("animal_kills", {})
	for kind in animal_kills.keys():
		animal_kills[kind] = maxi(0, int(saved_animal_kills.get(kind, 0)))
	carcasses_skinned = maxi(0, int(data.get("carcasses_skinned", 0)))
	last_activity = str(data.get("last_activity", last_activity))
	_apply_research_effects()
	_emit_snapshot()

func _update_quest() -> void:
	var completed_any := false
	while quest_index < QUESTS.size():
		var quest: Dictionary = QUESTS[quest_index]
		if _quest_value(quest) < int(quest["target"]):
			break
		_bind_managers()
		var reward: Dictionary = quest["reward"]
		if _resource_manager != null:
			for resource_type in reward.keys():
				_resource_manager.add_stored(str(resource_type), int(reward[resource_type]))
		last_activity = "Задание выполнено: %s" % str(quest["title"])
		activity_changed.emit(last_activity)
		quest_completed.emit(str(quest["id"]), reward.duplicate(true))
		quest_index += 1
		completed_any = true
	if completed_any:
		_emit_snapshot()
		_request_save()

func _quest_value(quest: Dictionary) -> int:
	match str(quest["type"]):
		"gathered":
			return int(gathered.get(str(quest["key"]), 0))
		"building":
			_bind_managers()
			if _settlement_manager != null:
				return 1 if int(_settlement_manager.get_building_level(str(quest["key"]))) > 0 else 0
		"workers":
			_bind_managers()
			if _settlement_manager != null:
				return int(_settlement_manager.worker_count)
		"kills":
			return kills
		"animal":
			return int(animal_kills.get(str(quest["key"]), 0))
		"carcasses":
			return carcasses_skinned
	return 0

func _apply_research_effects() -> void:
	_bind_managers()
	if _resource_manager != null:
		_resource_manager.carry_capacity = BASE_CARRY_CAPACITY + get_carry_bonus()
		_resource_manager.inventory_changed.emit(_resource_manager.carried.duplicate(true), _resource_manager.stored.duplicate(true))

func _bind_managers() -> void:
	if _resource_manager == null or not is_instance_valid(_resource_manager):
		_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if _settlement_manager == null or not is_instance_valid(_settlement_manager):
		_settlement_manager = get_tree().get_first_node_in_group("settlement_manager")

func _request_save() -> void:
	var save_manager = get_tree().get_first_node_in_group("save_manager")
	if save_manager != null and save_manager.has_method("save_game"):
		save_manager.call_deferred("save_game")

func _emit_snapshot() -> void:
	progression_changed.emit(get_snapshot())

func reset_for_test() -> void:
	researched.clear()
	quest_index = 0
	gathered = {"wood":0, "stone":0, "food":0, "gold":0, "pelts":0}
	kills = 0
	upgrades = 0
	animal_kills = {"bear":0, "boar":0, "deer":0, "rabbit":0}
	carcasses_skinned = 0
	last_activity = ""
	_apply_research_effects()
	_emit_snapshot()
