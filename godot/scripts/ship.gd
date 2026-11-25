extends CharacterBody3D
class_name WbmShip

signal destroyed(vessel: WbmShip)
signal module_damaged(module_name: String, remaining: float)

@export var team := 0
@export var max_health := 300.0
@export var cruise_speed := 8.0
@export var turn_rate := 0.42
@export var acceleration := 2.8
@export var deceleration := 3.8

var health := 300.0
var is_player := false
var weapon_cooldown := 0.0
var target: Node3D
var current_speed := 0.0
var engine_health := 100.0
var steering_health := 100.0
var weapons_health := 100.0
var module_status := "ВСЕ СИСТЕМЫ ИСПРАВНЫ"
var _destroyed_emitted := false
var repair_tick := 0.0
var wake_timer := 0.0
var _hull_material: StandardMaterial3D
var _visual_root: Node3D
var _wave_phase := 0.0
var _turn_visual := 0.0

func _ready() -> void:
	add_to_group("combat_vehicles")
	add_to_group("naval_vehicles")
	health = max_health
	_build_ship()
	var audio := get_tree().get_first_node_in_group("wbm_audio_manager")
	if audio:
		audio.attach_engine(self, "ship")

func _process(delta: float) -> void:
	_wave_phase += delta
	if not is_instance_valid(_visual_root):
		return
	var speed_ratio := clampf(absf(current_speed) / maxf(cruise_speed, 0.1), 0.0, 1.0)
	var wave_a := sin(_wave_phase * 1.15 + float(get_instance_id() % 17)) 
	var wave_b := sin(_wave_phase * 1.73 + 1.2)
	_visual_root.position.y = 0.12 + wave_a * 0.075 + wave_b * 0.035
	_visual_root.rotation.x = wave_b * 0.012 * (0.35 + speed_ratio)
	_visual_root.rotation.z = _turn_visual * 0.035 * speed_ratio + wave_a * 0.009
	_turn_visual = move_toward(_turn_visual, 0.0, delta * 1.8)

func _physics_process(delta: float) -> void:
	weapon_cooldown = maxf(0.0, weapon_cooldown - delta)
	if health <= 0.0:
		velocity = Vector3.ZERO
		return

	var throttle := 0.0
	if is_player:
		if Input.is_action_pressed("ship_repair"):
			repair_tick += delta
			if repair_tick >= 1.0:
				repair_tick = 0.0
				repair_modules(4.0)
		else:
			repair_tick = 0.0
		var steering := Input.get_action_strength("ship_turn_left") - Input.get_action_strength("ship_turn_right")
		throttle = Input.get_action_strength("ship_forward") - Input.get_action_strength("ship_reverse")
		var steering_factor := clampf(steering_health / 100.0, 0.0, 1.0)
		var turn_input := steering * steering_factor * (0.35 + absf(current_speed) / maxf(cruise_speed, 0.1))
		rotation.y += turn_input * turn_rate * delta
		_turn_visual = turn_input
		if Input.is_action_just_pressed("ship_fire"):
			fire_guns()
	else:
		throttle = _ai_naval_combat(delta)

	var engine_factor := clampf(engine_health / 100.0, 0.0, 1.0)
	var target_speed := throttle * cruise_speed * engine_factor
	var rate := acceleration if absf(target_speed) > absf(current_speed) else deceleration
	current_speed = move_toward(current_speed, target_speed, rate * delta)
	velocity = -global_transform.basis.z * current_speed
	move_and_slide()
	_update_wake(delta)


func _update_wake(delta: float) -> void:
	wake_timer -= delta
	if absf(current_speed) < 1.4 or wake_timer > 0.0:
		return
	wake_timer = 0.42
	var wake := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(2.0, 4.8)
	wake.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.55, 0.72, 0.76, 0.28)
	material.roughness = 0.25
	wake.material_override = material
	get_tree().current_scene.add_child(wake)
	wake.global_position = global_position + global_transform.basis.z * 7.2 + Vector3.UP * 0.09
	wake.global_rotation.y = global_rotation.y
	var tween := get_tree().create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 3.0)
	tween.tween_callback(wake.queue_free)

func _ai_naval_combat(delta: float) -> float:
	if not is_instance_valid(target) or not target.is_in_group("naval_vehicles") or float(target.get("health")) <= 0.0:
		target = _find_enemy_ship()
	if not is_instance_valid(target):
		return 0.2
	var to_target := target.global_position - global_position
	var desired_yaw := atan2(-to_target.x, -to_target.z)
	var difference := wrapf(desired_yaw - rotation.y, -PI, PI)
	var steering_factor := clampf(steering_health / 100.0, 0.0, 1.0)
	var turn_delta := wrapf(desired_yaw - rotation.y, -PI, PI)
	rotation.y = rotate_toward(rotation.y, desired_yaw, turn_rate * steering_factor * delta)
	_turn_visual = clampf(turn_delta * 1.8, -1.0, 1.0)
	if to_target.length() <= 72.0 and absf(difference) < 0.34:
		fire_guns()
	return 0.65

