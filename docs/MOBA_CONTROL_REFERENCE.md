# Urban Brawl — MOBA Control Reference

This decision keeps the combat-feel checklist from drifting between unrelated control models.

## Chosen target

Urban Brawl will use a **Heroes of the Storm-style command model** as its primary control reference:

- right-click issues a ground movement command
- holding right-click continuously updates the destination
- movement follows navigable paths around level geometry
- `S` immediately stops the current movement command
- `A` issues attack-move once basic attacks exist
- `Q`, `W`, `E`, and `R` activate the hero kit
- abilities support quick-cast, cast-on-release, and indicator modes
- directional abilities face the cast direction during their committed phase
- ordinary travel faces the path direction rather than permanently tracking the cursor

## Secondary references

### Albion Online

Borrow:

- clean ground-targeted shape language
- readable cooldown commitment
- deliberate spacing and group-fight clarity
- uncluttered silhouettes at a distant top-down camera

Do not borrow:

- equipment-defined class identity for the initial hero-brawler slice
- MMO progression or gathering systems

### Diablo III

Borrow:

- immediate response to a new ground destination
- attacks cleanly interrupting travel
- aggressive audiovisual confirmation
- dense enemies remaining readable during ability use

Do not borrow:

- loot-driven power as a substitute for hero-kit depth
- screen-filling effects that hide PvP decisions

## Technical references

### Godot NavigationAgent3D

`NavigationAgent3D` supplies a path and the next path position. It does not move the fighter. Urban Brawl's `CharacterBody3D` motor remains authoritative over acceleration, collision, displacement, knockback, and attack movement.

### CAIRNFALL

Borrow its separation of input, simulation, and presentation; its fixed-tick input latch; its simulation-authored impact events; and its data-driven telegraph shapes. Do not borrow its twin-stick control scheme.

### Shotcaller

Borrow only the separation between player orders, path selection, and unit movement. Its current public implementation is a useful architectural example but not a production-quality 3D movement motor for Urban Brawl.

## Rejected as the primary reference

- twin-stick WASD plus permanent mouse-facing, because it produces the current strafing/mannequin feel
- physics-driven character motion, because combat control must remain deterministic and tunable
- the available Godot 3 MOBA prototypes, because their controller and navigation patterns predate the current Godot 4 stack

## Implementation order

1. keep the movement lab and primitive fighter as the baseline
2. separate presentation from gameplay simulation
3. install one production humanoid presenter and locomotion set
4. replace WASD travel with right-click ground commands
5. add stop and attack-move commands
6. add ability targeting modes
7. tune arrival, repathing, collision, turning, and animation against the movement quality gate
