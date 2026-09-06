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
Godot: Godot 4.x; current v2.9.3 release explicitly targets modern Godot 4.7 and includes runtime debugging fixes.

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

### Godot Road Generator — authored city roads, intersections and traffic lanes
Repository: `TheDuckCow/godot-road-generator`
Pinned release: `0.9.3`
License: MIT
Godot: 4.4+; release 0.9.3 is tested on official Godot 4.7 builds.

This **replaces our hand-built BoxMesh road rectangles**.

Why it fits:
- spline/cross-section based road geometry
- multi-lane streets with proper lane markings
- procedural and prefab intersections
- automated collision generation
- automatically connected AI lane curves
- road-edge curves for sidewalks / street furniture
- supports runtime generation as well as editor-authored streets
- GDScript-only addon

Urban Brawl usage:
- one coherent authored semi-open city street network
- future traffic and getaway AI lanes
- road-edge decoration hooks for sidewalks, lights and clutter
- custom road width hierarchy: avenue / collector / neighborhood street

Urban Brawl **still owns the street plan**. The plugin owns road geometry, not city design. Faction base locations, combat sightlines, alleys, public plazas and MMO activity hotspots remain deliberately authored.

Current city rule:
`street network -> blocks -> lots -> buildings -> props -> gameplay interactions`

Do not return to placing buildings first and drawing roads around whatever space remains.

### Shomy QuestSystem — activities, jobs, heists, warrants and objectives
Repository: `ShomyKohai/quest-system`
License: MIT
Godot: 4.4+

Adopt when the Activity Framework slice starts instead of creating a custom quest/objective tracker.

Why it fits:
- resource-based quests/objectives
- modular API
- typed Godot 4 code
- serialization/deserialization
- localization support
- GDUnit4 tests
- designed to integrate with dialogue addons

Urban Brawl usage:
- FFA activity objectives
- beat-cop jobs
- heist prep / breach / vault / escape objectives
- warrants and raid prerequisites
- gang jobs
- street activities
- rewards and completion state

### Dialogue Manager 4 — dealers, NPC conversations and planning interactions
Repository: `nathanhoad/godot_dialogue_manager`
License: MIT
Godot: Dialogue Manager 4 targets Godot 4.6+

Adopt when the hideout + street slice begins.

Why it fits:
- branching dialogue editor/runtime
- conditions and mutations
- localization
- stateless architecture: Urban Brawl remains authority over economy/faction state
- headless presentation: we can keep diegetic Urban Brawl UI rather than using a generic RPG dialogue box

Urban Brawl usage:
- street weapon dealers
- contraband dealers
- police NPCs / dispatch
- heist planning interactions
- faction contacts
- gang recruitment / introductions
- tutorials without conventional menus

### Godot State Charts — activity and heist phase orchestration
Repository: `derkork/godot-statecharts`
License: MIT
Godot: 4.x; current Asset Library line is actively maintained.

Use this for complicated multi-phase activities rather than building another homegrown FSM framework.

Urban Brawl usage:
- activity lifecycle: staging -> live -> result -> return
- heist chains
- getaway phase changes
- raid phases
- arrest / pursuit states
- match lifecycle
- nested substates without state-explosion spaghetti

Beehave remains for **AI decisions**; State Charts is for **game/activity state**.

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

### Friendslop Template / server-authoritative lobby references — networking/session components
Primary reference: `RGonzalezTech/Friendslop-Template`
License: MIT
Godot: 4.4+

Additional reference: `tngklp/godot-multiplayer-lobby-system` for server-authoritative lobby patterns, ready state, reconnect/disconnect handling and dedicated-server structure.

When multiplayer becomes active, we should be willing to **replace prototype lobby/session code with stronger components**, not merely study them.

Useful pieces:
- ENet multiplayer foundation
- scene synchronization
- lobby/player spawning
- synchronized scene transitions
- handshake replication
- ready-state flow
- dedicated-server patterns
- disconnect handling

Urban Brawl still owns the diegetic presentation: hideout party formation, physical matchmaking interaction, match entry and return-to-hideout flow.

### Kenney Starter Kit Racing — getaway-instance starting point
Repository: `KenneyNL/Starter-Kit-Racing`
License: MIT code; bundled art/audio are CC0
Godot: current starter targets Godot 4.6

Do not build a car physics engine from scratch for the first heist getaway.

Use/transplant its arcade vehicle controller as the starting point for:
- goofy bank-heist getaways
- traffic dodging
- chase instances
- passenger shooting modes
- roadblocks / pursuit events

Urban Brawl can heavily simplify or exaggerate the handling rather than turning this into a driving simulator.

### SaveSystem candidate — local prototype persistence
Candidate: current Godot Asset Store `SaveSystem` by Tom Kooij
License: MIT
Godot: 4.5+

Evaluate when hideout state first needs disk persistence.

Important: long-term multiplayer economy / inventories should become **server-authoritative persistence**, so do not let a local-save addon dictate the final backend architecture. Oen44 item serialization and QuestSystem serialization already cover their respective data; this layer would initially coordinate local prototype state such as cash, heat, hideout upgrades and activity progress.

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

## Reference / transplant

### CityCrafter 3D — block/district configuration reference
Repository: `SpartanDavie/CityCrafter3D-Aug2025`
License: MIT
Godot: 4.4

Useful ideas:
- explicit CityConfiguration resource
- district-to-building collections
- block-size variation
- residential/internal subdivision concepts
- building spacing / border-margin controls
- generated objects remain editable standalone nodes

Do **not** make CityCrafter the Urban Brawl world generator. Its stated goal is a blocky grid city starting point, and it explicitly expects manual cleanup. Urban Brawl needs a more authored, combat-readable street plan. Borrow the configuration/data ideas, not the generated city topology.

## Evaluate only when needed

### Open World Database / Chunx — world streaming
Candidates:
- `DigitallyTailored/Godot-Open-World-Database`
- `SlashScreen/chunx`

Both are Godot 4 open-world streaming approaches. OWDB also has optional multiplayer-aware streaming; Chunx focuses on authored chunk streaming.

Do **not** install either yet.

Urban Brawl is intentionally targeting compact connected districts. First prove that ordinary scene organization, occlusion/LOD and district transitions are insufficient. Both streaming projects are under active development and add complexity we may not need.

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
- police evidence provenance / case-value rules
- crime economy balance and item-sink rules
- authored city topology / faction territory relationships / activity placement

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

Then classify it:

1. **Adopt now** — the current vertical slice needs it.
2. **Adopt when slice starts** — proven fit, but don't bloat today's project.
3. **Reference/transplant** — borrow the solved implementation/pattern without importing an entire project.
4. **Evaluate later** — useful only after we prove a real need.
5. **Keep custom** — this mechanic is part of Urban Brawl's identity.

If the external solution is better, **replace ours early while migration is cheap**.
