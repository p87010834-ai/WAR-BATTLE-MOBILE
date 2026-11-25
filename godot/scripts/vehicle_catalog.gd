extends RefCounted
class_name WbmVehicleCatalog

const VEHICLES := [
	{"id": "tank_basic", "name": "Средний танк", "class": "tank", "unlock_level": 1, "role": "Наземная поддержка"},
	{"id": "fighter_basic", "name": "Истребитель", "class": "aircraft", "unlock_level": 3, "role": "Воздушное превосходство"},
	{"id": "destroyer_basic", "name": "Эсминец", "class": "ship", "unlock_level": 5, "role": "Морская поддержка"}
]

static func get_available(profile_level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in VEHICLES:
		if profile_level >= int(item.unlock_level):
			result.append(item)
	return result

static func get_by_id(vehicle_id: String) -> Dictionary:
	for item in VEHICLES:
		if str(item.id) == vehicle_id:
			return item
	return {}

static func get_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in VEHICLES:
		result.append(item)
	return result
