extends Node
class_name PlayerInteraction

@export var interaction_distance: float = 2.5
@export var camera_path: NodePath = NodePath("../Head/Camera3D")

@onready var camera: Camera3D = get_node(camera_path)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("interact"):
        try_interact()

func try_interact() -> void:
    var origin := camera.global_position
    var end := origin + (-camera.global_transform.basis.z * interaction_distance)
    var query := PhysicsRayQueryParameters3D.create(origin, end)
    query.collide_with_areas = true
    var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var target: Object = hit.get("collider")
    if target != null and target.has_method("interact"):
        target.interact(get_parent())
