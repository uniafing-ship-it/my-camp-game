extends Control

@onready var carried_label: Label = $Panel/Margin/VBox/Carried
@onready var stored_label: Label = $Panel/Margin/VBox/Stored
@onready var status_label: Label = $Panel/Margin/VBox/Status

var _manager = null

func _ready() -> void:
	call_deferred("_bind_manager")

func _bind_manager() -> void:
	_manager = get_tree().get_first_node_in_group("resource_manager")
	if _manager == null:
		return
	if _manager.has_signal("inventory_changed"):
		_manager.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
	if _manager.has_signal("activity_changed"):
		_manager.connect("activity_changed", Callable(self, "_on_activity_changed"))
	_refresh()

func _refresh() -> void:
	if _manager == null:
		return
	_on_inventory_changed(_manager.get("carried"), _manager.get("stored"))
	_on_activity_changed(str(_manager.get("last_activity")))

func _on_inventory_changed(carried: Dictionary, stored: Dictionary) -> void:
	var total := 0
	for key in ["wood", "stone", "food", "gold"]:
		total += int(carried.get(key, 0))
	var capacity := int(_manager.get("carry_capacity")) if _manager else 0
	carried_label.text = "РЮКЗАК %d/%d   🌲 %d   🪨 %d   🍓 %d   🪙 %d" % [
		total,
		capacity,
		int(carried.get("wood", 0)),
		int(carried.get("stone", 0)),
		int(carried.get("food", 0)),
		int(carried.get("gold", 0)),
	]
	stored_label.text = "СКЛАД        🌲 %d   🪨 %d   🍓 %d   🪙 %d" % [
		int(stored.get("wood", 0)),
		int(stored.get("stone", 0)),
		int(stored.get("food", 0)),
		int(stored.get("gold", 0)),
	]

func _on_activity_changed(text: String) -> void:
	status_label.text = text
