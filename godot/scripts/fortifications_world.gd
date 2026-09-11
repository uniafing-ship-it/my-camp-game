extends Node3D
class_name FortificationsWorld

const BUILDING_IDS: Array[String] = [
	"stone_wall", "watchtower", "cannon", "barracks", "infirmary", "training_ground"
]
const POSITIONS := {
	"watchtower": Vector3(4.8, 0.0, -13.0),
	"cannon": Vector3(-4.8, 0.0, -13.0),
	"barracks": Vector3(13.5, 0.0, -7.5),
	"infirmary": Vector3(-13.5, 0.0, -7.5),
	"training_ground": Vector3(0.0, 0.0, 14.5),
}
const DAMAGE_SCALE: int = 6
const CANNON_SPLASH_RADIUS: float = 3.2

var _settlement = null
var _progression = null
var _built_nodes: Dictionary = {}
var _built_levels: Dictionary = {}
var _tower_left: float = 0.0
var _cannon_left: float = 0.0

func _ready() -> void:
	add_to_group("fortifications_world")
	call_deferred("_bind")

func _process(delta: float) -> void:
	_bind_managers_if_needed()
	if _settlement == null:
		return
	var tower_level: int = _level("watchtower")
	if tower_level > 0:
		_tower_left -= delta
		if _tower_left <= 0.0 and _fire_watchtower():
			_tower_left = maxf(0.4, 1.2 * pow(0.95, tower_level - 1))
	var cannon_level: int = _level("cannon")
	if cannon_level > 0:
		_cannon_left -= delta
		if _cannon_left <= 0.0 and _fire_cannon():
			_cannon_left = maxf(0.7, 2.6 * pow(0.95, cannon_level - 1))

func _bind() -> void:
	_bind_managers_if_needed()
	if _settlement == null:
		return
	var changed: Callable = Callable(self, "_on_settlement_changed")
	if _settlement.has_signal("settlement_changed") and not _settlement.is_connected("settlement_changed", changed):
		_settlement.connect("settlement_changed", changed)
	var imported: Callable = Callable(self, "_on_settlement_changed")
	if _settlement.has_signal("state_imported") and not _settlement.is_connected("state_imported", imported):
		_settlement.connect("state_imported", imported)
	_refresh()

func _bind_managers_if_needed() -> void:
	if _settlement == null or not is_instance_valid(_settlement):
		_settlement = get_tree().get_first_node_in_group("settlement_manager")
	if _progression == null or not is_instance_valid(_progression):
		_progression = get_tree().get_first_node_in_group("progression_manager")

func _on_settlement_changed(_snapshot: Dictionary) -> void:
	_refresh()

func _refresh() -> void:
	_bind_managers_if_needed()
	if _settlement == null:
		return
	for building_id: String in BUILDING_IDS:
		var level: int = _level(building_id)
		var previous_level: int = int(_built_levels.get(building_id, -1))
		if level <= 0:
			_remove_building(building_id)
		elif not _built_nodes.has(building_id) or previous_level != level:
			_remove_building(building_id)
			_build(building_id, level)

func _remove_building(building_id: String) -> void:
	if _built_nodes.has(building_id):
		var node: Node = _built_nodes[building_id]
		if node != null and is_instance_valid(node):
			node.queue_free()
		_built_nodes.erase(building_id)
	_built_levels.erase(building_id)

func _build(building_id: String, level: int) -> void:
	var root_node := Node3D.new()
	root_node.name = "Fortification_%s" % building_id
	if POSITIONS.has(building_id):
		root_node.position = POSITIONS[building_id]
	add_child(root_node)
	_built_nodes[building_id] = root_node
	_built_levels[building_id] = level
	match building_id:
		"stone_wall":
			_build_wall(root_node, level)
		"watchtower":
			_build_watchtower(root_node, level)
		"cannon":
			_build_cannon(root_node, level)
		"barracks":
			_build_barracks(root_node, level)
		"infirmary":
			_build_infirmary(root_node, level)
		"training_ground":
			_build_training_ground(root_node, level)
	_build_label(root_node, building_id, level)

func _build_wall(root_node: Node3D, level: int) -> void:
	var radius: float = 11.5
	var segment_count: int = 24
	for i: int in range(segment_count):
		if i == 0 or i == 6 or i == 12 or i == 18:
			continue
		var angle: float = TAU * float(i) / float(segment_count)
		var position_value := Vector3(cos(angle) * radius, 0.72, sin(angle) * radius)
		var segment := _box(Vector3(2.7, 1.3 + 0.12 * float(level), 0.55), position_value, Color(0.43, 0.44, 0.40), 0.96)
		segment.rotation.y = -angle
		root_node.add_child(segment)

