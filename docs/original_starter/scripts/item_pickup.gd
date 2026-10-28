extends Area3D
class_name LastLightItemPickup

@export_enum("power_fuse", "battery", "medkit", "flare", "keycard") var item_id: String = "battery"
@export var amount: int = 1
@export var display_name: String = "Battery"

func interact(player: Node) -> void:
    var inventory := player.get_node_or_null("Inventory")
    if inventory != null and inventory.has_method("add_item"):
        if inventory.add_item(item_id, amount):
            if item_id == "power_fuse":
                var manager := get_tree().get_first_node_in_group("game_manager")
                if manager and manager.has_method("collect_fuse"):
                    manager.collect_fuse()
            queue_free()
