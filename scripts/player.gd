extends CharacterBody3D
class_name LastLightPlayer
## Alex. First-person (or optional third-person) survivor controller:
## walk / sprint with stamina / crouch / jump / interact, flashlight, items,
## footstep noise that The Hollow can hear, hit invulnerability and death.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal hurt(amount: float)
signal died

@export var max_health := 100.0
@export var walk_speed := 3.5
@export var sprint_speed := 6.0
@export var crouch_speed := 1.6
@export var jump_velocity := 4.0
@export var mouse_sensitivity := 0.002
@export var touch_look_sensitivity := 0.005
@export var stamina_max := 100.0
@export var stamina_drain := 24.0
@export var stamina_recovery := 16.0
@export var hit_invulnerability := 0.8
@export var stand_height := 1.8
@export var crouch_height := 1.1
@export var flare_scene: PackedScene = preload("res://scenes/Flare.tscn")

var health: float
var stamina: float
var mobile_move := Vector2.ZERO
var mobile_sprint := false
var mobile_crouch := false
var can_move := true
var is_crouching := false
var is_sprinting := false
var third_person := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _exhausted := false
var _invulnerable := 0.0
var _step_timer := 0.0
var _bob_time := 0.0
var _shake := 0.0
var _head_stand_y := 1.62
var _head_target_y := 1.62

@onready var head: Node3D = $Head
@onready var camera_arm: SpringArm3D = $Head/CameraArm
@onready var camera: Camera3D = $Head/CameraArm/Camera3D
@onready var flashlight: FlashlightTool = $Head/Flashlight
@onready var inventory: LastLightInventory = $Inventory
@onready var interaction: PlayerInteraction = $Interaction
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var model: AlexModel = $AlexModel


func _ready() -> void:
	add_to_group("player")
	health = max_health
	stamina = stamina_max
	_head_stand_y = head.position.y
	_head_target_y = _head_stand_y
	# Own copy of the capsule so crouching never edits the shared resource.
	collision.shape = collision.shape.duplicate()
	camera_arm.add_excluded_object(get_rid())
	SaveSystem.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, stamina_max)


func _unhandled_input(event: InputEvent) -> void:
	if not can_move:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_apply_look(motion.relative * mouse_sensitivity * float(SaveSystem.settings["look_sensitivity"]))
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if not SaveSystem.touch_controls_enabled() and not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("flashlight"):
		flashlight.toggle_flashlight()
	elif event.is_action_pressed("use_flare"):
		use_item("flare")
	elif event.is_action_pressed("toggle_view"):
		SaveSystem.set_setting("third_person", not third_person)


func _physics_process(delta: float) -> void:
	_invulnerable = maxf(0.0, _invulnerable - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not can_move:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		move_and_slide()
		return

	var want_crouch := mobile_crouch or Input.is_action_pressed("crouch")
	if want_crouch != is_crouching and (want_crouch or _can_stand()):
		_set_crouch(want_crouch)

	if is_on_floor() and Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = jump_velocity
		model.play("jump")
		make_noise(0.6)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if mobile_move.length() > 0.08:
		input_dir = mobile_move.limit_length()
	var moving := input_dir.length() > 0.1

	if stamina <= 0.0:
		_exhausted = true
	elif stamina > stamina_max * 0.25:
		_exhausted = false
	var wants_sprint := (mobile_sprint or Input.is_action_pressed("sprint")) and moving and not is_crouching and not _exhausted

	var speed := walk_speed * clampf(input_dir.length(), 0.35, 1.0)
	is_sprinting = false
	if is_crouching:
		speed = crouch_speed
	elif wants_sprint:
		speed = sprint_speed
		is_sprinting = true
		stamina = maxf(0.0, stamina - stamina_drain * delta)
	if not is_sprinting:
		stamina = minf(stamina_max, stamina + stamina_recovery * delta * (0.6 if moving else 1.0))
	stamina_changed.emit(stamina, stamina_max)

	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var accel := 12.0 if is_on_floor() else 3.0
	if moving:
		velocity.x = move_toward(velocity.x, direction.x * speed, accel * speed * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, accel * speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 6.0 * delta)
	move_and_slide()

	var flat_speed := Vector2(velocity.x, velocity.z).length()
	_update_footsteps(delta, flat_speed)
	_update_camera(delta, flat_speed)
	model.animate(delta, flat_speed, is_crouching, is_on_floor(), is_sprinting)


# --- Look -------------------------------------------------------------------

func add_touch_look(relative_pixels: Vector2) -> void:
	if can_move:
		_apply_look(relative_pixels * touch_look_sensitivity * float(SaveSystem.settings["look_sensitivity"]))


func _apply_look(amount: Vector2) -> void:
	var invert := -1.0 if bool(SaveSystem.settings["invert_y"]) else 1.0
	rotate_y(-amount.x)
	head.rotate_x(-amount.y * invert)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))


