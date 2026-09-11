extends Node
class_name MetaProgressionManager

signal meta_changed(snapshot: Dictionary)
signal expedition_started(slot_index: int, expedition_id: String)
signal expedition_finished(slot_index: int, expedition_id: String, reward: Dictionary)
signal achievement_unlocked(achievement_id: String, reward_gold: int)
signal relic_unlocked(relic_id: String)
signal hero_level_changed(level: int, xp: int)
signal ascended(fame_gained: int, total_fame: int)
signal activity_changed(text: String)

const EXPEDITION_ORDER := ["scout", "supplies", "ruins"]
const EXPEDITIONS := {
	"scout": {"name":"РАЗВЕДКА", "duration":60.0, "soldiers":2, "workers":0, "description":"2 бойца · золото и ресурсы"},
	"supplies": {"name":"СБОР ПРИПАСОВ", "duration":90.0, "soldiers":0, "workers":2, "description":"2 рабочих · много ресурсов"},
	"ruins": {"name":"ДРЕВНИЕ РУИНЫ", "duration":150.0, "soldiers":3, "workers":2, "description":"3 бойца + 2 рабочих · шанс реликвии"},
}
const RELIC_ORDER := ["banner", "sickle", "pouch", "boots", "orb", "horn"]
const RELICS := {
	"banner": {"name":"ЗНАМЯ ВОЙНЫ", "icon":"🚩", "description":"урон героя и бойцов +1"},
	"sickle": {"name":"ЗОЛОТОЙ СЕРП", "icon":"🌾", "description":"добыча +1"},
	"pouch": {"name":"МЕШОК ДЕРЖАНИЯ", "icon":"👝", "description":"рюкзак +6"},
	"boots": {"name":"ЗНАМЯ СПЕШКИ", "icon":"🏳️", "description":"рабочие двигаются на 15% быстрее"},
	"orb": {"name":"ЗОЛОТОЙ ОРБ", "icon":"🔮", "description":"золото за убийства ×2"},
	"horn": {"name":"РОГ ДЕРЕВНИ", "icon":"📯", "description":"запас переноски жителей +2"},
}
const ACHIEVEMENT_ORDER := [
	"wood1", "food1", "bears1", "beast1", "pelts1", "carc1", "kill1",
	"build1", "build2", "res1", "rel1", "hero1", "exp10", "fame1",
]
const ACHIEVEMENTS := {
	"wood1": {"name":"Первый лес", "description":"Собери 100 🌲", "reward":20},
	"food1": {"name":"Гурман", "description":"Собери 100 🍓", "reward":40},
	"bears1": {"name":"Медвежатник", "description":"Убей 10 медведей", "reward":80},
	"beast1": {"name":"Зверобой", "description":"Убей 50 зверей", "reward":120},
	"pelts1": {"name":"Скорняк", "description":"Собери 10 шкур", "reward":60},
	"carc1": {"name":"Раздельщик", "description":"Разделай 10 туш", "reward":60},
	"kill1": {"name":"Охотник на рейдеров", "description":"Победи 50 рейдеров", "reward":60},
	"build1": {"name":"Крепость", "description":"Построй 12 объектов лагеря", "reward":80},
	"build2": {"name":"Метрополия", "description":"Построй все доступные здания", "reward":150},
	"res1": {"name":"Учёный", "description":"Изучи все 6 технологий", "reward":100},
	"rel1": {"name":"Коллекционер", "description":"Собери все 6 реликвий", "reward":120},
	"hero1": {"name":"Полубог", "description":"Герой 10 уровня", "reward":100},
	"exp10": {"name":"Следопыт", "description":"Заверши 10 экспедиций", "reward":100},
	"fame1": {"name":"Вечное пламя", "description":"Соверши Восхождение", "reward":200},
}
const ANIMAL_XP := {"bear":6, "boar":4, "deer":3, "rabbit":1}
const RAID_XP := 3
const ASCENSION_BUILDING_REQUIREMENT := 12
const EXPEDITION_SLOT_COUNT := 3

