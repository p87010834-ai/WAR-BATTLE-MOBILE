extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game := MAIN_SCENE.instantiate() as Node3D
	if game == null:
		push_error("SMOKE TEST: main scene could not be instantiated")
		quit(1)
		return
	root.add_child(game)
	await process_frame
	await process_frame
	await create_timer(1.0).timeout

	var player := game.get("player") as Node3D
	var points: Array = game.get("capture_points")
	var enemies: Array = game.get("enemies")
	var allies: Array = game.get("allies")
	var active_vehicle := game.get("active_vehicle") as Node3D
	var ui := root.get_tree().get_first_node_in_group("game_ui_manager")
	var manager := root.get_tree().get_first_node_in_group("game_manager")
	var controls := root.get_tree().get_first_node_in_group("game_touch_controls")

	if not is_instance_valid(player):
		push_error("SMOKE TEST: player tank was not spawned")
		quit(1)
		return
	if points.size() != 3:
		push_error("SMOKE TEST: expected three capture points, got %d" % points.size())
		quit(1)
		return
	if enemies.is_empty() or allies.is_empty():
		push_error("SMOKE TEST: both bot teams must spawn")
		quit(1)
		return
	if not is_instance_valid(active_vehicle) or active_vehicle != player:
		push_error("SMOKE TEST: player must start in the tank")
		quit(1)
		return
	if ui == null or manager == null or controls == null:
		push_error("SMOKE TEST: gameplay UI or game manager is missing")
		quit(1)
		return
	if game.get("current_vehicle_mode") != "tank":
		push_error("SMOKE TEST: initial vehicle mode is not tank")
		quit(1)
		return

	print("SMOKE TEST PASSED: scene, player tank, AI teams, 3 capture points, HUD and touch controls initialized")
	quit(0)
