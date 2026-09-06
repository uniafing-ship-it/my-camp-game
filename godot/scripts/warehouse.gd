extends Node3D
class_name Warehouse

@export var deposit_radius: float = 5.2
@export var deposit_cooldown: float = 0.75

var _next_deposit_msec: int = 0

func _ready() -> void:
	add_to_group("warehouse")

func try_deposit(player_position: Vector3, manager: Node) -> bool:
	if manager == null or not manager.has_method("deposit_all"):
		return false
	if global_position.distance_to(player_position) > deposit_radius:
		return false
	var now := Time.get_ticks_msec()
	if now < _next_deposit_msec:
		return false
	_next_deposit_msec = now + int(deposit_cooldown * 1000.0)
	if manager.has_method("get_total_carried") and int(manager.get_total_carried()) <= 0:
		return false
	manager.deposit_all()
	return true
