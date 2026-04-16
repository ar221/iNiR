# Bar Redesign Phase 1: Layout Overhaul + MiniRing Component

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the bar's visual layout to the Organic Flow aesthetic — gradient arc mini-rings for system metrics, leaner element set, taller bar, fade-mask text overflow, and monogram click rewired to a new `dashboardOpen` state (dashboard itself ships in Phase 2).

**Architecture:** Replace the existing `Resource.qml` (icon + circular progress + text) with a new `MiniRing.qml` (Canvas-drawn gradient arc + center value + label). Restructure `BarContent.qml` to a three-section layout with flexible spacers. Add config-driven bar height override. Rewire `MonogramAnchor` click from sidebar toggle to dashboard state toggle.

**Tech Stack:** QML (Qt 6), Quickshell framework, Canvas 2D API for gradient arcs, Qt5Compat.GraphicalEffects for OpacityMask

**Spec:** `docs/superpowers/specs/2026-04-16-bar-dashboard-redesign.md` — Part 1 only.

---

## Visual Primitives: CSS → QML Mapping

The design spec uses CSS notation. Here's how each visual maps to QML:

| Spec (CSS) | QML Equivalent |
|---|---|
| `linear-gradient(135deg, #fb923c, #f472b6)` on a circle stroke | `Canvas` with `createConicalGradient()` or `createLinearGradient()` drawing arcs via `context.arc()` |
| `mask-image: linear-gradient(to right, black 80%, transparent)` | `OpacityMask` (Qt5Compat.GraphicalEffects) with a `LinearGradient` source |
| `box-shadow: 0 8px 32px rgba(...)` | Existing `StyledRectangularShadow` component (already used in BarContent.qml line 119) |
| `backdrop-filter: blur(20px)` | Already handled by Aurora theme path in BarContent.qml (lines 221-255) — no new work |
| `border-radius: 22px` | `Rectangle { radius: 22 }` — standard QML |
| `gap: 12px` between rings | `RowLayout { spacing: 12 }` |
| Gradient fill on monogram circle | `Rectangle { radius: width/2; gradient: Gradient { ... } }` with `rotation: 135` for diagonal |

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| **Create** | `modules/bar/MiniRing.qml` | Reusable gradient-arc ring indicator (Canvas + value + label) |
| **Create** | `modules/bar/MiniRings.qml` | Row of 4 MiniRing instances (CPU/GPU/Temp/RAM) bound to ResourceUsage |
| **Modify** | `modules/bar/MonogramAnchor.qml` | Rewire click: sidebar → dashboard state. Add gradient background. |
| **Modify** | `modules/bar/BarContent.qml` | Restructure to 3-section with spacers. Swap Resources for MiniRings. Default-off media/util/weather/systray. Fade-mask on ActiveWindow. |
| **Modify** | `modules/bar/ActiveWindow.qml` | Add OpacityMask fade and bounded max-width |
| **Modify** | `modules/common/Appearance.qml` | Add `barHeightOverride` config-driven sizing |
| **Modify** | `modules/common/Config.qml` | Register new config keys (bar.height, bar.rings.*, bar.activeWindow.*) |
| **Modify** | `defaults/config.json` | Add default values for new config keys |
| **Modify** | `GlobalStates.qml` | Add `dashboardOpen` property |

---

## Tasks

### Task 1: Add `dashboardOpen` State to GlobalStates

**Files:**
- Modify: `GlobalStates.qml` (line ~18, near other panel state booleans)

- [ ] **Step 1: Add the dashboardOpen property**

Open `GlobalStates.qml`. Near the existing sidebar state properties (around line 18), add:

```qml
property bool dashboardOpen: false
```

And add a handler that closes other overlays when the dashboard opens (following the same pattern as sidebar handlers at lines 137-142):

```qml
onDashboardOpenChanged: {
    if (GlobalStates.dashboardOpen) {
        GlobalStates.sidebarLeftOpen = false
        GlobalStates.sidebarRightOpen = false
        GlobalStates.overviewOpen = false
        GlobalStates.controlPanelOpen = false
    }
}
```

