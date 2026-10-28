extends Node
class_name LastLightGameManager
## Game flow: objectives, fuses, documents, pause, win/lose and the three endings.

signal objective_updated(text: String)
signal fuses_changed(found: int, required: int)
signal documents_changed(found: int, total: int)
signal message(text: String, seconds: float)
signal document_found(title: String, body: String)
signal state_changed(new_state: int)
signal final_chase_started
signal game_won(title: String, body: String)
signal game_lost

enum GameState { MENU, PLAYING, PAUSED, WON, LOST }

const DOCUMENTS := {
	"maintenance_map": {
		"title": "Torn Maintenance Map",
		"body": "Fuse A - Generator Station (east of the road).\nFuse B - Research Facility, back server room (north).\nFuse C - Maintenance Tunnels, west of the facility.\nGate control box - north fence.\n\nSomeone wrote across the corner in marker: DON'T RUN. IT HEARS YOU.",
	},
	"photograph": {
		"title": "Photograph - Before",
		"body": "The station staff in front of the gate, in summer. Everyone is smiling. One face has been scratched out with a key.\n\nOn the back: \"Night shift, before the trials. - M.\"",
	},
	"audio_log_01": {
		"title": "Audio Log 01 - Night Shift",
		"body": "\"Log, 2:05 AM. The generator trips every time the subject makes a sound. Dr. Reyes says that's coincidence. I've started leaving the lights on. I don't think the lights help.\"",
	},
	"lab_note": {
		"title": "Lab Note - Acoustic Response Trials",
		"body": "Subject reacts to walking at 40 m and to running at 90 m. Bright light agitates it. It no longer answers to its name.\n\nRecommendation: end the trials and seal the lower level.\nResponse stamped across the page: DENIED.",
	},
	"radio_recording": {
		"title": "Radio Recording - Final Evacuation Call",
		"body": "\"All staff to the north gate. Do not open the lower door. Repeat: do not open the lower door. If you hear walking above you... it isn't us.\"",
	},
}

var state: GameState = GameState.MENU
var fuses_found := 0
var required_fuses := 3
var gate_powered := false
var reading_document := false
var documents_found: Array[String] = []
var elapsed := 0.0


func _ready() -> void:
	add_to_group("game_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("start_game")


func _process(delta: float) -> void:
	if state == GameState.PLAYING:
		elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if state == GameState.PLAYING:
		pause_game()
		get_viewport().set_input_as_handled()
	elif state == GameState.PAUSED and not reading_document:
		resume_game()
		get_viewport().set_input_as_handled()


func start_game() -> void:
	fuses_found = 0
	gate_powered = false
	reading_document = false
	documents_found.clear()
	elapsed = 0.0
	get_tree().paused = false
	_set_state(GameState.PLAYING)
	set_mouse_captured(true)
	fuses_changed.emit(fuses_found, required_fuses)
	documents_changed.emit(0, DOCUMENTS.size())
	_update_objective()
	notify("2:17 AM. The power is out and the gate is locked. Find a way out.", 5.0)


func notify(text: String, seconds := 2.5) -> void:
	message.emit(text, seconds)


func collect_fuse() -> void:
	if state != GameState.PLAYING:
		return
	fuses_found = mini(required_fuses, fuses_found + 1)
	fuses_changed.emit(fuses_found, required_fuses)
	_play_sfx("objective")
	if fuses_found >= required_fuses:
		notify("All three fuses found. Get to the emergency gate.", 4.0)
	else:
		notify("Power fuse %d of %d." % [fuses_found, required_fuses], 3.0)
	_update_objective()


func collect_document(doc_id: String) -> void:
	if documents_found.has(doc_id) or not DOCUMENTS.has(doc_id):
		return
	documents_found.append(doc_id)
	documents_changed.emit(documents_found.size(), DOCUMENTS.size())
	var doc: Dictionary = DOCUMENTS[doc_id]
	_play_sfx("static")
	reading_document = true
	_pause_tree(true)
	document_found.emit(str(doc["title"]), str(doc["body"]))


func close_document() -> void:
	if not reading_document:
		return
	reading_document = false
	_pause_tree(false)


func restore_gate() -> bool:
	if gate_powered:
		return true
	if state != GameState.PLAYING:
		return false
	if fuses_found < required_fuses:
		notify("The control box needs %d more fuse(s)." % (required_fuses - fuses_found))
		_play_sfx("error")
		return false
	gate_powered = true
	notify("Power restored. The gate is opening... something heard that.", 4.0)
	_update_objective()
	final_chase_started.emit()
	return true


func reach_exit() -> void:
	if state != GameState.PLAYING or not gate_powered:
		return
	var ending_id := "escape"
	var title := "YOU ESCAPED"
	var body := "Alex runs until the trees thin out and the road appears in the grey light. Behind the gate, something stands very still and listens.\n\nThe radio crackles. A new transmission - from inside the forest."
	if documents_found.size() >= DOCUMENTS.size():
		ending_id = "true"
		title = "TRUE ENDING - THE LOWER DOOR"
		body = "You carry every record out of the station: the photograph, the logs, the trials, the last call.\n\nThe face scratched out of the photo was the night-shift technician who opened the lower door. The Hollow answered to that name once. Now someone outside will know what was done here."
	_set_state(GameState.WON)
	set_mouse_captured(false)
	SaveSystem.record_escape(elapsed, ending_id)
	game_won.emit(title, body)


func player_died() -> void:
	if state == GameState.WON or state == GameState.LOST:
		return
	_set_state(GameState.LOST)
	set_mouse_captured(false)
	SaveSystem.record_death()
	game_lost.emit()


func pause_game() -> void:
	if state == GameState.PLAYING:
		_set_state(GameState.PAUSED)
		_pause_tree(true)


func resume_game() -> void:
	if state == GameState.PAUSED:
		reading_document = false
		_set_state(GameState.PLAYING)
		_pause_tree(false)


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func set_mouse_captured(captured: bool) -> void:
	if SaveSystem.touch_controls_enabled():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func time_text() -> String:
	var total := int(elapsed)
	return "%d:%02d" % [total / 60, total % 60]


func _pause_tree(paused: bool) -> void:
	get_tree().paused = paused
	set_mouse_captured(not paused and state == GameState.PLAYING)
	state_changed.emit(state)


func _set_state(new_state: GameState) -> void:
	state = new_state
	state_changed.emit(state)


func _update_objective() -> void:
	var text := ""
	if gate_powered:
		text = "The gate is opening. Get through it and ESCAPE!"
	elif fuses_found >= required_fuses:
		text = "Restore power at the emergency gate (north fence)."
	else:
		text = "Find the power fuses (%d / %d). Avoid The Hollow." % [fuses_found, required_fuses]
	objective_updated.emit(text)


func _play_sfx(sfx: String) -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager") as LastLightAudio
	if audio != null:
		audio.play_sfx(sfx)
