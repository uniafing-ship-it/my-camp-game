extends Control

var _player = null
var _wave_manager = null
var _health_bar: ProgressBar
var _health_label: Label
var _wave_label: Label
var _camp_label: Label
var _attack_button: Button

func _ready() -> void:
	_build_ui()
	call_deferred("_bind")

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var status_panel := PanelContainer.new()
	status_panel.anchor_left = 0.5
	status_panel.anchor_right = 0.5
	status_panel.offset_left = -150.0
	status_panel.offset_top = 16.0
	status_panel.offset_right = 150.0
	status_panel.offset_bottom = 104.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.045, 0.88)
	style.border_color = Color(0.50, 0.58, 0.68, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	status_panel.add_theme_stylebox_override("panel", style)
	add_child(status_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	status_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	_wave_label = Label.new()
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.text = "ДО НОЧИ 180с"
	_wave_label.add_theme_font_size_override("font_size", 14)
	_wave_label.add_theme_color_override("font_color", Color(0.88, 0.91, 1.0))
	box.add_child(_wave_label)

	_health_bar = ProgressBar.new()
	_health_bar.min_value = 0
	_health_bar.max_value = 100
	_health_bar.value = 100
	_health_bar.show_percentage = false
	_health_bar.custom_minimum_size = Vector2(0, 14)
	box.add_child(_health_bar)

	_health_label = Label.new()
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.text = "HP 100/100"
	_health_label.add_theme_font_size_override("font_size", 12)
	box.add_child(_health_label)

	_camp_label = Label.new()
	_camp_label.anchor_left = 0.5
	_camp_label.anchor_right = 0.5
	_camp_label.offset_left = -120.0
	_camp_label.offset_top = 108.0
	_camp_label.offset_right = 120.0
	_camp_label.offset_bottom = 132.0
	_camp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_camp_label.text = "ЛАГЕРЬ 300/300"
	_camp_label.add_theme_font_size_override("font_size", 12)
	_camp_label.add_theme_color_override("font_color", Color(0.92, 0.79, 0.57))
	add_child(_camp_label)

	_attack_button = Button.new()
	_attack_button.anchor_left = 1.0
	_attack_button.anchor_top = 1.0
	_attack_button.anchor_right = 1.0
	_attack_button.anchor_bottom = 1.0
	_attack_button.offset_left = -118.0
	_attack_button.offset_top = -132.0
	_attack_button.offset_right = -24.0
	_attack_button.offset_bottom = -38.0
	_attack_button.text = "АТАКА\n⚔"
	_attack_button.add_theme_font_size_override("font_size", 16)
	_attack_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_attack_button.pressed.connect(_on_attack_pressed)
	add_child(_attack_button)

func _bind() -> void:
	_player = get_tree().get_first_node_in_group("player_combat")
	_wave_manager = get_tree().get_first_node_in_group("raid_manager")
	if _player != null:
		if _player.has_signal("health_changed"):
			_player.connect("health_changed", Callable(self, "_on_health_changed"))
		if _player.has_signal("died"):
			_player.connect("died", Callable(self, "_on_player_died"))
		_on_health_changed(int(_player.health), int(_player.max_health))
	if _wave_manager != null:
		if _wave_manager.has_signal("timer_changed"):
			_wave_manager.connect("timer_changed", Callable(self, "_on_timer_changed"))
		if _wave_manager.has_signal("camp_health_changed"):
			_wave_manager.connect("camp_health_changed", Callable(self, "_on_camp_health_changed"))
		if _wave_manager.has_signal("game_over"):
			_wave_manager.connect("game_over", Callable(self, "_on_game_over"))
		_on_timer_changed(float(_wave_manager.next_wave_in), bool(_wave_manager.is_night), float(_wave_manager.night_seconds_left))
		_on_camp_health_changed(int(_wave_manager.camp_health), int(_wave_manager.camp_max_health))

func _on_attack_pressed() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player_combat")
	if _player != null and _player.has_method("request_attack"):
		_player.request_attack()

func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "HP %d/%d" % [current, maximum]

func _on_timer_changed(seconds_to_next: float, is_night: bool, night_left: float) -> void:
	if is_night:
		_wave_label.text = "НОЧЬ · ВОЛНА %d · %dс" % [int(_wave_manager.wave_number) if _wave_manager else 0, int(ceil(night_left))]
		_wave_label.add_theme_color_override("font_color", Color(1.0, 0.43, 0.34))
	else:
		_wave_label.text = "ДО НОЧИ %dс" % int(ceil(seconds_to_next))
		_wave_label.add_theme_color_override("font_color", Color(0.88, 0.91, 1.0))

func _on_camp_health_changed(current: int, maximum: int) -> void:
	_camp_label.text = "ЛАГЕРЬ %d/%d" % [current, maximum]

func _on_player_died() -> void:
	_health_label.text = "ГЕРОЙ ПОВЕРЖЕН · ВОЗРОЖДЕНИЕ"

func _on_game_over() -> void:
	_wave_label.text = "ЛАГЕРЬ РАЗРУШЕН"
	_wave_label.add_theme_color_override("font_color", Color(1.0, 0.18, 0.14))
	_attack_button.disabled = true
