# Godot 4 Scene Setup Checklist

The scripts are provided, but scenes and rigged models must be authored in Godot.

## Player.tscn
Root: CharacterBody3D named Player; attach `scripts/player.gd`.
Children:
- CollisionShape3D (capsule)
- Node3D named Head
  - Camera3D
    - SpotLight3D (flashlight beam)
- Node named Inventory (attach `scripts/inventory.gd`)
- Node named Interaction (attach `scripts/interaction.gd`; adjust camera_path if needed)
- Node3D named WeaponSocket

Set Player collision layer/mask appropriately and add it to the `player` group (script does this).

## TheHollow.tscn
Root: CharacterBody3D; attach `scripts/monster.gd`.
Children:
- CollisionShape3D
- NavigationAgent3D
- Node3D named ModelRoot (import your rigged GLB here)
- AnimationPlayer or AnimationTree for idle/patrol/chase/attack/death.
Bake a NavigationRegion3D navigation mesh over the walkable level.
Assign patrol_points in the Inspector to Node3D waypoints.

## Main.tscn
Root: Node3D named Main.
Children:
- WorldEnvironment (fog, ambient lighting)
- DirectionalLight3D or moon light
- NavigationRegion3D (walkable level and baked navigation mesh)
- StaticBody3D geometry for ground/walls with collision
- Player instance
- TheHollow instance
- GameManager (attach scripts/game_manager.gd; add to group `game_manager`)
- CanvasLayer HUD with health, stamina, battery, objective, interaction prompt
- CanvasLayer mobile controls for touch input

## ItemPickup.tscn
Root: Area3D; attach `scripts/item_pickup.gd`.
Children:
- CollisionShape3D
- MeshInstance3D (visual prop)
Set item_id and amount in the Inspector.

## Required implementation tasks
- Create an emergency gate interaction that calls `restore_gate()` after 3 fuses.
- Make the exit trigger call `reach_exit()`.
- Connect player `died` to `game_manager.player_died()`.
- Add a proper hit cooldown/invulnerability window to the player.
- Add line-of-sight raycasts and noise events to monster AI.
- Add animations and audio.
- Implement save/load, settings, subtitles, localization, and accessibility options.
- Build and test on real Android/iOS devices.
