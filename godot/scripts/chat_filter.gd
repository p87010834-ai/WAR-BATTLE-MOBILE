extends RefCounted
class_name WbmChatFilter

const MAX_MESSAGE_LENGTH := 240
const BLOCKED_TERMS := ["бля", "хуй", "пизд", "еба", "сука", "мудак"]

static func sanitize_message(raw_text: String) -> String:
	var cleaned := raw_text.strip_edges()
	cleaned = cleaned.replace("\n", " ").replace("\r", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	if cleaned.length() > MAX_MESSAGE_LENGTH:
		cleaned = cleaned.substr(0, MAX_MESSAGE_LENGTH)
	var lowered := cleaned.to_lower()
	for term in BLOCKED_TERMS:
		if not term.is_empty():
			var start := lowered.find(term)
			while start >= 0:
				var replacement := "*".repeat(term.length())
				cleaned = cleaned.substr(0, start) + replacement + cleaned.substr(start + term.length())
				lowered = cleaned.to_lower()
				start = lowered.find(term, start + replacement.length())
	return cleaned

static func is_message_allowed(raw_text: String) -> bool:
	return not sanitize_message(raw_text).strip_edges().is_empty()
