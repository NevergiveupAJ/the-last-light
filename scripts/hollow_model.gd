extends Node3D
class_name HollowModel
## The Hollow's body. Loads assets/models/monsters/the_hollow.glb when it exists and plays
## its animations (idle, patrol, investigate, chase, attack, search, death). Otherwise it
## builds a primitive stand-in from the design sheet: ~2.5 m, tall and thin, long arms
## reaching past the knees, crooked shoulders, pale decayed skin, torn dark cloth,
## a featureless face and glowing amber eyes.

const MODEL_PATH := "res://assets/models/monsters/the_hollow.glb"

var _imported: Node3D
var _anim: AnimationPlayer
var _torso: Node3D
var _neck: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _fore_l: Node3D
var _fore_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _phase := 0.0
var _time := 0.0
var _action := ""
var _action_time := 0.0
var _twitch := 0.0


func _ready() -> void:
	if ResourceLoader.exists(MODEL_PATH):
		var packed := load(MODEL_PATH) as PackedScene
		if packed != null:
			_imported = packed.instantiate() as Node3D
			add_child(_imported)
			_anim = _imported.find_child("AnimationPlayer", true, false) as AnimationPlayer
			return
	_build_placeholder()


func play(action: String) -> void:
	_action = action
	_action_time = 0.0
	if _anim != null and _anim.has_animation(action):
		_anim.play(action)


func animate(delta: float, flat_speed: float, state_name: String) -> void:
	_time += delta
	_action_time += delta
	if _imported != null:
		_play_imported(state_name)
		return
	if _torso == null:
		return

	var chasing := state_name == "chase"
	var stride := clampf(flat_speed / 4.5, 0.0, 1.0)
	_phase += delta * (2.5 + flat_speed * 1.6)
	var swing := sin(_phase) * (0.15 + 0.55 * stride) if flat_speed > 0.2 else 0.0

	_leg_l.rotation.x = swing
	_leg_r.rotation.x = -swing
	_torso.rotation.x = lerpf(_torso.rotation.x, -0.45 if chasing else -0.12, 6.0 * delta)
	_torso.scale.y = 1.0 + sin(_time * 1.3) * 0.012

	var arm_l := -swing * 0.9 + 0.1
	var arm_r := swing * 0.9 + 0.1
	var fore := 0.2 + absf(swing) * 0.4
	if chasing:
		arm_l = -0.6 + swing * 1.3
		arm_r = -0.6 - swing * 1.3

	# Head behaviour: scanning while searching, small twitches the rest of the time.
	var head_yaw := 0.0
	var head_roll := 0.0
	if state_name == "search" or state_name == "investigate":
		head_yaw = sin(_time * 1.6) * 0.9
		head_roll = sin(_time * 0.9) * 0.35
	_twitch -= delta
	if _twitch <= 0.0:
		_twitch = randf_range(1.5, 4.0)
		_neck.rotation.z = randf_range(-0.5, 0.5)
	_neck.rotation.y = lerpf(_neck.rotation.y, head_yaw, 4.0 * delta)
	_neck.rotation.z = lerpf(_neck.rotation.z, head_roll, 2.0 * delta)

	if _action == "attack" and _action_time < 0.9:
		var t := _action_time
		var raise := clampf(t / 0.4, 0.0, 1.0)
		var slash := clampf((t - 0.45) / 0.15, 0.0, 1.0)
		arm_l = lerpf(2.4 * raise, 0.4, slash)
		arm_r = lerpf(2.4 * raise, 0.4, slash)
		fore = 0.6
		_torso.rotation.x = lerpf(0.15, -0.6, slash)
	elif _action == "death":
		rotation.x = lerpf(rotation.x, -PI * 0.5, 3.0 * delta)

	_arm_l.rotation.x = lerpf(_arm_l.rotation.x, arm_l, 10.0 * delta)
	_arm_r.rotation.x = lerpf(_arm_r.rotation.x, arm_r, 10.0 * delta)
	_fore_l.rotation.x = fore
	_fore_r.rotation.x = fore


func _play_imported(state_name: String) -> void:
	if _anim == null:
		return
	var wanted := state_name
	if _action == "attack" and _action_time < 0.9:
		wanted = "attack"
	elif _action == "death":
		wanted = "death"
	if state_name == "attack" and _action != "attack":
		wanted = "idle"
	if not _anim.has_animation(wanted):
		wanted = "idle"
	if _anim.has_animation(wanted) and _anim.current_animation != wanted:
		_anim.play(wanted, 0.25)


