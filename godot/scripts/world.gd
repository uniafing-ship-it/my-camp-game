extends Node3D

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 20260906
	build_environment()
	build_ground()
	build_water()
	build_camp()
	build_forest()
	build_rocks()

func make_material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.31, 0.45, 0.35)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.66, 0.72, 0.64)
	environment.ambient_light_energy = 0.72
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.56, 0.65, 0.58)
	environment.fog_density = 0.008
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
	sun.light_color = Color(1.0, 0.89, 0.72)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 75.0
	add_child(sun)

func build_ground() -> void:
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(120.0, 120.0)
	ground_mesh.subdivide_width = 20
	ground_mesh.subdivide_depth = 20
	ground.mesh = ground_mesh
	ground.material_override = make_material(Color(0.19, 0.38, 0.21), 0.96)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

	var static_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(120.0, 0.3, 120.0)
	collision.shape = shape
	collision.position.y = -0.16
	static_body.add_child(collision)
	add_child(static_body)

	for i in range(55):
		var patch := MeshInstance3D.new()
		var patch_mesh := CylinderMesh.new()
		var radius := rng.randf_range(0.35, 1.15)
		patch_mesh.top_radius = radius
		patch_mesh.bottom_radius = radius
		patch_mesh.height = 0.012
		patch_mesh.radial_segments = 12
		patch.mesh = patch_mesh
		patch.position = Vector3(rng.randf_range(-52.0, 52.0), 0.008, rng.randf_range(-52.0, 52.0))
		patch.scale.z = rng.randf_range(0.55, 1.5)
		patch.material_override = make_material(Color(0.15 + rng.randf_range(0.0, 0.03), 0.31 + rng.randf_range(0.0, 0.05), 0.16), 1.0)
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(patch)

func build_water() -> void:
	var shore := MeshInstance3D.new()
	var shore_mesh := CylinderMesh.new()
	shore_mesh.top_radius = 8.8
	shore_mesh.bottom_radius = 8.8
	shore_mesh.height = 0.05
	shore_mesh.radial_segments = 48
	shore.mesh = shore_mesh
	shore.position = Vector3(-14.0, 0.02, 12.0)
	shore.scale.z = 0.72
	shore.material_override = make_material(Color(0.40, 0.31, 0.18), 1.0)
	shore.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shore)

	var water := MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(16.0, 11.0)
	water_mesh.subdivide_width = 32
	water_mesh.subdivide_depth = 24
	water.mesh = water_mesh
	water.position = Vector3(-14.0, 0.08, 12.0)
	water.scale.z = 0.82

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

void vertex() {
	VERTEX.y += sin((VERTEX.x + TIME * 1.5) * 0.8) * 0.06;
	VERTEX.y += cos((VERTEX.z - TIME) * 1.1) * 0.04;
}

void fragment() {
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	ALBEDO = mix(vec3(0.035, 0.18, 0.27), vec3(0.18, 0.56, 0.66), 0.48 + fresnel * 0.34);
	ROUGHNESS = 0.16;
	METALLIC = 0.08;
	ALPHA = 0.82;
}
"""
	var water_material := ShaderMaterial.new()
	water_material.shader = shader
	water.material_override = water_material
	add_child(water)

func build_camp() -> void:
	var camp_floor := MeshInstance3D.new()
	var camp_mesh := CylinderMesh.new()
	camp_mesh.top_radius = 6.2
	camp_mesh.bottom_radius = 6.2
	camp_mesh.height = 0.09
	camp_mesh.radial_segments = 40
	camp_floor.mesh = camp_mesh
	camp_floor.position.y = 0.045
	camp_floor.material_override = make_material(Color(0.40, 0.30, 0.18), 0.92)
	add_child(camp_floor)

	var hall := Node3D.new()
	hall.position = Vector3(0.0, 0.0, -1.0)
	add_child(hall)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(3.8, 2.1, 3.2)
	body.mesh = body_mesh
	body.position.y = 1.05
	body.material_override = make_material(Color(0.50, 0.34, 0.19), 0.82)
	hall.add_child(body)

	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(4.4, 0.45, 3.8)
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, 2.35, 0.0)
	roof.rotation_degrees.z = 0.0
	roof.material_override = make_material(Color(0.11, 0.18, 0.13), 0.78)
	hall.add_child(roof)

	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.85, 1.45, 0.12)
	door.mesh = door_mesh
	door.position = Vector3(0.0, 0.75, 1.64)
	door.material_override = make_material(Color(0.17, 0.10, 0.055), 0.92)
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
		post.material_override = make_material(Color(0.25, 0.15, 0.075), 0.95)
		add_child(post)

	var fire_light := OmniLight3D.new()
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
		ember.position = Vector3(-2.2 + float(i - 1) * 0.18, 0.20 + i * 0.08, 2.3)
		var ember_material := StandardMaterial3D.new()
		ember_material.albedo_color = Color(1.0, 0.26 + i * 0.12, 0.03, 1.0)
		ember_material.emission_enabled = true
		ember_material.emission = Color(1.0, 0.20 + i * 0.12, 0.02)
		ember_material.emission_energy_multiplier = 3.0
		ember.material_override = ember_material
		add_child(ember)

func build_forest() -> void:
	for i in range(42):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(10.0, 49.0)
		var tree_position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if tree_position.distance_to(Vector3(-14.0, 0.0, 12.0)) < 10.0:
			continue
		if tree_position.length() < 10.0:
			continue
		create_tree(tree_position, rng.randf_range(0.82, 1.35))

func create_tree(tree_position: Vector3, scale_factor: float) -> void:
	var tree := Node3D.new()
	tree.position = tree_position
	tree.rotation_degrees.y = rng.randf_range(0.0, 360.0)
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
	trunk.material_override = make_material(Color(0.24, 0.13, 0.065), 0.98)
	tree.add_child(trunk)

	var crown_material := make_material(Color(0.08 + rng.randf_range(0.0, 0.025), 0.26 + rng.randf_range(0.0, 0.05), 0.12), 0.88)
	var crown_data := [
		Vector4(0.0, 3.0, 0.0, 1.35),
		Vector4(-0.72, 2.72, 0.18, 0.92),
		Vector4(0.72, 2.78, -0.12, 0.96),
		Vector4(0.08, 3.85, 0.0, 0.95)
	]
	for data in crown_data:
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
		tree.add_child(crown)

	var trunk_body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.34
	trunk_shape.height = 2.7
	collider.shape = trunk_shape
	collider.position.y = 1.35
	trunk_body.add_child(collider)
	tree.add_child(trunk_body)

func build_rocks() -> void:
	for i in range(24):
		var radius := rng.randf_range(0.28, 0.72)
		var rock_position := Vector3(rng.randf_range(-48.0, 48.0), radius * 0.45, rng.randf_range(-48.0, 48.0))
		if rock_position.length() < 9.0:
			continue
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = radius
		rock_mesh.height = radius * 1.55
		rock_mesh.radial_segments = 9
		rock_mesh.rings = 5
		rock.mesh = rock_mesh
		rock.position = rock_position
		rock.scale = Vector3(rng.randf_range(0.8, 1.4), rng.randf_range(0.65, 1.0), rng.randf_range(0.75, 1.25))
		rock.rotation_degrees = Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(0.0, 360.0), rng.randf_range(-8.0, 8.0))
		rock.material_override = make_material(Color(0.34, 0.37, 0.35), 0.92)
		add_child(rock)
