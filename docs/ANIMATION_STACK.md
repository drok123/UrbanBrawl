# Urban Brawl — Animation Stack

## Preferred long-term library: Quaternius Universal Animation Library 1 + 2

License: CC0

Use these as the primary animation source once the standard packs are imported into the project.

Why:
- 250+ combined humanoid animations
- 8-direction locomotion
- unarmed combat
- armed melee combat and multi-hit combos
- one- and two-handed gun animation coverage
- dodge / parkour / movement actions
- hit / death / interaction coverage
- root-motion and non-root-motion exports
- explicitly built for humanoid retargeting and tested with Godot

Urban Brawl should prefer the non-root-motion exports for normal player locomotion because CharacterBody3D remains authoritative over movement and collision. Root motion can still be evaluated for bespoke takedowns, executions or scripted heist moments later.

## Automated prototype rig: KayKit Character Pack — Adventurers

Repository: `KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0`
Pinned commit: `672074b73ba276876a19e8816ecdc5241817ab47`
License: CC0

The dependency installer copies the GLTF character set into:

`res://assets/third_party/kaykit_adventurers/`

The combat lab currently loads `Barbarian.glb` as the player visual. Collision and combat remain owned by the existing CharacterBody3D; the imported rig is presentation only.

Useful built-in animation names include:
- `Idle`
- `Walking_A`
- `Running_A`
- `Dodge_Forward`, `Dodge_Backward`, `Dodge_Left`, `Dodge_Right`
- `Hit_A`, `Hit_B`
- `Death_A`, `Death_B`
- `Unarmed_Idle`
- `Unarmed_Melee_Attack_Punch_A`
- `Unarmed_Melee_Attack_Punch_B`
- `Unarmed_Melee_Attack_Kick`
- `2H_Melee_Idle`
- `2H_Melee_Attack_Chop`
- `2H_Melee_Attack_Slice`
- `2H_Melee_Attack_Stab`
- `2H_Melee_Attack_Spin`
- `1H_Ranged_Aiming`, `1H_Ranged_Shoot`, `1H_Ranged_Reload`
- `2H_Ranged_Aiming`, `2H_Ranged_Shoot`, `2H_Ranged_Reload`

## Runtime architecture

`scripts/animation/combat_animation_driver_3d.gd` is deliberately library-agnostic.

It:
1. loads the configured humanoid scene at runtime;
2. finds its AnimationPlayer automatically;
3. hides the graybox capsule only after a valid rig loads;
4. maps Urban Brawl combat states to animation aliases;
5. falls back through aliases when a library uses different clip names.

The combat controller stays authoritative over:
- movement
- collision
- attack timing
- active hit windows
- hitstop
- damage
- cooldowns

Animations are presentation and should follow combat timing, never redefine it.

## Retargeting rule

Use Godot's humanoid SkeletonProfile / BoneMap retargeting for final character models. We should be able to change the visual character or animation library without rewriting player combat.

## Next animation work

- validate KayKit scale / facing in the combat lab
- tune blend times
- synchronize attack playback speed to CombatAbility timing
- attach held weapons to hand bones instead of the current procedural offset
- add bot animation driver
- import Quaternius UAL 1 + 2 and map the best Urban Brawl clips
- later add ragdoll handoff and dismemberment-compatible skeleton setup
