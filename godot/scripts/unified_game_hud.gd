extends Control
class_name UnifiedGameHUD

const BASE_BUILDINGS := ["town_hall", "lumber_camp", "quarry", "fishing_hut"]
const SUPPORT_BUILDINGS := ["hunting_lodge", "kennel"]
const DEFENSE_BUILDINGS := ["stone_wall", "watchtower", "cannon", "barracks", "infirmary", "training_ground"]
const RESEARCH_IDS := ["axes", "bags", "armor", "arrows", "walls", "hounds"]
const UNIT_KINDS := ["foot", "hunter", "dog"]

var _player = null
var _resources = null
var _settlement = null
var _progression = null
var _units = null
var _meta = null
var _stage10 = null
var _waves = null
var _save = null

var _top_panel: PanelContainer
var _wave_label: Label
var _tier_label: Label
var _resource_labels: Dictionary = {}
var _hero_label: Label
var _hero_bar: ProgressBar
var _camp_label: Label
var _camp_bar: ProgressBar
var _activity_label: Label

var _nav_panel: PanelContainer
var _nav_box: HBoxContainer
var _drawer: PanelContainer
var _drawer_title: Label
var _content: VBoxContainer
var _current_tab := ""

var _attack_button: Button
var _touch_ui := false

var _encounter_panel: PanelContainer
var _encounter_box: VBoxContainer
var _refresh_accum := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_ui = DisplayServer.is_touchscreen_available()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_bind")
	call_deferred("_layout")

func _process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum >= 0.25:
		_refresh_accum = 0.0
		_refresh_status()

func _panel_style(alpha := 0.92, border := Color(0.56, 0.48, 0.30, 0.82), radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.042, 0.033, alpha)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 6
	return style

