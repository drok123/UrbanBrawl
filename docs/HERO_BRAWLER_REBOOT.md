# Urban Brawl: combat-first reboot

The default boot path is now a self-contained rooftop hero-brawler prototype. The old city/MMO-era scenes and scripts are intentionally left in the repository for reference, but they are no longer autoloaded or used by the main scene.

## Playtest loop

Three chunky procedural humanoids fight in a small rooftop arena. The player can switch live between three hero mechanics:

- **BRICK** — 125 HP. `E` braces the next hit, heavily reducing knockback and storing some of that force for the next heavy.
- **SPRING** — 92 HP. Faster movement and dash; wall contact during a dash refreshes the dash and ricochets the character.
- **VICE** — 108 HP. Strong throws; `E` arms a long-range, high-force empowered grab.

## Controls

- `WASD` move
- mouse aims independently of movement
- `LMB` or `J` quick attack
- `RMB` or `K` heavy attack
- `F` or `L` grab / throw
- `Space` dash / attack cancel
- `E` hero mechanic
- `1`, `2`, `3` switch BRICK / SPRING / VICE
- `R` reset the brawl

## Combat experiments included

- short attack startup and input buffering
- dash canceling
- directional knockback
- wall splat bonus damage
- local hit-stop and camera impact
- rooftop ring-outs with fast respawn
- lightweight FFA bots
- dynamic orthographic arena camera
- simple low-detail procedural humanoids and rooftop props; no third-party character pack required

This is intentionally a feel prototype. Progression, inventory, factions, MMO world systems, vendors, and character creation are not part of the active play path.
