extends Node3D

const WorkerScript = preload("res://scripts/camp_worker.gd")

const BUILDING_POSITIONS := {
	"lumber_camp": Vector3(8.2, 0.0, 0.0),
	"quarry": Vector3(-7.5, 0.0, -5.5),
	"fishing_hut": Vector3(-8.8, 0.0, 8.4),
	"hunting_lodge": Vector3(8.8, 0.0, 7.4),
	"kennel": Vector3(8.8, 0.0, -7.8),
}

var _settlement_manager = null
var _building_nodes: Dictionary = {}
var _worker_spawn_index := 0

func _ready() -> void:
	call_deferred("_bind")

func _bind() -> void:
	_settlement_manager = get_tree().get_first_node_in_group("settlement_manager")
	if _settlement_manager == null:
		return
	if _settlement_manager.has_signal("building_built"):
		_settlement_manager.connect("building_built", Callable(self, "_on_building_changed"))
	if _settlement_manager.has_signal("building_upgraded"):
		_settlement_manager.connect("building_upgraded", Callable(self, "_on_building_changed"))
	if _settlement_manager.has_signal("worker_recruited"):
		_settlement_manager.connect("worker_recruited", Callable(self, "_on_worker_recruited"))
	_build_all_plots()
	for i in range(int(_settlement_manager.worker_count)):
		_spawn_worker(i + 1)

func _build_all_plots() -> void:
	for building_id in BUILDING_POSITIONS.keys():
		_rebuild_building(str(building_id), int(_settlement_manager.get_building_level(str(building_id))))

func _on_building_changed(building_id: String, level: int) -> void:
	if not BUILDING_POSITIONS.has(building_id):
		return
	_rebuild_building(building_id, level)

func _on_worker_recruited(worker_id: int) -> void:
	_spawn_worker(worker_id)

func _rebuild_building(building_id: String, level: int) -> void:
	if not BUILDING_POSITIONS.has(building_id):
		return
	if _building_nodes.has(building_id):
		var old_node = _building_nodes[building_id]
		if is_instance_valid(old_node):
			old_node.queue_free()
	var root := Node3D.new()
	root.name = "Building_%s" % building_id
	root.position = BUILDING_POSITIONS[building_id]
	add_child(root)
	_building_nodes[building_id] = root
	_build_foundation(root, building_id, level)
	if level <= 0:
		_build_blueprint(root, building_id)
	else:
		match building_id:
			"lumber_camp": _build_lumber_camp(root, level)
			"quarry": _build_quarry(root, level)
			"fishing_hut": _build_fishing_hut(root, level)
			"hunting_lodge": _build_hunting_lodge(root, level)
			"kennel": _build_kennel(root, level)
	_build_label(root, building_id, level)

func _build_foundation(root: Node3D, building_id: String, level: int) -> void:
	var pad := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.7
	mesh.bottom_radius = 2.9
	mesh.height = 0.10
	mesh.radial_segments = 24
	pad.mesh = mesh
	pad.position.y = 0.05
	pad.material_override = _material(Color(0.28, 0.23, 0.15) if level > 0 else Color(0.22, 0.25, 0.18), 0.98)
	root.add_child(pad)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 2.55
	ring_mesh.outer_radius = 2.70
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 32
	ring.mesh = ring_mesh
	ring.position.y = 0.12
	ring.rotation_degrees.x = 90.0
	var color := Color(0.78, 0.62, 0.28, 0.75) if level > 0 else Color(0.52, 0.62, 0.45, 0.55)
	var ring_mat := _material(color, 0.65)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	root.add_child(ring)

func _build_blueprint(root: Node3D, building_id: String) -> void:
	for i in range(4):
		var post := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.05
		mesh.bottom_radius = 0.07
		mesh.height = 1.15
		mesh.radial_segments = 6
		post.mesh = mesh
		var angle := TAU * float(i) / 4.0 + PI * 0.25
		post.position = Vector3(cos(angle) * 1.6, 0.58, sin(angle) * 1.6)
		post.material_override = _material(Color(0.50, 0.38, 0.20), 0.98)
		root.add_child(post)
	var rope_mat := _material(Color(0.75, 0.65, 0.42), 0.95)
	for z in [-1.6, 1.6]:
		var rope := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(3.2, 0.04, 0.04)
		rope.mesh = mesh
		rope.position = Vector3(0.0, 0.95, z)
		rope.material_override = rope_mat
		root.add_child(rope)

