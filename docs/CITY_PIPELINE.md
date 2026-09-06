# Urban Brawl — City Construction Pipeline

Urban Brawl's public city should look authored even though generic structure is generated. No single addon owns the whole world.

## Resource roles

### CityCrafter 3D — topology authority
Pinned source: `SpartanDavie/CityCrafter3D-Aug2025` commit `04aee37b8d0d8279fbfe0b48d29c5aff7e05992e`
License: MIT

Urban Brawl uses CityCrafter for:
- active block topology
- 1x1 / 2x1 / 1x2 / 2x2 block merging
- compact district distribution
- street seam topology implied by those blocks

Urban Brawl deliberately disables CityCrafter edge mutations/random extensions in the current production seed because they were creating dangling road stubs and implausible perimeter shapes.

Urban Brawl does **not** use CityCrafter's bundled example art, flat road planes, or random building scatter.

The generated city is seeded so the production prototype does not rearrange itself every launch.

### Godot Road Generator — street geometry authority
Pinned release: `TheDuckCow/godot-road-generator 0.9.3`
License: MIT

Road Generator consumes the seams produced by CityCrafter and owns:
- one connected road graph
- native `RoadIntersection` junctions
- road meshes
- lane markings
- collision
- road edge curves
- generated AI traffic lanes

The road network must follow CityCrafter topology. A merged CityCrafter superblock therefore removes its internal street rather than merely hiding a road under a building.

Urban Brawl gives each junction one shared radius and one consistent two-lane cross-section. T-junctions and four-way intersections receive restrained crosswalk/stop-line dressing; perimeter two-arm corners stay visually quieter.

### Quaternius Downtown City MegaKit — presentation authority
License: CC0

Quaternius supplies architecture and street props. Urban Brawl selects different building categories for:
- commercial / downtown blocks
- residential / mixed blocks
- industrial / service blocks
- Police precinct
- Contraband safehouse
- Arms workshop

The runtime catalog weights semantic category matches before generic `building` matches and uses a deterministic shuffled stride rather than walking alphabetically through numbered model families. Adjacent lots should therefore pull a broader visual mix while remaining deterministic.

Quaternius does not decide world topology.

## Urban Brawl-owned layers

### Gameplay spatial layer
Game-specific spatial design remains custom:
- faction territory boundaries
- Police / Contraband / Arms base selection
- public Central Commons
- drug buyer
- gunrunner buyer
- police interdiction target
- FFA activity entrance
- public weapon market
- cops and faction guards
- future heist / event / gang hotspots

These locations are selected from the generated block graph and placed onto valid frontages/plazas rather than maintained as unrelated magic coordinates.

### Authored refinement layer
`CityAuthoredRefinement3D` runs after the generated city exists and performs a deliberately narrow presentation pass.

It may:
- refine **single-building generic blocks** into stronger street-wall/corner compositions
- choose district-aware frontage instead of making every building point at world origin
- offset a single building laterally when the lot has room
- add a small entrance apron connecting building and sidewalk
- add restrained residential/commercial/industrial lot character
- add driveway cuts to selected service lots
- add sparse courtyard/service props to multi-building blocks
- add subtle faction-frontage identity props
- realign public objectives and their nearby guard when a single-building frontage changes

It must **not**:
- move faction HQ buildings
- move Central Commons kiosks
- rewrite long-block/superblock compositions
- change the road graph
- own gameplay territory/state
- add presentation collision that can snag the player

This separation lets us keep deslopifying presentation without destabilizing topology or gameplay.

## Current block language

CityCrafter starts from a compact deterministic **6x6** on-foot neighborhood grid and may merge cells into larger blocks.

Urban Brawl interprets the resulting footprints as:
- **normal block** — one primary building with a real setback and authored refinement pass
- **long block** — two or three aligned frontage buildings plus rear service access
- **superblock** — four perimeter buildings around an interior courtyard
- **industrial block** — lower/larger architecture with service or loading space
- **Central Commons** — mostly open pedestrian plaza with small kiosks, trees and bollards
- **faction HQ block** — one dominant building, readable forecourt, compact rear parking/service area

Ground treatment is also layered rather than one giant slab:
- recessed lot interior
- sidewalk perimeter strips
- curbs with corner clearance
- parking/loading pockets where appropriate
- service lanes on selected long/superblocks

## Deslop rules

1. Roads define blocks before buildings are placed.
2. No gameplay interaction should sit in a traffic lane.
3. Buildings align to a block footprint and cardinal street frontage.
4. Multi-size blocks must remove internal streets physically, not cosmetically.
5. Faction identity should come from architecture/NPC activity/signage/props, not giant colored ground planes.
6. Central public space should remain legible and less dense than faction neighborhoods.
7. Props decorate leftover pedestrian/service space; they do not determine layout.
8. Keep one primary city art family instead of mixing unrelated packs.
9. Generated topology is deterministic until we deliberately add multiple city seeds.
10. A refinement layer may move presentation, but gameplay objectives tied to that presentation must move with it.
11. Avoid uniform radial frontage; street hierarchy and district logic should determine where buildings address the street.
12. Networking/streaming must later attach to stable district/block IDs rather than regenerate a different map per client.

## Next refinement layer

After runtime validation of the current authored pass:
1. inspect Quaternius car/tree/planter scaling and prune bad fuzzy matches
2. add cleaner driveway/curb-ramp geometry where the current overlay treatment still reads flat
3. add addressable storefront/door anchors instead of assuming the center of a building facade is the entrance
4. add ambient pedestrians using the existing character stack
5. add light traffic using existing `city_traffic_lane` curves
6. add block-address / district IDs for multiplayer world events and persistence
7. profile the generated city before deciding whether Static Mesh Merger or streaming is actually needed
