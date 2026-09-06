extends Node3D

const HarvestableScript = preload("res://scripts/harvestable.gd")
const WarehouseScript = preload("res://scripts/warehouse.gd")

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 2026090602
	_build_warehouse()
	_build_trees()
	_build_stone_and_gold()
	_build_berries()
	_build_fishing_spot()

func _material(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _build_warehouse() -> void:
	var warehouse = WarehouseScript.new()
	warehouse.name = "Warehouse"
	warehouse.position = Vector3(0.0, 0.0, -1.0)
	warehouse.deposit_radius = 5.2
	add_child(warehouse)

	for i in range(3):
		var crate := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.9, 0.65, 0.75)
		crate.mesh = mesh
		crate.position = Vector3(2.3 + float(i % 2) * 0.75, 0.34 + float(i / 2) * 0.58, -2.7)
		crate.rotation_degrees.y = -12.0 + float(i) * 8.0
		crate.material_override = _material(Color(0.34, 0.21, 0.10), 0.95)
		warehouse.add_child(crate)

func _build_trees() -> void:
	var positions := [
		Vector3(10, 0, 10), Vector3(14, 0, 5), Vector3(17, 0, -4),
		Vector3(12, 0, -13), Vector3(-10, 0, -14), Vector3(-18, 0, -8),
		Vector3(-24, 0, 3), Vector3(20, 0, 17), Vector3(27, 0, -12),
	]
	for p in positions:
		_create_tree_resource(p, rng.randf_range(0.9, 1.25))

func _create_tree_resource(p: Vector3, scale_factor: float) -> void:
	var node = HarvestableScript.new()
	node.name = "TreeResource"
	node.position = p
	node.scale = Vector3.ONE * scale_factor
	node.resource_type = "wood"
	node.source_name = "Дерево"
	node.max_amount = 14
	node.yield_amount = 1
	node.harvest_interval = 0.42
	node.regrow_delay = 32.0
	node.harvest_radius = 2.7
	add_child(node)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.19
	trunk_mesh.bottom_radius = 0.31
	trunk_mesh.height = 3.0
	trunk_mesh.radial_segments = 10
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.5
	trunk.material_override = _material(Color(0.22, 0.12, 0.055), 0.98)
	node.add_child(trunk)

	var crown_material := _material(Color(0.065, 0.29, 0.12), 0.86)
	for data in [Vector4(0, 3.15, 0, 1.45), Vector4(-0.8, 2.9, 0.1, 0.95), Vector4(0.8, 2.95, -0.1, 1.0), Vector4(0.05, 4.0, 0, 1.0)]:
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = data.w
		crown_mesh.height = data.w * 2.0
		crown_mesh.radial_segments = 12
		crown_mesh.rings = 7
		crown.mesh = crown_mesh
		crown.position = Vector3(data.x, data.y, data.z)
		crown.scale.y = 0.82
		crown.material_override = crown_material
		node.add_child(crown)

	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.38
	shape.height = 2.8
	collision.shape = shape
	collision.position.y = 1.4
	body.add_child(collision)
	node.add_child(body)

func _build_stone_and_gold() -> void:
	var stone_positions := [Vector3(8, 0, -18), Vector3(18, 0, -20), Vector3(-14, 0, -23), Vector3(-28, 0, -15), Vector3(29, 0, 8), Vector3(23, 0, 24)]
	for p in stone_positions:
		_create_rock_resource(p, false)
	var gold_positions := [Vector3(32, 0, -26), Vector3(-31, 0, 22), Vector3(34, 0, 28)]
	for p in gold_positions:
		_create_rock_resource(p, true)

