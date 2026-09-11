extends Control
class_name MetaProgressionHUD

var _meta = null
var _button: Button
var _drawer: PanelContainer
var _hero_label: Label
var _fame_label: Label
var _slot_labels: Array[Label] = []
var _expedition_buttons: Dictionary = {}
var _relic_label: Label
var _achievement_label: Label
var _ascend_button: Button
var _ascend_info: Label
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
	style.bg_color = Color(0.025, 0.038, 0.034, 0.975)
	style.border_color = Color(0.72, 0.50, 0.24, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 9
	return style

func _build_ui() -> void:
	_button = Button.new()
	_button.text = "ПОХОДЫ"
	_button.custom_minimum_size = Vector2(112, 40)
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
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var title := Label.new()
	title.text = "ЭКСПЕДИЦИИ И ВОСХОЖДЕНИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.55))
	box.add_child(title)

	_hero_label = Label.new()
	_hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hero_label)
	_fame_label = Label.new()
	_fame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fame_label.add_theme_color_override("font_color", Color(0.95, 0.68, 0.36))
	box.add_child(_fame_label)

	box.add_child(HSeparator.new())
	var slot_header := Label.new()
	slot_header.text = "🗺 СЛОТЫ ЭКСПЕДИЦИЙ"
	slot_header.add_theme_font_size_override("font_size", 13)
	box.add_child(slot_header)
	for i in range(3):
		var slot_label := Label.new()
		slot_label.text = "Слот %d: свободен" % (i + 1)
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_label.add_theme_font_size_override("font_size", 12)
		box.add_child(slot_label)
		_slot_labels.append(slot_label)

	for expedition_id in ["scout", "supplies", "ruins"]:
		var expedition_button := Button.new()
		expedition_button.custom_minimum_size = Vector2(0, 48)
		expedition_button.pressed.connect(_on_expedition_pressed.bind(expedition_id))
		box.add_child(expedition_button)
		_expedition_buttons[expedition_id] = expedition_button

	box.add_child(HSeparator.new())
	var relic_header := Label.new()
	relic_header.text = "🏺 РЕЛИКВИИ"
	relic_header.add_theme_font_size_override("font_size", 13)
	box.add_child(relic_header)
	_relic_label = Label.new()
	_relic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_relic_label.add_theme_font_size_override("font_size", 12)
	box.add_child(_relic_label)

	var achievement_header := Label.new()
	achievement_header.text = "🏆 ДОСТИЖЕНИЯ"
	achievement_header.add_theme_font_size_override("font_size", 13)
	box.add_child(achievement_header)
	_achievement_label = Label.new()
	_achievement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_achievement_label.add_theme_font_size_override("font_size", 12)
	box.add_child(_achievement_label)

	box.add_child(HSeparator.new())
	var ascend_header := Label.new()
	ascend_header.text = "🔥 ВОСХОЖДЕНИЕ"
	ascend_header.add_theme_font_size_override("font_size", 13)
	box.add_child(ascend_header)
	_ascend_info = Label.new()
	_ascend_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ascend_info.add_theme_font_size_override("font_size", 12)
	box.add_child(_ascend_info)
	_ascend_button = Button.new()
	_ascend_button.text = "🔥 ВОСХОЖДЕНИЕ"
	_ascend_button.custom_minimum_size = Vector2(0, 44)
	_ascend_button.pressed.connect(_on_ascend_pressed)
	box.add_child(_ascend_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", Color(0.74, 0.82, 0.74))
	box.add_child(_status)

	var close := Button.new()
	close.text = "ЗАКРЫТЬ"
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(_toggle)
	box.add_child(close)

func _layout() -> void:
	var size := get_viewport_rect().size
	_button.position = Vector2((size.x - 112.0) * 0.5, 142.0)
	_button.size = Vector2(112.0, 40.0)
	var width := minf(size.x - 24.0, 430.0)
	var height := minf(size.y - 205.0, 590.0)
	_drawer.position = Vector2((size.x - width) * 0.5, 190.0)
	_drawer.size = Vector2(width, maxf(330.0, height))

func _bind() -> void:
	_meta = get_tree().get_first_node_in_group("meta_progression_manager")
	if _meta != null:
		for signal_name in ["meta_changed", "activity_changed", "expedition_started", "expedition_finished", "achievement_unlocked", "relic_unlocked", "ascended"]:
			if _meta.has_signal(signal_name):
				var cb := Callable(self, "_on_meta_event")
				if signal_name == "activity_changed":
					cb = Callable(self, "_on_activity")
				if not _meta.is_connected(signal_name, cb):
					_meta.connect(signal_name, cb)
	_refresh()

func _toggle() -> void:
	_open = not _open
	_drawer.visible = _open
	_button.text = "ЗАКРЫТЬ" if _open else "ПОХОДЫ"
	if _open:
		_refresh()

func _refresh() -> void:
	if _meta == null or not is_instance_valid(_meta):
		_meta = get_tree().get_first_node_in_group("meta_progression_manager")
	if _meta == null:
		return
	var snapshot: Dictionary = _meta.get_snapshot()
	_hero_label.text = "⭐ Герой ур.%d · XP %d/%d" % [int(snapshot.get("hero_level", 1)), int(snapshot.get("hero_xp", 0)), int(snapshot.get("hero_xp_needed", 1))]
	var ascension: Dictionary = snapshot.get("ascension", {})
	_fame_label.text = "🔥 Слава %d · производство +%d%% · урон +%d%%" % [int(snapshot.get("fame", 0)), int(ascension.get("production_bonus_percent", 0)), int(ascension.get("damage_bonus_percent", 0))]

	var expeditions: Dictionary = snapshot.get("expeditions", {})
	var slots: Array = expeditions.get("slots", [])
	for i in range(_slot_labels.size()):
		var label: Label = _slot_labels[i]
		if i >= slots.size() or not bool((slots[i] as Dictionary).get("active", false)):
			label.text = "Слот %d: свободен" % (i + 1)
			continue
		var slot: Dictionary = slots[i]
		var expedition_id := str(slot.get("id", ""))
		var name := expedition_id
		if _meta.EXPEDITIONS.has(expedition_id):
			name = str(_meta.EXPEDITIONS[expedition_id]["name"])
		var left := maxf(0.0, float(slot.get("duration", 0.0)) - float(slot.get("elapsed", 0.0)))
		label.text = "Слот %d: %s · %dс" % [i + 1, name, int(ceil(left))]

	for item in expeditions.get("definitions", []):
		var expedition_id := str(item.get("id", ""))
		var button := _expedition_buttons.get(expedition_id) as Button
		if button == null:
			continue
		button.text = "%s · %s · %dс" % [str(item.get("name", "")), str(item.get("description", "")), int(float(item.get("duration", 0.0)))]
		button.disabled = not bool(item.get("can_start", false))

	var relic_parts: Array[String] = []
	for item in _meta.get_relic_snapshot():
		if bool(item.get("owned", false)):
			relic_parts.append("%s %s — %s" % [str(item.get("icon", "")), str(item.get("name", "")), str(item.get("description", ""))])
	_relic_label.text = "Нет реликвий" if relic_parts.is_empty() else "\n".join(relic_parts)

	var achievement_parts: Array[String] = []
	var total := 0
	for item in _meta.get_achievement_snapshot():
		total += 1
		if bool(item.get("owned", false)):
			achievement_parts.append("✓ %s" % str(item.get("name", "")))
	_achievement_label.text = "%d/%d получено%s" % [achievement_parts.size(), total, "\n" + " · ".join(achievement_parts) if not achievement_parts.is_empty() else ""]

	_ascend_info.text = "Построено %d/%d · за Восхождение +%d Славы. Слава сохраняется; лагерь, ресурсы, исследования, герой и реликвии сбрасываются." % [int(ascension.get("built", 0)), int(ascension.get("required", 12)), int(ascension.get("fame_gain", 0))]
	_ascend_button.disabled = not bool(ascension.get("can_ascend", false))
	_status.text = str(snapshot.get("last_activity", ""))

func _on_expedition_pressed(expedition_id: String) -> void:
	if _meta != null:
		_meta.start_expedition(expedition_id)
		_refresh()

func _on_ascend_pressed() -> void:
	if _meta != null:
		_meta.ascend()
		_refresh()

func _on_meta_event(_a = null, _b = null, _c = null) -> void:
	_refresh()

func _on_activity(text: String) -> void:
	if _status != null:
		_status.text = text
	_refresh()