func _build_watchtower(root_node: Node3D, level: int) -> void:
	root_node.add_child(_box(Vector3(2.6, 0.45, 2.6), Vector3(0.0, 0.23, 0.0), Color(0.39, 0.40, 0.38), 0.96))
	var post_height: float = 3.6 + float(level) * 0.18
	for x_value: float in [-0.78, 0.78]:
		for z_value: float in [-0.78, 0.78]:
			root_node.add_child(_cylinder(0.13, 0.16, post_height, Vector3(x_value, post_height * 0.5 + 0.25, z_value), Color(0.30, 0.19, 0.09)))
	root_node.add_child(_box(Vector3(2.9, 0.28, 2.9), Vector3(0.0, post_height + 0.15, 0.0), Color(0.35, 0.22, 0.10), 0.9))
	var roof := MeshInstance3D.new()
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 2.05
	roof_mesh.height = 1.2
	roof_mesh.radial_segments = 4
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, post_height + 0.9, 0.0)
	roof.rotation_degrees.y = 45.0
	roof.material_override = _material(Color(0.18, 0.14, 0.09), 0.94)
	root_node.add_child(roof)

func _build_cannon(root_node: Node3D, level: int) -> void:
	root_node.add_child(_box(Vector3(2.1, 0.48, 1.4), Vector3(0.0, 0.55, 0.0), Color(0.30, 0.19, 0.09), 0.90))
	for x_value: float in [-0.88, 0.88]:
		var wheel := _cylinder(0.48, 0.48, 0.20, Vector3(x_value, 0.50, 0.0), Color(0.16, 0.16, 0.15), 0.78, 0.12)
		wheel.rotation_degrees.z = 90.0
		root_node.add_child(wheel)
	var barrel := _cylinder(0.20 + float(level) * 0.01, 0.28 + float(level) * 0.01, 2.9, Vector3(0.0, 1.05, -0.75), Color(0.13, 0.14, 0.14), 0.48, 0.68)
	barrel.rotation_degrees.x = 90.0
	root_node.add_child(barrel)

func _build_barracks(root_node: Node3D, level: int) -> void:
	root_node.add_child(_box(Vector3(4.5, 0.3, 3.5), Vector3(0.0, 0.15, 0.0), Color(0.40, 0.40, 0.38), 0.96))
	root_node.add_child(_box(Vector3(3.6, 2.2 + float(level) * 0.15, 2.8), Vector3(0.0, 1.3, 0.0), Color(0.34, 0.36, 0.40), 0.90))
	var roof := MeshInstance3D.new()
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 2.7
	roof_mesh.height = 1.35
	roof_mesh.radial_segments = 4
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, 3.0 + float(level) * 0.15, 0.0)
	roof.rotation_degrees.y = 45.0
	roof.scale.z = 0.78
	roof.material_override = _material(Color(0.16, 0.18, 0.24), 0.94)
	root_node.add_child(roof)

func _build_infirmary(root_node: Node3D, level: int) -> void:
	root_node.add_child(_box(Vector3(4.0, 0.2, 3.2), Vector3(0.0, 0.1, 0.0), Color(0.44, 0.40, 0.32), 0.96))
	root_node.add_child(_box(Vector3(3.4, 2.0 + float(level) * 0.12, 2.8), Vector3(0.0, 1.15, 0.0), Color(0.77, 0.75, 0.66), 0.96))
	root_node.add_child(_box(Vector3(0.28, 1.15, 0.14), Vector3(0.0, 1.45, -1.48), Color(0.63, 0.10, 0.09), 0.85))
	root_node.add_child(_box(Vector3(0.95, 0.28, 0.14), Vector3(0.0, 1.45, -1.49), Color(0.63, 0.10, 0.09), 0.85))
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.6, 0.0)
	light.light_color = Color(0.70, 1.0, 0.72)
	light.light_energy = 0.45 + float(level) * 0.12
	light.omni_range = 4.0
	root_node.add_child(light)

func _build_training_ground(root_node: Node3D, level: int) -> void:
	root_node.add_child(_cylinder(2.9, 3.1, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.48, 0.39, 0.23), 1.0))
	var dummy_count: int = 2 + level
	for i: int in range(dummy_count):
		var angle: float = TAU * float(i) / float(dummy_count)
		var dummy := Node3D.new()
		dummy.position = Vector3(cos(angle) * 1.65, 0.0, sin(angle) * 1.65)
		root_node.add_child(dummy)
		dummy.add_child(_cylinder(0.08, 0.10, 1.75, Vector3(0.0, 0.88, 0.0), Color(0.31, 0.20, 0.10)))
		dummy.add_child(_box(Vector3(1.05, 0.10, 0.10), Vector3(0.0, 1.25, 0.0), Color(0.31, 0.20, 0.10), 0.90))
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.22
		head_mesh.height = 0.44
		head_mesh.radial_segments = 8
		head_mesh.rings = 4
		head.mesh = head_mesh
		head.position = Vector3(0.0, 1.62, 0.0)
		head.material_override = _material(Color(0.53, 0.40, 0.22), 0.95)
		dummy.add_child(head)

