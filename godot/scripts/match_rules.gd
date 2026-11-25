extends RefCounted
class_name WbmMatchRules

const MIN_TEAM_SIZE := 1
const MAX_TEAM_SIZE := 10
const DEFAULT_MATCH_SECONDS := 600
const SCORE_LIMIT := 1000

static func is_valid_team_size(size: int) -> bool:
	return size >= MIN_TEAM_SIZE and size <= MAX_TEAM_SIZE

static func format_clock(seconds: float) -> String:
	var safe_seconds := maxi(0, int(ceil(seconds)))
	return "%02d:%02d" % [safe_seconds / 60, safe_seconds % 60]

static func winner_text(team_zero_score: int, team_one_score: int) -> String:
	if team_zero_score > team_one_score:
		return "ПОБЕДА СИНИХ"
	if team_one_score > team_zero_score:
		return "ПОБЕДА КРАСНЫХ"
	return "НИЧЬЯ"