func _find_enemy_ship() -> Node3D:
	var best: Node3D
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("naval_vehicles"):
		if not is_instance_valid(candidate) or int(candidate.get("team")) == team or float(candidate.get("health")) <= 0.0:
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate as Node3D
	return best

func fire_guns() -> void:
	if weapon_cooldown > 0.0 or weapons_health <= 0.0 or health <= 0.0:
		return
	weapon_cooldown = 2.4 if weapons_health > 45.0 else 4.0
	var audio := get_tree().get_first_node_in_group("wbm_audio_manager")
	if audio:
		audio.play_event("naval", global_position, 0.0)
	if is_instance_valid(target) and target.has_method("apply_damage"):
		var distance := global_position.distance_to(target.global_position)
		var forward := -global_transform.basis.z
		var direction := (target.global_position - global_position).normalized()
		if distance <= 78.0 and forward.dot(direction) > 0.82:
			var damage := 13.0 * clampf(weapons_health / 100.0, 0.25, 1.0)
			_launch_naval_shell(target, damage)

func _launch_naval_shell(victim: Node3D, damage: float) -> void:
	var shell := Area3D.new()
	shell.name = "NavalShell"
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.32
	collision.shape = sphere
	shell.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.27
	mesh.height = 0.54
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.58, 0.19)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.28, 0.06)
	visual.material_override = material
	shell.add_child(visual)
	var launch_position := global_position + Vector3.UP * 2.0 - global_transform.basis.z * 7.0
	var aim_position := victim.global_position + Vector3.UP * 1.1
	var direction := (aim_position - launch_position).normalized()
	shell.set_meta("team", team)
	shell.set_meta("direction", direction)
	shell.set_meta("speed", 52.0)
	shell.set_meta("damage", damage)
	shell.set_meta("shooter_id", get_instance_id())
	shell.set_script(load("res://scripts/shell.gd"))
	get_tree().current_scene.add_child(shell)
	shell.global_position = launch_position

func _add_ship_scorch(world_position: Vector3) -> void:
	var mark := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.42
	mesh.height = 0.09
	mark.mesh = mesh
	var mat := _ship_material(Color(0.045, 0.035, 0.03), 0.0, 1.0)
	mark.material_override = mat
	mark.position = to_local(world_position)
	mark.scale = Vector3(1.5, 0.16, 0.85)
	add_child(mark)

func apply_damage(amount: float, attacker_team: int, impact: Vector3 = Vector3.ZERO) -> void:
	if attacker_team == team or health <= 0.0:
		return
	var damage := maxf(0.0, amount)
	if impact != Vector3.ZERO and health > damage:
		_add_ship_scorch(impact)
	health = maxf(0.0, health - damage)
	var local_hit := to_local(impact) if impact != Vector3.ZERO else Vector3.ZERO
	if absf(local_hit.x) > 1.8:
		_damage_module("steering", damage * 1.15)
	elif local_hit.z > 3.0:
		_damage_module("engine", damage * 1.25)
	elif local_hit.z < -3.0:
		_damage_module("weapons", damage * 1.1)
	else:
		_damage_module("hull", damage * 0.35)
	_update_module_status()
	if _hull_material:
		_hull_material.albedo_color = Color(0.34, 0.22, 0.17) if health < max_health * 0.35 else (Color(0.29, 0.25, 0.20) if health < max_health * 0.7 else (Color(0.22, 0.30, 0.31) if team == 0 else Color(0.36, 0.20, 0.17)))
	if health <= 0.0 and not _destroyed_emitted:
		_destroyed_emitted = true
		var audio := get_tree().get_first_node_in_group("wbm_audio_manager")
		if audio:
			audio.play_event("explosion", global_position, 1.0)
		destroyed.emit(self)
		queue_free()

func _damage_module(module_name: String, damage: float) -> void:
	match module_name:
		"engine":
			engine_health = maxf(0.0, engine_health - damage)
			module_damaged.emit("ДВИГАТЕЛЬ", engine_health)
		"steering":
			steering_health = maxf(0.0, steering_health - damage)
			module_damaged.emit("РУЛЕВОЕ УПРАВЛЕНИЕ", steering_health)
		"weapons":
			weapons_health = maxf(0.0, weapons_health - damage)
			module_damaged.emit("ОРУДИЯ", weapons_health)

