extends CanvasLayer
class_name LastLightHUD
## Health / stamina / battery bars, objective, clock, fuse and document counters,
## interaction prompt, messages and captions, plus the inventory, document reader,
## pause (with settings) and win/lose screens.

const COLOR_HEALTH := Color(0.75, 0.12, 0.1)
const COLOR_STAMINA := Color(0.3, 0.75, 0.35)
const COLOR_BATTERY := Color(0.95, 0.8, 0.3)
const COLOR_LOW := Color(0.95, 0.3, 0.2)

var player: LastLightPlayer
var gm: LastLightGameManager
var touch: MobileControls

var _message_timer := 0.0
var _caption_timer := 0.0
var _flash := 0.0
var _touch_mode := false
var _battery_low := false

@onready var root: Control = $Root
@onready var damage_flash: ColorRect = $Root/DamageFlash
@onready var health_bar: ProgressBar = $Root/Bars/Health
@onready var stamina_bar: ProgressBar = $Root/Bars/Stamina
@onready var battery_bar: ProgressBar = $Root/Bars/Battery
@onready var objective_label: Label = $Root/Objective
@onready var clock_label: Label = $Root/Clock
@onready var fuses_label: Label = $Root/Fuses
@onready var docs_label: Label = $Root/Docs
@onready var prompt_label: Label = $Root/Prompt
@onready var message_label: Label = $Root/Message
@onready var caption_label: Label = $Root/Caption
@onready var crosshair: Label = $Root/Crosshair
@onready var inventory_panel: PanelContainer = $Root/InventoryPanel
@onready var inventory_items: VBoxContainer = $Root/InventoryPanel/VBox/Items
@onready var inventory_close: Button = $Root/InventoryPanel/VBox/Close
@onready var document_panel: PanelContainer = $Root/DocumentPanel
@onready var document_title: Label = $Root/DocumentPanel/VBox/Title
@onready var document_body: Label = $Root/DocumentPanel/VBox/Body
@onready var document_close: Button = $Root/DocumentPanel/VBox/Close
@onready var pause_panel: PanelContainer = $Root/PausePanel
@onready var resume_button: Button = $Root/PausePanel/VBox/Buttons/Resume
@onready var restart_button: Button = $Root/PausePanel/VBox/Buttons/Restart
@onready var menu_button: Button = $Root/PausePanel/VBox/Buttons/Menu
@onready var end_panel: PanelContainer = $Root/EndPanel
@onready var end_title: Label = $Root/EndPanel/VBox/Title
@onready var end_body: Label = $Root/EndPanel/VBox/Body
@onready var end_stats: Label = $Root/EndPanel/VBox/Stats
@onready var retry_button: Button = $Root/EndPanel/VBox/Buttons/Retry
@onready var end_menu_button: Button = $Root/EndPanel/VBox/Buttons/Menu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var hud_theme := Theme.new()
	hud_theme.default_font_size = 22
	root.theme = hud_theme
	_style_bar(health_bar, COLOR_HEALTH)
	_style_bar(stamina_bar, COLOR_STAMINA)
	_style_bar(battery_bar, COLOR_BATTERY)
	for panel in [inventory_panel, document_panel, pause_panel, end_panel]:
		_style_panel(panel)
	for big in [document_title, end_title]:
		big.add_theme_font_size_override("font_size", 34)
	for label in [objective_label, prompt_label, message_label, caption_label, clock_label, fuses_label, docs_label]:
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
	inventory_close.pressed.connect(toggle_inventory)
	document_close.pressed.connect(_close_document)
	resume_button.pressed.connect(func() -> void: gm.resume_game())
	restart_button.pressed.connect(func() -> void: gm.restart())
	menu_button.pressed.connect(func() -> void: gm.quit_to_menu())
	retry_button.pressed.connect(func() -> void: gm.restart())
	end_menu_button.pressed.connect(func() -> void: gm.quit_to_menu())
	inventory_panel.visible = false
	document_panel.visible = false
	pause_panel.visible = false
	end_panel.visible = false
	prompt_label.text = ""
	message_label.text = ""
	caption_label.text = ""


func bind(p: LastLightPlayer, manager: LastLightGameManager, controls: MobileControls, weather: WeatherSystem, audio: LastLightAudio) -> void:
	player = p
	gm = manager
	touch = controls
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.hurt.connect(_on_hurt)
	player.flashlight.battery_changed.connect(_on_battery_changed)
	player.interaction.focus_changed.connect(_on_prompt_changed)
	player.inventory.inventory_changed.connect(func(_items: Dictionary) -> void: _refresh_inventory())
	gm.objective_updated.connect(func(text: String) -> void: objective_label.text = text)
	gm.fuses_changed.connect(func(found: int, required: int) -> void: fuses_label.text = "Fuses %d / %d" % [found, required])
	gm.documents_changed.connect(func(found: int, total: int) -> void: docs_label.text = "Documents %d / %d" % [found, total])
	gm.message.connect(show_message)
	gm.document_found.connect(_on_document_found)
	gm.state_changed.connect(_on_state_changed)
	gm.game_won.connect(_on_game_won)
	gm.game_lost.connect(_on_game_lost)
	weather.clock_changed.connect(func(text: String) -> void: clock_label.text = text)
	audio.caption.connect(_on_caption)
	SaveSystem.settings_changed.connect(_update_touch_mode)
	_on_health_changed(player.health, player.max_health)
	_on_battery_changed(player.flashlight.battery, player.flashlight.max_battery)
	clock_label.text = weather.clock_text()
	_update_touch_mode()


