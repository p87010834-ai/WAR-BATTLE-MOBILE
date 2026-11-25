extends RefCounted
class_name WbmSeasonProgress

const SAVE_PATH := "user://wbm_season.cfg"
const SEASON_LENGTH_DAYS := 30
const MAX_TIERS := 50
var season_id := "season_001"
var season_xp := 0
var claimed_tiers: Array[int] = []

func add_xp(amount: int) -> void:
	season_xp = mini(MAX_TIERS * 1000, season_xp + maxi(0, amount))
	save()

func get_tier() -> int:
	return clampi(season_xp / 1000, 0, MAX_TIERS)

func claim_tier(tier: int) -> bool:
	if tier < 1 or tier > get_tier() or tier in claimed_tiers:
		return false
	claimed_tiers.append(tier)
	save()
	return true

func load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	season_id = str(cfg.get_value("season", "id", season_id))
	season_xp = clampi(int(cfg.get_value("season", "xp", 0)), 0, MAX_TIERS * 1000)
	claimed_tiers.assign(cfg.get_value("season", "claimed", []))

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("season", "id", season_id)
	cfg.set_value("season", "xp", season_xp)
	cfg.set_value("season", "claimed", claimed_tiers)
	cfg.save(SAVE_PATH)