- [ ] **Step 2: Verify hot-reload**

Save the file. Quickshell hot-reloads on save. Run:

```bash
qs msg -c inir eval "GlobalStates.dashboardOpen"
```

Expected: `false` (default value). No crash in `qs log -c inir`.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add GlobalStates.qml
git commit -m "bar: add dashboardOpen state to GlobalStates"
```

---

### Task 2: Register New Config Keys

**Files:**
- Modify: `modules/common/Config.qml` (bar section, lines ~716-857)
- Modify: `defaults/config.json` (bar section, lines ~376-515)

- [ ] **Step 1: Add config keys to Config.qml**

In `modules/common/Config.qml`, find the `bar` JsonObject (around line 716). Within the existing structure, add the following new keys. Find the `modules` sub-object (around line 747) and add after the existing module toggles:

Inside the existing `bar` object, add a new `rings` sub-object after the `resources` block (after ~line 801):

```qml
rings: JsonObject {
    cpu: true
    gpu: true
    temp: true
    ram: true
    showLabels: true
}
```

Add `height` and `activeWindow` keys at the bar top level (near line 726, alongside other bar properties):

```qml
height: -1  // -1 = use theme default, positive value = override in px
```

Add an `activeWindow` sub-object near the modules block:

```qml
activeWindow: JsonObject {
    maxWidth: 280
    fadeOverflow: true
}
```

- [ ] **Step 2: Add defaults to config.json**

In `defaults/config.json`, find the `"bar"` section. Add inside it (after the existing `"resources"` block):

```json
"height": -1,
"rings": {
    "cpu": true,
    "gpu": true,
    "temp": true,
    "ram": true,
    "showLabels": true
},
"activeWindow": {
    "maxWidth": 280,
    "fadeOverflow": true
}
```

Also update the default module visibility — set these to `false` (they move to dashboard in Phase 2):

```json
"modules": {
    "media": false,
    "utilButtons": false,
    "weather": false,
    "sysTray": false
}
```

Keep `resources: true` — we still need it as the data source. The MiniRings will replace its visual display.

- [ ] **Step 3: Verify config loads**

Save both files. Hot-reload fires. Check with:

```bash
qs msg -c inir eval "Config.options?.bar?.rings?.cpu"
```

Expected: `true`

```bash
qs msg -c inir eval "Config.options?.bar?.height"
```

Expected: `-1`

- [ ] **Step 4: Commit**

```bash
cd ~/Github/inir
git add modules/common/Config.qml defaults/config.json
git commit -m "bar: register config keys for rings, height override, activeWindow"
```

---

### Task 3: Add Bar Height Override to Appearance

**Files:**
- Modify: `modules/common/Appearance.qml` (sizes section, lines 857-889)

- [ ] **Step 1: Add config-driven height override**

In `modules/common/Appearance.qml`, find the `sizes` QtObject (line 857). Replace the `baseBarHeight` line (861) with a config-aware version:

Find this (line 861):
```qml
property real baseBarHeight: Math.round(40 * root.fontSizeScale)
```

Replace with:
```qml
property real _configBarHeight: Config.options?.bar?.height ?? -1
property real baseBarHeight: _configBarHeight > 0 ? Math.round(_configBarHeight * root.fontSizeScale) : Math.round(40 * root.fontSizeScale)
```

This preserves the existing default (40px scaled) but allows override via `bar.height` config. The `barHeight` computed property on line 862-863 continues to add corner-style padding on top of this — no change needed there.

- [ ] **Step 2: Verify height**

```bash
qs msg -c inir eval "Appearance.sizes.baseBarHeight"
```

Expected: same as before (approximately 40, depends on fontSizeScale). Now test override:

Temporarily set `bar.height` to `54` in `~/.config/illogical-impulse/config.json`, save, and check:

```bash
qs msg -c inir eval "Appearance.sizes.baseBarHeight"
```

Expected: approximately 54 (scaled). Revert the live config change after testing.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/common/Appearance.qml
git commit -m "bar: add config-driven bar height override"
```

---

### Task 4: Create MiniRing Component

