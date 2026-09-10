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
	var units = main.get_node_or_null("UnitManager")
	var wildlife = main.get_node_or_null("WildlifeManager")
	var saver = main.get_node_or_null("SaveManager")
	var unit_hud = main.get_node_or_null("UI/UnitHUD")

	_expect(resources != null, "resource manager present")
	_expect(settlement != null, "settlement manager present")
	_expect(progression != null, "progression manager present")
	_expect(units != null, "unit manager present")
	_expect(wildlife != null, "wildlife manager present")
	_expect(unit_hud != null, "squad mobile drawer present")
	_expect(resources.stored.has("pelts"), "pelts are a real resource")

	if resources != null and settlement != null and units != null:
		for key in resources.RESOURCE_TYPES:
			resources.stored[key] = 1000
		_expect(settlement.build("hunting_lodge"), "hunting lodge can be built")
		_expect(settlement.build("kennel"), "kennel can be built")
		_expect(units.get_capacity("hunter") == 3, "hunting lodge opens legacy hunter capacity")
		_expect(units.get_capacity("dog") == 5, "kennel opens legacy dog capacity")
		_expect(units.recruit("foot"), "foot soldier can be recruited")
		_expect(units.recruit("hunter"), "hunter can be recruited")
		_expect(units.recruit("dog"), "dog can be recruited using pelts")
		await process_frame
		_expect(units.get_count("foot") == 1, "foot soldier count updates")
		_expect(units.get_count("hunter") == 1, "hunter count updates")
		_expect(units.get_count("dog") == 1, "dog count updates")
		_expect(get_nodes_in_group("camp_defenders").size() >= 3, "3D defender actors exist")

	if progression != null and resources != null:
		resources.stored["gold"] = 500
		resources.stored["pelts"] = 20
		_expect(progression.research("armor"), "chainmail research can be purchased")
		_expect(progression.get_unit_hp_bonus() == 3, "chainmail gives +3 unit HP")
		_expect(progression.research("hounds"), "war hounds research can be purchased")
		_expect(progression.get_dog_damage_bonus() == 2, "war hounds gives +2 dog damage")

	if wildlife != null and progression != null and resources != null:
		var before_food := int(resources.stored.get("food", 0))
		var bear = wildlife.spawn_for_test("bear")
		_expect(bear != null, "bear can spawn")
		if bear != null:
			bear.take_damage(999, Vector3.ZERO)
			await process_frame
			await process_frame
		_expect(int(progression.animal_kills.get("bear", 0)) >= 1, "bear kill is tracked")
		_expect(int(resources.stored.get("food", 0)) > before_food, "wildlife kill yields food")
		var carcasses := get_nodes_in_group("carcasses")
		_expect(carcasses.size() >= 1, "wildlife kill creates carcass")
		if carcasses.size() > 0:
			var carcass = carcasses[carcasses.size() - 1]
			carcass._finish_skinning()
			await process_frame
			_expect(progression.carcasses_skinned >= 1, "carcass skinning is tracked")

	if saver != null and units != null:
		saver.delete_save()
		_expect(saver.save_game(), "Stage 7 state saves with units")
		var saved_foot: int = int(units.get_count("foot"))
		units.reset_for_test()
		_expect(units.get_count("foot") == 0, "unit state can reset before load")
		_expect(saver.load_game(), "Stage 7 state loads")
		await process_frame
		_expect(units.get_count("foot") == saved_foot, "unit counts restore from save")
		saver.delete_save()

	if failures == 0:
		print("STAGE7_UNITS_WILDLIFE_TESTS_OK")
		quit(0)
	else:
		push_error("Stage 7 unit/wildlife tests failed: %d" % failures)
		quit(1)
