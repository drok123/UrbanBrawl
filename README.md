# Urban Brawl

A ground-up Godot 4 reboot of Urban Brawl focused first on responsive top-down hero-brawler combat.

## Current milestone: Combat Lab 0.3

The combat prototype now uses a small data-driven ability foundation instead of instant hard-coded attacks:

- Real 3D arena and collision
- Fixed-angle top-down follow camera
- WASD movement
- Mouse-to-world raycast aiming
- Character rotation toward the cursor
- Data-defined `CombatAbility` resources
- Windup -> active -> recovery combat phases
- Reusable `Area3D` melee hitbox active only during the hit window
- LMB basic strike
- Q heavy cleave
- E shoulder charge
- Space directional dash
- Ability telegraphs during windup
- Hitstop and impact flash feedback
- Knockback and real wall-stun detection for the shoulder charge
- Live cooldown + combat-state HUD
- Three resettable training dummies and a practice wall

## Run

1. Install Godot 4.x.
2. Open this repository folder as a Godot project (`project.godot`).
3. Press **F6/F5** or the Play button.
4. Use **WASD** to move and the **mouse** to aim.
5. Use **LMB** to strike, **Q** for heavy cleave, **E** for shoulder charge, and **Space** to dash.

## Combat architecture

Ability tuning lives under `resources/abilities/`. Hit detection, damage reactions, player movement, and HUD code are kept separate so future heroes can share the same combat foundation instead of duplicating logic.

See `docs/COMBAT_REFERENCES.md` for the open-source/reference projects being studied, the patterns we are adopting, and relevant license notes.

## Direction

The old 2.5D projection is intentionally not part of this reboot. Combat is being built on a genuine 3D world while preserving a readable top-down/isometric hero-brawler presentation. The immediate goal is to make positioning, attacks, displacement, cooldown rhythm, and hit feedback feel good before deciding the final game loop.