func _build_ui() -> void:
	_top_panel = PanelContainer.new()
	_top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_panel.add_theme_stylebox_override("panel", _panel_style(0.87, Color(0.66, 0.55, 0.31, 0.74), 10))
	add_child(_top_panel)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 12)
	top_margin.add_theme_constant_override("margin_right", 12)
	top_margin.add_theme_constant_override("margin_top", 8)
	top_margin.add_theme_constant_override("margin_bottom", 8)
	_top_panel.add_child(top_margin)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 3)
	top_margin.add_child(top_box)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	top_box.add_child(status_row)
	_wave_label = Label.new()
	_wave_label.text = "ДО НОЧИ 180с"
	_wave_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wave_label.add_theme_font_size_override("font_size", 15)
	_wave_label.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	status_row.add_child(_wave_label)
	_tier_label = Label.new()
	_tier_label.text = "СТОЯНКА 0/17"
	_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tier_label.add_theme_font_size_override("font_size", 13)
	_tier_label.add_theme_color_override("font_color", Color(0.95, 0.81, 0.49))
	status_row.add_child(_tier_label)

	var resources_row := HBoxContainer.new()
	resources_row.add_theme_constant_override("separation", 18)
	top_box.add_child(resources_row)
	for resource_type in ["wood", "stone", "food", "gold", "pelts"]:
		var label := Label.new()
		label.text = "%s 0" % _resource_short(resource_type)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.88, 0.87, 0.76))
		resources_row.add_child(label)
		_resource_labels[resource_type] = label

	var bars_row := HBoxContainer.new()
	bars_row.add_theme_constant_override("separation", 12)
	top_box.add_child(bars_row)
	var hero_box := VBoxContainer.new()
	hero_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_row.add_child(hero_box)
	_hero_label = Label.new()
	_hero_label.text = "ГЕРОЙ 100/100"
	_hero_label.add_theme_font_size_override("font_size", 10)
	hero_box.add_child(_hero_label)
	_hero_bar = ProgressBar.new()
	_hero_bar.show_percentage = false
	_hero_bar.custom_minimum_size = Vector2(0, 8)
	hero_box.add_child(_hero_bar)
	var camp_box := VBoxContainer.new()
	camp_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_row.add_child(camp_box)
	_camp_label = Label.new()
	_camp_label.text = "ЛАГЕРЬ 300/300"
	_camp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_camp_label.add_theme_font_size_override("font_size", 10)
	camp_box.add_child(_camp_label)
	_camp_bar = ProgressBar.new()
	_camp_bar.show_percentage = false
	_camp_bar.custom_minimum_size = Vector2(0, 8)
	camp_box.add_child(_camp_bar)

	_activity_label = Label.new()
	_activity_label.text = "Исследуй мир и развивай лагерь."
	_activity_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_activity_label.add_theme_font_size_override("font_size", 10)
	_activity_label.add_theme_color_override("font_color", Color(0.73, 0.80, 0.72))
	top_box.add_child(_activity_label)

	_nav_panel = PanelContainer.new()
	_nav_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_nav_panel.add_theme_stylebox_override("panel", _panel_style(0.91, Color(0.55, 0.50, 0.35, 0.80), 12))
	add_child(_nav_panel)
	var nav_margin := MarginContainer.new()
	nav_margin.add_theme_constant_override("margin_left", 6)
	nav_margin.add_theme_constant_override("margin_right", 6)
	nav_margin.add_theme_constant_override("margin_top", 5)
	nav_margin.add_theme_constant_override("margin_bottom", 5)
	_nav_panel.add_child(nav_margin)
	_nav_box = HBoxContainer.new()
	_nav_box.add_theme_constant_override("separation", 4)
	nav_margin.add_child(_nav_box)
	for item in [["camp", "ЛАГЕРЬ"], ["progress", "РАЗВИТИЕ"], ["units", "ОТРЯД"], ["defense", "ОБОРОНА"], ["meta", "ПОХОДЫ"]]:
		var button := Button.new()
		button.text = str(item[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(94, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_open_tab.bind(str(item[0])))
		_nav_box.add_child(button)

	_drawer = PanelContainer.new()
	_drawer.visible = false
	_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer.add_theme_stylebox_override("panel", _panel_style(0.975, Color(0.70, 0.57, 0.31, 0.92), 14))
	add_child(_drawer)
	var drawer_margin := MarginContainer.new()
	drawer_margin.add_theme_constant_override("margin_left", 14)
	drawer_margin.add_theme_constant_override("margin_right", 14)
	drawer_margin.add_theme_constant_override("margin_top", 12)
	drawer_margin.add_theme_constant_override("margin_bottom", 12)
	_drawer.add_child(drawer_margin)
	var drawer_box := VBoxContainer.new()
	drawer_box.add_theme_constant_override("separation", 8)
	drawer_margin.add_child(drawer_box)
	var title_row := HBoxContainer.new()
	drawer_box.add_child(title_row)
	_drawer_title = Label.new()
	_drawer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drawer_title.add_theme_font_size_override("font_size", 17)
	_drawer_title.add_theme_color_override("font_color", Color(0.96, 0.84, 0.60))
	title_row.add_child(_drawer_title)
	var close := Button.new()
	close.text = "X"
	close.custom_minimum_size = Vector2(40, 34)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_drawer)
	title_row.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	drawer_box.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 7)
	scroll.add_child(_content)

	_attack_button = Button.new()
	_attack_button.text = "АТАКА"
	_attack_button.visible = _touch_ui
	_attack_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_attack_button.focus_mode = Control.FOCUS_NONE
	_attack_button.pressed.connect(_attack)
	add_child(_attack_button)

	_encounter_panel = PanelContainer.new()
	_encounter_panel.visible = false
	_encounter_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_encounter_panel.add_theme_stylebox_override("panel", _panel_style(0.985, Color(0.77, 0.54, 0.24, 0.96), 14))
	add_child(_encounter_panel)
	var enc_margin := MarginContainer.new()
	enc_margin.add_theme_constant_override("margin_left", 18)
	enc_margin.add_theme_constant_override("margin_right", 18)
	enc_margin.add_theme_constant_override("margin_top", 16)
	enc_margin.add_theme_constant_override("margin_bottom", 16)
	_encounter_panel.add_child(enc_margin)
	_encounter_box = VBoxContainer.new()
	_encounter_box.add_theme_constant_override("separation", 9)
	enc_margin.add_child(_encounter_box)