func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		message_label.modulate.a = clampf(_message_timer, 0.0, 1.0)
	if _caption_timer > 0.0:
		_caption_timer -= delta
		caption_label.modulate.a = clampf(_caption_timer, 0.0, 1.0)
	_flash = maxf(0.0, _flash - delta * 1.5)
	var low_health := 0.0
	if player != null and player.health > 0.0 and player.health < 35.0:
		low_health = 0.12 + 0.06 * sin(Time.get_ticks_msec() * 0.006)
	damage_flash.color = Color(0.6, 0.0, 0.0, maxf(_flash, low_health))


func _unhandled_input(event: InputEvent) -> void:
	if gm == null:
		return
	if event.is_action_pressed("inventory") and (gm.state == LastLightGameManager.GameState.PLAYING and not gm.reading_document):
		toggle_inventory()
		get_viewport().set_input_as_handled()


func show_message(text: String, seconds := 2.5) -> void:
	message_label.text = text
	_message_timer = seconds
	message_label.modulate.a = 1.0


func toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		_refresh_inventory()
	gm.set_mouse_captured(not inventory_panel.visible)
	_update_touch_active()


func _refresh_inventory() -> void:
	if not inventory_panel.visible or player == null:
		return
	for child in inventory_items.get_children():
		child.queue_free()
	var any := false
	for item_id in LastLightInventory.ITEM_INFO.keys():
		var count := player.inventory.count(item_id)
		if count <= 0:
			continue
		any = true
		var info: Dictionary = LastLightInventory.ITEM_INFO[item_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.text = "%s  x%d\n%s" % [info["name"], count, info["desc"]]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(320, 0)
		row.add_child(label)
		if bool(info["usable"]):
			var use := Button.new()
			use.text = "Use"
			use.custom_minimum_size = Vector2(110, 56)
			var id := str(item_id)
			use.pressed.connect(func() -> void:
				if player.use_item(id) and id == "flare":
					toggle_inventory()
			)
			row.add_child(use)
		inventory_items.add_child(row)
	if not any:
		var empty := Label.new()
		empty.text = "Nothing but lint."
		inventory_items.add_child(empty)


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


func _on_battery_changed(value: float, maximum: float) -> void:
	battery_bar.max_value = maximum
	battery_bar.value = value
	var low := value < maximum * 0.2
	if low != _battery_low:
		_battery_low = low
		_style_bar(battery_bar, COLOR_LOW if low else COLOR_BATTERY)


func _on_hurt(_amount: float) -> void:
	_flash = 0.55


func _on_prompt_changed(prompt: String) -> void:
	if prompt == "":
		prompt_label.text = ""
		return
	prompt_label.text = ("Tap USE: %s" if _touch_mode else "[E] %s") % prompt


func _on_caption(text: String) -> void:
	caption_label.text = text
	_caption_timer = 2.5
	caption_label.modulate.a = 1.0


func _on_document_found(title: String, body: String) -> void:
	inventory_panel.visible = false
	document_title.text = title
	document_body.text = body
	document_panel.visible = true
	_update_touch_active()


func _close_document() -> void:
	document_panel.visible = false
	gm.close_document()
	_update_touch_active()


func _on_state_changed(state: int) -> void:
	pause_panel.visible = state == LastLightGameManager.GameState.PAUSED
	if state != LastLightGameManager.GameState.PLAYING:
		inventory_panel.visible = false
	if not gm.reading_document:
		document_panel.visible = false
	_update_touch_active()


func _on_game_won(title: String, body: String) -> void:
	_show_end(title, body)


func _on_game_lost() -> void:
	_show_end("THE LAST LIGHT GOES OUT", "The Hollow found you in the dark.\n\nTip: crouch to stay quiet, keep the flashlight off when it's close, and throw a flare to send it the other way.")


func _show_end(title: String, body: String) -> void:
	end_title.text = title
	end_body.text = body
	end_stats.text = "Time %s   -   Fuses %d / 3   -   Documents %d / %d" % [gm.time_text(), gm.fuses_found, gm.documents_found.size(), LastLightGameManager.DOCUMENTS.size()]
	end_panel.visible = true
	inventory_panel.visible = false
	prompt_label.text = ""
	_update_touch_active()


func _update_touch_mode() -> void:
	_touch_mode = SaveSystem.touch_controls_enabled()
	crosshair.visible = true
	_update_touch_active()


func _update_touch_active() -> void:
	if touch == null or gm == null:
		return
	var playing := gm.state == LastLightGameManager.GameState.PLAYING and not gm.reading_document
	touch.set_active(playing and not inventory_panel.visible and not end_panel.visible)


func _style_bar(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(4)
	bg.border_color = Color(1, 1, 1, 0.2)
	bg.set_border_width_all(1)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)


func _style_panel(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.05, 0.08, 0.94)
	box.border_color = Color(0.3, 0.55, 0.85, 0.8)
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", box)
