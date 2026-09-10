extends Control
class_name UnitHUD

var _units = null
var _settlement = null
var _resources = null
var _button: Button
var _drawer: PanelContainer
var _status: Label
var _pelt_label: Label
var _buttons: Dictionary = {}
var _build_buttons: Dictionary = {}
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
	style.bg_color = Color(0.025,0.045,0.035,0.96)
	style.border_color = Color(0.46,0.62,0.42,0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0,0,0,0.38)
	style.shadow_size = 8
	return style

func _build_ui() -> void:
	_button = Button.new()
	_button.text = "ОТРЯД"
	_button.custom_minimum_size = Vector2(104,40)
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_button.pressed.connect(_toggle)
	add_child(_button)

	_drawer = PanelContainer.new()
	_drawer.visible = false
	_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer.add_theme_stylebox_override("panel", _style())
	add_child(_drawer)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",14)
	margin.add_theme_constant_override("margin_right",14)
	margin.add_theme_constant_override("margin_top",12)
	margin.add_theme_constant_override("margin_bottom",12)
	_drawer.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",7)
	margin.add_child(box)
	var title := Label.new()
	title.text = "ОТРЯД И ОХОТА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",18)
	title.add_theme_color_override("font_color", Color(0.88,0.94,0.74))
	box.add_child(title)
	_pelt_label = Label.new()
	_pelt_label.text = "🧵 Шкуры: 0"
	_pelt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_pelt_label)

	for building_id in ["hunting_lodge", "kennel"]:
		var build_button := Button.new()
		build_button.custom_minimum_size = Vector2(0,44)
		build_button.pressed.connect(_build_support.bind(building_id))
		box.add_child(build_button)
		_build_buttons[building_id] = build_button

	for kind in ["foot","hunter","dog"]:
		var recruit := Button.new()
		recruit.custom_minimum_size = Vector2(0,48)
		recruit.pressed.connect(_recruit.bind(kind))
		box.add_child(recruit)
		_buttons[kind] = recruit

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0,42)
	_status.add_theme_font_size_override("font_size",12)
	_status.add_theme_color_override("font_color",Color(0.76,0.83,0.76))
	box.add_child(_status)
	var close := Button.new()
	close.text = "ЗАКРЫТЬ"
	close.custom_minimum_size = Vector2(0,40)
	close.pressed.connect(_toggle)
	box.add_child(close)

func _layout() -> void:
	var size := get_viewport_rect().size
	_button.position = Vector2(12.0,190.0)
	_button.size = Vector2(108.0,40.0)
	var width := minf(size.x - 24.0,380.0)
	var height := minf(size.y - 250.0,430.0)
	_drawer.position = Vector2(12.0,238.0)
	_drawer.size = Vector2(width,maxf(320.0,height))

func _bind() -> void:
	_units = get_tree().get_first_node_in_group("unit_manager")
	_settlement = get_tree().get_first_node_in_group("settlement_manager")
	_resources = get_tree().get_first_node_in_group("resource_manager")
	if _units != null:
		if _units.has_signal("units_changed"): _units.connect("units_changed", Callable(self,"_on_units_changed"))
		if _units.has_signal("activity_changed"): _units.connect("activity_changed", Callable(self,"_on_activity"))
	if _settlement != null and _settlement.has_signal("settlement_changed"):
		_settlement.connect("settlement_changed", Callable(self,"_on_settlement"))
	if _resources != null and _resources.has_signal("inventory_changed"):
		_resources.connect("inventory_changed", Callable(self,"_on_inventory"))
	_refresh()

func _toggle() -> void:
	_open = not _open
	_drawer.visible = _open
	_button.text = "ЗАКРЫТЬ" if _open else "ОТРЯД"
	if _open: _refresh()

func _refresh() -> void:
	if _units == null or _settlement == null or _resources == null:
		return
	_pelt_label.text = "🧵 Шкуры: %d" % int(_resources.stored.get("pelts",0))
	for building_id in _build_buttons.keys():
		var button: Button = _build_buttons[building_id]
		var level := int(_settlement.get_building_level(str(building_id)))
		if level > 0:
			button.text = "✓ %s построена" % _building_name(str(building_id))
			button.disabled = true
		else:
			var cost: Dictionary = _settlement.get_build_cost(str(building_id))
			button.text = "Построить %s · %s" % [_building_name(str(building_id)), _cost_text(cost)]
			button.disabled = not bool(_settlement.can_build(str(building_id)))
	for kind in _buttons.keys():
		var button: Button = _buttons[kind]
		var current := int(_units.get_count(str(kind)))
		var capacity := int(_units.get_capacity(str(kind)))
		var cost: Dictionary = _units.get_recruit_cost(str(kind))
		button.text = "%s %d/%d · %s" % [_unit_name(str(kind)), current, capacity, _cost_text(cost)]
		button.disabled = not bool(_units.can_recruit(str(kind)))
	_status.text = str(_units.last_activity)

func _build_support(building_id: String) -> void:
	if _settlement != null:
		_settlement.build(building_id)
		_refresh()

func _recruit(kind: String) -> void:
	if _units != null:
		_units.recruit(kind)
		_refresh()

func _on_units_changed(_snapshot: Dictionary) -> void: _refresh()
func _on_settlement(_snapshot: Dictionary) -> void: _refresh()
func _on_inventory(_carried: Dictionary, _stored: Dictionary) -> void: _refresh()
func _on_activity(text: String) -> void:
	if _status != null: _status.text = text

func _unit_name(kind: String) -> String:
	match kind:
		"foot": return "⚔ Воин"
		"hunter": return "🏹 Охотник"
		"dog": return "🐕 Пёс"
	return kind

func _building_name(id: String) -> String:
	return "Охотничья изба" if id == "hunting_lodge" else "Псарня"

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	var names := {"wood":"🌲", "stone":"🪨", "food":"🍓", "gold":"🪙", "pelts":"🧵"}
	for key in ["wood","stone","food","gold","pelts"]:
		if int(cost.get(key,0)) > 0:
			parts.append("%s%d" % [str(names[key]), int(cost[key])])
	return " ".join(parts)
