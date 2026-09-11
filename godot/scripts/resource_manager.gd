extends Node
class_name ResourceManager

signal inventory_changed(carried: Dictionary, stored: Dictionary)
signal activity_changed(text: String)

const RESOURCE_TYPES := ["wood", "stone", "food", "gold", "pelts"]

@export var carry_capacity: int = 30

var carried: Dictionary = {"wood":0, "stone":0, "food":0, "gold":0, "pelts":0}
var stored: Dictionary = {"wood":0, "stone":0, "food":0, "gold":0, "pelts":0}
var last_activity: String = "Подойди к ресурсу — добыча начнётся автоматически."

func _ready() -> void:
	add_to_group("resource_manager")
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
	activity_changed.emit(last_activity)

func get_total_carried() -> int:
	var total := 0
	for resource_type in RESOURCE_TYPES:
		total += int(carried.get(resource_type, 0))
	return total

func get_effective_carry_capacity() -> int:
	var total := carry_capacity
	var meta = get_tree().get_first_node_in_group("meta_progression_manager")
	if meta != null and meta.has_method("get_carry_bonus"):
		total += maxi(0, int(meta.get_carry_bonus()))
	var parity = get_tree().get_first_node_in_group("stage10_settlement_parity")
	if parity != null and parity.has_method("get_hero_carry_bonus"):
		total += maxi(0, int(parity.get_hero_carry_bonus()))
	return maxi(1, total)

func get_free_capacity() -> int:
	return maxi(0, get_effective_carry_capacity() - get_total_carried())

func add_carried(resource_type: String, amount: int) -> int:
	if amount <= 0 or not carried.has(resource_type): return 0
	var accepted := mini(amount, get_free_capacity())
	if accepted <= 0:
		report_activity("Рюкзак заполнен. Вернись к складу.")
		return 0
	carried[resource_type] = int(carried[resource_type]) + accepted
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
	return accepted

func add_stored(resource_type: String, amount: int) -> int:
	if amount <= 0 or not stored.has(resource_type): return 0
	stored[resource_type] = int(stored[resource_type]) + amount
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
	return amount

func can_afford_stored(cost: Dictionary) -> bool:
	for resource_type in cost.keys():
		if not stored.has(resource_type) or int(stored.get(resource_type, 0)) < int(cost[resource_type]): return false
	return true

func spend_stored(cost: Dictionary) -> bool:
	if not can_afford_stored(cost): return false
	for resource_type in cost.keys(): stored[resource_type] = int(stored[resource_type]) - int(cost[resource_type])
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
	return true

func deposit_all() -> Dictionary:
	var moved: Dictionary = {}
	var total_moved := 0
	for resource_type in RESOURCE_TYPES:
		var amount := int(carried.get(resource_type, 0))
		moved[resource_type] = amount
		if amount > 0:
			stored[resource_type] = int(stored.get(resource_type, 0)) + amount
			carried[resource_type] = 0
			total_moved += amount
	if total_moved > 0:
		inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
		report_activity("Склад пополнен: %d ед." % total_moved)
	return moved

func report_activity(text: String) -> void:
	if text.is_empty(): return
	last_activity = text
	activity_changed.emit(last_activity)

func export_state() -> Dictionary:
	return {"carried":carried.duplicate(true), "stored":stored.duplicate(true), "carry_capacity":carry_capacity, "last_activity":last_activity}

func import_state(data: Dictionary) -> void:
	var next_carried: Dictionary = data.get("carried", {})
	var next_stored: Dictionary = data.get("stored", {})
	for resource_type in RESOURCE_TYPES:
		carried[resource_type] = maxi(0, int(next_carried.get(resource_type, 0)))
		stored[resource_type] = maxi(0, int(next_stored.get(resource_type, 0)))
	carry_capacity = maxi(1, int(data.get("carry_capacity", carry_capacity)))
	last_activity = str(data.get("last_activity", last_activity))
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
	activity_changed.emit(last_activity)

func reset_for_test() -> void:
	for resource_type in RESOURCE_TYPES:
		carried[resource_type] = 0
		stored[resource_type] = 0
	carry_capacity = 30
	last_activity = ""
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
