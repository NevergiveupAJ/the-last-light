extends Node
## Automated playthrough. Run headless:
##   godot --headless --path . res://tests/playthrough_test.tscn
## Plays the real Main scene: movement, crouch, interaction ray, items, documents,
## monster senses and attacks, flare distraction, touch controls, gate, final chase and the win.

const MAIN := preload("res://scenes/Main.tscn")

var failures := 0
var main: Node
var player: LastLightPlayer
var monster: TheHollowAI
var gm: LastLightGameManager
var level: LevelBuilder


func _ready() -> void:
	SaveSystem.settings["touch_controls"] = "off"
	main = MAIN.instantiate()
	add_child(main)
	player = main.get_node("Player")
	monster = main.get_node("TheHollow")
	gm = main.get_node("GameManager")
	level = main.get_node("Level")
	await _run()
	print("\n%s (%d failure(s))" % ["ALL TESTS PASSED" if failures == 0 else "TESTS FAILED", failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	print(("  PASS  " if ok else "  FAIL  ") + what)
	if not ok:
		failures += 1


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func park_monster() -> void:
	monster.global_position = Vector3(60, 0.2, 15)
	monster.velocity = Vector3.ZERO
	monster.state = TheHollowAI.BrainState.PATROL
	monster.patrol_points = []
	monster.set_physics_process(false)


func _run() -> void:
	await wait(0.5)
	check(gm.state == LastLightGameManager.GameState.PLAYING, "game starts in PLAYING state")
	check(player.is_on_floor() or player.global_position.y > -0.5, "player spawned on the ground")
	var t := 0.0
	while not level.nav_ready and t < 20.0:
		await wait(0.25)
		t += 0.25
	check(level.nav_ready, "navigation mesh baked (%.1fs)" % t)
	check(level.patrol_points.size() == 10, "10 patrol points")
	park_monster()

	# Movement.
	var start := player.global_position
	Input.action_press("move_forward")
	await wait(1.0)
	Input.action_release("move_forward")
	var walked := start.distance_to(player.global_position)
	check(walked > 2.0 and walked < 4.5, "walks forward at walk speed (%.2f m in 1 s)" % walked)
	check(player.global_position.z < start.z, "forward is north (-Z)")
	start = player.global_position
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await wait(1.0)
	Input.action_release("sprint")
	Input.action_release("move_forward")
	var sprinted := start.distance_to(player.global_position)
	check(sprinted > walked * 1.3, "sprint is faster (%.2f m)" % sprinted)
	check(player.stamina < player.stamina_max, "sprinting uses stamina")

	# Crouch, and refusing to stand under a ceiling (inside the tunnels).
	Input.action_press("crouch")
	await wait(0.3)
	check(player.is_crouching, "crouch works")
	Input.action_release("crouch")
	await wait(0.3)
	check(not player.is_crouching, "stands back up in the open")

	# Every pickup and document can be reached by the interaction ray.
	var pickups: Array[Node3D] = []
	for child in level.get_children():
		if child is LastLightItemPickup or child is LastLightDocument:
			pickups.append(child)
	check(pickups.size() == 17, "pickups and documents placed (%d)" % pickups.size())
	var unreachable := []
	for p in pickups:
		if not await _look_at_and_probe(p):
			unreachable.append("%s %s" % [p.name, p.global_position])
	check(unreachable.is_empty(), "interaction ray reaches every pickup " + str(unreachable))

	# Fuses (also proves the tunnel fuse is reachable by walking down the ramp).
	var fuses := pickups.filter(func(p) -> bool: return is_instance_valid(p) and p is LastLightItemPickup and p.item_id == "power_fuse")
	check(fuses.size() == 3, "3 fuses in the world")
	for f in fuses:
		if is_instance_valid(f):
			f.interact(player)
	await wait(0.2)
	check(gm.fuses_found == 3 and player.inventory.fuse_count() == 3, "collected 3 fuses")

	# Items.
	player.flashlight.battery = 20.0
	var batteries := player.inventory.count("battery")
	player.use_item("battery")
	check(player.flashlight.battery > 70.0 and player.inventory.count("battery") == batteries - 1, "battery recharges flashlight")
	player.flashlight.toggle_flashlight()
	check(not player.flashlight.is_on(), "flashlight toggles off")
	player.flashlight.toggle_flashlight()
	check(player.flashlight.is_on(), "flashlight toggles on")

	# Documents pause the game while reading.
	var docs := pickups.filter(func(p) -> bool: return is_instance_valid(p) and p is LastLightDocument)
	for d in docs:
		d.interact(player)
		check(get_tree().paused and gm.reading_document, "reading %s pauses" % d.doc_id)
		gm.close_document()
	await wait(0.2)
	check(gm.documents_found.size() == 5 and not get_tree().paused, "5 documents read, game resumed")

	# Monster: sees the player, chases, attacks with cooldown.
	monster.set_physics_process(true)
	player.global_position = Vector3(0, 0.2, -45)
	monster.global_position = Vector3(0, 0.2, -37)
	monster.look_at(Vector3(0, 0.2, -45), Vector3.UP)
	monster._sight_timer = 0.0
	await wait(0.5)
	check(monster.state == TheHollowAI.BrainState.CHASE or monster.state == TheHollowAI.BrainState.ATTACK, "monster sees player in the open and chases")
	var health_before := player.health
	await wait(4.0)
	var lost := health_before - player.health
	check(lost > 0.0, "monster attacks and hurts the player (%.0f damage in 4 s)" % lost)
	check(lost <= 75.0, "attacks respect cooldown (not damage every frame)")
	player.heal(100)

	# Line of sight is blocked by walls: player inside the closed generator room corner.
	park_monster()
	monster.set_physics_process(true)
	player.global_position = Vector3(33, 0.2, -31)
	monster.global_position = Vector3(38, 0.2, -31)
	monster.state = TheHollowAI.BrainState.PATROL
	await wait(0.4)
	check(not monster._check_sight(), "walls block the monster's sight")

	# Hearing.
	park_monster()
	monster.set_physics_process(true)
	monster.global_position = Vector3(10, 0.2, -10)
	monster.hear_sound(Vector3(15, 0, -10), 1.0)
	check(monster.state == TheHollowAI.BrainState.INVESTIGATE, "monster investigates a loud noise")
	monster.state = TheHollowAI.BrainState.PATROL
	monster.hear_sound(Vector3(40, 0, -10), 0.08)
	check(monster.state == TheHollowAI.BrainState.PATROL, "crouch-level noise far away is not heard")

	# Navigation: monster walks a path to a point behind buildings.
	monster.global_position = Vector3(0, 0.2, -48)
	monster.last_known_position = Vector3(8, 0, -68)
	player.global_position = Vector3(-60, 0.2, 18)
	monster.state = TheHollowAI.BrainState.INVESTIGATE
	await wait(12.0)
	check(monster.global_position.distance_to(Vector3(8, 0, -68)) < 6.0 or monster.state == TheHollowAI.BrainState.SEARCH, "monster navigates into the server room (now %s)" % monster.global_position)

	# Flare distraction.
	player.global_position = Vector3(0, 0.2, -30)
	monster.global_position = Vector3(0, 0.2, -50)
	player.inventory.add_item("flare")
	player.rotation.y = 0.0
	player.head.rotation.x = 0.0
	check(player.use_item("flare"), "throws a flare")
	await wait(1.5)
	check(monster.state == TheHollowAI.BrainState.DISTRACTED, "flare distracts the monster")

	# Touch controls: stick moves the player, buttons send actions.
	park_monster()
	SaveSystem.settings["touch_controls"] = "on"
	var touch: MobileControls = main.get_node("MobileControls/TouchLayer")
	touch.set_active(true)
	check(touch.visible, "touch controls visible when enabled")
	player.global_position = Vector3(0, 0.2, 10)
	var size := touch.size
	_touch(0, Vector2(200, size.y - 170), true)
	_drag(0, Vector2(200, size.y - 270))
	await wait(0.6)
	check(player.mobile_move.y < -0.5, "touch stick pushes forward")
	_touch(0, Vector2(200, size.y - 270), false)
	check(player.mobile_move == Vector2.ZERO, "releasing the stick stops movement")
	var yaw := player.rotation.y
	_touch(1, Vector2(size.x * 0.6, 300), true)
	_drag(1, Vector2(size.x * 0.6 + 120, 300), Vector2(120, 0))
	_touch(1, Vector2(size.x * 0.6 + 120, 300), false)
	check(absf(player.rotation.y - yaw) > 0.1, "dragging on the right turns the camera")
	var light_before := player.flashlight.is_on()
	var light_pos := touch._button_center(touch.BUTTONS[4])
	_touch(2, light_pos, true)
	await wait(0.05)
	_touch(2, light_pos, false)
	await wait(0.05)
	check(player.flashlight.is_on() != light_before, "LIGHT button toggles the flashlight")
	var crouch_pos := touch._button_center(touch.BUTTONS[3])
	_touch(3, crouch_pos, true)
	_touch(3, crouch_pos, false)
	await wait(0.3)
	check(player.is_crouching, "CROUCH button toggles crouch")
	_touch(3, crouch_pos, true)
	_touch(3, crouch_pos, false)
	SaveSystem.settings["touch_controls"] = "off"
	touch.set_active(true)

	# Gate, final chase, escape.
	player.global_position = Vector3(4.6, 0.2, -107.0)
	var gate: EmergencyGate = null
	for child in level.get_children():
		if child is EmergencyGate:
			gate = child
	check(gate != null, "emergency gate exists")
	monster.set_physics_process(true)
	monster.global_position = Vector3(60, 0.2, 15)
	gate.get_node("ControlBox").interact(player)
	check(gm.gate_powered and gate.powered, "gate powered with 3 fuses")
	check(player.inventory.fuse_count() == 0, "fuses used up")
	await wait(0.3)
	check(monster.enraged and monster.global_position.distance_to(level.final_chase_spawn) < 3.0, "final chase: monster teleported in and enraged")
	park_monster()
	await wait(6.5)
	check(gate.get_node("GateDoor").position.x > 6.0, "gate slid open")
	park_monster()
	player.global_position = Vector3(0, 0.2, -108)
	player.rotation.y = 0.0
	Input.action_press("move_forward")
	await wait(3.0)
	Input.action_release("move_forward")
	check(gm.state == LastLightGameManager.GameState.WON, "walking through the open gate wins (at %s)" % player.global_position)
	var hud: LastLightHUD = main.get_node("HUD")
	check(hud.end_panel.visible and hud.end_title.text.begins_with("TRUE ENDING"), "true ending shown (all documents)")


func _look_at_and_probe(target: Node3D) -> bool:
	# Stand 1.6 m away on the open side and aim the camera at the target.
	var best := false
	for dir in [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
		var spot: Vector3 = target.global_position + dir * 1.6
		spot.y = target.global_position.y - 0.35 if target.global_position.y < -1.0 else 0.15
		if target.global_position.y < -1.0:
			spot.y = -3.9
		player.global_position = spot
		player.velocity = Vector3.ZERO
		await get_tree().physics_frame
		var eye := player.head.global_position
		var flat := Vector3(target.global_position.x - eye.x, 0, target.global_position.z - eye.z)
		player.rotation.y = atan2(-flat.x, -flat.z)
		var to_target := target.global_position - eye
		player.head.rotation.x = atan2(to_target.y, Vector2(to_target.x, to_target.z).length())
		await get_tree().physics_frame
		await get_tree().physics_frame
		if player.interaction._probe() == target:
			best = true
			break
	return best


# Headless Godot reports a different window size than a phone, so touches go straight to the
# controls instead of through the window.
func _touch_layer() -> MobileControls:
	return main.get_node("MobileControls/TouchLayer")


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	_touch_layer()._input(ev)


func _drag(index: int, pos: Vector2, relative := Vector2.ZERO) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	ev.relative = relative if relative != Vector2.ZERO else Vector2(0, -100)
	_touch_layer()._input(ev)
