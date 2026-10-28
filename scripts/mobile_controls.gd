extends Control
class_name MobileControls
## On-screen touch controls (landscape): a floating movement stick on the left, drag anywhere
## else to look, and action buttons on the right. Every finger is tracked separately, so you
## can move, look and press a button at the same time. Mirrors for left-handed players.
## Buttons send normal input actions, so the game reacts exactly as it does to the keyboard.

const STICK_RADIUS := 95.0
const BUTTONS := [
	{"id": "interact", "label": "USE", "offset": Vector2(-120, -150), "radius": 58.0, "top": false},
	{"id": "jump", "label": "JUMP", "offset": Vector2(-255, -95), "radius": 46.0, "top": false},
	{"id": "sprint", "label": "SPRINT", "offset": Vector2(-375, -80), "radius": 44.0, "top": false},
	{"id": "crouch", "label": "CROUCH", "offset": Vector2(-100, -290), "radius": 44.0, "top": false},
	{"id": "flashlight", "label": "LIGHT", "offset": Vector2(-240, -235), "radius": 42.0, "top": false},
	{"id": "use_flare", "label": "FLARE", "offset": Vector2(-360, -205), "radius": 38.0, "top": false},
	{"id": "inventory", "label": "BAG", "offset": Vector2(-150, 60), "radius": 36.0, "top": true},
	{"id": "pause", "label": "II", "offset": Vector2(-60, 60), "radius": 36.0, "top": true},
]

var player: LastLightPlayer
var active := true

var _fingers := {}
var _stick_index := -1
var _stick_center := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _pressed := {}
var _crouch_on := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	SaveSystem.settings_changed.connect(_on_settings_changed)
	resized.connect(queue_redraw)
	_on_settings_changed()


func bind(p: LastLightPlayer) -> void:
	player = p


func set_active(on: bool) -> void:
	active = on
	var should_show := on and SaveSystem.touch_controls_enabled()
	if not should_show:
		_release_all()
	visible = should_show
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_down(touch.index, touch.position)
		else:
			_touch_up(touch.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touch_move(drag.index, drag.position, drag.relative):
			get_viewport().set_input_as_handled()


func _touch_down(index: int, pos: Vector2) -> void:
	var id := _hit_button(pos)
	if id != "":
		_fingers[index] = {"kind": "button", "id": id}
		_press(id)
		return
	var stick_side := pos.x > size.x * 0.55 if _left_handed() else pos.x < size.x * 0.45
	if stick_side and _stick_index == -1:
		_stick_index = index
		_stick_center = pos
		_stick_pos = pos
		_fingers[index] = {"kind": "stick", "id": ""}
		_update_stick()
		return
	_fingers[index] = {"kind": "look", "id": ""}


func _touch_move(index: int, pos: Vector2, relative: Vector2) -> bool:
	if not _fingers.has(index):
		return false
	var kind := str(_fingers[index]["kind"])
	if kind == "stick":
		_stick_pos = pos
		_update_stick()
	elif kind == "look" and player != null:
		player.add_touch_look(relative)
	return true


func _touch_up(index: int) -> void:
	if not _fingers.has(index):
		return
	var finger: Dictionary = _fingers[index]
	_fingers.erase(index)
	match str(finger["kind"]):
		"button":
			_release(str(finger["id"]))
		"stick":
			_stick_index = -1
			if player != null:
				player.set_mobile_movement(Vector2.ZERO)


func _update_stick() -> void:
	var radius := STICK_RADIUS * _scale()
	var value := ((_stick_pos - _stick_center) / radius).limit_length(1.0)
	if player != null:
		player.set_mobile_movement(value)


func _press(id: String) -> void:
	_pressed[id] = true
	if id == "crouch":
		_crouch_on = not _crouch_on
		if player != null:
			player.set_mobile_crouch(_crouch_on)
	else:
		_send_action(id, true)
	if bool(SaveSystem.settings["vibration"]):
		Input.vibrate_handheld(15)


func _release(id: String) -> void:
	_pressed.erase(id)
	if id != "crouch":
		_send_action(id, false)


func _release_all() -> void:
	for index in _fingers.keys():
		_touch_up(int(index))
	_fingers.clear()
	_stick_index = -1
	if player != null:
		player.set_mobile_movement(Vector2.ZERO)


func _send_action(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


# --- Layout -----------------------------------------------------------------

func _scale() -> float:
	return float(SaveSystem.settings["button_scale"])


func _left_handed() -> bool:
	return bool(SaveSystem.settings["left_handed"])


func _button_center(b: Dictionary) -> Vector2:
	var offset: Vector2 = b["offset"]
	offset *= _scale()
	var x := -offset.x if _left_handed() else size.x + offset.x
	var y := offset.y if bool(b["top"]) else size.y + offset.y
	return Vector2(x, y)


func _hit_button(pos: Vector2) -> String:
	for b in BUTTONS:
		var radius := float(b["radius"]) * _scale()
		if pos.distance_to(_button_center(b)) <= radius * 1.15:
			return str(b["id"])
	return ""


func _stick_home() -> Vector2:
	var s := _scale()
	var x := size.x - 190.0 * s if _left_handed() else 190.0 * s
	return Vector2(x, size.y - 170.0 * s)


func _draw() -> void:
	var s := _scale()
	var font := ThemeDB.fallback_font
	var base := _stick_center if _stick_index != -1 else _stick_home()
	var knob := base
	if _stick_index != -1:
		knob = base + (_stick_pos - base).limit_length(STICK_RADIUS * s)
	draw_circle(base, STICK_RADIUS * s, Color(1, 1, 1, 0.07))
	draw_arc(base, STICK_RADIUS * s, 0.0, TAU, 48, Color(0.6, 0.8, 1.0, 0.45), 3.0)
	draw_circle(knob, 42.0 * s, Color(0.75, 0.9, 1.0, 0.35))

	for b in BUTTONS:
		var id := str(b["id"])
		var center := _button_center(b)
		var radius := float(b["radius"]) * s
		var lit := _pressed.has(id) or (id == "crouch" and _crouch_on)
		if id == "flashlight" and player != null and player.flashlight.is_on():
			lit = true
		draw_circle(center, radius, Color(0.35, 0.7, 1.0, 0.45) if lit else Color(0.04, 0.07, 0.11, 0.55))
		draw_arc(center, radius, 0.0, TAU, 40, Color(0.55, 0.8, 1.0, 0.85), 3.0)
		var text := str(b["label"])
		var font_size := int(16.0 * s)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, center + Vector2(-width * 0.5, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.92))


func _on_settings_changed() -> void:
	set_active(active)
