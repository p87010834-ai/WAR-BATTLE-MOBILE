extends Node3D

var player: WbmTank
var active_vehicle: Node3D
var current_vehicle_mode := "tank"
var profile := WbmPlayerProfile.new()
var weather_manager: WbmWeatherManager
var audio_manager: WbmAudioManager
var settings := WbmSettingsManager.new()
var missions := WbmMissionSystem.new()
var achievements := WbmAchievementSystem.new()
var season := WbmSeasonProgress.new()
var replay_recorder: WbmReplayRecorder
var result_recorded := false
var allies: Array[WbmTank] = []
var enemies: Array[WbmTank] = []
var allied_aircraft: Array[WbmAircraft] = []
var enemy_aircraft: Array[WbmAircraft] = []
var allied_ships: Array[WbmShip] = []
var enemy_ships: Array[WbmShip] = []
var capture_points: Array[WbmCapturePoint] = []
var health_label: Label
var status_label: Label
var capture_label: Label
var score_label: Label
var score := 0
var team_score := [0, 0]
var score_remainder := [0.0, 0.0]
var match_time := 600.0
var weather_cycle_timer := 75.0
var weather_cycle_index := 0
var match_over := false
var camera_pivot: Node3D
var player_spawn := Vector3(0, 0.15, 28)
var enemy_spawns := [Vector3(-26, 0.15, -24), Vector3(0, 0.15, -30), Vector3(26, 0.15, -24), Vector3(12, 0.15, -42)]
var ally_spawns := [Vector3(-9, 0.15, 23), Vector3(9, 0.15, 23)]

func _ready() -> void:
	add_to_group("game_manager")
	_build_world()
	profile.load_profile()
	settings.load_settings()
	settings.apply_audio()
	audio_manager = WbmAudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	season.load()
	replay_recorder = WbmReplayRecorder.new()
	replay_recorder.name = "ReplayRecorder"
	add_child(replay_recorder)
	replay_recorder.start_recording()
	weather_manager = WbmWeatherManager.new()
	weather_manager.name = "WeatherManager"
	add_child(weather_manager)
	_build_hud()
	_build_capture_points()
	_spawn_match()

