extends RefCounted
class_name WbmSettingsManager

const SAVE_PATH := "user://wbm_settings.cfg"
var master_volume := 0.8
var music_volume := 0.65
var effects_volume := 0.85
var sensitivity := 1.0
var graphics_quality := 1
var language := "ru"
var vibration_enabled := true
var aim_assist_enabled := false

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	master_volume = clampf(float(cfg.get_value("audio", "master", 0.8)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music", 0.65)), 0.0, 1.0)
	effects_volume = clampf(float(cfg.get_value("audio", "effects", 0.85)), 0.0, 1.0)
	sensitivity = clampf(float(cfg.get_value("controls", "sensitivity", 1.0)), 0.25, 2.5)
	graphics_quality = clampi(int(cfg.get_value("graphics", "quality", 1)), 0, 2)
	language = str(cfg.get_value("interface", "language", "ru"))
	vibration_enabled = bool(cfg.get_value("controls", "vibration", true))
	aim_assist_enabled = bool(cfg.get_value("controls", "aim_assist", false))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "effects", effects_volume)
	cfg.set_value("controls", "sensitivity", sensitivity)
	cfg.set_value("controls", "vibration", vibration_enabled)
	cfg.set_value("controls", "aim_assist", aim_assist_enabled)
	cfg.set_value("graphics", "quality", graphics_quality)
	cfg.set_value("interface", "language", language)
	cfg.save(SAVE_PATH)

func apply_audio() -> void:
	AudioServer.set_bus_volume_linear(0, master_volume)
