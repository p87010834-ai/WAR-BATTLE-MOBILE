extends Node3D
class_name WbmCapturePoint

signal captured(team: int)

@export var point_name := "АЛЬФА"
@export var capture_radius := 13.0
@export var capture_speed := 24.0

var owner_team := -1
var progress := 0.0
var progress_team := -1
var _ring: MeshInstance3D
var _core: MeshInstance3D
var _label: Label3D

func _ready() -> void:
	_ring = MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = capture_radius
	ring_mesh.bottom_radius = capture_radius
	ring_mesh.height = 0.12
	_ring.mesh = ring_mesh
	_ring.position.y = 0.08
	add_child(_ring)

	_core = MeshInstance3D.new()
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 1.1
	core_mesh.bottom_radius = 1.1
	core_mesh.height = 0.18
	_core.mesh = core_mesh
	_core.position.y = 0.22
	add_child(_core)

	_label = Label3D.new()
	_label.text = point_name
	_label.position = Vector3(0, 2.0, 0)
	_label.font_size = 48
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	_refresh_visual()

func update_control(tanks: Array[WbmTank], delta: float) -> void:
	var blue := 0
	var red := 0
	for tank in tanks:
		if not is_instance_valid(tank) or tank.health <= 0.0:
			continue
		var distance := Vector2(tank.global_position.x - global_position.x, tank.global_position.z - global_position.z).length()
		if distance <= capture_radius:
			if tank.team == 0:
				blue += 1
			else:
				red += 1

	# A contested point cannot change hands while both teams are present.
	if blue > 0 and red > 0:
		return
	if blue == red:
		return

	var attacking_team := 0 if blue > red else 1
	var strength := minf(2.0, absf(float(blue - red)))
	var step := capture_speed * strength * delta

	if owner_team == attacking_team:
		return

	if owner_team >= 0:
		# First drain the current owner's control before the point becomes neutral.
		progress = maxf(0.0, progress - step)
		if progress <= 0.0:
			owner_team = -1
			progress_team = attacking_team
		_refresh_visual()
		return

	# Neutral capture progress belongs to one team; the opponent must reverse it.
	if progress_team == -1:
		progress_team = attacking_team
	elif progress_team != attacking_team:
		progress = maxf(0.0, progress - step)
		if progress <= 0.0:
			progress_team = attacking_team
		_refresh_visual()
		return

	progress = minf(100.0, progress + step)
	if progress >= 100.0:
		owner_team = attacking_team
		progress_team = attacking_team
		captured.emit(owner_team)
	_refresh_visual()

func _refresh_visual() -> void:
	var tint := Color(0.55, 0.58, 0.6) if owner_team == -1 else (Color(0.18, 0.48, 1.0) if owner_team == 0 else Color(1.0, 0.22, 0.16))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint * 0.35
	_ring.material_override = mat
	_core.material_override = mat
	_label.modulate = tint
	var state := "НЕЙТРАЛЬНА" if owner_team == -1 else ("СИНИЕ" if owner_team == 0 else "КРАСНЫЕ")
	_label.text = "%s  %s  %d%%" % [point_name, state, roundi(progress)]