**Files:**
- Create: `modules/bar/MiniRing.qml`

This is the core new visual component. A Canvas-drawn gradient arc ring with center value text and an optional label below.

- [ ] **Step 1: Create MiniRing.qml**

Create `modules/bar/MiniRing.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    // Data
    required property real value          // 0.0 – 1.0 normalized
    property string label: ""             // e.g. "CPU", "GPU"
    property bool showLabel: Config.options?.bar?.rings?.showLabels ?? true

    // Warning thresholds (0-100 scale, 0 = disabled)
    property real cautionThreshold: 0
    property real warningThreshold: 100
    property bool _caution: cautionThreshold > 0 && (value * 100) >= cautionThreshold && !_warning
    property bool _warning: (value * 100) >= warningThreshold

    // Theming — shifts to red/hot on warning
    property color gradientStart: _warning ? "#ef4444" : _caution ? "#f59e0b" : Appearance.colors.colPrimary
    property color gradientEnd: _warning ? "#dc2626" : _caution ? "#f97316" : Appearance.colors.colTertiary
    property color trackColor: Appearance.inirEverywhere
        ? Qt.rgba(Appearance.inir.colText.r, Appearance.inir.colText.g, Appearance.inir.colText.b, 0.08)
        : Qt.rgba(1, 1, 1, 0.06)
    property color valueColor: Appearance.inirEverywhere
        ? Appearance.inir.colText
        : Appearance.colors.colOnLayer0

    // Sizing
    property real ringSize: 28
    property real lineWidth: 3
    property real labelOffset: 2  // gap between ring and label

    implicitWidth: ringSize
    implicitHeight: showLabel ? ringSize + labelOffset + labelText.implicitHeight : ringSize

    // Redraw when value or colors change
    onValueChanged: canvas.requestPaint()
    onGradientStartChanged: canvas.requestPaint()
    onGradientEndChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: root.ringSize
        height: root.ringSize
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width / 2
            var cy = height / 2
            var radius = (Math.min(width, height) - root.lineWidth) / 2
            var startAngle = -Math.PI / 2  // 12 o'clock
            var endAngle = startAngle + (2 * Math.PI * Math.min(Math.max(root.value, 0), 1))

            // Track (full circle, dim)
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
            ctx.lineWidth = root.lineWidth
            ctx.strokeStyle = root.trackColor.toString()
            ctx.lineCap = "round"
            ctx.stroke()

            // Value arc (gradient)
            if (root.value > 0.005) {
                // Create a linear gradient across the canvas for the arc color
                var grad = ctx.createLinearGradient(0, 0, width, height)
                grad.addColorStop(0.0, root.gradientStart.toString())
                grad.addColorStop(1.0, root.gradientEnd.toString())

                ctx.beginPath()
                ctx.arc(cx, cy, radius, startAngle, endAngle)
                ctx.lineWidth = root.lineWidth
                ctx.strokeStyle = grad
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }

    // Center value text
    StyledText {
        anchors.centerIn: canvas
        text: Math.round(root.value * 100).toString()
        font.pixelSize: 8
        font.weight: Font.DemiBold
        color: root.valueColor
    }

    // Label below ring
    StyledText {
        id: labelText
        anchors.top: canvas.bottom
        anchors.topMargin: root.labelOffset
        anchors.horizontalCenter: canvas.horizontalCenter
        visible: root.showLabel && root.label !== ""
        text: root.label
        font.pixelSize: 7
        font.weight: Font.Medium
        font.capitalization: Font.AllUppercase
        color: Qt.rgba(root.valueColor.r, root.valueColor.g, root.valueColor.b, 0.35)
        horizontalAlignment: Text.AlignHCenter
    }
}
```

- [ ] **Step 2: Visual verification**

Save the file. It won't appear in the bar yet (that's Task 6), but check for parse errors:

```bash
qs log -c inir 2>&1 | tail -20
```

