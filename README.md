# Urban Brawl

A Godot 4 top-down 3D urban crime brawler being built around faction territory, physical weapons, a shared street economy and MMO-style public-world structure.

## Current prototype shape

The normal flow is now:

`character creation -> semi-open city -> faction territory / private base -> street economy / combat -> instanced activities -> city`

Current systems include:
- three factions: Police, Contraband and Arms
- one walkable public city containing all three territories plus Central Commons
- private faction homes: Precinct 07, Contraband Safehouse and Arms Workshop
- combat/criminal/duty flagging
- physical weapon pickup/drop/equip and rarity/affix item instances
- unarmed, bat, knife and pistol movesets
- probabilistic recoil/stumble/fallback hit reactions with a balance-break model
- Beehave-driven cops, territory guards and FFA bot behavior
- observed crime events, arrests, evidence packages, case value, warrants and police raids
- grow/sell contraband loop
- arms gunrunning loop
- police interdiction loop
- staked FFA weapon-scramble activity
- Quaternius city/character/animation presentation with procedural fallbacks
- CityCrafter-driven block topology
- Godot Road Generator street geometry and traffic-lane foundation

## First-time setup

Urban Brawl deliberately uses mature external systems for solved infrastructure instead of rebuilding everything ourselves.

1. Install the current stable Godot 4 release.
2. Clone/pull this repository.
3. Double-click **`INSTALL-DEPENDENCIES.bat`** after a fresh clone and whenever pinned code dependencies change.
4. That installer fetches:
   - `Oen44/Godot-Inventory @ v4.0.1a` for inventory/itemization/equipment/affixes.
   - `bitbrain/beehave @ v2.9.3` for behavior-tree AI.
   - `TheDuckCow/godot-road-generator @ 0.9.3` for road meshes, collision and AI road lanes.
   - `SpartanDavie/CityCrafter3D-Aug2025 @ 04aee37` for city block topology/district generation. Only its core generator code is installed; its bundled example city art is intentionally excluded.
5. For the polished visual prototype, double-click **`INSTALL-VISUAL-PACKS.bat`**.
6. The visual installer opens the official Quaternius pages if the Standard/free ZIPs are not already in your Windows Downloads folder. Download the free versions of:
   - Downtown City MegaKit
   - Universal Base Characters
   - Universal Animation Library
   - Universal Animation Library 2
7. Return to the installer and press Enter. It detects the ZIPs, installs the glTF city/character assets, and copies only a focused GLB animation subset from UAL 1 + 2.
8. Restart/reopen Godot and allow the new 3D assets/addons to import.
9. Open `project.godot` and press Play.

The Quaternius packs are CC0 and are intentionally installed locally rather than committed as large binary dependencies. If they are missing or fail validation, Urban Brawl automatically keeps the procedural humanoid and graybox building fallbacks.

## City construction rule

The public city is now built in layers:

`CityCrafter topology -> Road Generator streets -> Urban Brawl block interpretation -> Quaternius buildings/props -> faction/gameplay placement`

CityCrafter determines active blocks, multi-size superblocks, edge variation and broad district density. It does **not** spray its bundled demo buildings into the game.

Road Generator consumes CityCrafter's actual seams, so merging a 2x2 block removes its internal streets rather than leaving a fake road hidden under geometry.

Urban Brawl interprets generated footprints deliberately:
- normal block = one primary building with setback
- long block = two or three aligned frontage buildings
- superblock = perimeter buildings around an interior courtyard
- industrial block = larger low structure with service space
- Central Commons = open pedestrian/public activity block
- faction HQ block = dominant structure with a readable forecourt

Quaternius Downtown City MegaKit supplies the primary architecture/street-prop visual language. Faction bases, buyers, interdiction targets, FFA, public vendors, cops and guards are placed onto valid generated frontages/plazas rather than unrelated fixed coordinates.

See `docs/CITY_PIPELINE.md` for the detailed rules.

## Controls

- **WASD** — move
- **Mouse** — aim
- **LMB** — basic attack
- **Q** — secondary/heavy ability
- **E** — utility/charge ability
- **Space** — dodge/dash
- **F** — contextual interaction / weapon pickup-drop

`R` remains reserved.

## Architecture rule

External resources should replace solved presentation/infrastructure, not Urban Brawl's identity.

Keep custom:
- CombatHit / attack timing / weapon movesets
- physical weapon ownership and extraction rules
- faction / territory / combat / criminal / duty flags
- crime observation and evidence provenance
- faction economy loops
- FFA risk/reward semantics
- balance/stumble/fallback probability rules
- faction/gameplay relationships layered onto the generated city

Use external systems for better art, animation, cameras, UI, sound, physics helpers, generic AI plumbing, persistence, roads, city topology and networking foundations when they are demonstrably stronger.

See:
- `docs/CITY_PIPELINE.md`
- `docs/RESOURCE_REPLACEMENT_AUDIT_2026-09.md`
- `docs/RESOURCE_STACK.md`
- `docs/MMO_WORLD_ARCHITECTURE.md`
- `docs/FACTION_CONFLICT.md`
- `docs/COMBAT_REFERENCES.md`