func _layout() -> void:
	var size := get_viewport_rect().size
	var portrait := size.y > size.x
	var top_width := minf(size.x - 24.0, 760.0)
	_top_panel.position = Vector2(12.0, 12.0)
	_top_panel.size = Vector2(top_width, 112.0)

	var nav_width := minf(size.x - 24.0, 650.0)
	_nav_panel.position = Vector2((size.x - nav_width) * 0.5, size.y - 62.0)
	_nav_panel.size = Vector2(nav_width, 50.0)

	if portrait:
		var drawer_width := size.x - 16.0
		var drawer_height := minf(size.y * 0.54, 500.0)
		_drawer.position = Vector2(8.0, size.y - drawer_height - 70.0)
		_drawer.size = Vector2(drawer_width, drawer_height)
	else:
		var drawer_width := minf(430.0, size.x * 0.38)
		var drawer_height := minf(size.y - 160.0, 540.0)
		_drawer.position = Vector2(size.x - drawer_width - 14.0, 126.0)
		_drawer.size = Vector2(drawer_width, drawer_height)

	_attack_button.position = Vector2(size.x - 88.0, size.y - 138.0)
	_attack_button.size = Vector2(72.0, 58.0)
	var encounter_width := minf(size.x - 32.0, 470.0)
	var encounter_height := minf(size.y - 120.0, 390.0)
	_encounter_panel.position = Vector2((size.x - encounter_width) * 0.5, (size.y - encounter_height) * 0.5)
	_encounter_panel.size = Vector2(encounter_width, encounter_height)

func _bind() -> void:
	_player = get_tree().get_first_node_in_group("player_combat")
	_resources = get_tree().get_first_node_in_group("resource_manager")
	_settlement = get_tree().get_first_node_in_group("settlement_manager")
	_progression = get_tree().get_first_node_in_group("progression_manager")
	_units = get_tree().get_first_node_in_group("unit_manager")
	_meta = get_tree().get_first_node_in_group("meta_progression_manager")
	_stage10 = get_tree().get_first_node_in_group("stage10_settlement_parity")
	_waves = get_tree().get_first_node_in_group("raid_manager")
	_save = get_tree().get_first_node_in_group("save_manager")
	if _stage10 != null and _stage10.has_signal("encounter_available"):
		var cb := Callable(self, "_on_encounter")
		if not _stage10.is_connected("encounter_available", cb):
			_stage10.connect("encounter_available", cb)
	var current: Dictionary = _stage10.get_current_encounter() if _stage10 != null else {}
	if not current.is_empty():
		_on_encounter(current)
	_refresh_status()

func _refresh_status() -> void:
	if _player == null or not is_instance_valid(_player): _player = get_tree().get_first_node_in_group("player_combat")
	if _resources == null or not is_instance_valid(_resources): _resources = get_tree().get_first_node_in_group("resource_manager")
	if _waves == null or not is_instance_valid(_waves): _waves = get_tree().get_first_node_in_group("raid_manager")
	if _stage10 == null or not is_instance_valid(_stage10): _stage10 = get_tree().get_first_node_in_group("stage10_settlement_parity")
	if _resources != null:
		var stored: Dictionary = _resources.get("stored")
		for key in _resource_labels.keys():
			(_resource_labels[key] as Label).text = "%s %d" % [_resource_short(str(key)), int(stored.get(key, 0))]
	if _player != null:
		_hero_bar.max_value = int(_player.max_health)
		_hero_bar.value = int(_player.health)
		_hero_label.text = "ГЕРОЙ %d/%d" % [int(_player.health), int(_player.max_health)]
	if _waves != null:
		_camp_bar.max_value = int(_waves.camp_max_health)
		_camp_bar.value = int(_waves.camp_health)
		_camp_label.text = "ЛАГЕРЬ %d/%d" % [int(_waves.camp_health), int(_waves.camp_max_health)]
		if bool(_waves.is_night):
			_wave_label.text = "НОЧЬ · ВОЛНА %d · %dс" % [int(_waves.wave_number), int(ceil(float(_waves.night_seconds_left)))]
			_wave_label.add_theme_color_override("font_color", Color(1.0, 0.46, 0.34))
		else:
			_wave_label.text = "ДО НОЧИ %dс" % int(ceil(float(_waves.next_wave_in)))
			_wave_label.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	if _stage10 != null:
		var tier: Dictionary = _stage10.get_camp_tier()
		_tier_label.text = "%s %d/17" % [str(tier.get("name", "СТОЯНКА")), int(tier.get("buildings", 0))]
		var hint := str(_stage10.get_player_hint())
		if not hint.is_empty():
			_activity_label.text = hint

func _open_tab(tab: String) -> void:
	if _drawer.visible and _current_tab == tab:
		_close_drawer()
		return
	_current_tab = tab
	_drawer.visible = true
	_rebuild_tab()

func _close_drawer() -> void:
	_drawer.visible = false
	_current_tab = ""

func _rebuild_tab() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	match _current_tab:
		"camp": _build_camp_tab()
		"progress": _build_progress_tab()
		"units": _build_units_tab()
		"defense": _build_defense_tab()
		"meta": _build_meta_tab()

