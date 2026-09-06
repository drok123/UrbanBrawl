# Urban Brawl — Production City Pipeline

The public city uses external resources for the jobs those resources were actually designed to solve. Urban Brawl owns the master plan and gameplay geography.

## Audit decision — September 2026

The earlier generated-city stack accumulated too many correction layers. The core problem was not polish; it was asking resources to do jobs outside their intended design.

### CityCrafter 3D — evaluated, retired from production

CityCrafter is a useful MIT generator for quick **blocky / retro-style** city layouts. Its normal building pass chooses randomized positions inside generated blocks and its own documentation notes that unique building scenes may require cleanup.

That is useful for prototyping, but it is not the correct authority for Urban Brawl's semi-realistic Boston/NYC-inspired public city.

Production rules:
- CityCrafter is not a runtime dependency.
- `CityCrafterLayoutBridge` is removed.
- No post-generation script tries to repair a randomized city afterward.
- The installer removes stale `addons/citycrafter` files when it encounters them.

## Urban Brawl master plan — topology authority

`scripts/world/city_master_plan.gd` defines the production public-city topology.

It owns:
- stable street centerlines
- unequal block spacing
- stable block IDs
- Police / Contraband / Arms district placement
- Central Commons placement
- intended primary and secondary building frontages
- game-specific sightlines and activity geography

This is level design, not generic infrastructure, so it belongs to Urban Brawl.

The current plan is a compact four-by-four intersection network producing nine usable urban blocks. Spacing is intentionally not perfectly uniform. Block boundaries are derived from the real road envelope rather than an abstract generator cell size.

## Godot Road Generator 0.9.3 — street geometry authority

Pinned release: `TheDuckCow/godot-road-generator 0.9.3`
License: MIT

Production uses Road Generator the way its prefab workflow is designed:
- standard crossings instantiate the supplied `custom_containers/4way_1x1.tscn`
- the prefab owns its hand-modeled intersection mesh
- the prefab owns its intersection collision
- the prefab owns its hand-authored RoadLanes
- straight road runs live in their own RoadContainers
- RoadPoints inside one container use `connect_roadpoint()`
- separate RoadContainers are bridged with `connect_container()`
- outer roads continue past the last junction as ordinary straight RoadContainers

Production does **not** generate ordinary grid crossings with procedural `RoadIntersection` NGons.

Procedural intersections remain available for a future genuinely irregular junction where a prefab is not appropriate, but they are not the default.

The dependency installer validates the actual 3-way/4-way prefab `.tscn` and `.glb` files, not just the Road Generator scripts.

## Quaternius Downtown City MegaKit — architecture authority

License: CC0

The Downtown City MegaKit is a modular meter-scale city environment with hundreds of building/street pieces and authored example buildings.

Production rules:
- complete/prebuilt/example buildings are preferred for automatic whole-building placement
- a facade, wall, roof, window, road or sidewalk module is **never** promoted into a complete building just because its filename partially matches
- imported architecture stays at native 1:1 scale whenever it fits
- a building may be uniformly **scaled down** to fit a lot envelope
- automatic building placement does not scale a building up to fill an arbitrary graybox footprint
- collision is created from the fitted imported building bounds rather than from an unrelated prototype box
- the building root is ground-centered so height does not alter lot placement

This reverses the old relationship: the lot provides a maximum envelope; the authored building keeps its own proportions inside that envelope.

Later, genuinely modular custom landmarks can be assembled from Quaternius wall/facade/roof pieces deliberately. That is different from treating one module as an entire building at runtime.

## Current block language

The nine current blocks have explicit purposes instead of generated archetypes:
- northwest residential neighborhood
- north market/commercial block
- Contraband mixed-use block
- Police civic block
- Central Commons
- east market/commercial block
- southwest residential neighborhood
- west Foundry/industrial block
- Arms industrial block

Building rows use explicit street frontages. There is no radial “face the world origin” rule.

Central Commons remains open and is framed by real storefront buildings rather than procedural kiosks scattered through the plaza.

Industrial blocks reserve service-yard space. Police has a civic forecourt/parking relationship. Contraband is intentionally denser and mixed-use.

## Ground / sidewalk rules

For the current clean checkpoint:
- Road Generator owns asphalt and junction geometry.
- Urban Brawl derives block edges from the road envelope.
- each block gets a simple lot surface
- sidewalk strips follow those stable block edges
- custom curb/crosswalk overlays are intentionally removed while validating the corrected road resource use
- decorative street clutter is intentionally disabled during this structural checkpoint

We add detail only after the resource geometry reads correctly without camouflage.

## Gameplay geography

Urban Brawl still owns:
- faction territory state
- Police / Contraband / Arms HQ interactions
- drug buyer
- gunrunner buyer
- police interdiction target
- FFA activity entrance
- public weapon market
- guards/cops
- future world events and persistent block IDs

Gameplay nodes are placed from the same authored block/frontage data as the presentation. There is no second correction layer that can move a building without moving the activity relationship.

## Non-negotiable deslop rules

1. Use a resource according to its documented design before writing correction code around it.
2. Roads define the buildable block envelope.
3. Standard Road Generator intersections use its supplied prefab RoadContainers.
4. Do not distort complete Quaternius buildings to satisfy prototype box dimensions.
5. Do not use modular facades/walls as giant fake buildings.
6. One source of truth owns topology: `CityMasterPlan`.
7. One source of truth owns street geometry: Road Generator.
8. One source of truth owns city architecture: Quaternius Downtown City MegaKit.
9. Gameplay geography stays custom and references stable block/frontage IDs.
10. Never add a second post-generation layer whose purpose is to repair the first layer.
11. Do not add cars, trees, pedestrians or clutter to conceal structural problems.
12. Runtime diagnostics must identify which external building file was selected and the scale actually applied.

## Next work after runtime validation

Only after the corrected structural build is visually sound:
1. introduce 3-way prefab junctions where the authored plan benefits from a terminated street
2. deliberately assemble a few signature modular Quaternius landmarks
3. add door/storefront anchors
4. add restrained parking/loading geometry
5. restore district-specific street furniture
6. add ambient pedestrians
7. add light traffic using Road Generator lane data
8. profile before introducing mesh merging or streaming
