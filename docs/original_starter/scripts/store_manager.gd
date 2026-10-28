extends Node
class_name StoreManager

# Starter architecture only. Do not connect real purchases until store products,
# platform receipt validation, privacy disclosures, and parental safeguards are ready.
signal purchase_requested(product_id: String)
signal product_unlocked(product_id: String)

var catalog: Dictionary = {
    "skin_raincoat": {"name": "Storm Coat", "type": "cosmetic", "price_label": "Optional cosmetic"},
    "skin_hazmat": {"name": "Research Suit", "type": "cosmetic", "price_label": "Optional cosmetic"},
    "flashlight_skin": {"name": "Vintage Beam", "type": "cosmetic", "price_label": "Optional cosmetic"}
}

func request_purchase(product_id: String) -> void:
    if not catalog.has(product_id):
        push_warning("Unknown store product: " + product_id)
        return
    purchase_requested.emit(product_id)
    # Implement Apple/Google in-app purchases and server receipt validation here.
    # Never grant paid content solely because a client says the purchase succeeded.
