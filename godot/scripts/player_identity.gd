extends RefCounted
class_name WbmPlayerIdentity

const MIN_NAME_LENGTH := 3
const MAX_NAME_LENGTH := 16

static func validate_username(value: String) -> Dictionary:
	var username := value.strip_edges()
	if username.length() < MIN_NAME_LENGTH or username.length() > MAX_NAME_LENGTH:
		return {"valid": false, "reason": "Имя должно содержать от 3 до 16 символов"}
	for index in range(username.length()):
		var code := username.unicode_at(index)
		var allowed := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 0x0400 and code <= 0x04FF) or code == 95 or code == 45
		if not allowed:
			return {"valid": false, "reason": "Разрешены кириллица, латиница, цифры, _ и -"}
	return {"valid": true, "reason": ""}
