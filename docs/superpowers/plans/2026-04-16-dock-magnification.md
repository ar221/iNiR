# Dock Magnification + Visual Refresh — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add macOS-style magnification wave to the iNiR dock with a visual refresh (bigger icons, dark shelf background, theme accent line).

**Architecture:** Each dock icon delegate computes a gaussian scale factor based on cursor distance. Icon size and delegate dimensions react to this scale, with icons "popping" toward screen center. A hover-tracking MouseArea on DockApps feeds cursor position to all delegates. The dock panel grows to accommodate magnified overflow.

**Tech Stack:** QML (Quickshell), JavaScript (config/math), JSON (config)

**Spec:** `docs/superpowers/specs/2026-04-16-dock-magnification-design.md`

**Important:** This is a Quickshell QML project. There are no unit tests — testing is visual via hot-reload. After each task, sync changes to the live runtime (`~/.config/quickshell/inir/`) and visually verify. Never restart `qs` — hot-reload is automatic on file save.

**Two-copy sync:** Edit files in `~/Github/inir/` (repo), then copy changed files to `~/.config/quickshell/inir/` (live) for hot-reload testing.

---

### Task 1: Make DockButton base dimensions config-driven

**Files:**
- Modify: `modules/dock/DockButton.qml`

Currently all dimensions are hardcoded to `50`. Make them derive from `Config.options.dock.iconSize` so icon size changes flow through automatically.

- [ ] **Step 1: Replace hardcoded dimensions in DockButton.qml**

Replace the entire content of `modules/dock/DockButton.qml` with:

```qml
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    property bool vertical: false
    property string dockPosition: "bottom"

    readonly property real baseIconSize: Config.options?.dock?.iconSize ?? 56
    readonly property real baseButtonSize: baseIconSize + 8

    Layout.fillHeight: !vertical
    Layout.fillWidth: vertical

    implicitWidth: baseButtonSize
    implicitHeight: baseButtonSize
    buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.normal

    // Background: fully transparent for angel (no boxes visible), only glass on hover
    colBackground: Appearance.angelEverywhere ? "transparent" : "transparent"

    // Hover colors for dock (Layer0 context)
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer0Hover
    colRipple: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive
        : Appearance.colors.colLayer0Active

    background.implicitHeight: baseButtonSize
    background.implicitWidth: baseButtonSize
}
```

- [ ] **Step 2: Sync to live and verify**

```bash
cp ~/Github/inir/modules/dock/DockButton.qml ~/.config/quickshell/inir/modules/dock/DockButton.qml
```

Verify: Dock icons should appear slightly larger (64px buttons instead of 50px). The overview button at the end of the dock should also resize. No layout breakage.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/dock/DockButton.qml
git commit -m "dock: make button dimensions config-driven

Replace hardcoded 50px with baseIconSize (from config) + 8px padding.
Default iconSize changes from 35 to 56."
```

---

### Task 2: Make DockAppButton dimensions config-driven and add magnification properties

**Files:**
- Modify: `modules/dock/DockAppButton.qml:15,91-95`

DockAppButton has hardcoded `50` for button size and `35` for icon size. Make these config-driven and add the `magnifyScale` property that delegates will use.

- [ ] **Step 1: Update DockAppButton.qml sizing and add magnification scale**

In `modules/dock/DockAppButton.qml`, find these lines near the top (around line 15):

```qml
    property real iconSize: Config.options?.dock?.iconSize ?? 35
```

Replace with:

```qml
    property real iconSize: Config.options?.dock?.iconSize ?? 56
    readonly property real baseButtonSize: iconSize + 8
```

Then find the sizing block (around lines 91-95):

```qml
    readonly property real dockHeight: Config.options?.dock?.height ?? 70
    readonly property real separatorSize: dockHeight - 50

    implicitWidth: isSeparator ? (vertical ? separatorSize : 8) : (vertical ? 50 : (implicitHeight - topInset - bottomInset))
    implicitHeight: isSeparator ? (vertical ? 8 : separatorSize) : 50
