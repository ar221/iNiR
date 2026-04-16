# Dock Magnification + Visual Refresh — Design Spec

**Date:** 2026-04-16
**Status:** Approved
**Scope:** iNiR dock (Quickshell QML)

---

## Summary

Add macOS-style magnification wave to the iNiR dock. Icons scale up in a gaussian bell curve as the cursor sweeps across, with neighbors tapering off smoothly. Works in all dock positions (bottom/left/right). Layered on top of a visual refresh: bigger base icons, opaque dark shelf background with a theme-colored accent line.

## Design Decisions

### Visual Identity (Resting State)

| Property | Current | New |
|----------|---------|-----|
| Icon size | 35px | 56px |
| Button size | 50px | 64px |
| Dock height/width | 60px | 80px |
| Background | None (`showBackground: false`) | Dark opaque shelf (~95% opacity) |
| Border | None | Subtle theme-tinted border |
| Accent | None | 2px theme-colored gradient line on inner edge |
| Border radius | `Appearance.rounding.normal` | 20px (generous, modern) |

- **Background color**: Pulls from `Appearance.colors.colLayer1` (respects current theme variant — inir, aurora, angel, default).
- **Accent line**: Positioned along the inner edge (top edge for bottom dock, bottom edge for top dock, left edge for right dock, right edge for left dock). Uses `Appearance.colors.colPrimary` with a gradient fade to transparent at both ends. Purely decorative — ties the dock to the wallpaper-driven Material You theme.
- **Floating gap**: Existing `Appearance.sizes.elevationMargin` already handles spacing from screen edge. No change needed.

### Magnification Behavior

- **Max scale**: 1.8× (56px → ~100px at cursor center)
- **Spread**: Gaussian falloff affecting 3-4 neighbors on each side
- **Formula**: `scale = 1 + (maxScale - 1) * exp(-distance² / (2 * spread²))`
  - `distance`: pixel distance from cursor to icon center along the dock axis
  - `spread`: controls falloff width (default: `3.5 * iconSize`)
- **Axis**: Follows dock orientation — X for horizontal docks (bottom), Y for vertical docks (left/right)
- **Transform origin**: Icons scale from the edge facing screen center:
  - Bottom dock: `transformOrigin: Item.Bottom`
  - Top dock: `transformOrigin: Item.Top`
  - Left dock: `transformOrigin: Item.Right`
  - Right dock: `transformOrigin: Item.Left`
- **Animation**: `Behavior on scale` using `Appearance.animation.elementMoveFast` duration and easing. Gives smooth transitions when cursor enters/exits the dock region.

### Layout Accommodation

When icons scale up, the dock must grow to contain them and neighbors must shift apart.

**Approach:** Each delegate's `implicitWidth`/`implicitHeight` reacts to its computed scale factor. The ListView's `contentWidth`/`contentHeight` updates naturally since delegate sizes change. The dock panel (`Dock.qml`) already binds its own size to the background's implicit dimensions, which bind to the ListView content size.

Specifically:
1. `DockAppButton.implicitWidth` = `baseButtonSize * currentScale` (horizontal) or `baseButtonSize` (vertical)
2. `DockAppButton.implicitHeight` = `baseButtonSize` (horizontal) or `baseButtonSize * currentScale` (vertical)
3. ListView `contentWidth`/`contentHeight` recalculates automatically
4. Existing `Behavior on implicitWidth/Height` with `elementMoveFast` on the ListView handles smooth grow/shrink
5. The PanelWindow's `implicitWidth`/`implicitHeight` in `Dock.qml` already chains from `dockBackground` → `dockRow`/`dockColumn` → `DockApps.listView` → delegates. The growth propagates up.

**Separator handling:** The separator (`DockSeparator`) does NOT scale. Only app icons magnify.

### Mouse Tracking

A `MouseArea` spanning the full ListView in `DockApps.qml` tracks cursor position:

```
property real magnifyMousePos: -1  // -1 = cursor not in dock
```

- `hoverEnabled: true`, `acceptedButtons: Qt.NoButton` (doesn't interfere with clicks)
- On `onPositionChanged`: update `magnifyMousePos` to `mouseX` (horizontal) or `mouseY` (vertical)
- On `onExited`: set `magnifyMousePos = -1` (triggers all icons to animate back to scale 1.0)
- Each `DockAppButton` delegate reads `appListRoot.magnifyMousePos` and computes its own scale based on its position in the ListView

### Interaction Rules

| Interaction | Behavior |
|-------------|----------|
| Drag & drop starts | Magnification pauses — all icons return to scale 1.0. Accurate hit targets needed during reorder. |
| Drag & drop ends | Magnification resumes on next mouse move. |
| Hover preview popup | Magnification stays active. Hovered icon at max scale is natural. |
| Auto-hide reveal | Magnification activates as dock reveals. No partial-scale state. |
| Game mode / reduced animations | Magnification disabled (`scale` always 1.0) when `Appearance.animationsEnabled` is false. |
| Context menu open | Magnification stays active (same as hover preview). |

### Config Schema

New keys under `dock.magnification` in `config.json`:

```json
{
  "dock": {
    "magnification": {
      "enabled": true,
      "maxScale": 1.8,
      "spread": 3.5
    },
    "iconSize": 56,
    "height": 80
  }
}
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `dock.magnification.enabled` | bool | `true` | Enable/disable magnification |
| `dock.magnification.maxScale` | float | `1.8` | Maximum scale at cursor (1.0 = no zoom) |
| `dock.magnification.spread` | float | `3.5` | Gaussian spread as multiplier of iconSize |
| `dock.iconSize` | int | `56` | Base icon size in pixels |
| `dock.height` | int | `80` | Dock panel thickness |

All values are live-tunable via `config.json` (FileView watches for changes).

### Defaults Change

The new defaults for a fresh install change the dock personality:
- `iconSize`: 35 → 56
- `height`: 60 → 80
- `showBackground`: remains user's choice (current users keep their setting)
- `magnification.enabled`: `true` by default

Existing users keep their current `iconSize` and `height` — the config system preserves existing values. The magnification block is new, so it defaults to enabled.

## Files Changed

| File | Change Summary |
|------|----------------|
| `modules/dock/DockApps.qml` | Add magnification MouseArea, expose `magnifyMousePos` and `magnifyEnabled` properties |
| `modules/dock/DockAppButton.qml` | Compute per-icon scale from distance to cursor, apply scale transform, adjust implicit dimensions reactively, set transformOrigin per dock position |
| `modules/dock/DockButton.qml` | Update base dimensions to use `Config.options.dock.iconSize` instead of hardcoded 50/35 |
| `modules/dock/Dock.qml` | Add accent line component to `dockVisualBackground`, update height binding |
| `defaults/config.json` | Add `dock.magnification` block with defaults, update `dock.iconSize` and `dock.height` defaults |

## Out of Scope

- The "Unity Bold" theme-colored background variant — parked as a potential future `dock.style` option
- Per-icon bounce animation on click (macOS has this; could add later)
- Dock "genie" minimize effect
- Magnification curve alternatives (parabolic, cosine) — gaussian is the right default, config knob is enough
