extends CharacterBody3D
class_name WildlifeAnimal

signal died(kind: String, food_min: int, food_max: int, pelt_chance: float, death_position: Vector3)

@export var animal_kind: String = "deer"
@export var max_health: int = 8
@export var move_speed: float = 3.0
@export var aggro_radius: float = 0.0
@export var flee: bool = true
@export var food_min: int = 8
@export var food_max: int = 12
@export var pelt_chance: float = 0.3
@export var attack_damage: int = 4

var health: int = 0
var _dead := false
var _target: Node3D = null
var _attack_left := 0.0
var _wander_left := 0.0
var _wander_dir := Vector3.ZERO
var _flee_left := 0.0
var _visual: Node3D
var _home := Vector3.ZERO
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("wildlife")
	health = max_health
	_home = global_position
	_rng.seed = int(abs(hash(name))) + 701
	_build_visual()
	_choose_wander()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_left = maxf(0.0, _attack_left - delta)
	_wander_left -= delta
	_flee_left = maxf(0.0, _flee_left - delta)
	var threat := _nearest_threat()
	var desired := Vector3.ZERO

	if flee and threat != null and global_position.distance_to(threat.global_position) < 7.0:
		desired = global_position - threat.global_position
		desired.y = 0.0
		if desired.length_squared() > 0.01:
			desired = desired.normalized()
		_flee_left = 1.2
	elif _flee_left > 0.0 and _target != null and is_instance_valid(_target):
		desired = global_position - _target.global_position
		desired.y = 0.0
		if desired.length_squared() > 0.01:
			desired = desired.normalized()
	elif not flee and aggro_radius > 0.0 and threat != null and global_position.distance_to(threat.global_position) <= aggro_radius:
		_target = threat
		var flat := Vector3(threat.global_position.x, global_position.y, threat.global_position.z)
		var distance := global_position.distance_to(flat)
		if distance > 1.45:
			desired = (flat - global_position).normalized()
		elif _attack_left <= 0.0:
			_attack_left = 1.0
			if threat.has_method("take_damage"):
				threat.take_damage(attack_damage, global_position)
	else:
		if _wander_left <= 0.0:
			_choose_wander()
		desired = _wander_dir
		if global_position.distance_to(_home) > 12.0:
			desired = (_home - global_position).normalized()

	var speed := move_speed * (1.28 if flee and (_flee_left > 0.0 or threat != null) else 1.0)
	velocity.x = move_toward(velocity.x, desired.x * speed, 10.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z * speed, 10.0 * delta)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.5
	if desired.length_squared() > 0.02 and _visual != null:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(desired.x, desired.z), minf(1.0, delta * 7.0))
	move_and_slide()

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO) -> int:
	if _dead or amount <= 0:
		return health
	health = maxi(0, health - amount)
	if source_position != Vector3.ZERO:
		_target = _nearest_node_to(source_position)
		_flee_left = 2.0 if flee else 0.0
	if health <= 0:
		_dead = true
		died.emit(animal_kind, food_min, food_max, pelt_chance, global_position)
		queue_free()
	return health

func is_alive() -> bool:
	return not _dead and health > 0

func _nearest_threat() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var player = get_tree().get_first_node_in_group("player_combat")
	if player is Node3D and player.has_method("is_alive") and bool(player.is_alive()):
		best = player
		best_d = global_position.distance_to(player.global_position)
	for unit in get_tree().get_nodes_in_group("camp_defenders"):
		if not (unit is Node3D):
			continue
		if unit.has_method("is_alive") and not bool(unit.is_alive()):
			continue
		var d := global_position.distance_to(unit.global_position)
		if d < best_d:
			best = unit
			best_d = d
	return best

func _nearest_node_to(position: Vector3) -> Node3D:
	var best := _nearest_threat()
	if best != null:
		return best
	return null

func _choose_wander() -> void:
	_wander_left = _rng.randf_range(1.5, 4.0)
	if _rng.randf() < 0.3:
		_wander_dir = Vector3.ZERO
	else:
		var angle := _rng.randf_range(0.0, TAU)
		_wander_dir = Vector3(cos(angle), 0.0, sin(angle))

func _build_visual() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	var scale_factor := _scale_for_kind()
	shape.radius = 0.35 * scale_factor
	shape.height = 0.85 * scale_factor
	collision.shape = shape
	collision.position.y = 0.42 * scale_factor
	add_child(collision)

	_visual = Node3D.new()
	add_child(_visual)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34 * scale_factor
	body_mesh.height = 0.88 * scale_factor
	body_mesh.radial_segments = 10
	body_mesh.rings = 5
	body.mesh = body_mesh
	body.rotation_degrees.z = 90.0
	body.position.y = 0.48 * scale_factor
	body.material_override = _material(_color_for_kind())
	_visual.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24 * scale_factor
	head_mesh.height = 0.48 * scale_factor
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.62 * scale_factor, 0.48 * scale_factor)
	head.material_override = _material(_color_for_kind().lightened(0.06))
	_visual.add_child(head)
	if animal_kind == "deer":
		for x in [-0.12, 0.12]:
			var antler := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.025
			mesh.bottom_radius = 0.035
			mesh.height = 0.42
			mesh.radial_segments = 6
			antler.mesh = mesh
			antler.position = Vector3(x,0.95,0.48)
			antler.rotation_degrees.z = x * 70.0
			antler.material_override = _material(Color(0.32,0.20,0.10))
			_visual.add_child(antler)

func _scale_for_kind() -> float:
	match animal_kind:
		"bear": return 1.45
		"boar": return 1.08
		"rabbit": return 0.55
	return 1.0

func _color_for_kind() -> Color:
	match animal_kind:
		"bear": return Color(0.25,0.15,0.085)
		"boar": return Color(0.28,0.22,0.18)
		"deer": return Color(0.53,0.36,0.19)
		"rabbit": return Color(0.72,0.71,0.67)
	return Color(0.5,0.4,0.3)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material
