extends Node
class_name LastLightInventory

signal inventory_changed(items: Dictionary)

var items: Dictionary = {
    "power_fuse": 0,
    "battery": 2,
    "medkit": 1,
    "flare": 0,
    "keycard": 0
}
var max_slots: int = 8

func add_item(item_id: String, amount: int = 1) -> bool:
    if amount <= 0:
        return false
    var total := 0
    for value in items.values():
        total += int(value)
    if not items.has(item_id) and total >= max_slots:
        return false
    items[item_id] = int(items.get(item_id, 0)) + amount
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

func fuse_count() -> int:
    return int(items.get("power_fuse", 0))
