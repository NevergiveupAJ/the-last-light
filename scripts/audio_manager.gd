extends Node
class_name LastLightAudio
## Music, ambience and sound effects.
## Real files: put them in assets/audio/music and assets/audio/sfx using the names in
## docs/asset_prompts.md (.ogg, .wav or .mp3). Anything missing is replaced by a small
## synthesized placeholder (wind, rain, heartbeat, chase drone, clicks), so the game is never silent.

signal caption(text: String)

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const EXTENSIONS := [".ogg", ".wav", ".mp3"]
const RATE := 16000.0
const DURATIONS := {
	"footstep": 0.08, "pickup": 0.25, "click": 0.05, "objective": 1.2, "hurt": 0.5,
	"growl": 1.4, "scream": 0.9, "static": 0.8, "gate": 4.0, "thunder": 3.0, "flare": 1.0, "error": 0.25,
}
const CAPTIONS := {
	"growl": "[A low growl nearby]",
	"scream": "[The Hollow shrieks]",
	"static": "[Radio static]",
	"gate": "[The gate grinds open]",
	"thunder": "[Thunder]",
	"flare": "[Flare hisses]",
}

@export var menu_mode := false

var proximity := 0.0
var chase := 0.0
var escape_mode := false
var rain := 0.6

var _player: Node3D
var _monster: TheHollowAI
var _gen_player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _music: AudioStreamPlayer
var _music_name := ""
var _sfx_pool: Array[AudioStreamPlayer] = []
var _voices: Array[Dictionary] = []
var _stream_cache := {}
var _lp_wind := 0.0
var _lp_rain := 0.0
var _heart := 0.0
var _drone := 0.0
var _time := 0.0
var _growl_timer := 10.0


func _ready() -> void:
	add_to_group("audio_manager")
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = 0.2
	_gen_player = AudioStreamPlayer.new()
	_gen_player.stream = generator
	_gen_player.volume_db = -4.0
	add_child(_gen_player)
	_gen_player.play()
	_playback = _gen_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	_music.finished.connect(_music.play)
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	play_music("menu_theme" if menu_mode else "forest_ambience")


func bind(player: Node3D, monster: TheHollowAI) -> void:
	_player = player
	_monster = monster


func _process(delta: float) -> void:
	var chase_target := 0.0
	if _player != null and _monster != null and is_instance_valid(_monster):
		var d := _player.global_position.distance_to(_monster.global_position)
		proximity = clampf(1.0 - (d - 4.0) / 26.0, 0.0, 1.0)
		var hunting := _monster.state == TheHollowAI.BrainState.CHASE or _monster.state == TheHollowAI.BrainState.ATTACK
		chase_target = 1.0 if hunting else 0.0
		if not hunting and proximity > 0.3:
			_growl_timer -= delta
			if _growl_timer <= 0.0:
				_growl_timer = randf_range(6.0, 14.0)
				play_sfx("growl", proximity)
		_pick_music()
	chase = move_toward(chase, chase_target, delta * 0.8)
	_fill_buffer()


func _pick_music() -> void:
	if escape_mode:
		play_music("escape_theme")
	elif chase > 0.5:
		play_music("chase_theme")
	elif _player.global_position.y < -1.5 or (absf(_player.global_position.x) < 12.0 and _player.global_position.z < -53.0 and _player.global_position.z > -71.0):
		play_music("lab_ambience")
	else:
		play_music("forest_ambience")


func play_music(track: String) -> void:
	if track == _music_name:
		return
	_music_name = track
	var stream := _find_stream(MUSIC_DIR, track)
	if stream == null:
		_music.stop()
		return
	_music.stream = stream
	_music.play()


func play_sfx(sfx: String, volume := 1.0) -> void:
	if CAPTIONS.has(sfx) and bool(SaveSystem.settings["subtitles"]):
		caption.emit(str(CAPTIONS[sfx]))
	var stream := _find_stream(SFX_DIR, sfx)
	if stream != null:
		for p in _sfx_pool:
			if not p.playing:
				p.stream = stream
				p.volume_db = linear_to_db(maxf(volume, 0.001))
				p.play()
				return
		return
	if _voices.size() > 10:
		_voices.pop_front()
	_voices.append({"kind": sfx, "t": 0.0, "dur": float(DURATIONS.get(sfx, 0.3)), "vol": volume, "phase": 0.0, "lp": 0.0})


