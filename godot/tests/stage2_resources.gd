extends SceneTree

const ResourceManagerScript = preload("res://scripts/resource_manager.gd")
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
	var manager = ResourceManagerScript.new()
	manager.carry_capacity = 4
	root.add_child(manager)

	var tree = HarvestableScript.new()
	tree.resource_type = "wood"
	tree.source_name = "Дерево"
	tree.max_amount = 3
	tree.yield_amount = 1
	tree.harvest_interval = 0.0
	tree.regrow_delay = 0.0
	root.add_child(tree)

	await process_frame
	_expect(manager.get_total_carried() == 0, "inventory starts empty")
	_expect(tree.try_harvest(manager) == 1, "tree yields wood automatically")
	_expect(int(manager.carried["wood"]) == 1, "wood enters carried inventory")

	tree.try_harvest(manager)
	tree.try_harvest(manager)
	_expect(tree.is_depleted(), "finite tree depletes after its resource amount is collected")
	_expect(int(manager.carried["wood"]) == 3, "three wood units were collected")

	var berries = HarvestableScript.new()
	berries.resource_type = "food"
	berries.source_name = "Ягодный куст"
	berries.max_amount = 10
	berries.yield_amount = 2
	berries.harvest_interval = 0.0
	root.add_child(berries)
	await process_frame
	_expect(berries.try_harvest(manager) == 1, "carry capacity limits accepted resource amount")
	_expect(manager.get_total_carried() == 4, "backpack stops at carry capacity")
	_expect(berries.try_harvest(manager) == 0, "full backpack blocks harvesting")

	var moved: Dictionary = manager.deposit_all()
	_expect(int(moved["wood"]) == 3 and int(moved["food"]) == 1, "warehouse deposit moves carried resources")
	_expect(manager.get_total_carried() == 0, "backpack is empty after warehouse deposit")
	_expect(int(manager.stored["wood"]) == 3 and int(manager.stored["food"]) == 1, "warehouse stores deposited resources")

	var fishing = HarvestableScript.new()
	fishing.resource_type = "food"
	fishing.source_name = "Рыбалка"
	fishing.max_amount = 1
	fishing.yield_amount = 1
	fishing.harvest_interval = 0.0
	fishing.infinite_source = true
	root.add_child(fishing)
	await process_frame
	_expect(fishing.try_harvest(manager) == 1, "fishing yields food")
	_expect(fishing.try_harvest(manager) == 1, "fishing remains available without manual reactivation")
	_expect(not fishing.is_depleted(), "fishing spot is persistent")

	if failures == 0:
		print("STAGE2_RESOURCE_TESTS_OK")
		quit(0)
	else:
		push_error("Stage 2 resource tests failed: %d" % failures)
		quit(1)
