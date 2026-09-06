# Urban Brawl — City Construction Pipeline

Urban Brawl's public city should look authored even though generic structure is generated. No single addon owns the whole world.

## Resource roles

### CityCrafter 3D — topology authority
Pinned source: `SpartanDavie/CityCrafter3D-Aug2025` commit `04aee37b8d0d8279fbfe0b48d29c5aff7e05992e`
License: MIT

Urban Brawl uses CityCrafter for:
- active block topology
- 1x1 / 2x1 / 1x2 / 2x2 block merging
- city edge variation
- small random edge extensions
- downtown / mixed / outer-service district classification
- street seam topology implied by those blocks

Urban Brawl does **not** use CityCrafter's bundled example art, flat road planes, or random building scatter.

The generated city is seeded so the production prototype does not rearrange itself every launch.

### Godot Road Generator — street geometry authority
Pinned release: `TheDuckCow/godot-road-generator 0.9.3`
License: MIT

Road Generator consumes the seams produced by CityCrafter and owns:
- road meshes
- lane markings
- cross-sections
- collision
- road edge curves
- generated AI traffic lanes

The road network must follow CityCrafter topology. A merged CityCrafter superblock therefore removes its internal street rather than merely hiding a road under a building.

### Quaternius Downtown City MegaKit — presentation authority
License: CC0

Quaternius supplies architecture and street props. Urban Brawl selects different building categories for:
- commercial / downtown blocks
- residential / mixed blocks
- industrial / service blocks
- Police precinct
- Contraband safehouse
- Arms workshop

Quaternius does not decide world topology.

## Urban Brawl-owned layer

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

## Current block language

CityCrafter starts from a compact 5x5 on-foot scale and may merge cells into larger blocks or extend the edge.

Urban Brawl interprets the resulting footprints as:
- **normal block** — one primary building with a real setback
- **long block** — two or three aligned frontage buildings
- **superblock** — four perimeter buildings around an interior courtyard
- **industrial block** — lower, larger building with service space
- **Central Commons** — mostly open pedestrian plaza with small kiosks
- **faction HQ block** — one dominant building pulled back from a readable forecourt

This is intentionally more structured than CityCrafter's default random-position building generation.

## Deslop rules

1. Roads define blocks before buildings are placed.
2. No gameplay interaction should sit in a traffic lane.
3. Buildings align to a block footprint and cardinal street frontage.
4. Multi-size blocks must remove internal streets physically, not cosmetically.
5. Faction identity should come from architecture/NPC activity/signage, not giant colored ground planes.
6. Central public space should remain legible and less dense than faction neighborhoods.
7. Props decorate leftover pedestrian/service space; they do not determine layout.
8. Keep one primary city art family instead of mixing unrelated packs.
9. Generated topology is deterministic until we deliberately add multiple city seeds.
10. Networking/streaming must later attach to stable district/block IDs rather than regenerate a different map per client.

## Next refinement layer

After runtime validation:
1. replace temporary intersection cover geometry with native Road Generator `RoadIntersection` graph nodes
2. create continuous curb/sidewalk edge treatment from road edge curves
3. add alleys/service lanes to selected superblocks
4. add parked cars/loading bays/parking pockets
5. add ambient pedestrians
6. add light traffic using existing `city_traffic_lane` curves
7. add block-address / district IDs for multiplayer world events and persistence