var fame: int = 0
var hero_level: int = 1
var hero_xp: int = 0
var expedition_count: int = 0
var relics: Array[String] = []
var achievements: Array[String] = []
var slots: Array = []
var last_activity: String = "Экспедиции, реликвии и Восхождение открыты."

var _resource_manager = null
var _settlement_manager = null
var _progression_manager = null
var _unit_manager = null
var _wave_manager = null
var _player = null
var _wildlife_manager = null
var _rng := RandomNumberGenerator.new()
var _scan_accum := 0.0

func _ready() -> void:
	add_to_group("meta_progression_manager")
	_rng.seed = 2026091109
	_ensure_slots()
	call_deferred("_bind")

func _process(delta: float) -> void:
	_update_expeditions(delta)
	_scan_accum += delta
	if _scan_accum >= 0.45:
		_scan_accum = 0.0
		_bind_dynamic_sources()
		_check_achievements()

func _bind() -> void:
	_bind_managers()
	_bind_dynamic_sources()
	_reapply_reservations()
	_apply_meta_effects()
	_emit_snapshot()
	activity_changed.emit(last_activity)

func _bind_managers() -> void:
	if _resource_manager == null or not is_instance_valid(_resource_manager):
		_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if _settlement_manager == null or not is_instance_valid(_settlement_manager):
		_settlement_manager = get_tree().get_first_node_in_group("settlement_manager")
	if _progression_manager == null or not is_instance_valid(_progression_manager):
		_progression_manager = get_tree().get_first_node_in_group("progression_manager")
	if _unit_manager == null or not is_instance_valid(_unit_manager):
		_unit_manager = get_tree().get_first_node_in_group("unit_manager")
	if _wave_manager == null or not is_instance_valid(_wave_manager):
		_wave_manager = get_tree().get_first_node_in_group("raid_manager")
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player_combat")
	if _wildlife_manager == null or not is_instance_valid(_wildlife_manager):
		_wildlife_manager = get_tree().get_first_node_in_group("wildlife_manager")

func _bind_dynamic_sources() -> void:
	_bind_managers()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy) or not enemy.has_signal("died"):
			continue
		var cb := Callable(self, "_on_enemy_died")
		if not enemy.is_connected("died", cb):
			enemy.connect("died", cb)
	if _wildlife_manager != null and _wildlife_manager.has_signal("animal_killed"):
		var wildlife_cb := Callable(self, "_on_animal_killed")
		if not _wildlife_manager.is_connected("animal_killed", wildlife_cb):
			_wildlife_manager.connect("animal_killed", wildlife_cb)

func _on_enemy_died(_enemy: Node) -> void:
	add_hero_xp(RAID_XP)

func _on_animal_killed(kind: String, _food: int, _pelts: int) -> void:
	add_hero_xp(int(ANIMAL_XP.get(kind, 1)))

func get_hero_xp_needed() -> int:
	return 20 + hero_level * 15

func add_hero_xp(amount: int) -> void:
	if amount <= 0:
		return
	hero_xp += amount
	var leveled := false
	while hero_xp >= get_hero_xp_needed():
		hero_xp -= get_hero_xp_needed()
		hero_level += 1
		leveled = true
	if leveled:
		_set_activity("Герой достиг уровня %d" % hero_level)
	hero_level_changed.emit(hero_level, hero_xp)
	_check_achievements()
	_emit_snapshot()

func has_relic(relic_id: String) -> bool:
	return relics.has(relic_id)

func grant_relic(relic_id: String = "") -> String:
	var chosen := relic_id
	if chosen.is_empty():
		var pool: Array[String] = []
		for id in RELIC_ORDER:
			if not relics.has(str(id)):
				pool.append(str(id))
		if pool.is_empty():
			_bind_managers()
			if _resource_manager != null:
				_resource_manager.add_stored("gold", 50)
			_set_activity("Все реликвии собраны: вместо дубликата +50 золота")
			return ""
		chosen = pool[_rng.randi_range(0, pool.size() - 1)]
	if not RELICS.has(chosen) or relics.has(chosen):
		return ""
	relics.append(chosen)
	_apply_meta_effects()
	_set_activity("Реликвия: %s" % str(RELICS[chosen]["name"]))
	relic_unlocked.emit(chosen)
	_check_achievements()
	_emit_snapshot()
	_request_save()
	return chosen

