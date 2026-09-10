extends SceneTree

const PlayerScene = preload("res://scenes/player/Player.tscn")
const EnemyScript = preload("res://scripts/enemy.gd")
const WaveManagerScript = preload("res://scripts/wave_manager.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var player = PlayerScene.instantiate()
	player.position = Vector3.ZERO
	player.respawn_delay = 0.01
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	_expect(player.health == 100, "player starts with full health")
	_expect(player.take_damage(25) == 75, "player receives combat damage")
	_expect(player.is_alive(), "player remains alive above zero health")

	var enemy = EnemyScript.new()
	enemy.max_health = 30
	enemy.reward_gold = 0
	enemy.position = Vector3(0.0, 0.0, 1.2)
	root.add_child(enemy)
	await process_frame
	enemy.set_physics_process(false)
	_expect(enemy.health == 30, "enemy starts with configured health")
	_expect(player.perform_attack(), "sword attack hits enemy in melee range")
	_expect(enemy.health == 6, "sword attack applies configured damage")
	enemy.take_damage(6)
	await process_frame
	_expect(not is_instance_valid(enemy), "enemy is removed after lethal damage")

	var waves = WaveManagerScript.new()
	waves.simulation_enabled = false
	root.add_child(waves)
	await process_frame
	_expect(is_equal_approx(waves.first_night_delay, 180.0), "first night starts after 3 minutes")
	_expect(is_equal_approx(waves.wave_interval, 90.0), "later night starts are 90 seconds apart")
	_expect(waves.get_enemy_count_for_wave(1) == 3, "first wave contains three enemies")
	_expect(waves.get_enemy_count_for_wave(2) == 5, "wave difficulty scales enemy count")
	_expect(waves.camp_health == 300, "camp starts at full combat health")
	_expect(waves.damage_camp(35) == 265, "enemy damage reduces camp health")
	waves.start_wave_now()
	await process_frame
	_expect(waves.wave_number == 1 and waves.is_night, "manual wave start enters night state")
	_expect(is_equal_approx(waves.next_wave_in, 90.0), "next night timer resets to 90 seconds")
	_expect(get_nodes_in_group("enemies").size() == 3, "wave manager spawns expected enemy count")

	for spawned in get_nodes_in_group("enemies"):
		if is_instance_valid(spawned):
			spawned.queue_free()
	await process_frame

	if failures == 0:
		print("STAGE4_COMBAT_TESTS_OK")
		quit(0)
	else:
		push_error("Stage 4 combat tests failed: %d" % failures)
		quit(1)