func _build_lumber_camp(root: Node3D, level: int) -> void:
	var floor := _box(Vector3(3.8, 0.18, 3.2), Vector3(0, 0.20, 0), Color(0.34, 0.21, 0.10))
	root.add_child(floor)
	var shed := _box(Vector3(2.7 + level * 0.25, 1.45, 2.0), Vector3(-0.35, 0.95, -0.35), Color(0.43, 0.28, 0.13))
	root.add_child(shed)
	var roof := _box(Vector3(3.1 + level * 0.28, 0.22, 2.45), Vector3(-0.35, 1.78, -0.35), Color(0.13, 0.19, 0.12))
	roof.rotation_degrees.z = -5.0
	root.add_child(roof)
	for i in range(4 + level * 2):
		var log := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.13
		mesh.bottom_radius = 0.15
		mesh.height = 1.45
		mesh.radial_segments = 8
		log.mesh = mesh
		log.rotation_degrees.z = 90.0
		log.position = Vector3(1.25, 0.25 + float(i % 3) * 0.22, -0.9 + float(i / 3) * 0.48)
		log.material_override = _material(Color(0.31, 0.17, 0.075), 0.98)
		root.add_child(log)

func _build_quarry(root: Node3D, level: int) -> void:
	var pit := MeshInstance3D.new()
	var pit_mesh := CylinderMesh.new()
	pit_mesh.top_radius = 2.15
	pit_mesh.bottom_radius = 1.65
	pit_mesh.height = 0.28
	pit_mesh.radial_segments = 18
	pit.mesh = pit_mesh
	pit.position.y = 0.02
	pit.material_override = _material(Color(0.25, 0.27, 0.26), 1.0)
	root.add_child(pit)
	for i in range(5 + level * 2):
		var stone := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.28 + float(i % 3) * 0.07
		mesh.height = mesh.radius * 1.35
		mesh.radial_segments = 8
		mesh.rings = 4
		stone.mesh = mesh
		var angle := TAU * float(i) / float(5 + level * 2)
		stone.position = Vector3(cos(angle) * 1.35, 0.28, sin(angle) * 1.35)
		stone.scale = Vector3(1.2, 0.72, 0.95)
		stone.material_override = _material(Color(0.38, 0.40, 0.39), 0.95)
		root.add_child(stone)
	var mast := _box(Vector3(0.18, 2.5, 0.18), Vector3(1.45, 1.25, -1.0), Color(0.35, 0.22, 0.10))
	root.add_child(mast)
	var arm := _box(Vector3(1.9 + level * 0.2, 0.14, 0.14), Vector3(0.65, 2.35, -1.0), Color(0.35, 0.22, 0.10))
	arm.rotation_degrees.z = -12.0
	root.add_child(arm)

func _build_fishing_hut(root: Node3D, level: int) -> void:
	var deck := _box(Vector3(3.5, 0.18, 2.8), Vector3(0, 0.25, 0), Color(0.35, 0.23, 0.12))
	root.add_child(deck)
	var hut := _box(Vector3(2.35 + level * 0.18, 1.4, 1.85), Vector3(0.35, 0.98, 0.15), Color(0.50, 0.34, 0.18))
	root.add_child(hut)
	var roof := _box(Vector3(2.75 + level * 0.18, 0.24, 2.25), Vector3(0.35, 1.82, 0.15), Color(0.12, 0.20, 0.17))
	roof.rotation_degrees.z = 6.0
	root.add_child(roof)
	for i in range(3):
		var post := _box(Vector3(0.12, 0.95, 0.12), Vector3(-1.1 + i * 1.1, 0.46, 1.7), Color(0.28, 0.17, 0.08))
		root.add_child(post)
	var lantern := OmniLight3D.new()
	lantern.position = Vector3(-0.75, 1.55, 0.95)
	lantern.light_color = Color(1.0, 0.64, 0.30)
	lantern.light_energy = 1.1 + float(level) * 0.25
	lantern.omni_range = 4.0
	root.add_child(lantern)

