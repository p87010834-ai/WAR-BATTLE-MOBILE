extends CanvasLayer

const JoystickScript = preload("res://scripts/virtual_joystick.gd")

func _ready() -> void:
	_build_joystick()
	_build_fire_button()
	_build_repair_button()

func _build_joystick() -> void:
	var stick := Control.new()
	stick.set_script(JoystickScript)
	stick.name = "MovementJoystick"
	stick.anchor_left = 0.0
	stick.anchor_top = 1.0
	stick.anchor_right = 0.0
	stick.anchor_bottom = 1.0
	stick.offset_left = 28.0
	stick.offset_top = -218.0
	stick.offset_right = 208.0
	stick.offset_bottom = -38.0
	add_child(stick)
	stick.vector_changed.connect(_on_joystick_changed)

func _build_fire_button() -> void:
	var fire_button := Button.new()
	fire_button.name = "FireButton"
	fire_button.text = "ОГОНЬ"
	fire_button.focus_mode = Control.FOCUS_NONE
	fire_button.anchor_left = 1.0
	fire_button.anchor_top = 1.0
	fire_button.anchor_right = 1.0
	fire_button.anchor_bottom = 1.0
	fire_button.offset_left = -166.0
	fire_button.offset_top = -154.0
	fire_button.offset_right = -30.0
	fire_button.offset_bottom = -30.0
	fire_button.add_theme_font_size_override("font_size", 23)
	fire_button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.72))
	fire_button.add_theme_stylebox_override("normal", _button_style(Color(0.65, 0.20, 0.08, 0.9)))
	fire_button.add_theme_stylebox_override("pressed", _button_style(Color(0.95, 0.42, 0.10, 1.0)))
	add_child(fire_button)
	fire_button.button_down.connect(func(): Input.action_press("fire"))
	fire_button.button_up.connect(func(): Input.action_release("fire"))

func _build_repair_button() -> void:
	var repair_button := Button.new()
	repair_button.name = "RepairButton"
	repair_button.text = "РЕМОНТ"
	repair_button.focus_mode = Control.FOCUS_NONE
	repair_button.anchor_left = 1.0
	repair_button.anchor_top = 1.0
	repair_button.anchor_right = 1.0
	repair_button.anchor_bottom = 1.0
	repair_button.offset_left = -166.0
	repair_button.offset_top = -250.0
	repair_button.offset_right = -30.0
	repair_button.offset_bottom = -174.0
	repair_button.add_theme_font_size_override("font_size", 18)
	repair_button.add_theme_color_override("font_color", Color(0.9, 1.0, 0.88))
	repair_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.38, 0.22, 0.92)))
	repair_button.add_theme_stylebox_override("pressed", _button_style(Color(0.2, 0.62, 0.3, 1.0)))
	add_child(repair_button)
	repair_button.button_down.connect(func(): Input.action_press("repair"))
	repair_button.button_up.connect(func(): Input.action_release("repair"))

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.67, 0.34, 0.9)
	return style

func _on_joystick_changed(value: Vector2) -> void:
	_set_action("turn_left", value.x < -0.18)
	_set_action("turn_right", value.x > 0.18)
	_set_action("move_forward", value.y < -0.18)
	_set_action("move_backward", value.y > 0.18)

func _set_action(action_name: String, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action_name):
		Input.action_press(action_name)
	elif not pressed and Input.is_action_pressed(action_name):
		Input.action_release(action_name)
