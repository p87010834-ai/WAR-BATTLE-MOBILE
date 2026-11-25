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
var target: WbmTank
var ai_fire_timer := 0.0
var turret: Node3D
var muzzle: Marker3D
var hull_material: StandardMaterial3D

func _ready() -> void:
	health = max_health
	_build_vehicle()
	if not is_player:
		ai_fire_timer = randf_range(0.5, 1.5)

func _build_vehicle() -> void:
	var body_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.7, 1.15, 4.0)
	body_shape.shape = box
	body_shape.position.y = 0.85
	add_child(body_shape)

	hull_material = StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.20, 0.27, 0.18) if team == 0 else Color(0.34, 0.16, 0.13)
	hull_material.metallic = 0.35
	hull_material.roughness = 0.78

	var hull := MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(2.7, 1.0, 4.0)
	hull.mesh = hull_mesh
	hull.position.y = 0.9
	hull.material_override = hull_material
	add_child(hull)

	for side in [-1.0, 1.0]:
		var track := MeshInstance3D.new()
		var track_mesh := BoxMesh.new()
		track_mesh.size = Vector3(0.48, 0.82, 4.25)
		track.mesh = track_mesh
		track.position = Vector3(side * 1.48, 0.65, 0.0)
		var track_mat := StandardMaterial3D.new()
		track_mat.albedo_color = Color(0.075, 0.08, 0.075)
		track.material_override = track_mat
		add_child(track)

	turret = Node3D.new()
	turret.position.y = 1.48
	add_child(turret)

	var turret_mesh := MeshInstance3D.new()
	var turret_shape := BoxMesh.new()
	turret_shape.size = Vector3(1.75, 0.68, 1.85)
	turret_mesh.mesh = turret_shape
	turret_mesh.material_override = hull_material
	turret.add_child(turret_mesh)

	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.095
	barrel_mesh.bottom_radius = 0.13
	barrel_mesh.height = 2.5
	barrel.mesh = barrel_mesh
	barrel.rotation.x = PI / 2.0
	barrel.position.z = -1.55
	barrel.material_override = hull_material
	turret.add_child(barrel)

	muzzle = Marker3D.new()
	muzzle.position = Vector3(0, 0, -2.85)
	turret.add_child(muzzle)

func _physics_process(delta: float) -> void:
	reload_left = maxf(0.0, reload_left - delta)
	if is_player:
		_player_drive(delta)
	else:
		_bot_drive(delta)
	move_and_slide()

func _player_drive(delta: float) -> void:
	var throttle := Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var steering := Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	rotation.y += steering * turn_speed * delta * (0.45 + absf(throttle) * 0.55)
	var forward := -global_transform.basis.z
	velocity.x = forward.x * throttle * move_speed
	velocity.z = forward.z * throttle * move_speed
	velocity.y -= 24.0 * delta
	if Input.is_action_just_pressed("fire"):
		fire_shell()

func _bot_drive(delta: float) -> void:
	if not is_instance_valid(target) or target.health <= 0.0:
		velocity = Vector3.ZERO
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var desired_angle := atan2(-to_target.x, -to_target.z)
	rotation.y = rotate_toward(rotation.y, desired_angle, turn_speed * delta)
	var distance := to_target.length()
	var forward := -global_transform.basis.z
	var throttle := 1.0 if distance > 17.0 else (-0.25 if distance < 9.0 else 0.0)
	velocity.x = forward.x * throttle * move_speed * 0.72
	velocity.z = forward.z * throttle * move_speed * 0.72
	velocity.y -= 24.0 * delta
	ai_fire_timer -= delta
	if distance < 42.0 and ai_fire_timer <= 0.0:
		fire_shell()
		ai_fire_timer = randf_range(1.8, 3.0)

func fire_shell() -> void:
	if reload_left > 0.0:
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
	shell.set_script(load("res://scripts/shell.gd"))
	get_tree().current_scene.add_child(shell)
	shell.global_position = muzzle.global_position

func apply_damage(amount: float, attacker_team: int) -> void:
	if attacker_team == team or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		destroyed.emit(self)
		queue_free()
