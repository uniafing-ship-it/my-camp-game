extends CharacterBody3D
class_name CampEnemy

signal health_changed(current: int, maximum: int)
signal died(enemy: Node)

@export var max_health: int = 55
@export var move_speed: float = 3.0
@export var acceleration: float = 12.0
@export var gravity_force: float = 24.0
@export var attack_damage: int = 12
@export var attack_range: float = 1.65
@export var attack_interval: float = 1.05
@export var aggro_radius: float = 11.5
@export var camp_attack_radius: float = 5.3
@export var reward_gold: int = 1

var health: int = 0
var _attack_cooldown := 0.0
var _dead := false
var _player = null
var _raid_manager = null
var _resource_manager = null
var _visual: Node3D

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_player = get_tree().get_first_node_in_group("player_combat")
	_raid_manager = get_tree().get_first_node_in_group("raid_manager")
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	_build_visual()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity_force * delta
	else:
		velocity.y = -0.5

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player_combat")
	if _raid_manager == null or not is_instance_valid(_raid_manager):
		_raid_manager = get_tree().get_first_node_in_group("raid_manager")

	var target_position := Vector3.ZERO
	var target_player := false
	if _player != null and _player.has_method("is_alive") and bool(_player.is_alive()):
		var player_distance := global_position.distance_to(_player.global_position)
		if player_distance <= aggro_radius:
			target_position = _player.global_position
			target_player = true

	var flat_target := Vector3(target_position.x, global_position.y, target_position.z)
	var distance := global_position.distance_to(flat_target)
	var desired := Vector3.ZERO
	var stopping_distance := attack_range if target_player else camp_attack_radius
	if distance > stopping_distance:
		desired = (flat_target - global_position).normalized()
		velocity.x = move_toward(velocity.x, desired.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired.z * move_speed, acceleration * delta)
		if _visual != null:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(desired.x, desired.z), minf(1.0, delta * 7.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		_try_attack(target_player)

	move_and_slide()

func _try_attack(target_player: bool) -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = attack_interval
	if target_player and _player != null and _player.has_method("take_damage"):
		_player.take_damage(attack_damage, global_position)
	elif _raid_manager != null and _raid_manager.has_method("damage_camp"):
		_raid_manager.damage_camp(attack_damage)

func take_damage(amount: int, _source_position: Vector3 = Vector3.ZERO) -> int:
	if _dead or amount <= 0:
		return health
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()
	return health

func is_alive() -> bool:
	return not _dead and health > 0

func _die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector3.ZERO
	if reward_gold > 0:
		if _resource_manager == null or not is_instance_valid(_resource_manager):
			_resource_manager = get_tree().get_first_node_in_group("resource_manager")
		if _resource_manager != null and _resource_manager.has_method("add_stored"):
			_resource_manager.add_stored("gold", reward_gold)
			if _resource_manager.has_method("report_activity"):
				_resource_manager.report_activity("Враг повержен: +%d золота" % reward_gold)
	died.emit(self)
	queue_free()

func _build_visual() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.43
	body_mesh.height = 1.25
	body_mesh.radial_segments = 12
	body_mesh.rings = 6
	body.mesh = body_mesh
	body.position.y = 0.78
	body.material_override = _material(Color(0.20, 0.39, 0.13), 0.7)
	_visual.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.31
	head_mesh.height = 0.62
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.58, 0.0)
	head.material_override = _material(Color(0.36, 0.57, 0.20), 0.76)
	_visual.add_child(head)

	var shoulder := MeshInstance3D.new()
	var shoulder_mesh := BoxMesh.new()
	shoulder_mesh.size = Vector3(0.98, 0.18, 0.42)
	shoulder.mesh = shoulder_mesh
	shoulder.position = Vector3(0.0, 1.22, 0.0)
	shoulder.material_override = _material(Color(0.13, 0.14, 0.12), 0.56, 0.14)
	_visual.add_child(shoulder)

	var club := MeshInstance3D.new()
	var club_mesh := CylinderMesh.new()
	club_mesh.top_radius = 0.08
	club_mesh.bottom_radius = 0.12
	club_mesh.height = 1.25
	club_mesh.radial_segments = 8
	club.mesh = club_mesh
	club.position = Vector3(0.58, 0.88, 0.04)
	club.rotation_degrees.z = -28.0
	club.material_override = _material(Color(0.23, 0.12, 0.055), 0.94)
	_visual.add_child(club)

	for x in [-0.13, 0.13]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.035
		eye_mesh.height = 0.07
		eye_mesh.radial_segments = 8
		eye_mesh.rings = 4
		eye.mesh = eye_mesh
		eye.position = Vector3(x, 1.64, 0.285)
		var eye_material := _material(Color(1.0, 0.16, 0.05), 0.3)
		eye_material.emission_enabled = true
		eye_material.emission = Color(0.8, 0.03, 0.01)
		eye_material.emission_energy_multiplier = 1.7
		eye.material_override = eye_material
		_visual.add_child(eye)

func _material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