func _process(delta: float) -> void:
	if match_over:
		return
	match_time = maxf(0.0, match_time - delta)
	weather_cycle_timer -= delta
	if weather_cycle_timer <= 0.0 and is_instance_valid(weather_manager):
		weather_cycle_timer = 75.0
		weather_cycle_index = (weather_cycle_index + 1) % 4
		var weather_states := [WbmWeatherManager.Weather.CLEAR, WbmWeatherManager.Weather.OVERCAST, WbmWeatherManager.Weather.RAIN, WbmWeatherManager.Weather.FOG]
		weather_manager.set_weather(weather_states[weather_cycle_index], [0.0, 0.42, 0.62, 0.78][weather_cycle_index])
	if match_time <= 0.0 or team_score[0] >= 1000 or team_score[1] >= 1000:
		match_over = true
		var won: bool = int(team_score[0]) > int(team_score[1])
		if not result_recorded:
			result_recorded = true
			profile.add_battle_result(won)
			missions.add_progress("play_3")
			achievements.unlock("first_battle")
			if won:
				achievements.unlock("first_victory")
			season.add_xp(100 if won else 50)
			replay_recorder.stop_recording()
			replay_recorder.save_replay()
		status_label.text = "БОЙ ОКОНЧЕН — %s" % ("ПОБЕДА" if team_score[0] > team_score[1] else "ПОРАЖЕНИЕ" if team_score[1] > team_score[0] else "НИЧЬЯ")
		var ui_manager := get_tree().get_first_node_in_group("game_ui_manager")
		if ui_manager and ui_manager.has_method("show_match_results"):
			ui_manager.show_match_results(won, team_score[0], team_score[1])
		return

	var living := _get_alive_combat_vehicles()
	for point in capture_points:
		point.update_control(living, delta)
		if point.owner_team >= 0:
			score_remainder[point.owner_team] += delta * 2.0
			if score_remainder[point.owner_team] >= 1.0:
				var gained := int(score_remainder[point.owner_team])
				team_score[point.owner_team] += gained
				score_remainder[point.owner_team] -= float(gained)
	var owned := 0
	for point in capture_points:
		if point.owner_team == 0:
			owned += 1
	var minutes := int(match_time) / 60
	var seconds := int(match_time) % 60
	if is_instance_valid(player):
		health_label.text = "БРОНЯ  %d%%   |   %s" % [roundi(player.health), player.module_status]
	else:
		health_label.text = "МАШИНА УНИЧТОЖЕНА — ВОЗРОЖДЕНИЕ"
	status_label.text = "ВРАГИ: %d   УНИЧТОЖЕНО: %d   ВРЕМЯ: %02d:%02d" % [enemies.size(), score, minutes, seconds]
	capture_label.text = "ТОЧКИ: %d/3   СИНИЕ %d  :  %d КРАСНЫЕ" % [owned, team_score[0], team_score[1]]
	if is_instance_valid(active_vehicle):
		camera_pivot.global_position = active_vehicle.global_position
		var active_health := float(active_vehicle.get("health"))
		var health_percent := roundi(active_health / float(active_vehicle.get("max_health")) * 100.0)
		if active_vehicle is WbmAircraft:
			var plane := active_vehicle as WbmAircraft
			health_label.text = "САМОЛЁТ  %d%%  |  СКОРОСТЬ %d  |  ВЫСОТА %d м" % [health_percent, roundi(plane.speed), roundi(plane.global_position.y)]
		elif active_vehicle is WbmShip:
			var vessel := active_vehicle as WbmShip
			health_label.text = "КОРАБЛЬ  %d%%  |  СКОРОСТЬ %.1f  |  %s" % [health_percent, vessel.current_speed, vessel.module_status]
		else:
			health_label.text = "ТАНК  %d%%  |  %s" % [health_percent, (active_vehicle as WbmTank).module_status]
	for tank_index in range(_get_alive_tanks().size()):
		var tank := _get_alive_tanks()[tank_index]
		if is_instance_valid(tank):
			var tank_id := "player_tank" if tank == player else ("tank_blue_%d" % tank_index if tank.team == 0 else "tank_red_%d" % tank_index)
			replay_recorder.record_vehicle(tank, tank_id, tank.team, tank.health)
	for aircraft_index in range(allied_aircraft.size()):
		var aircraft := allied_aircraft[aircraft_index]
		if is_instance_valid(aircraft) and aircraft.health > 0.0:
			replay_recorder.record_vehicle(aircraft, "aircraft_blue_%d" % aircraft_index, aircraft.team, aircraft.health)
	for aircraft_index in range(enemy_aircraft.size()):
		var aircraft := enemy_aircraft[aircraft_index]
		if is_instance_valid(aircraft) and aircraft.health > 0.0:
			replay_recorder.record_vehicle(aircraft, "aircraft_red_%d" % aircraft_index, aircraft.team, aircraft.health)
	for ship_index in range(allied_ships.size()):
		var vessel := allied_ships[ship_index]
		if is_instance_valid(vessel) and vessel.health > 0.0:
			replay_recorder.record_vehicle(vessel, "ship_blue_%d" % ship_index, vessel.team, vessel.health)
	for ship_index in range(enemy_ships.size()):
		var vessel := enemy_ships[ship_index]
		if is_instance_valid(vessel) and vessel.health > 0.0:
			replay_recorder.record_vehicle(vessel, "ship_red_%d" % ship_index, vessel.team, vessel.health)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.035, 0.105, 0.19)
	sky_material.sky_horizon_color = Color(0.39, 0.49, 0.53)
	sky_material.ground_bottom_color = Color(0.075, 0.085, 0.09)
	sky_material.ground_horizon_color = Color(0.24, 0.29, 0.30)
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.43, 0.39)
	env.ambient_light_energy = 0.82
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.37, 0.44, 0.42)
	env.fog_density = 0.0018
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_strength = 0.38
	env.ssao_enabled = true
	env.ssao_radius = 1.6
	env.ssao_intensity = 1.35
	env.ssao_power = 1.25
	env.ssil_enabled = true
	env.ssil_radius = 3.0
	env.ssil_intensity = 0.55
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 115.0
	sun.directional_shadow_fade_start = 0.82
	sun.shadow_bias = 0.035
	sun.shadow_normal_bias = 1.1
	add_child(sun)

	var ground := StaticBody3D.new()
	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	ground_mesh.mesh = plane
	var ground_shader := Shader.new()
	ground_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = world_pos.xz * 0.115;
	float broad = noise2(p);
	float medium = noise2(p * 4.8);
	float fine = noise2(p * 19.0);
	float grain = hash21(floor(world_pos.xz * 34.0));
	float n = broad * 0.48 + medium * 0.30 + fine * 0.16 + grain * 0.06;
	vec3 dark_soil = vec3(0.075, 0.088, 0.075);
	vec3 earth = vec3(0.145, 0.145, 0.115);
	vec3 grass = vec3(0.205, 0.235, 0.155);
	vec3 dry_grass = vec3(0.29, 0.245, 0.165);
	vec3 col = mix(dark_soil, earth, smoothstep(0.16, 0.58, n));
	col = mix(col, grass, smoothstep(0.42, 0.76, n));
	col = mix(col, dry_grass, smoothstep(0.72, 0.96, n) * 0.48);
	float flecks = smoothstep(0.76, 0.98, fine) * 0.12;
	col = mix(col, vec3(0.34, 0.32, 0.25), flecks);
	float damp = smoothstep(0.35, 0.7, broad) * (1.0 - smoothstep(0.68, 0.9, medium));
	col *= 1.0 - damp * 0.13;
	ALBEDO = col;
	ROUGHNESS = 0.98;
}
"""
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = ground_shader
	ground_mesh.material_override = ground_mat
	ground.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(180, 1, 180)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.5
	ground.add_child(ground_collision)
	add_child(ground)

	var ocean := MeshInstance3D.new()
	var ocean_mesh := PlaneMesh.new()
	ocean_mesh.size = Vector2(100, 38)
	ocean.mesh = ocean_mesh
	ocean.position = Vector3(0, 0.035, -69)
	var ocean_material := StandardMaterial3D.new()
	var water_shader := Shader.new()
	water_shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec3 deep_color : source_color = vec3(0.012, 0.075, 0.12);
uniform vec3 shallow_color : source_color = vec3(0.055, 0.23, 0.28);
void vertex() {
	float wave_a = sin(VERTEX.x * 0.19 + TIME * 1.25) * 0.13;
	float wave_b = cos(VERTEX.z * 0.24 - TIME * 0.82) * 0.10;
	float wave_c = sin((VERTEX.x + VERTEX.z) * 0.11 + TIME * 0.6) * 0.07;
	VERTEX.y += wave_a + wave_b + wave_c;
}
void fragment() {
	float ripple = sin(UV.x * 145.0 + TIME * 1.8) * cos(UV.y * 105.0 - TIME) * 0.035;
	ALBEDO = mix(deep_color, shallow_color, clamp(UV.y * 0.55 + 0.28 + ripple, 0.0, 1.0));
	METALLIC = 0.24;
	ROUGHNESS = 0.2;
}
"""
	var water_material := ShaderMaterial.new()
	water_material.shader = water_shader
	ocean.material_override = water_material
	add_child(ocean)

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

	_add_environment_props()
	var battlefield := WbmBattlefieldEnvironment.new()
	battlefield.name = "BattlefieldEnvironment"
	add_child(battlefield)
	camera_pivot = Node3D.new()
	camera_pivot.top_level = true
	add_child(camera_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 9, 14)
	camera.rotation_degrees = Vector3(24, 0, 0)
	camera.current = true
	camera_pivot.add_child(camera)