```

Replace with:

```qml
    readonly property real dockHeight: Config.options?.dock?.height ?? 80
    readonly property real separatorSize: Math.max(dockHeight - baseButtonSize, 8)

    // Magnification scale — set by the delegate in DockApps.qml
    property real magnifyScale: 1.0

    implicitWidth: isSeparator
        ? (vertical ? separatorSize : 8)
        : baseButtonSize * (vertical ? 1 : magnifyScale)
    implicitHeight: isSeparator
        ? (vertical ? 8 : separatorSize)
        : baseButtonSize * (vertical ? magnifyScale : 1)
```

- [ ] **Step 2: Update icon anchoring for directional pop**

Find the icon image loader anchors (around line 273):

```qml
            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
```

Replace with position-dependent anchoring so icons "pop" toward screen center:

```qml
            Loader {
                id: iconImageLoader
                anchors {
                    // Horizontal docks: fill width, anchor to outer edge
                    left: !root.vertical ? parent.left : undefined
                    right: !root.vertical ? parent.right
                         : root.dockPosition === "right" ? parent.right : undefined
                    // Vertical docks: fill height, anchor to outer edge
                    top: root.vertical ? parent.top : undefined
                    bottom: root.vertical ? parent.bottom
                          : root.dockPosition === "bottom" ? parent.bottom : undefined
                    // Top dock: anchor to top
                    // Left dock: anchor to left (right is already undefined)
                }
```

- [ ] **Step 3: Make IconImage size reactive to magnification**

Find the `IconImage` `implicitSize` property (around line 309):

```qml
                    implicitSize: root.iconSize
```

Replace with:

```qml
                    implicitSize: root.iconSize * root.magnifyScale
```

- [ ] **Step 4: Sync to live and verify**

```bash
cp ~/Github/inir/modules/dock/DockAppButton.qml ~/.config/quickshell/inir/modules/dock/DockAppButton.qml
```

Verify: Dock should show bigger icons (56px in 64px buttons). Separator should still render correctly. Layout should be clean. Magnification isn't wired up yet — icons are at resting size.

- [ ] **Step 5: Commit**

```bash
cd ~/Github/inir
git add modules/dock/DockAppButton.qml
git commit -m "dock: config-driven sizes + magnification scale property

- iconSize defaults to 56 (was 35), buttonSize = iconSize + 8
- Add magnifyScale property (default 1.0, set by DockApps)
- implicitWidth/Height react to magnifyScale along dock axis
- IconImage.implicitSize scales with magnifyScale
- Icon anchoring changes from center to edge-aligned for directional pop"
```

---

### Task 3: Add magnification mouse tracking and scale computation to DockApps

**Files:**
- Modify: `modules/dock/DockApps.qml`

This is the core task — add the hover-tracking MouseArea, compute magnification scale per delegate, and wire it all up.

- [ ] **Step 1: Add magnification properties to DockApps root**

In `modules/dock/DockApps.qml`, find the properties block near the top (after line 28, around the `lastHoveredButton` property):

```qml
    property Item lastHoveredButton
    property bool buttonHovered: false
```

Add these magnification properties right after:

```qml
    // ─── Magnification ───────────────────────────────────────────────
    readonly property bool magnifyEnabled: (Config.options?.dock?.magnification?.enabled ?? true)
        && Appearance.animationsEnabled
    property real magnifyMousePos: -1  // Cursor position along dock axis (-1 = not hovering)
    readonly property real magnifyMaxScale: Config.options?.dock?.magnification?.maxScale ?? 1.8
    readonly property real magnifySpread: {
        const factor = Config.options?.dock?.magnification?.spread ?? 3.5
        const iconSize = Config.options?.dock?.iconSize ?? 56
        return factor * iconSize
    }
```

- [ ] **Step 2: Add magnification MouseArea**

Find the `StyledListView` block (around line 525):

```qml
    StyledListView {
        id: listView
```

Add this MouseArea right BEFORE the StyledListView:

```qml
    // Magnification hover tracker — pure position tracking, doesn't eat events
    MouseArea {
        id: magnifyArea
        anchors.fill: listView
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Transparent to press/release/click
        enabled: root.magnifyEnabled && !root.dragActive

        onPositionChanged: (mouse) => {
            root.magnifyMousePos = root.vertical ? mouse.y : mouse.x
        }
        onExited: root.magnifyMousePos = -1
        // Reset when drag starts (enabled becomes false)
        onEnabledChanged: if (!enabled) root.magnifyMousePos = -1
    }

    StyledListView {
        id: listView
```

- [ ] **Step 3: Add magnifyScale computation to the delegate**

Find the delegate block inside the StyledListView (around line 551):

```qml
        delegate: DockAppButton {
            id: dockDelegate
            required property var modelData
            required property int index
            appToplevel: modelData
            appListRoot: root
            vertical: root.vertical
            dockPosition: root.dockPosition
```

Add the magnifyScale computation right after `dockPosition: root.dockPosition`:

```qml
            dockPosition: root.dockPosition

            // ─── Magnification Scale ─────────────────────────────────
            magnifyScale: {
                if (!root.magnifyEnabled || root.dragActive) return 1.0
                const mousePos = root.magnifyMousePos
                if (mousePos < 0) return 1.0

                // Icon center along the dock axis (delegate coords ≈ ListView coords)
                const myCenter = root.vertical ? (y + height / 2) : (x + width / 2)
                const distance = Math.abs(mousePos - myCenter)
                const spread = root.magnifySpread

                return 1 + (root.magnifyMaxScale - 1) * Math.exp(-(distance * distance) / (2 * spread * spread))
            }

            Behavior on magnifyScale {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
```

- [ ] **Step 4: Update delegate anchoring for directional pop**

Still in the delegate block, find the centering anchors (around line 560):

```qml
            anchors.verticalCenter: !root.vertical ? parent?.verticalCenter : undefined
            anchors.horizontalCenter: root.vertical ? parent?.horizontalCenter : undefined
```

Replace with edge-aligned anchoring:

```qml
            // Edge-aligned so magnified icons pop toward screen center
            anchors.bottom: root.dockPosition === "bottom" ? parent?.bottom : undefined
            anchors.top: root.dockPosition === "top" ? parent?.top : undefined
            anchors.right: root.dockPosition === "right" ? parent?.right : undefined
            anchors.left: root.dockPosition === "left" ? parent?.left : undefined
```

- [ ] **Step 5: Sync to live and verify magnification**

```bash
cp ~/Github/inir/modules/dock/DockApps.qml ~/.config/quickshell/inir/modules/dock/DockApps.qml
```

Verify by hovering over the dock:
- Icons should scale up as cursor approaches (max 1.8× at cursor center)
- Neighboring icons should scale in a bell curve falloff
- Icons should "pop" toward screen center (upward for bottom dock, leftward for right dock)
- Dragging an icon should pause magnification (all icons return to 1.0)
- Leaving the dock area should smoothly animate all icons back to 1.0
- Test with dock in at least two positions (current = right, try setting `dock.position` to `"bottom"` in config)

- [ ] **Step 6: Commit**

```bash
cd ~/Github/inir
git add modules/dock/DockApps.qml
git commit -m "dock: add macOS-style magnification wave

- MouseArea tracks cursor position along dock axis
- Each delegate computes gaussian scale from cursor distance
- magnifyScale drives delegate implicit size + icon render size
- Delegates edge-aligned for directional pop (toward screen center)
- Magnification pauses during drag, disabled with reduced animations
- Config: dock.magnification.enabled, .maxScale (1.8), .spread (3.5)"
```

---

### Task 4: Add accent line to dock visual background

**Files:**
- Modify: `modules/dock/Dock.qml`

Add a 2px theme-colored gradient line along the inner edge of the dock (the edge facing screen center).

- [ ] **Step 1: Add accent line component**

In `modules/dock/Dock.qml`, find the `AngelPartialBorder` closing tag inside `dockVisualBackground` (around line 258):

```qml
                                AngelPartialBorder {
                                    targetRadius: dockVisualBackground.radius
                                }
                            }
```

Add the accent line right before the closing `}` of `dockVisualBackground` (before the `}` that closes the Rectangle `dockVisualBackground`, after `AngelPartialBorder`):

```qml
                                AngelPartialBorder {
                                    targetRadius: dockVisualBackground.radius
                                }

                                // Theme accent line — inner edge of dock
                                Rectangle {
                                    id: dockAccentLine
                                    visible: !Appearance.gameModeMinimal
                                    opacity: 0.5

                                    // Position along inner edge based on dock position
                                    anchors {
                                        // Horizontal docks: line at top (bottom dock) or bottom (top dock)
                                        left: !root.isVertical ? parent.left : undefined
                                        right: !root.isVertical ? parent.right : undefined
                                        top: root.position === "bottom" ? parent.top
                                           : root.isLeft ? undefined : (root.position === "right" ? undefined : undefined)
                                        bottom: root.isTop ? parent.bottom : undefined
                                        // Vertical docks: line at inner side
                                        // Right dock: line on left edge; Left dock: line on right edge
                                    }

                                    // For vertical docks, anchor top/bottom and position on inner side
                                    states: [
                                        State {
                                            when: root.position === "right"
                                            AnchorChanges {
                                                target: dockAccentLine
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                            }
                                        },
                                        State {
                                            when: root.isLeft
                                            AnchorChanges {
                                                target: dockAccentLine
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                anchors.right: parent.right
                                            }
                                        }
                                    ]

                                    // Dimensions: thin line
                                    width: root.isVertical ? 2 : undefined
                                    height: root.isVertical ? undefined : 2

                                    // Inset from edges for the gradient fade
                                    anchors.leftMargin: !root.isVertical ? 20 : 0
                                    anchors.rightMargin: !root.isVertical ? 20 : 0
                                    anchors.topMargin: root.isVertical ? 20 : 0
                                    anchors.bottomMargin: root.isVertical ? 20 : 0

                                    gradient: Gradient {
                                        orientation: root.isVertical ? Gradient.Vertical : Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.3; color: Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary }
                                        GradientStop { position: 0.7; color: Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }
                            }
```

- [ ] **Step 2: Sync to live and verify**

```bash
cp ~/Github/inir/modules/dock/Dock.qml ~/.config/quickshell/inir/modules/dock/Dock.qml
```

Verify: A thin, theme-colored gradient line should appear along the inner edge of the dock background. It should be subtle (50% opacity) with faded ends. Verify it appears on the correct edge based on dock position.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/dock/Dock.qml
git commit -m "dock: add theme-colored accent line on inner edge

2px gradient line using colPrimary, fades at both ends.
Position-aware: top edge for bottom dock, left edge for right dock, etc.
Hidden in game mode minimal."
```

---

### Task 5: Expand PanelWindow for magnification overflow

**Files:**
- Modify: `modules/dock/Dock.qml`

The PanelWindow needs extra space perpendicular to the dock axis so magnified icons have room to "pop" without clipping.

- [ ] **Step 1: Add magnification overflow calculation**

In `modules/dock/Dock.qml`, find the `dockRoot` PanelWindow properties (around line 74):

```qml
                readonly property real dockHeight: Config.options?.dock?.height ?? 70
```

Replace with:

```qml
                readonly property real dockHeight: Config.options?.dock?.height ?? 80
                readonly property real magnificationOverflow: {
                    const enabled = Config.options?.dock?.magnification?.enabled ?? true
                    if (!enabled) return 0
                    const iconSize = Config.options?.dock?.iconSize ?? 56
                    const buttonSize = iconSize + 8
                    const maxScale = Config.options?.dock?.magnification?.maxScale ?? 1.8
                    return buttonSize * (maxScale - 1)
                }
```

- [ ] **Step 2: Update PanelWindow implicit dimensions**

Find the implicitWidth/Height bindings (around line 85-86):

```qml
                implicitWidth: root.isVertical ? (dockHeight + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut) : dockBackground.implicitWidth
                implicitHeight: root.isVertical ? dockBackground.implicitHeight : (dockHeight + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut)
```

Replace with:

```qml
                implicitWidth: root.isVertical
                    ? (dockHeight + magnificationOverflow + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut)
                    : dockBackground.implicitWidth
                implicitHeight: root.isVertical
                    ? dockBackground.implicitHeight
                    : (dockHeight + magnificationOverflow + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut)
```

- [ ] **Step 3: Sync to live and verify**

```bash
cp ~/Github/inir/modules/dock/Dock.qml ~/.config/quickshell/inir/modules/dock/Dock.qml
```

Verify: When hovering the dock, magnified icons should be fully visible — no clipping at the edge facing screen center. The dock panel should be large enough to contain the tallest/widest magnified icon.

- [ ] **Step 4: Commit**

```bash
cd ~/Github/inir
git add modules/dock/Dock.qml
git commit -m "dock: expand panel window for magnification overflow

Add magnificationOverflow to PanelWindow implicit dimensions so
magnified icons have room to pop without clipping. Overflow is
iconButtonSize * (maxScale - 1), zero when magnification disabled."
```

---

### Task 6: Update default config

**Files:**
- Modify: `defaults/config.json`

Add the `magnification` config block and update the `iconSize`/`height` defaults.

- [ ] **Step 1: Update defaults/config.json dock section**

Open `defaults/config.json` and find the `"dock"` section. Replace it with:

```json
  "dock": {
    "enable": true,
    "enableBlurGlass": false,
    "height": 80,
    "hoverRegionHeight": 2,
    "hoverToReveal": true,
    "ignoredAppRegexes": [],
    "monochromeIcons": true,
    "pinnedApps": [
      "org.gnome.Nautilus",
      "firefox",
      "kitty"
    ],
    "pinnedOnStartup": true,
    "showBackground": true,
    "iconSize": 56,
    "separatePinnedFromRunning": true,
    "enableDragReorder": true,
    "style": "panel",
    "magnification": {
      "enabled": true,
      "maxScale": 1.8,
      "spread": 3.5
    }
  }
```

Changes from current defaults:
- `height`: 60 → 80
- `iconSize`: 35 → 56
- Added `magnification` block with `enabled`, `maxScale`, `spread`

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add defaults/config.json
git commit -m "dock: update defaults for magnification and bigger icons

- iconSize: 35 -> 56, height: 60 -> 80
- Add magnification config block (enabled, maxScale 1.8, spread 3.5)"
```

---

### Task 7: Update user config and full integration test

**Files:**
- Modify: `~/.config/illogical-impulse/config.json` (user config, NOT repo)

Update the user's live config to use the new defaults, then do a full integration test across dock positions.

- [ ] **Step 1: Update user config**

Using a script or manual edit, update the user's `~/.config/illogical-impulse/config.json` to add the magnification block and update icon size/height:

```bash
cd ~/Github/inir && python3 -c "
import json
with open('/home/ayaz/.config/illogical-impulse/config.json', 'r') as f:
    config = json.load(f)

dock = config.setdefault('dock', {})
dock['iconSize'] = 56
dock['height'] = 80
dock['showBackground'] = True  # Enable the dark shelf
dock['magnification'] = {
    'enabled': True,
    'maxScale': 1.8,
    'spread': 3.5
}

with open('/home/ayaz/.config/illogical-impulse/config.json', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
print('Config updated')
"
```

- [ ] **Step 2: Sync ALL changed dock files to live**

```bash
cp ~/Github/inir/modules/dock/DockButton.qml ~/.config/quickshell/inir/modules/dock/DockButton.qml
cp ~/Github/inir/modules/dock/DockAppButton.qml ~/.config/quickshell/inir/modules/dock/DockAppButton.qml
cp ~/Github/inir/modules/dock/DockApps.qml ~/.config/quickshell/inir/modules/dock/DockApps.qml
cp ~/Github/inir/modules/dock/Dock.qml ~/.config/quickshell/inir/modules/dock/Dock.qml
```

- [ ] **Step 3: Integration test checklist**

Test each of these (change `dock.position` in config to test different positions):

1. **Bottom dock**: Hover → icons magnify upward in bell curve. Leave → smooth return to 1.0.
2. **Right dock**: Hover → icons magnify leftward (toward screen center).
3. **Left dock** (if desired): Hover → icons magnify rightward.
4. **Drag & drop**: Start dragging → magnification pauses, icons snap to 1.0. Drop → magnification resumes.
5. **Hover preview**: Hover an app with windows → preview popup appears, magnified icon stays large.
6. **Auto-hide**: Dock hidden → move cursor to edge → dock reveals → hover triggers magnification.
7. **Accent line**: Visible on correct inner edge for each dock position. Theme color matches wallpaper.
8. **Separator**: Does NOT magnify. Stays thin between pinned and running sections.
9. **Config tuning**: Change `maxScale` to `1.5` in config → magnification becomes more subtle immediately. Change to `2.2` → more dramatic. Change `enabled` to `false` → no magnification.
10. **Pinned apps without windows**: Icons should magnify same as running apps.

- [ ] **Step 4: Commit config defaults if not already committed**

Verify all repo changes are committed:

```bash
cd ~/Github/inir && git status
```
