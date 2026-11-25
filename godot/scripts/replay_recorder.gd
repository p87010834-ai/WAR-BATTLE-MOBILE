extends Node
class_name WbmReplayRecorder

const MAX_SAMPLES := 18000
var recording := false
var elapsed := 0.0
var samples: Array[Dictionary] = []
var last_sample_time_by_id: Dictionary = {}
var sample_interval := 0.2

func start_recording() -> void:
	samples.clear()
	last_sample_time_by_id.clear()
	elapsed = 0.0
	recording = true

func stop_recording() -> void:
	recording = false

func record_vehicle(vehicle: Node3D, vehicle_id: String, team: int, health: float) -> void:
	if not recording or not is_instance_valid(vehicle) or samples.size() >= MAX_SAMPLES:
		return
	var previous_time := float(last_sample_time_by_id.get(vehicle_id, -sample_interval))
	if elapsed - previous_time < sample_interval:
		return
	last_sample_time_by_id[vehicle_id] = elapsed
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

func list_replays() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directory := DirAccess.open("user://replays")
	if directory == null:
		return result
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.to_lower().ends_with(".json"):
			var path := "user://replays/" + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var parsed = JSON.parse_string(file.get_as_text())
				file.close()
				if parsed is Dictionary and parsed.get("samples", []) is Array:
					var entries: Array = parsed.get("samples", [])
					result.append({
						"name": file_name,
						"duration": float(parsed.get("duration", 0.0)),
						"sample_count": entries.size(),
						"valid": not entries.is_empty()
					})
		file_name = directory.get_next()
	directory.list_dir_end()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.name) > str(b.name))
	return result

func load_replay(file_name: String) -> Dictionary:
	var safe_name := file_name.get_file().validate_filename()
	if safe_name.is_empty() or not safe_name.to_lower().ends_with(".json"):
		return {}
	var file := FileAccess.open("user://replays/" + safe_name, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not parsed.get("samples", []) is Array:
		return {}
	return parsed

func delete_replay(file_name: String) -> Error:
	var safe_name := file_name.get_file().validate_filename()
	if safe_name.is_empty() or not safe_name.to_lower().ends_with(".json"):
		return ERR_INVALID_PARAMETER
	return DirAccess.remove_absolute(ProjectSettings.globalize_path("user://replays/" + safe_name))

func save_replay(file_name: String = "latest_replay.json") -> Error:
	if recording:
		stop_recording()
	var safe_name := file_name.get_file().validate_filename()
	if safe_name.is_empty():
		safe_name = "latest_replay.json"
	var file := FileAccess.open("user://replays/" + safe_name, FileAccess.WRITE)
	if file == null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://replays"))
		file = FileAccess.open("user://replays/" + safe_name, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"duration": elapsed, "samples": samples}))
	file.close()
	return OK
