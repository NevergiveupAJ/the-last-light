# THE LAST LIGHT: what's finished and what isn't

Version 0.1.1, a Godot 4.3 vertical slice. Tested in Godot 4.3 on 2026-10-28.

## How this was checked (read this first)

| Check | Result |
|---|---|
| Opened in **Godot 4.3** (editor import, headless) | **No errors.** Fixed 1 type error in the menu along the way. |
| Game started and run for 25 seconds | **No script errors** |
| Automated playthrough in the real engine (`tests/playthrough_test.tscn`): 45 checks covering walking, sprint, crouch, every pickup reachable, 3 fuses, items, 5 documents, monster sight, attacks and cooldown, walls blocking sight, hearing, navigation into the server room, flare distraction, touch stick / look / buttons, gate, final chase, walking out the gate, true ending | **45 / 45 passed** |
| Real rendered screenshots of the menu, all 6 locations, The Hollow and third person (`docs/screenshots/`) | Done |
| `tools/validate_project.py` and the GDScript syntax parser | Passed |
| Played by a person, or run on a real phone | **Not yet.** Still needed for feel, difficulty and performance. |

Run the tests yourself:
```
godot --headless --path . res://tests/playthrough_test.tscn
```
(The only output besides the results is a harmless "mesh is null" message that headless mode prints.)

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
| **Human and phone testing** | It passes automated tests in Godot, but nobody has played it by hand or run it on a phone yet. |
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
1. Open `project.godot` and let Godot import (it was clean in testing).
2. Press Play. The main menu should show the key art.
3. Press New Game. Watch for "navigation map" warnings, then walk to the generator station, the research facility server room and the tunnels.
4. Turn on The Hollow's debug label (TheHollow scene, `show_debug_label`) to watch its states.
5. To try the touch UI with a mouse, turn on Project > Project Settings > Input Devices > Pointing > Emulate Touch From Mouse, then set Touch controls to "Always on" in the game's settings. Turn emulation off again afterwards, because it makes a computer report a touchscreen.
6. Run `python3 tools/validate_project.py` again after any change.
