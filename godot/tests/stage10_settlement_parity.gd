extends SceneTree

const ResourceManagerScript = preload("res://scripts/resource_manager.gd")
const SettlementManagerScript = preload("res://scripts/settlement_manager.gd")
const ProgressionManagerScript = preload("res://scripts/progression_manager.gd")
const WaveManagerScript = preload("res://scripts/wave_manager.gd")
const Stage10Script = preload("res://scripts/stage10_settlement_parity.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node.new()
	root.add_child(root_node)

	var resources = ResourceManagerScript.new()
	root_node.add_child(resources)
	var settlement = SettlementManagerScript.new()
	root_node.add_child(settlement)
	var progression = ProgressionManagerScript.new()
	root_node.add_child(progression)
	var wave = WaveManagerScript.new()
	wave.simulation_enabled = false
	root_node.add_child(wave)
	var parity = Stage10Script.new()
	root_node.add_child(parity)
	await process_frame
	await process_frame

	resources.reset_for_test()
	settlement.worker_count = 0
	progression.reset_for_test()
	parity.reset_for_test()
	for resource_type in ["wood","stone","food","gold","pelts"]:
		resources.stored[resource_type] = 100000

	_check(parity.BUILDING_ORDER.size() == 7, "Stage 10 must contain exactly seven missing legacy buildings")
	_check(parity.get_build_cost("house") == {"wood":30}, "house cost must match legacy build")
	_check(parity.get_build_cost("gold_mine") == {"wood":80,"stone":60,"food":30}, "gold mine cost must match legacy build")
	_check(parity.get_build_cost("farm") == {"wood":180,"stone":120,"gold":40}, "farm cost must match legacy build")

	_check(parity.build("house"), "house should build when resources are available")
	_check(parity.get_hero_carry_bonus() == 10, "level 1 house must add +10 hero carry")
	_check(resources.get_effective_carry_capacity() >= 40, "resource manager must include Stage 10 house carry bonus")
	_check(parity.upgrade("house"), "house should upgrade")
	_check(parity.get_hero_carry_bonus() == 16, "level 2 house must add legacy +6 carry upgrade")

	_check(parity.build("forge"), "forge should build")
	_check(parity.build("workshop"), "workshop should build")
	_check(parity.get_worker_harvest_bonus() == 1, "forge level must become worker harvest bonus")
	_check(is_equal_approx(parity.get_worker_speed_multiplier(), 1.1), "workshop level must add 10 percent worker speed")
	_check(parity.get_worker_carry_bonus() == 2, "workshop level must add +2 worker carry")

	for id in ["gold_mine","residential_house","big_house","farm"]:
		_check(parity.build(id), "%s should build" % id)
	_check(parity.get_building_level("farm") == 1, "farm level should persist in manager state")

	for id in parity.LEGACY_COUNT_IDS:
		settlement.buildings[id] = 1
	var tier: Dictionary = parity.get_camp_tier()
	_check(int(tier["buildings"]) == 17, "combined legacy building count must reach 17")
	_check(str(tier["name"]) == "ЦИТАДЕЛЬ", "14+ legacy buildings must resolve to ЦИТАДЕЛЬ")

	var gold_before := int(resources.stored["gold"])
	parity.production_timers["gold_mine"] = 4.0
	parity._process_production(0.0)
	_check(int(resources.stored["gold"]) > gold_before, "gold mine must produce stored gold")
	var food_before := int(resources.stored["food"])
	parity.production_timers["farm"] = 3.0
	parity._process_production(0.0)
	_check(int(resources.stored["food"]) > food_before, "farm must produce stored food")

	parity.resolved_encounters.clear()
	parity.active_encounter_id = ""
	parity._loaded_once = true
	parity._on_wave_ended(1)
	var encounter: Dictionary = parity.get_current_encounter()
	_check(str(encounter.get("id","")) == "forest-spoils", "wave 1 must unlock forest-spoils encounter")
	var wood_before := int(resources.stored["wood"])
	_check(parity.resolve_encounter("timber"), "encounter timber choice should resolve")
	_check(int(resources.stored["wood"]) == wood_before + 25, "forest-spoils timber reward must be +25 wood")
	_check(parity.resolved_encounters.has("forest-spoils"), "resolved encounter must be persisted")

	progression.quest_index = progression.QUESTS.size()
	parity.extension_house_quest_completed = false
	var quest: Dictionary = parity.get_extension_quest()
	_check(str(quest.get("id","")) == "house", "ninth migrated quest must be Построй ДОМ")
	_check(not str(parity.get_player_hint()).is_empty(), "house quest must expose contextual player hint")
	parity._update_house_quest()
	_check(parity.extension_house_quest_completed, "house quest must complete when house already exists")

	var saved := parity.export_state()
	parity.reset_for_test()
	parity.import_state(saved)
	await process_frame
	_check(parity.get_building_level("house") == 2, "Stage 10 building levels must survive export/import")
	_check(parity.resolved_encounters.has("forest-spoils"), "Stage 10 encounter progress must survive export/import")

	root_node.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Stage 10 settlement parity tests passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