func _build_camp_tab() -> void:
	_drawer_title.text = "ЛАГЕРЬ И СТРОИТЕЛЬСТВО"
	if _stage10 != null:
		var tier: Dictionary = _stage10.get_camp_tier()
		_add_info("%s · построено %d/17" % [str(tier.get("name", "СТОЯНКА")), int(tier.get("buildings", 0))], true)
		var hint := str(_stage10.get_player_hint())
		if not hint.is_empty(): _add_info(hint, false)
	_add_section("ОСНОВА")
	if _settlement != null:
		for id in BASE_BUILDINGS:
			_add_settlement_building(id)
		_add_separator()
		var recruit := Button.new()
		recruit.text = "НАНЯТЬ РАБОЧЕГО · %d/%d · ЕДА 8 · ДЕР 5" % [int(_settlement.worker_count), int(_settlement.get_worker_capacity())]
		recruit.disabled = not bool(_settlement.can_recruit_worker())
		recruit.custom_minimum_size = Vector2(0, 42)
		recruit.pressed.connect(_recruit_worker)
		_content.add_child(recruit)
	if _stage10 != null:
		_add_section("РАСШИРЕНИЕ ПОСЕЛЕНИЯ")
		for id in _stage10.BUILDING_ORDER:
			_add_stage10_building(str(id))

func _build_progress_tab() -> void:
	_drawer_title.text = "РАЗВИТИЕ"
	if _progression == null: return
	var quest: Dictionary = _progression.get_current_quest()
	if bool(quest.get("complete", false)) and _stage10 != null:
		var ext: Dictionary = _stage10.get_extension_quest()
		if bool(ext.get("active", false)): quest = ext
	_add_section("ТЕКУЩЕЕ ЗАДАНИЕ")
	_add_info(str(quest.get("title", "Заданий нет")), true)
	_add_info(str(quest.get("progress", "")), false)
	if quest.has("reward"): _add_info("Награда: %s" % _cost_text(quest.get("reward", {})), false)
	_add_section("ИССЛЕДОВАНИЯ")
	for item in _progression.get_research_snapshot():
		var id := str(item.get("id", ""))
		if not RESEARCH_IDS.has(id): continue
		var owned := bool(item.get("owned", false))
		var text := "%s · %s" % [str(item.get("name", id)), str(item.get("description", ""))]
		if owned: text = "ГОТОВО · " + text
		else: text += " · " + _cost_text(item.get("cost", {}))
		var button := Button.new()
		button.text = text
		button.disabled = owned or not bool(item.get("can_buy", false))
		button.custom_minimum_size = Vector2(0, 46)
		button.pressed.connect(_buy_research.bind(id))
		_content.add_child(button)
	_add_separator()
	var save_button := Button.new()
	save_button.text = "СОХРАНИТЬ СЕЙЧАС"
	save_button.custom_minimum_size = Vector2(0, 40)
	save_button.pressed.connect(_save_now)
	_content.add_child(save_button)
	if _save != null: _add_info(str(_save.get_status_text()), false)

func _build_units_tab() -> void:
	_drawer_title.text = "ОТРЯД И ОХОТА"
	if _resources != null: _add_info("ШКУРЫ: %d" % int((_resources.get("stored") as Dictionary).get("pelts", 0)), true)
	if _settlement != null:
		_add_section("ПОСТРОЙКИ")
		for id in SUPPORT_BUILDINGS: _add_settlement_building(id)
	if _units != null:
		_add_section("БОЙЦЫ")
		for kind in UNIT_KINDS:
			var current := int(_units.get_count(kind))
			var capacity := int(_units.get_capacity(kind))
			var cost: Dictionary = _units.get_recruit_cost(kind)
			var button := Button.new()
			button.text = "%s %d/%d · %s" % [_unit_name(kind), current, capacity, _cost_text(cost)]
			button.disabled = not bool(_units.can_recruit(kind))
			button.custom_minimum_size = Vector2(0, 44)
			button.pressed.connect(_recruit_unit.bind(kind))
			_content.add_child(button)

func _build_defense_tab() -> void:
	_drawer_title.text = "ОБОРОНА"
	_add_info("Стены замедляют рейдеров. Башни и пушки ведут автоматический огонь.", false)
	if _settlement != null:
		for id in DEFENSE_BUILDINGS: _add_settlement_building(id)

