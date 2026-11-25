extends CharacterBody3D
class_name WbmAircraft

signal destroyed(vehicle: WbmAircraft)

@export var team := 0
@export var max_health := 120.0
@export var throttle_acceleration := 22.0
@export var max_speed := 95.0
@export var turn_rate := 0.8
@export var projectile_scene: PackedScene

var health := 120.0
var speed := 25.0
var throttle := 0.35
var fire_cooldown := 0.0
var is_player := false
var target: Node3D
var _visual_material: StandardMaterial3D
var stall_warning := false

func _ready() -> void:
	add_to_group("combat_vehicles")
	health = max_health
	_build_aircraft()

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if is_player:
		_player_flight(delta)
	else:
		_ai_flight(delta)
	velocity += Vector3.DOWN * 9.81 * delta * (0.15 if speed > 18.0 else 1.0)
	move_and_slide()
	if global_position.y < 3.0:
		global_position.y = 3.0
		velocity.y = maxf(0.0, velocity.y)
	if global_position.y > 150.0:
		global_position.y = 150.0
		velocity.y = minf(0.0, velocity.y)

func _ai_flight(delta: float) -> void:
	if not is_instance_valid(target) or not target.has_method("apply_damage") or float(target.get("health")) <= 0.0:
		target = _find_enemy_target()
	if not is_instance_valid(target):
		velocity = -global_transform.basis.z * speed
		return
	var to_target := target.global_position - global_position
	var aim_point := target.global_position + Vector3.UP * 1.5
	speed = move_toward(speed, max_speed * 0.72, throttle_acceleration * delta)
	var control_authority := clampf(speed / 45.0, 0.35, 1.0)
	if to_target.length() > 0.5:
		var desired_transform := global_transform.looking_at(aim_point, Vector3.UP)
		global_transform = global_transform.interpolate_with(desired_transform, clampf(turn_rate * control_authority * delta, 0.0, 1.0))
	velocity = -global_transform.basis.z * speed
	if to_target.length() < 115.0 and absf(to_target.normalized().dot(-global_transform.basis.z)) > 0.82:
		fire_weapon()

func _find_enemy_target() -> Node3D:
	var best: Node3D
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("combat_vehicles"):
		if not is_instance_valid(candidate) or not candidate.has_method("apply_damage"):
			continue
		if int(candidate.get("team")) == team or float(candidate.get("health")) <= 0.0:
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate as Node3D
	return best

func _player_flight(delta: float) -> void:
	var pitch := Input.get_action_strength("air_pitch_down") - Input.get_action_strength("air_pitch_up")
	var roll := Input.get_action_strength("air_roll_right") - Input.get_action_strength("air_roll_left")
	var yaw := Input.get_action_strength("air_yaw_right") - Input.get_action_strength("air_yaw_left")
	throttle = clampf(throttle + Input.get_axis("air_throttle_down", "air_throttle_up") * delta * 0.35, 0.12, 1.0)
	speed = move_toward(speed, max_speed * throttle, throttle_acceleration * delta)
	stall_warning = speed < 22.0
	var control_authority := clampf(speed / 45.0, 0.35, 1.0)
	rotate_object_local(Vector3.FORWARD, roll * turn_rate * control_authority * delta)
	rotate_object_local(Vector3.RIGHT, pitch * turn_rate * control_authority * delta)
	rotate_y(yaw * turn_rate * 0.65 * control_authority * delta)
	velocity = -global_transform.basis.z * speed
	if stall_warning:
		velocity += Vector3.DOWN * (22.0 - speed) * 0.22
	if Input.is_action_pressed("air_fire"):
		fire_weapon()

func fire_weapon() -> void:
	if fire_cooldown > 0.0:
		return
	fire_cooldown = 0.18
	var bolt := Area3D.new()
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.05)
	visual.material_override = mat
	bolt.add_child(visual)
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	shape_node.shape = shape
	bolt.add_child(shape_node)
	bolt.set_script(load("res://scripts/aircraft_bullet.gd"))
	bolt.set_meta("team", team)
	bolt.set_meta("direction", -global_transform.basis.z)
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position - global_transform.basis.z * 4.0

func apply_damage(amount: float, attacker_team: int, impact: Vector3 = Vector3.ZERO) -> void:
	if attacker_team == team or health <= 0.0:
		return
	if impact != Vector3.ZERO and health > amount:
		_add_aircraft_scorch(impact)
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		destroyed.emit(self)
		queue_free()

