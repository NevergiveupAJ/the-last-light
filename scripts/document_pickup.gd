extends Area3D
class_name LastLightDocument
## Collectible story document (map, photo, audio log, lab note, radio recording).
## Reading one pauses the game and opens the reader. Finding all five unlocks the true ending.

@export_enum("maintenance_map", "photograph", "audio_log_01", "lab_note", "radio_recording") var doc_id: String = "maintenance_map"

var _time := 0.0

@onready var visual: Node3D = $Visual


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	_build_visual()


func _process(delta: float) -> void:
	_time += delta
	visual.position.y = sin(_time * 1.5) * 0.02


func get_prompt() -> String:
	var doc: Dictionary = LastLightGameManager.DOCUMENTS.get(doc_id, {})
	return "Read: %s" % str(doc.get("title", "Document"))


func interact(_player: Node) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as LastLightGameManager
	if gm != null:
		gm.collect_document(doc_id)
	queue_free()


func _build_visual() -> void:
	var paper := PrimitiveKit.mat(Color(0.86, 0.83, 0.74), 0.95)
	var dark := PrimitiveKit.mat(Color(0.1, 0.1, 0.11), 0.6)
	var red_led := PrimitiveKit.mat(Color(1, 0.1, 0.1), 0.5, 0.0, Color(1, 0.1, 0.05), 4.0)
	match doc_id:
		"maintenance_map":
			PrimitiveKit.box(visual, Vector3(0.42, 0.01, 0.3), paper, Vector3.ZERO, Vector3(0, 12, 0))
			PrimitiveKit.box(visual, Vector3(0.2, 0.012, 0.012), PrimitiveKit.mat(Color(0.6, 0.1, 0.1)), Vector3(0.04, 0.0, 0.02), Vector3(0, -20, 0))
		"photograph":
			PrimitiveKit.box(visual, Vector3(0.15, 0.01, 0.11), PrimitiveKit.mat(Color(0.75, 0.68, 0.55), 0.6))
		"lab_note":
			PrimitiveKit.box(visual, Vector3(0.22, 0.012, 0.3), paper, Vector3.ZERO, Vector3(0, -8, 0))
			PrimitiveKit.box(visual, Vector3(0.08, 0.013, 0.06), PrimitiveKit.mat(Color(0.7, 0.1, 0.1)), Vector3(0.04, 0, -0.08))
		_:
			PrimitiveKit.box(visual, Vector3(0.16, 0.05, 0.1), dark)
			PrimitiveKit.box(visual, Vector3(0.015, 0.015, 0.015), red_led, Vector3(0.06, 0.03, -0.03))
