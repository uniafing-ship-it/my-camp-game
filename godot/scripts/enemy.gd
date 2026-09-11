extends CharacterBody3D
class_name EnemyCombatant

signal health_changed(current: int, maximum: int)
signal died(enemy: Node)

@export var max_health: int = 55
@export var move_speed: float = 2.9
@export var attack_damage: int = 10
@export var attack_interval: float = 1.05
@export var aggro_radius: float = 11.5
@export var camp_attack_range: float = 2.1
@export var unit_attack_range: float = 1.65
@export var reward_gold: int = 1

const WALL_SLOW_RADIUS := 12.5

var health: int = 0
var _attack_left := 0.0
var _dead := false
var _visual: Node3D
var _target: Node3D = null

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_build_visual()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_left = maxf(0.0, _attack_left - delta)
	_target = _choose_target()
	var camp_target := Vector3.ZERO
	var target_position := camp_target
	var attack_range := camp_attack_range
	var target_is_unit := false
	if _target != null and is_instance_valid(_target):
		target_position = _target.global_position
		attack_range = unit_attack_range
		target_is_unit = true
	var flat_target := Vector3(target_position.x, global_position.y, target_position.z)
	var distance := global_position.distance_to(flat_target)
	var desired := Vector3.ZERO
	if distance > attack_range:
		desired = (flat_target - global_position).normalized()
	else:
		_try_attack(target_is_unit)
	var effective_speed := move_speed * get_fortification_speed_multiplier()
	velocity.x = move_toward(velocity.x, desired.x * effective_speed, 10.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z * effective_speed, 10.0 * delta)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.5
	if desired.length_squared() > 0.02 and _visual != null:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(desired.x, desired.z), minf(1.0, delta * 8.0))
	move_and_slide()

func get_fortification_speed_multiplier() -> float:
	if Vector2(global_position.x, global_position.z).length() >= WALL_SLOW_RADIUS:
		return 1.0
	var settlement = get_tree().get_first_node_in_group("settlement_manager")
	if settlement == null:
		return 1.0
	var wall_level := int(settlement.get_building_level("stone_wall"))
	if wall_level <= 0:
		return 1.0
	var factor := maxf(0.2, 0.6 - 0.05 * float(wall_level - 1))
	var progression = get_tree().get_first_node_in_group("progression_manager")
	if progression != null and progression.has_method("has_research") and bool(progression.has_research("walls")):
		factor = maxf(0.15, factor - 0.1)
	return factor

func _choose_target() -> Node3D:
	var best: Node3D = null
	var best_d := aggro_radius
	var player = get_tree().get_first_node_in_group("player_combat")
	if player is Node3D and player.has_method("is_alive") and bool(player.is_alive()):
		var d := global_position.distance_to(player.global_position)
		if d < best_d:
			best = player
			best_d = d
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

func _try_attack(target_is_unit: bool) -> void:
	if _attack_left > 0.0:
		return
	_attack_left = attack_interval
	if target_is_unit and _target != null and is_instance_valid(_target) and _target.has_method("take_damage"):
		_target.take_damage(attack_damage, global_position)
		return
	var raid = get_tree().get_first_node_in_group("raid_manager")
	if raid != null and raid.has_method("damage_camp"):
		raid.damage_camp(attack_damage)

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
	var resources = get_tree().get_first_node_in_group("resource_manager")
	var reward := reward_gold
	var meta = get_tree().get_first_node_in_group("meta_progression_manager")
	if meta != null and meta.has_method("get_gold_kill_multiplier"):
		reward *= maxi(1, int(meta.get_gold_kill_multiplier()))
	if resources != null and reward > 0:
		resources.add_stored("gold", reward)
	died.emit(self)
	queue_free()

func _build_visual() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.44
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)
	_visual = Node3D.new()
	add_child(_visual)
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.43
	bm.height = 1.25
	bm.radial_segments = 10
	bm.rings = 5
	body.mesh = bm
	body.position.y = 0.78
	body.material_override = _mat(Color(0.25,0.42,0.15))
	_visual.add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.31
	hm.height = 0.62
	hm.radial_segments = 10
	hm.rings = 5
	head.mesh = hm
	head.position.y = 1.63
	head.material_override = _mat(Color(0.44,0.62,0.24))
	_visual.add_child(head)
	var weapon := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(0.10,0.9,0.13)
	weapon.mesh = wm
	weapon.position = Vector3(0.5,0.78,0)
	weapon.rotation_degrees.z = -25
	weapon.material_override = _mat(Color(0.43,0.33,0.22),0.65,0.12)
	_visual.add_child(weapon)

func _mat(color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m
