extends CanvasLayer

const JoystickScript = preload("res://scripts/virtual_joystick.gd")
var game_manager: Node
var current_mode := "tank"
var fire_button: Button
var repair_button: Button
var flight_buttons: Array[Button] = []

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	_build_joystick()
	_build_fire_button()
	_build_repair_button()
	_build_vehicle_button()
	_build_flight_buttons()

func _process(_delta: float) -> void:
	if is_instance_valid(game_manager):
		var mode: String = str(game_manager.get("current_vehicle_mode"))
		if mode != current_mode:
			_release_vehicle_actions()
			current_mode = mode
	repair_button.visible = current_mode == "tank"
	for button in flight_buttons:
		button.visible = current_mode == "aircraft"

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
	fire_button = Button.new()
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
	fire_button.button_down.connect(_fire_down)
	fire_button.button_up.connect(_fire_up)

func _build_repair_button() -> void:
	repair_button = Button.new()
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
	if current_mode == "aircraft":
		_set_action("air_yaw_left", value.x < -0.18)
		_set_action("air_yaw_right", value.x > 0.18)
		_set_action("air_pitch_up", value.y < -0.18)
		_set_action("air_pitch_down", value.y > 0.18)
	elif current_mode == "ship":
		_set_action("ship_turn_left", value.x < -0.18)
		_set_action("ship_turn_right", value.x > 0.18)
		_set_action("ship_forward", value.y < -0.18)
		_set_action("ship_reverse", value.y > 0.18)
	else:
		_set_action("turn_left", value.x < -0.18)
		_set_action("turn_right", value.x > 0.18)
		_set_action("move_forward", value.y < -0.18)
		_set_action("move_backward", value.y > 0.18)


func _build_flight_buttons() -> void:
	_add_hold_button("КРЕН ◀", "air_roll_left", -326.0, -154.0)
	_add_hold_button("КРЕН ▶", "air_roll_right", -326.0, -94.0)
	_add_hold_button("ТЯГА +", "air_throttle_up", -326.0, -250.0)
	_add_hold_button("ТЯГА −", "air_throttle_down", -326.0, -190.0)

func _add_hold_button(caption: String, action: String, left: float, top: float) -> void:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = left
	button.offset_right = left + 138.0
	button.offset_top = top
	button.offset_bottom = top + 52.0
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.78))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.16, 0.25, 0.31, 0.94)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.28, 0.43, 0.52, 1.0)))
	add_child(button)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	button.visibility_changed.connect(func():
		if not button.visible and Input.is_action_pressed(action):
			Input.action_release(action)
	)
	flight_buttons.append(button)

func _build_vehicle_button() -> void:
	var button := Button.new()
	button.name = "VehicleSwitchButton"
	button.text = "ТЕХНИКА"
	button.focus_mode = Control.FOCUS_NONE
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.offset_left = -174.0
	button.offset_right = -24.0
	button.offset_top = 22.0
	button.offset_bottom = 78.0
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.78))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.55, 0.24, 0.08, 0.94)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.9, 0.4, 0.1, 1.0)))
	add_child(button)
	button.pressed.connect(_switch_vehicle)

func _switch_vehicle() -> void:
	if is_instance_valid(game_manager) and game_manager.has_method("switch_player_vehicle"):
		game_manager.switch_player_vehicle()

func _fire_down() -> void:
	var action := "air_fire" if current_mode == "aircraft" else "ship_fire" if current_mode == "ship" else "fire"
	Input.action_press(action)

func _fire_up() -> void:
	var action := "air_fire" if current_mode == "aircraft" else "ship_fire" if current_mode == "ship" else "fire"
	Input.action_release(action)

func _release_vehicle_actions() -> void:
	for action in ["turn_left", "turn_right", "move_forward", "move_backward", "air_yaw_left", "air_yaw_right", "air_pitch_up", "air_pitch_down", "air_roll_left", "air_roll_right", "air_throttle_up", "air_throttle_down", "ship_turn_left", "ship_turn_right", "ship_forward", "ship_reverse", "fire", "air_fire", "ship_fire"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)

func _set_action(action_name: String, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action_name):
		Input.action_press(action_name)
	elif not pressed and Input.is_action_pressed(action_name):
		Input.action_release(action_name)
