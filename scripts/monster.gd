extends CharacterBody3D
class_name TheHollowAI
## The Hollow. Patrols waypoints, investigates noises, chases on sight (line-of-sight
## raycast + field of view), attacks with a wind-up and cooldown, searches where it
## lost Alex, and is drawn to thrown flares. Hunts harder during the final chase.

signal state_changed(new_state: int, old_state: int)
signal attacked

enum BrainState { PATROL, INVESTIGATE, CHASE, ATTACK, SEARCH, DISTRACTED }

@export var patrol_speed := 1.8
@export var investigate_speed := 2.6
@export var chase_speed := 4.6
@export var detection_range := 16.0
@export var close_sense_range := 3.5
@export var field_of_view_deg := 120.0
@export var hearing_range := 14.0
@export var attack_range := 1.9
@export var attack_windup := 0.45
@export var attack_damage := 25.0
@export var attack_cooldown := 1.6
@export var attack_recovery := 0.6
@export var forget_after := 5.0
@export var search_duration := 10.0
@export var turn_speed := 7.0
## Leave empty to use every node in the "patrol_point" group.
@export var patrol_points: Array[Node3D] = []
@export var show_debug_label := false
## Physics layers The Hollow's eyes are blocked by (world) or can see (player).
@export_flags_3d_physics var sight_mask := 3

var state: BrainState = BrainState.PATROL
var player: LastLightPlayer
var last_known_position := Vector3.ZERO
var lost_time := 0.0
var attack_timer := 0.0
var windup_timer := -1.0
var recovery_timer := 0.0
var patrol_index := 0
var search_timer := 0.0
var search_target := Vector3.ZERO
var distract_timer := 0.0
var distract_position := Vector3.ZERO
var enraged := false
var speed_mult := 1.0
var detect_mult := 1.0
var damage_mult := 1.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _delta := 0.0
var _sight_timer := 0.0
var _can_see := false
var _rng := RandomNumberGenerator.new()

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var eyes: Node3D = $Eyes
@onready var model: HollowModel = $ModelRoot
@onready var debug_label: Label3D = $DebugLabel


func _ready() -> void:
	add_to_group("monster")
	_rng.randomize()
	debug_label.visible = show_debug_label
	last_known_position = global_position


func apply_difficulty(settings: Dictionary) -> void:
	speed_mult = float(settings.get("monster_speed", 1.0))
	detect_mult = float(settings.get("detection", 1.0))
	damage_mult = float(settings.get("damage", 1.0))


func _physics_process(delta: float) -> void:
	_delta = delta
	attack_timer = maxf(0.0, attack_timer - delta)
	recovery_timer = maxf(0.0, recovery_timer - delta)
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= gravity * delta

	if player == null:
		player = get_tree().get_first_node_in_group("player") as LastLightPlayer
	if player == null or player.health <= 0.0:
		_stop_horizontal()
		move_and_slide()
		model.animate(delta, 0.0, "idle")
		return

	_sight_timer -= delta
	if _sight_timer <= 0.0:
		_sight_timer = 0.15
		_can_see = _check_sight()

	var distance := global_position.distance_to(player.global_position)

	if windup_timer >= 0.0:
		windup_timer -= delta
		_stop_horizontal()
		_face(player.global_position)
		if windup_timer < 0.0:
			_resolve_attack()
		_finish_frame(delta)
		return

	if _can_see and not (state == BrainState.DISTRACTED and distance > close_sense_range and not enraged):
		last_known_position = player.global_position
		lost_time = 0.0
		_set_state(BrainState.ATTACK if distance <= attack_range else BrainState.CHASE)
	elif state == BrainState.CHASE or state == BrainState.ATTACK:
		lost_time += delta
		if enraged and lost_time > 2.5:
			# Final chase: it keeps getting fresh hints of where Alex is.
			last_known_position = player.global_position
			lost_time = 0.0
		elif lost_time >= forget_after:
			_begin_search(last_known_position)

	match state:
		BrainState.PATROL:
			_patrol()
		BrainState.INVESTIGATE:
			_move_to(last_known_position, investigate_speed)
			if _flat_distance(last_known_position) < 1.5:
				_begin_search(last_known_position)
		BrainState.CHASE:
			if recovery_timer > 0.0:
				_stop_horizontal()
			else:
				_move_to(last_known_position, chase_speed * (1.2 if enraged else 1.0))
				if not _can_see and _flat_distance(last_known_position) < 1.2 and not enraged:
					_begin_search(last_known_position)
		BrainState.ATTACK:
			_stop_horizontal()
			_face(player.global_position)
			if distance > attack_range + 0.3:
				_set_state(BrainState.CHASE)
			elif attack_timer <= 0.0 and recovery_timer <= 0.0:
				windup_timer = attack_windup
				model.play("attack")
				_play_sfx("scream", 0.8)
		BrainState.SEARCH:
			search_timer -= delta
			_move_to(search_target, patrol_speed * 1.2)
			if _flat_distance(search_target) < 1.2:
				search_target = _random_point_near(last_known_position, 8.0)
			if search_timer <= 0.0:
				_set_state(BrainState.PATROL)
		BrainState.DISTRACTED:
			distract_timer -= delta
			if _flat_distance(distract_position) > 2.0:
				_move_to(distract_position, investigate_speed)
			else:
				_stop_horizontal()
				_face(distract_position)
			if distract_timer <= 0.0:
				_begin_search(distract_position)

	_finish_frame(delta)


