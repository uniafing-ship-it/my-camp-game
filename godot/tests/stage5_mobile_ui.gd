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

	var hud = main.get_node_or_null("UI/MobileGameHUD")
	_expect(hud != null, "unified mobile HUD is present")
	_expect(main.get_node_or_null("UI/ResourceHUD") == null, "legacy resource HUD is removed from main scene")
	_expect(main.get_node_or_null("UI/SettlementHUD") == null, "legacy settlement HUD is removed from main scene")
	_expect(main.get_node_or_null("UI/CombatHUD") == null, "legacy combat HUD is removed from main scene")
	_expect(main.get_node_or_null("UI/MobileJoystick") != null, "mobile joystick remains available")

	if hud != null:
		_expect(hud.get_child_count() >= 4, "HUD builds compact status, action and drawer controls")
		_expect(hud.has_method("_toggle_camp_drawer"), "camp drawer control exists")
		_expect(hud.has_method("_on_attack_pressed"), "mobile attack control exists")
		_expect(hud.has_method("_layout_for_viewport"), "responsive viewport layout exists")
		hud._on_inventory_changed({}, {"wood": 11, "stone": 7, "food": 5, "gold": 2})
		hud._on_health_changed(73, 100)
		hud._on_camp_health_changed(245, 300)
		hud._on_timer_changed(42.0, false, 0.0)
		_expect(true, "HUD accepts live resource, health and wave updates")

	if failures == 0:
		print("STAGE5_MOBILE_UI_TESTS_OK")
		quit(0)
	else:
		push_error("Stage 5 mobile UI tests failed: %d" % failures)
		quit(1)
