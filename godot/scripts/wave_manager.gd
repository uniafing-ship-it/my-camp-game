extends Node3D
class_name WaveManager

signal wave_started(number: int, enemy_count: int)
signal wave_ended(number: int)
signal timer_changed(seconds_to_next: float, is_night: bool, night_seconds_left: float)
signal camp_health_changed(current: int, maximum: int)
signal game_over()

const EnemyScript = preload("res://scripts/enemy.gd")

@export var first_night_delay: float = 180.0
@export var wave_interval: float = 90.0
@export var night_duration: float = 35.0
@export var base_enemy_count: int = 3
@export var enemies_per_wave: int = 2
@export var spawn_radius: float = 30.0
@export var camp_max_health: int = 300
@export var simulation_enabled: bool = true

var wave_number: int = 0
var next_wave_in: float = 0.0
var night_seconds_left: float = 0.0
var camp_health: int = 0
var is_night: bool = false
var is_game_over: bool = false
var _rng := RandomNumberGenerator.new()
var _last_timer_second := -1

func _ready() -> void:
	add_to_group("raid_manager")
	_rng.seed = 2026091004
	next_wave_in = first_night_delay
	camp_health = camp_max_health
	camp_health_changed.emit(camp_health, camp_max_health)
	_emit_timer(true)

func _process(delta: float) -> void:
	if not simulation_enabled or is_game_over:
		return
	next_wave_in = maxf(0.0, next_wave_in - delta)
	if is_night:
		night_seconds_left = maxf(0.0, night_seconds_left - delta)
		if night_seconds_left <= 0.0:
			_end_night()
	if next_wave_in <= 0.0:
		_start_night()
	_emit_timer(false)

func start_wave_now() -> void:
	if is_game_over:
		return
	_start_night()

func damage_camp(amount: int) -> int:
	if amount <= 0 or is_game_over:
		return camp_health
	camp_health = maxi(0, camp_health - amount)
	camp_health_changed.emit(camp_health, camp_max_health)
	if camp_health <= 0:
		is_game_over = true
		_set_world_night(false)
		game_over.emit()
	return camp_health

func repair_camp(amount: int) -> int:
	if amount <= 0:
		return camp_health
	camp_health = mini(camp_max_health, camp_health + amount)
	camp_health_changed.emit(camp_health, camp_max_health)
	return camp_health

func get_enemy_count_for_wave(number: int) -> int:
	return base_enemy_count + maxi(0, number - 1) * enemies_per_wave

func get_status_text() -> String:
	if is_game_over:
		return "ЛАГЕРЬ РАЗРУШЕН"
	if is_night:
		return "НОЧЬ · ВОЛНА %d · %dс" % [wave_number, int(ceil(night_seconds_left))]
	return "ДО НОЧИ %dс" % int(ceil(next_wave_in))

func _start_night() -> void:
	wave_number += 1
	is_night = true
	night_seconds_left = night_duration
	next_wave_in = wave_interval
	_set_world_night(true)
	var count := get_enemy_count_for_wave(wave_number)
	_spawn_enemies(count)
	wave_started.emit(wave_number, count)
	_emit_timer(true)

func _end_night() -> void:
	if not is_night:
		return
	is_night = false
	night_seconds_left = 0.0
	_set_world_night(false)
	wave_ended.emit(wave_number)
	_emit_timer(true)

func _spawn_enemies(count: int) -> void:
	for i in range(count):
		var enemy = EnemyScript.new()
		enemy.name = "Raider_%d_%d" % [wave_number, i + 1]
		var angle := TAU * float(i) / maxf(1.0, float(count)) + _rng.randf_range(-0.22, 0.22)
		var radius := spawn_radius + _rng.randf_range(-3.0, 3.0)
		enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		enemy.max_health = 52 + (wave_number - 1) * 9
		enemy.attack_damage = 10 + int((wave_number - 1) * 1.5)
		enemy.move_speed = minf(4.5, 2.8 + float(wave_number - 1) * 0.08)
		enemy.reward_gold = 1
		add_child(enemy)

func _set_world_night(enabled: bool) -> void:
	var root_scene := get_tree().current_scene
	if root_scene == null:
		return
	for child in root_scene.get_children():
		if child is WorldEnvironment:
			var env := (child as WorldEnvironment).environment
			if env != null:
				if enabled:
					env.background_color = Color(0.035, 0.055, 0.085)
					env.ambient_light_color = Color(0.16, 0.22, 0.32)
					env.ambient_light_energy = 0.42
					env.fog_light_color = Color(0.10, 0.16, 0.24)
				else:
					env.background_color = Color(0.31, 0.45, 0.35)
					env.ambient_light_color = Color(0.66, 0.72, 0.64)
					env.ambient_light_energy = 0.72
					env.fog_light_color = Color(0.56, 0.65, 0.58)
		elif child is DirectionalLight3D:
			var sun := child as DirectionalLight3D
			if enabled:
				sun.light_color = Color(0.42, 0.50, 0.72)
				sun.light_energy = 0.48
			else:
				sun.light_color = Color(1.0, 0.89, 0.72)
				sun.light_energy = 1.35

func _emit_timer(force: bool) -> void:
	var second := int(ceil(night_seconds_left if is_night else next_wave_in))
	if force or second != _last_timer_second:
		_last_timer_second = second
		timer_changed.emit(next_wave_in, is_night, night_seconds_left)

func reset_for_test() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	wave_number = 0
	next_wave_in = first_night_delay
	night_seconds_left = 0.0
	camp_health = camp_max_health
	is_night = false
	is_game_over = false
	_last_timer_second = -1
	camp_health_changed.emit(camp_health, camp_max_health)
	_emit_timer(true)
