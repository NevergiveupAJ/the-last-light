# Asset prompts and drop-in file names

Everything here is original. Keep the licence or receipt for every asset you use, and don't copy existing franchises, logos or melodies.
The game picks up files automatically when they have these exact names. Until then it uses its built-in stand-ins.

## 3D models (glTF binary, .glb)

| File | Notes |
|---|---|
| `assets/models/characters/alex.glb` | Humanoid rig, faces -Z, about 1.8 m. Animations named: `idle walk run crouch jump interact hurt death` |
| `assets/models/monsters/the_hollow.glb` | Faces -Z, about 2.5 m. Animations named: `idle patrol investigate chase attack search death` |

**Alex.** "Create an original game-ready 3D survivor named Alex for a first-person survival horror game. Adult male, 1.8 m, athletic build, weatherproof dark olive jacket, worn charcoal tactical cargo trousers, mud-stained hiking boots, compact emergency backpack, radio clipped to the strap, flashlight in the right hand. Front, side and back turnaround plus a close-up face reference, neutral A-pose, realistic PBR materials, humanoid skeleton for retargeting, mobile-friendly polygon budget, no text, no watermark."

**The Hollow.** "Create an original game-ready horror creature called The Hollow. About 2.5 m tall, thin, asymmetrical humanoid silhouette, elongated forearms reaching past the knees, crooked shoulders, pale rough decayed skin, torn dark fabric, a featureless face with subtle glowing amber eyes. Front, side and back turnaround, neutral rigging pose, PBR roughness and normal maps, humanoid skeleton with extra spine and neck controls, animation-ready, no gore, no text, no watermark, no resemblance to known horror franchises."

**Environment kit.** "Modular, mobile-optimised assets for an abandoned research station in a dense pine forest at night: pine trees, rocks, roots, broken chain-link fence, three small wooden cabins, a concrete generator station with a diesel generator, a research facility (front hall, lab with benches and terminals, server room), concrete maintenance tunnels with pipes, puddles and a sealed rusted 'lower door', and a sliding emergency gate with a yellow fuse control box. Wet PBR materials, collision-friendly shapes, separate reusable pieces."

**Items.** Flashlight (worn aluminium), flare (red, emissive tip), knife, medkit (pouch with cross), bandage roll, battery, keys, industrial ceramic power fuse with metal caps. "Isolated game prop, realistic PBR, low-poly game mesh plus high-poly reference."

**UI and store art.** "Readable mobile survival-horror HUD icons, high contrast, large thumb-friendly buttons, original icons." Store icon: "1024x1024, abandoned forest silhouette, small flashlight beam, two glowing eyes far between the trees, blue-black palette with one warm light, no small text."

## Music (`assets/audio/music/`, .ogg preferred, loops)

| File | Prompt |
|---|---|
| `menu_theme.ogg` | "Original slow ambient horror theme for a title screen: distant piano notes in a minor key, low string drone, faint wind, sparse and lonely, 90 seconds, seamless loop, no vocals." |
| `forest_ambience.ogg` | "Loopable night forest bed: wind through pines, creaking branches, light rain on leaves, very low sub drone, no melody, no speech, 2 minutes." |
| `lab_ambience.ogg` | "Loopable abandoned laboratory and tunnel ambience: electrical hum, flickering fluorescent buzz, distant dripping water, metal settling, ventilation rumble, no melody, 2 minutes." |
| `chase_theme.ogg` | "Original tense chase cue: driving low percussion, bowed metal, rising string clusters, 120-140 BPM, builds and loops, no melody copied from existing works, 60-90 seconds." |
| `escape_theme.ogg` | "Original escape and dawn cue: urgency that resolves into relief, warm low strings, a single held high note as daylight arrives, 60 seconds." |

## Sound effects (`assets/audio/sfx/`)

| File | Prompt |
|---|---|
| `footstep.ogg` | "Single boot footstep on wet forest dirt, close mic, short, dry." |
| `pickup.ogg` | "Short restrained analog click and soft rustle for picking up an item." |
| `click.ogg` | "Flashlight switch click, small metal button." |
| `objective.ogg` | "Low soft thump with a faint tone for completing an objective." |
| `static.ogg` | "Handheld radio static burst with a faint distorted voice fragment, under 1 second." |
| `growl.ogg` | "Low wet breathing growl from a large creature nearby, unsettling, not a known animal, 1-2 seconds." |
| `scream.ogg` | "Short inhuman shriek with a breathy distorted texture, 1 second, for a creature attack." |
| `hurt.ogg` | "Male grunt of pain with cloth movement, short." |
| `gate.ogg` | "Heavy rusted metal gate grinding and sliding open slowly, alarm hum underneath, 4-6 seconds." |
| `thunder.ogg` | "Distant rolling thunder over a forest, 3 seconds." |
| `flare.ogg` | "Road flare ignition: strike, fizz, steady hiss." |
| `error.ogg` | "Short low electrical buzz for a failed action." |

Also worth making later (not wired into the game yet): monster footsteps, heartbeat, rain on a metal roof, door creaks, monster proximity breathing loop.
