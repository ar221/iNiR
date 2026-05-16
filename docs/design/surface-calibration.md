# Surface Calibration

Surface Calibration is the first recommended pilot from the Huashu extraction. It is an internal design tool for tuning iNiR's look and feel without hard-coding guesses.

## Purpose

Create a hidden or dev-facing calibration panel that adjusts key visual and motion tokens live.

This should help answer:

- How dense should this surface be?
- How much blur is enough?
- How warm should the accent feel?
- How strong should borders be?
- How much CRT texture is useful before it becomes cosplay?
- How fast should shell motion feel?

## First-Version Scope

Start ephemeral. Persistence can come later after the controls prove useful.

Initial controls:

- Density scale.
- Blur strength.
- Surface opacity.
- Accent temperature.
- Border opacity.
- Corner radius.
- CRT grain intensity.
- Motion tempo.
- Mono label weight.
- Clock weight.

## Preview Surfaces

The panel should preview changes against real shell-like surfaces.

Recommended preview set:

- Compact status tile.
- Notification sample.
- Launcher result row.
- Dashboard module.
- Clock/time block.
- Metadata strip.

## Design Requirements

- Internal/dev tone, not user-facing settings polish.
- Dense but readable.
- Clear labels and current values.
- Reset to defaults.
- Reduced-motion-safe preview behavior.
- No broad shell redesign required for v1.

## Non-Goals

- Full theme editor.
- Public settings panel.
- Persistent user profiles.
- Export/import workflow.
- Replacing the theming pipeline.

## Future Extensions

- Save named presets.
- Compare two token sets side by side.
- Export candidate token diffs.
- Add screenshot capture for design review.
- Connect to direction matrix variants: `Mission Glass`, `CRT Console`, `Material Flight Deck`.

## Acceptance Criteria

- It hot-reloads safely.
- It can tune at least density, blur, accent, radius, and motion tempo.
- It does not disrupt normal shell use.
- It gives visible design leverage within one session.
- It makes future design decisions less guessy.
