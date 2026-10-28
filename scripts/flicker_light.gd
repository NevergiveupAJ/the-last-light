extends OmniLight3D
class_name FlickerLight
## A failing light: mostly steady, with random dips and short blackouts.

@export var blackout_chance := 0.15

var base_energy := 1.0
var _timer := 0.0


func _ready() -> void:
	base_energy = light_energy
	_timer = randf() * 0.5


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	if randf() < blackout_chance:
		light_energy = base_energy * 0.05
		_timer = randf_range(0.05, 0.4)
	else:
		light_energy = base_energy * randf_range(0.8, 1.0)
		_timer = randf_range(0.05, 0.35)
