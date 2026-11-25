extends CharacterBody3D
class_name WbmTank

signal destroyed(tank: WbmTank)

@export var is_player := false
@export var team := 0
@export var move_speed := 8.0
@export var turn_speed := 1.7
@export var max_health := 100.0
@export var reload_seconds := 1.6

var health := 100.0
var reload_left := 0.0
var target: Node3D
var ai_fire_timer := 0.0
var turret: Node3D
var muzzle: Marker3D
var hull_material: StandardMaterial3D
var engine_damaged := false
var track_damaged := false
var gun_disabled_left := 0.0
var module_status := "НОРМА"
var repair_progress := 0.0
var repair_cooldown := 0.0

func _ready() -> void:
	add_to_group("combat_vehicles")
	health = max_health
	_build_vehicle()
	if not is_player:
		ai_fire_timer = randf_range(0.5, 1.5)

func _build_vehicle() -> void:
	var body_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.5, 1.65, 4.8)
	body_shape.shape = box
	body_shape.position.y = 1.0
	add_child(body_shape)

	hull_material = StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.20, 0.27, 0.18) if team == 0 else Color(0.34, 0.16, 0.13)
	hull_material.metallic = 0.42
	hull_material.roughness = 0.76

	_add_box(self, Vector3(3.0, 0.9, 4.35), Vector3(0, 1.05, 0), hull_material)
	_add_box(self, Vector3(2.45, 0.48, 3.05), Vector3(0, 1.68, 0.18), hull_material)
	_add_box(self, Vector3(2.8, 0.18, 3.8), Vector3(0, 1.48, 0), hull_material)

	var dark := _make_material(Color(0.065, 0.075, 0.07), 0.18, 0.88)
	var steel := _make_material(Color(0.16, 0.18, 0.17), 0.72, 0.48)
	var rubber := _make_material(Color(0.035, 0.04, 0.038), 0.0, 0.95)
	for side in [-1.0, 1.0]:
		_add_box(self, Vector3(0.62, 0.9, 4.75), Vector3(side * 1.62, 0.72, 0), dark)
		_add_box(self, Vector3(0.7, 0.16, 4.55), Vector3(side * 1.62, 1.18, 0), steel)
		for wheel_index in range(6):
			var wheel_z := -1.78 + float(wheel_index) * 0.71
			_add_cylinder(self, 0.39, 0.20, Vector3(side * 1.69, 0.66, wheel_z), Vector3(0, 0, PI / 2.0), rubber, 16)
			_add_cylinder(self, 0.17, 0.215, Vector3(side * 1.70, 0.66, wheel_z), Vector3(0, 0, PI / 2.0), steel, 12)
		_add_cylinder(self, 0.43, 0.2, Vector3(side * 1.69, 0.66, -2.12), Vector3(0, 0, PI / 2.0), steel, 16)
		_add_cylinder(self, 0.43, 0.2, Vector3(side * 1.69, 0.66, 2.12), Vector3(0, 0, PI / 2.0), steel, 16)

	turret = Node3D.new()
	turret.position = Vector3(0, 2.02, -0.12)
	add_child(turret)
	_add_cylinder(turret, 1.0, 0.42, Vector3.ZERO, Vector3.ZERO, steel, 24)
	_add_box(turret, Vector3(1.95, 0.62, 2.0), Vector3(0, 0.37, 0.12), hull_material)
	_add_box(turret, Vector3(1.7, 0.12, 1.5), Vector3(0, 0.74, 0.12), steel)
	_add_box(turret, Vector3(0.72, 0.42, 0.45), Vector3(0, 0.38, -1.03), steel)
	_add_cylinder(turret, 0.14, 2.75, Vector3(0, 0.43, -2.18), Vector3(PI / 2.0, 0, 0), steel, 16)
	_add_cylinder(turret, 0.19, 0.34, Vector3(0, 0.43, -0.98), Vector3(PI / 2.0, 0, 0), dark, 16)
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0, 0.43, -3.58)
	turret.add_child(muzzle)

	# Commander cupola, hatches, periscopes and external stowage.
	_add_cylinder(turret, 0.34, 0.18, Vector3(0.55, 0.78, 0.42), Vector3.ZERO, steel, 16)
	_add_cylinder(turret, 0.23, 0.12, Vector3(-0.58, 0.79, 0.42), Vector3.ZERO, dark, 16)
	_add_box(turret, Vector3(0.48, 0.12, 0.52), Vector3(0.55, 0.89, 0.42), hull_material)
	for side in [-1.0, 1.0]:
		_add_box(turret, Vector3(0.12, 0.25, 0.28), Vector3(side * 0.88, 0.30, 0.4), steel)
		_add_box(self, Vector3(0.18, 0.28, 0.5), Vector3(side * 1.12, 1.55, 1.52), dark)
		_add_box(self, Vector3(0.22, 0.18, 0.34), Vector3(side * 1.48, 1.18, -1.72), steel)
	_add_box(self, Vector3(0.38, 0.28, 0.42), Vector3(-0.82, 1.48, 2.05), dark)
	_add_box(self, Vector3(0.38, 0.28, 0.42), Vector3(0.82, 1.48, 2.05), dark)
	var lamp_mat := _make_material(Color(1.0, 0.78, 0.42), 0.05, 0.25)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(0.35, 0.2, 0.08)
	for side in [-1.0, 1.0]:
		_add_cylinder(self, 0.13, 0.12, Vector3(side * 0.92, 1.2, -2.18), Vector3(PI / 2.0, 0, 0), lamp_mat, 12)
	_add_box(self, Vector3(0.18, 0.18, 1.0), Vector3(0, 1.55, 2.2), steel)
	# Original irregular camouflage panels and team identification.
	var camo := _make_material(Color(0.12, 0.17, 0.12) if team == 0 else Color(0.22, 0.095, 0.075), 0.12, 0.92)
	var camo_light := _make_material(Color(0.34, 0.31, 0.20) if team == 0 else Color(0.48, 0.27, 0.20), 0.08, 0.95)
	for patch_index in range(7):
		var px: float = float([-0.92, 0.62, -0.35, 0.88, -0.7, 0.25, 0.0][patch_index])
		var pz: float = float([-1.25, -0.82, 0.12, 0.75, 1.25, 1.05, -0.25][patch_index])
		var patch_mat: Material = camo if patch_index % 2 == 0 else camo_light
		_add_box(self, Vector3(0.48, 0.025, 0.72), Vector3(px, 1.515, pz), patch_mat)
	_add_box(self, Vector3(0.08, 0.035, 0.72), Vector3(-1.505, 1.55, -0.15), camo_light)
	_add_box(self, Vector3(0.08, 0.035, 0.72), Vector3(1.505, 1.55, -0.15), camo_light)
	# Additional original armor geometry: sloped glacis, side skirts and service fittings.
	var glacis := _add_box(self, Vector3(2.78, 0.22, 1.18), Vector3(0, 1.48, -1.72), hull_material)
	glacis.rotation.x = -0.24
	var applique := _make_material(Color(0.16, 0.21, 0.15) if team == 0 else Color(0.29, 0.14, 0.12), 0.34, 0.82)
	for side in [-1.0, 1.0]:
		_add_box(self, Vector3(0.12, 0.48, 1.35), Vector3(side * 1.78, 1.18, -0.75), applique)
		for bolt_index in range(4):
			_add_cylinder(self, 0.055, 0.035, Vector3(side * 1.79, 1.31, -1.25 + bolt_index * 0.32), Vector3(0, 0, PI / 2.0), steel, 8)
	_add_box(turret, Vector3(0.18, 0.12, 0.58), Vector3(0.82, 0.52, 0.45), dark)
	_add_box(turret, Vector3(0.18, 0.12, 0.58), Vector3(-0.82, 0.52, 0.45), dark)