func _find_stream(folder: String, file_stem: String) -> AudioStream:
	var key := folder + file_stem
	if _stream_cache.has(key):
		return _stream_cache[key]
	var found: AudioStream = null
	for ext in EXTENSIONS:
		var path: String = key + ext
		if ResourceLoader.exists(path):
			found = load(path) as AudioStream
			break
	_stream_cache[key] = found
	return found


# --- Synthesized placeholder sound ------------------------------------------

func _fill_buffer() -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	var dt := 1.0 / RATE
	var has_music := _music.playing
	for i in frames:
		_time += dt
		var n := randf() * 2.0 - 1.0
		_lp_wind += (n - _lp_wind) * 0.015
		_lp_rain += (n - _lp_rain) * 0.4
		var gust := 0.55 + 0.3 * sin(_time * 0.23) + 0.15 * sin(_time * 0.071)
		var s := _lp_wind * 1.6 * gust + _lp_rain * rain * 0.05

		if proximity > 0.02 and not menu_mode:
			_heart += dt * (0.9 + 1.6 * proximity)
			if _heart >= 1.0:
				_heart -= 1.0
			var beat := sin(TAU * 52.0 * _heart) * exp(-_heart * 28.0)
			var second := _heart - 0.22
			if second > 0.0:
				beat += 0.7 * sin(TAU * 48.0 * second) * exp(-second * 28.0)
			s += beat * proximity * 0.55

		if not has_music:
			if chase > 0.01:
				_drone += 49.0 * dt
				if _drone >= 1.0:
					_drone -= 1.0
				s += (_drone * 2.0 - 1.0) * 0.07 * chase * (0.6 + 0.4 * sin(_time * TAU * 3.0))
			if menu_mode or escape_mode:
				s += sin(TAU * 110.0 * _time) * 0.03 + sin(TAU * 164.8 * _time) * 0.02 * (0.5 + 0.5 * sin(_time * 0.5))

		var v := _voices.size() - 1
		while v >= 0:
			var voice: Dictionary = _voices[v]
			s += _voice_sample(voice, n, dt)
			if float(voice["t"]) >= float(voice["dur"]):
				_voices.remove_at(v)
			v -= 1

		s = clampf(s, -1.0, 1.0)
		_playback.push_frame(Vector2(s, s))


func _voice_sample(v: Dictionary, n: float, dt: float) -> float:
	var t: float = v["t"]
	var dur: float = v["dur"]
	var env := clampf(1.0 - t / dur, 0.0, 1.0)
	var swell := sin(PI * clampf(t / dur, 0.0, 1.0))
	var phase: float = v["phase"]
	var s := 0.0
	match str(v["kind"]):
		"footstep":
			s = n * exp(-t * 60.0) * 0.5
		"pickup":
			s = sin(TAU * 880.0 * t) * exp(-t * 25.0) * 0.35
		"click":
			s = n * exp(-t * 200.0) * 0.6
		"objective":
			s = (sin(TAU * 220.0 * t) + 0.5 * sin(TAU * 330.0 * t)) * exp(-t * 3.0) * 0.3
		"hurt":
			s = sin(TAU * (140.0 - t * 80.0) * t) * exp(-t * 8.0) * 0.6 + n * 0.2 * env
		"growl":
			phase += (55.0 + 12.0 * sin(TAU * 7.0 * t)) * dt
			s = (fmod(phase, 1.0) * 2.0 - 1.0) * 0.35 * swell + n * 0.08 * swell
		"scream":
			phase += (650.0 + 350.0 * sin(TAU * 9.0 * t)) * dt
			s = sin(TAU * phase) * 0.22 * env + n * 0.15 * env
		"static":
			s = n * 0.25 * env * (0.6 + 0.4 * signf(sin(TAU * 13.0 * t)))
		"gate":
			phase += 38.0 * dt
			s = (fmod(phase, 1.0) * 2.0 - 1.0) * 0.25 * swell + n * 0.08 * swell
		"thunder":
			var lp: float = v["lp"]
			lp += (n - lp) * 0.03
			v["lp"] = lp
			s = lp * 4.0 * env * env
		"flare":
			s = n * 0.12 * env
		"error":
			s = signf(sin(TAU * 140.0 * t)) * 0.15 * env
	v["phase"] = phase
	v["t"] = t + dt
	return s * float(v["vol"])