Expected: no new errors mentioning `MiniRing`.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/bar/MiniRing.qml
git commit -m "bar: add MiniRing gradient arc component"
```

---

### Task 5: Create MiniRings Container

**Files:**
- Create: `modules/bar/MiniRings.qml`

This groups 4 MiniRing instances in a row, bound to ResourceUsage data, with per-ring config toggles.

- [ ] **Step 1: Create MiniRings.qml**

Create `modules/bar/MiniRings.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services

RowLayout {
    id: root
    spacing: 12

    // Ensure resource polling is active while rings are visible
    Component.onCompleted: ResourceUsage.ensureRunning()

    // CPU ring — orange → pink
    MiniRing {
        visible: Config.options?.bar?.rings?.cpu ?? true
        value: ResourceUsage.cpuUsage
        label: "CPU"
        gradientStart: "#fb923c"
        gradientEnd: "#f472b6"
        cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
        warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        Layout.alignment: Qt.AlignVCenter
    }

    // GPU ring — sky → indigo
    MiniRing {
        visible: Config.options?.bar?.rings?.gpu ?? true
        value: ResourceUsage.gpuUsage
        label: "GPU"
        gradientStart: "#38bdf8"
        gradientEnd: "#818cf8"
        cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
        warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        Layout.alignment: Qt.AlignVCenter
    }

    // Temperature ring — green → cyan
    MiniRing {
        visible: Config.options?.bar?.rings?.temp ?? true
        value: Math.min(ResourceUsage.cpuTemp / 100, 1.0)
        label: "TMP"
        gradientStart: "#4ade80"
        gradientEnd: "#22d3ee"
        cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
        warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
        Layout.alignment: Qt.AlignVCenter
    }

    // RAM ring — purple → pink
    MiniRing {
        visible: Config.options?.bar?.rings?.ram ?? true
        value: ResourceUsage.memoryUsedPercentage
        label: "RAM"
        gradientStart: "#c084fc"
        gradientEnd: "#f472b6"
        cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
        warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        Layout.alignment: Qt.AlignVCenter
    }
}
```

- [ ] **Step 2: Verify no parse errors**

```bash
qs log -c inir 2>&1 | tail -20
```

Expected: no new errors.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/bar/MiniRings.qml
git commit -m "bar: add MiniRings container with 4 resource rings"
```

---

### Task 6: Add Fade-Mask Overflow to ActiveWindow

**Files:**
- Modify: `modules/bar/ActiveWindow.qml`

- [ ] **Step 1: Add OpacityMask fade to ActiveWindow**

Open `modules/bar/ActiveWindow.qml`. The current structure (lines 79-104) is a `ColumnLayout` with two text rows. We need to:

1. Wrap the root Item in a way that applies a gradient opacity mask when `fadeOverflow` is enabled
2. Respect the `maxWidth` config

Add the import at the top of the file (after the existing imports):

```qml
import Qt5Compat.GraphicalEffects as GE
```

Find the root `Item` (around line 6-7). Add these properties after the existing properties:

```qml
property real maxTextWidth: Config.options?.bar?.activeWindow?.maxWidth ?? 280
property bool fadeOverflow: Config.options?.bar?.activeWindow?.fadeOverflow ?? true
```

Now wrap the existing `ColumnLayout` (lines 79-104) inside a clipping container with an opacity mask. The key change: the ColumnLayout needs to be the `source` for the mask. Replace the ColumnLayout section with:

```qml
Item {
    id: textContainer
    anchors.fill: parent
    clip: true

    // Constrain width
    implicitWidth: Math.min(contentColumn.implicitWidth, root.maxTextWidth)

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: -1
        // ... keep existing content: appNameText + titleText children unchanged
    }

    // Fade mask: visible content → transparent at right edge
    layer.enabled: root.fadeOverflow
    layer.effect: GE.OpacityMask {
        maskSource: Rectangle {
            width: textContainer.width
            height: textContainer.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ffffffff" }
                GradientStop { position: 0.8; color: "#ffffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }
    }
}
```

Keep the existing `ColumnLayout` children (appNameText and titleText) exactly as they are — just re-parent them inside `contentColumn` within the `textContainer` Item.

- [ ] **Step 2: Verify with a long window title**

