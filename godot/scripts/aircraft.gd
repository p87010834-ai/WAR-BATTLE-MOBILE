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

func apply_damage(amount: float, attacker_team: int, _impact: Vector3 = Vector3.ZERO) -> void:
	if attacker_team == team or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		destroyed.emit(self)
		queue_free()

func _build_aircraft() -> void:
	_visual_material = StandardMaterial3D.new()
	_visual_material.albedo_color = Color(0.24, 0.31, 0.35) if team == 0 else Color(0.42, 0.19, 0.15)
	_visual_material.metallic = 0.55
	var fuselage := MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = Vector3(0.9, 0.75, 5.5)
	fuselage.mesh = body
	fuselage.material_override = _visual_material
	add_child(fuselage)
	var wings := MeshInstance3D.new()
	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(10.0, 0.18, 1.35)
	wings.mesh = wing_mesh
	wings.position.z = -0.35
	wings.material_override = _visual_material
	add_child(wings)
	var tail := MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(3.0, 0.14, 0.75)
	tail.mesh = tail_mesh
	tail.position.z = 2.0
	tail.material_override = _visual_material
	add_child(tail)
	var fin := MeshInstance3D.new()
	var fin_mesh := BoxMesh.new()
	fin_mesh.size = Vector3(0.18, 1.1, 1.0)
	fin.mesh = fin_mesh
	fin.position = Vector3(0, 0.55, 2.0)
	fin.material_override = _visual_material
	add_child(fin)
