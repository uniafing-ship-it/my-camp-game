extends Node3D

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20260906
	_build_environment()
	_build_ground()
	_build_water()
	_build_camp()
	_build_test_forest()
	_build_rocks()

func _material(color: Color, roughness: float = 0.72, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.33, 0.48, 0.38)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.63, 0.72, 0.65)
	environment.ambient_light_energy = 0.72
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.58, 0.68, 0.61)
	environment.fog_light_energy = 0.72
	environment.fog_density = 0.008
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
	sun.light_color = Color(1.0, 0.89, 0.70)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 75.0
	add_child(sun)

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(120.0, 120.0)
	mesh.subdivide_width = 24
	mesh.subdivide_depth = 24
	ground.mesh = mesh
	ground.material_override = _material(Color(0.20, 0.39, 0.22), 0.95)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

	var static_body := StaticBody3D.new()
	static_body.name = "GroundCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(120.0, 0.3, 120.0)
	collision.shape = shape
	collision.position.y = -0.17
	static_body.add_child(collision)
	add_child(static_body)

	for i in range(70):
		var patch := MeshInstance3D.new()
		var patch_mesh := CylinderMesh.new()
		patch_mesh.top_radius = _rng.randf_range(0.35, 1.2)
		patch_mesh.bottom_radius = patch_mesh.top_radius
		patch_mesh.height = 0.012
		patch_mesh.radial_segments = 12
		patch.mesh = patch_mesh
		patch.position = Vector3(_rng.randf_range(-52.0, 52.0), 0.008, _rng.randf_range(-52.0, 52.0))
		patch.scale.z = _rng.randf_range(0.45, 1.55)
		patch.material_override = _material(Color(0.16 + _rng.randf_range(-0.02, 0.03), 0.33 + _rng.randf_range(-0.02, 0.04), 0.17), 1.0)
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(patch)

func _build_water() -> void:
	var water := MeshInstance3D.new()
	water.name = "Pond"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(16.0, 11.0)
	mesh.subdivide_width = 36
	mesh.subdivide_depth = 24
	water.mesh = mesh
	water.position = Vector3(-14.0, 0.08, 12.0)
	water.scale = Vector3(1.0, 1.0, 0.82)

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

void vertex() {
	float wave_a = sin((VERTEX.x + TIME * 1.6) * 0.85) * 0.07;
	float wave_b = cos((VERTEX.z - TIME * 1.15) * 1.10) * 0.05;
	VERTEX.y += wave_a + wave_b;
}

void fragment() {
	vec3 shallow = vec3(0.20, 0.58, 0.68);
	vec3 deep = vec3(0.035, 0.19, 0.29);
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
	ALBEDO = mix(deep, shallow, 0.48 + fresnel * 0.34);
	ROUGHNESS = 0.16;
	METALLIC = 0.08;
	ALPHA = 0.83;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	water.material_override = material
	add_child(water)

	var shore := MeshInstance3D.new()
	shore.name = "PondShore"
	var shore_mesh := CylinderMesh.new()
	shore_mesh.top_radius = 8.9
	shore_mesh.bottom_radius = 8.9
	shore_mesh.height = 0.055
	shore_mesh.radial_segments = 48
	shore.mesh = shore_mesh
	shore.position = Vector3(-14.0, 0.018, 12.0)
	shore.scale.z = 0.72
	shore.material_override = _material(Color(0.39, 0.31, 0.18), 1.0)
	shore.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	move_child(shore, 0)
	add_child(shore)

func _build_camp() -> void:
	var camp_floor := MeshInstance3D.new()
	camp_floor.name = "CampFloor"
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 6.2
	floor_mesh.bottom_radius = 6.2
	floor_mesh.height = 0.09
	floor_mesh.radial_segments = 40
	camp_floor.mesh = floor_mesh
	camp_floor.position.y = 0.045
	camp_floor.material_override = _material(Color(0.42, 0.32, 0.20), 0.92)
	add_child(camp_floor)

	var hall := Node3D.new()
	hall.name = "TownHallPrototype"
	hall.position = Vector3(0.0, 0.0, -1.0)
	add_child(hall)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(3.8, 2.1, 3.2)
	body.mesh = body_mesh
	body.position.y = 1.05
	body.material_override = _material(Color(0.50, 0.34, 0.19), 0.82)
	hall.add_child(body)

	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(4.5, 1.45, 3.8)
	roof.mesh = roof_mesh
	roof.position.y = 2.82
	roof.rotation_degrees.y = 90.0
	roof.material_override = _material(Color(0.12, 0.19, 0.14), 0.75)
	hall.add_child(roof)

	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.85, 1.45, 0.12)
	door.mesh = door_mesh
	door.position = Vector3(0.0, 0.75, 1.64)
	door.material_override = _material(Color(0.17, 0.10, 0.055), 0.9)
	hall.add_child(door)

	for i in range(20):
		var angle := TAU * float(i) / 20.0
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.10
		post_mesh.bottom_radius = 0.14
		post_mesh.height = 1.25
		post_mesh.radial_segments = 8
		post.mesh = post_mesh
		post.position = Vector3(cos(angle) * 7.3, 0.62, sin(angle) * 7.3)
		post.material_override = _material(Color(0.25, 0.15, 0.075), 0.95)
		add_child(post)

	var fire_light := OmniLight3D.new()
	fire_light.name = "CampFireLight"
	fire_light.position = Vector3(-2.2, 1.0, 2.3)
	fire_light.light_color = Color(1.0, 0.47, 0.16)
	fire_light.light_energy = 2.2
	fire_light.omni_range = 8.5
	fire_light.shadow_enabled = true
	add_child(fire_light)

	for i in range(3):
		var ember := MeshInstance3D.new()
		var ember_mesh := SphereMesh.new()
		ember_mesh.radius = 0.18 + i * 0.04
		ember_mesh.height = ember_mesh.radius * 2.0
		ember_mesh.radial_segments = 10
		ember_mesh.rings = 5
		ember.mesh = ember_mesh
		ember.position = Vector3(-2.2 + (i - 1) * 0.18, 0.20 + i * 0.08, 2.3)
		var ember_mat := StandardMaterial3D.new()
		ember_mat.albedo_color = Color(1.0, 0.26 + i * 0.12, 0.03, 1.0)
		ember_mat.emission_enabled = true
		ember_mat.emission = Color(1.0, 0.20 + i * 0.12, 0.02)
		ember_mat.emission_energy_multiplier = 3.0
		ember.material_override = ember_mat
		add_child(ember)

