extends Node3D
class_name WeatherSystem
## Night atmosphere: rain that follows Alex, lightning with thunder, drifting fog,
## and a slow night-to-dawn clock that starts at 2:17 AM.

signal clock_changed(text: String)

## Game minutes per real second. 0.1 = dawn after about 27 minutes of play.
@export var minutes_per_second := 0.1
@export var start_minutes := 137.0

var game_minutes := 137.0
var rain_on := true

var _player: Node3D
var _env: Environment
var _moon: DirectionalLight3D
var _rain: CPUParticles3D
var _moon_energy := 0.25
var _ambient_energy := 0.4
var _fog_density := 0.03
var _fog_color := Color.BLACK
var _background := Color.BLACK
var _flash := 0.0
var _lightning_timer := 25.0
var _rain_timer := 60.0
var _last_minute := -1
var _time := 0.0


func _ready() -> void:
	game_minutes = start_minutes
	_rain = CPUParticles3D.new()
	_rain.amount = 700
	_rain.lifetime = 1.0
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(18, 1, 18)
	_rain.direction = Vector3(0.1, -1, 0)
	_rain.spread = 3.0
	_rain.initial_velocity_min = 18.0
	_rain.initial_velocity_max = 22.0
	_rain.gravity = Vector3(0, -9.8, 0)
	_rain.particle_flag_align_y = true
	var drop := QuadMesh.new()
	drop.size = Vector2(0.015, 0.45)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.albedo_color = Color(0.7, 0.75, 0.85, 0.25)
	drop_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	drop.material = drop_mat
	_rain.mesh = drop
	add_child(_rain)


func bind(player: Node3D, env: Environment, moon: DirectionalLight3D) -> void:
	_player = player
	_env = env
	_moon = moon
	_moon_energy = moon.light_energy
	_ambient_energy = env.ambient_light_energy
	_fog_density = env.fog_density
	_fog_color = env.fog_light_color
	_background = env.background_color


func clock_text() -> String:
	var total := int(game_minutes) % (24 * 60)
	var hour := total / 60
	var minute := total % 60
	var suffix := "AM" if hour < 12 else "PM"
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, minute, suffix]


func _process(delta: float) -> void:
	_time += delta
	game_minutes += delta * minutes_per_second
	if int(game_minutes) != _last_minute:
		_last_minute = int(game_minutes)
		clock_changed.emit(clock_text())

	if _player != null:
		_rain.global_position = _player.global_position + Vector3(0, 12, 0)
		# No rain inside the tunnels.
		_rain.visible = rain_on and _player.global_position.y > -1.5

	_rain_timer -= delta
	if _rain_timer <= 0.0:
		_rain_timer = randf_range(45.0, 120.0)
		rain_on = randf() < 0.7
		_rain.emitting = rain_on
		var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
		if audio != null:
			audio.rain = 0.6 if rain_on else 0.1

	_lightning_timer -= delta
	if _lightning_timer <= 0.0:
		_lightning_timer = randf_range(20.0, 55.0)
		if rain_on:
			_flash = 1.0
			get_tree().create_timer(randf_range(0.8, 2.5)).timeout.connect(_thunder)
	_flash = maxf(0.0, _flash - delta * 3.0)

	if _env == null:
		return
	# Dawn starts at 5:00 AM and is complete by 6:00 AM.
	var dawn := clampf((game_minutes - 300.0) / 60.0, 0.0, 1.0)
	var flicker := _flash * (0.6 + 0.4 * sin(_time * 60.0))
	_moon.light_energy = lerpf(_moon_energy, 0.8, dawn) + flicker * 3.0
	_env.ambient_light_energy = lerpf(_ambient_energy, 0.9, dawn) + flicker
	_env.background_color = _background.lerp(Color(0.25, 0.3, 0.4), dawn)
	_env.fog_light_color = _fog_color.lerp(Color(0.35, 0.38, 0.45), dawn)
	_env.fog_density = _fog_density * (1.0 + 0.25 * sin(_time * 0.05))


func _thunder() -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx("thunder", 0.8)
