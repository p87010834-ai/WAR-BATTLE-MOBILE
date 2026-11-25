extends RefCounted
class_name WbmLocalization

static var current_language := "ru"
const TEXT := {
	"ru": {"play": "ИГРАТЬ", "settings": "НАСТРОЙКИ", "hangar": "АНГАР", "shop": "МАГАЗИН", "battle": "БОЙ", "victory": "ПОБЕДА", "defeat": "ПОРАЖЕНИЕ", "repair": "РЕМОНТ"},
	"en": {"play": "PLAY", "settings": "SETTINGS", "hangar": "HANGAR", "shop": "SHOP", "battle": "BATTLE", "victory": "VICTORY", "defeat": "DEFEAT", "repair": "REPAIR"}
}

static func set_language(language: String) -> void:
	current_language = "en" if language == "en" else "ru"

static func translate_text(key: String) -> String:
	var dictionary: Dictionary = TEXT.get(current_language, TEXT["ru"])
	return str(dictionary.get(key, key))
