# Urban Brawl — Resource Replacement Audit (September 2026)

Goal: replace prototype presentation and solved generic infrastructure before it hardens into the product. Keep Urban Brawl-specific gameplay systems custom.

## Decision summary

### Replace / adopt now

#### 1. Quaternius Downtown City MegaKit — primary city environment art
License: CC0
Current pack: May 2026

Why:
- 300+ modular Boston/NYC-style building and street pieces
- free Standard pack contains the majority of the kit
- glTF/FBX assets work directly with Godot
- prebuilt example buildings provide a coherent visual language
- Source version demonstrates Godot-specific shaders/collisions, but the free Standard models are sufficient to begin replacement

Replace:
- procedural BoxMesh city buildings
- plain colored district slabs as the visible environment
- most placeholder street architecture

Keep:
- Urban Brawl district boundaries, territory IDs, spawn points and interaction locations

Rule: use this as the **primary environment language**. Do not mix several unrelated city kits indiscriminately.

#### 2. Godot Asset Placer 1.6.0 — environment authoring workflow
License: MIT
Godot: 4.3+
Current release: August 25, 2026

Why:
- editor-only; no runtime dependency risk
- placement collections
- surface/plane placement
- random asset placement and randomized transforms
- supports GLB/GLTF/OBJ/FBX/Blend/TSCN

Use it to populate the city with modular buildings, trash, barriers, props, signs and furniture instead of creating placement code for static art.

#### 3. Quaternius Universal Base Characters — visible humanoids
License: CC0
Current pack: August 2025

Why:
- neutral humanoid base rather than fantasy-specific characters
- regular/superhero/teen male and female proportions
- animation-friendly topology (~13k triangles average)
- 20 hairstyles
- humanoid rig
- explicitly compatible with Quaternius Universal Animation Library

Replace:
- the procedural chunky mannequin as the normal visible player/NPC body

Keep procedural humanoid only as:
- fallback/debug visual
- server/headless-safe placeholder
- emergency animation-import fallback

#### 4. Quaternius Universal Animation Library 1 + 2 — character animation source
License: CC0
UAL1: 120+ clips
UAL2: 130+ clips
2026 updates include synchronized 8-direction locomotion and root-motion exports; UAL2 includes melee combos, armed combat and parkour. Both provide Godot-tested exports.

Replace most handcrafted presentation poses with imported clips for:
- idle / walk / jog / sprint
- 8-direction locomotion
- unarmed combat
- bat / melee combat
- pistol aim / fire / reload
- hit reactions
- dodge / movement actions
- death / down animations

Urban Brawl remains authoritative over:
- attack timing
- hit windows
- movement/collision
- damage
- balance/stumble probability

The existing hit-reaction/balance system should become an **additive procedural layer** over the imported skeleton rather than being deleted.

#### 5. Phantom Camera — replace simple follow-camera script
License: MIT
Godot: 4.4+
Current Asset Store update: July 19, 2026

Why:
- mature Cinemachine-style camera system
- 2D/3D support
- established community usage
- removes the need to keep growing `top_down_camera.gd` into a homebrew camera framework

Use for:
- normal top-down follow
- combat framing
- activity cameras
- heist/set-piece camera transitions
- camera shake/offset behavior through one coherent camera layer

#### 6. Built-in Jolt Physics — explicitly evaluate/pin
Official Godot engine system.
Godot 4.6+ uses Jolt by default for new 3D projects; Godot 4.7 documentation describes it as the normal built-in 3D physics option.

Why:
- generally faster and more reliable than GodotPhysics3D
- built into the engine; no external addon required
- good fit for physical weapons, ragdolls, bodies, props and future vehicles

Action:
- explicitly smoke-test Urban Brawl under Jolt
- if clean, pin `physics/3d/physics_engine` to `Jolt Physics` rather than relying on inherited/default behavior

Do not enable experimental separate-thread physics yet.

#### 7. Kenney UI Pack + Input Prompts — clean UI presentation
License: CC0

UI Pack:
- 430+ UI elements

Input Prompts:
- 1,500+ keyboard/mouse/gamepad/touch glyphs
- current 1.5 line includes updated vector/font assets

Replace:
- plain `F  INTERACT` text presentation
- prototype button/panel styling on character creation/settings
- manually typed key labels where an icon is clearer

Keep the HUD intentionally minimal.

#### 8. Kenney Impact Sounds + Interface Sounds — baseline audio polish
License: CC0
Impact Sounds: 130 files
Interface Sounds: 100 files

Use as a clean baseline for:
- punch/bat/body impacts
- UI click/confirm/cancel
- pickups/interactions

Do not force them as final sound design; they are a much better placeholder layer than silence/reused generic sounds.

### Adopt immediately after the first visual swap

