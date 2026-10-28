extends Node3D
class_name FlashlightTool
## Alex's flashlight: battery drain, dimming and flicker when low, cosmetic beam colour.
## A navigation tool, not a weapon. A lit flashlight makes Alex easier for The Hollow to spot.

signal battery_changed(value: float, maximum: float)
signal toggled(enabled: bool)

@export var max_battery := 100.0
@export var battery := 100.0
@export var drain_per_second := 0.6
@export var flashlight_enabled := true
@export var base_energy := 4.0

var drain_multiplier := 1.0
var _flicker_timer := 0.0
var _flicker_off := false

@onready var beam: SpotLight3D = $SpotLight3D
@onready var body: MeshInstance3D = $Body


func _ready() -> void:
	battery = clampf(battery, 0.0, max_battery)
	if str(SaveSystem.cosmetics.get("equipped_flashlight", "default")) == "flashlight_vintage":
		beam.light_color = Color(1.0, 0.82, 0.55)
	_sync_light()
	battery_changed.emit(battery, max_battery)


func _process(delta: float) -> void:
	if not is_on():
		return
	battery = maxf(0.0, battery - drain_per_second * drain_multiplier * delta)
	battery_changed.emit(battery, max_battery)
	if battery <= 0.0:
		flashlight_enabled = false
		_sync_light()
		toggled.emit(false)
		return
	_update_flicker(delta)


func is_on() -> bool:
	return flashlight_enabled and battery > 0.0


func toggle_flashlight() -> void:
	if flashlight_enabled:
		flashlight_enabled = false
	elif battery > 0.0:
		flashlight_enabled = true
	_sync_light()
	toggled.emit(is_on())
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx("click")


func add_battery(amount: float) -> void:
	battery = minf(max_battery, battery + amount)
	battery_changed.emit(battery, max_battery)


func set_body_visible(value: bool) -> void:
	if is_instance_valid(body):
		body.visible = value


func _update_flicker(delta: float) -> void:
	var pct := battery / max_battery
	var energy := base_energy * (0.45 + 0.55 * clampf(pct * 4.0, 0.0, 1.0))
	if pct < 0.15:
		_flicker_timer -= delta
		if _flicker_timer <= 0.0:
			_flicker_off = randf() < 0.3
			_flicker_timer = randf_range(0.04, 0.12) if _flicker_off else randf_range(0.3, 1.5)
		if _flicker_off:
			energy *= 0.08
	beam.light_energy = energy


func _sync_light() -> void:
	if is_instance_valid(beam):
		beam.visible = is_on()
		beam.light_energy = base_energy
