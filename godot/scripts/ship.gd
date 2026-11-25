extends CharacterBody3D
class_name WbmShip

signal destroyed(vessel: WbmShip)

@export var team := 0
@export var max_health := 300.0
@export var cruise_speed := 5.0
@export var turn_rate := 0.35
var health := 300.0
var is_player := false
var weapon_cooldown := 0.0
var target: Node3D

func _ready() -> void:
	add_to_group("combat_vehicles")
	health = max_health
	_build_ship()

func _physics_process(delta: float) -> void:
	weapon_cooldown = maxf(0.0, weapon_cooldown - delta)
	if is_player:
		var steering := Input.get_action_strength("ship_turn_left") - Input.get_action_strength("ship_turn_right")
		var throttle := Input.get_action_strength("ship_forward") - Input.get_action_strength("ship_reverse")
		rotation.y += steering * turn_rate * delta
		velocity = -global_transform.basis.z * throttle * cruise_speed
		if Input.is_action_just_pressed("ship_fire"):
			fire_guns()
	else:
		velocity = -global_transform.basis.z * cruise_speed * 0.35
	move_and_slide()

func fire_guns() -> void:
	if weapon_cooldown > 0.0:
		return
	weapon_cooldown = 3.0
	if is_instance_valid(target) and target.has_method("apply_damage"):
		target.apply_damage(24.0, team, target.global_position)

func apply_damage(amount: float, attacker_team: int, _impact: Vector3 = Vector3.ZERO) -> void:
	if attacker_team == team or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		destroyed.emit(self)
		queue_free()

func _build_ship() -> void:
	var hull := MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(5.0, 2.0, 18.0)
	hull.mesh = hull_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.30, 0.31) if team == 0 else Color(0.36, 0.20, 0.17)
	material.metallic = 0.45
	hull.material_override = material
	add_child(hull)
	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(4.2, 0.5, 13.0)
	deck.mesh = deck_mesh
	deck.position.y = 1.1
	deck.material_override = material
	add_child(deck)
	var bridge := MeshInstance3D.new()
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(2.5, 2.5, 3.0)
	bridge.mesh = bridge_mesh
	bridge.position = Vector3(0, 2.3, 1.0)
	bridge.material_override = material
	add_child(bridge)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 2.0, 18.0)
	collision.shape = shape
	add_child(collision)
