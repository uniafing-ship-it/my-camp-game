extends Control
class_name MobileGameHUD

var _player = null
var _resource_manager = null
var _settlement_manager = null
var _wave_manager = null

var _top_bar: PanelContainer
var _resource_row: HBoxContainer
var _wave_badge: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _camp_bar: ProgressBar
var _camp_label: Label
var _activity_panel: PanelContainer
var _activity_label: Label
var _camp_button: Button
var _camp_drawer: PanelContainer
var _camp_buttons: Dictionary = {}
var _recruit_button: Button
var _attack_button: Button
var _drawer_open := false
var _refresh_accum := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	get_viewport().size_changed.connect(_layout_for_viewport)
	call_deferred("_bind")
	call_deferred("_layout_for_viewport")

func _process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum >= 0.25:
		_refresh_accum = 0.0
		_refresh()

func _panel_style(alpha := 0.90, border := Color(0.48, 0.56, 0.42, 0.72)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.035, alpha)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 7
	return style

func _build_ui() -> void:
	_top_bar = PanelContainer.new()
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.add_theme_stylebox_override("panel", _panel_style(0.86, Color(0.58, 0.49, 0.27, 0.72)))
	add_child(_top_bar)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 10)
	top_margin.add_theme_constant_override("margin_right", 10)
	top_margin.add_theme_constant_override("margin_top", 7)
	top_margin.add_theme_constant_override("margin_bottom", 7)
	_top_bar.add_child(top_margin)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 5)
	top_margin.add_child(top_box)

	var status_line := HBoxContainer.new()
	status_line.add_theme_constant_override("separation", 8)
	top_box.add_child(status_line)

	_wave_badge = Label.new()
	_wave_badge.text = "ДО НОЧИ 180с"
	_wave_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wave_badge.add_theme_font_size_override("font_size", 14)
	_wave_badge.add_theme_color_override("font_color", Color(0.90, 0.93, 1.0))
	status_line.add_child(_wave_badge)

	_camp_button = Button.new()
	_camp_button.text = "ЛАГЕРЬ"
	_camp_button.custom_minimum_size = Vector2(92, 36)
	_camp_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_camp_button.pressed.connect(_toggle_camp_drawer)
	status_line.add_child(_camp_button)

	_resource_row = HBoxContainer.new()
	_resource_row.add_theme_constant_override("separation", 8)
	top_box.add_child(_resource_row)
	for resource_type in ["wood", "stone", "food", "gold"]:
		var label := Label.new()
		label.name = resource_type.capitalize()
		label.text = _resource_icon(resource_type) + " 0"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.91, 0.88, 0.76))
		_resource_row.add_child(label)

	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 8)
	top_box.add_child(bars)

	var hero_box := VBoxContainer.new()
	hero_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_child(hero_box)
	_hp_label = Label.new()
	_hp_label.text = "ГЕРОЙ 100/100"
	_hp_label.add_theme_font_size_override("font_size", 11)
	hero_box.add_child(_hp_label)
	_hp_bar = ProgressBar.new()
	_hp_bar.min_value = 0
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 10)
	hero_box.add_child(_hp_bar)

	var camp_box := VBoxContainer.new()
	camp_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_child(camp_box)
	_camp_label = Label.new()
	_camp_label.text = "ЛАГЕРЬ 300/300"
	_camp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_camp_label.add_theme_font_size_override("font_size", 11)
	_camp_label.add_theme_color_override("font_color", Color(0.94, 0.80, 0.58))
	camp_box.add_child(_camp_label)
	_camp_bar = ProgressBar.new()
	_camp_bar.min_value = 0
	_camp_bar.max_value = 300
	_camp_bar.value = 300
	_camp_bar.show_percentage = false
	_camp_bar.custom_minimum_size = Vector2(0, 10)
	camp_box.add_child(_camp_bar)

	_activity_panel = PanelContainer.new()
	_activity_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activity_panel.add_theme_stylebox_override("panel", _panel_style(0.78, Color(0.40, 0.50, 0.40, 0.50)))
	add_child(_activity_panel)
	var activity_margin := MarginContainer.new()
	activity_margin.add_theme_constant_override("margin_left", 12)
	activity_margin.add_theme_constant_override("margin_right", 12)
	activity_margin.add_theme_constant_override("margin_top", 7)
	activity_margin.add_theme_constant_override("margin_bottom", 7)
	_activity_panel.add_child(activity_margin)
	_activity_label = Label.new()
	_activity_label.text = "Исследуй мир и развивай лагерь."
	_activity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_activity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_activity_label.add_theme_font_size_override("font_size", 12)
	_activity_label.add_theme_color_override("font_color", Color(0.80, 0.87, 0.80))
	activity_margin.add_child(_activity_label)

	_attack_button = Button.new()
	_attack_button.text = "⚔"
	_attack_button.add_theme_font_size_override("font_size", 30)
	_attack_button.custom_minimum_size = Vector2(86, 86)
	_attack_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_attack_button.pressed.connect(_on_attack_pressed)
	add_child(_attack_button)

	_build_camp_drawer()