func _make_material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = rough
	return mat

func _add_box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	parent.add_child(node)
	return node

func _add_cylinder(parent: Node3D, radius: float, height: float, at: Vector3, angles: Vector3, material: Material, segments: int = 16) -> MeshInstance3D:
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
	parent.add_child(node)
	return node
func _physics_process(delta: float) -> void:
	reload_left = maxf(0.0, reload_left - delta)
	gun_disabled_left = maxf(0.0, gun_disabled_left - delta)
	repair_cooldown = maxf(0.0, repair_cooldown - delta)
	_update_repair(delta)
	if is_player:
		_player_drive(delta)
	else:
		_bot_drive(delta)
	move_and_slide()

func _player_drive(delta: float) -> void:
	var throttle := Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var steering := Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	rotation.y += steering * turn_speed * (0.55 if track_damaged else 1.0) * delta * (0.45 + absf(throttle) * 0.55)
	var forward := -global_transform.basis.z
	var effective_speed := move_speed * (0.55 if engine_damaged else 1.0)
	velocity.x = forward.x * throttle * effective_speed
	velocity.z = forward.z * throttle * effective_speed
	velocity.y -= 24.0 * delta
	if not Input.is_action_pressed("repair") and Input.is_action_just_pressed("fire") and gun_disabled_left <= 0.0:
		fire_shell()

