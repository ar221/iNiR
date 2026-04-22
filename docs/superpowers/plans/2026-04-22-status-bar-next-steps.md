# iNiR Status Bar — Post-Ship Next Steps

**Date:** 2026-04-22
**Owner:** Elsa + Hermes
**Status:** Ready for next session

## What was completed today

- Implemented density presets (`compact`, `default`, `airy`) and wired them in Bar + Quick settings.
- Implemented visual presets (`dusky`, `clean`, `glass`) and mapped them to group/background/border/typography behavior.
- Finalized right-lane information architecture:
  - utility vs ambient separation
  - alert/status sub-cluster divider in the right chip
  - ambient tail overflow policy for narrow widths
- Added new controls:
  - `bar.laneSeparator`: `off | subtle | strong`
  - `bar.ambientVisibility`: `auto | always | hidden`
- Applied ship polish:
  - style-aware right indicator icon sizing
  - adaptive calendar chip truncation and text sizing under narrow/compact conditions
- Updated design spec with Iterations A→F implementation notes.

## Recommended next steps

### 1) Visual regression matrix (high value)
Capture screenshots for this matrix:
- style: `dusky`, `clean`, `glass`
- density: `compact`, `default`, `airy`
- lane separator: `off`, `subtle`, `strong`
- ambient visibility: `auto`, `always`, `hidden`

Goal: verify no clipping/overlap and preserve intended visual identity per preset.

### 2) Runtime stress checks (high value)
Test under:
- shortened and hella-shortened forms
- high notification/load states (multiple indicators on)
- weather enabled/disabled
- systray heavy vs empty

Goal: ensure right-lane never collapses into unreadable crowding.

### 3) Optional refinement pass (medium value)
- Add user-facing one-line descriptions under visual preset selector.
- Add an accessibility variant for icon weight/contrast.
- Tune calendar title truncation thresholds after screenshot review.

## Suggested execution order

1. Visual regression captures
2. Runtime stress checks + quick fixes
3. Optional refinement pass
4. Merge/ship tag
