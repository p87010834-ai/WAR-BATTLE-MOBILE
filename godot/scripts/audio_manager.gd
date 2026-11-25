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
