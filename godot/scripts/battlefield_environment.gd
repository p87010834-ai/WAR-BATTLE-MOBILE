extends Node3D
class_name WbmBattlefieldEnvironment

# Original lightweight battlefield set dressing. Visual-only props keep the
# current prototype mobile-friendly; production collision/navigation is separate.

var _materials: Dictionary = {}

func _ready() -> void:
	_make_materials()
	_add_roads()
	_add_ruins()
	_add_trench_sections()
	_add_barriers_and_sandbags()
	_add_craters_and_debris()
	_add_forest_details()
	_add_outpost()

func _make_materials() -> void:
	_materials["road"] = _mat(Color(0.16, 0.17, 0.15), 1.0)
	_materials["concrete"] = _mat(Color(0.34, 0.34, 0.31), 0.94)
	_materials["broken"] = _mat(Color(0.23, 0.23, 0.21), 1.0)
	_materials["brick"] = _mat(Color(0.31, 0.22, 0.17), 0.96)
	_materials["sand"] = _mat(Color(0.43, 0.38, 0.27), 1.0)
	_materials["metal"] = _mat(Color(0.12, 0.15, 0.15), 0.72)
	_materials["wood"] = _mat(Color(0.20, 0.14, 0.09), 1.0)
	_materials["crater"] = _mat(Color(0.075, 0.078, 0.068), 1.0)
	_materials["grass"] = _mat(Color(0.18, 0.22, 0.13), 1.0)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material, yaw: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.rotation.y = yaw
	parent.add_child(instance)
	return instance

