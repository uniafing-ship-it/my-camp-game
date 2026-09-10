extends CharacterBody3D
class_name CampUnit

signal died(kind: String, unit: Node)

@export var unit_kind: String = "foot"
@export var max_health: int = 48
@export var attack_damage: int = 12
@export var move_speed: float = 3.7
@export var attack_range: float = 1.8
@export var attack_interval: float = 0.85
@export var scan_radius: float = 16.0

var health: int = 0
var _target: Node3D = null
var _attack_left := 0.0
var _scan_left := 0.0
var _dead := false
var _visual: Node3D
var _home := Vector3.ZERO

func _ready() -> void:
	add_to_group("camp_defenders")
	health = max_health
	_home = global_position
	_build_visual()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_left = maxf(0.0, _attack_left - delta)
	_scan_left -= delta
	if _scan_left <= 0.0 or _target == null or not is_instance_valid(_target):
		_scan_left = 0.35
		_target = _find_target()

	var desired := Vector3.ZERO
	if _target != null and is_instance_valid(_target):
		if _target.has_method("is_alive") and not bool(_target.is_alive()):
			_target = null
		else:
			var flat := Vector3(_target.global_position.x, global_position.y, _target.global_position.z)
			var distance := global_position.distance_to(flat)
			if distance > attack_range:
				desired = (flat - global_position).normalized()
			else:
				_try_attack()
	elif global_position.distance_to(_home) > 5.5:
		desired = (_home - global_position).normalized()

	velocity.x = move_toward(velocity.x, desired.x * move_speed, 14.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z * move_speed, 14.0 * delta)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.5
	if desired.length_squared() > 0.02 and _visual != null:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(desired.x, desired.z), minf(1.0, delta * 9.0))
	move_and_slide()

func _find_target() -> Node3D:
	var best: Node3D = null
	var best_distance := scan_radius
	for node in get_tree().get_nodes_in_group("enemies"):
		if not (node is Node3D):
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_distance:
			best = node
			best_distance = d
	if best != null:
		return best
	if unit_kind == "hunter" or unit_kind == "dog":
		for node in get_tree().get_nodes_in_group("wildlife"):
			if not (node is Node3D):
				continue
			var d := global_position.distance_to(node.global_position)
			if d < best_distance:
				best = node
				best_distance = d
	return best

func _try_attack() -> void:
	if _attack_left > 0.0 or _target == null or not is_instance_valid(_target):
		return
	_attack_left = attack_interval
	if _target.has_method("take_damage"):
		_target.take_damage(attack_damage, global_position)

func take_damage(amount: int, _source_position: Vector3 = Vector3.ZERO) -> int:
	if _dead or amount <= 0:
		return health
	health = maxi(0, health - amount)
	if health <= 0:
		_dead = true
		died.emit(unit_kind, self)
		queue_free()
	return health

func is_alive() -> bool:
	return not _dead and health > 0

func _build_visual() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38 if unit_kind != "dog" else 0.32
	shape.height = 1.55 if unit_kind != "dog" else 0.85
	collision.shape = shape
	collision.position.y = 0.78 if unit_kind != "dog" else 0.42
	add_child(collision)

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	if unit_kind == "dog":
		_build_dog()
	else:
		_build_humanoid()

func _build_humanoid() -> void:
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.36
	mesh.height = 1.12
	mesh.radial_segments = 10
	mesh.rings = 5
	body.mesh = mesh
	body.position.y = 0.72
	body.material_override = _material(Color(0.20,0.32,0.46) if unit_kind == "foot" else Color(0.20,0.39,0.23), 0.72)
	_visual.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.54
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.position.y = 1.48
	head.material_override = _material(Color(0.78,0.57,0.36), 0.82)
	_visual.add_child(head)
	var weapon := MeshInstance3D.new()
	if unit_kind == "hunter":
		var bow := TorusMesh.new()
		bow.inner_radius = 0.29
		bow.outer_radius = 0.33
		bow.rings = 12
		bow.ring_segments = 12
		weapon.mesh = bow
		weapon.position = Vector3(0.45,0.9,0.0)
		weapon.rotation_degrees = Vector3(90,0,0)
		weapon.material_override = _material(Color(0.40,0.23,0.09), 0.9)
	else:
		var blade := BoxMesh.new()
		blade.size = Vector3(0.08,0.92,0.12)
		weapon.mesh = blade
		weapon.position = Vector3(0.47,0.83,0.0)
		weapon.rotation_degrees.z = -22
		weapon.material_override = _material(Color(0.66,0.70,0.73), 0.34, 0.36)
	_visual.add_child(weapon)

func _build_dog() -> void:
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.32
	mesh.height = 0.82
	mesh.radial_segments = 10
	mesh.rings = 5
	body.mesh = mesh
	body.rotation_degrees.z = 90
	body.position = Vector3(0,0.48,0)
	body.material_override = _material(Color(0.34,0.22,0.12), 0.9)
	_visual.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.position = Vector3(0,0.62,0.48)
	head.material_override = _material(Color(0.40,0.27,0.15), 0.9)
	_visual.add_child(head)

func _material(color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
