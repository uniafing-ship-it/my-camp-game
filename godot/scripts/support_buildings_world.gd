extends Node3D
class_name SupportBuildingsWorld

var _settlement = null
var _built_nodes: Dictionary = {}

const POSITIONS := {
	"hunting_lodge": Vector3(10.5, 0.0, 7.0),
	"kennel": Vector3(-10.5, 0.0, 4.0),
}

func _ready() -> void:
	add_to_group("support_buildings_world")
	call_deferred("_bind")

func _bind() -> void:
	_settlement = get_tree().get_first_node_in_group("settlement_manager")
	if _settlement == null:
		return
	var changed := Callable(self, "_on_settlement_changed")
	if _settlement.has_signal("settlement_changed") and not _settlement.is_connected("settlement_changed", changed):
		_settlement.connect("settlement_changed", changed)
	_refresh()

func _on_settlement_changed(_snapshot: Dictionary) -> void:
	_refresh()

func _refresh() -> void:
	if _settlement == null:
		return
	for building_id in POSITIONS.keys():
		var level := int(_settlement.get_building_level(str(building_id)))
		if level > 0 and not _built_nodes.has(building_id):
			_build(str(building_id), level)
		elif level <= 0 and _built_nodes.has(building_id):
			var node = _built_nodes[building_id]
			if is_instance_valid(node): node.queue_free()
			_built_nodes.erase(building_id)

func _build(building_id: String, level: int) -> void:
	var root := Node3D.new()
	root.name = building_id
	root.position = POSITIONS[building_id]
	add_child(root)
	_built_nodes[building_id] = root
	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 2.3
	floor_mesh.bottom_radius = 2.45
	floor_mesh.height = 0.25
	floor_mesh.radial_segments = 12
	floor.mesh = floor_mesh
	floor.position.y = 0.12
	floor.material_override = _mat(Color(0.29,0.23,0.15), 0.94)
	root.add_child(floor)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(3.2, 1.75, 2.5)
	body.mesh = body_mesh
	body.position.y = 1.0
	body.material_override = _mat(Color(0.34,0.22,0.12) if building_id == "hunting_lodge" else Color(0.29,0.25,0.19), 0.9)
	root.add_child(body)
	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(3.7, 1.15, 3.0)
	roof.mesh = roof_mesh
	roof.position.y = 2.25
	roof.material_override = _mat(Color(0.16,0.095,0.055), 0.94)
	root.add_child(roof)
	if building_id == "hunting_lodge":
		var rack := MeshInstance3D.new()
		var rack_mesh := CylinderMesh.new()
		rack_mesh.top_radius = 0.06
		rack_mesh.bottom_radius = 0.08
		rack_mesh.height = 2.0
		rack.mesh = rack_mesh
		rack.position = Vector3(1.9,1.0,0)
		rack.rotation_degrees.z = 90
		rack.material_override = _mat(Color(0.43,0.28,0.13), 0.9)
		root.add_child(rack)
	else:
		for z in [-0.65, 0.0, 0.65]:
			var post := MeshInstance3D.new()
			var post_mesh := CylinderMesh.new()
			post_mesh.top_radius = 0.07
			post_mesh.bottom_radius = 0.09
			post_mesh.height = 1.2
			post_mesh.radial_segments = 6
			post.mesh = post_mesh
			post.position = Vector3(-2.0,0.6,z)
			post.material_override = _mat(Color(0.39,0.27,0.15),0.9)
			root.add_child(post)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
