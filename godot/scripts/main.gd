extends Node3D

var player: WbmTank
var allies: Array[WbmTank] = []
var enemies: Array[WbmTank] = []
var capture_points: Array[WbmCapturePoint] = []
var health_label: Label
var status_label: Label
var capture_label: Label
var score_label: Label
var score := 0
var team_score := [0, 0]
var match_time := 600.0
var match_over := false
var camera_pivot: Node3D
var player_spawn := Vector3(0, 0.15, 28)
var enemy_spawns := [Vector3(-26, 0.15, -24), Vector3(0, 0.15, -30), Vector3(26, 0.15, -24), Vector3(12, 0.15, -42)]
var ally_spawns := [Vector3(-9, 0.15, 23), Vector3(9, 0.15, 23)]

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_capture_points()
	_spawn_match()

func _process(delta: float) -> void:
	if match_over:
		return
	match_time = maxf(0.0, match_time - delta)
	if match_time <= 0.0 or team_score[0] >= 1000 or team_score[1] >= 1000:
		match_over = true
		status_label.text = "БОЙ ОКОНЧЕН — %s" % ("ПОБЕДА" if team_score[0] > team_score[1] else "ПОРАЖЕНИЕ" if team_score[1] > team_score[0] else "НИЧЬЯ")
		return

	var living := _get_alive_tanks()
	for point in capture_points:
		point.update_control(living, delta)
		if point.owner_team >= 0:
			team_score[point.owner_team] += int(delta * 2.0)
	var owned := 0
	for point in capture_points:
		if point.owner_team == 0:
			owned += 1
	var minutes := int(match_time) / 60
	var seconds := int(match_time) % 60
	if is_instance_valid(player):
		health_label.text = "БРОНЯ  %d%%" % roundi(player.health)
	else:
		health_label.text = "МАШИНА УНИЧТОЖЕНА — ВОЗРОЖДЕНИЕ"
	status_label.text = "ВРАГИ: %d   УНИЧТОЖЕНО: %d   ВРЕМЯ: %02d:%02d" % [enemies.size(), score, minutes, seconds]
	capture_label.text = "ТОЧКИ: %d/3   СИНИЕ %d  :  %d КРАСНЫЕ" % [owned, team_score[0], team_score[1]]
	if is_instance_valid(player):
		camera_pivot.global_position = player.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48, 0.53, 0.58)
	env.ambient_light_energy = 0.7
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	add_child(sun)

	var ground := StaticBody3D.new()
	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	ground_mesh.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.24, 0.27, 0.22)
	ground_mat.roughness = 1.0
	ground_mesh.material_override = ground_mat
	ground.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(180, 1, 180)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.5
	ground.add_child(ground_collision)
	add_child(ground)

	for i in range(22):
		var block := StaticBody3D.new()
		var mesh_instance := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		var size := Vector3(randf_range(3.0, 8.0), randf_range(2.0, 6.0), randf_range(3.0, 8.0))
		box_mesh.size = size
		mesh_instance.mesh = box_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = [Color(0.29,0.30,0.27), Color(0.34,0.32,0.28), Color(0.22,0.25,0.23)][i % 3]
		mesh_instance.material_override = mat
		block.add_child(mesh_instance)
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		block.add_child(shape_node)
		block.position = Vector3(randf_range(-65,65), size.y / 2.0, randf_range(-65,65))
		if block.position.length() < 18.0:
			block.position.x += 28.0
		add_child(block)

	camera_pivot = Node3D.new()
	camera_pivot.top_level = true
	add_child(camera_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 9, 14)
	camera.rotation_degrees = Vector3(24, 0, 0)
	camera.current = true
	camera_pivot.add_child(camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.035, 0.04, 0.84)
	panel.position = Vector2(18, 16)
	panel.size = Vector2(700, 112)
	layer.add_child(panel)
	health_label = _make_label(panel, "БРОНЯ", Vector2(16, 7), 24, Color(1.0, 0.58, 0.16))
	status_label = _make_label(panel, "", Vector2(16, 43), 16, Color(0.9, 0.92, 0.9))
	capture_label = _make_label(panel, "", Vector2(16, 76), 16, Color(0.95, 0.65, 0.25))
	var help := Label.new()
	help.text = "W/S — движение    A/D — поворот    ПРОБЕЛ — огонь    R — заново"
	help.position = Vector2(22, 674)
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))
	layer.add_child(help)
	var touch_controls := CanvasLayer.new()
	touch_controls.set_script(load("res://scripts/mobile_controls.gd"))
	add_child(touch_controls)

func _make_label(parent: Control, value: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _build_capture_points() -> void:
	for i in range(3):
		var point := WbmCapturePoint.new()
		point.point_name = ["АЛЬФА", "БРАВО", "ЧАРЛИ"][i]
		point.position = [Vector3(-32, 0.08, 0), Vector3(0, 0.08, -7), Vector3(32, 0.08, 0)][i]
		add_child(point)
		capture_points.append(point)

func _spawn_match() -> void:
	player = _create_tank(player_spawn, 0, true)
	for at in ally_spawns:
		var ally := _create_tank(at, 0, false)
		ally.target = null
		allies.append(ally)
	for at in enemy_spawns:
		var enemy := _create_tank(at, 1, false)
		enemy.target = player
		enemies.append(enemy)
	camera_pivot.global_position = player.global_position

func _create_tank(at: Vector3, faction: int, controlled: bool) -> WbmTank:
	var tank := WbmTank.new()
	tank.is_player = controlled
	tank.team = faction
	tank.position = at
	tank.destroyed.connect(_on_tank_destroyed)
	add_child(tank)
	return tank

func _get_alive_tanks() -> Array[WbmTank]:
	var result: Array[WbmTank] = []
	if is_instance_valid(player):
		result.append(player)
	for tank in allies:
		if is_instance_valid(tank):
			result.append(tank)
	for tank in enemies:
		if is_instance_valid(tank):
			result.append(tank)
	return result

func _on_tank_destroyed(tank: WbmTank) -> void:
	if tank.is_player:
		_respawn_player()
	elif tank.team == 1:
		enemies.erase(tank)
		score += 1
		_respawn_bot(1)
	else:
		allies.erase(tank)
		_respawn_bot(0)

func _respawn_player() -> void:
	await get_tree().create_timer(5.0).timeout
	if not match_over:
		player = _create_tank(player_spawn, 0, true)
		camera_pivot.global_position = player.global_position

func _respawn_bot(faction: int) -> void:
	await get_tree().create_timer(7.0).timeout
	if match_over:
		return
	if faction == 1:
		var at: Vector3 = enemy_spawns[randi() % enemy_spawns.size()]
		var enemy := _create_tank(at, 1, false)
		enemy.target = player
		enemies.append(enemy)
	else:
		var at: Vector3 = ally_spawns[randi() % ally_spawns.size()]
		var ally := _create_tank(at, 0, false)
		allies.append(ally)