Open a browser window with a very long page title. Check that:
1. The active window text fades out at the right edge instead of clipping hard
2. The text doesn't push into the center workspaces area
3. Short titles display normally without any visible fade

```bash
qs log -c inir 2>&1 | tail -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/bar/ActiveWindow.qml
git commit -m "bar: add fade-mask overflow to ActiveWindow text"
```

---

### Task 7: Rewire MonogramAnchor Click to Dashboard

**Files:**
- Modify: `modules/bar/MonogramAnchor.qml`

- [ ] **Step 1: Change click handler**

Open `modules/bar/MonogramAnchor.qml`. Find the click handler (line 53-55):

```qml
onPressed: {
    GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
}
```

Replace with:

```qml
onPressed: {
    GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
}
```

Also update the `toggled` property (line 51) from:

```qml
toggled: GlobalStates.sidebarLeftOpen
```

To:

```qml
toggled: GlobalStates.dashboardOpen
```

- [ ] **Step 2: Add gradient background to monogram**

The spec calls for a gradient circular avatar. The current MonogramAnchor is a `RippleButton` with text. We'll add a gradient circle behind the text when dashboard mode is available. 

After the existing `StyledText` block (lines 74-90), add a `Rectangle` that renders the gradient circle behind the label. Actually — the cleaner approach is to replace the text-based monogram with a gradient circle that contains the letter. Find the `StyledText` block and replace the whole `StyledText` (lines 74-90) with:

```qml
Rectangle {
    id: monogramCircle
    anchors.centerIn: parent
    width: 28
    height: 28
    radius: width / 2
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Qt.rgba(0.984, 0.573, 0.235, 1.0) }  // #fb923c
        GradientStop { position: 1.0; color: Qt.rgba(0.957, 0.447, 0.698, 1.0) }  // #f472b6
    }
    // Note: Qt Rectangle gradient is vertical only. The 135deg angle from the spec
    // is approximated. For exact diagonal, a ShaderEffect or rotated approach would
    // be needed. Vertical gradient is visually close enough at 28px.

    StyledText {
        anchors.centerIn: parent
        text: root.monogramText
        font.pixelSize: 13
        font.weight: Font.Bold
        color: "#ffffff"
    }
}
```

Update the root sizing properties (lines 27-28) to accommodate the circle:

```qml
implicitWidth: 28 + buttonPadding * 2
implicitHeight: 28 + buttonPadding * 2
```

Remove the market-state color logic from the text (since the letter is now always white on gradient). The market-state tinting can be applied to the gradient stops instead — when market is open, shift the gradient toward red:

After the `monogramCircle` definition, add color behavior:

```qml
// Market-aware gradient tinting
property color _gradStart: marketState === "open" ? "#ff4444" : "#fb923c"
property color _gradEnd: marketState === "open" ? "#ff1100" : "#f472b6"
```

And update the GradientStop colors to use these properties:
```qml
GradientStop { position: 0.0; color: root._gradStart }
GradientStop { position: 1.0; color: root._gradEnd }
```

- [ ] **Step 3: Verify monogram appearance and click**

Save. The monogram should now appear as a gradient circle with white "AR" text. Click it:

```bash
qs msg -c inir eval "GlobalStates.dashboardOpen"
```

