extends Node
class_name LastLightInventory
## Item counts with per-item carry limits and a limit on how many different items fit.

signal inventory_changed(items: Dictionary)

const ITEM_INFO := {
	"power_fuse": {"name": "Power Fuse", "desc": "Industrial fuse. The gate needs three.", "max": 3, "usable": false},
	"battery": {"name": "Battery", "desc": "Recharges the flashlight by 60%.", "max": 5, "usable": true},
	"medkit": {"name": "Medkit", "desc": "Restores 45 health.", "max": 3, "usable": true},
	"bandage": {"name": "Bandage", "desc": "Restores 20 health.", "max": 5, "usable": true},
	"flare": {"name": "Flare", "desc": "Throw it. The Hollow goes for the light for a few seconds.", "max": 3, "usable": true},
}

var items := {"power_fuse": 0, "battery": 1, "medkit": 0, "bandage": 1, "flare": 1}
var max_slots := 8


## Called once at the start of a run with the difficulty's extra supplies (-1, 0 or 2).
func apply_starting_supplies(extra: int) -> void:
	items["battery"] = clampi(1 + extra, 0, 5)
	items["flare"] = clampi(1 + extra, 0, 3)
	items["medkit"] = clampi(extra, 0, 3)
	items["bandage"] = clampi(1 + extra, 0, 5)
	inventory_changed.emit(items.duplicate(true))


func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not ITEM_INFO.has(item_id):
		return false
	var current := int(items.get(item_id, 0))
	var cap := int(ITEM_INFO[item_id]["max"])
	if current >= cap:
		return false
	if current == 0 and _used_slots() >= max_slots:
		return false
	items[item_id] = mini(cap, current + amount)
	inventory_changed.emit(items.duplicate(true))
	return true


func has_item(item_id: String, amount: int = 1) -> bool:
	return int(items.get(item_id, 0)) >= amount


func use_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	items[item_id] = int(items[item_id]) - amount
	inventory_changed.emit(items.duplicate(true))
	return true


func count(item_id: String) -> int:
	return int(items.get(item_id, 0))


func fuse_count() -> int:
	return count("power_fuse")


func _used_slots() -> int:
	var used := 0
	for value in items.values():
		if int(value) > 0:
			used += 1
	return used