func _build_camp_drawer() -> void:
	_camp_drawer = PanelContainer.new()
	_camp_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_camp_drawer.visible = false
	_camp_drawer.add_theme_stylebox_override("panel", _panel_style(0.97, Color(0.70, 0.56, 0.29, 0.90)))
	add_child(_camp_drawer)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_camp_drawer.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	var title := Label.new()
	title.text = "УПРАВЛЕНИЕ ЛАГЕРЕМ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.96, 0.85, 0.61))
	box.add_child(title)
	for building_id in ["town_hall", "lumber_camp", "quarry", "fishing_hut"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 46)
		button.pressed.connect(_on_building_pressed.bind(building_id))
		box.add_child(button)
		_camp_buttons[building_id] = button
	_recruit_button = Button.new()
	_recruit_button.custom_minimum_size = Vector2(0, 50)
	_recruit_button.pressed.connect(_on_recruit_pressed)
	box.add_child(_recruit_button)
	var close := Button.new()
	close.text = "ЗАКРЫТЬ"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(_toggle_camp_drawer)
	box.add_child(close)

func _layout_for_viewport() -> void:
	var size := get_viewport_rect().size
	var margin := 12.0
	_top_bar.position = Vector2(margin, margin)
	_top_bar.size = Vector2(maxf(300.0, size.x - margin * 2.0), 116.0)

	var activity_width := minf(size.x - 32.0, 520.0)
	_activity_panel.position = Vector2((size.x - activity_width) * 0.5, 138.0)
	_activity_panel.size = Vector2(activity_width, 44.0)

	_attack_button.position = Vector2(size.x - 110.0, size.y - 122.0)
	_attack_button.size = Vector2(86.0, 86.0)

	var drawer_width := minf(size.x - 24.0, 390.0)
	var drawer_height := minf(size.y - 170.0, 430.0)
	_camp_drawer.position = Vector2(size.x - drawer_width - 12.0, 134.0)
	_camp_drawer.size = Vector2(drawer_width, drawer_height)

func _bind() -> void:
	_player = get_tree().get_first_node_in_group("player_combat")
	_resource_manager = get_tree().get_first_node_in_group("resource_manager")
	_settlement_manager = get_tree().get_first_node_in_group("settlement_manager")
	_wave_manager = get_tree().get_first_node_in_group("raid_manager")
	if _player != null:
		if _player.has_signal("health_changed"): _player.connect("health_changed", Callable(self, "_on_health_changed"))
		if _player.has_signal("died"): _player.connect("died", Callable(self, "_on_player_died"))
	if _resource_manager != null:
		if _resource_manager.has_signal("inventory_changed"): _resource_manager.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
		if _resource_manager.has_signal("activity_changed"): _resource_manager.connect("activity_changed", Callable(self, "_on_activity_changed"))
	if _settlement_manager != null:
		if _settlement_manager.has_signal("settlement_changed"): _settlement_manager.connect("settlement_changed", Callable(self, "_on_settlement_changed"))
		if _settlement_manager.has_signal("activity_changed"): _settlement_manager.connect("activity_changed", Callable(self, "_on_activity_changed"))
	if _wave_manager != null:
		if _wave_manager.has_signal("timer_changed"): _wave_manager.connect("timer_changed", Callable(self, "_on_timer_changed"))
		if _wave_manager.has_signal("camp_health_changed"): _wave_manager.connect("camp_health_changed", Callable(self, "_on_camp_health_changed"))
		if _wave_manager.has_signal("game_over"): _wave_manager.connect("game_over", Callable(self, "_on_game_over"))
	_refresh()

func _refresh() -> void:
	if _resource_manager != null:
		_on_inventory_changed(_resource_manager.get("carried"), _resource_manager.get("stored"))
	if _player != null:
		_on_health_changed(int(_player.health), int(_player.max_health))
	if _wave_manager != null:
		_on_timer_changed(float(_wave_manager.next_wave_in), bool(_wave_manager.is_night), float(_wave_manager.night_seconds_left))
		_on_camp_health_changed(int(_wave_manager.camp_health), int(_wave_manager.camp_max_health))
	_refresh_camp_buttons()

