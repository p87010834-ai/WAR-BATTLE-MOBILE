extends Control

signal vector_changed(value: Vector2)

var stick_vector := Vector2.ZERO
var active_index := -1
var knob_radius := 31.0
var base_radius := 76.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, Color(0.035, 0.045, 0.05, 0.58))
	draw_arc(center, base_radius, 0.0, TAU, 64, Color(0.95, 0.58, 0.19, 0.85), 3.0)
	draw_circle(center + stick_vector * 49.0, knob_radius, Color(0.95, 0.55, 0.16, 0.88))
	draw_arc(center + stick_vector * 49.0, knob_radius, 0.0, TAU, 48, Color(1.0, 0.78, 0.48), 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_index == -1:
			active_index = event.index
			_update_stick(event.position)
		elif not event.pressed and event.index == active_index:
			active_index = -1
			_reset_stick()
	elif event is InputEventScreenDrag and event.index == active_index:
		_update_stick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active_index = 0
			_update_stick(event.position)
		else:
			active_index = -1
			_reset_stick()
	elif event is InputEventMouseMotion and active_index == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_stick(event.position)

func _update_stick(local_position: Vector2) -> void:
	var center := size * 0.5
	stick_vector = (local_position - center) / base_radius
	if stick_vector.length() > 1.0:
		stick_vector = stick_vector.normalized()
	vector_changed.emit(stick_vector)
	queue_redraw()

func _reset_stick() -> void:
	stick_vector = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()
