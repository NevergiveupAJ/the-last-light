extends Node
## Renders preview screenshots. Needs a display (e.g. xvfb-run):
##   godot --path . --rendering-driver opengl3 res://tests/screenshots.tscn -- OUT_DIR
const SHOTS := [
	# name, player position, yaw degrees, pitch degrees, third person, monster position (or null)
	["01_forest_entrance", Vector3(0, 0.1, 17), 0.0, -2.0, false, null],
	["02_cabins", Vector3(-17, 0.1, -10), 60.0, -4.0, false, null],
	["03_generator_inside", Vector3(24, 0.1, -28), -100.0, -8.0, false, null],
	["04_research_facility", Vector3(0, 0.1, -42), 0.0, 4.0, false, null],
	["05_server_room", Vector3(6, 0.1, -66), -60.0, -12.0, false, null],
	["06_tunnels", Vector3(-38, -3.9, -82), 90.0, -5.0, false, null],
	["07_emergency_gate", Vector3(2, 0.1, -98), 0.0, 3.0, false, null],
	["08_the_hollow", Vector3(0, 0.1, -36), 0.0, 6.0, false, Vector3(0, 0.1, -41)],
	["09_alex_third_person", Vector3(0, 0.1, -30), 180.0, -8.0, true, Vector3(1.5, 0.1, -36)],
]
var out_dir := "user://shots"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveSystem.settings["touch_controls"] = "on"
	SaveSystem.settings["third_person"] = false
	var menu: Node = load("res://scenes/MainMenu.tscn").instantiate()
	add_child(menu)
	await _frames(20)
	_save("00_main_menu")
	menu.queue_free()
	await _frames(2)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	var player: LastLightPlayer = main.get_node("Player")
	var monster: TheHollowAI = main.get_node("TheHollow")
	var weather: WeatherSystem = main.get_node("Weather")
	weather.set_process(false)
	main.get_node("HUD").show_message("", 0.0)
	await _frames(30)
	for shot in SHOTS:
		monster.set_physics_process(false)
		monster.global_position = shot[5] if shot[5] != null else Vector3(60, 0.1, 15)
		monster.rotation.y = 0.0
		if shot[5] != null:
			var to_player: Vector3 = shot[1] - shot[5]
			monster.rotation.y = atan2(-to_player.x, -to_player.z)
		SaveSystem.set_setting("third_person", shot[4])
		player.global_position = shot[1]
		player.velocity = Vector3.ZERO
		player.rotation.y = deg_to_rad(shot[2])
		player.head.rotation.x = deg_to_rad(shot[3])
		monster.get_node("ModelRoot").animate(0.016, 0.0, "investigate")
		await _frames(25)
		_save(shot[0])
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _save(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(shot_name + ".png"))
	print("saved ", shot_name)
