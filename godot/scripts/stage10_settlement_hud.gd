extends Control
class_name Stage10SettlementHUD

var _manager = null
var _panel: PanelContainer
var _content: VBoxContainer
var _tier_label: Label
var _hint_label: Label
var _toggle: Button
var _encounter_panel: PanelContainer
var _encounter_content: VBoxContainer
var _open := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	call_deferred("_bind")

func _build_ui() -> void:
	_tier_label = Label.new()
	_tier_label.position = Vector2(12, 102)
	_tier_label.add_theme_font_size_override("font_size", 14)
	_tier_label.add_theme_color_override("font_color", Color(1.0,0.86,0.45))
	add_child(_tier_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(12, 124)
	_hint_label.size = Vector2(360, 42)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", Color(0.82,0.86,0.78))
	add_child(_hint_label)

	_toggle = Button.new()
	_toggle.text = "РАЗВИТИЕ"
	_toggle.anchor_left = 1.0
	_toggle.anchor_right = 1.0
	_toggle.offset_left = -126
	_toggle.offset_right = -12
	_toggle.offset_top = 126
	_toggle.offset_bottom = 168
	_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	_toggle.pressed.connect(_toggle_panel)
	add_child(_toggle)

	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -390
	_panel.offset_right = -12
	_panel.offset_top = 176
	_panel.offset_bottom = 620
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var scroll := ScrollContainer.new()
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	scroll.add_child(_content)
	_panel.add_child(scroll)
	add_child(_panel)

	_encounter_panel = PanelContainer.new()
	_encounter_panel.anchor_left = 0.5
	_encounter_panel.anchor_top = 0.5
	_encounter_panel.anchor_right = 0.5
	_encounter_panel.anchor_bottom = 0.5
	_encounter_panel.offset_left = -220
	_encounter_panel.offset_top = -180
	_encounter_panel.offset_right = 220
	_encounter_panel.offset_bottom = 180
	_encounter_panel.visible = false
	_encounter_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_encounter_content = VBoxContainer.new()
	_encounter_content.add_theme_constant_override("separation", 10)
	_encounter_panel.add_child(_encounter_content)
	add_child(_encounter_panel)

func _bind() -> void:
	_manager = get_tree().get_first_node_in_group("stage10_settlement_parity")
	if _manager == null:
		return
	var changed_cb := Callable(self,"_refresh")
	if _manager.has_signal("parity_changed") and not _manager.is_connected("parity_changed",changed_cb):
		_manager.connect("parity_changed",changed_cb)
	var encounter_cb := Callable(self,"_on_encounter_available")
	if _manager.has_signal("encounter_available") and not _manager.is_connected("encounter_available",encounter_cb):
		_manager.connect("encounter_available",encounter_cb)
	_refresh(_manager.get_snapshot())

func _toggle_panel() -> void:
	_open = not _open
	_panel.visible = _open
	if _open and _manager != null:
		_rebuild_building_panel()

func _refresh(_snapshot: Dictionary = {}) -> void:
	if _manager == null:
		return
	var tier: Dictionary = _manager.get_camp_tier()
	_tier_label.text = "%s · %d/17 зданий" % [str(tier.get("name","СТОЯНКА")), int(tier.get("buildings",0))]
	var hint := str(_manager.get_player_hint())
	_hint_label.text = ("КАК: " + hint) if not hint.is_empty() else ""
	_hint_label.visible = not hint.is_empty()
	if _open:
		_rebuild_building_panel()
	var encounter: Dictionary = _manager.get_current_encounter()
	if not encounter.is_empty():
		_show_encounter(encounter)

func _rebuild_building_panel() -> void:
	for child in _content.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "НЕДОСТАЮЩИЕ LEGACY-ЗДАНИЯ"
	title.add_theme_font_size_override("font_size",16)
	_content.add_child(title)
	for id in _manager.BUILDING_ORDER:
		var def: Dictionary = _manager.LEGACY_BUILDINGS[id]
		var level := int(_manager.get_building_level(id))
		var row := VBoxContainer.new()
		var name := Label.new()
		name.text = "%s · %s" % [str(def["name"]), ("не построено" if level <= 0 else "ур. %d" % level)]
		row.add_child(name)
		var desc := Label.new()
		desc.text = str(def["description"])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc)
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		if level <= 0:
			var cost: Dictionary = _manager.get_build_cost(id)
			button.text = "ПОСТРОИТЬ · %s" % _format_cost(cost)
			button.disabled = not bool(_manager.can_build(id))
			button.pressed.connect(func(): _manager.build(id))
		else:
			var cost: Dictionary = _manager.get_upgrade_cost(id)
			button.text = "УЛУЧШИТЬ · %s" % _format_cost(cost)
			button.disabled = not bool(_manager.can_upgrade(id))
			button.pressed.connect(func(): _manager.upgrade(id))
		row.add_child(button)
		_content.add_child(row)
		_content.add_child(HSeparator.new())

func _on_encounter_available(encounter: Dictionary) -> void:
	_show_encounter(encounter)

func _show_encounter(encounter: Dictionary) -> void:
	for child in _encounter_content.get_children():
		child.queue_free()
	var kicker := Label.new()
	kicker.text = "СОБЫТИЕ ПОСЛЕ ВОЛНЫ %d" % int(encounter.get("wave",0))
	_encounter_content.add_child(kicker)
	var title := Label.new()
	title.text = str(encounter.get("title","Событие лагеря"))
	title.add_theme_font_size_override("font_size",22)
	_encounter_content.add_child(title)
	var text := Label.new()
	text.text = str(encounter.get("text",""))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(400,60)
	_encounter_content.add_child(text)
	for choice in encounter.get("choices",[]):
		var button := Button.new()
		button.text = "%s%s" % [str(choice.get("label","Выбрать")), _reward_suffix(choice.get("rewards",{}))]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var choice_id := str(choice.get("id",""))
		button.pressed.connect(func():
			if _manager.resolve_encounter(choice_id):
				_encounter_panel.visible = false
		)
		_encounter_content.add_child(button)
	_encounter_panel.visible = true

func _format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["wood","stone","food","gold","pelts"]:
		if cost.has(key): parts.append("%s %d" % [_icon(key),int(cost[key])])
	return " · ".join(parts)
func _reward_suffix(rewards: Dictionary) -> String:
	if rewards.is_empty(): return ""
	return "  →  " + _format_cost(rewards)
func _icon(resource: String) -> String:
	match resource:
		"wood": return "🌲"
		"stone": return "🪨"
		"food": return "🍓"
		"gold": return "🪙"
		"pelts": return "🐻"
		_: return resource
