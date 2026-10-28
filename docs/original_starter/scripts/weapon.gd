extends Node3D
class_name FlashlightTool

signal battery_changed(value: float)

@export var max_battery: float = 100.0
@export var battery: float = 100.0
@export var drain_per_second: float = 1.4
@export var flashlight_enabled: bool = true

@onready var beam: SpotLight3D = $SpotLight3D

func _ready() -> void:
    battery = clampf(battery, 0.0, max_battery)
    _sync_light()
    battery_changed.emit(battery)

func _process(delta: float) -> void:
    if flashlight_enabled:
        battery = maxf(0.0, battery - drain_per_second * delta)
        if battery <= 0.0:
            flashlight_enabled = false
            _sync_light()
        battery_changed.emit(battery)

func toggle_flashlight() -> void:
    if flashlight_enabled:
        flashlight_enabled = false
    elif battery > 0.0:
        flashlight_enabled = true
    _sync_light()

func add_battery(amount: float) -> void:
    battery = minf(max_battery, battery + amount)
    battery_changed.emit(battery)

func _sync_light() -> void:
    if is_instance_valid(beam):
        beam.visible = flashlight_enabled and battery > 0.0