func get_harvest_bonus() -> int:
	return 1 if has_relic("sickle") else 0

func get_carry_bonus() -> int:
	return 6 if has_relic("pouch") else 0

func get_worker_speed_multiplier() -> float:
	return 1.15 if has_relic("boots") else 1.0

func get_villager_carry_bonus() -> int:
	return 2 if has_relic("horn") else 0

func get_gold_kill_multiplier() -> int:
	return 2 if has_relic("orb") else 1

func get_flat_damage_bonus() -> int:
	return 1 if has_relic("banner") else 0

func get_damage_multiplier() -> float:
	return 1.0 + 0.04 * float(fame)

func get_production_multiplier() -> float:
	return 1.0 + 0.08 * float(fame)

func apply_production_amount(amount: int) -> int:
	if amount <= 0:
		return 0
	return maxi(1, int(round(float(amount) * get_production_multiplier())))

func get_relic_snapshot() -> Array:
	var result: Array = []
	for id in RELIC_ORDER:
		var definition: Dictionary = RELICS[str(id)]
		result.append({
			"id":str(id),
			"name":str(definition["name"]),
			"icon":str(definition["icon"]),
			"description":str(definition["description"]),
			"owned":relics.has(str(id)),
		})
	return result

func start_expedition(expedition_id: String) -> bool:
	if not EXPEDITIONS.has(expedition_id):
		return false
	var slot_index := _first_free_slot()
	if slot_index < 0:
		_set_activity("Все три слота экспедиций заняты.")
		return false
	var definition: Dictionary = EXPEDITIONS[expedition_id]
	var soldier_need := int(definition["soldiers"])
	var worker_need := int(definition["workers"])
	if _available_soldier_count() < soldier_need or _available_worker_count() < worker_need:
		_set_activity("Для экспедиции не хватает свободных бойцов или рабочих.")
		return false
	var assigned_units := _reserve_soldiers(soldier_need)
	var assigned_workers := _reserve_workers(worker_need)
	if _sum_dictionary(assigned_units) != soldier_need or assigned_workers != worker_need:
		_release_units(assigned_units)
		_release_workers(assigned_workers)
		_set_activity("Не удалось собрать отряд экспедиции.")
		return false
	slots[slot_index] = {
		"active":true,
		"id":expedition_id,
		"elapsed":0.0,
		"duration":float(definition["duration"]),
		"assigned_units":assigned_units,
		"workers":assigned_workers,
	}
	_set_activity("Экспедиция вышла: %s" % str(definition["name"]))
	expedition_started.emit(slot_index, expedition_id)
	_emit_snapshot()
	_request_save()
	return true

func can_start_expedition(expedition_id: String) -> bool:
	if not EXPEDITIONS.has(expedition_id) or _first_free_slot() < 0:
		return false
	var definition: Dictionary = EXPEDITIONS[expedition_id]
	return _available_soldier_count() >= int(definition["soldiers"]) and _available_worker_count() >= int(definition["workers"])

func _update_expeditions(delta: float) -> void:
	var completed: Array[int] = []
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if not bool(slot.get("active", false)):
			continue
		slot["elapsed"] = minf(float(slot.get("duration", 1.0)), float(slot.get("elapsed", 0.0)) + delta)
		slots[i] = slot
		if float(slot["elapsed"]) >= float(slot["duration"]):
			completed.append(i)
	for slot_index in completed:
		_finish_expedition(slot_index)

