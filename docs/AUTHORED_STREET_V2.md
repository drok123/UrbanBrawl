# Urban Brawl — Authored Street V2

This scene is a deliberate visual-direction experiment, not another iteration of the generated city.

Scene:
`res://scenes/world/city_street_v2.tscn`

Runtime builder:
`res://scripts/world/authored_street_v2.gd`

## Why it exists

The previous public-city experiments accumulated a procedural visual fingerprint even after the road and building resources were technically working. The result did not match the intended Urban Brawl identity.

V2 changes the question from:

> How do we generate a convincing city?

To:

> What does one excellent Urban Brawl street look and play like?

## Rules

- No procedural city topology.
- No Road Generator in this scene.
- No random building placement.
- No post-generation refinement pass.
- Streets use compressed game dimensions rather than literal real-world block dimensions.
- Every building has an explicit gameplay/presentation role and explicit street frontage.
- Alleys, courtyards and service yards are designed as combat spaces first.
- Quaternius provides visual assets, but it does not choose world layout.
- Decorative props are sparse and intentional; there is no scatter system.
- The old `city_world.tscn` remains in the repository untouched as a reference/prototype shell.

## Current composition

The first slice contains:

- one narrow east-west commercial street
- one offset north-south side street
- a civic/Police corner
- a bodega + pawn-shop frontage
- mixed-use / apartment frontage for Contraband
- a diner and residential frontage
- an Arms workshop + warehouse/service edge
- a five-meter alley that opens into a rear fight courtyard
- a separate industrial service yard
- faction entrances, public vendors, buyer/interdiction loops, guards and FFA access

This is intentionally only about a block-and-a-half of world. If the composition does not feel right, we redesign this slice instead of multiplying it into a city.

## Scale language

The street is intentionally compressed for the top-down camera:

- main road: ~8 m wide
- side road: ~7 m wide
- sidewalk: ~2.4 m
- fight alley: ~5.2 m

Those dimensions are not trying to simulate a real Boston/NYC street literally. They are trying to make characters, vehicles, storefronts and combat read well from the gameplay camera.

## Expansion rule

Do not expand V2 into a larger district until the player can stand in the current slice and the scene already feels like Urban Brawl.

If it lands, expansion should happen by authoring adjacent gameplay spaces with distinct identities:

`civic corner -> market strip -> alley court -> apartment court -> underpass -> industrial yard -> faction compound`

The world may still become seamless and MMO-like later, but it should grow from authored spaces rather than from a city generator.