func _cylinder(parent: Node3D, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _add_roads() -> void:
	# A broken, branching supply road across the combat area.
	var segments := [
		[Vector3(-62.0, 0.025, 12.0), 0.0, Vector3(24.0, 0.05, 5.5)],
		[Vector3(-38.0, 0.025, 12.0), 0.0, Vector3(24.0, 0.05, 5.5)],
		[Vector3(-14.0, 0.025, 12.0), 0.0, Vector3(24.0, 0.05, 5.5)],
		[Vector3(10.0, 0.025, 12.0), 0.0, Vector3(24.0, 0.05, 5.5)],
		[Vector3(34.0, 0.025, 12.0), 0.0, Vector3(24.0, 0.05, 5.5)],
		[Vector3(58.0, 0.025, 12.0), 0.0, Vector3(24.0, 0.05, 5.5)],
		[Vector3(0.0, 0.03, -24.0), 1.5708, Vector3(5.0, 0.05, 38.0)]
	]
	for segment in segments:
		_box(self, segment[2], segment[0], _materials["road"], segment[1])
	for road_x: float in [-49.0, -25.0, 23.0, 47.0]:
		_box(self, Vector3(1.2, 0.055, 5.8), Vector3(road_x, 0.06, 12.0), _materials["concrete"], 0.0)

func _add_ruins() -> void:
	var sites := [Vector3(-55.0, 0.0, -43.0), Vector3(55.0, 0.0, -42.0), Vector3(-58.0, 0.0, 48.0), Vector3(58.0, 0.0, 47.0)]
	for index in range(sites.size()):
		var site := Node3D.new()
		site.position = sites[index]
		add_child(site)
		var yaw := float(index) * 0.63
		_box(site, Vector3(10.0, 0.45, 0.8), Vector3(0.0, 1.5, -4.0), _materials["brick"], yaw)
		_box(site, Vector3(0.8, 2.8, 7.0), Vector3(-4.4, 1.4, 0.0), _materials["concrete"], yaw)
		_box(site, Vector3(7.0, 1.0, 0.65), Vector3(1.8, 0.5, 3.5), _materials["brick"], yaw)
		_box(site, Vector3(0.8, 1.4, 4.2), Vector3(4.2, 0.7, -1.4), _materials["broken"], yaw)
		for piece in range(7):
			var rubble := _box(site, Vector3(randf_range(0.35, 1.3), randf_range(0.2, 0.65), randf_range(0.3, 1.1)), Vector3(randf_range(-5.0, 5.0), 0.25, randf_range(-5.0, 5.0)), _materials["broken"], randf_range(0.0, TAU))
			rubble.scale.y = randf_range(0.7, 1.4)

func _add_trench_sections() -> void:
	for side in [-1.0, 1.0]:
		for i in range(8):
			var x: float = side * (18.0 + float(i) * 3.0)
			var z := -11.0 if i % 2 == 0 else -13.0
			_box(self, Vector3(2.8, 0.65, 0.55), Vector3(x, 0.33, z), _materials["sand"], 0.0)
			_box(self, Vector3(0.55, 0.65, 2.2), Vector3(x + 1.35, 0.33, z + 0.9), _materials["sand"], 0.0)
		_box(self, Vector3(28.0, 0.08, 2.0), Vector3(side * 28.0, 0.02, -15.0), _materials["crater"])

func _add_barriers_and_sandbags() -> void:
	for i in range(12):
		var x: float = -48.0 + float(i) * 8.5
		if absf(x) < 15.0:
			continue
		_box(self, Vector3(3.2, 0.85, 0.65), Vector3(x, 0.43, 28.0), _materials["concrete"], 0.0)
		_box(self, Vector3(2.2, 0.42, 0.55), Vector3(x + 0.4, 0.95, 27.8), _materials["sand"], 0.0)
	for side in [-1.0, 1.0]:
		for row in range(3):
			for col in range(5):
				var bag := _box(self, Vector3(1.0, 0.42, 0.55), Vector3(side * (35.0 + float(col) * 1.0), 0.22 + float(row) * 0.4, -3.0 + float(row % 2) * 0.35), _materials["sand"], 0.0)
				bag.rotation.z = randf_range(-0.05, 0.05)

func _add_craters_and_debris() -> void:
	for i in range(24):
		var crater := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = randf_range(0.7, 1.8)
		mesh.bottom_radius = mesh.top_radius * 1.2
		mesh.height = 0.06
		mesh.radial_segments = 12
		crater.mesh = mesh
		crater.material_override = _materials["crater"]
		crater.position = Vector3(randf_range(-72.0, 72.0), 0.04, randf_range(-62.0, 62.0))
		if Vector2(crater.position.x, crater.position.z - 18.0).length() > 16.0:
			add_child(crater)
	for i in range(32):
		var debris := _box(self, Vector3(randf_range(0.25, 1.0), randf_range(0.12, 0.35), randf_range(0.2, 0.8)), Vector3(randf_range(-70.0, 70.0), 0.12, randf_range(-65.0, 65.0)), _materials["broken"], randf_range(0.0, TAU))
		debris.scale.y = randf_range(0.6, 1.2)

func _add_forest_details() -> void:
	for i in range(54):
		var x: float = randf_range(-86.0, 86.0)
		var z: float = randf_range(-78.0, 68.0)
		if Vector2(x, z - 18.0).length() < 38.0:
			continue
		var trunk_height := randf_range(2.4, 4.2)
		_cylinder(self, randf_range(0.10, 0.19), trunk_height, Vector3(x, trunk_height * 0.5, z), _materials["wood"])
		for tier in range(3):
			var crown := MeshInstance3D.new()
			var crown_mesh := CylinderMesh.new()
			crown_mesh.top_radius = 0.04
			crown_mesh.bottom_radius = randf_range(1.0, 1.65) * (1.0 - float(tier) * 0.16)
			crown_mesh.height = randf_range(1.7, 2.5)
			crown_mesh.radial_segments = 8
			crown.mesh = crown_mesh
			crown.material_override = _materials["grass"]
			crown.position = Vector3(x, 2.0 + float(tier) * 1.1, z)
			add_child(crown)

func _add_outpost() -> void:
	var tower := Node3D.new()
	tower.position = Vector3(0.0, 0.0, -51.0)
	add_child(tower)
	for corner in [Vector2(-1.4, -1.4), Vector2(1.4, -1.4), Vector2(-1.4, 1.4), Vector2(1.4, 1.4)]:
		_cylinder(tower, 0.12, 5.0, Vector3(corner.x, 2.5, corner.y), _materials["metal"])
	_box(tower, Vector3(3.4, 0.18, 3.4), Vector3(0.0, 4.7, 0.0), _materials["wood"])
	_box(tower, Vector3(4.0, 0.18, 4.0), Vector3(0.0, 5.2, 0.0), _materials["metal"])
	_box(tower, Vector3(3.8, 0.15, 3.8), Vector3(0.0, 6.8, 0.0), _materials["wood"])
	_cylinder(tower, 0.045, 2.0, Vector3(0.0, 7.8, 0.0), _materials["metal"])
