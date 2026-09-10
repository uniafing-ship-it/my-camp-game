extends Control

var _manager = null
var _resource_manager = null
var _panel: PanelContainer
var _toggle: Button
var _title: Label
var _status: Label
var _buttons: Dictionary = {}
var _recruit_button: Button
var _refresh_accum := 0.0

func _ready() -> void:
	_build_ui()
	call_deferred("_bind")

func _process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum >= 0.35:
		_refresh_accum = 0.0
		_refresh()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_toggle = Button.new()
	_toggle.text = "ЛАГЕРЬ"
	_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toggle.offset_left = -126.0
	_toggle.offset_top = 16.0
	_toggle.offset_right = -16.0
	_toggle.offset_bottom = 58.0
	_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	_toggle.pressed.connect(_toggle_panel)
	add_child(_toggle)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.offset_left = -310.0
	_panel.offset_top = 64.0
	_panel.offset_right = -16.0
	_panel.offset_bottom = 438.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.05, 0.94)
	style.border_color = Color(0.68, 0.55, 0.30, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 7
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	_title = Label.new()
	_title.text = "ЛАГЕРЬ · СТРОИТЕЛЬСТВО"
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", Color(0.96, 0.86, 0.62))
	box.add_child(_title)

	for building_id in ["town_hall", "lumber_camp", "quarry", "fishing_hut"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(_on_building_pressed.bind(building_id))
		box.add_child(button)
		_buttons[building_id] = button

	_recruit_button = Button.new()
	_recruit_button.custom_minimum_size = Vector2(0, 48)
	_recruit_button.pressed.connect(_on_recruit_pressed)
	box.add_child(_recruit_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0, 52)
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", Color(0.78, 0.84, 0.78))
	box.add_child(_status)

func _toggle_panel() -> void:
	_panel.visible = not _panel.visible
	_toggle.text = "ЗАКРЫТЬ" if _panel.visible else "ЛАГЕРЬ"

func _bind() -> void:
	_manager = get_tree().get_first_node_in_group("settlement_manager")
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if _manager != null:
		if _manager.has_signal("settlement_changed"):
			_manager.connect("settlement_changed", Callable(self, "_on_settlement_changed"))
		if _manager.has_signal("activity_changed"):
			_manager.connect("activity_changed", Callable(self, "_on_activity_changed"))
	if _resource_manager != null and _resource_manager.has_signal("inventory_changed"):
		_resource_manager.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
	_refresh()

func _refresh() -> void:
	if _manager == null:
		return
	for building_id in _buttons.keys():
		var button: Button = _buttons[building_id]
		var level := int(_manager.get_building_level(str(building_id)))
		if str(building_id) == "town_hall":
			if level >= int(_manager.MAX_BUILDING_LEVEL):
				button.text = "Ратуша · ур.%d · MAX" % level
				button.disabled = true
			else:
				var cost: Dictionary = _manager.get_upgrade_cost("town_hall")
				button.text = "Ратуша ур.%d → %d   %s" % [level, level + 1, _cost_text(cost)]
				button.disabled = not bool(_manager.can_upgrade("town_hall"))
		else:
			if level <= 0:
				var build_cost: Dictionary = _manager.get_build_cost(str(building_id))
				button.text = "Построить %s   %s" % [_building_name(str(building_id)), _cost_text(build_cost)]
				button.disabled = not bool(_manager.can_build(str(building_id)))
			elif level >= int(_manager.MAX_BUILDING_LEVEL):
				button.text = "%s · ур.%d · MAX" % [_building_name(str(building_id)), level]
				button.disabled = true
			else:
				var upgrade_cost: Dictionary = _manager.get_upgrade_cost(str(building_id))
				button.text = "%s ур.%d → %d   %s" % [_building_name(str(building_id)), level, level + 1, _cost_text(upgrade_cost)]
				button.disabled = not bool(_manager.can_upgrade(str(building_id)))

	_recruit_button.text = "Нанять рабочего %d/%d   Еда 8 · Дерево 5" % [int(_manager.worker_count), int(_manager.get_worker_capacity())]
	_recruit_button.disabled = not bool(_manager.can_recruit_worker())
	_status.text = str(_manager.last_activity)

func _on_building_pressed(building_id: String) -> void:
	if _manager == null:
		return
	var level := int(_manager.get_building_level(building_id))
	if level <= 0:
		_manager.build(building_id)
	else:
		_manager.upgrade(building_id)
	_refresh()

func _on_recruit_pressed() -> void:
	if _manager != null:
		_manager.recruit_worker()
		_refresh()

func _on_settlement_changed(_snapshot: Dictionary) -> void:
	_refresh()

func _on_inventory_changed(_carried: Dictionary, _stored: Dictionary) -> void:
	_refresh()

func _on_activity_changed(text: String) -> void:
	if _status != null:
		_status.text = text

func _building_name(building_id: String) -> String:
	var names := {
		"lumber_camp": "лесопилку",
		"quarry": "каменоломню",
		"fishing_hut": "рыбацкую хижину",
	}
	return str(names.get(building_id, building_id))

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	var titles := {"wood": "Д", "stone": "К", "food": "Е", "gold": "З"}
	for key in ["wood", "stone", "food", "gold"]:
		if int(cost.get(key, 0)) > 0:
			parts.append("%s:%d" % [str(titles[key]), int(cost[key])])
	return " · ".join(parts)
