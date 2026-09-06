extends CharacterBody3D

@export var move_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var acceleration: float = 18.0
@export var gravity_force: float = 24.0
@export var look_sensitivity: float = 0.004

@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot

var _joystick: Node = null
var _pitch := deg_to_rad(-17.0)
var _yaw := 0.0

func _ready() -> void:
	_joystick = get_tree().get_first_node_in_group("mobile_joystick")
	_yaw = rotation.y

func _physics_process(delta: float) -> void:
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
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, min(1.0, delta * 10.0))

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if event.position.x < get_viewport().get_visible_rect().size.x * 0.35:
			return
		_apply_look(event.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_apply_look(event.relative)

func _apply_look(relative: Vector2) -> void:
	_yaw -= relative.x * look_sensitivity
	_pitch = clamp(_pitch - relative.y * look_sensitivity, deg_to_rad(-48.0), deg_to_rad(18.0))
	camera_pivot.rotation = Vector3(_pitch, _yaw, 0.0)
