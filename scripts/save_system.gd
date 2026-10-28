extends Node
## Autoload "SaveSystem": settings, stats and cosmetic choices in user://last_light.cfg.
## The section and key names are permanent. Renaming one resets that value for players.

signal settings_changed

const SAVE_PATH := "user://last_light.cfg"

const DIFFICULTIES := {
	"story": {"label": "Story", "monster_speed": 0.8, "detection": 0.75, "damage": 0.6, "battery_drain": 0.7, "extra_supplies": 2},
	"survival": {"label": "Survival", "monster_speed": 1.0, "detection": 1.0, "damage": 1.0, "battery_drain": 1.0, "extra_supplies": 0},
	"nightmare": {"label": "Nightmare", "monster_speed": 1.15, "detection": 1.3, "damage": 1.4, "battery_drain": 1.4, "extra_supplies": -1},
}

var settings := {
	"difficulty": "survival",
	"look_sensitivity": 1.0,
	"invert_y": false,
	"left_handed": false,
	"third_person": false,
	"touch_controls": "auto",
	"button_scale": 1.0,
	"master_volume": 0.8,
	"vibration": true,
	"subtitles": true,
}
var stats := {"best_time": 0.0, "escapes": 0, "deaths": 0, "endings": []}
var cosmetics := {"owned": ["default"], "equipped_outfit": "default", "equipped_flashlight": "default"}


func _ready() -> void:
	load_game()
	_apply_volume()


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in settings.keys():
		settings[key] = cfg.get_value("settings", key, settings[key])
	for key in stats.keys():
		stats[key] = cfg.get_value("stats", key, stats[key])
	for key in cosmetics.keys():
		cosmetics[key] = cfg.get_value("cosmetics", key, cosmetics[key])
	if not DIFFICULTIES.has(settings["difficulty"]):
		settings["difficulty"] = "survival"


func save_game() -> void:
	var cfg := ConfigFile.new()
	for key in settings.keys():
		cfg.set_value("settings", key, settings[key])
	for key in stats.keys():
		cfg.set_value("stats", key, stats[key])
	for key in cosmetics.keys():
		cfg.set_value("cosmetics", key, cosmetics[key])
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save settings (error %d)." % err)


func set_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		push_warning("Unknown setting: " + key)
		return
	settings[key] = value
	save_game()
	_apply_volume()
	settings_changed.emit()


func difficulty() -> Dictionary:
	return DIFFICULTIES.get(settings["difficulty"], DIFFICULTIES["survival"])


func touch_controls_enabled() -> bool:
	match str(settings["touch_controls"]):
		"on":
			return true
		"off":
			return false
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func record_escape(time_sec: float, ending_id: String) -> void:
	stats["escapes"] = int(stats["escapes"]) + 1
	var best := float(stats["best_time"])
	if best <= 0.0 or time_sec < best:
		stats["best_time"] = time_sec
	var endings: Array = stats["endings"]
	if not endings.has(ending_id):
		endings.append(ending_id)
	stats["endings"] = endings
	save_game()


func record_death() -> void:
	stats["deaths"] = int(stats["deaths"]) + 1
	var endings: Array = stats["endings"]
	if not endings.has("lost"):
		endings.append("lost")
	stats["endings"] = endings
	save_game()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(settings["master_volume"]), 0.0001)))