func _build_test_forest() -> void:
	for i in range(42):
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(10.0, 49.0)
		var position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if position.distance_to(Vector3(-14.0, 0.0, 12.0)) < 10.0:
			continue
		if position.length() < 10.0:
			continue
		_create_tree(position, _rng.randf_range(0.82, 1.35))

func _create_tree(position: Vector3, scale_factor: float) -> void:
	var tree := Node3D.new()
	tree.position = position
	tree.rotation_degrees.y = _rng.randf_range(0.0, 360.0)
	tree.scale = Vector3.ONE * scale_factor
	add_child(tree)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 2.7
	trunk_mesh.radial_segments = 9
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.35
	trunk.material_override = _material(Color(0.24, 0.13, 0.065), 0.98)
	tree.add_child(trunk)

	var crown_material := _material(Color(0.08 + _rng.randf_range(0.0, 0.025), 0.26 + _rng.randf_range(0.0, 0.05), 0.12), 0.88)
	for crown_data in [Vector4(0.0, 3.0, 0.0, 1.35), Vector4(-0.72, 2.72, 0.18, 0.92), Vector4(0.72, 2.78, -0.12, 0.96), Vector4(0.08, 3.85, 0.0, 0.95)]:
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = crown_data.w
		crown_mesh.height = crown_data.w * 2.0
		crown_mesh.radial_segments = 12
		crown_mesh.rings = 7
		crown.mesh = crown_mesh
		crown.position = Vector3(crown_data.x, crown_data.y, crown_data.z)
		crown.scale.y = 0.82
		crown.material_override = crown_material
		tree.add_child(crown)

	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.34
	shape.height = 2.7
	collider.shape = shape
	collider.position.y = 1.35
	body.add_child(collider)
	tree.add_child(body)

func _build_rocks() -> void:
	for i in range(26):
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = _rng.randf_range(0.28, 0.72)
		mesh.height = mesh.radius * 1.55
		mesh.radial_segments = 9
		mesh.rings = 5
		rock.mesh = mesh
		rock.position = Vector3(_rng.randf_range(-48.0, 48.0), mesh.radius * 0.45, _rng.randf_range(-48.0, 48.0))
		if rock.position.length() < 9.0:
			continue
		rock.scale = Vector3(_rng.randf_range(0.8, 1.4), _rng.randf_range(0.65, 1.0), _rng.randf_range(0.75, 1.25))
		rock.rotation_degrees = Vector3(_rng.randf_range(-12.0, 12.0), _rng.randf_range(0.0, 360.0), _rng.randf_range(-8.0, 8.0))
		rock.material_override = _material(Color(0.34, 0.37, 0.35), 0.92)
		add_child(rock)
