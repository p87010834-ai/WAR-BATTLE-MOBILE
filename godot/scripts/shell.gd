extends Area3D

var direction := Vector3.FORWARD
var speed := 55.0
var damage := 28.0
var team := -1
var lifetime := 3.0

func _ready() -> void:
	direction = get_meta("direction", Vector3.FORWARD)
	speed = float(get_meta("speed", 55.0))
	damage = float(get_meta("damage", 28.0))
	team = int(get_meta("team", -1))
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is WbmTank:
		body.apply_damage(damage, team, global_position)
	queue_free()

func _on_area_entered(_area: Area3D) -> void:
	queue_free()
