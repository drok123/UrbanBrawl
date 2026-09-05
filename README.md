# Urban Brawl

A ground-up Godot 4 reboot of Urban Brawl focused first on responsive top-down hero-brawler combat.

## Current milestone: Combat Lab 0.4 -> resource-backed 0.5

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

## First-time setup

Urban Brawl now intentionally uses mature external Godot systems for solved infrastructure instead of rebuilding everything ourselves.

1. Install the current stable Godot 4 release.
2. Clone/pull this repository.
3. Double-click **`INSTALL-DEPENDENCIES.bat`** once after a fresh clone (and whenever dependency versions are intentionally changed).
4. The installer fetches pinned releases of:
   - `Oen44/Godot-Inventory @ v4.0.1a` for inventory, itemization, equipment and affixes.
   - `bitbrain/beehave @ v2.9.3` for behavior-tree AI.
5. Restart Godot after installation.
6. Open `project.godot` and press **F6/F5** or Play.

Generated third-party folders are intentionally git-ignored. Pulling Urban Brawl remains clean; dependency versions are controlled by the installer script.

## Controls

Fight the sparring bot using **WASD** + mouse aim.

- **LMB** — strike
- **Q** — heavy cleave
- **E** — shoulder charge
- **Space** — dodge/dash

## Combat architecture

Ability tuning lives under `resources/abilities/`. Hit detection, damage reactions, player movement, AI and HUD code are separated so future fighters and weapons can reuse the same combat foundation.

`CombatHit` is the common damage payload. It carries source, ability, damage, impulse, hitstop, wall-stun window, damage type, weapon id, rarity metadata, gore power and hit-location fields. The current unarmed moves use `weapon_id = unarmed` and blunt/body defaults, but the same pipeline is intended to support bats, knives, cleavers, firearms, localized reactions, dismemberment and other weapon-specific outcomes later without replacing the damage API.

Generic persistent item/rarity/inventory code is no longer being built in-house. Oen44's inventory/itemization stack will own that side while Urban Brawl owns how an equipped item maps into a physical weapon and combat moveset.

The current hand-written sparring brain is also transitional. Beehave will own decision-tree plumbing while Urban Brawl supplies combat-specific actions/conditions such as seek weapon, maintain spacing, dodge danger, steal pickup, choose target and commit to attacks.

See:

- `docs/COMBAT_REFERENCES.md` for combat references.
- `docs/RESOURCE_STACK.md` for the use-vs-build dependency strategy and license notes.

## Direction

The current moveset is the **unarmed baseline**, not a permanent hero-specific kit.

Longer-term direction:

1. Prove readable unarmed PvP-style combat and counterplay.
2. Replace generic prototype subsystems with stronger maintained Godot resources where appropriate.
3. Add world weapon pickups as alternate movesets rather than simple damage buffs.
4. Add rarity/stat/affix data through the inventory/itemization layer while preserving matchup readability.
5. Build the free-for-all weapon scramble loop.
6. Add persistent winner loot/inventory and prize-pool extraction.
7. Build the hideout as the physical lobby, party, stash and game-mode interface.
8. Layer in blood, pooled decals, ragdolls, dismemberment and gibs through the existing hit-result pipeline.

The old 2.5D projection is intentionally not part of this reboot. Combat is built in a genuine 3D world while preserving a readable top-down/isometric presentation.
