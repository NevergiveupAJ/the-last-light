# Store, Monetization, and Publishing Plan

## Fictional in-game store
The starter catalog is cosmetic-first:
1. Storm Coat — survivor cosmetic.
2. Research Suit — survivor cosmetic.
3. Vintage Beam — flashlight skin only.
4. Digital Artbook — optional bonus content.
5. Original Soundtrack — optional bonus content.

The game should remain complete and beatable without purchases. No loot boxes, no pay-to-win stats, and no fake discounts.

## Technical status
The sample `store_manager.gd` only contains product data and signals. It does NOT charge money or connect to Apple/Google.
Before enabling real payments, implement official platform billing, receipt verification, restore purchases, refund support,
privacy policy, terms, age rating, parental safeguards, and regional price display.

## App Store / Google Play checklist
- Choose app name and verify trademark/store-name availability.
- Create release builds from Godot for Android and iOS.
- Configure package/bundle ID and signing certificates.
- Create original icon, feature graphic, screenshots, and preview video.
- Provide accurate age rating and content disclosures for horror/violence.
- Publish privacy policy and support contact.
- Test controls, performance, overheating, accessibility, crash recovery, and offline behavior.
- Test on real devices, multiple screen sizes, and low-memory phones.
- Verify all third-party assets and sounds have commercial-use licenses.
- Submit through the official developer consoles and address review feedback.

## Store page copy draft
Title: THE LAST LIGHT
Short description: Find the fuses. Avoid the Hollow. Escape the research station.
Long description:
A storm traps you inside an abandoned forest research station. Your flashlight is dying, the emergency gate has no
power, and something moves between the trees. Search cabins, recover three fuses, manage scarce supplies, and
listen carefully: every sound may reveal your location. Hide, distract the creature, and reach the gate before the
last light goes out.
Features:
- First-person survival horror
- Stealth, exploration, and resource management
- A roaming enemy that investigates and pursues
- Dark forest, cabins, lab corridors, and maintenance tunnels
- Optional cosmetic items; core story playable without purchases