func _add_environment_props() -> void:
	var rock_materials: Array[StandardMaterial3D] = []
	for color in [Color(0.20, 0.22, 0.21), Color(0.29, 0.28, 0.24), Color(0.16, 0.19, 0.18)]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.98
		rock_materials.append(material)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.19, 0.13, 0.085)
	bark.roughness = 1.0
	var pine := StandardMaterial3D.new()
	pine.albedo_color = Color(0.075, 0.13, 0.095)
	pine.roughness = 1.0
	for i in range(26):
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.7, 2.0)
		mesh.height = mesh.radius * randf_range(0.45, 0.9)
		rock.mesh = mesh
		rock.material_override = rock_materials[i % rock_materials.size()]
		rock.position = Vector3(randf_range(-78.0, 78.0), mesh.height * 0.25, randf_range(-76.0, 68.0))
		rock.scale = Vector3(randf_range(0.8, 1.5), 1.0, randf_range(0.8, 1.4))
		if Vector2(rock.position.x, rock.position.z - 18.0).length() > 24.0:
			add_child(rock)
	for i in range(18):
		var tree := Node3D.new()
		tree.position = Vector3(randf_range(-82.0, 82.0), 0.0, randf_range(-76.0, 62.0))
		if Vector2(tree.position.x, tree.position.z - 18.0).length() < 34.0:
			continue
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.16
		trunk_mesh.bottom_radius = 0.28
		trunk_mesh.height = randf_range(2.5, 4.0)
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height * 0.5
		trunk.material_override = bark
		tree.add_child(trunk)
		for tier in range(3):
			var crown := MeshInstance3D.new()
			var crown_mesh := CylinderMesh.new()
			crown_mesh.top_radius = 0.0
			crown_mesh.bottom_radius = 1.7 - tier * 0.34
			crown_mesh.height = 2.6
			crown.mesh = crown_mesh
			crown.position.y = 2.1 + tier * 1.45
			crown.material_override = pine
			tree.add_child(crown)
		add_child(tree)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.035, 0.04, 0.84)
	panel.anchor_right = 1.0
	panel.offset_left = 18.0
	panel.offset_top = 16.0
	panel.offset_right = -18.0
	panel.offset_bottom = 128.0
	layer.add_child(panel)
	health_label = _make_label(panel, "БРОНЯ", Vector2(16, 7), 24, Color(1.0, 0.58, 0.16))
	status_label = _make_label(panel, "", Vector2(16, 43), 16, Color(0.9, 0.92, 0.9))
	capture_label = _make_label(panel, "", Vector2(16, 76), 16, Color(0.95, 0.65, 0.25))
	var help := Label.new()
	help.text = "W/S — движение    A/D — поворот    ПРОБЕЛ — огонь    R — заново"
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_left = 22.0
	help.offset_top = -42.0
	help.offset_right = -18.0
	help.offset_bottom = -12.0
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))
	layer.add_child(help)
	var touch_controls := CanvasLayer.new()
	touch_controls.set_script(load("res://scripts/mobile_controls.gd"))
	add_child(touch_controls)
	var game_ui := CanvasLayer.new()
	game_ui.set_script(load("res://scripts/ui_manager.gd"))
	add_child(game_ui)

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
		point.captured.connect(_on_capture_point_captured)
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
	_spawn_air_support()
	_spawn_naval_battle()
	active_vehicle = player
	camera_pivot.global_position = player.global_position

