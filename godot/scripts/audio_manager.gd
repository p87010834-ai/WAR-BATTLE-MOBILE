extends Node
class_name WbmAudioManager

const SAMPLE_RATE := 22050
var _streams: Dictionary = {}
var _engine_players: Dictionary = {}

func _ready() -> void:
	add_to_group("wbm_audio_manager")
	_streams["tank"] = _make_loop(72.0, 2, 0.42)
	_streams["aircraft"] = _make_loop(118.0, 1, 0.24)
	_streams["ship"] = _make_loop(48.0, 2, 0.32)
	_streams["cannon"] = _make_effect(82.0, 0.42, 0.92, true)
	_streams["gun"] = _make_effect(620.0, 0.075, 0.34, true)
	_streams["naval"] = _make_effect(58.0, 0.62, 0.88, true)
	_streams["explosion"] = _make_effect(42.0, 0.78, 0.95, true)
	_streams["impact"] = _make_effect(240.0, 0.12, 0.48, true)

func attach_engine(vehicle: Node3D, kind: String) -> void:
	if not _streams.has(kind) or _engine_players.has(vehicle.get_instance_id()):
		return
	var player := AudioStreamPlayer3D.new()
	player.name = "EngineAudio"
	player.stream = _streams[kind]
	player.volume_db = -13.0
	player.max_distance = 115.0
	player.unit_size = 12.0
	player.autoplay = true
	vehicle.add_child(player)
	player.play()
	_engine_players[vehicle.get_instance_id()] = player

func play_event(kind: String, at: Vector3, volume_db: float = -5.0) -> void:
	if kind == "explosion":
		spawn_explosion(at)
	elif kind == "impact":
		spawn_impact(at)
	if not _streams.has(kind):
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = _streams[kind]
	player.volume_db = volume_db
	player.max_distance = 150.0
	player.unit_size = 10.0
	get_tree().current_scene.add_child(player)
	player.global_position = at
	player.finished.connect(player.queue_free)
	player.play()


func spawn_explosion(at: Vector3) -> void:
	var fx := Node3D.new()
	fx.name = "ExplosionFX"
	get_tree().current_scene.add_child(fx)
	fx.global_position = at
	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 1.15
	flash_mesh.height = 2.3
	flash.mesh = flash_mesh
	var flash_mat := StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color(1.0, 0.38, 0.08, 0.82)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.2, 0.025)
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = flash_mat
	fx.add_child(flash)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.36, 0.12)
	light.light_energy = 3.2
	light.omni_range = 12.0
	fx.add_child(light)
	var particles := GPUParticles3D.new()
	particles.amount = 42
	particles.lifetime = 1.35
	particles.one_shot = true
	particles.explosiveness = 0.92
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 3.0
	process.initial_velocity_max = 12.0
	process.gravity = Vector3(0.0, -8.0, 0.0)
	process.scale_min = 0.18
	process.scale_max = 0.72
	process.color = Color(1.0, 0.34, 0.075, 0.92)
	particles.process_material = process
	var spark := SphereMesh.new()
	spark.radius = 0.16
	spark.height = 0.32
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.albedo_color = Color(1.0, 0.52, 0.16)
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(1.0, 0.22, 0.035)
	spark.material = spark_mat
	particles.draw_pass_1 = spark
	fx.add_child(particles)
	particles.emitting = true
	var smoke := GPUParticles3D.new()
	smoke.amount = 18
	smoke.lifetime = 3.4
	smoke.one_shot = true
	smoke.explosiveness = 0.7
	var smoke_process := ParticleProcessMaterial.new()
	smoke_process.direction = Vector3.UP
	smoke_process.spread = 24.0
	smoke_process.initial_velocity_min = 1.0
	smoke_process.initial_velocity_max = 3.2
	smoke_process.gravity = Vector3(0.0, 0.45, 0.0)
	smoke_process.scale_min = 0.8
	smoke_process.scale_max = 2.2
	smoke_process.color = Color(0.16, 0.15, 0.14, 0.68)
	smoke.process_material = smoke_process
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.48
	smoke_mesh.height = 0.96
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.albedo_color = Color(0.2, 0.19, 0.18, 0.55)
	smoke_mat.roughness = 1.0
	smoke_mesh.material = smoke_mat
	smoke.draw_pass_1 = smoke_mesh
	fx.add_child(smoke)
	smoke.emitting = true
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.48)
	tween.parallel().tween_property(flash, "scale", Vector3(0.05, 0.05, 0.05), 0.42)
	get_tree().create_timer(4.0).timeout.connect(fx.queue_free)

func spawn_impact(at: Vector3) -> void:
	var sparks := GPUParticles3D.new()
	sparks.name = "ImpactSparks"
	sparks.amount = 12
	sparks.lifetime = 0.38
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 7.0
	process.gravity = Vector3(0.0, -9.0, 0.0)
	process.scale_min = 0.045
	process.scale_max = 0.12
	process.color = Color(1.0, 0.58, 0.18)
	sparks.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.52, 0.12)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.24, 0.04)
	mesh.material = material
	sparks.draw_pass_1 = mesh
	get_tree().current_scene.add_child(sparks)
	sparks.global_position = at
	sparks.emitting = true
	get_tree().create_timer(0.8).timeout.connect(sparks.queue_free)

func _process(_delta: float) -> void:
	for instance_id in _engine_players.keys():
		var player: AudioStreamPlayer3D = _engine_players[instance_id]
		if not is_instance_valid(player) or not is_instance_valid(player.get_parent()):
			_engine_players.erase(instance_id)
			continue
		var vehicle := player.get_parent()
		var speed_value := 0.0
		if vehicle is WbmTank:
			speed_value = (vehicle as WbmTank).velocity.length()
		elif vehicle is WbmAircraft:
			speed_value = (vehicle as WbmAircraft).speed
		elif vehicle is WbmShip:
			speed_value = absf((vehicle as WbmShip).current_speed) * 3.0
		player.pitch_scale = clampf(0.78 + speed_value / 90.0, 0.72, 1.65)
		player.volume_db = -16.0 + clampf(speed_value / 18.0, 0.0, 5.0)

func _make_loop(frequency: float, harmonics: int, amplitude: float) -> AudioStreamWAV:
	var count := SAMPLE_RATE
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var phase := TAU * frequency * t
		var sample := sin(phase) * 0.58
		if harmonics > 1:
			sample += sin(phase * 2.01) * 0.22
			sample += sin(phase * 0.5) * 0.2
		sample *= amplitude * (0.82 + 0.18 * sin(TAU * 3.0 * t))
		bytes.encode_s16(i * 2, int(clampi(roundi(sample * 32767.0), -32767, 32767)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	stream.data = bytes
	return stream

func _make_effect(frequency: float, duration: float, amplitude: float, noise_mix: bool) -> AudioStreamWAV:
	var count := maxi(1, roundi(float(SAMPLE_RATE) * duration))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var envelope := pow(1.0 - float(i) / float(count), 2.1)
		var tone := sin(TAU * frequency * t) * 0.65 + sin(TAU * frequency * 1.73 * t) * 0.2
		var noise := randf_range(-1.0, 1.0) * (0.7 if noise_mix else 0.0)
		var sample := (tone + noise) * envelope * amplitude
		bytes.encode_s16(i * 2, int(clampi(roundi(sample * 32767.0), -32767, 32767)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
