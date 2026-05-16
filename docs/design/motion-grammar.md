# Motion Grammar

iNiR motion should feel like a system coming online, not an app doing tricks.

Motion must explain state, hierarchy, causality, or attention. Decorative motion is noise.

## Motion Beats

### wake

The surface becomes available.

- Use for opening panels, launcher, dashboard modules, overlays.
- Prefer opacity and transform.
- Keep it quick and quiet.

### scan

Metadata, indicators, or secondary structure appears.

- Use for labels, timestamps, status rows, module IDs.
- Can stagger very lightly.
- Should feel like instrumentation resolving, not a loading gimmick.

### lock

Primary content settles into its final state.

- Use when a selection, search result, workspace, or panel becomes active.
- Smooth deceleration.
- No bounce or elastic easing.

### pulse

State confirmation or live urgency.

- Use rarely.
- Appropriate for active recording, urgent status, focused workspace, or critical alert.
- Avoid permanent ambient pulsing unless it reflects live state.

### retire

The surface exits or yields focus.

- Faster than entry.
- Low drama.
- Avoid lingering transitions that slow the shell down.

## Timing Guidance

- Micro feedback: 80-140ms.
- Panel entry: 140-220ms.
- Complex staged reveal: 220-360ms.
- Exit: 90-180ms.

Use smooth deceleration. Avoid bounce, springy novelty, and motion that calls attention to itself.

## Reduced Motion

Every motion pattern needs a reduced-motion equivalent.

- Replace staged movement with opacity or instant state change.
- Preserve information hierarchy.
- Do not hide state changes just because motion is disabled.

## Rules

- Animate transform and opacity where possible.
- Do not animate layout properties unless the platform-specific pattern is known safe.
- Do not add motion to every hover.
- Do not use motion to compensate for unclear layout.
- Name motion by intent: `wake`, `scan`, `lock`, `pulse`, `retire`.

## Reference Translation

When extracting motion from a reference, convert it into beats.

Bad:

```text
Make it animate like the reference.
```

Good:

```text
Launcher opens with wake, metadata resolves with scan, selected action confirms with lock.
```
