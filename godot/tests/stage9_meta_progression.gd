extends SceneTree

var failures := 0
var _finished := false

func _init() -> void:
	var watchdog := create_timer(45.0)
	watchdog.timeout.connect(_on_watchdog)
	call_deferred("_run")

func _on_watchdog() -> void:
	if _finished:
		return
	push_error("Stage 9 meta progression tests timed out")
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _finish(code: int) -> void:
	_finished = true
	quit(code)

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	_expect(packed != null, "main scene loads")
	if packed == null:
		_finish(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var resources = main.get_node_or_null("ResourceManager")
	var settlement = main.get_node_or_null("SettlementManager")
	var progression = main.get_node_or_null("ProgressionManager")
	var meta = main.get_node_or_null("MetaProgressionManager")
	var units = main.get_node_or_null("UnitManager")
	var wave = main.get_node_or_null("WaveManager")
	var saver = main.get_node_or_null("SaveManager")
	var meta_hud = main.get_node_or_null("UI/MetaProgressionHUD")

	_expect(resources != null, "resource manager present")
	_expect(settlement != null, "settlement manager present")
	_expect(progression != null, "progression manager present")
	_expect(meta != null, "meta progression manager present")
	_expect(units != null, "unit manager present")
	_expect(meta_hud != null, "meta progression mobile drawer present")
	if resources == null or settlement == null or progression == null or meta == null or units == null:
		_finish(1)
		return

	if saver != null:
		saver.set_process(false)
		saver.delete_save()
	if wave != null:
		wave.simulation_enabled = false
		wave.reset_for_test()
	resources.reset_for_test()
	settlement.reset_for_test()
	progression.reset_for_test()
	units.reset_for_test()
	meta.reset_for_test()
	await process_frame
	await process_frame

	for key in resources.RESOURCE_TYPES:
		resources.stored[key] = 100000

	# Stage 9 preserves the legacy three expedition templates and durations.
	var exp_snapshot: Dictionary = meta.get_expedition_snapshot()
	var definitions: Dictionary = {}
	for item in exp_snapshot.get("definitions", []):
		definitions[str(item.get("id", ""))] = item
	_expect(definitions.has("scout") and int(float(definitions["scout"].get("duration", 0))) == 60, "scout expedition keeps 60 second legacy duration")
	_expect(definitions.has("supplies") and int(float(definitions["supplies"].get("duration", 0))) == 90, "supply expedition keeps 90 second legacy duration")
	_expect(definitions.has("ruins") and int(float(definitions["ruins"].get("duration", 0))) == 150, "ruins expedition keeps 150 second legacy duration")

	for building_id in settlement.BUILD_COSTS.keys():
		_expect(settlement.build(str(building_id)), "%s can be built for Stage 9 setup" % str(building_id))
	await process_frame
	await process_frame
	_expect(meta.get_built_count() == 12, "town hall plus eleven migrated buildings satisfy current 12-object ascension gate")

	_expect(settlement.recruit_worker(), "first expedition worker recruited")
	_expect(settlement.recruit_worker(), "second expedition worker recruited")
	_expect(units.recruit("foot"), "first expedition fighter recruited")
	_expect(units.recruit("foot"), "second expedition fighter recruited")
	_expect(units.recruit("foot"), "third expedition fighter recruited")
	await process_frame
	await process_frame
	_expect(get_nodes_in_group("camp_workers").size() >= 2, "worker actors exist before expedition")
	_expect(get_nodes_in_group("camp_defenders").size() >= 3, "defender actors exist before expedition")

	var gold_before := int(resources.stored.get("gold", 0))
	_expect(meta.start_expedition("scout"), "scout expedition can start with two free fighters")
	await process_frame
	_expect(get_nodes_in_group("expedition_reserved_units").size() == 2, "two fighters leave active defense while scouting")
	var expedition_reward: Dictionary = meta.complete_expedition_for_test(0)
	await process_frame
	_expect(not expedition_reward.is_empty(), "completed expedition returns a reward")
	_expect(int(resources.stored.get("gold", 0)) > gold_before, "scout expedition returns gold")
	_expect(get_nodes_in_group("expedition_reserved_units").is_empty(), "fighters return to camp after expedition")
	_expect(meta.expedition_count == 1, "completed expedition counter advances")

	_expect(meta.start_expedition("supplies"), "supply expedition can start with two workers")
	await process_frame
	_expect(get_nodes_in_group("expedition_reserved_workers").size() == 2, "two workers leave gathering while expedition is active")
	meta.complete_expedition_for_test(0)
	await process_frame
	_expect(get_nodes_in_group("expedition_reserved_workers").is_empty(), "workers return to gathering after expedition")

	var base_capacity := int(resources.carry_capacity)
	_expect(meta.grant_relic("pouch") == "pouch", "Pouch of Holding can be granted")
	_expect(resources.get_effective_carry_capacity() == base_capacity + 6, "Pouch of Holding adds six carry slots")
	_expect(meta.grant_relic("sickle") == "sickle", "Golden Sickle can be granted")
	_expect(meta.get_harvest_bonus() == 1, "Golden Sickle adds one gathering unit")
	_expect(meta.grant_relic("orb") == "orb", "Golden Orb can be granted")
	_expect(meta.get_gold_kill_multiplier() == 2, "Golden Orb doubles kill gold")
	var defender = get_nodes_in_group("camp_defenders")[0] if not get_nodes_in_group("camp_defenders").is_empty() else null
	var damage_before := int(defender.attack_damage) if defender != null else 0
	_expect(meta.grant_relic("banner") == "banner", "War Banner can be granted")
	await process_frame
	if defender != null and is_instance_valid(defender):
		_expect(int(defender.attack_damage) >= damage_before + 1, "War Banner increases defender damage")

	progression.gathered["wood"] = 100
	var achievement_gold_before := int(resources.stored.get("gold", 0))
	meta.check_achievements_for_test()
	_expect(meta.achievements.has("wood1"), "First Forest achievement unlocks at 100 wood")
	_expect(int(resources.stored.get("gold", 0)) >= achievement_gold_before + 20, "First Forest achievement pays legacy 20 gold")

	var xp_needed := int(meta.get_hero_xp_needed())
	meta.add_hero_xp(xp_needed)
	_expect(meta.hero_level == 2, "hero XP advances hero level")

	_expect(meta.can_ascend(), "fully built current camp can ascend")
	var expected_fame := int(meta.get_fame_gain())
	var achievements_before: Array = meta.achievements.duplicate()
	_expect(expected_fame > 0, "ascension produces positive fame")
	_expect(meta.ascend(), "ascension succeeds")
	await process_frame
	await process_frame
	_expect(meta.fame == expected_fame, "ascension stores earned fame")
	_expect(meta.relics.is_empty(), "ascension resets relics like legacy game")
	_expect(settlement.get_building_level("town_hall") == 1 and settlement.get_building_level("watchtower") == 0, "ascension resets camp but retains base town hall")
	_expect(meta.achievements.size() >= achievements_before.size(), "earned achievements survive ascension")
	_expect(meta.achievements.has("fame1"), "first ascension unlocks Eternal Flame achievement")
	_expect(absf(meta.get_production_multiplier() - (1.0 + 0.08 * float(meta.fame))) < 0.001, "fame grants legacy eight percent production per point")
	_expect(absf(meta.get_damage_multiplier() - (1.0 + 0.04 * float(meta.fame))) < 0.001, "fame grants legacy four percent damage per point")

	if saver != null:
		meta.grant_relic("orb")
		meta.add_hero_xp(meta.get_hero_xp_needed())
		var saved_fame := int(meta.fame)
		var saved_level := int(meta.hero_level)
		_expect(saver.save_game(), "Stage 9 meta state saves")
		meta.reset_for_test()
		_expect(meta.fame == 0 and meta.relics.is_empty(), "meta state resets before load")
		_expect(saver.load_game(), "Stage 9 meta state loads through backward-compatible save version")
		await process_frame
		await process_frame
		_expect(meta.fame == saved_fame, "fame restores from save")
		_expect(meta.hero_level == saved_level, "hero meta level restores from save")
		_expect(meta.has_relic("orb"), "relic collection restores from save")
		saver.delete_save()

	if failures == 0:
		print("STAGE9_META_PROGRESSION_TESTS_OK")
		_finish(0)
	else:
		push_error("Stage 9 meta progression tests failed: %d" % failures)
		_finish(1)
