# THE LAST LIGHT: what's finished and what isn't

Version 0.1.0, a Godot 4.3 vertical slice. Last checked 2026-10-28.

## How this was checked (read this first)

| Check | Result |
|---|---|
| GDScript syntax, all 25 scripts (gdtoolkit 4.3.3 parser) | **Passed** |
| `tools/validate_project.py`: scene files, resource ids, node paths used by scripts, input actions, `res://` files, method, property and signal names across the project's own classes | **Passed** (146 cross-file checks) |
| Validator self-test (I broke a node name, an input action and a method name on purpose) | All 3 problems were caught |
| Opened in the Godot editor, played, exported to a phone | **Not done.** I couldn't install Godot in this environment. |

So the files are consistent with each other and free of syntax errors. They have **not been run**. Expect a few small runtime fixes the first time it's opened in Godot, such as a light that's too bright, a prop that needs moving, or a warning to clear. Do the first-run checklist at the bottom before trusting anything else in this file.

## Finished (written, wired together, and passing the checks above)

### Alex (playable character)
- First-person controller with an optional third-person camera (V key, or Settings). The camera arm won't clip through walls.
- Walk, sprint with stamina (and an exhausted state), crouch that shrinks the collider and won't let you stand up under a ceiling, jump, interact.
- Head bob, a camera shake when hit, a fall-down death camera.
- Health with a 0.8 s invulnerability window after each hit. Vibrates on hit (can be turned off).
- Footstep noise: sprinting is loud, walking is medium, crouching is nearly silent. The Hollow hears it.
- Stand-in 3D body built to the design sheet: 1.8 m, olive jacket, charcoal pants, boots, backpack, radio, flashlight in the right hand. It animates idle, walk, run, crouch, jump, interact, hurt and death in code.
- Drop-in rig support: put `alex.glb` in `assets/models/characters/` and it's used automatically, with animations named idle/walk/run/crouch/jump/interact/hurt/death.

### The Hollow (monster)
- State machine: patrol, investigate, chase, attack, search, distracted.
- Real line of sight: a raycast plus a 120° field of view, with close-range sensing. Crouching makes Alex harder to see, a lit flashlight makes him easier to see.
- Hearing: footsteps, jumps and pickups send noise events.
- Attack: wind-up, then damage only if Alex is still in range, then cooldown and recovery. It never damages every frame.
- Search: wanders random points around where it lost Alex, then goes back to patrolling.
- Flares distract it.
- Final chase: once the gate is powered it gets faster, sees farther, keeps getting hints of where Alex is, and teleports in if it's far away.
- Uses NavigationAgent3D on a navigation mesh baked at runtime, and walks straight at its target until the bake finishes.
- Stand-in body built to the design sheet: about 2.5 m, gaunt, long arms, crooked shoulders, pale skin, torn cloth, featureless head, glowing amber eyes. Animations in code: idle twitch, gait, chase lean, attack slash, search head-scan, death.
- Drop-in model support: `assets/models/monsters/the_hollow.glb`.
- Difficulty changes its speed, detection and damage.