#### 9. Maaack's Options Menus / Menus Template
License: MIT
Current Godot 4.7-compatible release line: September 2026

Why:
- persistent display/audio/input settings
- fullscreen handling
- pause/options menus
- gamepad support
- multiple resolutions

This should replace our improvised fullscreen toggle and prevent basic product settings from becoming another custom subsystem.

Prefer the **Options Menus addon** or Menus Template addon for integration into the existing project rather than replacing the whole project template.

#### 10. Static Mesh Merger 1.0.1
License: MIT
Current release: August 26, 2026

Use only after modular city art is placed.

Why:
- merges static MeshInstance3D geometry
- preserves materials/textures
- preserves existing collision hierarchy
- editor-side optimization with no runtime framework

Good candidate for completed city blocks that no longer need every modular wall/window object to remain independent.

#### 11. ProtonScatter 4.1
License: MIT

Use for non-destructive environmental dressing:
- trash/clutter
- weeds
- small props
- debris
- repeated environmental detail

Do not use it for gameplay-critical interactables.

#### 12. Coding Creature City Props Kit 1
License: CC0
Free pack: 130+ urban props, GLB/FBX/OBJ

Evaluate visually beside the Quaternius Downtown kit. Adopt only props that match the primary art direction closely enough; avoid asset-pack collage syndrome.

### Reference / transplant, not wholesale replacement

#### 13. 3D Multiplayer Template v2.0.0
License: MIT
Godot 4.7 starter template; released September 2, 2026.

Useful solved pieces:
- synchronized movement/animation
- player skins/name tags
- global chat/player list
- server-authoritative inventory
- synchronized equipment
- physics world items
- headless dedicated-server support

Do **not** replace Urban Brawl with the template. Transplant/reference its networking patterns when replication begins.

#### 14. Talo Game Services 1.0.0
License: MIT
Godot 4.6+

Useful later for:
- authentication
- persistent player data
- presence
- friends/relationships
- analytics
- leaderboards
- cloud configuration

Do not make Talo P2P the authority for the core Urban Brawl economy. Long-term item/economy state needs authoritative server ownership.

### Evaluate later; do not replace working systems yet

#### LimboAI 1.8.x
License: MIT
Godot 4.6+ GDExtension / Godot 4.7 module support.

It is objectively richer than Beehave in several areas:
- behavior trees + hierarchical state machines
- C++ implementation
- visual debugger/editor
- substantial built-in task system

But Beehave is already integrated and working, is pure GDScript, and is not currently the source of visible sloppiness.

Verdict: **keep Beehave now**. Re-evaluate LimboAI when NPC behavior complexity or NPC count makes the migration worthwhile.

#### Open-world streaming addons
Still do not adopt yet. The current city should first use coherent modular scenes, LOD/visibility/occlusion and sensible static batching. Add streaming only when actual profiling proves it is needed.

## Keep custom — these systems are Urban Brawl

Do not replace these simply because an addon exists:

- `CombatHit` and result pipeline
- weapon movesets / timing / commitment
- hit balance/stumble/fallback probability rules
- physical world weapon ownership/drop/steal rules
- faction/territory/combat/criminal/duty flag model
- crime observation and police evidence provenance
- case value / warrants / raids
- faction economy loops
- FFA risk/reward/extraction rules
- activity reward semantics
- hideout/faction-base gameplay

External animation/physics systems should **present and physically express** these rules, not own them.

## Recommended replacement order

### Wave 1 — immediate visual credibility
1. Downtown City MegaKit
2. Godot Asset Placer
3. Universal Base Characters
4. Universal Animation Library 1 + 2
5. Phantom Camera
6. Kenney UI/Input Prompts
7. Kenney impact/interface audio

### Wave 2 — production hygiene
1. Jolt smoke test + explicit pin
2. Maaack Options Menus
3. Static Mesh Merger
4. ProtonScatter
5. coherent urban prop pass

### Wave 3 — multiplayer foundation
1. study/transplant 3D Multiplayer Template v2 patterns
2. decide dedicated-server authority boundary
3. evaluate Talo for identity/presence/social services
4. replicate Urban Brawl's existing authoritative gameplay state rather than rewriting it around a networking template

## Art-direction rule

The biggest visual danger now is not low detail — it is **inconsistency**.

Use one primary environment kit and one primary humanoid/animation family. Secondary packs are for gaps only.

Current recommendation:
- environment: Quaternius Downtown City MegaKit as the main language
- characters: Quaternius Universal Base Characters
- animation: Quaternius UAL 1 + 2
- UI/icon polish: Kenney
- extra street props: only assets that visually match the primary environment

A coherent modest asset set will look substantially more intentional than a larger pile of unrelated high-quality assets.
