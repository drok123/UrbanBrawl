# Urban Brawl — Game Vision

Urban Brawl is a top-down 3D urban crime brawler built around a physical hideout, street economy, gangs, faction conflict and high-stakes combat activities.

The current combat lab is the **unarmed baseline**. Weapons, contraband, faction bonuses and persistent loot layer on top of that foundation.

## Core world loop

```text
HIDEOUT
  -> gear / stash / upgrades / gang / passive operations
  -> walk into street district
  -> buy, steal, craft or find weapons / contraband
  -> enter activities, fights, robberies and matches
  -> survive / win / extract value
  -> return to hideout
  -> invest, trade, craft, expand, risk a raid
```

The hideout replaces conventional menus wherever practical.

## Hideout

The hideout is the player's persistent home, lobby and progression space.

Possible rooms / upgrades:
- weapon stash / armory
- workbench / weapon crafting
- grow room
- chemistry / processing room
- cash storage / laundering operation
- planning table
- gang party area
- trophy wall
- black-market storage
- defensive upgrades

Illegal operations generate passive income or resources but increase exposure / heat and create meaningful raid risk.

## Open-ish world

Use compact connected urban districts rather than a giant empty open world.

Street features:
- weapon dealers instead of menu vendors
- drug / contraband dealers
- faction-controlled blocks
- public fights and emergent encounters
- activity entrances
- heist staging areas
- safehouses / hideouts
- police patrol / response zones
- player and NPC trading locations

The city should feel like a navigable game interface.

## Free-for-all weapon scramble

Players spawn unarmed into an arena / district with weapons scattered in-world.

- bats
- knives
- cleavers
- pipes
- hammers
- pistols / shotguns / improvised firearms
- other urban junk weapons

Weapons roll rarity and affixes.

Players fight, steal dropped weapons and eliminate each other. The winner can extract selected surviving loot back to the hideout.

## Heists / robberies

Heists use the same combat engine but become objective modes.

Example bank robbery:
- gang attackers vs defenders / police
- breach / objective phase
- secure cash or valuables
- escape / extraction phase
- carried loot creates risk
- winner / survivor payout feeds the persistent economy

This can support 5v5 or other team sizes without creating a second combat game.

## Gangs

Gangs replace conventional clans.

Gang systems can include:
- shared identity / colors / emblem
- gang hideout access
- group matchmaking
- territory influence
- crafting specialization
- shared operations
- rivalries
- seasonal / district competition

## Factions

Faction identity should create economic specialization rather than simple stat superiority.

Possible structure:

### Arms-focused faction
Bonuses to:
- weapon crafting
- repair / durability
- ammo production
- weapon quality / reroll efficiency

### Contraband-focused faction
Bonuses to:
- drug / consumable production
- grow operations
- processing yield
- buff duration / quality
- smuggling / laundering

### Police faction
Bonuses to:
- lawful equipment access
- intel / tracking
- raids / seizures
- defensive response

Police should not be able to endlessly delete player inventories. Raids need cooldowns, evidence / warrant requirements, protection windows and capped confiscation.

## Drug / consumable gameplay

Consumables can create meaningful short-term bonuses with tradeoffs.

Examples:
- pain suppression
- movement / stamina boost
- attack-speed increase
- reduced hitstun
- temporary damage resistance
- focus / accuracy effects

Balance them with costs such as duration, crash / debuff, tolerance, price, rarity or increased heat.

The system exists to create economy demand and combat decisions, not just permanent stat inflation.

## Economy

Target: an Albion-like player-driven economy where useful goods are produced, traded, consumed and destroyed.

### Sources
- heists
- matches
- passive hideout operations
- crafting
- scavenging
- faction production
- world activities

### Sinks
- weapon loss / confiscation
- durability / repair
- ammunition
- consumable use
- crafting inputs
- hideout upgrades
- vendor taxes / market fees
- failed heists
- raid losses

### Anti-crash rules
The economy needs controlled destruction of value.

Police raids are one sink, but should be bounded:
- evidence / heat threshold
- raid cooldown per target
- limited confiscation percentage
- protected core slots / minimum retained value
- diminishing returns for repeated raids
- faction-wide or district-wide raid budget

This prevents police players from spam-clearing inventories while still removing enough goods to fight inflation.

## Heat / evidence

Criminal activity generates heat.

Heat can influence:
- NPC police response
- raid eligibility
- dealer availability
- laundering costs
- hideout vulnerability
- rewards for high-risk activities

Evidence can be a second, slower meter used specifically for player-police raids so raids require actual buildup rather than random griefing.

## Violence / presentation

Target tone: gritty, bloody, exaggerated urban violence.

Later systems:
- blood decals and pools
- localized hit reactions
- limb dismemberment
- weapon-specific wounds
- gibs on extreme impact
- persistent arena aftermath under a performance budget

Gore is driven by CombatHit data: weapon, damage type, hit location, impulse and gore power.

## Development strategy

Build in large vertical slices rather than isolated micro-features.

### Slice 1 — Combat + weapons
- unarmed combat
- world weapon pickup / drop
- bat / knife / firearm examples
- rarity / affixes
- opponent weapon seeking

### Slice 2 — Hideout + street
- minimal hideout
- one connected street district
- dealer NPC
- stash
- one passive operation (grow room)
- one activity entrance

### Slice 3 — Economy + heat
- cash / item value
- vendor transactions
- production timer
- heat / evidence
- one police seizure path
- item destruction / economy sinks

### Slice 4 — Heist
- bank robbery objective flow
- loot carrying
- extraction
- payout
- return to hideout

### Slice 5 — Multiplayer / gangs
- party formation in hideout
- gang identity
- replicated combat / items
- matchmaking / activity transitions

Polish, art replacement and deeper content come after these loops work.