func _build_aircraft() -> void:
	_visual_material = StandardMaterial3D.new()
	_visual_material.albedo_color = Color(0.24, 0.31, 0.35) if team == 0 else Color(0.42, 0.19, 0.15)
	_visual_material.metallic = 0.62
	_visual_material.roughness = 0.42
	var dark := _air_material(Color(0.07, 0.085, 0.09), 0.72, 0.42)
	var glass := _air_material(Color(0.035, 0.16, 0.22), 0.78, 0.16)
	var fuselage := _air_cylinder(0.43, 6.1, Vector3(0, 0, 0), Vector3(PI / 2.0, 0, 0), _visual_material, 20)
	_air_box(Vector3(0.72, 0.38, 2.3), Vector3(0, 0.08, 0.15), _visual_material)
	_air_cylinder(0.4, 0.85, Vector3(0, 0, -3.38), Vector3(PI / 2.0, 0, 0), dark, 16)
	_air_cylinder(0.19, 0.34, Vector3(0, 0, -3.91), Vector3(PI / 2.0, 0, 0), steel_air(), 16)

	var wings := _air_box(Vector3(11.2, 0.2, 1.55), Vector3(0, -0.12, -0.32), _visual_material)
	var wing_tip_l := _air_box(Vector3(1.15, 0.16, 1.05), Vector3(-5.65, -0.12, -0.25), dark)
	wing_tip_l.rotation.y = -0.08
	var wing_tip_r := _air_box(Vector3(1.15, 0.16, 1.05), Vector3(5.65, -0.12, -0.25), dark)
	wing_tip_r.rotation.y = 0.08
	_air_box(Vector3(3.25, 0.16, 0.82), Vector3(0, 0.12, 2.18), _visual_material)
	_air_box(Vector3(0.2, 1.45, 1.05), Vector3(0, 0.67, 2.35), _visual_material)
	_air_box(Vector3(0.72, 0.12, 0.62), Vector3(0, 0.48, 2.35), dark)

	# Raised cockpit glazing and framed canopy.
	var canopy := MeshInstance3D.new()
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 0.62
	canopy_mesh.height = 1.0
	canopy.mesh = canopy_mesh
	canopy.scale = Vector3(0.72, 0.72, 1.55)
	canopy.position = Vector3(0, 0.48, -0.78)
	canopy.material_override = glass
	add_child(canopy)
	_air_box(Vector3(0.06, 0.09, 1.15), Vector3(0, 0.87, -0.82), dark)

	# Twin engine nacelles, exhausts, pylons and wing hardpoints.
	for side in [-1.0, 1.0]:
		_air_cylinder(0.22, 2.35, Vector3(side * 2.45, -0.05, 0.72), Vector3(PI / 2.0, 0, 0), dark, 16)
		_air_cylinder(0.18, 0.22, Vector3(side * 2.45, -0.05, 1.95), Vector3(PI / 2.0, 0, 0), steel_air(), 16)
		_air_box(Vector3(0.18, 0.58, 0.22), Vector3(side * 3.45, -0.35, -0.34), dark)
		_air_cylinder(0.09, 1.65, Vector3(side * 3.5, -0.45, -0.88), Vector3(PI / 2.0, 0, 0), steel_air(), 12)
		_air_box(Vector3(0.32, 0.14, 0.9), Vector3(side * 4.65, -0.18, 0.35), dark)
		_air_box(Vector3(0.12, 0.16, 0.42), Vector3(side * 5.25, -0.05, -0.34), glass)

	# Antenna, pitot probe and small surface panels.
	_air_cylinder(0.035, 0.8, Vector3(0, 0.53, 1.55), Vector3.ZERO, dark, 8)
	_air_cylinder(0.035, 0.9, Vector3(0, 0.02, -3.25), Vector3(PI / 2.0, 0, 0), steel_air(), 8)
	_air_box(Vector3(0.14, 0.08, 0.65), Vector3(0, -0.15, 1.15), dark)
	# Original squadron bands and maintenance panels.
	var marking := _air_material(Color(0.95, 0.48, 0.12) if team == 0 else Color(0.78, 0.22, 0.13), 0.22, 0.62)
	for side in [-1.0, 1.0]:
		_air_box(Vector3(0.72, 0.035, 0.28), Vector3(side * 3.9, -0.005, -0.3), marking)
		_air_box(Vector3(0.36, 0.035, 0.22), Vector3(side * 4.65, -0.005, -0.3), dark)
		_air_box(Vector3(0.18, 0.035, 0.52), Vector3(side * 0.34, -0.22, 0.35), dark)
	_air_box(Vector3(0.5, 0.035, 0.42), Vector3(0, -0.22, -2.1), marking)
	# Flight-control surfaces, hinge lines and engine intake lips.
	var control_mat := _air_material(Color(0.13, 0.17, 0.19) if team == 0 else Color(0.25, 0.12, 0.10), 0.48, 0.68)
	for side in [-1.0, 1.0]:
		var aileron := _air_box(Vector3(2.25, 0.075, 0.32), Vector3(side * 4.15, -0.235, 0.62), control_mat)
		aileron.rotation.y = side * 0.035
		_air_box(Vector3(2.15, 0.025, 0.045), Vector3(side * 4.1, -0.235, 0.43), dark)
		_air_cylinder(0.245, 0.09, Vector3(side * 2.45, -0.05, -0.42), Vector3(PI / 2.0, 0, 0), steel_air(), 20)
		_air_box(Vector3(0.42, 0.06, 0.18), Vector3(side * 2.45, -0.23, 1.72), marking)
	var elevator := _air_box(Vector3(2.65, 0.07, 0.28), Vector3(0, 0.08, 2.62), control_mat)
	elevator.rotation.y = 0.0
	_air_box(Vector3(0.08, 0.08, 0.72), Vector3(0, 0.78, 2.35), steel_air())

func _add_aircraft_scorch(impact: Vector3) -> void:
	var mark := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.08
	mark.mesh = mesh
	var mat := _air_material(Color(0.035, 0.028, 0.025), 0.0, 1.0)
	mark.material_override = mat
	mark.position = to_local(impact)
	mark.scale = Vector3(1.25, 0.2, 0.7)
	add_child(mark)

func _air_material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = rough
	return mat

func steel_air() -> StandardMaterial3D:
	return _air_material(Color(0.32, 0.36, 0.38), 0.82, 0.34)

func _air_box(size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	add_child(node)
	return node

func _air_cylinder(radius: float, height: float, at: Vector3, angles: Vector3, material: Material, segments: int = 16) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.9
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	node.mesh = mesh
	node.position = at
	node.rotation = angles
	node.material_override = material
	add_child(node)
	return node
