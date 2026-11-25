extends RefCounted
class_name WbmAchievementSystem

const SAVE_PATH := "user://wbm_achievements.cfg"
const DEFINITIONS := {
	"first_battle": {"title": "Первый бой", "description": "Завершить первый бой"},
	"first_victory": {"title": "Первая победа", "description": "Одержать первую победу"},
	"tank_ace": {"title": "Танковый ас", "description": "Уничтожить 10 машин"},
	"capture_master": {"title": "Захватчик", "description": "Захватить 10 точек"}
}
var unlocked: Array[String] = []

func _init() -> void:
	load_data()

func unlock(achievement_id: String) -> bool:
	if not DEFINITIONS.has(achievement_id) or achievement_id in unlocked:
		return false
	unlocked.append(achievement_id)
	save_data()
	return true

func get_unlocked_count() -> int:
	return unlocked.size()

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var saved: Array = cfg.get_value("achievements", "unlocked", [])
		unlocked.assign(saved)

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.save(SAVE_PATH)
