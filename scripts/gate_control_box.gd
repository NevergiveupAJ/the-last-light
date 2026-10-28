extends StaticBody3D
## Fuse control box beside the emergency gate. Passes interaction to the gate.


func get_prompt() -> String:
	var gate := get_parent() as EmergencyGate
	return gate.get_prompt() if gate != null else ""


func interact(player: Node) -> void:
	var gate := get_parent() as EmergencyGate
	if gate != null:
		gate.try_power(player)
