# Direction Matrix Template

Use this when a design reference could influence a major surface. The matrix prevents single-reference drift by forcing multiple iNiR-native translations.

## Default Variants

### Mission Glass

Modern glass, precise metadata, restrained atmospheric depth.

Use when:

- The surface needs polish and hierarchy.
- Data density is medium.
- The interaction should feel calm but technical.

Risks:

- Too much blur becomes decorative glassmorphism.
- Too little density becomes a SaaS dashboard.

### CRT Console

Denser, more terminal-forward, operational but not cosplay.

Use when:

- The surface is status-heavy.
- Fast scanning matters.
- Time, logs, commands, or system state are central.

Risks:

- Faux-retro styling can become costume.
- Overdense labels can hurt readability.

### Material Flight Deck

Closest to current iNiR: Material You structure with mission-system pressure and selective retro cues.

Use when:

- The surface is core daily shell UI.
- Stability and consistency matter.
- The reference should influence details, not identity.

Risks:

- Can become too safe if the borrowed move is diluted.
- Can lose the reference's useful edge.

## Matrix

| Variant | Mood | Borrowed Idea | What Changes | Risk | Best Surface | Verdict |
|---|---|---|---|---|---|---|
| Mission Glass | | | | | | |
| CRT Console | | | | | | |
| Material Flight Deck | | | | | | |

## Decision Rules

- Pick `Mission Glass` when the surface needs refinement, hierarchy, and atmospheric polish.
- Pick `CRT Console` when the surface needs fast scan density and operational pressure.
- Pick `Material Flight Deck` when the surface is core shell UI and must preserve current cohesion.
- If none fit, the reference may be mood-only or off-brand.

## Required Verdict

End every matrix with one of these decisions:

- Build this variant.
- Prototype only.
- Save for later.
- Reject for iNiR.
