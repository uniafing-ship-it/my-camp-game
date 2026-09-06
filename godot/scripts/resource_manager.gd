extends Node
class_name ResourceManager

signal inventory_changed(carried: Dictionary, stored: Dictionary)
signal activity_changed(text: String)

const RESOURCE_TYPES := ["wood", "stone", "food", "gold"]

@export var carry_capacity: int = 30

var carried: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"gold": 0,
}

var stored: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"gold": 0,
}

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

func get_free_capacity() -> int:
	return maxi(0, carry_capacity - get_total_carried())

func add_carried(resource_type: String, amount: int) -> int:
	if amount <= 0 or not carried.has(resource_type):
		return 0
	var accepted := mini(amount, get_free_capacity())
	if accepted <= 0:
		report_activity("Рюкзак заполнен. Вернись к складу.")
		return 0
	carried[resource_type] = int(carried[resource_type]) + accepted
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
	return accepted

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
	if text.is_empty():
		return
	last_activity = text
	activity_changed.emit(last_activity)

func reset_for_test() -> void:
	for resource_type in RESOURCE_TYPES:
		carried[resource_type] = 0
		stored[resource_type] = 0
	last_activity = ""
	inventory_changed.emit(carried.duplicate(true), stored.duplicate(true))