func get_watchtower_damage() -> int:
	var level: int = _level("watchtower")
	if level <= 0:
		return 0
	return DAMAGE_SCALE + maxi(0, level - 1) * 3 + _tower_research_bonus() * 3

func get_cannon_damage() -> int:
	var level: int = _level("cannon")
	if level <= 0:
		return 0
	return DAMAGE_SCALE * 2 + maxi(0, level - 1) * DAMAGE_SCALE + _tower_research_bonus() * 3

func get_wall_slow_factor() -> float:
	var level: int = _level("stone_wall")
	if level <= 0:
		return 1.0
	var factor: float = maxf(0.2, 0.6 - 0.05 * float(level - 1))
	_bind_managers_if_needed()
	if _progression != null and _progression.has_method("has_research") and bool(_progression.has_research("walls")):
		factor = maxf(0.15, factor - 0.1)
	return factor

func fire_defenses_once_for_test() -> int:
	var hits: int = 0
	if _fire_watchtower():
		hits += 1
	if _fire_cannon():
		hits += 1
	return hits

func _fire_watchtower() -> bool:
	var level: int = _level("watchtower")
	if level <= 0:
		return false
	var origin: Vector3 = POSITIONS["watchtower"]
	var target: Node3D = _nearest_enemy(origin, 18.0 + float(level - 1) * 1.1)
	if target == null:
		return false
	if target.has_method("take_damage"):
		target.take_damage(get_watchtower_damage(), origin)
		return true
	return false

func _fire_cannon() -> bool:
	var level: int = _level("cannon")
	if level <= 0:
		return false
	var origin: Vector3 = POSITIONS["cannon"]
	var target: Node3D = _nearest_enemy(origin, 16.5 + float(level - 1))
	if target == null:
		return false
	var impact: Vector3 = target.global_position
	var damage: int = get_cannon_damage()
	var hit_any: bool = false
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not (candidate is Node3D) or not is_instance_valid(candidate):
			continue
		var enemy_node := candidate as Node3D
		if enemy_node.global_position.distance_to(impact) <= CANNON_SPLASH_RADIUS and candidate.has_method("take_damage"):
			candidate.take_damage(damage, origin)
			hit_any = true
	return hit_any

func _nearest_enemy(origin: Vector3, range_value: float) -> Node3D:
	var nearest: Node3D = null
	var nearest_distance: float = range_value
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not (candidate is Node3D) or not is_instance_valid(candidate):
			continue
		if candidate.has_method("is_alive") and not bool(candidate.is_alive()):
			continue
		var enemy_node := candidate as Node3D
		var distance_value: float = origin.distance_to(enemy_node.global_position)
		if distance_value <= nearest_distance:
			nearest = enemy_node
			nearest_distance = distance_value
	return nearest

func _level(building_id: String) -> int:
	_bind_managers_if_needed()
	if _settlement == null:
		return 0
	return int(_settlement.get_building_level(building_id))

func _tower_research_bonus() -> int:
	_bind_managers_if_needed()
	if _progression != null and _progression.has_method("get_tower_damage_bonus"):
		return int(_progression.get_tower_damage_bonus())
	return 0

func _build_label(root_node: Node3D, building_id: String, level: int) -> void:
	var label := Label3D.new()
	label.text = "%s · ур.%d" % [_building_name(building_id), level]
	label.position = Vector3(0.0, 4.9, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	label.outline_size = 7
	label.modulate = Color(0.92, 0.88, 0.76)
	root_node.add_child(label)

func _building_name(building_id: String) -> String:
	var names := {
		"stone_wall": "Каменная стена",
		"watchtower": "Сторожевая башня",
		"cannon": "Пушка",
		"barracks": "Казарма",
		"infirmary": "Лазарет",
		"training_ground": "Тренировочный плац",
	}
	return str(names.get(building_id, building_id))

func _box(size_value: Vector3, position_value: Vector3, color: Color, roughness: float = 0.9) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh_value := BoxMesh.new()
	mesh_value.size = size_value
	node.mesh = mesh_value
	node.position = position_value
	node.material_override = _material(color, roughness)
	return node

func _cylinder(top_radius: float, bottom_radius: float, height: float, position_value: Vector3, color: Color, roughness: float = 0.9, metallic: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh_value := CylinderMesh.new()
	mesh_value.top_radius = top_radius
	mesh_value.bottom_radius = bottom_radius
	mesh_value.height = height
	mesh_value.radial_segments = 12
	node.mesh = mesh_value
	node.position = position_value
	node.material_override = _material(color, roughness, metallic)
	return node

func _material(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
