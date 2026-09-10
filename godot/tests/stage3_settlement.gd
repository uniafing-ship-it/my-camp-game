extends SceneTree

const ResourceManagerScript = preload("res://scripts/resource_manager.gd")
const SettlementManagerScript = preload("res://scripts/settlement_manager.gd")
const HarvestableScript = preload("res://scripts/harvestable.gd")

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
	var resources = ResourceManagerScript.new()
	root.add_child(resources)
	await process_frame
	for resource_type in ["wood", "stone", "food", "gold"]:
		resources.add_stored(resource_type, 200)

	var settlement = SettlementManagerScript.new()
	root.add_child(settlement)
	await process_frame

	_expect(settlement.get_building_level("town_hall") == 1, "town hall exists at level 1")
	_expect(settlement.get_worker_capacity() == 4, "level 1 town hall provides four worker slots")

	var wood_before := int(resources.stored["wood"])
	var stone_before := int(resources.stored["stone"])
	_expect(settlement.build("lumber_camp"), "lumber camp can be constructed from stored resources")
	_expect(settlement.get_building_level("lumber_camp") == 1, "constructed lumber camp is level 1")
	_expect(int(resources.stored["wood"]) == wood_before - 18, "building consumes wood from warehouse")
	_expect(int(resources.stored["stone"]) == stone_before - 4, "building consumes stone from warehouse")
	_expect(not settlement.build("lumber_camp"), "same building cannot be constructed twice")

	var capacity_before := settlement.get_worker_capacity()
	_expect(settlement.upgrade("town_hall"), "town hall can be upgraded")
	_expect(settlement.get_building_level("town_hall") == 2, "town hall reaches level 2")
	_expect(settlement.get_worker_capacity() > capacity_before, "town hall upgrade increases worker capacity")

	var food_before := int(resources.stored["food"])
	var worker_wood_before := int(resources.stored["wood"])
	_expect(settlement.recruit_worker(), "worker can be recruited when resources and capacity are available")
	_expect(settlement.worker_count == 1, "worker count increases after recruitment")
	_expect(int(resources.stored["food"]) == food_before - 8, "worker recruitment consumes food")
	_expect(int(resources.stored["wood"]) == worker_wood_before - 5, "worker recruitment consumes wood")

	var tree = HarvestableScript.new()
	tree.resource_type = "wood"
	tree.max_amount = 3
	tree.regrow_delay = 0.0
	root.add_child(tree)
	await process_frame
	_expect(tree.take_for_worker(2) == 2, "worker harvesting can take resources independently of player backpack")
	_expect(tree.current_amount == 1, "worker harvesting reduces source amount")
	_expect(tree.take_for_worker(2) == 1, "worker harvesting is capped by remaining resource")
	_expect(tree.is_depleted(), "resource depletes after worker takes final unit")

	if failures == 0:
		print("STAGE3_SETTLEMENT_TESTS_OK")
		quit(0)
	else:
		push_error("Stage 3 settlement tests failed: %d" % failures)
		quit(1)