### World, story, objectives
- All 6 locations are built from simple shapes with collision: Forest Entrance, Cabins (3), Generator Station, Research Facility (front hall, lab, server room), Underground Tunnels (a real pit with a ramp, ceiling, corridors and the "lower door"), and the Emergency Gate.
- Pine forest (about 190 trees, batched for phones), rocks, perimeter fence, signs, wrecked truck, puddles, pipes, flickering lights.
- 3-fuse mission. The gate control box only works with all 3 fuses. The gate then grinds open slowly (that's the final chase) and the exit trigger wins the game.
- 5 collectible documents with story text. Reading one pauses the game.
- 3 endings: death, escape, and the true ending (escape with all 5 documents).
- Items: battery, medkit, bandage, flare, power fuse. Inventory has carry limits.
- Difficulty modes Story, Survival and Nightmare change monster speed, detection, damage, battery drain and starting supplies.
- Atmosphere: rain that follows you (not inside the tunnels), lightning and thunder, drifting fog, flickering lamps, and a 2:17 AM clock that runs toward dawn.

### Mobile controls and UI
- Multi-touch: floating move stick on the left, drag-to-look on the right, plus USE, JUMP, SPRINT (hold), CROUCH (toggle), LIGHT, FLARE, BAG and pause buttons.
- Left-handed mirror, button size slider, look sensitivity, invert-Y, touch controls set to Auto/On/Off.
- Touch buttons send the same input actions as the keyboard, so both always behave the same.
- HUD: health, stamina and flashlight bars, objective, clock, fuse and document counters, a context prompt ("Tap USE: Pick up Battery"), messages, a damage flash, a low-health pulse, sound captions.
- Inventory screen (use items), document reader, pause menu with all settings, win and lose screens with time and stats.
- Main menu with the key art, difficulty, settings, store, how-to-play, and saved stats.
- Saving: settings, stats (escapes, deaths, best time, endings found) and cosmetics in `user://last_light.cfg`.
- Landscape orientation, the mobile renderer, and ETC2/ASTC textures for phones.

### Audio
- Plays real files if you add them (see `docs/asset_prompts.md` for file names): menu, forest, lab and tunnel, chase and escape music, plus sound effects.
- Until then, a built-in synthesizer makes stand-in sound so the game is never silent: wind, rain, a heartbeat that speeds up as The Hollow gets closer, a chase drone, footsteps, pickups, growls, shrieks, radio static, thunder, the gate grinding, flare hiss.
- Prompts for every original music track and sound effect are in `docs/asset_prompts.md`.

### Store
- Catalog (Storm Coat, Research Suit, Vintage Beam, Artbook, Soundtrack), owned and equipped state, equip screen. Outfits change Alex's colours and Vintage Beam warms the flashlight.
- **Buying is switched off on purpose** (`PURCHASES_ENABLED := false`). Nothing takes payment details or charges money.

### Build setup
- `export_presets.cfg` with Android (arm64 APK) and iOS presets. `builds/android` and `builds/ios` have step-by-step READMEs.

## Not finished

| Area | What's missing |
|---|---|
| **Testing** | Never opened in Godot, never played, never run on a phone. This is the biggest gap. |
| **Real 3D art** | Alex, The Hollow and every building are stand-in shapes. Realistic rigged models and textures still have to be made or bought (prompts are in `docs/asset_prompts.md`). |
| **Real audio** | Only the synthesized stand-ins exist. No composed music or recorded sound effects yet. |
| **Real purchases** | Apple and Google billing, a server that checks receipts, restoring purchases, refunds, privacy policy. Not started, and intentionally switched off. |
| **App store release** | No signing keys, developer accounts, icons at store sizes, screenshots or store listing. An iOS build needs a Mac with Xcode. |
| **Saving mid-run** | Only settings and stats are saved. Quitting mid-run starts over. |
| **Knife / pry tool, keys and locked doors, hiding spots (lockers)** | Mentioned in the starter docs but not built. |
| **Full day/night cycle** | Only night to dawn (the story happens in one night). |
| **Localization** | English only. |
| **Supporter pack "extra items"** | Left out on purpose: it would be pay-to-win, which the starter's own store rules forbid. |
| **Gamepad controls** | Keyboard, mouse and touch only. |
| **Performance tuning on real phones** | Shadows, the number of lights, fog and the navigation bake time still need measuring on low-end devices. |

## First-run checklist (in Godot 4.3)
1. Open `project.godot`. Let Godot import, then check the **Output** panel for red errors.
2. Press Play. The main menu should show the key art.
3. Press New Game. Watch for "navigation map" warnings, then walk to the generator station, the research facility server room and the tunnels.
4. Turn on The Hollow's debug label (TheHollow scene, `show_debug_label`) to watch its states.
5. To try the touch UI with a mouse, turn on Project > Project Settings > Input Devices > Pointing > Emulate Touch From Mouse, then set Touch controls to "Always on" in the game's settings. Turn emulation off again afterwards, because it makes a computer report a touchscreen.
6. Run `python3 tools/validate_project.py` again after any change.
