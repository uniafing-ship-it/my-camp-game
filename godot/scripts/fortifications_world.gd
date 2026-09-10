extends Node3D
class_name FortificationsWorld

const BUILDING_IDS := ["stone_wall", "watchtower", "cannon", "barracks", "infirmary", "training_ground"]
const POSITIONS := {
	"watchtower": Vector3(4.8, 0.0, -13.0),
	"cannon": Vector3(-4.8, 0.0, -13.0),
	"barracks": Vector3(13.5, 0.0, -7.5),
	"infirmary": Vector3(-13.5, 0.0, -7.5),
	"training_ground": Vector3(0.0, 0.0, 14.5),
}
const DAMAGE_SCALE := 6
const CANNON_SPLASH_RADIUS := 3.2

var _settlement = null
var _progression = null
var _built_nodes: Dictionary = {}
var _built_levels: Dictionary = {}
var _tower_left := 0.0
var _cannon_left := 0.0

func _ready() -> void:
	add_to_group("fortifications_world")
	call_deferred("_bind")

func _process(delta: float) -> void:
	if _settlement == null or not is_instance_valid(_settlement):
		_bind()
	if _settlement == null:
		return
	var tower_level := int(_settlement.get_building_level("watchtower"))
	if tower_level > 0:
		_tower_left -= delta
		if _tower_left <= 0.0 and _fire_watchtower():
			_tower_left = maxf(0.4, 1.2 * pow(0.95, tower_level - 1))
	var cannon_level := int(_settlement.get_building_level("cannon"))
	if cannon_level > 0:
		_cannon_left -= delta
		if _cannon_left <= 0.0 and _fire_cannon():
			_cannon_left = maxf(0.4, 2.6 * pow(0.95, cannon_level - 1))

func _bind() -> void:
	_settlement = get_tree().get_first_node_in_group("settlement_manager")
	_progression = get_tree().get_first_node_in_group("progression_manager")
	if _settlement == null:
		return
	var changed := Callable(self, "_on_settlement_changed")
	if _settlement.has_signal("settlement_changed") and not _settlement.is_connected("settlement_changed", changed):
		_settlement.connect("settlement_changed", changed)
	var imported := Callable(self, "_on_settlement_changed")
	if _settlement.has_signal("state_imported") and not _settlement.is_connected("state_imported", imported):
		_settlement.connect("state_imported", imported)
	_refresh()

func _on_settlement_changed(_snapshot: Dictionary) -> void:
	_refresh()

func _refresh() -> void:
	if _settlement == null:
		return
	for building_id in BUILDING_IDS:
		var level := int(_settlement.get_building_level(building_id))
		if level <= 0:
			_remove_building(building_id)
		elif not _built_nodes.has(building_id) or int(_built_levels.get(building_id, -1)) != level:
			_remove_building(building_id)
			_build(building_id, level)

func _remove_building(building_id: String) -> void:
	if _built_nodes.has(building_id):
		var node = _built_nodes[building_id]
		if node != null and is_instance_valid(node):
			node.queue_free()
		_built_nodes.erase(building_id)
	_built_levels.erase(building_id)

func _build(building_id: String, level: int) -> void:
	var root := Node3D.new()
	root.name = "Fortification_%s" % building_id
	root.position = POSITIONS.get(building_id, Vector3.ZERO)
	add_child(root)
	_built_nodes[building_id] = root
	_built_levels[building_id] = level
	match building_id:
		"stone_wall": _build_wall(root, level)
		"watchtower": _build_watchtower(root, level)
		"cannon": _build_cannon(root, level)
		"barracks": _build_barracks(root, level)
		"infirmary": _build_infirmary(root, level)
		"training_ground": _build_training_ground(root, level)
	_build_label(root, building_id, level)

func _build_wall(root: Node3D, level: int) -> void:
	var radius := 11.5
	var segments := 24
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		# Keep four narrow gates so player/NPC circulation is not visually blocked.
		if i in [0, 6, 12, 18]:
			continue
		var segment := _box(Vector3(2.7, 1.25 + 0.12 * level, 0.55), Vector3(cos(angle) * radius, 0.66, sin(angle) * radius), Color(0.43, 0.44, 0.40), 0.96)
		segment.rotation.y = -angle
		root.add_child(segment)
		for offset in [-1.05, 1.05]:
			var merlon := _box(Vector3(0.46, 0.42, 0.64), Vector3(cos(angle) * radius, 1.46 + 0.12 * level, sin(angle) * radius), Color(0.51, 0.51, 0.46), 0.98)
			var tangent := Vector3(-sin(angle), 0.0, cos(angle)) * offset
			merlon.position += tangent
			merlon.rotation.y = -angle
			root.add_child(merlon)