func _spawn_air_support() -> void:
	var friendly_air := WbmAircraft.new()
	friendly_air.team = 0
	friendly_air.position = Vector3(-18, 30, 18)
	friendly_air.speed = 62.0
	friendly_air.target = enemies[0] if not enemies.is_empty() else null
	friendly_air.destroyed.connect(_on_aircraft_destroyed)
	add_child(friendly_air)
	allied_aircraft.append(friendly_air)

	var hostile_air := WbmAircraft.new()
	hostile_air.team = 1
	hostile_air.position = Vector3(18, 34, -18)
	hostile_air.rotation.y = PI
	hostile_air.speed = 62.0
	hostile_air.target = player
	hostile_air.destroyed.connect(_on_aircraft_destroyed)
	add_child(hostile_air)
	enemy_aircraft.append(hostile_air)

func _on_aircraft_destroyed(vehicle: WbmAircraft) -> void:
	if vehicle.is_player:
		_switch_to_tank()
	if vehicle.team == 1:
		enemy_aircraft.erase(vehicle)
		score += 1
		_respawn_aircraft(1)
	else:
		allied_aircraft.erase(vehicle)
		_respawn_aircraft(0)

func _respawn_aircraft(faction: int) -> void:
	await get_tree().create_timer(12.0).timeout
	if match_over:
		return
	var aircraft := WbmAircraft.new()
	aircraft.team = faction
	aircraft.position = Vector3(-20 if faction == 0 else 20, 32, 22 if faction == 0 else -22)
	aircraft.rotation.y = PI if faction == 1 else 0.0
	aircraft.speed = 62.0
	aircraft.target = player if faction == 1 else (enemies[0] if not enemies.is_empty() else null)
	aircraft.destroyed.connect(_on_aircraft_destroyed)
	add_child(aircraft)
	if faction == 1:
		enemy_aircraft.append(aircraft)
	else:
		allied_aircraft.append(aircraft)

func _spawn_naval_battle() -> void:
	var friendly_ship := WbmShip.new()
	friendly_ship.team = 0
	friendly_ship.position = Vector3(-24, 1.25, -69)
	friendly_ship.rotation.y = -PI / 2.0
	friendly_ship.destroyed.connect(_on_ship_destroyed)
	add_child(friendly_ship)
	allied_ships.append(friendly_ship)

	var hostile_ship := WbmShip.new()
	hostile_ship.team = 1
	hostile_ship.position = Vector3(24, 1.25, -69)
	hostile_ship.rotation.y = PI / 2.0
	hostile_ship.destroyed.connect(_on_ship_destroyed)
	add_child(hostile_ship)
	enemy_ships.append(hostile_ship)

func _on_ship_destroyed(vessel: WbmShip) -> void:
	if vessel.is_player:
		_switch_to_tank()
	if vessel.team == 1:
		enemy_ships.erase(vessel)
		score += 1
		_respawn_ship(1)
	else:
		allied_ships.erase(vessel)
		_respawn_ship(0)

