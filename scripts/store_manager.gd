extends Node
class_name StoreManager
## Optional cosmetic store. The catalog, ownership and equipping work; buying does NOT.
## Purchases stay switched off until official Apple / Google billing and server-side receipt
## checks exist. Nothing here takes payment details or charges money, and nothing sold
## changes gameplay. The whole story is free to finish.

signal purchase_requested(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal product_unlocked(product_id: String)
signal equipped(product_id: String)

const PURCHASES_ENABLED := false

var catalog := {
	"skin_raincoat": {"name": "Storm Coat", "type": "outfit", "price_label": "$4.99", "desc": "Navy rain shell for Alex. Cosmetic only."},
	"skin_hazmat": {"name": "Research Suit", "type": "outfit", "price_label": "$4.99", "desc": "Yellow lab hazard suit. Cosmetic only."},
	"flashlight_vintage": {"name": "Vintage Beam", "type": "flashlight", "price_label": "$2.99", "desc": "Warmer flashlight colour. No extra power."},
	"artbook": {"name": "Digital Artbook", "type": "bonus", "price_label": "$4.99", "desc": "Concept art and production notes."},
	"soundtrack": {"name": "Original Soundtrack", "type": "bonus", "price_label": "$2.99", "desc": "The game's music as an album."},
}


func is_owned(product_id: String) -> bool:
	var owned: Array = SaveSystem.cosmetics["owned"]
	return owned.has(product_id)


func is_equipped(product_id: String) -> bool:
	return SaveSystem.cosmetics["equipped_outfit"] == product_id or SaveSystem.cosmetics["equipped_flashlight"] == product_id


func request_purchase(product_id: String) -> void:
	if not catalog.has(product_id):
		push_warning("Unknown store product: " + product_id)
		return
	purchase_requested.emit(product_id)
	if not PURCHASES_ENABLED:
		purchase_failed.emit(product_id, "The store isn't open yet. Nothing was charged.")
		return
	# Real flow (not built): platform billing plugin -> your server verifies the receipt
	# -> the server's answer calls unlock_verified(product_id). Never unlock from the
	# client's word alone.


## Only call after a server has verified the platform receipt.
func unlock_verified(product_id: String) -> void:
	if is_owned(product_id):
		return
	var owned: Array = SaveSystem.cosmetics["owned"]
	owned.append(product_id)
	SaveSystem.cosmetics["owned"] = owned
	SaveSystem.save_game()
	product_unlocked.emit(product_id)


func equip(product_id: String) -> void:
	if product_id == "default":
		SaveSystem.cosmetics["equipped_outfit"] = "default"
		SaveSystem.cosmetics["equipped_flashlight"] = "default"
	elif is_owned(product_id) and catalog.has(product_id):
		match str(catalog[product_id]["type"]):
			"outfit":
				SaveSystem.cosmetics["equipped_outfit"] = product_id
			"flashlight":
				SaveSystem.cosmetics["equipped_flashlight"] = product_id
			_:
				return
	else:
		return
	SaveSystem.save_game()
	equipped.emit(product_id)
