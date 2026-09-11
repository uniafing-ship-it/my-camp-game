extends Node3D
class_name Stage10SettlementWorld

const POSITIONS := {
	"house":Vector3(-15.5,0.0,13.5),
	"gold_mine":Vector3(-20.5,0.0,4.5),
	"forge":Vector3(-20.0,0.0,-6.5),
	"workshop":Vector3(-13.5,0.0,-15.5),
	"residential_house":Vector3(13.5,0.0,-15.5),
	"big_house":Vector3(20.0,0.0,-6.0),
	"farm":Vector3(20.5,0.0,6.0),
}
const COLORS := {
	"house":Color(0.48,0.32,0.18),
	"gold_mine":Color(0.58,0.47,0.20),
	"forge":Color(0.28,0.29,0.30),
	"workshop":Color(0.40,0.29,0.17),
	"residential_house":Color(0.52,0.38,0.24),
	"big_house":Color(0.45,0.31,0.20),
	"farm":Color(0.36,0.50,0.22),
}

var _manager = null
var _roots: Dictionary = {}
var _labels: Dictionary = {}

func _ready() -> void:
	_build_sites()
	call_deferred("_bind")

func _bind() -> void:
	_manager = get_tree().get_first_node_in_group("stage10_settlement_parity")
	if _manager == null:
		return
	var cb := Callable(self,"_refresh")
	if _manager.has_signal("parity_changed") and not _manager.is_connected("parity_changed",cb):
		_manager.connect("parity_changed",cb)
	_refresh(_manager.get_snapshot())

func _build_sites() -> void:
	for id in POSITIONS.keys():
		var root := Node3D.new()
		root.name = "Stage10_%s" % id
		root.position = POSITIONS[id]
		add_child(root)
		_roots[id] = root

		var pad := MeshInstance3D.new()
		var pad_mesh := CylinderMesh.new()
		pad_mesh.top_radius = 2.5
		pad_mesh.bottom_radius = 2.7
		pad_mesh.height = 0.18
		pad_mesh.radial_segments = 12
		pad.mesh = pad_mesh
		pad.position.y = 0.09
		pad.material_override = _material(Color(0.22,0.19,0.13),0.98)
		root.add_child(pad)

		var body := MeshInstance3D.new()
		body.name = "BuildingBody"
		var body_mesh := BoxMesh.new()
		body_mesh.size = Vector3(3.4,2.2,3.0)
		body.mesh = body_mesh
		body.position.y = 1.2
		body.material_override = _material(COLORS[id],0.88)
		root.add_child(body)

		var roof := MeshInstance3D.new()
		var roof_mesh := PrismMesh.new()
		roof_mesh.size = Vector3(3.9,1.4,3.5)
		roof.mesh = roof_mesh
		roof.position.y = 2.75
		roof.rotation_degrees.y = 90.0
		roof.material_override = _material(Color(0.25,0.13,0.08),0.94)
		root.add_child(roof)

		if id == "gold_mine":
			_add_chimney(root,Color(0.32,0.30,0.25))
		elif id == "forge":
			_add_chimney(root,Color(0.22,0.22,0.23))
		elif id == "farm":
			_add_farm_rows(root)

		var label := Label3D.new()
		label.position = Vector3(0.0,4.1,0.0)
		label.font_size = 26
		label.outline_size = 5
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(1.0,0.88,0.58)
		root.add_child(label)
		_labels[id] = label
		root.visible = false

func _refresh(_snapshot: Dictionary = {}) -> void:
	if _manager == null:
		return
	for id in _roots.keys():
		var level := int(_manager.get_building_level(str(id)))
		var root: Node3D = _roots[id]
		root.visible = level > 0
		if level > 0:
			var def: Dictionary = _manager.LEGACY_BUILDINGS[id]
			(_labels[id] as Label3D).text = "%s · ур. %d" % [str(def["name"]),level]
			root.scale = Vector3.ONE * (1.0 + minf(0.25,float(level-1)*0.06))

func _add_chimney(root: Node3D, color: Color) -> void:
	var chimney := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.34
	mesh.height = 2.2
	mesh.radial_segments = 8
	chimney.mesh = mesh
	chimney.position = Vector3(1.05,2.9,0.65)
	chimney.material_override = _material(color,0.96)
	root.add_child(chimney)

func _add_farm_rows(root: Node3D) -> void:
	for i in range(4):
		var row := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.32,0.16,4.2)
		row.mesh = mesh
		row.position = Vector3(-2.2+float(i)*1.45,0.14,0.0)
		row.material_override = _material(Color(0.30,0.47,0.16),0.95)
		root.add_child(row)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
