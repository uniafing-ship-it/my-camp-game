extends Control

@export var radius: float = 72.0
@export var knob_radius: float = 27.0

var _touch_id := -1
var _vector := Vector2.ZERO
var _center := Vector2.ZERO

func _ready() -> void:
	add_to_group("mobile_joystick")
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	_center = size * 0.5
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		queue_redraw()

func get_vector() -> Vector2:
	return _vector

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_update_vector(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_vector = Vector2.ZERO
			queue_redraw()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_vector(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_id = -2
			_update_vector(event.position)
		else:
			_touch_id = -1
			_vector = Vector2.ZERO
			queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and _touch_id == -2:
		_update_vector(event.position)
		accept_event()

func _update_vector(local_position: Vector2) -> void:
	var delta := local_position - _center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	_vector = delta / radius
	queue_redraw()

func _draw() -> void:
	draw_circle(_center, radius, Color(0.04, 0.07, 0.055, 0.42))
	draw_arc(_center, radius, 0.0, TAU, 64, Color(0.86, 0.73, 0.39, 0.56), 2.0, true)
	var knob_position := _center + _vector * radius
	draw_circle(knob_position, knob_radius, Color(0.86, 0.73, 0.39, 0.72))
	draw_arc(knob_position, knob_radius, 0.0, TAU, 40, Color(1.0, 0.91, 0.64, 0.88), 2.0, true)