func _build_watchtower(root: Node3D, level: int) -> void:
	var stone := _box(Vector3(2.5, 0.45, 2.5), Vector3(0, 0.23, 0), Color(0.39,0.40,0.38), 0.96)
	root.add_child(stone)
	for x in [-0.78, 0.78]:
		for z in [-0.78, 0.78]:
			var post := _cylinder(0.12, 0.16, 3.6 + level * 0.18, Vector3(x, 1.9, z), Color(0.30,0.19,0.09))
			root.add_child(post)
	var deck := _box(Vector3(2.8,0.28,2.8), Vector3(0,3.55 + level * 0.18,0), Color(0.35,0.22,0.10), 0.9)
	root.add_child(deck)
	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(3.2,1.1,3.2)
	roof.mesh = roof_mesh
	roof.position = Vector3(0,4.25 + level * 0.18,0)
	roof.material_override = _material(Color(0.18,0.14,0.09),0.94)
	root.add_child(roof)
	var bow := MeshInstance3D.new()
	var bow_mesh := TorusMesh.new()
	bow_mesh.inner_radius = 0.32
	bow_mesh.outer_radius = 0.37
	bow_mesh.rings = 12
	bow_mesh.ring_segments = 12
	bow.mesh = bow_mesh
	bow.position = Vector3(0,3.95 + level * 0.18,-0.65)
	bow.rotation_degrees.x = 90
	bow.material_override = _material(Color(0.58,0.38,0.15),0.82)
	root.add_child(bow)

func _build_cannon(root: Node3D, level: int) -> void:
	var base := _cylinder(1.45, 1.65, 0.42, Vector3(0,0.21,0), Color(0.38,0.39,0.38))
	root.add_child(base)
	var carriage := _box(Vector3(1.9,0.48,1.3), Vector3(0,0.65,0), Color(0.30,0.19,0.09),0.9)
	root.add_child(carriage)
	for x in [-0.82,0.82]:
		var wheel := _cylinder(0.46,0.46,0.18,Vector3(x,0.58,0),Color(0.17,0.16,0.14),0.78,0.15)
		wheel.rotation_degrees.z = 90
		root.add_child(wheel)
	var barrel := _cylinder(0.19 + level * 0.015,0.27 + level * 0.015,2.8,Vector3(0,1.05,-0.75),Color(0.13,0.14,0.14),0.48,0.65)
	barrel.rotation_degrees.x = 90
	root.add_child(barrel)

func _build_barracks(root: Node3D, level: int) -> void:
	var base := _box(Vector3(4.4,0.3,3.4),Vector3(0,0.15,0),Color(0.40,0.40,0.38),0.96)
	root.add_child(base)
	var body := _box(Vector3(3.5,2.1 + level * 0.15,2.7),Vector3(0,1.2,0),Color(0.34,0.36,0.40),0.9)
	root.add_child(body)
	var roof := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(4.1,1.35,3.25)
	roof.mesh = mesh
	roof.position = Vector3(0,2.8 + level * 0.15,0)
	roof.material_override = _material(Color(0.16,0.18,0.24),0.94)
	root.add_child(roof)
	for x in [-1.1,0.0,1.1]:
		var shield := _cylinder(0.29,0.29,0.08,Vector3(x,1.25,-1.39),Color(0.35,0.16,0.12),0.75,0.12)
		shield.rotation_degrees.x = 90
		root.add_child(shield)

func _build_infirmary(root: Node3D, level: int) -> void:
	var floor := _box(Vector3(4.0,0.2,3.2),Vector3(0,0.1,0),Color(0.44,0.40,0.32),0.96)
	root.add_child(floor)
	var tent := MeshInstance3D.new()
	var tent_mesh := PrismMesh.new()
	tent_mesh.size = Vector3(3.6,2.3 + level * 0.12,3.0)
	tent.mesh = tent_mesh
	tent.position = Vector3(0,1.25,0)
	tent.material_override = _material(Color(0.77,0.75,0.66),0.96)
	root.add_child(tent)
	var cross_v := _box(Vector3(0.28,1.1,0.12),Vector3(0,1.55,-1.54),Color(0.63,0.10,0.09),0.85)
	root.add_child(cross_v)
	var cross_h := _box(Vector3(0.9,0.28,0.12),Vector3(0,1.55,-1.55),Color(0.63,0.10,0.09),0.85)
	root.add_child(cross_h)
	var light := OmniLight3D.new()
	light.position = Vector3(0,1.5,0)
	light.light_color = Color(0.70,1.0,0.72)
	light.light_energy = 0.45 + level * 0.12
	light.omni_range = 4.0
	root.add_child(light)

