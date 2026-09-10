extends Control
class_name ProgressionHUD

var _progression = null
var _save_manager = null
var _button: Button
var _drawer: PanelContainer
var _quest_title: Label
var _quest_progress: Label
var _quest_reward: Label
var _research_buttons: Dictionary = {}
var _save_status: Label
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
	style.bg_color = Color(0.025, 0.045, 0.035, 0.96)
	style.border_color = Color(0.66, 0.54, 0.28, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 8
	return style

func _build_ui() -> void:
	_button = Button.new()
	_button.text = "РАЗВИТИЕ"
	_button.custom_minimum_size = Vector2(112, 40)
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_button.pressed.connect(_toggle)
	add_child(_button)

	_drawer = PanelContainer.new()
	_drawer.visible = false
	_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer.add_theme_stylebox_override("panel", _style())
	add_child(_drawer)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_drawer.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var title := Label.new()
	title.text = "РАЗВИТИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.96, 0.85, 0.61))
	box.add_child(title)
	var quest_header := Label.new()
	quest_header.text = "📜 ТЕКУЩЕЕ ЗАДАНИЕ"
	quest_header.add_theme_font_size_override("font_size", 13)
	box.add_child(quest_header)
	_quest_title = Label.new()
	_quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_title.add_theme_font_size_override("font_size", 15)
	box.add_child(_quest_title)
	_quest_progress = Label.new()
	_quest_progress.add_theme_color_override("font_color", Color(0.64, 0.86, 0.64))
	box.add_child(_quest_progress)
	_quest_reward = Label.new()
	_quest_reward.add_theme_color_override("font_color", Color(0.94, 0.80, 0.48))
	box.add_child(_quest_reward)
	box.add_child(HSeparator.new())
	var research_header := Label.new()
	research_header.text = "📖 ИССЛЕДОВАНИЯ"
	research_header.add_theme_font_size_override("font_size", 13)
	box.add_child(research_header)
	for research_id in ["axes", "bags", "armor", "hounds"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_on_research_pressed.bind(research_id))
		box.add_child(button)
		_research_buttons[research_id] = button
	box.add_child(HSeparator.new())
	var save_button := Button.new()
	save_button.text = "💾 СОХРАНИТЬ СЕЙЧАС"
	save_button.custom_minimum_size = Vector2(0, 42)
	save_button.pressed.connect(_on_save_pressed)
	box.add_child(save_button)
	_save_status = Label.new()
	_save_status.text = "Автосохранение каждые 10с"
	_save_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_status.add_theme_font_size_override("font_size", 11)
	box.add_child(_save_status)
	var close := Button.new()
	close.text = "ЗАКРЫТЬ"
	close.custom_minimum_size = Vector2(0, 38)
	close.pressed.connect(_toggle)
	box.add_child(close)

func _layout() -> void:
	var size := get_viewport_rect().size
	_button.position = Vector2(size.x - 132.0, 190.0)
	_button.size = Vector2(120.0, 40.0)
	var width := minf(size.x - 24.0, 390.0)
	var height := minf(size.y - 250.0, 500.0)
	_drawer.position = Vector2(size.x - width - 12.0, 238.0)
	_drawer.size = Vector2(width, maxf(360.0, height))

func _bind() -> void:
	_progression = get_tree().get_first_node_in_group("progression_manager")
	_save_manager = get_tree().get_first_node_in_group("save_manager")
	if _progression != null:
		var cb := Callable(self, "_on_progression_changed")
		if _progression.has_signal("progression_changed") and not _progression.is_connected("progression_changed", cb):
			_progression.connect("progression_changed", cb)
	if _save_manager != null:
		var save_cb := Callable(self, "_on_save_completed")
		if _save_manager.has_signal("save_completed") and not _save_manager.is_connected("save_completed", save_cb):
			_save_manager.connect("save_completed", save_cb)
		var load_cb := Callable(self, "_on_load_completed")
		if _save_manager.has_signal("load_completed") and not _save_manager.is_connected("load_completed", load_cb):
			_save_manager.connect("load_completed", load_cb)
	_refresh()

func _toggle() -> void:
	_open = not _open
	_drawer.visible = _open
	_button.text = "ЗАКРЫТЬ" if _open else "РАЗВИТИЕ"
	if _open:
		_refresh()

func _refresh() -> void:
	if _progression == null or not is_instance_valid(_progression):
		_progression = get_tree().get_first_node_in_group("progression_manager")
	if _progression == null:
		return
	var quest: Dictionary = _progression.get_current_quest()
	_quest_title.text = str(quest.get("title", ""))
	_quest_progress.text = str(quest.get("progress", ""))
	_quest_reward.text = "Награда: %s" % _reward_text(quest.get("reward", {})) if not bool(quest.get("complete", false)) else ""
	for item in _progression.get_research_snapshot():
		var research_id := str(item.get("id", ""))
		var button := _research_buttons.get(research_id) as Button
		if button == null:
			continue
		if bool(item.get("owned", false)):
			button.text = "✓ %s · %s" % [str(item.get("name", "")), str(item.get("description", ""))]
			button.disabled = true
		else:
			button.text = "%s · %s · %s" % [str(item.get("name", "")), str(item.get("description", "")), _cost_text(item.get("cost", {}))]
			button.disabled = not bool(item.get("can_buy", false))
	if _save_manager != null:
		_save_status.text = str(_save_manager.get_status_text())

func _on_research_pressed(research_id: String) -> void:
	if _progression != null and _progression.research(research_id):
		_refresh()
func _on_save_pressed() -> void:
	if _save_manager == null or not is_instance_valid(_save_manager):
		_save_manager = get_tree().get_first_node_in_group("save_manager")
	if _save_manager != null:
		_save_manager.save_game()
func _on_progression_changed(_snapshot: Dictionary) -> void: _refresh()
func _on_save_completed(success: bool, _unix_time: int) -> void: _save_status.text = "Сохранено" if success else "Ошибка сохранения"
func _on_load_completed(found: bool) -> void:
	_save_status.text = "Сохранение загружено" if found else "Новая игра · автосохранение включено"
	_refresh()
func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	var names := {"wood":"🌲", "stone":"🪨", "food":"🍓", "gold":"🪙", "pelts":"🧵"}
	for key in ["wood", "stone", "food", "gold", "pelts"]:
		if int(cost.get(key, 0)) > 0:
			parts.append("%s%d" % [str(names[key]), int(cost[key])])
	return " ".join(parts)
func _reward_text(reward: Dictionary) -> String:
	return "—" if reward.is_empty() else _cost_text(reward)