func _finish_frame(delta: float) -> void:
	move_and_slide()
	var flat_speed := Vector2(velocity.x, velocity.z).length()
	model.animate(delta, flat_speed, BrainState.keys()[state].to_lower())
	if show_debug_label:
		debug_label.text = "%s%s" % [BrainState.keys()[state], " (enraged)" if enraged else ""]


# --- Senses -----------------------------------------------------------------

func _check_sight() -> bool:
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var sight_range := detection_range * detect_mult
	if player.is_crouching:
		sight_range *= 0.6
	if player.flashlight.is_on():
		sight_range *= 1.35
	if enraged:
		sight_range *= 2.0
	if distance > sight_range:
		return false
	if distance > close_sense_range:
		var forward := -global_transform.basis.z
		forward.y = 0.0
		var flat := Vector3(to_player.x, 0.0, to_player.z)
		if forward.length() > 0.01 and flat.length() > 0.01 and forward.angle_to(flat) > deg_to_rad(field_of_view_deg * 0.5):
			return false
	var exclude: Array[RID] = [get_rid()]
	var query := PhysicsRayQueryParameters3D.create(eyes.global_position, player.head.global_position, sight_mask, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == player


## Called by the player (footsteps, jumps, pickups) and by other noise sources.
func hear_sound(world_position: Vector3, loudness: float = 1.0) -> void:
	if state == BrainState.CHASE or state == BrainState.ATTACK:
		return
	if state == BrainState.DISTRACTED and loudness < 0.9:
		return
	var reach := hearing_range * detect_mult * maxf(loudness, 0.05)
	if global_position.distance_to(world_position) <= reach:
		last_known_position = world_position
		_set_state(BrainState.INVESTIGATE)


## Called by a thrown flare.
func distract(world_position: Vector3, duration: float) -> void:
	if global_position.distance_to(world_position) > 45.0:
		return
	distract_position = world_position
	distract_timer = duration * (0.5 if enraged else 1.0)
	windup_timer = -1.0
	_set_state(BrainState.DISTRACTED)


## Final chase after the gate is powered. Teleports in if it is far away.
func set_enraged(value: bool, spawn_position := Vector3.INF) -> void:
	enraged = value
	if not value:
		return
	if spawn_position != Vector3.INF and player != null and global_position.distance_to(player.global_position) > 35.0:
		global_position = spawn_position
		velocity = Vector3.ZERO
	if player != null:
		last_known_position = player.global_position
	_set_state(BrainState.CHASE)
	_play_sfx("scream", 1.0)


# --- Movement ---------------------------------------------------------------

func _patrol() -> void:
	if patrol_points.is_empty():
		for node in get_tree().get_nodes_in_group("patrol_point"):
			if node is Node3D:
				patrol_points.append(node)
	if patrol_points.is_empty():
		_stop_horizontal()
		return
	patrol_index = patrol_index % patrol_points.size()
	var target := patrol_points[patrol_index].global_position
	_move_to(target, patrol_speed)
	if _flat_distance(target) < 1.5:
		patrol_index = (patrol_index + 1) % patrol_points.size()


func _move_to(target: Vector3, speed: float) -> void:
	var next_pos := target
	if _nav_ready():
		nav.target_position = target
		if not nav.is_navigation_finished():
			next_pos = nav.get_next_path_position()
	var direction := next_pos - global_position
	direction.y = 0.0
	if direction.length() > 0.15:
		direction = direction.normalized()
		velocity.x = direction.x * speed * speed_mult
		velocity.z = direction.z * speed * speed_mult
		_turn_toward(direction)
	else:
		_stop_horizontal()


func _nav_ready() -> bool:
	return NavigationServer3D.map_get_iteration_id(nav.get_navigation_map()) > 0


func _turn_toward(direction: Vector3) -> void:
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * _delta, 0.0, 1.0))


func _face(world_position: Vector3) -> void:
	var direction := world_position - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		_turn_toward(direction.normalized())


func _stop_horizontal() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _flat_distance(target: Vector3) -> float:
	return Vector2(global_position.x - target.x, global_position.z - target.z).length()


func _random_point_near(center: Vector3, radius: float) -> Vector3:
	var point := center + Vector3(_rng.randf_range(-radius, radius), 0.0, _rng.randf_range(-radius, radius))
	if _nav_ready():
		point = NavigationServer3D.map_get_closest_point(nav.get_navigation_map(), point)
	return point


# --- Combat -----------------------------------------------------------------

func _resolve_attack() -> void:
	windup_timer = -1.0
	attack_timer = attack_cooldown
	recovery_timer = attack_recovery
	if player != null and global_position.distance_to(player.global_position) <= attack_range + 0.5:
		player.take_damage(attack_damage * damage_mult)
		attacked.emit()
	_set_state(BrainState.CHASE)


func _begin_search(center: Vector3) -> void:
	last_known_position = center
	search_timer = search_duration
	search_target = _random_point_near(center, 6.0)
	_set_state(BrainState.SEARCH)


func _set_state(new_state: BrainState) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	state_changed.emit(new_state, old)
	if new_state == BrainState.CHASE and old != BrainState.ATTACK:
		_play_sfx("growl", 1.0)


func _play_sfx(sfx: String, volume := 1.0) -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx(sfx, volume)