func _bot_drive(delta: float) -> void:
	if not is_instance_valid(target) or float(target.get("health")) <= 0.0 or int(target.get("team")) == team:
		target = _find_nearest_opponent()
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var desired_angle := atan2(-to_target.x, -to_target.z)
	rotation.y = rotate_toward(rotation.y, desired_angle, turn_speed * (0.55 if track_damaged else 1.0) * delta)
	var distance := to_target.length()
	var forward := -global_transform.basis.z
	var throttle := 1.0 if distance > 17.0 else (-0.25 if distance < 9.0 else 0.0)
	var effective_speed := move_speed * (0.55 if engine_damaged else 1.0)
	velocity.x = forward.x * throttle * effective_speed * 0.72
	velocity.z = forward.z * throttle * effective_speed * 0.72
	velocity.y -= 24.0 * delta
	ai_fire_timer -= delta
	if distance < 42.0 and ai_fire_timer <= 0.0 and gun_disabled_left <= 0.0:
		fire_shell()
		ai_fire_timer = randf_range(1.8, 3.0)

func _find_nearest_opponent() -> Node3D:
	var nearest: Node3D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("combat_vehicles"):
		if candidate == self or not candidate is Node3D or not candidate.has_method("apply_damage"):
			continue
		var vehicle := candidate as Node3D
		if int(vehicle.get("team")) == team or float(vehicle.get("health")) <= 0.0:
			continue
		var distance := global_position.distance_squared_to(vehicle.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = vehicle
	return nearest

func fire_shell() -> void:
	if reload_left > 0.0 or gun_disabled_left > 0.0:
		return
	reload_left = reload_seconds
	var shell := Area3D.new()
	shell.name = "TankShell"
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.28
	collision.shape = sphere
	shell.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.44
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.53, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.24, 0.035)
	visual.material_override = mat
	shell.add_child(visual)
	var direction := -turret.global_transform.basis.z
	shell.set_meta("team", team)
	shell.set_meta("direction", direction)
	shell.set_meta("speed", 55.0)
	shell.set_meta("damage", 28.0)
	shell.set_meta("shooter_id", get_instance_id())
	shell.set_script(load("res://scripts/shell.gd"))
	get_tree().current_scene.add_child(shell)
	shell.global_position = muzzle.global_position

func _update_repair(delta: float) -> void:
	if not is_player:
		return
	var repairing := Input.is_action_pressed("repair")
	var moving := absf(Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")) > 0.08 or absf(Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")) > 0.08
	if not repairing or moving or repair_cooldown > 0.0:
		repair_progress = 0.0
		return
	repair_progress += delta
	if repair_progress >= 4.0:
		health = minf(max_health, health + 20.0 * delta)
		engine_damaged = false
		track_damaged = false
		gun_disabled_left = 0.0
		module_status = "РЕМОНТ" if health < max_health else "НОРМА"
		if health >= max_health:
			repair_cooldown = 1.0
	if is_instance_valid(hull_material) and not engine_damaged and not track_damaged:
		hull_material.albedo_color = Color(0.20, 0.27, 0.18) if team == 0 else Color(0.34, 0.16, 0.13)

func _apply_module_damage(impact_position: Vector3) -> void:
	var local_hit := to_local(impact_position)
	if local_hit.z < -0.75:
		gun_disabled_left = maxf(gun_disabled_left, 8.0)
		module_status = "ОРУДИЕ ПОВРЕЖДЕНО"
	elif local_hit.z > 0.75:
		engine_damaged = true
		module_status = "ДВИГАТЕЛЬ ПОВРЕЖДЁН"
	elif absf(local_hit.x) > 0.9:
		track_damaged = true
		module_status = "ГУСЕНИЦА ПОВРЕЖДЕНА"
	else:
		module_status = "БРОНЯ ПРОБИТА"
	if is_instance_valid(hull_material):
		hull_material.albedo_color = Color(0.38, 0.22, 0.12) if (engine_damaged or track_damaged) else Color(0.48, 0.34, 0.16)

func _add_impact_scorch(world_position: Vector3) -> void:
	var mark := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.24
	mesh.height = 0.07
	mark.mesh = mesh
	var mat := _make_material(Color(0.045, 0.035, 0.028), 0.0, 1.0)
	mark.material_override = mat
	mark.position = to_local(world_position)
	mark.scale = Vector3(1.0, 0.18, 1.35)
	add_child(mark)

func apply_damage(amount: float, attacker_team: int, impact_position: Vector3 = Vector3.ZERO) -> void:
	if attacker_team == team or health <= 0.0:
		return
	_apply_module_damage(impact_position)
	if impact_position != Vector3.ZERO and health > amount:
		_add_impact_scorch(impact_position)
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		destroyed.emit(self)
		queue_free()
