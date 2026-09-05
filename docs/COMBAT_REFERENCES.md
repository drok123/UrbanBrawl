# Combat engineering references

Urban Brawl's combat should use proven Godot patterns where they fit, but avoid importing large frameworks until the game actually needs them.

## 1. GDQuest Godot 4 3D controller

Repository: `gdquest-demos/godot-4-3d-third-person-controller`

Useful patterns:

- Melee contact is represented by a real `Area3D` attached to the character.
- The melee area is enabled only while the attack is active, then disabled again.
- Attack timing and character movement are intentionally coupled to the attack animation window instead of treating damage as an instantaneous button event.
- Movement, combat, character visuals, and camera responsibilities are kept as separate pieces.

License note: GDQuest states that its source scripts/scenes/shaders are MIT licensed. Its art assets use a different non-commercial Creative Commons license, so Urban Brawl should learn from/use source patterns only unless an asset is separately cleared.

Urban Brawl adoption:

- `MeleeHitbox3D` is an `Area3D` with explicit active/inactive windows.
- Combat now uses windup -> active -> recovery phases.
- We are not importing GDQuest art or copying its whole controller.

## 2. GDAbilitySystem (kibble-cabal)

Repository: `kibble-cabal/ability-system`

Useful patterns:

- Abilities are definitions owned by an ability system rather than giant branches inside the player controller.
- Attributes, effects, tags, and ability events are separate concepts.
- Tags can express state such as casting, cooldown, stunned, dead, etc.

Urban Brawl adoption:

- Ability tuning lives in `CombatAbility` resources (`resources/abilities/`).
- We are keeping the implementation lightweight for now instead of adding a GDExtension dependency.
- If hero interactions become complex, a tag/status layer is the next logical escalation.

## 3. OctoD godot-gameplay-systems

Repository: `OctoD/godot-gameplay-systems`

Useful patterns:

- An `Ability` resource describes activation behavior.
- An `AbilityContainer` owns/grants abilities.
- Tags describe activation requirements, blocks, cancellation, cooldown state, and other gameplay conditions.
- Signals decouple ability execution from other systems.

Urban Brawl adoption:

- Ability resources are data, not duplicated constants.
- The reusable hitbox emits a `hit_landed` signal; the player decides what juice/feedback to apply.
- We should add explicit gameplay tags/status rules once multiple heroes can stun, root, silence, shield, interrupt, etc.

## 4. CAIRNFALL (top-down Godot 4 action RPG)

Repository: `euuuuuuuan/cairnfall-public`

Useful patterns:

- Mouse aim is projected onto the ground plane before gameplay logic uses it.
- Telegraph shape, telegraph lifetime, and hit resolution are separate concepts.
- Combat content is data-driven rather than encoded as one-off boss/skill scripts.
- A fixed 60 Hz simulation, deterministic input latch, and automated combat soaks are used for reliability.
- Source is Apache-2.0; media has separate licensing/provenance rules.

Urban Brawl adoption now:

- We already use mouse-to-ground aim.
- Ability telegraphs are generated from ability data.
- Hit resolution is separate from the telegraph visual.
- Ability timings and geometry are data resources.

Potential later adoption:

- Input buffering/latching if PvP/networking becomes a goal.
- Fixed-tick combat tests and soak bots once the first full hero kit exists.
- Separate simulation/view layers if multiplayer or replay/determinism demands it.

## Current design rule

Do not add complexity only because another project has it. Borrow the smallest proven pattern that solves a real Urban Brawl problem.

Current combat stack:

`input -> CombatAbility resource -> windup -> active hitbox -> hit signal -> damage/knockback/status -> recovery -> cooldown`

This keeps the prototype fast while giving us a path to hero-scale combat without rewriting the foundation later.
