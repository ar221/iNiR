# iNiR Status Bar — Post-Ship Next Steps

**Date:** 2026-04-22
**Owner:** Elsa + Hermes
**Status:** Ready to ship

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

- [x] Add user-facing one-line descriptions under visual preset selector.
- [x] Add an accessibility variant for icon weight/contrast (`outlined` / `high-contrast`).
- [x] Tune calendar title truncation thresholds after runtime screenshot review.

## Suggested execution order

1. Visual regression captures
2. Runtime stress checks + quick fixes
3. Optional refinement pass
4. Merge/ship tag

## Merge / ship tag

- [x] Optional refinement pass complete.
- [x] Runtime validation log updated for final calendar truncation thresholds.
- [x] QML lint validated on updated bar runtime file.
- [x] Commit and tag this refinement (`status-bar-calendar-truncation-2026-04-22`).

## Runtime validation log

- Calendar title truncation tuned to reduce long text in reduced widths after runtime review.
  - `hella-short`: `8 -> 7`
  - `shortened`: `10 -> 9`
  - `compact + not-short`: `12 -> 11`
