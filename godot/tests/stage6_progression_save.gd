extends SceneTree

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
	var packed := load("res://scenes/Main.tscn") as PackedScene
	_expect(packed != null, "main scene loads")
	if packed == null:
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var resources = main.get_node_or_null("ResourceManager")
	var settlement = main.get_node_or_null("SettlementManager")
	var progression = main.get_node_or_null("ProgressionManager")
	var save_manager = main.get_node_or_null("SaveManager")
	var wave = main.get_node_or_null("WaveManager")
	var player = main.get_node_or_null("Player")
	var progression_hud = main.get_node_or_null("UI/ProgressionHUD")

	_expect(resources != null, "resource manager present")
	_expect(settlement != null, "settlement manager present")
	_expect(progression != null, "progression manager present")
	_expect(save_manager != null, "save manager present")
	_expect(wave != null, "wave manager present")
	_expect(player != null, "player present")
	_expect(progression_hud != null, "progression mobile drawer present")

	if save_manager != null:
		save_manager.delete_save()

	if resources != null and progression != null:
		resources.stored["wood"] = 300
		resources.stored["gold"] = 100
		_expect(progression.research("axes"), "axes research can be purchased")
		_expect(int(progression.get_harvest_bonus("wood")) == 1, "axes research adds +1 harvesting")
		_expect(progression.research("bags"), "bags research can be purchased")
		_expect(int(resources.carry_capacity) == 36, "bags research raises carry capacity to 36")

	if progression != null and resources != null:
		progression.gathered["wood"] = 30
		progression._update_quest()
		_expect(int(progression.quest_index) >= 1, "first legacy quest auto-completes at 30 wood")
		_expect(int(resources.stored.get("food", 0)) >= 10, "quest reward is deposited to storage")

	if resources != null and settlement != null and progression != null and save_manager != null and wave != null and player != null:
		resources.stored["stone"] = 77
		settlement.buildings["lumber_camp"] = 2
		settlement.worker_count = 2
		progression.kills = 4
		wave.wave_number = 3
		wave.next_wave_in = 44.0
		wave.camp_health = 211
		player.global_position = Vector3(4.0, 0.0, 9.0)
		player.health = 67
		_expect(save_manager.save_game(), "manual save writes Godot user save")

		resources.stored["stone"] = 0
		settlement.buildings["lumber_camp"] = 0
		settlement.worker_count = 0
		progression.kills = 0
		wave.wave_number = 0
		wave.next_wave_in = 180.0
		wave.camp_health = 300
		player.global_position = Vector3.ZERO
		player.health = 100

		_expect(save_manager.load_game(), "saved state loads")
		await process_frame
		_expect(int(resources.stored.get("stone", 0)) == 77, "stored resources restore")
		_expect(int(settlement.get_building_level("lumber_camp")) == 2, "building levels restore")
		_expect(int(settlement.worker_count) == 2, "worker count restores")
		_expect(int(progression.kills) == 4, "progression statistics restore")
		_expect(int(wave.wave_number) == 3, "wave number restores")
		_expect(int(wave.camp_health) == 211, "camp health restores")
		_expect(player.global_position.distance_to(Vector3(4.0, 0.0, 9.0)) < 0.05, "player position restores")
		_expect(int(player.health) == 67, "player health restores")

	if save_manager != null:
		save_manager.delete_save()

	if failures == 0:
		print("STAGE6_PROGRESSION_SAVE_TESTS_OK")
		quit(0)
	else:
		push_error("Stage 6 progression/save tests failed: %d" % failures)
		quit(1)
