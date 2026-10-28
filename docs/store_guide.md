# Store guide

**Rules:** the whole story is free and can be finished. Store items are cosmetic only. No loot boxes, no pay-to-win, no fake discounts.

| Product | Type | Label shown | Effect |
|---|---|---|---|
| Storm Coat | outfit | $4.99 | Navy jacket on Alex |
| Research Suit | outfit | $4.99 | Yellow hazard suit on Alex |
| Vintage Beam | flashlight | $2.99 | Warmer beam colour, same power |
| Digital Artbook | bonus | $4.99 | Bonus content (not built) |
| Original Soundtrack | bonus | $2.99 | Bonus content (not built) |

## Status
- Done: catalog, owned and equipped state (saved), equip screen, outfit and beam visuals.
- **Off:** `StoreManager.PURCHASES_ENABLED = false`. Tapping a price only shows "The store isn't open yet. Nothing was charged."

## Turning on real purchases later
1. Create the products in App Store Connect and Google Play Console.
2. Add the official Godot billing plugins (Google Play Billing for Android, StoreKit for iOS).
3. Send each receipt to **your own server**, check it with Apple or Google, and only then call `StoreManager.unlock_verified(id)`.
4. Add Restore Purchases, refund handling, a privacy policy and parental safeguards.
5. Never collect card details in the game. The platforms handle payment.