func _build_placeholder() -> void:
	var skin := PrimitiveKit.mat(Color(0.72, 0.69, 0.62), 0.95)
	var skin_dark := PrimitiveKit.mat(Color(0.5, 0.47, 0.42), 0.95)
	var cloth := PrimitiveKit.mat(Color(0.08, 0.07, 0.07), 1.0)
	var eye := PrimitiveKit.mat(Color(1.0, 0.6, 0.15), 0.4, 0.0, Color(1.0, 0.55, 0.1), 6.0)

	# Legs: hips at 1.2 m.
	_leg_l = PrimitiveKit.pivot(self, "LegL", Vector3(-0.12, 1.2, 0.0))
	_leg_r = PrimitiveKit.pivot(self, "LegR", Vector3(0.12, 1.2, 0.0))
	for leg in [_leg_l, _leg_r]:
		PrimitiveKit.capsule(leg, 0.065, 1.22, skin, Vector3(0, -0.6, 0))
		PrimitiveKit.sphere(leg, 0.075, skin_dark, Vector3(0, -0.6, -0.01))
		PrimitiveKit.box(leg, Vector3(0.1, 0.05, 0.26), skin_dark, Vector3(0, -1.18, -0.06))

	# Torso, ribs and torn cloth.
	_torso = PrimitiveKit.pivot(self, "Torso", Vector3(0, 1.2, 0))
	PrimitiveKit.box(_torso, Vector3(0.3, 0.16, 0.16), skin_dark, Vector3(0, 0.06, 0))
	var spine := PrimitiveKit.capsule(_torso, 0.13, 0.9, skin, Vector3(0, 0.46, 0.02))
	spine.scale = Vector3(1.0, 1.0, 0.75)
	for i in 5:
		PrimitiveKit.box(_torso, Vector3(0.24 - i * 0.012, 0.014, 0.03), skin_dark, Vector3(0, 0.5 + i * 0.07, -0.085))
	PrimitiveKit.box(_torso, Vector3(0.34, 0.26, 0.2), cloth, Vector3(0, 0.02, 0), Vector3(0, 0, 4))
	PrimitiveKit.box(_torso, Vector3(0.12, 0.34, 0.02), cloth, Vector3(0.1, -0.2, -0.1), Vector3(0, 0, -8))

	# Crooked shoulders and long arms (upper arm + forearm + claws).
	_arm_l = PrimitiveKit.pivot(_torso, "ArmL", Vector3(-0.21, 0.88, 0))
	_arm_r = PrimitiveKit.pivot(_torso, "ArmR", Vector3(0.23, 0.81, 0))
	_arm_l.rotation.z = -0.08
	_arm_r.rotation.z = 0.12
	_fore_l = _build_arm(_arm_l, skin, skin_dark)
	_fore_r = _build_arm(_arm_r, skin, skin_dark)

	# Long neck, featureless elongated head, amber eyes.
	_neck = PrimitiveKit.pivot(_torso, "Neck", Vector3(0.02, 0.95, -0.03))
	PrimitiveKit.capsule(_neck, 0.045, 0.2, skin_dark, Vector3(0, 0.06, 0))
	PrimitiveKit.sphere(_neck, 0.11, skin, Vector3(0, 0.2, -0.01), Vector3(0.85, 1.35, 0.95))
	PrimitiveKit.sphere(_neck, 0.018, eye, Vector3(-0.04, 0.21, -0.1))
	PrimitiveKit.sphere(_neck, 0.018, eye, Vector3(0.04, 0.21, -0.1))
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.55, 0.15)
	glow.light_energy = 0.8
	glow.omni_range = 2.4
	glow.position = Vector3(0, 0.21, -0.18)
	_neck.add_child(glow)


func _build_arm(shoulder: Node3D, skin: Material, skin_dark: Material) -> Node3D:
	PrimitiveKit.sphere(shoulder, 0.06, skin_dark)
	PrimitiveKit.capsule(shoulder, 0.05, 0.62, skin, Vector3(0, -0.31, 0))
	var elbow := PrimitiveKit.pivot(shoulder, "Elbow", Vector3(0, -0.62, 0))
	PrimitiveKit.capsule(elbow, 0.042, 0.78, skin, Vector3(0, -0.39, 0))
	for i in 3:
		PrimitiveKit.capsule(elbow, 0.012, 0.24, skin_dark, Vector3((i - 1) * 0.025, -0.86, -0.01), Vector3(-10, 0, (i - 1) * 8))
	return elbow
