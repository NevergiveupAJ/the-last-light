extends Node3D
class_name AlexModel
## Alex's body (seen in third-person view). Loads assets/models/characters/alex.glb when it
## exists and plays its animations (idle, walk, run, crouch, jump, interact, hurt, death).
## Otherwise builds a primitive stand-in from the design sheet: 1.8 m, athletic, weatherproof
## olive jacket, charcoal tactical pants, mud-stained boots, emergency backpack, radio on the
## strap, flashlight in the right hand.

const MODEL_PATH := "res://assets/models/characters/alex.glb"
const OUTFITS := {
	"default": {"jacket": Color(0.24, 0.27, 0.17), "pants": Color(0.16, 0.16, 0.17)},
	"skin_raincoat": {"jacket": Color(0.1, 0.16, 0.27), "pants": Color(0.12, 0.12, 0.14)},
	"skin_hazmat": {"jacket": Color(0.86, 0.76, 0.28), "pants": Color(0.8, 0.72, 0.3)},
}

var _imported: Node3D
var _anim: AnimationPlayer
var _body: Node3D
var _torso: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _phase := 0.0
var _time := 0.0
var _action := ""
var _action_time := 0.0


func _ready() -> void:
	if ResourceLoader.exists(MODEL_PATH):
		var packed := load(MODEL_PATH) as PackedScene
		if packed != null:
			_imported = packed.instantiate() as Node3D
			add_child(_imported)
			_anim = _imported.find_child("AnimationPlayer", true, false) as AnimationPlayer
			return
	_build_placeholder(str(SaveSystem.cosmetics.get("equipped_outfit", "default")))


func play(action: String) -> void:
	_action = action
	_action_time = 0.0
	if _anim != null and _anim.has_animation(action):
		_anim.play(action, 0.15)


func animate(delta: float, flat_speed: float, crouching: bool, on_floor: bool, sprinting: bool) -> void:
	_time += delta
	_action_time += delta
	if _imported != null:
		_play_imported(flat_speed, crouching, on_floor, sprinting)
		return
	if _body == null:
		return
	if _action == "death":
		_body.rotation.x = lerpf(_body.rotation.x, PI * 0.5, 4.0 * delta)
		_body.position.y = lerpf(_body.position.y, 0.15, 4.0 * delta)
		return

	var moving := flat_speed > 0.3
	_phase += delta * (5.0 + flat_speed * 1.8) if moving else 0.0
	var amount := clampf(flat_speed / 6.0, 0.25, 0.85)
	var swing := sin(_phase) * amount if moving else 0.0

	var leg_l := swing
	var leg_r := -swing
	var arm_l := -swing * 0.8
	var arm_r := 0.9 + swing * 0.15  # right hand keeps the flashlight up
	var lean := -0.25 if sprinting else -0.05
	var drop := 0.0
	if crouching:
		drop = -0.35
		lean = -0.35
		leg_l = 0.9 + swing * 0.3
		leg_r = 0.9 - swing * 0.3
	if not on_floor:
		leg_l = 0.6
		leg_r = -0.2
		arm_l = 1.2
	if _action == "interact" and _action_time < 0.5:
		arm_l = 1.4
	if _action == "hurt" and _action_time < 0.3:
		lean = 0.3

	_leg_l.rotation.x = lerpf(_leg_l.rotation.x, leg_l, 12.0 * delta)
	_leg_r.rotation.x = lerpf(_leg_r.rotation.x, leg_r, 12.0 * delta)
	_arm_l.rotation.x = lerpf(_arm_l.rotation.x, arm_l, 12.0 * delta)
	_arm_r.rotation.x = lerpf(_arm_r.rotation.x, arm_r, 12.0 * delta)
	_torso.rotation.x = lerpf(_torso.rotation.x, lean, 8.0 * delta)
	_body.position.y = lerpf(_body.position.y, drop, 10.0 * delta)
	_torso.scale.y = 1.0 + sin(_time * 1.8) * 0.008
	_head.rotation.y = sin(_time * 0.4) * 0.08


func set_outfit(outfit_id: String) -> void:
	if _imported != null:
		return
	for child in get_children():
		child.queue_free()
	_body = null
	_build_placeholder(outfit_id)


func _play_imported(flat_speed: float, crouching: bool, on_floor: bool, sprinting: bool) -> void:
	if _anim == null:
		return
	var wanted := "idle"
	if _action in ["interact", "hurt"] and _action_time < 0.5:
		wanted = _action
	elif _action == "death":
		wanted = "death"
	elif not on_floor:
		wanted = "jump"
	elif crouching:
		wanted = "crouch"
	elif flat_speed > 0.3:
		wanted = "run" if sprinting else "walk"
	if _anim.has_animation(wanted) and _anim.current_animation != wanted:
		_anim.play(wanted, 0.2)


