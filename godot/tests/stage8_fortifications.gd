extends SceneTree

const EnemyScript = preload("res://scripts/enemy.gd")
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
	var units = main.get_node_or_null("UnitManager")
	var wave = main.get_node_or_null("WaveManager")
	var defenses = main.get_node_or_null("FortificationsWorld")
	var defense_hud = main.get_node_or_null("UI/FortificationsHUD")
	var saver = main.get_node_or_null("SaveManager")

	_expect(resources != null, "resource manager present")
	_expect(settlement != null, "settlement manager present")
	_expect(progression != null, "progression manager present")
	_expect(units != null, "unit manager present")
	_expect(defenses != null, "fortifications world present")
	_expect(defense_hud != null, "fortifications mobile drawer present")
	if resources == null or settlement == null or progression == null or units == null or defenses == null:
		quit(1)
		return

	if saver != null:
		saver.delete_save()
	if wave != null:
		wave.simulation_enabled = false
		wave.reset_for_test()
	settlement.reset_for_test()
	progression.reset_for_test()
	units.reset_for_test()
	await process_frame
	for key in resources.RESOURCE_TYPES:
		resources.stored[key] = 10000

	_expect(settlement.get_build_cost("stone_wall") == {"wood":60,"stone":40}, "stone wall keeps legacy build cost")
	_expect(settlement.get_build_cost("watchtower") == {"wood":90,"stone":70}, "watchtower keeps legacy build cost")
	_expect(settlement.get_build_cost("cannon") == {"stone":150,"gold":40}, "cannon keeps legacy build cost")
	_expect(settlement.get_build_cost("barracks") == {"wood":200,"stone":150,"food":100}, "barracks keeps legacy build cost")
	_expect(settlement.get_build_cost("infirmary") == {"stone":200,"food":100,"gold":60}, "infirmary keeps legacy build cost")
	_expect(settlement.get_build_cost("training_ground") == {"wood":250,"stone":200,"gold":80}, "training ground keeps legacy build cost")

	for building_id in ["stone_wall","watchtower","cannon","barracks","infirmary","training_ground"]:
		_expect(settlement.build(building_id), "%s can be constructed" % building_id)
	await process_frame
	await process_frame
	_expect(get_nodes_in_group("fortifications_world").size() == 1, "single fortifications renderer owns advanced structures")
	_expect(settlement.get_upgrade_cost("watchtower") == {"gold":74,"wood":23,"stone":18}, "watchtower level-2 price follows legacy upgrade curve")
	_expect(settlement.upgrade("watchtower"), "watchtower can be upgraded")
	_expect(settlement.get_building_level("watchtower") == 2, "watchtower reaches level 2")

	var research_by_id: Dictionary = {}
	for item in progression.get_research_snapshot():
		research_by_id[str(item.get("id",""))] = item
	_expect(research_by_id.has("arrows"), "Elven Arrows research is exposed")
	_expect(research_by_id.has("walls"), "Stone Masonry research is exposed")
	_expect((research_by_id.get("armor",{}).get("cost",{}) as Dictionary) == {"gold":40,"stone":120}, "armor research cost matches legacy source")
	_expect(progression.research("armor"), "armor research can be purchased")
	_expect(progression.research("arrows"), "Elven Arrows research can be purchased")
	_expect(progression.research("walls"), "Stone Masonry research can be purchased")
	_expect(defenses.get_wall_slow_factor() <= 0.50, "wall research strengthens slowdown")
	_expect(defenses.get_watchtower_damage() > 0, "watchtower damage is active")
	_expect(defenses.get_cannon_damage() > defenses.get_watchtower_damage(), "cannon hit is stronger than watchtower hit")

	_expect(units.get_capacity("foot") == 16, "level-1 barracks adds four warrior slots")
	_expect(units.recruit("foot"), "warrior can be recruited with Stage 8 infrastructure")
	await process_frame
	var foot = null
	for defender in get_nodes_in_group("camp_defenders"):
		if str(defender.unit_kind) == "foot":
			foot = defender
			break
	_expect(foot != null, "3D warrior actor exists")
	if foot != null:
		_expect(int(foot.max_health) == 53, "infirmary and armor add five HP to warrior")
		_expect(int(foot.attack_damage) > 12, "training ground increases warrior damage")
		_expect(float(foot.attack_interval) < 0.82, "training ground increases warrior attack tempo")

	var enemy = EnemyScript.new()
	enemy.max_health = 240
	enemy.position = Vector3(0,0,-11.5)
	main.add_child(enemy)
	await process_frame
	_expect(absf(float(enemy.get_fortification_speed_multiplier()) - 0.50) < 0.001, "raider inside wall radius receives legacy level-1 wall slowdown plus masonry")
	var before_hp := int(enemy.health)
	var fired := int(defenses.fire_defenses_once_for_test())
	_expect(fired >= 1, "automated fortifications acquire a nearby raider")
	_expect(int(enemy.health) < before_hp, "automated fortifications damage raider")

	if saver != null:
		await process_frame
		await process_frame
		_expect(saver.save_game(), "Stage 8 state saves")
		settlement.reset_for_test()
		progression.reset_for_test()
		units.reset_for_test()
		await process_frame
		_expect(settlement.get_building_level("watchtower") == 0, "fortification state resets before load")
		_expect(saver.load_game(), "Stage 8 state loads")
		await process_frame
		await process_frame
		_expect(settlement.get_building_level("watchtower") == 2, "fortification level restores from save")
		_expect(progression.has_research("walls"), "fortification research restores from save")
		_expect(units.get_capacity("foot") == 16, "barracks capacity restores from save")
		saver.delete_save()

	if failures == 0:
		print("STAGE8_FORTIFICATION_TESTS_OK")
		quit(0)
	else:
		push_error("Stage 8 fortification tests failed: %d" % failures)
		quit(1)