func _build_meta_tab() -> void:
	_drawer_title.text = "ПОХОДЫ И ВОСХОЖДЕНИЕ"
	if _meta == null: return
	var snapshot: Dictionary = _meta.get_snapshot()
	_add_info("Герой ур.%d · XP %d/%d" % [int(snapshot.get("hero_level", 1)), int(snapshot.get("hero_xp", 0)), int(snapshot.get("hero_xp_needed", 1))], true)
	var ascension: Dictionary = snapshot.get("ascension", {})
	_add_info("Слава %d · производство +%d%% · урон +%d%%" % [int(snapshot.get("fame", 0)), int(ascension.get("production_bonus_percent", 0)), int(ascension.get("damage_bonus_percent", 0))], false)
	_add_section("ЭКСПЕДИЦИИ")
	var expeditions: Dictionary = snapshot.get("expeditions", {})
	var slots: Array = expeditions.get("slots", [])
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if bool(slot.get("active", false)):
			var left := maxf(0.0, float(slot.get("duration", 0.0)) - float(slot.get("elapsed", 0.0)))
			_add_info("Слот %d: %s · %dс" % [i + 1, str(slot.get("id", "поход")), int(ceil(left))], false)
		else:
			_add_info("Слот %d: свободен" % (i + 1), false)
	for item in expeditions.get("definitions", []):
		var id := str(item.get("id", ""))
		var button := Button.new()
		button.text = "%s · %s · %dс" % [str(item.get("name", id)), str(item.get("description", "")), int(float(item.get("duration", 0.0)))]
		button.disabled = not bool(item.get("can_start", false))
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(_start_expedition.bind(id))
		_content.add_child(button)
	_add_section("РЕЛИКВИИ И ДОСТИЖЕНИЯ")
	var relic_count := 0
	for item in _meta.get_relic_snapshot():
		if bool(item.get("owned", false)): relic_count += 1
	var achievement_count := 0
	var achievement_total := 0
	for item in _meta.get_achievement_snapshot():
		achievement_total += 1
		if bool(item.get("owned", false)): achievement_count += 1
	_add_info("Реликвии: %d · достижения: %d/%d" % [relic_count, achievement_count, achievement_total], false)
	_add_section("ВОСХОЖДЕНИЕ")
	_add_info("Построено %d/%d · награда +%d славы" % [int(ascension.get("built", 0)), int(ascension.get("required", 12)), int(ascension.get("fame_gain", 0))], false)
	var ascend := Button.new()
	ascend.text = "СОВЕРШИТЬ ВОСХОЖДЕНИЕ"
	ascend.disabled = not bool(ascension.get("can_ascend", false))
	ascend.custom_minimum_size = Vector2(0, 44)
	ascend.pressed.connect(_ascend)
	_content.add_child(ascend)

func _add_settlement_building(id: String) -> void:
	var level := int(_settlement.get_building_level(id))
	var button := Button.new()
	if level <= 0:
		var cost: Dictionary = _settlement.get_build_cost(id)
		button.text = "ПОСТРОИТЬ · %s · %s" % [_building_name(id), _cost_text(cost)]
		button.disabled = not bool(_settlement.can_build(id))
	else:
		var max_level := int(_settlement.MAX_BUILDING_LEVEL)
		if level >= max_level:
			button.text = "%s · ур.%d · MAX" % [_building_name(id), level]
			button.disabled = true
		else:
			var cost: Dictionary = _settlement.get_upgrade_cost(id)
			button.text = "%s · ур.%d > %d · %s" % [_building_name(id), level, level + 1, _cost_text(cost)]
			button.disabled = not bool(_settlement.can_upgrade(id))
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(_settlement_action.bind(id))
	_content.add_child(button)

func _add_stage10_building(id: String) -> void:
	var def: Dictionary = _stage10.LEGACY_BUILDINGS[id]
	var level := int(_stage10.get_building_level(id))
	var button := Button.new()
	if level <= 0:
		button.text = "ПОСТРОИТЬ · %s · %s" % [str(def.get("name", id)), _cost_text(_stage10.get_build_cost(id))]
		button.disabled = not bool(_stage10.can_build(id))
	else:
		button.text = "%s · ур.%d > %d · %s" % [str(def.get("name", id)), level, level + 1, _cost_text(_stage10.get_upgrade_cost(id))]
		button.disabled = not bool(_stage10.can_upgrade(id))
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(_stage10_action.bind(id))
	_content.add_child(button)
	_add_info(str(def.get("description", "")), false)

