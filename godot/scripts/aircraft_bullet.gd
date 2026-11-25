extends Area3D

@export var speed := 150.0
@export var damage := 8.0
@export var lifetime := 3.0
var team := 0
var direction := Vector3.FORWARD
var _age := 0.0

func _ready() -> void:
	team = int(get_meta("team", 0))
	direction = get_meta("direction", Vector3.FORWARD)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	var start := global_position
	var finish := start + direction.normalized() * speed * delta
	var query := PhysicsRayQueryParameters3D.create(start, finish)
	query.collide_with_areas = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target: Node = hit.get("collider") as Node
		if is_instance_valid(target) and target.has_method("apply_damage"):
			target.apply_damage(damage, team, hit.get("position", finish))
		var audio := get_tree().get_first_node_in_group("wbm_audio_manager")
		if audio:
			audio.play_event("impact", hit.get("position", finish), -11.0)
		queue_free()
	else:
		global_position = finish

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_damage"):
		body.apply_damage(damage, team, global_position)
	queue_free()
