# Urban Brawl — Animation Stack

## Current prototype visual

Urban Brawl currently uses a native procedural humanoid generated from Godot primitive meshes.

This remains useful as:
- a zero-dependency fallback/debug character
- a headless/server-safe stand-in
- a way to validate combat logic without waiting on imported art

It is **not** the preferred final presentation path.

The old KayKit Rogue/Barbarian experiment is retired and should not be treated as an active dependency or target rig.

## Preferred production character family: Quaternius Universal Base Characters

License: CC0

Why:
- neutral humanoid base rather than fantasy-specific baked gear
- male/female regular, superhero and teen proportions
- animation-friendly topology
- humanoid rig
- hairstyle variation
- explicitly compatible with the Universal Animation Library
- glTF/FBX exports suitable for Godot

The visible player, cops, guards and civilians should migrate to this rig family before bespoke final character art is considered.

The combat controller remains authoritative; imported characters are presentation.

## Preferred animation library: Quaternius Universal Animation Library 1 + 2

License: CC0

Use these as the primary animation source.

Combined they provide more than 250 humanoid animations covering:
- 8-direction locomotion
- idle / walk / jog / sprint
- unarmed combat
- armed melee combat and multi-hit combos
- one- and two-handed gun actions
- dodge / parkour / movement actions
- hit reactions
- death/down actions
- interactions and miscellaneous movement

2026 updates added/fixed root-motion exports and synchronized 8-direction locomotion. Godot-specific exports are provided and the rigs are designed for retargeting.

### Movement authority rule

Prefer non-root-motion locomotion for ordinary gameplay.

`CharacterBody3D` remains authoritative over:
- movement
- collision
- knockback
- dash motion
- combat displacement

Root motion may be used later for tightly controlled bespoke actions such as takedowns, executions or scripted heist moments.

## Hit reaction architecture

The current `HitReactionController3D` balance/stumble/fallback system is part of Urban Brawl's combat feel and should remain.

When production skeletons replace the procedural mannequin, migrate the visual reaction layer from primitive-node pivots to an additive skeleton/AnimationTree layer.

The decision logic remains custom:
- recoil vs stumble vs fallback probability
- hidden balance accumulation/decay
- force/damage influence
- randomized reaction variant
- physical shove direction and magnitude

Imported animation clips can improve the presentation of those decisions without owning them.

## Runtime architecture target

Combat gameplay should expose clean presentation state:

```text
movement state
combat phase
current ability / weapon style
hit-reaction request
fall/down/death state
```

The character presentation layer should combine:
1. locomotion base animation
2. attack/action animation
3. additive hit/recoil layer
4. optional aim/upper-body layer
5. death/ragdoll handoff

Animations follow gameplay timing; they do not redefine hit windows or damage.

## Retargeting rule

Use Godot humanoid retargeting (`SkeletonProfileHumanoid` / BoneMap import configuration) so the gameplay layer is not tied to one mesh.

The same Urban Brawl combat state should be able to drive:
- Quaternius base characters
- later custom faction outfits
- civilian variants
- future higher-detail replacement characters

without controller rewrites.

## Weapon attachment rule

Move from the current procedural hand anchor to skeleton hand-bone attachments when the production rig lands.

Weapon ownership remains in the gameplay/inventory layer. The visual attachment is only presentation.

## Near-term migration order

1. import one Quaternius Universal Base Character as the reference rig
2. import a narrow UAL locomotion subset
3. prove Godot retargeting and 8-direction movement
4. map unarmed/basic melee/pistol actions
5. attach held weapons to hand bones
6. migrate the current hit-reaction system to additive skeleton presentation
7. replace player, bot, cop and territory-guard visuals through the same shared presenter
8. expand animation coverage only after the shared pipeline is stable

The goal is **one production character/animation pipeline**, not bespoke animation code per actor type.