func _finish_expedition(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size():
		return {}
	var slot: Dictionary = slots[slot_index]
	if not bool(slot.get("active", false)):
		return {}
	var expedition_id := str(slot.get("id", ""))
	var assigned_units: Dictionary = slot.get("assigned_units", {})
	_release_units(assigned_units)
	_release_workers(int(slot.get("workers", 0)))
	var reward := _roll_expedition_reward(expedition_id)
	_grant_reward(reward)
	expedition_count += 1
	slots[slot_index] = _empty_slot()
	_set_activity("Экспедиция вернулась: %s" % str(EXPEDITIONS.get(expedition_id, {}).get("name", expedition_id)))
	expedition_finished.emit(slot_index, expedition_id, reward.duplicate(true))
	_check_achievements()
	_emit_snapshot()
	_request_save()
	return reward

func complete_expedition_for_test(slot_index: int) -> Dictionary:
	return _finish_expedition(slot_index)

func _roll_expedition_reward(expedition_id: String) -> Dictionary:
	_bind_managers()
	var wave_number := int(_wave_manager.wave_number) if _wave_manager != null else 0
	var reward: Dictionary = {}
	match expedition_id:
		"scout":
			reward["gold"] = _rng.randi_range(20, 45) + wave_number * 2
			var resource: String = str(["wood", "stone", "food"][_rng.randi_range(0, 2)])
			reward[resource] = int(reward.get(resource, 0)) + _rng.randi_range(40, 80)
		"supplies":
			for _i in range(2):
				var resource: String = str(["wood", "stone", "gold"][_rng.randi_range(0, 2)])
				reward[resource] = int(reward.get(resource, 0)) + _rng.randi_range(60, 130)
		"ruins":
			reward["gold"] = _rng.randi_range(60, 120) + wave_number * 3
			var resource: String = str(["wood", "stone", "food", "gold"][_rng.randi_range(0, 3)])
			reward[resource] = int(reward.get(resource, 0)) + _rng.randi_range(80, 160)
			if _rng.randf() < 0.25:
				var relic_id := grant_relic()
				if not relic_id.is_empty():
					reward["relic"] = relic_id
	return reward

func _grant_reward(reward: Dictionary) -> void:
	_bind_managers()
	if _resource_manager == null:
		return
	for key in ["wood", "stone", "food", "gold", "pelts"]:
		if int(reward.get(key, 0)) > 0:
			_resource_manager.add_stored(key, int(reward[key]))

func get_expedition_snapshot() -> Dictionary:
	var definitions: Array = []
	for id in EXPEDITION_ORDER:
		var definition: Dictionary = EXPEDITIONS[str(id)]
		definitions.append({
			"id":str(id),
			"name":str(definition["name"]),
			"description":str(definition["description"]),
			"duration":float(definition["duration"]),
			"soldiers":int(definition["soldiers"]),
			"workers":int(definition["workers"]),
			"can_start":can_start_expedition(str(id)),
		})
	return {"definitions":definitions, "slots":slots.duplicate(true), "completed":expedition_count}

func _available_soldier_count() -> int:
	var count := 0
	for unit in get_tree().get_nodes_in_group("camp_defenders"):
		if unit != null and is_instance_valid(unit) and unit.has_method("set_expedition_reserved"):
			count += 1
	return count

func _available_worker_count() -> int:
	var count := 0
	for worker in get_tree().get_nodes_in_group("camp_workers"):
		if worker != null and is_instance_valid(worker) and worker.has_method("set_expedition_reserved"):
			count += 1
	return count

func _reserve_soldiers(amount: int) -> Dictionary:
	var assigned: Dictionary = {"foot":0, "hunter":0, "dog":0}
	var left := amount
	for kind in ["foot", "hunter", "dog"]:
		if left <= 0:
			break
		for unit in get_tree().get_nodes_in_group("camp_defenders"):
			if left <= 0:
				break
			if unit == null or not is_instance_valid(unit) or str(unit.get("unit_kind")) != kind:
				continue
			if not unit.has_method("set_expedition_reserved"):
				continue
			unit.set_expedition_reserved(true)
			assigned[kind] = int(assigned[kind]) + 1
			left -= 1
	return assigned

func _reserve_workers(amount: int) -> int:
	var reserved := 0
	for worker in get_tree().get_nodes_in_group("camp_workers"):
		if reserved >= amount:
			break
		if worker == null or not is_instance_valid(worker) or not worker.has_method("set_expedition_reserved"):
			continue
		worker.set_expedition_reserved(true)
		reserved += 1
	return reserved

func _release_units(assigned: Dictionary) -> void:
	for kind in ["foot", "hunter", "dog"]:
		var left := int(assigned.get(kind, 0))
		if left <= 0:
			continue
		for unit in get_tree().get_nodes_in_group("expedition_reserved_units"):
			if left <= 0:
				break
			if unit == null or not is_instance_valid(unit) or str(unit.get("unit_kind")) != kind:
				continue
			unit.set_expedition_reserved(false)
			left -= 1

func _release_workers(amount: int) -> void:
	var left := amount
	for worker in get_tree().get_nodes_in_group("expedition_reserved_workers"):
		if left <= 0:
			break
		if worker == null or not is_instance_valid(worker):
			continue
		worker.set_expedition_reserved(false)
		left -= 1

func _release_all_reservations() -> void:
	for unit in get_tree().get_nodes_in_group("expedition_reserved_units"):
		if unit != null and is_instance_valid(unit) and unit.has_method("set_expedition_reserved"):
			unit.set_expedition_reserved(false)
	for worker in get_tree().get_nodes_in_group("expedition_reserved_workers"):
		if worker != null and is_instance_valid(worker) and worker.has_method("set_expedition_reserved"):
			worker.set_expedition_reserved(false)

func _reapply_reservations() -> void:
	_release_all_reservations()
	await get_tree().process_frame
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if not bool(slot.get("active", false)):
			continue
		var assigned: Dictionary = slot.get("assigned_units", {})
		for kind in ["foot", "hunter", "dog"]:
			var need := int(assigned.get(kind, 0))
			if need <= 0:
				continue
			var found := 0
			for unit in get_tree().get_nodes_in_group("camp_defenders"):
				if found >= need:
					break
				if unit != null and is_instance_valid(unit) and str(unit.get("unit_kind")) == kind and unit.has_method("set_expedition_reserved"):
					unit.set_expedition_reserved(true)
					found += 1
		var worker_need := int(slot.get("workers", 0))
		var worker_found := 0
		for worker in get_tree().get_nodes_in_group("camp_workers"):
			if worker_found >= worker_need:
				break
			if worker != null and is_instance_valid(worker) and worker.has_method("set_expedition_reserved"):
				worker.set_expedition_reserved(true)
				worker_found += 1

func get_built_count() -> int:
	_bind_managers()
	if _settlement_manager == null:
		return 0
	var count := 0
	for id in _settlement_manager.buildings.keys():
		if int(_settlement_manager.get_building_level(str(id))) > 0:
			count += 1
	return count

func get_fame_gain() -> int:
	_bind_managers()
	var wave_number := int(_wave_manager.wave_number) if _wave_manager != null else 0
	return maxi(0, int(floor(float(get_built_count()) / 4.0 + float(wave_number) / 5.0 + float(hero_level) / 5.0)))

func can_ascend() -> bool:
	return get_built_count() >= ASCENSION_BUILDING_REQUIREMENT and get_fame_gain() > 0

func ascend() -> bool:
	if not can_ascend():
		_set_activity("Для Восхождения нужно построить все 12 текущих объектов лагеря.")
		return false
	var gained := get_fame_gain()
	_release_all_reservations()
	fame += gained
	relics.clear()
	hero_level = 1
	hero_xp = 0
	expedition_count = 0
	_ensure_slots(true)
	_bind_managers()
	if _resource_manager != null and _resource_manager.has_method("import_state"):
		_resource_manager.import_state({})
	if _settlement_manager != null and _settlement_manager.has_method("import_state"):
		_settlement_manager.import_state({})
	if _progression_manager != null and _progression_manager.has_method("import_state"):
		_progression_manager.import_state({})
	if _unit_manager != null and _unit_manager.has_method("import_state"):
		_unit_manager.import_state({})
	if _wave_manager != null and _wave_manager.has_method("import_state"):
		_wave_manager.import_state({})
	if _player != null and _player.has_method("import_state"):
		_player.import_state({"position":[0.0, 0.0, 7.0], "health":int(_player.max_health)})
	_apply_meta_effects()
	_set_activity("Восхождение завершено: +%d Славы" % gained)
	ascended.emit(gained, fame)
	_check_achievements()
	_emit_snapshot()
	_request_save()
	return true

func get_ascension_snapshot() -> Dictionary:
	return {
		"fame":fame,
		"fame_gain":get_fame_gain(),
		"built":get_built_count(),
		"required":ASCENSION_BUILDING_REQUIREMENT,
		"can_ascend":can_ascend(),
		"production_bonus_percent":fame * 8,
		"damage_bonus_percent":fame * 4,
	}

func _check_achievements() -> void:
	_bind_managers()
	for achievement_id in ACHIEVEMENT_ORDER:
		var id := str(achievement_id)
		if achievements.has(id) or not _achievement_met(id):
			continue
		achievements.append(id)
		var reward := int(ACHIEVEMENTS[id]["reward"])
		if _resource_manager != null:
			_resource_manager.add_stored("gold", reward)
		achievement_unlocked.emit(id, reward)
		last_activity = "Достижение: %s · +%d золота" % [str(ACHIEVEMENTS[id]["name"]), reward]
		activity_changed.emit(last_activity)
		_request_save()
	_emit_snapshot()

func check_achievements_for_test() -> void:
	_check_achievements()

func _achievement_met(id: String) -> bool:
	if _progression_manager == null:
		return false
	var gathered: Dictionary = _progression_manager.gathered
	var animal_kills: Dictionary = _progression_manager.animal_kills
	match id:
		"wood1": return int(gathered.get("wood", 0)) >= 100
		"food1": return int(gathered.get("food", 0)) >= 100
		"bears1": return int(animal_kills.get("bear", 0)) >= 10
		"beast1":
			var total := 0
			for kind in animal_kills.keys(): total += int(animal_kills[kind])
			return total >= 50
		"pelts1": return int(gathered.get("pelts", 0)) >= 10
		"carc1": return int(_progression_manager.carcasses_skinned) >= 10
		"kill1": return int(_progression_manager.kills) >= 50
		"build1": return get_built_count() >= 12
		"build2": return _all_current_buildings_built()
		"res1": return int(_progression_manager.researched.size()) >= 6
		"rel1": return relics.size() >= RELIC_ORDER.size()
		"hero1": return hero_level >= 10
		"exp10": return expedition_count >= 10
		"fame1": return fame >= 1
	return false

func _all_current_buildings_built() -> bool:
	_bind_managers()
	if _settlement_manager == null:
		return false
	for id in _settlement_manager.buildings.keys():
		if int(_settlement_manager.get_building_level(str(id))) <= 0:
			return false
	return true

func get_achievement_snapshot() -> Array:
	var result: Array = []
	for id in ACHIEVEMENT_ORDER:
		var definition: Dictionary = ACHIEVEMENTS[str(id)]
		result.append({
			"id":str(id),
			"name":str(definition["name"]),
			"description":str(definition["description"]),
			"reward":int(definition["reward"]),
			"owned":achievements.has(str(id)),
		})
	return result

func get_snapshot() -> Dictionary:
	return {
		"fame":fame,
		"hero_level":hero_level,
		"hero_xp":hero_xp,
		"hero_xp_needed":get_hero_xp_needed(),
		"expedition_count":expedition_count,
		"relics":relics.duplicate(),
		"achievements":achievements.duplicate(),
		"expeditions":get_expedition_snapshot(),
		"ascension":get_ascension_snapshot(),
		"last_activity":last_activity,
	}

func export_state() -> Dictionary:
	return {
		"fame":fame,
		"hero_level":hero_level,
		"hero_xp":hero_xp,
		"expedition_count":expedition_count,
		"relics":relics.duplicate(),
		"achievements":achievements.duplicate(),
		"slots":slots.duplicate(true),
		"last_activity":last_activity,
	}

func import_state(data: Dictionary) -> void:
	_release_all_reservations()
	fame = maxi(0, int(data.get("fame", 0)))
	hero_level = maxi(1, int(data.get("hero_level", 1)))
	hero_xp = maxi(0, int(data.get("hero_xp", 0)))
	expedition_count = maxi(0, int(data.get("expedition_count", 0)))
	relics.clear()
	for value in data.get("relics", []):
		var id := str(value)
		if RELICS.has(id) and not relics.has(id): relics.append(id)
	achievements.clear()
	for value in data.get("achievements", []):
		var id := str(value)
		if ACHIEVEMENTS.has(id) and not achievements.has(id): achievements.append(id)
	_ensure_slots(true)
	var saved_slots = data.get("slots", [])
	if saved_slots is Array:
		for i in range(mini(saved_slots.size(), EXPEDITION_SLOT_COUNT)):
			if saved_slots[i] is Dictionary and bool(saved_slots[i].get("active", false)):
				var expedition_id := str(saved_slots[i].get("id", ""))
				if EXPEDITIONS.has(expedition_id):
					var definition: Dictionary = EXPEDITIONS[expedition_id]
					var assigned: Dictionary = saved_slots[i].get("assigned_units", {})
					slots[i] = {
						"active":true,
						"id":expedition_id,
						"elapsed":clampf(float(saved_slots[i].get("elapsed", 0.0)), 0.0, float(definition["duration"])),
						"duration":float(definition["duration"]),
						"assigned_units":{"foot":maxi(0,int(assigned.get("foot",0))),"hunter":maxi(0,int(assigned.get("hunter",0))),"dog":maxi(0,int(assigned.get("dog",0)))},
						"workers":maxi(0,int(saved_slots[i].get("workers",0))),
					}
	last_activity = str(data.get("last_activity", last_activity))
	_apply_meta_effects()
	call_deferred("_reapply_reservations")
	_emit_snapshot()

func _apply_meta_effects() -> void:
	_bind_managers()
	if _progression_manager != null and _progression_manager.has_method("refresh_carry_effects"):
		_progression_manager.refresh_carry_effects()
	if _unit_manager != null and _unit_manager.has_method("refresh_meta_effects"):
		_unit_manager.refresh_meta_effects()

func _ensure_slots(clear: bool = false) -> void:
	if clear:
		slots.clear()
	while slots.size() < EXPEDITION_SLOT_COUNT:
		slots.append(_empty_slot())
	while slots.size() > EXPEDITION_SLOT_COUNT:
		slots.pop_back()

func _empty_slot() -> Dictionary:
	return {"active":false, "id":"", "elapsed":0.0, "duration":1.0, "assigned_units":{"foot":0,"hunter":0,"dog":0}, "workers":0}

func _first_free_slot() -> int:
	for i in range(slots.size()):
		if not bool((slots[i] as Dictionary).get("active", false)):
			return i
	return -1

func _sum_dictionary(values: Dictionary) -> int:
	var total := 0
	for value in values.values(): total += int(value)
	return total

func _set_activity(text: String) -> void:
	last_activity = text
	activity_changed.emit(text)
	if _resource_manager != null and _resource_manager.has_method("report_activity"):
		_resource_manager.report_activity(text)

func _request_save() -> void:
	var saver = get_tree().get_first_node_in_group("save_manager")
	if saver != null and saver.has_method("save_game"):
		saver.call_deferred("save_game")

func _emit_snapshot() -> void:
	meta_changed.emit(get_snapshot())

func reset_for_test() -> void:
	_release_all_reservations()
	fame = 0
	hero_level = 1
	hero_xp = 0
	expedition_count = 0
	relics.clear()
	achievements.clear()
	_ensure_slots(true)
	last_activity = ""
	_apply_meta_effects()
	_emit_snapshot()
