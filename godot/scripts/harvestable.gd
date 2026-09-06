extends Node3D
class_name Harvestable

signal harvested(resource_type: String, amount: int, remaining: int)
signal depleted(resource_type: String)
signal regrown(resource_type: String)

@export var resource_type: String = "wood"
@export var source_name: String = "Ресурс"
@export var max_amount: int = 12
@export var yield_amount: int = 1
@export var harvest_interval: float = 0.55
@export var regrow_delay: float = 24.0
@export var harvest_radius: float = 2.6
@export var infinite_source: bool = false

var current_amount: int = 0
var _next_harvest_msec: int = 0
var _depleted := false

func _ready() -> void:
	add_to_group("harvestables")
	current_amount = max_amount

func is_depleted() -> bool:
	return _depleted

func try_harvest(manager: Node) -> int:
	if _depleted or manager == null or not manager.has_method("add_carried"):
		return 0
	var now := Time.get_ticks_msec()
	if now < _next_harvest_msec:
		return 0
	_next_harvest_msec = now + int(harvest_interval * 1000.0)
	var requested := yield_amount
	if not infinite_source:
		requested = mini(requested, current_amount)
	var accepted: int = int(manager.add_carried(resource_type, requested))
	if accepted <= 0:
		return 0
	if not infinite_source:
		current_amount -= accepted
	if manager.has_method("report_activity"):
		manager.report_activity("%s: +%d %s" % [source_name, accepted, _resource_title(resource_type)])
	harvested.emit(resource_type, accepted, current_amount)
	if not infinite_source and current_amount <= 0:
		_begin_regrow()
	return accepted

func _begin_regrow() -> void:
	if _depleted:
		return
	_depleted = true
	_set_active_visual(false)
	depleted.emit(resource_type)
	if regrow_delay <= 0.0:
		return
	await get_tree().create_timer(regrow_delay).timeout
	current_amount = max_amount
	_depleted = false
	_set_active_visual(true)
	regrown.emit(resource_type)

func _set_active_visual(active: bool) -> void:
	for child in get_children():
		_set_child_active(child, active)

func _set_child_active(node: Node, active: bool) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = active
	elif node is CollisionShape3D:
		(node as CollisionShape3D).set_deferred("disabled", not active)
	for child in node.get_children():
		_set_child_active(child, active)

func _resource_title(resource: String) -> String:
	match resource:
		"wood": return "дерева"
		"stone": return "камня"
		"food": return "еды"
		"gold": return "золота"
		_: return resource
