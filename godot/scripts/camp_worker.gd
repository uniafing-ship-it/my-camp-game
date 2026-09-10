extends CharacterBody3D
class_name CampWorker

@export var worker_id: int = 1
@export var preferred_resource: String = "wood"
@export var move_speed: float = 3.4
@export var carry_capacity: int = 8
@export var harvest_interval: float = 0.85

var cargo_type: String = ""
var cargo_amount: int = 0
var state: String = "gather"
var _target = null
var _resource_manager = null
var _warehouse = null
var _harvest_cooldown := 0.0
var _visual: Node3D

func _ready() -> void:
	add_to_group("camp_workers")
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	_warehouse = get_tree().get_first_node_in_group("warehouse")
	_build_visual()

func _physics_process(delta: float) -> void:
	_harvest_cooldown = maxf(0.0, _harvest_cooldown - delta)
	if _resource_manager == null:
		_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if _warehouse == null:
		_warehouse = get_tree().get_first_node_in_group("warehouse")

	if cargo_amount >= carry_capacity:
		state = "return"

	if state == "return":
		_process_return(delta)
	else:
		_process_gather(delta)

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.4
	move_and_slide()
	_animate_visual(delta)

func _process_gather(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or (_target.has_method("is_depleted") and _target.is_depleted()):
		_target = _find_target()
	if _target == null:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		return

	var distance := global_position.distance_to(_target.global_position)
	var harvest_radius := float(_target.get("harvest_radius"))
	if distance > harvest_radius * 0.78:
		_move_toward(_target.global_position, delta)
		return

	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	if _harvest_cooldown > 0.0 or cargo_amount >= carry_capacity:
		return
	_harvest_cooldown = harvest_interval
	if _target.has_method("take_for_worker"):
		var accepted := int(_target.take_for_worker(mini(2, carry_capacity - cargo_amount)))
		if accepted > 0:
			cargo_type = str(_target.get("resource_type"))
			cargo_amount += accepted
			if _resource_manager != null and _resource_manager.has_method("report_activity"):
				_resource_manager.report_activity("Рабочий #%d добывает %s (%d/%d)" % [worker_id, _resource_title(cargo_type), cargo_amount, carry_capacity])
		if cargo_amount >= carry_capacity or (_target.has_method("is_depleted") and _target.is_depleted()):
			state = "return" if cargo_amount > 0 else "gather"
			_target = null

func _process_return(delta: float) -> void:
	if _warehouse == null:
		return
	var warehouse_position: Vector3 = _warehouse.global_position
	var distance := global_position.distance_to(warehouse_position)
	if distance > 3.0:
		_move_toward(warehouse_position, delta)
		return
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	if cargo_amount > 0 and _resource_manager != null and _resource_manager.has_method("add_stored"):
		_resource_manager.add_stored(cargo_type, cargo_amount)
		if _resource_manager.has_method("report_activity"):
			_resource_manager.report_activity("Рабочий #%d сдал на склад: +%d %s" % [worker_id, cargo_amount, _resource_title(cargo_type)])
	cargo_amount = 0
	cargo_type = ""
	state = "gather"
	_target = null

func _find_target():
	var best = null
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("harvestables"):
		if not (candidate is Node3D):
			continue
		if candidate.has_method("is_depleted") and candidate.is_depleted():
			continue
		if str(candidate.get("resource_type")) != preferred_resource:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best == null and preferred_resource != "wood":
		preferred_resource = "wood"
		return _find_target()
	return best

func _move_toward(target_position: Vector3, delta: float) -> void:
	var direction := target_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()
	velocity.x = move_toward(velocity.x, direction.x * move_speed, 10.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * move_speed, 10.0 * delta)
	if _visual != null:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))

func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.25
	body.mesh = body_mesh
	body.position.y = 0.92
	body.material_override = _material(Color(0.40, 0.27, 0.15), 0.9)
	_visual.add_child(body)

	var tunic := MeshInstance3D.new()
	var tunic_mesh := CylinderMesh.new()
	tunic_mesh.top_radius = 0.38
	tunic_mesh.bottom_radius = 0.44
	tunic_mesh.height = 0.72
	tunic_mesh.radial_segments = 10
	tunic.mesh = tunic_mesh
	tunic.position.y = 1.05
	tunic.material_override = _material(Color(0.27, 0.39, 0.48), 0.85)
	_visual.add_child(tunic)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head_mesh.radial_segments = 10
	head_mesh.rings = 6
	head.mesh = head_mesh
	head.position.y = 1.78
	head.material_override = _material(Color(0.79, 0.59, 0.38), 0.82)
	_visual.add_child(head)

	var backpack := MeshInstance3D.new()
	var backpack_mesh := BoxMesh.new()
	backpack_mesh.size = Vector3(0.52, 0.62, 0.25)
	backpack.mesh = backpack_mesh
	backpack.position = Vector3(0.0, 1.07, -0.42)
	backpack.material_override = _material(Color(0.25, 0.16, 0.08), 0.96)
	_visual.add_child(backpack)

	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.65
	collider.shape = shape
	collider.position.y = 0.84
	add_child(collider)

	var label := Label3D.new()
	label.text = "Рабочий %d · %s" % [worker_id, _resource_title(preferred_resource)]
	label.position = Vector3(0.0, 2.35, 0.0)
	label.font_size = 28
	label.outline_size = 5
	label.modulate = Color(0.95, 0.89, 0.72, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_visual.add_child(label)

func _animate_visual(delta: float) -> void:
	if _visual == null:
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	var target_scale_y := 0.98 if moving else 1.0
	_visual.scale.y = lerpf(_visual.scale.y, target_scale_y, minf(1.0, delta * 8.0))

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _resource_title(resource: String) -> String:
	match resource:
		"wood": return "дерево"
		"stone": return "камень"
		"food": return "еда"
		"gold": return "золото"
		_: return resource
