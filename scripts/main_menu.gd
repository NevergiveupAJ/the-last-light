extends Control
## Title screen: New Game, difficulty, settings, cosmetic store (purchases disabled),
## how to play, and stats from earlier runs.

const GAME_SCENE := "res://scenes/Main.tscn"

var store := StoreManager.new()

@onready var new_game_button: Button = $Menu/NewGame
@onready var difficulty_option: OptionButton = $Menu/Difficulty
@onready var settings_button: Button = $Menu/Settings
@onready var store_button: Button = $Menu/Store
@onready var help_button: Button = $Menu/HowToPlay
@onready var quit_button: Button = $Menu/Quit
@onready var stats_label: Label = $Stats
@onready var panel: PanelContainer = $Panel
@onready var panel_title: Label = $Panel/VBox/PanelTitle
@onready var content: VBoxContainer = $Panel/VBox/Scroll/Content
@onready var back_button: Button = $Panel/VBox/Back
@onready var title_label: Label = $Title


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(store)
	var menu_theme := Theme.new()
	menu_theme.default_font_size = 24
	theme = menu_theme
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 10)
	_style_panel(panel)

	var keys := SaveSystem.DIFFICULTIES.keys()
	for i in keys.size():
		difficulty_option.add_item("Difficulty: %s" % SaveSystem.DIFFICULTIES[keys[i]]["label"], i)
		if keys[i] == SaveSystem.settings["difficulty"]:
			difficulty_option.select(i)
	difficulty_option.item_selected.connect(func(index: int) -> void: SaveSystem.set_setting("difficulty", keys[index]))

	new_game_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
	settings_button.pressed.connect(_show_settings)
	store_button.pressed.connect(_show_store)
	help_button.pressed.connect(_show_help)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	back_button.pressed.connect(func() -> void: panel.visible = false)
	store.purchase_failed.connect(func(_id: String, reason: String) -> void: _show_store(reason))
	# Apple does not allow a Quit button on iOS.
	quit_button.visible = not OS.has_feature("ios")
	panel.visible = false
	_update_stats()
	new_game_button.grab_focus()


func _update_stats() -> void:
	var s := SaveSystem.stats
	var best := float(s["best_time"])
	var best_text := "--"
	if best > 0.0:
		best_text = "%d:%02d" % [int(best) / 60, int(best) % 60]
	var endings: Array = s["endings"]
	stats_label.text = "Escapes %d   Deaths %d   Best time %s   Endings found %d / 3" % [int(s["escapes"]), int(s["deaths"]), best_text, endings.size()]


func _open(title: String) -> void:
	panel_title.text = title
	for child in content.get_children():
		child.queue_free()
	panel.visible = true


func _show_settings() -> void:
	_open("SETTINGS")
	content.add_child(SettingsPanel.new())


func _show_help() -> void:
	_open("HOW TO PLAY")
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = """You wake at 2:17 AM in an abandoned research station. Find 3 power fuses, restore the emergency gate on the north fence, and escape before The Hollow finds you.

TOUCH: left thumb moves (the stick appears where you touch). Drag anywhere on the right to look. USE picks things up and opens things. SPRINT (hold), CROUCH (toggle), JUMP, LIGHT, FLARE, BAG (items), II (pause).

KEYBOARD: WASD move, mouse look, Shift sprint, Ctrl or C crouch, Space jump, E use, F flashlight, G throw flare, Tab or I items, V camera view, Esc pause.

SURVIVAL TIPS
- The Hollow hears footsteps. Running is loud, crouching is almost silent.
- A lit flashlight makes you easier to see. Batteries are scarce.
- Throw a flare and it will go for the light.
- Five documents are hidden around the station. Find them all for the true ending."""
	content.add_child(label)


func _show_store(notice := "") -> void:
	_open("STORE (cosmetics only)")
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = notice if notice != "" else "Everything here is optional and cosmetic. The full story is free. Purchases are not switched on yet, so nothing here can charge money."
	content.add_child(info)
	content.add_child(_store_row("default", "Survivor (default)", "Alex's original olive jacket and flashlight.", ""))
	for id in store.catalog.keys():
		var item: Dictionary = store.catalog[id]
		content.add_child(_store_row(str(id), str(item["name"]), str(item["desc"]), str(item["price_label"])))


func _store_row(id: String, item_name: String, desc: String, price: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = "%s\n%s" % [item_name, desc]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(280, 0)
	row.add_child(label)
	var button := Button.new()
	button.custom_minimum_size = Vector2(170, 56)
	if id == "default" or store.is_owned(id):
		var equipped: bool = store.is_equipped(id) or (id == "default" and SaveSystem.cosmetics["equipped_outfit"] == "default" and SaveSystem.cosmetics["equipped_flashlight"] == "default")
		button.text = "Equipped" if equipped else "Equip"
		button.disabled = equipped
		button.pressed.connect(func() -> void:
			store.equip(id)
			_show_store()
		)
	else:
		button.text = "%s - Soon" % price
		button.pressed.connect(func() -> void: store.request_purchase(id))
	row.add_child(button)
	return row


func _style_panel(target: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.05, 0.08, 0.94)
	box.border_color = Color(0.3, 0.55, 0.85, 0.8)
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(22)
	target.add_theme_stylebox_override("panel", box)
