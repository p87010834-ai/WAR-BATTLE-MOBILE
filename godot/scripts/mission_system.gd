extends RefCounted
class_name WbmMissionSystem

const SAVE_PATH := "user://wbm_missions.cfg"
var progress: Dictionary = {}
var definitions := {
	"play_3": {"title": "Сыграть 3 боя", "target": 3, "reward_xp": 250},
	"destroy_5": {"title": "Уничтожить 5 машин", "target": 5, "reward_xp": 300},
	"capture_3": {"title": "Захватить 3 точки", "target": 3, "reward_xp": 200}
}

func _init() -> void:
	load_progress()

func add_progress(mission_id: String, amount: int = 1) -> bool:
	if not definitions.has(mission_id):
		return false
	var entry: Dictionary = definitions[mission_id]
	var current := int(progress.get(mission_id, 0))
	if current >= int(entry.target):
		return false
	progress[mission_id] = mini(int(entry.target), current + maxi(0, amount))
	save_progress()
	return int(progress[mission_id]) >= int(entry.target)

func is_complete(mission_id: String) -> bool:
	return definitions.has(mission_id) and int(progress.get(mission_id, 0)) >= int(definitions[mission_id].target)

func claim_reward(mission_id: String, profile: WbmPlayerProfile) -> bool:
	if not is_complete(mission_id):
		return false
	var claimed: Array = progress.get("_claimed", [])
	if mission_id in claimed:
		return false
	claimed.append(mission_id)
	progress["_claimed"] = claimed
	profile.add_experience(int(definitions[mission_id].reward_xp))
	save_progress()
	return true

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		progress = cfg.get_value("missions", "progress", {})

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("missions", "progress", progress)
	cfg.save(SAVE_PATH)