func _respawn_ship(faction: int) -> void:
	await get_tree().create_timer(18.0).timeout
	if match_over:
		return
	var vessel := WbmShip.new()
	vessel.team = faction
	vessel.position = Vector3(-24 if faction == 0 else 24, 1.25, -69)
	vessel.rotation.y = -PI / 2.0 if faction == 0 else PI / 2.0
	vessel.destroyed.connect(_on_ship_destroyed)
	add_child(vessel)
	if faction == 0:
		allied_ships.append(vessel)
	else:
		enemy_ships.append(vessel)

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
	if is_instance_valid(player) and player.health > 0.0:
		result.append(player)
	for tank in allies:
		if is_instance_valid(tank) and tank.health > 0.0:
			result.append(tank)
	for tank in enemies:
		if is_instance_valid(tank) and tank.health > 0.0:
			result.append(tank)
	return result

func _get_alive_combat_vehicles() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for vehicle in get_tree().get_nodes_in_group("combat_vehicles"):
		if is_instance_valid(vehicle) and vehicle is Node3D and float(vehicle.get("health")) > 0.0:
			result.append(vehicle as Node3D)
	return result

func _on_capture_point_captured(team: int) -> void:
	if team == 0:
		missions.add_progress("capture_3")

func _on_tank_destroyed(tank: WbmTank) -> void:
	# The player's tank remains the persistent player vehicle while another vehicle is controlled.
	if tank == player:
		_respawn_player()
	elif tank.team == 1:
		enemies.erase(tank)
		score += 1
		missions.add_progress("destroy_5")
		if score >= 10:
			achievements.unlock("tank_ace")
		_respawn_bot(1)
	else:
		allies.erase(tank)
		_respawn_bot(0)

func _respawn_player() -> void:
	await get_tree().create_timer(5.0).timeout
	if not match_over:
		player = _create_tank(player_spawn, 0, true)
		active_vehicle = player
		current_vehicle_mode = "tank"
		camera_pivot.global_position = player.global_position
		_update_vehicle_hud()

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


func select_vehicle_from_hangar(vehicle_class: String) -> bool:
	if match_over:
		return false
	match vehicle_class:
		"tank":
			if is_instance_valid(player) and player.health > 0.0:
				_set_player_vehicle(player, "tank")
				return true
		"aircraft":
			for aircraft in allied_aircraft:
				if is_instance_valid(aircraft) and aircraft.health > 0.0:
					_set_player_vehicle(aircraft, "aircraft")
					return true
		"ship":
			for vessel in allied_ships:
				if is_instance_valid(vessel) and vessel.health > 0.0:
					_set_player_vehicle(vessel, "ship")
					return true
	return false

func switch_player_vehicle() -> void:
	if match_over:
		return
	if current_vehicle_mode == "tank":
		if not allied_aircraft.is_empty() and is_instance_valid(allied_aircraft[0]):
			_set_player_vehicle(allied_aircraft[0], "aircraft")
		elif not allied_ships.is_empty() and is_instance_valid(allied_ships[0]):
			_set_player_vehicle(allied_ships[0], "ship")
	elif current_vehicle_mode == "aircraft":
		if not allied_ships.is_empty() and is_instance_valid(allied_ships[0]):
			_set_player_vehicle(allied_ships[0], "ship")
		else:
			_switch_to_tank()
	else:
		_switch_to_tank()

func _set_player_vehicle(vehicle: Node3D, mode: String) -> void:
	if is_instance_valid(active_vehicle):
		active_vehicle.set("is_player", false)
		if active_vehicle is WbmTank:
			(active_vehicle as WbmTank).target = enemies[0] if not enemies.is_empty() else null
		elif active_vehicle is WbmAircraft:
			(active_vehicle as WbmAircraft).target = enemies[0] if not enemies.is_empty() else null
	vehicle.set("is_player", true)
	active_vehicle = vehicle
	current_vehicle_mode = mode
	camera_pivot.global_position = vehicle.global_position
	_update_vehicle_hud()

func _switch_to_tank() -> void:
	if not is_instance_valid(player):
		return
	if is_instance_valid(active_vehicle) and active_vehicle != player:
		active_vehicle.set("is_player", false)
	player.is_player = true
	active_vehicle = player
	current_vehicle_mode = "tank"
	camera_pivot.global_position = player.global_position
	_update_vehicle_hud()

func _vehicle_mode_label() -> String:
	match current_vehicle_mode:
		"aircraft":
			return "САМОЛЁТ"
		"ship":
			return "КОРАБЛЬ"
		_:
			return "ТАНК"

func _update_vehicle_hud() -> void:
	if is_instance_valid(status_label):
		status_label.text = "УПРАВЛЕНИЕ: %s  |  КНОПКА «ТЕХНИКА» — СМЕНА" % _vehicle_mode_label()
