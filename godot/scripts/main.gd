extends Node3D

var player: WbmTank
var enemies: Array[WbmTank] = []
var health_label: Label
var status_label: Label
var score := 0
var camera_pivot: Node3D

func _ready() -> void:
	_build_world()
	_build_hud()
	_spawn_match()

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		health_label.text = "БРОНЯ  %d%%" % roundi(player.health)
		status_label.text = "ЦЕЛЕЙ ОСТАЛОСЬ: %d     УНИЧТОЖЕНО: %d" % [enemies.size(), score]
	else:
		health_label.text = "МАШИНА УНИЧТОЖЕНА"
		status_label.text = "БОЙ ОКОНЧЕН — ПЕРЕЗАПУСК: R"

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
	add_child(camera_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 9, 14)
	camera.rotation_degrees = Vector3(-24, 0, 0)
	camera.current = true
	camera_pivot.add_child(camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.035, 0.04, 0.82)
	panel.position = Vector2(18, 16)
	panel.size = Vector2(540, 76)
	layer.add_child(panel)
	health_label = Label.new()
	health_label.position = Vector2(34, 25)
	health_label.add_theme_font_size_override("font_size", 25)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.16))
	panel.add_child(health_label)
	status_label = Label.new()
	status_label.position = Vector2(34, 58)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.86, 0.89, 0.87))
	panel.add_child(status_label)
	var help := Label.new()
	help.text = "W/S — движение    A/D — поворот    ПРОБЕЛ — огонь    R — заново"
	help.position = Vector2(22, 674)
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))
	layer.add_child(help)

func _spawn_match() -> void:
	player = _create_tank(Vector3(0, 0.15, 28), 0, true)
	for i in range(4):
		var enemy := _create_tank(Vector3(randf_range(-28, 28), 0.15, randf_range(-28, -12)), 1, false)
		enemy.target = player
		enemy.destroyed.connect(_on_enemy_destroyed)
		enemies.append(enemy)
	camera_pivot.top_level = true
	camera_pivot.global_position = player.global_position

func _create_tank(at: Vector3, faction: int, controlled: bool) -> WbmTank:
	var tank := WbmTank.new()
	tank.is_player = controlled
	tank.team = faction
	tank.position = at
	add_child(tank)
	return tank

func _on_enemy_destroyed(enemy: WbmTank) -> void:
	enemies.erase(enemy)
	score += 1