Expected: toggles between `true` and `false` on each click. The left sidebar should NOT open (that's now edge-pull only, implemented in Phase 5).

```bash
qs log -c inir 2>&1 | tail -20
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd ~/Github/inir
git add modules/bar/MonogramAnchor.qml
git commit -m "bar: rewire monogram to dashboard toggle, add gradient circle"
```

---

### Task 8: Restructure BarContent Layout

**Files:**
- Modify: `modules/bar/BarContent.qml` (this is the big one — 832 lines)

This task restructures the bar to the new three-section layout. The changes are surgical — we modify what exists rather than rewriting 800 lines.

- [ ] **Step 1: Replace Resources loader with MiniRings in right section**

The current Resources module lives in the left-center group (lines 358-365). We're moving system metrics to the RIGHT section as MiniRings (per the spec: rings live next to the notification bell on the right).

First, disable the old Resources loader. Find this block (lines 358-365):

```qml
Loader {
    active: Config.options?.bar?.modules?.resources ?? true
    visible: active
    Layout.fillWidth: root.useShortenedForm === 2
    sourceComponent: Resources {
        alwaysShowAllResources: root.useShortenedForm === 2
    }
}
```

Change `active` to `false` to disable it (we'll remove it fully once MiniRings are confirmed working):

```qml
Loader {
    active: false  // Replaced by MiniRings in right section
    visible: active
    Layout.fillWidth: root.useShortenedForm === 2
    sourceComponent: Resources {
        alwaysShowAllResources: root.useShortenedForm === 2
    }
}
```

- [ ] **Step 2: Add MiniRings to right section**

Find the right section's `RowLayout` (`rightSectionRowLayout`, around line 559). Since it uses `Qt.RightToLeft` layout direction (line 565), items are visually reversed — the first child appears rightmost. We want MiniRings to appear LEFT of the notification indicators and RIGHT of center.

Find the `SysTray` loader (around line 799). Just BEFORE the SysTray block, add the MiniRings:

```qml
// MiniRings — gradient arc resource indicators
Loader {
    active: Config.options?.bar?.modules?.resources ?? true
    visible: active
    Layout.alignment: Qt.AlignVCenter
    sourceComponent: MiniRings {}
}

VerticalBarSeparator {
    visible: (Config.options?.bar?.modules?.resources ?? true)
        && (Config.options?.bar?.borderless ?? true)
}
```

Note: Because the RowLayout is `RightToLeft`, adding items before SysTray places them visually to the LEFT of the sidebar button area and RIGHT of the existing side modules — which is where we want the rings.

Wait — actually, let me reconsider the layout direction. The right section uses `Qt.RightToLeft`, so the first child (`RippleButton` containing indicators at line 567) renders rightmost. Items added after it render to its LEFT. The SysTray, Timer, Weather etc. are already after the button, so they appear LEFT of the button.

The MiniRings should appear between the center section and the right sidebar button. So we need to add them AFTER the Weather/Spacer (at the leftmost position of the right section, which is the LAST items in the RightToLeft layout).

Find the Spacer Item (around line 816-819) and the Weather block (lines 822-829). Add the MiniRings AFTER the Weather block (making them the leftmost visual element in the right section):

```qml
// MiniRings — gradient arc resource indicators (leftmost in right section)
VerticalBarSeparator {
    visible: (Config.options?.bar?.modules?.resources ?? true)
        && (Config.options?.bar?.borderless ?? true)
}

Loader {
    active: Config.options?.bar?.modules?.resources ?? true
    visible: active
    Layout.alignment: Qt.AlignVCenter
    sourceComponent: MiniRings {}
}
```

- [ ] **Step 3: Default-off the modules that move to dashboard**

The spec says media, utilButtons, weather, and sysTray default to off (moved to dashboard). The config defaults were changed in Task 2, but the live config (`~/.config/illogical-impulse/config.json`) may still have them enabled. The QML already respects config toggles, so this is automatic — no code change needed. The user's live config preserves their choices; new installs get the leaner defaults.

- [ ] **Step 4: Verify bar renders with MiniRings**

Save `BarContent.qml`. The bar should hot-reload with:
- Gradient arc rings visible in the right section
- Old circular resource indicators hidden (the loader is disabled)
- Media, util buttons, weather, systray visibility depends on user's live config

```bash
qs log -c inir 2>&1 | tail -30
```

Expected: no errors. Visual check: four small gradient ring arcs should appear in the right portion of the bar.

- [ ] **Step 5: Commit**

```bash
cd ~/Github/inir
git add modules/bar/BarContent.qml
git commit -m "bar: replace Resources with MiniRings, restructure right section"
```

---

### Task 9: Add Left-Section Spacer for Centered Middle

**Files:**
- Modify: `modules/bar/BarContent.qml`

Currently, the middle section uses `anchors.horizontalCenter: parent.horizontalCenter` (line 349). This works but doesn't adapt gracefully when left/right content is asymmetric. The spec wants flexible spacers. However, the existing anchor-based centering already achieves this — and the left section is bounded by `anchors.right: middleSection.left` (line 280).

The key missing piece: the left section's `ActiveWindow` currently uses `Layout.fillWidth: true` which can push the left section arbitrarily wide. We need to constrain it.

- [ ] **Step 1: Constrain the left section width**

In `BarContent.qml`, find the `barLeftSideMouseArea` (line 273). Its right anchor is already `middleSection.left` (line 280), which prevents it from overlapping center. But the ActiveWindow's `fillWidth: true` (line 338) can cause the left section to claim excessive space.

Find the ActiveWindow in the left section (lines 336-340):

```qml
ActiveWindow {
    visible: (Config.options?.bar?.modules?.activeWindow ?? true) && root.useShortenedForm === 0
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```

Replace with:

```qml
ActiveWindow {
    visible: (Config.options?.bar?.modules?.activeWindow ?? true) && root.useShortenedForm === 0
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.maximumWidth: Config.options?.bar?.activeWindow?.maxWidth ?? 280
}
```

This caps the active window text area while still allowing it to fill available space up to the max.

- [ ] **Step 2: Verify centering holds with long titles**

Open a window with a very long title. Verify:
1. The middle section (workspaces + clock) stays centered
2. The active window text fades out (from Task 6) and doesn't push center
3. Short titles don't leave a weird gap

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/bar/BarContent.qml
git commit -m "bar: constrain ActiveWindow maxWidth, preserve center alignment"
```

---

### Task 10: Bump Default Bar Height

**Files:**
- Modify: `defaults/config.json`

- [ ] **Step 1: Set default bar height to 54px**

In `defaults/config.json`, find the `"height": -1` we added in Task 2 and change it to:

```json
"height": 54
```

This sets the default for new installs. Existing users keep their current height unless they update their live config.

- [ ] **Step 2: Verify bar height change**

If testing against a live config that doesn't have `bar.height` set, temporarily add `"height": 54` to the live config at `~/.config/illogical-impulse/config.json` under the `"bar"` key. Save and verify:

```bash
qs msg -c inir eval "Appearance.sizes.baseBarHeight"
```

Expected: approximately 54 (scaled by fontSizeScale).

Visual check: the bar should be visibly taller, giving the MiniRings more breathing room.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add defaults/config.json
git commit -m "bar: set default height to 54px for Organic Flow spacing"
```

---

### Task 11: Left Sidebar Keyboard-Only Fallback

**Files:**
- Modify: `modules/bar/BarContent.qml`

Since the monogram no longer opens the left sidebar, the left side mouse area's click handler in BarContent.qml still opens it. We should update that to open the dashboard instead (matching the monogram behavior), while keeping the keyboard shortcut for the sidebar.

- [ ] **Step 1: Update left side click handler**

Find `barLeftSideMouseArea`'s `onPressed` handler (lines 288-293):

```qml
onPressed: event => {
    if (event.button === Qt.LeftButton)
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    else if (event.button === Qt.RightButton)
        root.openBarContextMenu(event.x, event.y, barLeftSideMouseArea)
}
```

Replace with:

```qml
onPressed: event => {
    if (event.button === Qt.LeftButton)
        GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
    else if (event.button === Qt.RightButton)
        root.openBarContextMenu(event.x, event.y, barLeftSideMouseArea)
}
```

The left sidebar is now accessible only via:
- Keyboard shortcut (existing Hyprland/Niri keybinds — unchanged)
- IPC: `qs msg -c inir sidebarLeft toggle`
- Edge pull (Phase 5)

- [ ] **Step 2: Verify**

Click the left side of the bar (not the monogram, but the area around it). Should toggle `dashboardOpen`, not `sidebarLeftOpen`.

```bash
qs msg -c inir eval "GlobalStates.dashboardOpen"
```

Keyboard shortcut for left sidebar should still work independently.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/bar/BarContent.qml
git commit -m "bar: left-side click opens dashboard, sidebar via keyboard/IPC only"
```

---

### Task 12: Sync Live Copy and Final Visual Verification

**Files:**
- Sync: `~/.config/quickshell/inir/` ← `~/Github/inir/`

- [ ] **Step 1: Sync all changed files to live copy**

```bash
cp ~/Github/inir/GlobalStates.qml ~/.config/quickshell/inir/GlobalStates.qml
cp ~/Github/inir/modules/bar/MiniRing.qml ~/.config/quickshell/inir/modules/bar/MiniRing.qml
cp ~/Github/inir/modules/bar/MiniRings.qml ~/.config/quickshell/inir/modules/bar/MiniRings.qml
cp ~/Github/inir/modules/bar/MonogramAnchor.qml ~/.config/quickshell/inir/modules/bar/MonogramAnchor.qml
cp ~/Github/inir/modules/bar/ActiveWindow.qml ~/.config/quickshell/inir/modules/bar/ActiveWindow.qml
cp ~/Github/inir/modules/bar/BarContent.qml ~/.config/quickshell/inir/modules/bar/BarContent.qml
cp ~/Github/inir/modules/common/Appearance.qml ~/.config/quickshell/inir/modules/common/Appearance.qml
cp ~/Github/inir/modules/common/Config.qml ~/.config/quickshell/inir/modules/common/Config.qml
cp ~/Github/inir/defaults/config.json ~/.config/quickshell/inir/defaults/config.json
```

Wait — Quickshell reads from the live copy at `~/.config/quickshell/inir/`. During development, edits to the repo at `~/Github/inir/` only take effect after syncing. However, if the live copy is what Quickshell watches, you may have been editing the repo without seeing changes. 

**Check which path Quickshell actually reads from:**

```bash
qs msg -c inir eval "Quickshell.shellRoot"
```

If it returns `~/.config/quickshell/inir/`, sync as above. If it returns `~/Github/inir/`, the files are already live.

- [ ] **Step 2: Full visual verification checklist**

After sync (or if repo is the live path), verify:

1. Bar is taller (~54px) 
2. Monogram shows as a gradient circle with white initials
3. Clicking monogram toggles `dashboardOpen` (no visible effect yet — dashboard UI ships in Phase 2)
4. Active window text fades out gracefully with long titles
5. Four MiniRings (CPU/GPU/Temp/RAM) visible in right section with gradient arcs
6. Rings update live as system load changes
7. Workspaces stay centered
8. Clock and date display correctly
9. Notification bell with badge still works
10. No errors in `qs log -c inir`

- [ ] **Step 3: Drift check**

```bash
diff -rq ~/.config/quickshell/inir/modules/bar/ ~/Github/inir/modules/bar/ | grep -v __pycache__
diff -rq ~/.config/quickshell/inir/GlobalStates.qml ~/Github/inir/GlobalStates.qml
```

Expected: files in sync (or repo IS the live path).

- [ ] **Step 4: Final commit (if any fixups)**

```bash
cd ~/Github/inir
git status
# If any uncommitted fixups from verification:
git add -A
git commit -m "bar: phase 1 verification fixups"
```

---

## Phase 1 Complete Checklist

After all tasks:

- [ ] `GlobalStates.dashboardOpen` property exists and toggles
- [ ] Config keys registered: `bar.height`, `bar.rings.*`, `bar.activeWindow.*`
- [ ] Bar height configurable (default 54px)
- [ ] `MiniRing.qml` renders gradient arc rings via Canvas
- [ ] `MiniRings.qml` shows CPU/GPU/Temp/RAM in right bar section
- [ ] `MonogramAnchor` is a gradient circle, click → dashboard toggle
- [ ] `ActiveWindow` fades text with OpacityMask, respects maxWidth
- [ ] Old Resources indicator disabled in bar
- [ ] Media/UtilButtons/Weather/SysTray default to off (configurable)
- [ ] Left side click → dashboard (sidebar via keyboard/IPC only)
- [ ] Live copy synced, no QML errors

**Next:** Phase 2 — Dashboard overlay shell + profile/system/toggles cards.
