extends Area3D

var direction := Vector3.FORWARD
var speed := 55.0
var damage := 28.0
var team := -1
var lifetime := 3.0
var shooter_id := 0

func _ready() -> void:
	direction = get_meta("direction", Vector3.FORWARD).normalized()
	speed = float(get_meta("speed", 55.0))
	damage = float(get_meta("damage", 28.0))
	team = int(get_meta("team", -1))
	shooter_id = int(get_meta("shooter_id", 0))
	collision_layer = 0
	collision_mask = 0
	monitoring = false

func _physics_process(delta: float) -> void:
	var start := global_position
	var finish := start + direction * speed * delta
	var query := PhysicsRayQueryParameters3D.create(start, finish)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var excluded: Array[RID] = [get_rid()]
	var shooter := instance_from_id(shooter_id)
	if shooter is CollisionObject3D:
		excluded.append(shooter.get_rid())
	query.exclude = excluded
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body: Object = hit.collider
		if body is Node and body.has_method("apply_damage") and int(body.get("team")) != team:
			body.apply_damage(damage, team, hit.position)
		global_position = hit.position
		queue_free()
		return
	global_position = finish
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
