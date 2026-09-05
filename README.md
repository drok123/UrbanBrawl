# Urban Brawl

A ground-up Godot 4 reboot of Urban Brawl focused first on responsive top-down hero-brawler combat.

## Current milestone: Combat Lab 0.2

The project now has the first playable combat slice while preserving the movement and camera feel from 0.1:

- Real 3D arena and collision
- Fixed-angle top-down follow camera
- WASD movement
- Mouse-to-world raycast aiming
- Character rotation toward the cursor
- Left-click basic melee strike
- Q heavy cleave
- Space directional dash
- Damage, knockback and simple hit feedback
- Three resettable training dummies with health readouts

## Run

1. Install Godot 4.x.
2. Open this repository folder as a Godot project (`project.godot`).
3. Press **F6/F5** or the Play button.
4. Use **WASD** to move and the **mouse** to aim.
5. Use **LMB** to strike, **Q** for heavy cleave, and **Space** to dash.

## Direction

The old 2.5D projection is intentionally not part of this reboot. Combat is being built on a genuine 3D world while preserving a readable top-down/isometric hero-brawler presentation. The immediate goal is to make positioning, attacks, displacement, cooldown rhythm, and hit feedback feel good before deciding the final game loop.
