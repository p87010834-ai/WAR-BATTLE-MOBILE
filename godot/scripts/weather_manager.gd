extends Node3D
class_name WbmWeatherManager

enum Weather { CLEAR, OVERCAST, RAIN, FOG }
@export var weather: Weather = Weather.CLEAR
@export_range(0.0, 1.0) var intensity := 0.35
@export var animate_clouds := true
var _clouds: Array[Node3D] = []
var _environment: Environment
var _rain: GPUParticles3D
var _sun: DirectionalLight3D

func _ready() -> void:
	_create_cloud_layer()
	_create_rain_system()
	_sun = get_parent().get_node_or_null("Sun") as DirectionalLight3D
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
	# Broad layered cloud banks instead of isolated shiny spheres.
	for i in range(10):
		var cloud := Node3D.new()
		cloud.position = Vector3(randf_range(-110.0, 110.0), randf_range(42.0, 58.0), randf_range(-105.0, 105.0))
		cloud.scale = Vector3(randf_range(1.0, 1.45), 1.0, randf_range(0.9, 1.35))
		var puff_count := randi_range(7, 10)
		for j in range(puff_count):
			var puff := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = randf_range(4.5, 8.5)
			mesh.height = mesh.radius * randf_range(0.42, 0.62)
			mesh.radial_segments = 20
			mesh.rings = 12
			puff.mesh = mesh
			puff.position = Vector3(randf_range(-8.0, 8.0), randf_range(-1.1, 1.1), randf_range(-6.5, 6.5))
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.78, 0.81, 0.82) if i % 3 == 0 else Color(0.68, 0.73, 0.76)
			mat.roughness = 1.0
			mat.metallic = 0.0
			puff.material_override = mat
			cloud.add_child(puff)
		add_child(cloud)
		_clouds.append(cloud)

func _create_rain_system() -> void:
	_rain = GPUParticles3D.new()
	_rain.name = "Rain"
	_rain.amount = 520
	_rain.lifetime = 1.8
	_rain.explosiveness = 0.0
	_rain.emitting = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(-0.12, -1.0, 0.0)
	process.spread = 8.0
	process.initial_velocity_min = 28.0
	process.initial_velocity_max = 38.0
	process.gravity = Vector3(0.0, -5.0, 0.0)
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(76.0, 18.0, 76.0)
	_rain.process_material = process
	var streak := QuadMesh.new()
	streak.size = Vector2(0.035, 0.72)
	var rain_material := StandardMaterial3D.new()
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_material.albedo_color = Color(0.55, 0.72, 0.82, 0.62)
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.material = rain_material
	_rain.draw_pass_1 = streak
	_rain.position = Vector3(0.0, 18.0, 0.0)
	add_child(_rain)

func _apply_weather() -> void:
	var world := get_parent()
	if not world:
		return
	var environment_node := world.get_node_or_null("WorldEnvironment")
	if environment_node and environment_node is WorldEnvironment:
		_environment = environment_node.environment
		_environment.fog_enabled = weather == Weather.FOG or weather == Weather.RAIN
		if weather == Weather.FOG:
			_environment.fog_density = 0.009 + intensity * 0.026
		elif weather == Weather.RAIN:
			_environment.fog_density = 0.002 + intensity * 0.008
		else:
			_environment.fog_density = 0.0018
		if _sun:
			_sun.light_energy = 1.25 if weather == Weather.CLEAR else (0.72 if weather == Weather.OVERCAST else 0.88)
			_sun.light_color = Color(1.0, 0.91, 0.78) if weather == Weather.CLEAR else Color(0.72, 0.79, 0.86)
		if is_instance_valid(_rain):
			_rain.emitting = weather == Weather.RAIN
		for cloud in _clouds:
			for puff in cloud.get_children():
				if puff is MeshInstance3D and puff.material_override is StandardMaterial3D:
					var cloud_mat := puff.material_override as StandardMaterial3D
					cloud_mat.albedo_color = Color(0.72, 0.76, 0.78, 0.72) if weather == Weather.CLEAR else Color(0.43, 0.49, 0.55, 0.84)