func _update_module_status() -> void:
	var status_parts := ""
	if engine_health < 75.0:
		status_parts += "ДВИГАТЕЛЬ %d%%" % roundi(engine_health)
	if steering_health < 75.0:
		if not status_parts.is_empty():
			status_parts += " / "
		status_parts += "РУЛЬ %d%%" % roundi(steering_health)
	if weapons_health < 75.0:
		if not status_parts.is_empty():
			status_parts += " / "
		status_parts += "ОРУДИЯ %d%%" % roundi(weapons_health)
	module_status = status_parts if not status_parts.is_empty() else "ВСЕ СИСТЕМЫ ИСПРАВНЫ"

func repair_modules(amount: float = 18.0) -> void:
	engine_health = minf(100.0, engine_health + amount)
	steering_health = minf(100.0, steering_health + amount)
	weapons_health = minf(100.0, weapons_health + amount)
	health = minf(max_health, health + amount * 0.5)
	_update_module_status()

func _build_ship() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "FloatingShipVisuals"
	add_child(_visual_root)
	_hull_material = StandardMaterial3D.new()
	_hull_material.albedo_color = Color(0.22, 0.30, 0.31) if team == 0 else Color(0.36, 0.20, 0.17)
	_hull_material.metallic = 0.48
	_hull_material.roughness = 0.7
	var deck_mat := _ship_material(Color(0.27, 0.29, 0.27), 0.38, 0.78)
	var dark := _ship_material(Color(0.075, 0.09, 0.095), 0.65, 0.52)
	var steel := _ship_material(Color(0.38, 0.40, 0.38), 0.78, 0.4)
	var glass := _ship_material(Color(0.035, 0.13, 0.17), 0.72, 0.18)

	# Layered hull with narrowed bow and stern shoulders.
	_ship_box(Vector3(4.4, 1.65, 12.8), Vector3(0, 0, 0.2), _hull_material)
	_ship_box(Vector3(3.5, 1.25, 3.6), Vector3(0, 0.08, -7.45), _hull_material)
	_ship_box(Vector3(2.8, 1.0, 2.2), Vector3(0, 0.12, -9.85), _hull_material)
	_ship_box(Vector3(3.9, 1.35, 3.2), Vector3(0, 0.05, 7.2), _hull_material)
	_ship_box(Vector3(4.0, 0.28, 14.0), Vector3(0, 0.94, 0.1), deck_mat)
	_ship_box(Vector3(2.7, 0.3, 2.8), Vector3(0, 1.12, -7.4), steel)

	# Superstructure and bridge levels.
	_ship_box(Vector3(2.55, 1.55, 3.8), Vector3(0, 1.9, 2.2), _hull_material)
	_ship_box(Vector3(2.05, 1.0, 2.25), Vector3(0, 3.12, 2.15), deck_mat)
	_ship_box(Vector3(2.2, 0.22, 2.45), Vector3(0, 3.72, 2.15), steel)
	_ship_box(Vector3(2.0, 0.85, 0.16), Vector3(0, 3.15, 1.0), glass)
	_ship_box(Vector3(0.16, 0.85, 1.65), Vector3(-1.0, 3.15, 2.15), glass)
	_ship_box(Vector3(0.16, 0.85, 1.65), Vector3(1.0, 3.15, 2.15), glass)
	_ship_cylinder(0.12, 3.0, Vector3(0, 5.15, 2.0), Vector3.ZERO, steel, 12)
	_ship_box(Vector3(0.12, 1.0, 0.12), Vector3(0, 6.45, 2.0), dark)

	# Two main gun turrets with barrels and rangefinder details.
	for turret_z in [-5.8, 5.4]:
		_ship_cylinder(0.88, 0.52, Vector3(0, 1.45, turret_z), Vector3.ZERO, dark, 20)
		_ship_cylinder(0.72, 0.48, Vector3(0, 1.78, turret_z), Vector3.ZERO, steel, 20)
		for side in [-1.0, 1.0]:
			_ship_cylinder(0.13, 2.65, Vector3(side * 0.28, 1.95, turret_z - 1.48), Vector3(PI / 2.0, 0, 0), steel, 12)
		_ship_box(Vector3(0.5, 0.18, 0.42), Vector3(0, 2.1, turret_z + 0.18), dark)

	# Armored gunhouse cheeks, mantlets and barrel reinforcement collars.
	var turret_armor := _ship_material(Color(0.25, 0.28, 0.27), 0.68, 0.62)
	for turret_z in [-5.8, 5.4]:
		_ship_box(Vector3(1.35, 0.62, 1.15), Vector3(0, 2.12, turret_z + 0.22), turret_armor)
		for barrel_side in [-1.0, 1.0]:
			_ship_cylinder(0.16, 0.18, Vector3(barrel_side * 0.28, 1.95, turret_z - 0.38), Vector3(PI / 2.0, 0, 0), dark, 12)
			_ship_cylinder(0.15, 0.12, Vector3(barrel_side * 0.28, 1.95, turret_z - 2.55), Vector3(PI / 2.0, 0, 0), steel, 12)
		for armor_side in [-1.0, 1.0]:
			_ship_box(Vector3(0.08, 0.34, 0.72), Vector3(armor_side * 0.70, 2.12, turret_z + 0.22), steel)
	# Deck hatches and ventilation grilles around the machinery spaces.
	var vent_dark := _ship_material(Color(0.055, 0.065, 0.067), 0.52, 0.78)
	for vent_index in range(4):
		var vent_z: float = -1.2 + float(vent_index) * 1.0
		_ship_box(Vector3(0.72, 0.06, 0.48), Vector3(0, 1.16, vent_z), dark)
		for grille_index in range(5):
			_ship_box(Vector3(0.58, 0.025, 0.035), Vector3(-0.29 + float(grille_index) * 0.145, 1.205, vent_z), vent_dark)

	# Secondary mounts, lifeboats, vents, bollards and rail posts.
	for side in [-1.0, 1.0]:
		for z in [-3.4, 0.0, 5.8]:
			_ship_cylinder(0.36, 0.38, Vector3(side * 1.55, 1.25, z), Vector3.ZERO, steel, 12)
			_ship_cylinder(0.09, 1.25, Vector3(side * 1.55, 1.7, z - 0.62), Vector3(PI / 2.0, 0, 0), dark, 8)
		_ship_box(Vector3(0.75, 0.42, 2.0), Vector3(side * 1.7, 1.45, 3.6), _ship_material(Color(0.55, 0.48, 0.30), 0.12, 0.8))
		_ship_box(Vector3(0.16, 0.28, 0.9), Vector3(side * 2.02, 1.38, -1.2), steel)
		for rail_index in range(5):
			_ship_box(Vector3(0.07, 0.34, 0.07), Vector3(side * 1.93, 1.25, -5.0 + rail_index * 1.5), steel)

	_ship_box(Vector3(0.75, 0.5, 1.2), Vector3(0, 1.35, 8.0), dark)
	_ship_cylinder(0.28, 0.85, Vector3(0, 2.0, 7.4), Vector3.ZERO, steel, 12)
	# Hull waterline stripe and original fleet identification.
	var waterline := _ship_material(Color(0.075, 0.12, 0.14), 0.28, 0.82)
	_ship_box(Vector3(4.42, 0.18, 12.7), Vector3(0, -0.68, 0.2), waterline)
	var fleet_mark := _ship_material(Color(0.95, 0.48, 0.12) if team == 0 else Color(0.78, 0.22, 0.13), 0.12, 0.78)
	_ship_box(Vector3(0.12, 0.12, 1.1), Vector3(-2.03, 1.13, 0.2), fleet_mark)
	_ship_box(Vector3(0.12, 0.12, 1.1), Vector3(2.03, 1.13, 0.2), fleet_mark)
	for deck_line in range(5):
		_ship_box(Vector3(2.8, 0.018, 0.035), Vector3(0, 1.095, -4.1 + deck_line * 1.65), steel)
	# Hull portholes, welded reinforcement strips and deck-edge fittings.
	var porthole_mat := _ship_material(Color(0.025, 0.065, 0.075), 0.55, 0.24)
	var hull_rib_mat := _ship_material(Color(0.16, 0.21, 0.22), 0.62, 0.72)
	for side in [-1.0, 1.0]:
		for porthole_index in range(7):
			var porthole_z := -4.7 + float(porthole_index) * 1.55
			_ship_cylinder(0.13, 0.055, Vector3(side * 2.225, 0.18, porthole_z), Vector3(0, 0, PI / 2.0), steel, 12)
			_ship_cylinder(0.082, 0.065, Vector3(side * 2.26, 0.18, porthole_z), Vector3(0, 0, PI / 2.0), porthole_mat, 12)
		for rib_index in range(5):
			var rib_z := -5.3 + float(rib_index) * 2.45
			_ship_box(Vector3(0.055, 0.72, 0.12), Vector3(side * 2.205, -0.12, rib_z), hull_rib_mat)
		# Bow anchor-chain runs and hawse openings.
		_ship_cylinder(0.07, 1.25, Vector3(side * 1.85, 0.83, -8.25), Vector3(0.12, 0, side * 0.32), dark, 10)
		_ship_cylinder(0.22, 0.16, Vector3(side * 1.92, 0.93, -8.85), Vector3(0, 0, PI / 2.0), steel, 12)
		# Deck cleats and mooring bollards.
		for bollard_index in range(4):
			var bollard_z := -5.0 + float(bollard_index) * 3.2
			_ship_cylinder(0.095, 0.28, Vector3(side * 1.78, 1.16, bollard_z), Vector3.ZERO, steel, 10)
			_ship_box(Vector3(0.34, 0.07, 0.12), Vector3(side * 1.78, 1.31, bollard_z), dark)
	# Bridge radar arrays, rotating-style antenna frame and mast crossarms.
	var radar_mat := _ship_material(Color(0.16, 0.19, 0.20), 0.72, 0.42)
	var nav_light_red := _ship_material(Color(0.72, 0.08, 0.045), 0.08, 0.28)
	nav_light_red.emission_enabled = true
	nav_light_red.emission = Color(0.28, 0.025, 0.01)
	var nav_light_green := _ship_material(Color(0.05, 0.58, 0.22), 0.08, 0.28)
	nav_light_green.emission_enabled = true
	nav_light_green.emission = Color(0.015, 0.18, 0.045)
	_ship_box(Vector3(1.45, 0.10, 0.22), Vector3(0, 6.52, 2.0), radar_mat)
	_ship_box(Vector3(0.12, 0.62, 0.12), Vector3(0, 6.84, 2.0), radar_mat)
	_ship_box(Vector3(0.92, 0.08, 0.08), Vector3(0, 7.12, 2.0), steel)
	_ship_cylinder(0.055, 0.82, Vector3(0, 6.92, 2.0), Vector3(0, 0, PI / 2.0), radar_mat, 10)
	_ship_cylinder(0.10, 0.10, Vector3(-1.16, 4.1, 2.0), Vector3.ZERO, nav_light_red, 10)
	_ship_cylinder(0.10, 0.10, Vector3(1.16, 4.1, 2.0), Vector3.ZERO, nav_light_green, 10)
	# Lifeboat seats, protective covers and davit arms.
	var lifeboat_mat := _ship_material(Color(0.62, 0.49, 0.28), 0.08, 0.82)
	for side in [-1.0, 1.0]:
		for seat_index in range(3):
			_ship_box(Vector3(0.46, 0.07, 0.10), Vector3(side * 1.7, 1.70, 2.95 + float(seat_index) * 0.48), steel)
		_ship_box(Vector3(0.12, 0.72, 0.12), Vector3(side * 2.02, 1.82, 3.55), radar_mat)
		_ship_box(Vector3(0.12, 0.10, 0.95), Vector3(side * 1.98, 2.16, 3.55), lifeboat_mat)
	# Funnels, exhaust caps, anchor gear and deck-service equipment.
	var funnel_mat := _ship_material(Color(0.12, 0.15, 0.16), 0.58, 0.58)
	for funnel_z in [0.2, 2.0]:
		_ship_box(Vector3(0.72, 1.25, 0.82), Vector3(0, 4.15, funnel_z), funnel_mat)
		_ship_box(Vector3(0.82, 0.12, 0.9), Vector3(0, 4.82, funnel_z), dark)
		_ship_box(Vector3(0.78, 0.08, 0.86), Vector3(0, 4.9, funnel_z), steel)
	_ship_cylinder(0.18, 0.5, Vector3(-1.72, 1.2, -8.0), Vector3(0, 0, PI / 2.0), steel, 12)
	_ship_cylinder(0.18, 0.5, Vector3(1.72, 1.2, -8.0), Vector3(0, 0, PI / 2.0), steel, 12)
	for side in [-1.0, 1.0]:
		_ship_box(Vector3(0.22, 0.22, 0.8), Vector3(side * 1.72, 1.28, -6.8), dark)
		_ship_box(Vector3(0.3, 0.16, 1.2), Vector3(side * 1.35, 1.3, 6.0), steel)
	_ship_box(Vector3(1.1, 0.16, 0.42), Vector3(0, 1.3, -9.25), deck_mat)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 2.0, 18.0)
	collision.shape = shape
	add_child(collision)

func _ship_material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = rough
	return mat

func _ship_box(size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	_visual_root.add_child(node)
	return node

func _ship_cylinder(radius: float, height: float, at: Vector3, angles: Vector3, material: Material, segments: int = 16) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	node.mesh = mesh
	node.position = at
	node.rotation = angles
	node.material_override = material
	_visual_root.add_child(node)
	return node
