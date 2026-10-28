extends CharacterBody3D
class_name LastLightPlayer

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0
@export var walk_speed: float = 3.5
@export var sprint_speed: float = 6.0
@export var crouch_speed: float = 1.6
@export var jump_velocity: float = 4.0
@export var mouse_sensitivity: float = 0.002
@export var stamina_max: float = 100.0
@export var stamina_drain: float = 24.0
@export var stamina_recovery: float = 16.0

var health: float
var stamina: float
var mobile_move: Vector2 = Vector2.ZERO
var mobile_sprint: bool = false
var mobile_crouch: bool = false
var can_move: bool = true
var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
    add_to_group("player")
    health = max_health
    stamina = stamina_max
    health_changed.emit(health, max_health)
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        head.rotate_x(-event.relative.y * mouse_sensitivity)
        head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
    if event.is_action_pressed("pause"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    if not can_move:
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity

    var crouched := mobile_crouch or Input.is_action_pressed("crouch")
    var wants_sprint := mobile_sprint or Input.is_action_pressed("sprint")
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if mobile_move.length() > 0.08:
        input_dir = mobile_move.limit_length()

    var speed := walk_speed
    if crouched:
        speed = crouch_speed
    elif wants_sprint and stamina > 0.0 and input_dir.length() > 0.1:
        speed = sprint_speed
        stamina = maxf(0.0, stamina - stamina_drain * delta)
    else:
        stamina = minf(stamina_max, stamina + stamina_recovery * delta)

    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction.length() > 0.01:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)
    move_and_slide()

func set_mobile_movement(value: Vector2) -> void:
    mobile_move = value.limit_length()

func set_mobile_sprint(value: bool) -> void:
    mobile_sprint = value

func set_mobile_crouch(value: bool) -> void:
    mobile_crouch = value

func take_damage(amount: float) -> void:
    health = clampf(health - amount, 0.0, max_health)
    health_changed.emit(health, max_health)
    if health <= 0.0:
        can_move = false
        died.emit()

func heal(amount: float) -> void:
    health = clampf(health + amount, 0.0, max_health)
    health_changed.emit(health, max_health)