func _build_placeholder(outfit_id: String) -> void:
	var outfit: Dictionary = OUTFITS.get(outfit_id, OUTFITS["default"])
	var jacket := PrimitiveKit.mat(outfit["jacket"], 0.85)
	var pants := PrimitiveKit.mat(outfit["pants"], 0.9)
	var boots := PrimitiveKit.mat(Color(0.22, 0.15, 0.09), 0.95)
	var skin := PrimitiveKit.mat(Color(0.78, 0.6, 0.48), 0.7)
	var hair := PrimitiveKit.mat(Color(0.12, 0.08, 0.05), 0.9)
	var pack := PrimitiveKit.mat(Color(0.13, 0.14, 0.11), 0.9)
	var black := PrimitiveKit.mat(Color(0.05, 0.05, 0.05), 0.6)
	var metal := PrimitiveKit.mat(Color(0.35, 0.36, 0.38), 0.4, 0.8)
	var led := PrimitiveKit.mat(Color(0.2, 1.0, 0.3), 0.5, 0.0, Color(0.2, 1.0, 0.3), 3.0)

	_body = PrimitiveKit.pivot(self, "Body", Vector3.ZERO)

	_leg_l = PrimitiveKit.pivot(_body, "LegL", Vector3(-0.11, 0.95, 0))
	_leg_r = PrimitiveKit.pivot(_body, "LegR", Vector3(0.11, 0.95, 0))
	for leg in [_leg_l, _leg_r]:
		PrimitiveKit.capsule(leg, 0.085, 0.9, pants, Vector3(0, -0.45, 0))
		PrimitiveKit.box(leg, Vector3(0.05, 0.12, 0.08), pants, Vector3(-0.08 if leg == _leg_l else 0.08, -0.35, 0))
		PrimitiveKit.box(leg, Vector3(0.13, 0.13, 0.27), boots, Vector3(0, -0.88, -0.04))

	_torso = PrimitiveKit.pivot(_body, "Torso", Vector3(0, 0.95, 0))
	PrimitiveKit.box(_torso, Vector3(0.44, 0.62, 0.26), jacket, Vector3(0, 0.33, 0))
	PrimitiveKit.box(_torso, Vector3(0.3, 0.08, 0.2), jacket, Vector3(0, 0.66, 0))
	PrimitiveKit.box(_torso, Vector3(0.34, 0.44, 0.18), pack, Vector3(0, 0.36, 0.21))
	PrimitiveKit.box(_torso, Vector3(0.06, 0.6, 0.02), pack, Vector3(-0.13, 0.36, -0.135))
	PrimitiveKit.box(_torso, Vector3(0.06, 0.6, 0.02), pack, Vector3(0.13, 0.36, -0.135))
	PrimitiveKit.box(_torso, Vector3(0.06, 0.12, 0.04), black, Vector3(-0.13, 0.48, -0.16))
	PrimitiveKit.box(_torso, Vector3(0.012, 0.012, 0.012), led, Vector3(-0.12, 0.53, -0.18))

	_head = PrimitiveKit.pivot(_torso, "Head", Vector3(0, 0.7, 0))
	PrimitiveKit.capsule(_head, 0.05, 0.12, skin, Vector3(0, 0.02, 0))
	PrimitiveKit.sphere(_head, 0.11, skin, Vector3(0, 0.15, 0), Vector3(0.9, 1.1, 1.0))
	PrimitiveKit.sphere(_head, 0.115, hair, Vector3(0, 0.2, 0.015), Vector3(0.95, 0.7, 1.0))

	_arm_l = PrimitiveKit.pivot(_torso, "ArmL", Vector3(-0.28, 0.58, 0))
	_arm_r = PrimitiveKit.pivot(_torso, "ArmR", Vector3(0.28, 0.58, 0))
	for arm in [_arm_l, _arm_r]:
		PrimitiveKit.capsule(arm, 0.07, 0.62, jacket, Vector3(0, -0.3, 0))
		PrimitiveKit.sphere(arm, 0.05, skin, Vector3(0, -0.63, 0))
	PrimitiveKit.cylinder(_arm_r, 0.035, 0.03, 0.22, metal, Vector3(0, -0.66, -0.08), Vector3(90, 0, 0))
