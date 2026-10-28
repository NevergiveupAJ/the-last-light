extends Node
class_name PlayerInteraction
## Looks along the camera for anything with interact(player) and shows its prompt.
## Works in first and third person (the ray is lengthened by the camera arm).

signal focus_changed(prompt: String)

@export var interaction_distance := 2.6
@export var camera_path: NodePath = NodePath("../Head/CameraArm/Camera3D")
## World (1) + interactable (4) layers.
@export_flags_3d_physics var interaction_mask := 9

var focused: Object = null
var _last_prompt := ""

@onready var camera: Camera3D = get_node(camera_path)
@onready var player: CharacterBody3D = get_parent()
@onready var head: Node3D = get_node("../Head")


func _physics_process(_delta: float) -> void:
	focused = _probe()
	var prompt := ""
	if focused != null and focused.has_method("get_prompt"):
		prompt = str(focused.call("get_prompt"))
	if prompt != _last_prompt:
		_last_prompt = prompt
		focus_changed.emit(prompt)
	if Input.is_action_just_pressed("interact"):
		try_interact()


func try_interact() -> void:
	var target := _probe()
	if target != null and target.has_method("interact"):
		target.call("interact", player)
		if player.has_method("on_interacted"):
			player.call("on_interacted")


func _probe() -> Object:
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var extra := origin.distance_to(head.global_position)
	var exclude: Array[RID] = [player.get_rid()]
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * (interaction_distance + extra), interaction_mask, exclude)
	query.collide_with_areas = true
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.get("collider")
