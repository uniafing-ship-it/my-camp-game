extends Node3D
class_name WildlifeCarcass

signal skinned(kind: String, food: int, pelts: int)

@export var animal_kind: String = "deer"
@export var food_amount: int = 4
@export var pelt_amount: int = 0
@export var lifetime: float = 25.0
@export var skin_time: float = 0.9
@export var interact_radius: float = 2.2

var _skin_progress := 0.0
var _done := false

func _ready() -> void:
	add_to_group("carcasses")
	_build_visual()

func _process(delta: float) -> void:
	if _done:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var player = get_tree().get_first_node_in_group("player_combat")
	if player is Node3D and global_position.distance_to(player.global_position) <= interact_radius:
		_skin_progress += delta
		if _skin_progress >= skin_time:
			_finish_skinning()
	else:
		_skin_progress = maxf(0.0, _skin_progress - delta * 0.75)

func _finish_skinning() -> void:
	if _done:
		return
	_done = true
	var resources = get_tree().get_first_node_in_group("resource_manager")
	if resources != null:
		if food_amount > 0:
			resources.add_stored("food", food_amount)
		if pelt_amount > 0:
			resources.add_stored("pelts", pelt_amount)
		if resources.has_method("report_activity"):
			resources.report_activity("Туша разделана: +%d еды, +%d шкур" % [food_amount, pelt_amount])
	skinned.emit(animal_kind, food_amount, pelt_amount)
	queue_free()

func _build_visual() -> void:
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.34
	mesh.height = 0.85
	mesh.radial_segments = 10
	mesh.rings = 5
	body.mesh = mesh
	body.rotation_degrees.z = 90.0
	body.position.y = 0.22
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28,0.16,0.11)
	mat.roughness = 0.98
	body.material_override = mat
	add_child(body)
