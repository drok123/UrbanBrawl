# Urban Brawl — Reusable Resource Stack

Goal: avoid rebuilding solved systems. Urban Brawl-specific combat, weapon feel, gore rules, and hideout interactions stay custom; generic infrastructure should use mature Godot resources where practical.

## Adopt / Study

### GLoot — inventory, stash, serialization
Repository: `peter-kish/gloot`
License: MIT
Godot: 4.4+

Why it fits:
- item prototypes with inheritance
- per-item overridden properties (good for rarity rolls / affixes)
- item slots
- inventory constraints
- item transfer
- serialization/deserialization
- basic inventory UI for debug/testing

Urban Brawl usage:
- hideout weapon stash
- winner/extraction inventory
- persistent weapon instances
- rarity, affixes, durability/ammo as item properties
- equipped weapon slot

Do **not** use GLoot to decide combat behavior. A stored item should reference an Urban Brawl weapon definition which owns attack timing, hitboxes, animations, damage type and physical presentation.

### LimboAI — bots / combat AI
Repository: `limbonaut/limboai`
License: MIT-style
Versions are matched to Godot versions (1.6.x supports 4.4/4.5/4.6; current 1.8.x targets 4.6+).

Why it fits:
- behavior trees
- hierarchical state machines
- blackboards
- reusable subtrees
- editor and live visual debugger

Urban Brawl usage later:
- sparring bots
- FFA bots
- weapon-seeking behavior
- danger avoidance / spacing
- opportunistic looting
- combat personality variation

Current hand-written sparring AI can remain the prototype until behavior complexity justifies installing LimboAI.

### Friendslop Template — networking/session reference
Repository: `RGonzalezTech/Friendslop-Template`
License: MIT
Godot: 4.4+

Why it fits:
- ENet multiplayer foundation
- scene synchronization
- lobby/player spawning
- safe synchronized scene transitions
- handshake replication
- GUT tests

Urban Brawl usage:
- use as a reference/source of proven patterns when the hideout becomes multiplayer
- physical hideout party/lobby state
- transition hideout party -> match -> return to hideout

Do not replace the current project with the template; transplant the useful networking components when multiplayer becomes the active milestone.

### Godot Compatibility Decal Node — blood / bullet decal pooling
Repository: `antzGames/Godot-Compatibility-Decal-Node`
License: MIT
Godot: tested 4.4–4.7.x

Why it fits:
- instanced decals
- very large decal counts with low draw-call cost
- animated one-shot decals
- fading / pooled instances
- supports Compatibility, Mobile and Forward+ workflows

Urban Brawl usage later:
- blood splashes
- blood pools
- bullet holes
- impact grime
- persistent arena aftermath with a controlled performance budget

### Alenvei Godot 4 blood-splatter example
Repository: `Alenvei/GODOT4-Blood-splatter-Tutorial`
License: MIT

Use as a small reference for blood particle/splatter setup. Do not make this the main gore architecture.

### Godot built-in ragdoll / PhysicalBone3D
Official engine system.

Urban Brawl usage later:
- full-body death ragdolls
- physical severed limbs
- partial physical-bone simulation where useful

Dismemberment itself remains Urban Brawl-specific because it must integrate hit location, damage type, weapon source, gore threshold and gameplay effects.

## Build ourselves

These systems define the game and should remain under our control:

- `CombatHit` / combat-result pipeline
- unarmed and weapon movesets
- active attack hitboxes / telegraphs / commitment timing
- weapon world pickup/drop/steal interaction
- weapon physical presentation
- rarity visualization in the 3D world
- weapon-definition -> inventory-item mapping
- damage-type and hit-location rules
- dismemberment/gib decision logic
- free-for-all match rules and prize-pool logic
- physical hideout interactions / diegetic UI

## Immediate architecture decision

A weapon has two layers:

1. **Weapon definition** — static Urban Brawl combat data (bat, knife, cleaver, pistol etc.).
2. **Weapon instance** — persistent rolled item stored by the inventory system (rarity, affixes, durability/ammo, unique ID/seed).

During a match, the world pickup bridges those layers. Picking up a weapon equips the definition plus the instance's rolled modifiers. Dropping it puts the same instance back into the world. Winning can transfer eligible instances into the hideout inventory.

This prevents the combat engine from becoming dependent on inventory UI/storage code while still allowing persistent loot.

## Rule

Before implementing a generic subsystem, check Godot Asset Library / maintained open-source Godot 4 projects first. Prefer MIT/BSD/Apache resources with clear Godot-version compatibility. Keep third-party licenses documented here.
