extends Control
class_name FortificationsHUD

const BUILDING_IDS := ["stone_wall", "watchtower", "cannon", "barracks", "infirmary", "training_ground"]

var _settlement = null
var _resources = null
var _button: Button
var _drawer: PanelContainer
var _buttons: Dictionary = {}
var _status: Label
var _open := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_bind")
	call_deferred("_layout")

func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03,0.04,0.045,0.97)
	style.border_color = Color(0.58,0.52,0.39,0.90)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0,0,0,0.4)
	style.shadow_size = 8
	return style

func _build_ui() -> void:
	_button = Button.new()
	_button.text = "ОБОРОНА"
	_button.custom_minimum_size = Vector2(108,40)
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_button.pressed.connect(_toggle)
	add_child(_button)

	_drawer = PanelContainer.new()
	_drawer.visible = false
	_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer.add_theme_stylebox_override("panel", _style())
	add_child(_drawer)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_drawer.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",14)
	margin.add_theme_constant_override("margin_right",14)
	margin.add_theme_constant_override("margin_top",12)
	margin.add_theme_constant_override("margin_bottom",12)
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",7)
	margin.add_child(box)

	var title := Label.new()
	title.text = "УКРЕПЛЕНИЯ И ИНФРАСТРУКТУРА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",16)
	title.add_theme_color_override("font_color",Color(0.95,0.84,0.62))
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Стена замедляет рейдеров. Башня и пушка ведут автоматический огонь."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",11)
	hint.add_theme_color_override("font_color",Color(0.72,0.78,0.72))
	box.add_child(hint)

	for building_id in BUILDING_IDS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0,48)
		button.pressed.connect(_on_building_pressed.bind(building_id))
		box.add_child(button)
		_buttons[building_id] = button

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0,42)
	_status.add_theme_font_size_override("font_size",11)
	_status.add_theme_color_override("font_color",Color(0.74,0.82,0.74))
	box.add_child(_status)

	var close := Button.new()
	close.text = "ЗАКРЫТЬ"
	close.custom_minimum_size = Vector2(0,40)
	close.pressed.connect(_toggle)
	box.add_child(close)

func _layout() -> void:
	var size := get_viewport_rect().size
	_button.position = Vector2((size.x - 108.0) * 0.5,190.0)
	_button.size = Vector2(108.0,40.0)
	var width := minf(size.x - 24.0,400.0)
	var height := minf(size.y - 250.0,540.0)
	_drawer.position = Vector2((size.x - width) * 0.5,238.0)
	_drawer.size = Vector2(width,maxf(320.0,height))

func _bind() -> void:
	_settlement = get_tree().get_first_node_in_group("settlement_manager")
	_resources = get_tree().get_first_node_in_group("resource_manager")
	if _settlement != null:
		var changed := Callable(self,"_on_settlement_changed")
		if _settlement.has_signal("settlement_changed") and not _settlement.is_connected("settlement_changed",changed):
			_settlement.connect("settlement_changed",changed)
		var activity := Callable(self,"_on_activity")
		if _settlement.has_signal("activity_changed") and not _settlement.is_connected("activity_changed",activity):
			_settlement.connect("activity_changed",activity)
	if _resources != null and _resources.has_signal("inventory_changed"):
		var inventory := Callable(self,"_on_inventory_changed")
		if not _resources.is_connected("inventory_changed",inventory):
			_resources.connect("inventory_changed",inventory)
	_refresh()

func _toggle() -> void:
	_open = not _open
	_drawer.visible = _open
	_button.text = "ЗАКРЫТЬ" if _open else "ОБОРОНА"
	if _open:
		_refresh()

func _refresh() -> void:
	if _settlement == null or not is_instance_valid(_settlement):
		_settlement = get_tree().get_first_node_in_group("settlement_manager")
	if _settlement == null:
		return
	for building_id in BUILDING_IDS:
		var button: Button = _buttons[building_id]
		var level := int(_settlement.get_building_level(building_id))
		if level <= 0:
			var cost: Dictionary = _settlement.get_build_cost(building_id)
			button.text = "Построить %s · %s" % [_building_name(building_id),_cost_text(cost)]
			button.disabled = not bool(_settlement.can_build(building_id))
		elif level >= int(_settlement.MAX_BUILDING_LEVEL):
			button.text = "✓ %s · ур.%d · MAX" % [_building_name(building_id),level]
			button.disabled = true
		else:
			var cost: Dictionary = _settlement.get_upgrade_cost(building_id)
			button.text = "%s ур.%d → %d · %s" % [_building_name(building_id),level,level + 1,_cost_text(cost)]
			button.disabled = not bool(_settlement.can_upgrade(building_id))
	_status.text = _effects_text()

func _on_building_pressed(building_id: String) -> void:
	if _settlement == null:
		return
	if int(_settlement.get_building_level(building_id)) <= 0:
		_settlement.build(building_id)
	else:
		_settlement.upgrade(building_id)
	_refresh()

func _on_settlement_changed(_snapshot: Dictionary) -> void:
	_refresh()

func _on_inventory_changed(_carried: Dictionary, _stored: Dictionary) -> void:
	_refresh()

func _on_activity(text: String) -> void:
	if _status != null:
		_status.text = text

func _effects_text() -> String:
	var wall := int(_settlement.get_building_level("stone_wall"))
	var barracks := int(_settlement.get_building_level("barracks"))
	var infirmary := int(_settlement.get_building_level("infirmary"))
	var training := int(_settlement.get_building_level("training_ground"))
	return "Стена ур.%d · лимит воинов %d · лечение %d/с · тренировка ур.%d" % [wall,12 + barracks * 4,1 + infirmary,training]

func _building_name(id: String) -> String:
	var names := {
		"stone_wall":"Каменная стена",
		"watchtower":"Сторожевая башня",
		"cannon":"Пушка",
		"barracks":"Казарма",
		"infirmary":"Лазарет",
		"training_ground":"Тренировочный плац",
	}
	return str(names.get(id,id))

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	var names := {"wood":"🌲", "stone":"🪨", "food":"🍓", "gold":"🪙", "pelts":"🧵"}
	for key in ["wood","stone","food","gold","pelts"]:
		if int(cost.get(key,0)) > 0:
			parts.append("%s%d" % [str(names[key]),int(cost[key])])
	return " ".join(parts)
