# Urban Brawl — Reusable Resource Stack

Goal: do not rebuild solved systems. If a maintained Godot 4 resource is clearly stronger than our prototype implementation, **replace the prototype** rather than preserving it out of pride. Urban Brawl-specific combat feel, weapon behavior, gore rules, FFA rules and hideout interactions remain custom.

## Adopt / Replace

### Oen44 Universal Inventory System — inventory, itemization, rarity/affixes, equipment
Repository: `Oen44/Godot-Inventory`
License: MIT
Target: current 4.0.x line; current asset-store build targets Godot 4.7.

This **replaces our homemade persistent weapon-instance / rarity / inventory layer**.

Why it fits:
- universal inventories and containers
- equipment system
- itemization
- affix rolls
- item tooltips
- vendor/trading support
- item events such as equip/unequip/use in recent releases

Urban Brawl usage:
- hideout weapon stash
- persistent extracted weapons
- rarity and affixes
- durability / ammo / value properties
- equipped weapon slot
- prize-pool rewards
- later hideout vendor / trading interactions if desired

Integration note: this project expects its `scripts/` and `scenes/` folders at `res://scripts/...` and `res://scenes/...`. Those namespaces do not currently collide with Urban Brawl's combat folders, so it can be merged into the project root. Its item data should point to Urban Brawl combat definitions rather than owning attack timing itself.

### Beehave — behavior-tree AI
Repository: `bitbrain/beehave`
License: MIT
Godot: Godot 4.x; current line supports modern Godot 4 versions and has a runtime debug view.

This **replaces the hand-written sparring-bot decision brain** once integrated. Our current bot remains only until the Beehave tree is wired and validated.

Why it fits:
- pure Godot/GDScript addon, avoiding compiled-extension version friction
- node-based behavior trees
- reusable behavior nodes/subtrees
- runtime debug view
- performance monitors
- automated tests

Urban Brawl usage:
- weapon-seeking FFA bots
- spacing / approach / retreat / strafing
- danger avoidance
- opportunistic pickup stealing
- target selection
- personality variations
- hideout NPC behavior later

### Godot Compatibility Decal Node — blood / bullet decal pooling
Repository: `antzGames/Godot-Compatibility-Decal-Node`
License: MIT
Godot: tested across modern Godot 4.x renderers.

This should **replace a homemade decal/pool renderer** if it performs well in our project.

Urban Brawl usage later:
- blood splashes
- blood pools
- bullet holes
- wall/floor impact grime
- persistent arena aftermath with a controlled performance budget

### Friendslop Template — networking/session components
Repository: `RGonzalezTech/Friendslop-Template`
License: MIT
Godot: 4.4+

When multiplayer becomes active, we should be willing to **replace prototype lobby/session code with its stronger components**, not merely study them.

Useful pieces:
- ENet multiplayer foundation
- scene synchronization
- lobby/player spawning
- synchronized scene transitions
- handshake replication
- GUT test setup

Urban Brawl still owns the diegetic presentation: hideout party formation, physical matchmaking interaction, match entry and return-to-hideout flow.

### Alenvei Godot 4 blood-splatter example
Repository: `Alenvei/GODOT4-Blood-splatter-Tutorial`
License: MIT

Use as a reference/source for blood particle and splatter behavior where useful. Prefer the pooled decal system for long-lived environmental marks.

### Godot built-in ragdoll / PhysicalBone3D
Official engine system.

Use instead of inventing body physics:
- full-body death ragdolls
- physical severed limbs
- partial physical-bone simulation

Urban Brawl still owns the decision layer that says *when* a limb severs or a body gibs based on hit location, damage type, weapon, impulse and gore threshold.

## Keep custom because this IS the game

These systems define Urban Brawl and remain under our control unless an external system demonstrably improves them without compromising the design:

- `CombatHit` / combat-result pipeline
- unarmed combat feel
- weapon movesets
- active attack windows / telegraphs / commitment timing
- physical world weapon pickup/drop/steal behavior
- rarity visualization in the 3D world
- inventory-item -> combat-definition bridge
- damage type / hit location / gore-power rules
- dismemberment and gib decision logic
- free-for-all match rules and prize-pool logic
- physical hideout interactions / diegetic UI

## Weapon architecture after replacement

A weapon still has two conceptual layers, but the persistent half belongs to the inventory system:

1. **Urban Brawl combat definition** — bat/knife/cleaver/pistol attack timing, reach, hitbox, damage type, animation/VFX/SFX and world model.
2. **Inventory item instance** — rarity, affixes, durability/ammo, value, unique rolled properties and persistence.

The world pickup bridges them. Equipping reads the inventory item's rolled modifiers and applies them to the combat definition. Dropping preserves the same item instance. Winning can transfer selected surviving items into the hideout stash.

## Development rule

Before implementing a generic subsystem, search the Godot Asset Store / Asset Library and maintained open-source Godot 4 projects first.

Prefer:
- current Godot-version compatibility
- MIT/BSD/Apache licensing
- active maintenance
- tests/debugging tools
- reusable data-driven APIs

If the external solution is better, **replace ours early while migration is cheap**.
