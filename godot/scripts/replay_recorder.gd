extends Node
class_name WbmReplayRecorder

const MAX_SAMPLES := 18000
var recording := false
var elapsed := 0.0
var samples: Array[Dictionary] = []

func start_recording() -> void:
	samples.clear()
	elapsed = 0.0
	recording = true

func stop_recording() -> void:
	recording = false

func record_vehicle(vehicle: Node3D, vehicle_id: String, team: int, health: float) -> void:
	if not recording or not is_instance_valid(vehicle) or samples.size() >= MAX_SAMPLES:
		return
	samples.append({
		"t": elapsed,
		"id": vehicle_id,
		"team": team,
		"p": [vehicle.global_position.x, vehicle.global_position.y, vehicle.global_position.z],
		"r": [vehicle.global_rotation.x, vehicle.global_rotation.y, vehicle.global_rotation.z],
		"hp": health
	})

func _process(delta: float) -> void:
	if recording:
		elapsed += delta

func save_replay(file_name: String = "latest_replay.json") -> Error:
	if recording:
		stop_recording()
	var safe_name := file_name.get_file().validate_filename()
	if safe_name.is_empty():
		safe_name = "latest_replay.json"
	var file := FileAccess.open("user://replays/" + safe_name, FileAccess.WRITE)
	if file == null:
		DirAccess.make_dir_recursive_absolute("user://replays")
		file = FileAccess.open("user://replays/" + safe_name, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"duration": elapsed, "samples": samples}))
	file.close()
	return OK