func _settlement_action(id: String) -> void:
	if _settlement == null: return
	if int(_settlement.get_building_level(id)) <= 0: _settlement.build(id)
	else: _settlement.upgrade(id)
	_rebuild_tab()

func _stage10_action(id: String) -> void:
	if _stage10 == null: return
	if int(_stage10.get_building_level(id)) <= 0: _stage10.build(id)
	else: _stage10.upgrade(id)
	_rebuild_tab()

func _recruit_worker() -> void:
	if _settlement != null: _settlement.recruit_worker()
	_rebuild_tab()

func _buy_research(id: String) -> void:
	if _progression != null: _progression.research(id)
	_rebuild_tab()

func _recruit_unit(kind: String) -> void:
	if _units != null: _units.recruit(kind)
	_rebuild_tab()

func _start_expedition(id: String) -> void:
	if _meta != null: _meta.start_expedition(id)
	_rebuild_tab()

func _ascend() -> void:
	if _meta != null: _meta.ascend()
	_rebuild_tab()

func _save_now() -> void:
	if _save != null: _save.save_game()
	_rebuild_tab()

func _attack() -> void:
	if _player != null and _player.has_method("request_attack"): _player.request_attack()

func _on_encounter(encounter: Dictionary) -> void:
	for child in _encounter_box.get_children():
		_encounter_box.remove_child(child)
		child.queue_free()
	var kicker := Label.new()
	kicker.text = "СОБЫТИЕ ПОСЛЕ ВОЛНЫ %d" % int(encounter.get("wave", 0))
	kicker.add_theme_font_size_override("font_size", 12)
	kicker.add_theme_color_override("font_color", Color(0.92, 0.73, 0.40))
	_encounter_box.add_child(kicker)
	var title := Label.new()
	title.text = str(encounter.get("title", "Событие лагеря"))
	title.add_theme_font_size_override("font_size", 20)
	_encounter_box.add_child(title)
	var text := Label.new()
	text.text = str(encounter.get("text", ""))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_encounter_box.add_child(text)
	for choice in encounter.get("choices", []):
		var button := Button.new()
		button.text = "%s%s" % [str(choice.get("label", "Выбрать")), _reward_suffix(choice.get("rewards", {}))]
		var choice_id := str(choice.get("id", ""))
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(_resolve_encounter.bind(choice_id))
		_encounter_box.add_child(button)
	_encounter_panel.visible = true

func _resolve_encounter(choice_id: String) -> void:
	if _stage10 != null and _stage10.resolve_encounter(choice_id):
		_encounter_panel.visible = false
		_refresh_status()

func _add_section(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.48))
	_content.add_child(label)

func _add_info(text: String, strong: bool) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13 if strong else 11)
	label.add_theme_color_override("font_color", Color(0.90, 0.91, 0.84) if strong else Color(0.72, 0.78, 0.72))
	_content.add_child(label)

func _add_separator() -> void:
	_content.add_child(HSeparator.new())

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["wood", "stone", "food", "gold", "pelts"]:
		var amount := int(cost.get(key, 0))
		if amount > 0: parts.append("%s %d" % [_resource_short(key), amount])
	return " · ".join(parts) if not parts.is_empty() else "БЕСПЛАТНО"

func _reward_suffix(rewards: Dictionary) -> String:
	return "" if rewards.is_empty() else "  >  " + _cost_text(rewards)

func _resource_short(id: String) -> String:
	match id:
		"wood": return "ДЕР"
		"stone": return "КАМ"
		"food": return "ЕДА"
		"gold": return "ЗОЛ"
		"pelts": return "ШК"
		_: return id.to_upper()

func _building_name(id: String) -> String:
	var names := {
		"town_hall":"Ратуша", "lumber_camp":"Лесопилка", "quarry":"Каменоломня", "fishing_hut":"Рыбацкая хижина",
		"hunting_lodge":"Охотничья изба", "kennel":"Псарня", "stone_wall":"Каменная стена", "watchtower":"Сторожевая башня",
		"cannon":"Пушка", "barracks":"Казарма", "infirmary":"Лазарет", "training_ground":"Тренировочный плац"
	}
	return str(names.get(id, id))

func _unit_name(kind: String) -> String:
	match kind:
		"foot": return "ВОИН"
		"hunter": return "ОХОТНИК"
		"dog": return "ПЁС"
		_: return kind.to_upper()
