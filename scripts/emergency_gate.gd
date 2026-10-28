extends Node3D
class_name EmergencyGate
## The emergency gate on the north fence. Inserting three fuses at the control box powers it;
## the gate then grinds open slowly (the final chase) and the exit trigger behind it wins the game.

@export var open_distance := 6.4
@export var open_time := 7.0

var powered := false
var _alarm_time := 0.0

@onready var door: AnimatableBody3D = $GateDoor
@onready var status_light: OmniLight3D = $StatusLight
@onready var alarm_light: OmniLight3D = $AlarmLight
@onready var exit_trigger: Area3D = $ExitTrigger
@onready var status_label: Label3D = $ControlBox/Label3D


func _ready() -> void:
	exit_trigger.body_entered.connect(_on_exit_body_entered)
	alarm_light.visible = false
	status_light.light_color = Color(1.0, 0.1, 0.05)


func _process(delta: float) -> void:
	if powered:
		_alarm_time += delta
		alarm_light.light_energy = 2.0 + 2.0 * sin(_alarm_time * 8.0)


func get_prompt() -> String:
	if powered:
		return "The gate is opening!"
	var gm := _gm()
	var found := gm.fuses_found if gm != null else 0
	if found >= 3:
		return "Insert 3 fuses and restore power"
	return "Fuse box: %d / 3 fuses" % found


func try_power(player: Node) -> void:
	if powered:
		return
	var gm := _gm()
	if gm == null or not gm.restore_gate():
		return
	var inventory := player.get_node_or_null("Inventory") as LastLightInventory
	if inventory != null:
		inventory.use_item("power_fuse", mini(3, inventory.fuse_count()))
	powered = true
	status_light.light_color = Color(0.2, 1.0, 0.3)
	alarm_light.visible = true
	status_label.text = "POWER RESTORED\nGATE OPENING"
	var tween := create_tween()
	tween.tween_property(door, "position:x", door.position.x + open_distance, open_time).set_trans(Tween.TRANS_SINE)
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx("gate")


func _on_exit_body_entered(body: Node3D) -> void:
	if powered and body.is_in_group("player"):
		var gm := _gm()
		if gm != null:
			gm.reach_exit()


func _gm() -> LastLightGameManager:
	return get_tree().get_first_node_in_group("game_manager") as LastLightGameManager
