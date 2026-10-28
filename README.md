# THE LAST LIGHT

*Survive. Find. Escape.* A mobile 3D survival-horror game for Godot 4.3: a playable vertical slice.

You wake at 2:17 AM in an abandoned forest research station. Find three power fuses, restore the emergency gate, and escape before **The Hollow** finds you.

**Start with `STATUS.md`.** It lists exactly what's finished and what isn't, and how it was checked.

## Play on a phone
Open **https://the-last-light.miliusjonathan68.workers.dev** in Safari or Chrome and turn the phone sideways.
Hosted on the Cloudflare Worker `the-last-light`. Every push to `main` redeploys it. After changing the game, run `sh tools/export_web.sh` and commit `web/`.

## Run it on a computer
1. Install **Godot 4.3** (standard build) from godotengine.org.
2. In Godot, choose Import and pick this folder's `project.godot`.
3. Press **Play** (F5).

Keys: WASD move, mouse look, Shift sprint, Ctrl/C crouch, Space jump, E use, F flashlight, G flare, Tab/I items, V camera view, Esc pause.
On a phone the touch controls turn on by themselves. To try them on a computer, go to Settings and set Touch controls to "Always on".

## Folders
```
TheLastLight/
  project.godot  export_presets.cfg  icon.svg  STATUS.md
  scenes/        MainMenu, Main, Player, TheHollow, HUD, MobileControls,
                 ItemPickup, Document, EmergencyGate, Flare
  scripts/       all GDScript (see docs/code_guide.md)
  assets/        audio/{music,sfx,video}  models/{characters,monsters,weapons,environment}
                 textures/{characters,monsters,weapons,environment,ui}  ui/{fonts,images}
  docs/          storyline, gameplay, controls, store_guide, asset_prompts, map_layout,
                 code_guide, concepts/ (design sheets), original_starter/ (your original kit)
  builds/        android/ and ios/ build instructions
  prototype_html/ the original browser prototype, unchanged
  tests/         automated playthrough + screenshot maker
  tools/validate_project.py   static checker (no Godot needed)
```

## Tests
```
godot --headless --path . res://tests/playthrough_test.tscn   # 45-check automated playthrough
```
Screenshots: `docs/screenshots/`.

## Check the project without Godot
```
pip install gdtoolkit==4.3.3   # optional, adds the GDScript syntax check
python3 tools/validate_project.py
```
