extends VBoxContainer
class_name SettingsPanel
## Settings controls shared by the main menu and the pause menu. Every change saves immediately.


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider("Look sensitivity", "look_sensitivity", 0.3, 3.0, 0.1)
	_check("Invert look up/down", "invert_y")
	_check("Third-person camera (V)", "third_person")
	_option("Touch controls", "touch_controls", ["auto", "on", "off"], ["Auto", "Always on", "Off"])
	_check("Left-handed touch layout", "left_handed")
	_slider("Touch button size", "button_scale", 0.7, 1.5, 0.05)
	_slider("Volume", "master_volume", 0.0, 1.0, 0.05)
	_check("Vibration", "vibration")
	_check("Sound captions", "subtitles")


func _row(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(250, 0)
	row.add_child(label)
	add_child(row)
	return row


func _slider(text: String, key: String, min_value: float, max_value: float, step: float) -> void:
	var row := _row(text)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = float(SaveSystem.settings[key])
	slider.custom_minimum_size = Vector2(220, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void: SaveSystem.set_setting(key, value))
	row.add_child(slider)


func _check(text: String, key: String) -> void:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = bool(SaveSystem.settings[key])
	box.custom_minimum_size = Vector2(0, 44)
	box.toggled.connect(func(on: bool) -> void: SaveSystem.set_setting(key, on))
	add_child(box)


func _option(text: String, key: String, values: Array, labels: Array) -> void:
	var row := _row(text)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(220, 44)
	for i in values.size():
		option.add_item(str(labels[i]), i)
		if str(values[i]) == str(SaveSystem.settings[key]):
			option.select(i)
	option.item_selected.connect(func(index: int) -> void: SaveSystem.set_setting(key, values[index]))
	row.add_child(option)
