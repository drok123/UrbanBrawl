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

## World architecture rule

The open-ish world does **not** need to contain every gameplay mechanic physically.

Use the street districts for:
- social interaction
- economy
- dealers / vendors
- police patrols
- gang presence
- hideout access
- activity discovery / entrances
- spontaneous fights
- setup and consequences

Use **instanced activities** for mechanics that are more fun when purpose-built:
- FFA arenas
- heist phases
- bank interiors
- raid interiors
- getaway sequences
- vehicle shooting / traffic dodging
- special PvP objectives
- survival / defense encounters

This keeps the world compact while allowing individual activities to have radically different rules, pacing, camera behavior or map design.

## Hideout

The hideout is the player's persistent home, lobby and progression space.

Possible rooms / upgrades:
- weapon stash / armory
- workbench / weapon crafting
- grow room
- chemistry / processing room
- cash storage / laundering operation
- planning table / heist setup room
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

Heists use the same persistent characters, equipment and economy but can be built as a **chain of separate instanced game modes**.

A heist begins in a physical planning / setup room similar in spirit to GTA Online. Players choose or unlock the job, gather the crew, inspect expected rewards / risk and launch the activity from there.

Example bank robbery chain:

```text
HIDEOUT / PLANNING ROOM
        -> SETUP / PREP INSTANCE
        -> ENTRY / BREACH INSTANCE
        -> BANK COMBAT + OBJECTIVE
        -> LOOT / VAULT PHASE
        -> GETAWAY INSTANCE
        -> PAYOUT / CONSEQUENCES
        -> RETURN TO WORLD / HIDEOUT
```

The phases do not need identical mechanics.

Examples:
- setup could be scouting, stealing a vehicle, acquiring tools or intercepting equipment
- breach could be a short combat objective
- vault could be a holdout / timed interaction
- getaway could become a deliberately goofy arcade driving-and-shooting mode with traffic dodging, roadblocks and pursuit
- a different heist could substitute rooftops, trains, sewers, armored cars or boats

The persistent layer carries across all phases:
- selected weapons
- consumables
- health / lives rules where appropriate
- carried loot
- crew identity
- heat / evidence consequences
- payout and item rewards

This lets us make memorable one-off mechanics without forcing them into the open-world simulation.

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

Police players also form persistent crews / organizations that fill the same social role as gangs for party formation, progression and raid teams, while retaining police-specific gameplay and identity.

## Factions

Faction identity should create economic specialization and different gameplay loops rather than simple stat superiority.

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
Police must be a **full playable career**, not a faction that exists only to raid criminal players.

Police activities can include:
- solo beat-cop patrol
- observing / interrupting street transactions
- responding to active fights / robberies
- contraband seizure
- arrest / capture objectives
- pursuit instances
- evidence collection
- warrant progression
- protecting banks / high-value locations
- escort / transport objectives
- gang hideout raids
- defending against criminal heist teams

#### Beat-cop loop

A solo police player should have useful street gameplay without needing a raid party.

Example:

```text
PATROL DISTRICT
   -> notice suspicious player/NPC activity
   -> observe or identify a transaction / crime
   -> commit to intervention
   -> chase / fight / arrest / seize
   -> recover evidence / contraband
   -> gain police progression + district intel
   -> contribute evidence toward larger warrants
```

The design goal is cat-and-mouse gameplay, not automatic punishment. Police should have to identify, catch and physically win interactions rather than simply press a confiscate button.

#### Hideout raids

Police crews are the player-controlled **raid parties** for criminal hideouts.

Raid eligibility should come from systemic buildup:

```text
criminal activity
      -> HEAT
      -> EVIDENCE
      -> WARRANT / RAID ELIGIBILITY
      -> POLICE CREW FORMS RAID PARTY
      -> INSTANCED HIDEOUT RAID
      -> CAPPED SEIZURE / DESTRUCTION
      -> COOLDOWN + CONSEQUENCES
```

Hideout raids should be actual objective combat, not inventory deletion through UI.

Potential attacker goals:
- breach defenses
- secure evidence rooms
- seize exposed contraband
- destroy illegal production equipment
- capture high-value targets / objectives

Potential defender goals:
- hold rooms / chokepoints
- move or protect exposed inventory
- destroy evidence
- survive until raid timer expires
- use hideout upgrades / traps / defenses

Police should not be able to endlessly delete inventories. Raids need cooldowns, evidence / warrant requirements, protected value, protection windows and capped confiscation.

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
- police seizures / evidence destruction

### Anti-crash rules
The economy needs controlled destruction of value.

Police raids are one sink, but should be bounded:
- evidence / heat threshold
- raid cooldown per target
- limited confiscation percentage
- protected core slots / minimum retained value
- diminishing returns for repeated raids
- faction-wide or district-wide raid budget

Some seized items can be destroyed / removed from circulation rather than all being transferred to police players. This creates a controllable item sink and reduces incentives for raid farming.

## Heat / evidence

Criminal activity generates heat.

Heat can influence:
- NPC police response
- player-police attention
- raid eligibility
- dealer availability
- laundering costs
- hideout vulnerability
- rewards for high-risk activities

Evidence can be a second, slower meter used specifically for player-police warrants and raids so raids require actual buildup rather than random griefing.

Beat-cop actions, recovered contraband and successful police activities can contribute to evidence progression.

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

Build in large vertical slices rather than isolated micro-features. Placeholder art is acceptable whenever it gets a complete playable loop running sooner.

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

### Slice 3 — Activity framework + economy
- generic world entrance -> instance -> result -> world return pipeline
- cash / item value
- vendor transactions
- persistent carried rewards
- production timer
- basic heat

This reusable activity router is important because FFA, heists, raids and pursuits all use the same transition architecture.

### Slice 4 — FFA + police beat loop
- FFA weapon scramble
- reward extraction
- police patrol role
- one observable street transaction
- intervention / chase / seizure outcome
- evidence progression

This tests both criminal and police careers before either becomes content-heavy.

### Slice 5 — First heist
- planning room
- one setup phase
- bank combat objective
- carried loot
- arcade getaway instance
- payout / heat consequence
- return to hideout

### Slice 6 — Hideout raid
- warrant / eligibility
- police raid party
- instanced hideout combat
- attacker / defender objectives
- capped exposed-stash seizure
- raid cooldown

### Slice 7 — Multiplayer / gangs / economy expansion
- party formation in hideout
- gang / police-crew identity
- replicated combat / items
- matchmaking / activity transitions
- player trading / market foundation
- faction production specializations

Polish, art replacement, deeper economy balancing and additional content come after these loops work.