func _create_rock_resource(p: Vector3, gold: bool) -> void:
	var node = HarvestableScript.new()
	node.name = "GoldResource" if gold else "StoneResource"
	node.position = p
	node.resource_type = "gold" if gold else "stone"
	node.source_name = "Золотая жила" if gold else "Камень"
	node.max_amount = 8 if gold else 12
	node.yield_amount = 1
	node.harvest_interval = 0.62 if gold else 0.5
	node.regrow_delay = 44.0 if gold else 36.0
	node.harvest_radius = 2.5
	add_child(node)

	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.95 if gold else 0.82
	mesh.height = 1.35 if gold else 1.15
	mesh.radial_segments = 9
	mesh.rings = 5
	rock.mesh = mesh
	rock.position.y = 0.56
	rock.scale = Vector3(1.25, 0.82, 0.95)
	rock.rotation_degrees = Vector3(-8, 22, 5)
	rock.material_override = _material(Color(0.48, 0.42, 0.22) if gold else Color(0.33, 0.36, 0.35), 0.82, 0.08 if gold else 0.0)
	node.add_child(rock)

	if gold:
		for offset in [Vector3(-0.35, 0.85, 0.4), Vector3(0.28, 0.55, 0.55), Vector3(0.1, 0.95, -0.25)]:
			var vein := MeshInstance3D.new()
			var vein_mesh := SphereMesh.new()
			vein_mesh.radius = 0.12
			vein_mesh.height = 0.24
			vein.mesh = vein_mesh
			vein.position = offset
			var gm := _material(Color(0.92, 0.68, 0.18), 0.3, 0.5)
			gm.emission_enabled = true
			gm.emission = Color(0.45, 0.22, 0.03)
			gm.emission_energy_multiplier = 1.4
			vein.material_override = gm
			node.add_child(vein)

	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.72
	collision.shape = shape
	collision.position.y = 0.58
	body.add_child(collision)
	node.add_child(body)

func _build_berries() -> void:
	var positions := [Vector3(6, 0, 16), Vector3(4, 0, -14), Vector3(-8, 0, -18), Vector3(-20, 0, 14), Vector3(15, 0, 22), Vector3(-27, 0, 27), Vector3(27, 0, 17)]
	for p in positions:
		_create_berry_resource(p)

func _create_berry_resource(p: Vector3) -> void:
	var node = HarvestableScript.new()
	node.name = "BerryResource"
	node.position = p
	node.resource_type = "food"
	node.source_name = "Ягодный куст"
	node.max_amount = 9
	node.yield_amount = 1
	node.harvest_interval = 0.48
	node.regrow_delay = 26.0
	node.harvest_radius = 2.35
	add_child(node)

	for data in [Vector3(0, 0.55, 0), Vector3(-0.42, 0.48, 0.18), Vector3(0.4, 0.45, -0.2)]:
		var bush := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.62
		mesh.height = 1.0
		mesh.radial_segments = 10
		mesh.rings = 6
		bush.mesh = mesh
		bush.position = data
		bush.scale.y = 0.7
		bush.material_override = _material(Color(0.10, 0.34, 0.13), 0.92)
		node.add_child(bush)
	for i in range(7):
		var berry := MeshInstance3D.new()
		var berry_mesh := SphereMesh.new()
		berry_mesh.radius = 0.075
		berry_mesh.height = 0.15
		berry_mesh.radial_segments = 8
		berry_mesh.rings = 4
		berry.mesh = berry_mesh
		berry.position = Vector3(rng.randf_range(-0.65, 0.65), rng.randf_range(0.35, 0.9), rng.randf_range(-0.55, 0.55))
		berry.material_override = _material(Color(0.72, 0.06, 0.08), 0.62)
		node.add_child(berry)

func _build_fishing_spot() -> void:
	var node = HarvestableScript.new()
	node.name = "FishingSpot"
	node.position = Vector3(-8.2, 0.0, 12.2)
	node.resource_type = "food"
	node.source_name = "Рыбалка"
	node.max_amount = 1
	node.yield_amount = 1
	node.harvest_interval = 1.35
	node.harvest_radius = 3.0
	node.infinite_source = true
	add_child(node)

	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.55
	mesh.outer_radius = 0.72
	mesh.rings = 16
	mesh.ring_segments = 24
	ring.mesh = mesh
	ring.position.y = 0.14
	ring.rotation_degrees.x = 90.0
	var water_marker := _material(Color(0.16, 0.58, 0.68, 0.82), 0.25, 0.05)
	water_marker.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = water_marker
	node.add_child(ring)

	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.06
	post_mesh.bottom_radius = 0.07
	post_mesh.height = 1.2
	post_mesh.radial_segments = 8
	post.mesh = post_mesh
	post.position = Vector3(0.9, 0.6, -0.65)
	post.material_override = _material(Color(0.31, 0.18, 0.08), 0.95)
	node.add_child(post)
