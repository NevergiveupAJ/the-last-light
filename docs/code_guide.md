# Code guide

| Script | Attached to | Job |
|---|---|---|
| save_system.gd | autoload `SaveSystem` | Settings, stats, cosmetics, difficulty table, save file |
| main_menu.gd | MainMenu.tscn | Title screen, difficulty, settings, store, help |
| main.gd | Main.tscn root | Wires everything together and applies difficulty |
| game_manager.gd | Main/GameManager | Objectives, fuses, documents, pause, endings |
| world_builder.gd | Main/Level (NavigationRegion3D) | Builds all 6 locations, then bakes navigation |
| player.gd | Player.tscn | Alex's movement, look, items, health, noise |
| alex_model.gd | Player/AlexModel | Alex's body and animations (or alex.glb) |
| weapon.gd | Player/Head/Flashlight | Flashlight battery, dimming, flicker |
| inventory.gd | Player/Inventory | Item counts and limits |
| interaction.gd | Player/Interaction | Look-at prompt and USE |
| monster.gd | TheHollow.tscn | AI state machine, senses, attacks |
| hollow_model.gd | TheHollow/ModelRoot | Hollow body and animations (or the_hollow.glb) |
| item_pickup.gd | ItemPickup.tscn | Fuse, battery, medkit, bandage, flare |
| document_pickup.gd | Document.tscn | The 5 story documents |
| emergency_gate.gd, gate_control_box.gd | EmergencyGate.tscn | Fuse box, opening gate, exit trigger |
| flare.gd | Flare.tscn | Thrown flare that distracts The Hollow |
| hud.gd, settings_panel.gd | HUD.tscn | All on-screen UI |
| mobile_controls.gd | MobileControls.tscn | Multi-touch stick, look and buttons |
| audio_manager.gd | Main/AudioManager, MainMenu/AudioManager | Music, sound effects, synthesized stand-ins, captions |
| weather.gd, flicker_light.gd | Main/Weather, the level's lights | Rain, lightning, fog, clock, flicker |
| store_manager.gd | created by the main menu | Cosmetic catalog (purchases off) |
| primitive_kit.gd | (helper) | Builds stand-in meshes and materials |

**Physics layers:** 1 world, 2 player, 3 monster, 4 interactable (pickups and the control box).
**Groups:** `player`, `monster`, `game_manager`, `audio_manager`, `patrol_point`.
**Save file:** `user://last_light.cfg` with sections `settings`, `stats` and `cosmetics`. Don't rename those keys, or players lose their saves.

What changed from the original starter scripts (kept in `docs/original_starter/scripts/`):
- `project.godot`: the Shift, Ctrl and Esc key codes were invalid (`_SHIFT` and so on), so those keys wouldn't have worked. Fixed, and added arrow keys, flare, view and alternate keys.
- `inventory.gd`: the slot limit counted item *amounts*, not slots, so you couldn't pick up a new kind of item once you had 8 things. Now it counts item types, and each item has a carry limit.
- `monster.gd`: line of sight was only a distance check, damage could repeat with no wind-up, and there was no flare or final-chase behaviour. All added, plus navigation fallback and search wandering.
- `player.gd`: added hit invulnerability, safe crouch (won't stand into a ceiling), noise, third person, items and death.
- `weapon.gd`: the flashlight couldn't be toggled from input. Now it can, and it flickers when low.
- `interaction.gd`: now ignores the player's own body, works in third person and shows prompts.
- `item_pickup.gd`: now has a pickup layer and visuals, and gives feedback when your bag is full.
