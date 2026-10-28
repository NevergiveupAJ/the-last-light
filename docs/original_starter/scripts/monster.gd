extends CharacterBody3D
class_name TheHollowAI

enum BrainState { PATROL, INVESTIGATE, CHASE, ATTACK, SEARCH }

@export var patrol_speed: float = 1.7
@export var investigate_speed: float = 2.3
@export var chase_speed: float = 4.2
@export var detection_range: float = 15.0
@export var hearing_range: float = 10.0
@export var attack_range: float = 1.55
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 1.6
@export var forget_after: float = 6.0
@export var patrol_points: Array[Node3D] = []

var state: BrainState = BrainState.PATROL
var player: Node3D
var last_known_position: Vector3
var lost_time: float = 0.0
var attack_timer: float = 0.0
var patrol_index: int = 0
var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

@onready var nav: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
    var candidate := get_tree().get_first_node_in_group("player")
    if candidate is Node3D:
        player = candidate

func _physics_process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    if not is_on_floor():
        velocity.y -= gravity * delta

    if player == null:
        _stop_horizontal()
        move_and_slide()
        return

    var distance := global_position.distance_to(player.global_position)
    if distance <= detection_range and _has_line_of_sight():
        last_known_position = player.global_position
        lost_time = 0.0
        state = BrainState.ATTACK if distance <= attack_range else BrainState.CHASE
    elif state == BrainState.CHASE or state == BrainState.ATTACK:
        lost_time += delta
        if lost_time >= forget_after:
            state = BrainState.SEARCH

    match state:
        BrainState.PATROL:
            _patrol()
        BrainState.INVESTIGATE:
            _move_to(last_known_position, investigate_speed)
            if global_position.distance_to(last_known_position) < 1.0:
                state = BrainState.SEARCH
        BrainState.CHASE:
            _move_to(player.global_position, chase_speed)
        BrainState.ATTACK:
            _stop_horizontal()
            _try_attack()
        BrainState.SEARCH:
            _move_to(last_known_position, patrol_speed)
            if global_position.distance_to(last_known_position) < 1.2:
                state = BrainState.PATROL
    move_and_slide()

func _has_line_of_sight() -> bool:
    # Add a raycast/occlusion test here for production stealth gameplay.
    # Range-based detection works as a fallback starter behavior.
    return global_position.distance_to(player.global_position) <= detection_range

func _patrol() -> void:
    if patrol_points.is_empty():
        _stop_horizontal()
        return
    var target := patrol_points[patrol_index].global_position
    _move_to(target, patrol_speed)
    if global_position.distance_to(target) < 1.0:
        patrol_index = (patrol_index + 1) % patrol_points.size()

func _move_to(target: Vector3, speed: float) -> void:
    nav.target_position = target
    var next_pos := nav.get_next_path_position()
    var direction := next_pos - global_position
    direction.y = 0.0
    if direction.length() > 0.15:
        direction = direction.normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        look_at(global_position + direction, Vector3.UP)
    else:
        _stop_horizontal()

func _stop_horizontal() -> void:
    velocity.x = 0.0
    velocity.z = 0.0

func _try_attack() -> void:
    if attack_timer > 0.0 or player == null:
        return
    if global_position.distance_to(player.global_position) > attack_range + 0.2:
        state = BrainState.CHASE
        return
    attack_timer = attack_cooldown
    if player.has_method("take_damage"):
        player.take_damage(attack_damage)
    # Trigger attack animation here through an AnimationTree/AnimationPlayer.

func hear_sound(world_position: Vector3, loudness: float = 1.0) -> void:
    if global_position.distance_to(world_position) <= hearing_range * maxf(loudness, 0.1):
        last_known_position = world_position
        state = BrainState.INVESTIGATE