func _on_inventory_changed(_carried: Dictionary, stored: Dictionary) -> void:
	for resource_type in ["wood", "stone", "food", "gold"]:
		var label := _resource_row.get_node_or_null(resource_type.capitalize()) as Label
		if label != null:
			label.text = "%s %d" % [_resource_icon(resource_type), int(stored.get(resource_type, 0))]

func _on_health_changed(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "ГЕРОЙ %d/%d" % [current, maximum]

func _on_camp_health_changed(current: int, maximum: int) -> void:
	_camp_bar.max_value = maximum
	_camp_bar.value = current
	_camp_label.text = "ЛАГЕРЬ %d/%d" % [current, maximum]

func _on_timer_changed(seconds_to_next: float, is_night: bool, night_left: float) -> void:
	if is_night:
		_wave_badge.text = "НОЧЬ · ВОЛНА %d · %dс" % [int(_wave_manager.wave_number) if _wave_manager else 0, int(ceil(night_left))]
		_wave_badge.add_theme_color_override("font_color", Color(1.0, 0.42, 0.33))
	else:
		_wave_badge.text = "ДО НОЧИ %dс" % int(ceil(seconds_to_next))
		_wave_badge.add_theme_color_override("font_color", Color(0.90, 0.93, 1.0))

func _on_activity_changed(text: String) -> void:
	_activity_label.text = text

func _on_settlement_changed(_snapshot: Dictionary) -> void:
	_refresh_camp_buttons()

func _on_player_died() -> void:
	_activity_label.text = "Герой повержен. Возрождение в лагере."

func _on_game_over() -> void:
	_wave_badge.text = "ЛАГЕРЬ РАЗРУШЕН"
	_wave_badge.add_theme_color_override("font_color", Color(1.0, 0.18, 0.14))
	_attack_button.disabled = true

func _toggle_camp_drawer() -> void:
	_drawer_open = not _drawer_open
	_camp_drawer.visible = _drawer_open
	_camp_button.text = "ЗАКРЫТЬ" if _drawer_open else "ЛАГЕРЬ"
	_refresh_camp_buttons()

func _refresh_camp_buttons() -> void:
	if _settlement_manager == null:
		return
	for building_id in _camp_buttons.keys():
		var button: Button = _camp_buttons[building_id]
		var level := int(_settlement_manager.get_building_level(str(building_id)))
		if level <= 0:
			var cost: Dictionary = _settlement_manager.get_build_cost(str(building_id))
			button.text = "Построить %s · %s" % [_building_name(str(building_id)), _cost_text(cost)]
			button.disabled = not bool(_settlement_manager.can_build(str(building_id)))
		elif level >= int(_settlement_manager.MAX_BUILDING_LEVEL):
			button.text = "%s · ур.%d · MAX" % [_building_name(str(building_id)), level]
			button.disabled = true
		else:
			var cost: Dictionary = _settlement_manager.get_upgrade_cost(str(building_id))
			button.text = "%s ур.%d → %d · %s" % [_building_name(str(building_id)), level, level + 1, _cost_text(cost)]
			button.disabled = not bool(_settlement_manager.can_upgrade(str(building_id)))
	_recruit_button.text = "Нанять рабочего %d/%d · Е:8 Д:5" % [int(_settlement_manager.worker_count), int(_settlement_manager.get_worker_capacity())]
	_recruit_button.disabled = not bool(_settlement_manager.can_recruit_worker())

func _on_building_pressed(building_id: String) -> void:
	if _settlement_manager == null:
		return
	if int(_settlement_manager.get_building_level(building_id)) <= 0:
		_settlement_manager.build(building_id)
	else:
		_settlement_manager.upgrade(building_id)
	_refresh_camp_buttons()

func _on_recruit_pressed() -> void:
	if _settlement_manager != null:
		_settlement_manager.recruit_worker()
		_refresh_camp_buttons()

func _on_attack_pressed() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player_combat")
	if _player != null and _player.has_method("request_attack"):
		_player.request_attack()

func _building_name(building_id: String) -> String:
	var names := {"town_hall":"Ратуша", "lumber_camp":"Лесопилка", "quarry":"Каменоломня", "fishing_hut":"Рыбацкая хижина"}
	return str(names.get(building_id, building_id))

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	var titles := {"wood":"Д", "stone":"К", "food":"Е", "gold":"З"}
	for key in ["wood", "stone", "food", "gold"]:
		if int(cost.get(key, 0)) > 0:
			parts.append("%s:%d" % [str(titles[key]), int(cost[key])])
	return " ".join(parts)

func _resource_icon(resource_type: String) -> String:
	match resource_type:
		"wood": return "🌲"
		"stone": return "🪨"
		"food": return "🍓"
		"gold": return "🪙"
		_: return "•"
