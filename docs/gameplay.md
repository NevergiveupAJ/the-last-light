# Gameplay systems

| System | How it works | Script |
|---|---|---|
| Objective | 3 fuses, then the gate control box, then the exit trigger behind the gate | game_manager.gd, emergency_gate.gd |
| Stamina | Sprinting drains 24/s and recovers 16/s. At 0 Alex is exhausted until stamina is back to 25% | player.gd |
| Noise | Footsteps: sprint 1.0, walk 0.4, crouch 0.08. Jumps 0.6, pickups 0.25. The Hollow hears noise up to 14 m times the loudness | player.gd, monster.gd |
| Sight | Range 16 m, 120° view, sensed within 3.5 m from any angle. Crouching ×0.6, flashlight on ×1.35, final chase ×2. Walls block sight | monster.gd |
| Attack | 0.45 s wind-up, 25 damage (scaled by difficulty), 1.6 s cooldown, 0.6 s recovery. Alex is invulnerable for 0.8 s after a hit | monster.gd, player.gd |
| Flashlight | 100% battery drains 0.6%/s (scaled by difficulty). Dims under 25%, flickers under 15%. A battery item adds 60% | weapon.gd |
| Items | Battery (max 5), Medkit +45 (max 3), Bandage +20 (max 5), Flare (max 3), Fuse (max 3). Up to 8 different item types | inventory.gd |
| Flare | Thrown with a throw arc. The Hollow goes to it for 8 s (4 s in the final chase) | flare.gd |
| Final chase | Gate powered: The Hollow chases at ×1.2 speed, keeps getting hints of where Alex is, and teleports in if more than 35 m away | monster.gd |
| Difficulty | Story / Survival / Nightmare: monster speed 0.8/1.0/1.15, detection 0.75/1/1.3, damage 0.6/1/1.4, battery drain 0.7/1/1.4, starting supplies +2/0/-1 | save_system.gd |
| Atmosphere | Rain cycles, lightning plus thunder, fog drift, flickering lights, clock from 2:17 AM to dawn (5:00 to 6:00 AM, about 27 minutes in) | weather.gd, flicker_light.gd |
