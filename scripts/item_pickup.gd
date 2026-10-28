extends Area3D
class_name LastLightItemPickup
## A pickup on the ground: power fuse, battery, medkit, bandage or flare.
## Builds its own placeholder prop so one scene works for every item.

@export_enum("power_fuse", "battery", "medkit", "bandage", "flare") var item_id: String = "battery"
@export var amount := 1
@export var display_name := ""

var _time := 0.0
var _base_y := 0.0

@onready var visual: Node3D = $Visual
@onready var glow: OmniLight3D = $Glow


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	if display_name == "":
		display_name = str(LastLightInventory.ITEM_INFO.get(item_id, {}).get("name", item_id))
	_base_y = visual.position.y
	_time = randf() * TAU
	_build_visual()


func _process(delta: float) -> void:
	_time += delta
	visual.rotation.y += delta * 0.8
	visual.position.y = _base_y + sin(_time * 2.0) * 0.04


func get_prompt() -> String:
	return "Pick up %s" % display_name


func interact(player: Node) -> void:
	var inventory := player.get_node_or_null("Inventory") as LastLightInventory
	if inventory == null:
		return
	var gm := get_tree().get_first_node_in_group("game_manager") as LastLightGameManager
	if not inventory.add_item(item_id, amount):
		if gm != null:
			gm.notify("You can't carry any more %s." % display_name)
		return
	if gm != null:
		if item_id == "power_fuse":
			gm.collect_fuse()
		else:
			gm.notify("Picked up %s." % display_name)
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx("pickup")
	if player.has_method("make_noise"):
		player.call("make_noise", 0.25)
	queue_free()


func _build_visual() -> void:
	var metal := PrimitiveKit.mat(Color(0.6, 0.6, 0.62), 0.35, 0.9)
	match item_id:
		"power_fuse":
			var ceramic := PrimitiveKit.mat(Color(0.86, 0.82, 0.74), 0.5)
			PrimitiveKit.cylinder(visual, 0.07, 0.07, 0.24, ceramic, Vector3.ZERO, Vector3(0, 0, 90))
			PrimitiveKit.cylinder(visual, 0.075, 0.075, 0.05, metal, Vector3(-0.14, 0, 0), Vector3(0, 0, 90))
			PrimitiveKit.cylinder(visual, 0.075, 0.075, 0.05, metal, Vector3(0.14, 0, 0), Vector3(0, 0, 90))
			PrimitiveKit.box(visual, Vector3(0.1, 0.02, 0.15), PrimitiveKit.mat(Color(1, 0.5, 0.05), 0.5, 0.0, Color(1, 0.45, 0.05), 2.0), Vector3(0, 0.07, 0))
			glow.light_color = Color(1.0, 0.6, 0.2)
			glow.light_energy = 1.2
		"battery":
			PrimitiveKit.cylinder(visual, 0.05, 0.05, 0.16, PrimitiveKit.mat(Color(0.08, 0.08, 0.08), 0.5))
			PrimitiveKit.cylinder(visual, 0.051, 0.051, 0.05, PrimitiveKit.mat(Color(0.9, 0.7, 0.1), 0.4), Vector3(0, 0.05, 0))
			PrimitiveKit.cylinder(visual, 0.015, 0.015, 0.02, metal, Vector3(0, 0.09, 0))
			glow.light_color = Color(0.9, 0.85, 0.4)
		"medkit":
			PrimitiveKit.box(visual, Vector3(0.36, 0.22, 0.14), PrimitiveKit.mat(Color(0.7, 0.08, 0.06), 0.8))
			var white := PrimitiveKit.mat(Color(0.95, 0.95, 0.95), 0.8)
			PrimitiveKit.box(visual, Vector3(0.14, 0.04, 0.005), white, Vector3(0, 0, -0.072))
			PrimitiveKit.box(visual, Vector3(0.04, 0.14, 0.005), white, Vector3(0, 0, -0.072))
			glow.light_color = Color(1.0, 0.3, 0.3)
		"bandage":
			PrimitiveKit.cylinder(visual, 0.07, 0.07, 0.09, PrimitiveKit.mat(Color(0.9, 0.86, 0.78), 0.95), Vector3.ZERO, Vector3(90, 0, 0))
			glow.light_color = Color(1.0, 0.9, 0.8)
		"flare":
			PrimitiveKit.cylinder(visual, 0.03, 0.03, 0.3, PrimitiveKit.mat(Color(0.8, 0.1, 0.05), 0.6), Vector3.ZERO, Vector3(0, 0, 70))
			PrimitiveKit.cylinder(visual, 0.032, 0.032, 0.06, PrimitiveKit.mat(Color(0.1, 0.1, 0.1), 0.6), Vector3(0.12, 0.045, 0), Vector3(0, 0, 70))
			glow.light_color = Color(1.0, 0.25, 0.15)
