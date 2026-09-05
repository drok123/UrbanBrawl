# Urban Brawl — MMO-style World Architecture

Urban Brawl should feel socially persistent and territory-driven before it becomes technically massive.

## Current world shape

The prototype now uses one public semi-open city scene:

`res://scenes/world/city_world.tscn`

The city is divided into four logical regions:

- Central Commons — neutral public space and activity access.
- Police District — public police territory, beat cops, drug-sale risk and the police precinct exterior.
- Contraband District — public contraband territory, faction enforcers and illegal arms-sale opportunity.
- Arms District — public arms territory, faction enforcers and police interdiction opportunity.

Players walk between these territories instead of loading separate street-block scenes.

## Private faction homes

Each faction owns a separate interior scene.

### Police

`res://scenes/world/police_precinct.tscn`

Contains:
- case board
- warrant desk
- raid launch board
- police-specific progression infrastructure

Only Police characters receive the precinct entrance marker and interaction in the public city.

### Contraband

`res://scenes/world/contraband_safehouse.tscn`

Contains:
- stash
- grow operation
- future chemistry / packaging / laundering systems

Only Contraband characters receive the safehouse entrance marker and interaction.

### Arms

`res://scenes/world/arms_workshop.tscn`

Contains:
- stash
- discounted prototype weapon benches
- future crafting / repair / modification systems

Only Arms characters receive the workshop entrance marker and interaction.

## Character identity

The project now boots through:

`res://scenes/ui/character_creation.tscn`

Prototype identity state includes:
- character name
- faction
- body color
- accent color

The procedural player humanoid reads the saved session colors.

Later character identity should expand without changing combat code:
- face / head variant
- hair
- clothes
- faction cosmetics
- armor
- gang emblem
- persistent character ID

## MMO-ish design rule

The world should use MMO principles where they improve gameplay without forcing MMO scale.

Prioritize:
- a shared public city
- persistent character identity
- faction territory
- public economic hotspots
- visible risk / flagging
- faction-only social hubs
- repeatable activities
- item loss and extraction
- persistent economy state
- world events and patrols
- instanced high-intensity activities

Do not prioritize a gigantic empty map.

## Public world versus instances

The public city owns:
- travel
- faction contact
- trade
- street crime
- patrols
- pursuit
- economic setup
- social presence
- entrances to activities

Instances own:
- FFA
- heists
- raids
- high-density combat
- future dungeons / special events

This lets the public world remain readable while combat instances can be much denser and more destructive.

## Streaming strategy

The first city is intentionally compact and loads as one scene.

Districts are treated as logical chunks now so later streaming can replace the loading layer without replacing gameplay rules.

Do not adopt an open-world streaming plugin until the authored city is large enough that editor/runtime node count actually becomes a problem. At that point evaluate maintained Godot chunk-streaming solutions against the current engine version and multiplayer requirements.

## Multiplayer migration seam

Gameplay state should remain split into:

### Character/session state
- identity
- faction
- inventory
- cash
- heat
- evidence
- flags
- progression

### Public-world state
- district ownership
- NPC population
- public pickups
- buyers / vendors
- world events
- active patrols

### Instance state
- participants
- activity rules
- temporary weapons
- win/loss result
- extraction payload

The single-player prototype may keep this state locally, but systems should communicate through stable events and IDs rather than directly depending on one scene tree layout.

## Networking order

When actual multiplayer starts:

1. network player movement / combat state
2. authoritative combat hits
3. replicated pickups and dropped weapons
4. shared district NPCs
5. public crime / duty events
6. party / group state
7. activity matchmaking and instance handoff
8. persistence service for characters / economy

Do not begin with full persistent-server infrastructure before the city loop is fun offline.

## Immediate next world work

1. validate the character creation -> city -> faction home loop
2. add transient territory-entry banners rather than permanent HUD clutter
3. add ambient civilian population and faction-neutral street NPCs
4. create faction-safe spawn rules
5. add public extraction / death-loss rules
6. add a map/minimap after city geography stabilizes
7. replace graybox city blocks with modular urban kits
8. later evaluate chunk streaming when profiling proves it is necessary
