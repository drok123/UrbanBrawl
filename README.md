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
- procedural humanoids and graybox city art as guaranteed fallbacks

## First-time setup

Urban Brawl deliberately uses mature external systems for solved infrastructure instead of rebuilding everything ourselves.

1. Install the current stable Godot 4 release.
2. Clone/pull this repository.
3. Double-click **`INSTALL-DEPENDENCIES.bat`** after a fresh clone (and whenever pinned code dependencies change).
4. That installer fetches:
   - `Oen44/Godot-Inventory @ v4.0.1a` for inventory/itemization/equipment/affixes.
   - `bitbrain/beehave @ v2.9.3` for behavior-tree AI.
5. For the polished visual prototype, double-click **`INSTALL-VISUAL-PACKS.bat`**.
6. The visual installer opens the official Quaternius pages if the Standard/free ZIPs are not already in your Windows Downloads folder. Download the free versions of:
   - Downtown City MegaKit
   - Universal Base Characters
   - Universal Animation Library
   - Universal Animation Library 2
7. Return to the installer and press Enter. It detects the ZIPs, installs the glTF city/character assets, and copies only a focused GLB animation subset from UAL 1 + 2.
8. Restart/reopen Godot and allow the new 3D assets to import.
9. Open `project.godot` and press Play.

The Quaternius packs are CC0 and are intentionally installed locally rather than committed as large binary dependencies. If they are missing or fail validation, Urban Brawl automatically keeps the procedural humanoid and graybox building fallbacks.

## Current visual replacement proof

The first controlled replacement wave intentionally changes only two things:

- **PoliceBlockA** in the public city prefers a Downtown City MegaKit building and automatically fits it to the existing gameplay footprint/collision.
- **Player presentation** prefers a Universal Base Character and runtime-retargeted Universal Animation Library clips. CharacterBody3D still owns collision/movement/combat timing; imported animation is presentation only.

Once this one-block / one-character proof survives runtime testing, the same bridge can expand across the rest of the city and NPC roster without changing gameplay systems.

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

Use external systems for better art, animation, cameras, UI, sound, physics helpers, generic AI plumbing, persistence and networking foundations when they are demonstrably stronger.

See:
- `docs/RESOURCE_REPLACEMENT_AUDIT_2026-09.md`
- `docs/RESOURCE_STACK.md`
- `docs/MMO_WORLD_ARCHITECTURE.md`
- `docs/FACTION_CONFLICT.md`
- `docs/COMBAT_REFERENCES.md`
