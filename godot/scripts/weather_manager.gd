extends Node3D
class_name WbmWeatherManager

enum Weather { CLEAR, OVERCAST, RAIN, FOG }
@export var weather: Weather = Weather.CLEAR
@export_range(0.0, 1.0) var intensity := 0.35
@export var animate_clouds := true
var _clouds: Array[Node3D] = []
var _environment: Environment

func _ready() -> void:
	_create_cloud_layer()
	_apply_weather()

func set_weather(next_weather: Weather, strength: float = 0.35) -> void:
	weather = next_weather
	intensity = clampf(strength, 0.0, 1.0)
	_apply_weather()

func _process(delta: float) -> void:
	if not animate_clouds:
		return
	for cloud in _clouds:
		if is_instance_valid(cloud):
			cloud.position.x += delta * (0.35 + intensity * 0.8)
			if cloud.position.x > 110.0:
				cloud.position.x = -110.0

func _create_cloud_layer() -> void:
	for i in range(12):
		var cloud := Node3D.new()
		cloud.position = Vector3(randf_range(-100.0, 100.0), randf_range(38.0, 55.0), randf_range(-90.0, 90.0))
		for j in range(4):
			var puff := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = randf_range(3.0, 7.0)
			mesh.height = mesh.radius * 0.55
			puff.mesh = mesh
			puff.position = Vector3(randf_range(-5.0, 5.0), randf_range(-1.0, 1.0), randf_range(-4.0, 4.0))
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.72, 0.76, 0.78, 0.72)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			puff.material_override = mat
			cloud.add_child(puff)
		add_child(cloud)
		_clouds.append(cloud)

func _apply_weather() -> void:
	var world := get_parent()
	if not world:
		return
	var environment_node := world.get_node_or_null("WorldEnvironment")
	if environment_node and environment_node is WorldEnvironment:
		_environment = environment_node.environment
		if weather == Weather.FOG:
			_environment.fog_enabled = true
			_environment.fog_density = 0.012 + intensity * 0.035
		else:
			_environment.fog_enabled = false
