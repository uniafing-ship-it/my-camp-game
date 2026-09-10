extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal died()
signal respawned()
signal attacked(hit: bool)

@export var move_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var acceleration: float = 18.0
@export var gravity_force: float = 24.0
@export var look_sensitivity: float = 0.004
@export var auto_harvest_enabled: bool = true
@export var max_health: int = 100
@export var attack_damage: int = 24
@export var attack_range: float = 2.35
@export var attack_cooldown: float = 0.58
@export var invulnerability_time: float = 0.36
@export var respawn_delay: float = 2.5

@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot

var health: int = 0
var _joystick: Node = null
var _resource_manager = null
var _pitch := deg_to_rad(-17.0)
var _yaw := 0.0
var _attack_cd := 0.0
var _invulnerability := 0.0
var _attack_anim := 0.0
var _dead := false
var _spawn_position := Vector3.ZERO
var _sword_pivot: Node3D = null

func _ready() -> void:
	add_to_group("player_combat")
	_joystick = get_tree().get_first_node_in_group("mobile_joystick")
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	_yaw = rotation.y
	health = max_health
	_spawn_position = global_position
	_sword_pivot = get_node_or_null("Visual/SwordPivot")
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_invulnerability = maxf(0.0, _invulnerability - delta)
	_update_attack_visual(delta)
	if _dead:
		velocity = Vector3.ZERO
		return

	var input_vec := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_vec.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_vec.y += 1.0
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	if _joystick and _joystick.has_method("get_vector"):
		var mobile_vec: Vector2 = _joystick.get_vector()
		if mobile_vec.length() > input_vec.length():
			input_vec = mobile_vec

	var camera := get_viewport().get_camera_3d()
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	if camera:
		forward = -camera.global_transform.basis.z
		right = camera.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()

	var desired_dir := right * input_vec.x + forward * -input_vec.y
	if desired_dir.length_squared() > 1.0:
		desired_dir = desired_dir.normalized()

	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	var target_speed := sprint_speed if sprinting else move_speed
	var target_velocity := desired_dir * target_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity_force * delta
	else:
		velocity.y = -0.5

	if desired_dir.length_squared() > 0.02:
		var target_angle := atan2(desired_dir.x, desired_dir.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, minf(1.0, delta * 10.0))

	move_and_slide()
	_process_resource_gameplay()

func request_attack() -> bool:
	return perform_attack()

func perform_attack() -> bool:
	if _dead or _attack_cd > 0.0:
		return false
	_attack_cd = attack_cooldown
	_attack_anim = 0.22
	var nearest = null
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not (candidate is Node3D):
			continue
		if candidate.has_method("is_alive") and not bool(candidate.is_alive()):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	var hit := false
	if nearest != null and nearest.has_method("take_damage"):
		nearest.take_damage(attack_damage, global_position)
		hit = true
	attacked.emit(hit)
	return hit

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO) -> int:
	if _dead or amount <= 0 or _invulnerability > 0.0:
		return health
	_invulnerability = invulnerability_time
	health = maxi(0, health - amount)
	if source_position != Vector3.ZERO:
		var away := global_position - source_position
		away.y = 0.0
		if away.length_squared() > 0.01:
			away = away.normalized()
			velocity.x += away.x * 3.5
			velocity.z += away.z * 3.5
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()
	return health

func heal(amount: int) -> int:
	if amount <= 0 or _dead:
		return health
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)
	return health

func is_alive() -> bool:
	return not _dead and health > 0

func export_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"health": health,
		"yaw": _yaw,
		"pitch": _pitch,
	}

func import_state(data: Dictionary) -> void:
	var saved_position = data.get("position", [])
	if saved_position is Array and saved_position.size() >= 3:
		global_position = Vector3(float(saved_position[0]), float(saved_position[1]), float(saved_position[2]))
	_spawn_position = global_position
	health = clampi(int(data.get("health", max_health)), 1, max_health)
	_yaw = float(data.get("yaw", _yaw))
	_pitch = clamp(float(data.get("pitch", _pitch)), deg_to_rad(-48.0), deg_to_rad(18.0))
	_dead = false
	_invulnerability = 0.5
	camera_pivot.rotation = Vector3(_pitch, _yaw, 0.0)
	health_changed.emit(health, max_health)

func _die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector3.ZERO
	died.emit()
	await get_tree().create_timer(respawn_delay).timeout
	if not is_inside_tree():
		return
	global_position = _spawn_position
	health = max_health
	_dead = false
	_invulnerability = 1.0
	health_changed.emit(health, max_health)
	respawned.emit()

func _update_attack_visual(delta: float) -> void:
	if _sword_pivot == null:
		return
	if _attack_anim > 0.0:
		_attack_anim = maxf(0.0, _attack_anim - delta)
		var t := 1.0 - _attack_anim / 0.22
		_sword_pivot.rotation_degrees.z = -34.0 + sin(t * PI) * 88.0
	else:
		_sword_pivot.rotation_degrees.z = -34.0

func _process_resource_gameplay() -> void:
	if _resource_manager == null:
		_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if _resource_manager == null:
		return

	for warehouse in get_tree().get_nodes_in_group("warehouse"):
		if warehouse and warehouse.has_method("try_deposit"):
			warehouse.try_deposit(global_position, _resource_manager)

	if not auto_harvest_enabled:
		return
	if _resource_manager.has_method("get_free_capacity") and int(_resource_manager.get_free_capacity()) <= 0:
		return

	var nearest: Node3D = null
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("harvestables"):
		if not (candidate is Node3D):
			continue
		if candidate.has_method("is_depleted") and candidate.is_depleted():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		var radius := float(candidate.get("harvest_radius"))
		if distance <= radius and distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	if nearest and nearest.has_method("try_harvest"):
		nearest.try_harvest(_resource_manager)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_F:
			request_attack()
	elif event is InputEventScreenDrag:
		if event.position.x < get_viewport().get_visible_rect().size.x * 0.35:
			return
		_apply_look(event.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_apply_look(event.relative)

func _apply_look(relative: Vector2) -> void:
	_yaw -= relative.x * look_sensitivity
	_pitch = clamp(_pitch - relative.y * look_sensitivity, deg_to_rad(-48.0), deg_to_rad(18.0))
	camera_pivot.rotation = Vector3(_pitch, _yaw, 0.0)
