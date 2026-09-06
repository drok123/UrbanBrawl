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
- authored public-city master plan
- Godot Road Generator prefab intersections, road geometry and traffic-lane foundation

## First-time setup

Urban Brawl deliberately uses mature external systems for solved infrastructure instead of rebuilding everything ourselves.

1. Install the current stable Godot 4 release.
2. Clone/pull this repository.
3. Double-click **`INSTALL-DEPENDENCIES.bat`** after a fresh clone and whenever pinned code dependencies change.
4. That installer fetches:
   - `Oen44/Godot-Inventory @ v4.0.1a` for inventory/itemization/equipment/affixes.
   - `bitbrain/beehave @ v2.9.3` for behavior-tree AI.
   - `TheDuckCow/godot-road-generator @ 0.9.3` for authored road/intersection meshes, collision and AI road lanes.
5. For the polished visual prototype, double-click **`INSTALL-VISUAL-PACKS.bat`**.
6. The visual installer opens the official Quaternius pages if the Standard/free ZIPs are not already in your Windows Downloads folder. Download the free versions of:
   - Downtown City MegaKit
   - Universal Base Characters
   - Universal Animation Library
   - Universal Animation Library 2
7. Return to the installer and press Enter. It detects the ZIPs, installs the glTF city/character assets, and copies only a focused GLB animation subset from UAL 1 + 2.
8. Restart/reopen Godot and allow the new 3D assets/addons to import.
9. Open `project.godot` and press Play.

The Quaternius packs are CC0 and are intentionally installed locally rather than committed as large binary dependencies. If they are missing or fail validation, Urban Brawl keeps its procedural humanoid and graybox building fallbacks.

## City construction rule

The production public city is built in this order:

`Urban Brawl master plan -> Road Generator prefab RoadContainers -> stable block/sidewalk envelopes -> Quaternius complete buildings -> faction/gameplay placement`

The master plan is deliberately authored because street topology, combat sightlines, faction relationships and public activity space are game design—not generic infrastructure.

Road Generator owns actual street geometry. Ordinary intersections use its supplied hand-modeled `4way_1x1` prefab rather than our old procedural NGon junctions. Straight road sections are separate RoadContainers bridged through the addon's documented container-connection system.

Quaternius Downtown City MegaKit supplies the primary architectural language. Complete/prebuilt buildings stay at native meter scale whenever possible and are only uniformly reduced when they exceed a lot envelope. We no longer stretch authored buildings up to arbitrary prototype dimensions, and modular facades/walls are never auto-promoted into giant fake buildings.

CityCrafter was evaluated during prototyping and retired from the production runtime path. Its blocky/random city generator is useful for quick prototypes, but it is not the right topology authority for the semi-realistic streetscape Urban Brawl is targeting.

For the current structural checkpoint, random street clutter is intentionally disabled. We want roads, sidewalks, lots and architecture to read correctly before cars/trees/benches/pedestrians can hide mistakes.

See `docs/CITY_PIPELINE.md` for the detailed rules and audit decisions.

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
- faction/gameplay relationships layered onto the authored city

Use external systems for better art, animation, cameras, UI, sound, physics helpers, generic AI plumbing, persistence, roads and networking foundations when they are demonstrably stronger.

See:
- `docs/CITY_PIPELINE.md`
- `docs/RESOURCE_REPLACEMENT_AUDIT_2026-09.md`
- `docs/RESOURCE_STACK.md`
- `docs/MMO_WORLD_ARCHITECTURE.md`
- `docs/FACTION_CONFLICT.md`
- `docs/COMBAT_REFERENCES.md`
