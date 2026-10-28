# Copyable Prompts for Building the Remaining Game

## Prompt 1 — Finish the Godot project
"Use Godot 4 GDScript and the files in this starter kit. Create a complete playable vertical slice of THE LAST LIGHT.
Create all required scenes with correct node paths and signal connections, a small forest level built from primitives,
a player controller, three fuse pickups, a gate that unlocks only after all fuses are collected, a monster with a
cooldown-based attack, win and lose states, and a restart button. Do not claim unimplemented systems work.
Return every file with exact paths and explain how to run the project."

## Prompt 2 — Monster behavior
"Implement a production-style stealth horror AI in Godot 4 using NavigationAgent3D, line-of-sight raycasts, hearing
events, patrol waypoints, investigate, chase, search, attack windup, attack cooldown, and recovery. Use clear exported
parameters, avoid damage every frame, and include animation state hooks and debugging labels."

## Prompt 3 — Mobile UI
"Create Godot 4 landscape touchscreen controls for THE LAST LIGHT: left virtual joystick, right-side camera drag,
sprint, crouch, jump, interact, flashlight, inventory, pause, health, stamina, battery, and fuse counter. Make buttons
resize for tablets and phones and support a left-handed layout and adjustable sensitivity."

## Prompt 4 — Store implementation
"Design an optional cosmetic store for Godot 4 with product catalog, product detail panel, purchase pending/success/
failure states, restore purchases, and locked/unlocked cosmetic selection. Keep all purchases disabled behind an
interface until official Apple/Google billing and server receipt validation are configured. Do not simulate a real
payment or store sensitive payment data."

## Prompt 5 — QA and performance
"Audit the Godot 4 project for missing node paths, invalid signals, script errors, mobile performance, touch targets,
accessibility, save/load, scene transitions, collision, navigation mesh, and store safety. Give a checklist and fix
issues in source files; distinguish tested behavior from assumptions."
