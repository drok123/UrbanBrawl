# Urban Brawl — Faction Conflict, Territory and Flagging

This document defines the street-risk rules that connect the three playable faction careers.

## Core rule

Urban Brawl should not rely on unrestricted always-on world PvP. Risk is created by **visible choices and profitable faction actions**.

A player becomes attackable when they deliberately expose themselves through combat or faction activity.

### Flag states

- **NEUTRAL** — no current hostile exposure.
- **COMBAT FLAGGED** — the player has a weapon equipped or has recently participated in combat.
- **CRIMINAL FLAGGED** — the player completed or attempted an illegal economic action such as a drug sale or illegal weapon transaction. Criminal flagging also creates heat/evidence.
- **DUTY FLAGGED** — a police player has committed to an enforcement action such as interdiction, seizure, warrant service or raid participation. Criminal players can fight back.

Priority for presentation is:

```text
CRIMINAL > DUTY > COMBAT > NEUTRAL
```

A flag should persist briefly after the triggering action so players cannot instantly remove risk by unequipping a weapon or stepping away from an interaction.

## Weapon rule

**Equipping a weapon automatically combat-flags the player.**

This makes a visible weapon a readable PvP signal. Walking around unarmed is safer; drawing a bat, knife or firearm is an intentional escalation.

Weapon flagging is separate from criminal flagging. Merely carrying a weapon does not necessarily create police evidence, but it does expose the player to combat.

## Territory rule

Faction territory should create profitable reasons to enter somebody else's turf rather than rewarding safe farming at home.

The three-way prototype relationship is:

```text
CONTRABAND FACTION
    -> sells drugs in POLICE territory
    -> criminal flagged + evidence generated

ARMS FACTION
    -> runs / sells illegal weapons in CONTRABAND territory
    -> combat flagged while armed
    -> criminal flagged when the transaction completes

POLICE FACTION
    -> performs interdiction / warrant / seizure work in ARMS territory
    -> duty flagged when enforcement begins
    -> earns evidence / requisition / case value
```

This creates a risk triangle in which each faction has at least one high-value activity that requires entering hostile or contested territory.

## Contraband faction interaction

### Drug sales

Drug sales are only available in **police-controlled territory**.

Flow:

```text
produce contraband at hideout
    -> carry product into police territory
    -> find buyer / sale point
    -> start transaction
    -> CRIMINAL FLAG
    -> cash payout
    -> heat + tagged evidence generated
    -> beat cops can intervene / chase / seize
```

The sale itself is the crime event. Police should not receive magical knowledge before there is an observable event, but a completed or interrupted sale can create evidence with provenance.

Higher quantity / quality can increase both payout and evidence value.

## Arms faction interaction

### Gunrunning / illegal weapon sales

The arms faction's profitable street interaction should occur in **contraband-controlled territory**.

Flow:

```text
craft / acquire weapon
    -> equip or transport it
    -> COMBAT FLAG while armed
    -> enter contraband territory
    -> sell / deliver weapon to criminal buyer
    -> CRIMINAL FLAG
    -> cash / crafting-resource payout
    -> weapon provenance + evidence trail created
```

High-rarity weapons should create higher payout and higher police case value if intercepted.

The weapon economy therefore creates physical risk before the sale even happens because the seller is already combat-flagged while visibly armed.

## Police faction interaction

### Interdiction / warrant work

Police should not be permanently immune simply because they are police. Committing to enforcement creates **DUTY FLAGGING**.

High-value police work should require entering criminal territory.

Prototype arms-territory flow:

```text
receive case / patrol lead
    -> enter arms-controlled territory
    -> begin interdiction / warrant action
    -> DUTY FLAG
    -> locate target shipment / suspect / evidence
    -> fight / arrest / seize
    -> evidence package + requisition payout
```

Later, contraband territory provides the equivalent drug-lab / smuggling enforcement loop.

Duty flagging makes the cop a legitimate combat target once they commit to enforcement, creating fair counterplay instead of one-sided confiscation.

## Faction interaction symmetry

Every faction needs all of the following:

1. **Home advantage** — production, crafting, organization or defensive benefits in its own territory.
2. **Foreign profit action** — a reason to enter another faction's territory for better rewards.
3. **Visible risk trigger** — weapon draw, illegal transaction or enforcement commitment.
4. **Counter-faction response** — another player career that profits from stopping that action.
5. **Economic output** — cash, goods, evidence, case value, crafting resources or progression.
6. **Economic sink / loss risk** — seizure, dropped weapons, destroyed contraband, failed sale, repair cost or raid exposure.

No faction should consist only of passive bonuses.

## Heat and evidence relationship

Flagging is immediate PvP exposure. Heat and evidence are longer-lived consequences.

- **Combat flag** answers: "Can this player be fought right now?"
- **Criminal flag** answers: "Is this player currently exposed because of an illegal act?"
- **Heat** answers: "How much attention is this player attracting?"
- **Evidence** answers: "How strong is the case against this player / gang / hideout?"

A crime can therefore end its immediate flag window while still leaving heat and evidence behind.

## Activity overrides

Instanced activities can override open-world flag rules.

Examples:
- FFA: everyone is combat-enabled by activity rules.
- Heist: criminal crew and police response team are mutually hostile.
- Hideout raid: attackers and defenders are mutually hostile for the raid instance.

The open-world flag state should resume when the player returns to the persistent city.

## Prototype implementation order

1. persistent faction / territory / flag state in `GameSession`
2. weapon equip automatically drives combat flag
3. HUD displays faction, territory, flag, heat and evidence
4. hideout faction-test terminals while careers are still prototype-only
5. grow room produces contraband units
6. police-territory drug buyer pays cash and criminal-flags contraband players
7. beat-cop intervention consumes that same crime/evidence event
8. add contraband territory + arms gunrunning interaction
9. add arms territory + police interdiction interaction
10. replace prototype faction terminals with real character / gang affiliation flow

The long-term rule remains: **profitable faction actions create conflict by design rather than requiring random griefing.**
