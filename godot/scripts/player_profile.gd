extends RefCounted
class_name WbmPlayerProfile

const SAVE_PATH := "user://wbm_profile.cfg"
const MAX_LEVEL := 100
const SEASON_DAYS := 30

var username := "Игрок"
var account_level := 1
var experience := 0
var total_battles := 0
var total_wins := 0
var daily_reward_claimed_date := ""
var completed_missions: Array[String] = []

func load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	username = str(config.get_value("profile", "username", username))
	account_level = clampi(int(config.get_value("profile", "level", 1)), 1, MAX_LEVEL)
	experience = maxi(0, int(config.get_value("profile", "experience", 0)))
	total_battles = maxi(0, int(config.get_value("stats", "battles", 0)))
	total_wins = maxi(0, int(config.get_value("stats", "wins", 0)))
	daily_reward_claimed_date = str(config.get_value("rewards", "daily_date", ""))

func add_battle_result(won: bool) -> void:
	total_battles += 1
	if won:
		total_wins += 1
	add_experience(100 if won else 50)
	save_profile()

func add_experience(amount: int) -> void:
	experience += maxi(0, amount)
	while account_level < MAX_LEVEL and experience >= _experience_for_next_level():
		experience -= _experience_for_next_level()
		account_level += 1

func _experience_for_next_level() -> int:
	return 500 + account_level * 125

func claim_daily_reward(date_key: String) -> bool:
	if date_key == daily_reward_claimed_date:
		return false
	daily_reward_claimed_date = date_key
	add_experience(75)
	save_profile()
	return true

func save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "username", username)
	config.set_value("profile", "level", account_level)
	config.set_value("profile", "experience", experience)
	config.set_value("stats", "battles", total_battles)
	config.set_value("stats", "wins", total_wins)
	config.set_value("rewards", "daily_date", daily_reward_claimed_date)
	config.save(SAVE_PATH)
