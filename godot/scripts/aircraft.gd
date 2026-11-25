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
var _visual_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("combat_vehicles")
	health = max_health
	_build_aircraft()

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if is_player:
		_player_flight(delta)
	else:
		velocity = -global_transform.basis.z * speed
	velocity += Vector3.DOWN * 9.81 * delta * (0.15 if speed > 18.0 else 1.0)
	move_and_slide()
	if global_position.y < 2.0:
		global_position.y = 2.0
		velocity.y = maxf(0.0, velocity.y)

func _player_flight(delta: float) -> void:
	var pitch := Input.get_action_strength("air_pitch_down") - Input.get_action_strength("air_pitch_up")
	var roll := Input.get_action_strength("air_roll_right") - Input.get_action_strength("air_roll_left")
	var yaw := Input.get_action_strength("air_yaw_right") - Input.get_action_strength("air_yaw_left")
	throttle = clampf(throttle + Input.get_axis("air_throttle_down", "air_throttle_up") * delta * 0.35, 0.12, 1.0)
	speed = move_toward(speed, max_speed * throttle, throttle_acceleration * delta)
	rotate_object_local(Vector3.FORWARD, roll * turn_rate * delta)
	rotate_object_local(Vector3.RIGHT, pitch * turn_rate * delta)
	rotate_y(yaw * turn_rate * 0.65 * delta)
	velocity = -global_transform.basis.z * speed
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
