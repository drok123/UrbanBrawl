# Urban Brawl

A ground-up Godot 4 reboot of Urban Brawl focused first on responsive top-down hero-brawler combat.

## Current milestone: Combat Lab 0.4

The prototype is now testing actual unarmed dueling instead of only stationary targets:

- Real 3D arena and collision
- Fixed-angle top-down follow camera
- WASD movement + mouse-to-world aiming
- Data-defined `CombatAbility` resources
- Windup -> active -> recovery combat phases
- Reusable `Area3D` melee hitboxes active only during hit windows
- LMB basic strike
- Q heavy cleave
- E shoulder charge
- Space directional dash with short invulnerability frames
- Player health, hitstun, interruption, death and automatic combat reset
- A sparring bot that approaches, backs off, strafes and uses readable jab/heavy telegraphs
- Shared damage/knockback rules between the player, bot and training dummies
- Real wall-stun detection
- Live health, cooldown and combat-state HUD
- Two side training dummies retained for pure attack testing

## Run

1. Install Godot 4.x.
2. Open this repository folder as a Godot project (`project.godot`).
3. Press **F6/F5** or the Play button.
4. Fight the sparring bot using **WASD** + mouse aim.
5. Use **LMB** to strike, **Q** for heavy cleave, **E** for shoulder charge, and **Space** to dash through committed attacks.

## Combat architecture

Ability tuning lives under `resources/abilities/`. Hit detection, damage reactions, player movement, AI and HUD code are separated so future fighters and weapons can reuse the same combat foundation.

`CombatHit` is now the common damage payload. It already carries source, ability, damage, impulse, hitstop, wall-stun window, damage type, weapon id and hit-location fields. The current unarmed moves use `weapon_id = unarmed` and blunt/body defaults, but the same pipeline is intended to support bats, knives, cleavers, firearms, localized reactions, dismemberment and other weapon-specific outcomes later without replacing the damage API.

See `docs/COMBAT_REFERENCES.md` for the open-source/reference projects being studied, the patterns we are adopting, and relevant license notes.

## Direction

The current moveset is being treated as the **unarmed baseline**, not a permanent hero-specific kit.

Longer-term direction:

1. Prove readable unarmed PvP-style combat and counterplay.
2. Add world weapon pickups as alternate movesets rather than simple damage buffs.
3. Add rarity/stat/affix data while preserving matchup readability.
4. Build the free-for-all weapon scramble loop.
5. Add persistent winner loot/inventory.
6. Build the hideout as the physical lobby, party, stash and game-mode interface.

The old 2.5D projection is intentionally not part of this reboot. Combat is built in a genuine 3D world while preserving a readable top-down/isometric presentation.
