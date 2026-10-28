extends RigidBody3D
class_name ThrownFlare
## A thrown emergency flare: bright red light and sparks for a few seconds.
## Once it lands, The Hollow is drawn to it (see TheHollowAI.distract).

@export var burn_time := 12.0
@export var distract_time := 8.0

var _time := 0.0
var _announced := false

@onready var light: OmniLight3D = $OmniLight3D
@onready var sparks: CPUParticles3D = $Sparks


func _ready() -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx("flare")


func _physics_process(delta: float) -> void:
	_time += delta
	if not _announced and _time > 0.6:
		_announced = true
		for monster in get_tree().get_nodes_in_group("monster"):
			if monster.has_method("distract"):
				monster.call("distract", global_position, distract_time)
	var fade := clampf((burn_time - _time) / 2.0, 0.0, 1.0)
	light.light_energy = (3.0 + randf() * 1.5) * fade
	if fade < 0.5:
		sparks.emitting = false
	if _time >= burn_time:
		queue_free()
