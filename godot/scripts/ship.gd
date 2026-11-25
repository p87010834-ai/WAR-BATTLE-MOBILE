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
var _hull_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("combat_vehicles")
	add_to_group("naval_vehicles")
	health = max_health
	_build_ship()

func _physics_process(delta: float) -> void:
	weapon_cooldown = maxf(0.0, weapon_cooldown - delta)
	if health <= 0.0:
		velocity = Vector3.ZERO
		return

	var throttle := 0.0
	if is_player:
		var steering := Input.get_action_strength("ship_turn_left") - Input.get_action_strength("ship_turn_right")
		throttle = Input.get_action_strength("ship_forward") - Input.get_action_strength("ship_reverse")
		var steering_factor := clampf(steering_health / 100.0, 0.0, 1.0)
		rotation.y += steering * turn_rate * steering_factor * (0.35 + current_speed / maxf(cruise_speed, 0.1)) * delta
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

func _ai_naval_combat(delta: float) -> float:
	if not is_instance_valid(target) or not target.is_in_group("naval_vehicles") or float(target.get("health")) <= 0.0:
		target = _find_enemy_ship()
	if not is_instance_valid(target):
		return 0.2
	var to_target := target.global_position - global_position
	var desired_yaw := atan2(-to_target.x, -to_target.z)
	var difference := wrapf(desired_yaw - rotation.y, -PI, PI)
	var steering_factor := clampf(steering_health / 100.0, 0.0, 1.0)
	rotation.y = rotate_toward(rotation.y, desired_yaw, turn_rate * steering_factor * delta)
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
	if is_instance_valid(target) and target.has_method("apply_damage"):
		var distance := global_position.distance_to(target.global_position)
		var forward := -global_transform.basis.z
		var direction := (target.global_position - global_position).normalized()
		if distance <= 78.0 and forward.dot(direction) > 0.82:
			var damage := 26.0 * clampf(weapons_health / 100.0, 0.25, 1.0)
			target.apply_damage(damage, team, target.global_position)

func apply_damage(amount: float, attacker_team: int, impact: Vector3 = Vector3.ZERO) -> void:
	if attacker_team == team or health <= 0.0:
		return
	var damage := maxf(0.0, amount)
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
	var hull := MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(5.0, 2.0, 18.0)
	hull.mesh = hull_mesh
	_hull_material = StandardMaterial3D.new()
	_hull_material.albedo_color = Color(0.22, 0.30, 0.31) if team == 0 else Color(0.36, 0.20, 0.17)
	_hull_material.metallic = 0.45
	_hull_material.roughness = 0.72
	hull.material_override = _hull_material
	add_child(hull)

	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(4.2, 0.5, 13.0)
	deck.mesh = deck_mesh
	deck.position.y = 1.1
	deck.material_override = _hull_material
	add_child(deck)

	var bridge := MeshInstance3D.new()
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(2.5, 2.5, 3.0)
	bridge.mesh = bridge_mesh
	bridge.position = Vector3(0, 2.3, 1.0)
	bridge.material_override = _hull_material
	add_child(bridge)

	for turret_z in [-5.5, 5.0]:
		var turret := MeshInstance3D.new()
		var turret_mesh := CylinderMesh.new()
		turret_mesh.top_radius = 0.8
		turret_mesh.bottom_radius = 0.9
		turret_mesh.height = 0.65
		turret.mesh = turret_mesh
		turret.position = Vector3(0, 1.55, turret_z)
		turret.material_override = _hull_material
		add_child(turret)
		var barrel := MeshInstance3D.new()
		var barrel_mesh := BoxMesh.new()
		barrel_mesh.size = Vector3(0.18, 0.18, 2.6)
		barrel.mesh = barrel_mesh
		barrel.position = Vector3(0, 1.75, turret_z - 1.3)
		barrel.material_override = _hull_material
		add_child(barrel)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 2.0, 18.0)
	collision.shape = shape
	add_child(collision)