func _build_hunting_lodge(root: Node3D, level: int) -> void:
	var floor := _box(Vector3(3.8, 0.18, 3.0), Vector3(0.0, 0.2, 0.0), Color(0.30, 0.19, 0.09))
	root.add_child(floor)
	var cabin := _box(Vector3(2.8, 1.55, 2.1), Vector3(-0.15, 1.0, -0.2), Color(0.39, 0.25, 0.12))
	root.add_child(cabin)
	var roof := _box(Vector3(3.2, 0.24, 2.5), Vector3(-0.15, 1.88, -0.2), Color(0.16, 0.14, 0.10))
	roof.rotation_degrees.z = -7.0
	root.add_child(roof)
	for x in [-1.35, 1.35]:
		var rack := _box(Vector3(0.12, 1.5, 0.12), Vector3(x, 0.82, 1.0), Color(0.30, 0.18, 0.08))
		root.add_child(rack)
	var beam := _box(Vector3(2.8, 0.12, 0.12), Vector3(0.0, 1.45, 1.0), Color(0.30, 0.18, 0.08))
	root.add_child(beam)
	var hide := _box(Vector3(1.15, 0.06, 0.85), Vector3(0.0, 1.0, 1.06), Color(0.46, 0.30, 0.17))
	hide.rotation_degrees.x = 90.0
	root.add_child(hide)
	var lantern := OmniLight3D.new()
	lantern.position = Vector3(0.9, 1.45, 0.9)
	lantern.light_color = Color(1.0, 0.57, 0.26)
	lantern.light_energy = 0.9 + float(level) * 0.15
	lantern.omni_range = 3.8
	root.add_child(lantern)

func _build_kennel(root: Node3D, level: int) -> void:
	var yard := _box(Vector3(3.9, 0.14, 3.1), Vector3(0.0, 0.18, 0.0), Color(0.27, 0.22, 0.14))
	root.add_child(yard)
	var hut := _box(Vector3(1.75, 1.15, 1.65), Vector3(-0.65, 0.78, -0.35), Color(0.39, 0.25, 0.12))
	root.add_child(hut)
	var roof := _box(Vector3(2.05, 0.20, 1.95), Vector3(-0.65, 1.45, -0.35), Color(0.15, 0.13, 0.10))
	roof.rotation_degrees.z = 8.0
	root.add_child(roof)
	for x in [-1.65, 1.65]:
		for z in [-1.2, 1.2]:
			var post := _box(Vector3(0.10, 1.05, 0.10), Vector3(x, 0.58, z), Color(0.33, 0.21, 0.10))
			root.add_child(post)
	for z in [-1.2, 1.2]:
		var rail := _box(Vector3(3.4, 0.09, 0.09), Vector3(0.0, 0.82, z), Color(0.33, 0.21, 0.10))
		root.add_child(rail)
	var bowl := MeshInstance3D.new()
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 0.42
	bowl_mesh.bottom_radius = 0.31
	bowl_mesh.height = 0.16
	bowl_mesh.radial_segments = 14
	bowl.mesh = bowl_mesh
	bowl.position = Vector3(0.85, 0.23, 0.55)
	bowl.material_override = _material(Color(0.30, 0.32, 0.31), 0.6)
	root.add_child(bowl)

func _build_label(root: Node3D, building_id: String, level: int) -> void:
	var label := Label3D.new()
	var names := {
		"lumber_camp": "Лесопилка",
		"quarry": "Каменоломня",
		"fishing_hut": "Рыбацкая хижина",
		"hunting_lodge": "Охотничья изба",
		"kennel": "Псарня",
	}
	label.text = "%s · %s" % [str(names.get(building_id, building_id)), "проект" if level <= 0 else "ур.%d" % level]
	label.position = Vector3(0.0, 2.9 if level > 0 else 1.8, 0.0)
	label.font_size = 30
	label.outline_size = 6
	label.modulate = Color(0.95, 0.88, 0.68, 0.96)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

func _spawn_worker(worker_id: int) -> void:
	var worker = WorkerScript.new()
	worker.name = "Worker_%d" % worker_id
	worker.worker_id = worker_id
	worker.preferred_resource = _job_for_worker(worker_id)
	var angle := TAU * float(_worker_spawn_index % 8) / 8.0
	worker.position = Vector3(cos(angle) * 3.3, 0.15, sin(angle) * 3.3)
	_worker_spawn_index += 1
	add_child(worker)

func _job_for_worker(worker_id: int) -> String:
	var jobs: Array[String] = []
	if int(_settlement_manager.get_building_level("lumber_camp")) > 0:
		jobs.append("wood")
	if int(_settlement_manager.get_building_level("quarry")) > 0:
		jobs.append("stone")
	if int(_settlement_manager.get_building_level("fishing_hut")) > 0:
		jobs.append("food")
	if int(_settlement_manager.get_building_level("quarry")) >= 2:
		jobs.append("gold")
	if jobs.is_empty():
		jobs.append("wood")
	return jobs[(worker_id - 1) % jobs.size()]

func _box(size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = _material(color, 0.92)
	return node

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