func set_third_person(enabled: bool) -> void:
	third_person = enabled
	camera_arm.spring_length = 2.6 if enabled else 0.0
	camera_arm.position = Vector3(0.45, 0.2, 0.0) if enabled else Vector3.ZERO
	model.visible = enabled
	flashlight.set_body_visible(not enabled)


# --- Mobile hooks (called by MobileControls) ---------------------------------

func set_mobile_movement(value: Vector2) -> void:
	mobile_move = value.limit_length()


func set_mobile_sprint(value: bool) -> void:
	mobile_sprint = value


func set_mobile_crouch(value: bool) -> void:
	mobile_crouch = value


# --- Items ------------------------------------------------------------------

func use_item(item_id: String) -> bool:
	if not can_move or not inventory.has_item(item_id):
		return false
	match item_id:
		"battery":
			if flashlight.battery >= flashlight.max_battery - 1.0:
				_notify("The flashlight is already full.")
				return false
			inventory.use_item(item_id)
			flashlight.add_battery(60.0)
			_notify("Flashlight recharged.")
		"medkit":
			if health >= max_health:
				_notify("You're not hurt.")
				return false
			inventory.use_item(item_id)
			heal(45.0)
			_notify("Used a medkit.")
		"bandage":
			if health >= max_health:
				_notify("You're not hurt.")
				return false
			inventory.use_item(item_id)
			heal(20.0)
			_notify("Used a bandage.")
		"flare":
			inventory.use_item(item_id)
			_throw_flare()
		_:
			_notify("Use fuses at the emergency gate control box.")
			return false
	model.play("interact")
	return true


func _throw_flare() -> void:
	if flare_scene == null:
		return
	var flare := flare_scene.instantiate() as RigidBody3D
	get_tree().current_scene.add_child(flare)
	var forward := -camera.global_transform.basis.z
	flare.global_position = head.global_position + forward * 0.7
	flare.linear_velocity = forward * 9.0 + Vector3.UP * 3.0 + velocity * 0.5
	flare.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
	_notify("Flare thrown. The Hollow will go for the light.")


func on_interacted() -> void:
	model.play("interact")


# --- Health -----------------------------------------------------------------

func take_damage(amount: float) -> void:
	if _invulnerable > 0.0 or health <= 0.0:
		return
	health = clampf(health - amount, 0.0, max_health)
	_invulnerable = hit_invulnerability
	_shake = 0.45
	health_changed.emit(health, max_health)
	hurt.emit(amount)
	model.play("hurt")
	_play_sfx("hurt")
	if bool(SaveSystem.settings["vibration"]):
		Input.vibrate_handheld(250)
	if health <= 0.0:
		_die()


func heal(amount: float) -> void:
	health = clampf(health + amount, 0.0, max_health)
	health_changed.emit(health, max_health)


func _die() -> void:
	can_move = false
	mobile_move = Vector2.ZERO
	model.play("death")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(head, "position:y", 0.35, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(head, "rotation:z", 0.7, 0.8)
	died.emit()


# --- Noise, footsteps, camera -----------------------------------------------

## Tells every monster in hearing range about a sound at the player's position.
func make_noise(loudness: float) -> void:
	for monster in get_tree().get_nodes_in_group("monster"):
		if monster.has_method("hear_sound"):
			monster.call("hear_sound", global_position, loudness)


func _update_footsteps(delta: float, flat_speed: float) -> void:
	if not is_on_floor() or flat_speed < 0.5:
		_step_timer = 0.0
		return
	var interval := 0.5
	var loudness := 0.4
	if is_sprinting:
		interval = 0.32
		loudness = 1.0
	elif is_crouching:
		interval = 0.7
		loudness = 0.08
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = interval
		make_noise(loudness)
		_play_sfx("footstep", 0.35 + loudness * 0.5)


func _update_camera(delta: float, flat_speed: float) -> void:
	head.position.y = lerpf(head.position.y, _head_target_y, 10.0 * delta)
	var bob := Vector2.ZERO
	if is_on_floor() and flat_speed > 0.5 and not third_person:
		_bob_time += delta * flat_speed * 2.2
		bob = Vector2(cos(_bob_time * 0.5) * 0.03, sin(_bob_time) * 0.04)
	_shake = maxf(0.0, _shake - delta)
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.15
	camera.h_offset = bob.x + shake.x
	camera.v_offset = bob.y + shake.y


func _set_crouch(enabled: bool) -> void:
	is_crouching = enabled
	var capsule := collision.shape as CapsuleShape3D
	capsule.height = crouch_height if enabled else stand_height
	collision.position.y = capsule.height * 0.5
	_head_target_y = _head_stand_y - (stand_height - crouch_height) if enabled else _head_stand_y


func _can_stand() -> bool:
	return not test_move(global_transform, Vector3.UP * (stand_height - crouch_height))


func _on_settings_changed() -> void:
	set_third_person(bool(SaveSystem.settings["third_person"]))


func _notify(text: String) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as LastLightGameManager
	if gm != null:
		gm.notify(text)


func _play_sfx(sfx: String, volume := 1.0) -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx(sfx, volume)