func _build_training_ground(root: Node3D, level: int) -> void:
	var ground := _cylinder(2.9,3.1,0.12,Vector3(0,0.06,0),Color(0.48,0.39,0.23),1.0)
	root.add_child(ground)
	for i in range(2 + level):
		var angle := TAU * float(i) / float(2 + level)
		var dummy_root := Node3D.new()
		dummy_root.position = Vector3(cos(angle) * 1.65,0,sin(angle) * 1.65)
		root.add_child(dummy_root)
		var pole := _cylinder(0.08,0.10,1.75,Vector3(0,0.88,0),Color(0.31,0.20,0.10))
		dummy_root.add_child(pole)
		var arm := _box(Vector3(1.05,0.10,0.10),Vector3(0,1.25,0),Color(0.31,0.20,0.10),0.9)
		dummy_root.add_child(arm)
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.22
		head_mesh.height = 0.44
		head_mesh.radial_segments = 8
		head_mesh.rings = 4
		head.mesh = head_mesh
		head.position = Vector3(0,1.62,0)
		head.material_override = _material(Color(0.53,0.40,0.22),0.95)
		dummy_root.add_child(head)

func get_watchtower_damage() -> int:
	var level := _level("watchtower")
	if level <= 0:
		return 0
	return (1 + (level - 1) + _tower_research_bonus()) * DAMAGE_SCALE

func get_cannon_damage() -> int:
	var level := _level("cannon")
	if level <= 0:
		return 0
	return (2 + (level - 1) + _tower_research_bonus()) * DAMAGE_SCALE

func get_wall_slow_factor() -> float:
	var level := _level("stone_wall")
	if level <= 0:
		return 1.0
	var factor := maxf(0.2, 0.6 - 0.05 * float(level - 1))
	if _progression != null and _progression.has_method("has_research") and bool(_progression.has_research("walls")):
		factor = maxf(0.15, factor - 0.1)
	return factor

func fire_defenses_once_for_test() -> int:
	var hits := 0
	if _fire_watchtower():
		hits += 1
	if _fire_cannon():
		hits += 1
	return hits

func _fire_watchtower() -> bool:
	var level := _level("watchtower")
	if level <= 0:
		return false
	var origin: Vector3 = POSITIONS["watchtower"]
	var target := _nearest_enemy(origin, 18.0 + float(level - 1) * 1.1)
	if target == null:
		return false
	target.take_damage(get_watchtower_damage(), origin)
	return true

func _fire_cannon() -> bool:
	var level := _level("cannon")
	if level <= 0:
		return false
	var origin: Vector3 = POSITIONS["cannon"]
	var target := _nearest_enemy(origin, 16.5 + float(level - 1) * 1.0)
	if target == null:
		return false
	var impact := target.global_position
	var damage := get_cannon_damage()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D) or not is_instance_valid(enemy):
			continue
		if (enemy as Node3D).global_position.distance_to(impact) <= CANNON_SPLASH_RADIUS and enemy.has_method("take_damage"):
			enemy.take_damage(damage, origin)
	return true

func _nearest_enemy(origin: Vector3, radius: float) -> Node3D:
	var best: Node3D = null
	var best_distance := radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D) or not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_alive") and not bool(enemy.is_alive()):
			continue
		var distance := origin.distance_to((enemy as Node3D).global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

func _tower_research_bonus() -> int:
	if _progression == null or not is_instance_valid(_progression):
		_progression = get_tree().get_first_node_in_group("progression_manager")
	return 1 if _progression != null and _progression.has_method("has_research") and bool(_progression.has_research("arrows")) else 0

func _level(building_id: String) -> int:
	if _settlement == null or not is_instance_valid(_settlement):
		_settlement = get_tree().get_first_node_in_group("settlement_manager")
	return int(_settlement.get_building_level(building_id)) if _settlement != null else 0

func _build_label(root: Node3D, building_id: String, level: int) -> void:
	var names := {
		"stone_wall":"Каменная стена",
		"watchtower":"Сторожевая башня",
		"cannon":"Пушка",
		"barracks":"Казарма",
		"infirmary":"Лазарет",
		"training_ground":"Тренировочный плац",
	}
	var label := Label3D.new()
	label.text = "%s · ур.%d" % [str(names.get(building_id, building_id)), level]
	label.position = Vector3(0, 2.8 if building_id not in ["watchtower", "stone_wall"] else (5.0 if building_id == "watchtower" else 2.1), 0)
	label.font_size = 24
	label.outline_size = 5
	label.modulate = Color(0.94,0.88,0.70,0.94)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

func _box(size: Vector3, position: Vector3, color: Color, roughness := 0.92) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = _material(color, roughness)
	return node

func _cylinder(top_radius: float, bottom_radius: float, height: float, position: Vector3, color: Color, roughness := 0.9, metallic := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.position = position
	node.material_override = _material(color, roughness, metallic)
	return node

func _material(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
