# Command Room Phase 1 — Visual Grammar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Command Room's visual grammar — warm palette, preset-aware cards, barcode meters, hero zone, restructured center column, and bar barcode meters — proving the design language before Phase 2 populates operational widgets.

**Architecture:** Style preset system controlled by `dashboard.stylePreset: "command" | "default"`. The warm palette shifts Apollo globally (all surfaces). Dashboard-scoped changes read the preset from config and switch card styling, layout, and component selection. Bar reads `bar.rings.variant: "barcode" | "arc"` independently. `Appearance.mission` — the semantic palette consumed only by dashboard components — carries the preset-aware values (radius, padding) that propagate to all cards without per-card branching.

**Tech Stack:** QML (Quickshell runtime), no build step, hot-reload verification. New files registered in `modules/dashboard/qmldir` and `modules/common/widgets/qmldir`. Config keys added to `defaults/config.json`. State files under `~/.local/state/inir/`.

---

## File Structure

### New files

| File | Responsibility |
|------|----------------|
| `modules/common/widgets/BarcodeMeter.qml` | Reusable barcode progress bar (block + inline variants) |
| `modules/common/widgets/StatusPill.qml` | Compact status indicator chip |
| `modules/dashboard/PerformanceBarcodeCard.qml` | Horizontal barcode meters replacing vertical gradient bars |
| `modules/dashboard/HeroZone.qml` | Idle-state hero card ("COMMAND ROOM STANDING BY") — active state deferred to Phase 2 |
| `modules/bar/BarcodeMiniMeters.qml` | Inline barcode meters for bar (parallel to MiniRings) |

### Modified files

| File | Change summary |
|------|----------------|
| `modules/common/ThemePresets.qml` | Warm-shift 9 Apollo background tokens |
| `modules/common/Appearance.qml` | Add preset-aware `radiusLarge`, `cardPadding` to `mission` object |
| `modules/dashboard/DashboardCard.qml` | Read preset values from `Appearance.mission` (already does — values just change) |
| `modules/dashboard/DashboardContent.qml` | Add HeroZone, restructure center column (activity + widget stack side-by-side) |
| `modules/bar/BarContent.qml` | Conditional load of BarcodeMiniMeters vs MiniRings |
| `modules/common/widgets/qmldir` | Register BarcodeMeter, StatusPill |
| `modules/dashboard/qmldir` | Register PerformanceBarcodeCard, HeroZone |
| `defaults/config.json` | Add `dashboard.stylePreset`, `dashboard.sections.heroZone`, `bar.rings.variant` |

### Preserved (unchanged)

- `MiniRing.qml`, `MiniRings.qml` — kept for `"arc"` variant
- `PerformanceBarsCard.qml`, `PerformanceBar.qml` — kept for `"default"` preset
- `NetworkSparklinesCard.qml` — hidden in command preset via config, not deleted

---

## Phase 1a — Palette, Cards, Primitives, Performance

### Task 1: Warm-shift Apollo palette in ThemePresets.qml

**Files:**
- Modify: `modules/common/ThemePresets.qml:681-736`

- [ ] **Step 1: Read current apolloColors and confirm line numbers**

Run: `grep -n "m3background\|m3surface\b\|m3surfaceDim\|m3surfaceBright\|m3surfaceContainerLowest\|m3surfaceContainerLow\|m3surfaceContainer\b\|m3surfaceContainerHigh\b\|m3surfaceContainerHighest" modules/common/ThemePresets.qml | head -20`

Expected: 9 lines matching the cool-neutral values.

- [ ] **Step 2: Replace the 9 background/surface tokens with warm values**

Change these values in the `apolloColors` object:

```qml
m3background: "#0E0B08",
m3surface: "#0E0B08",
m3surfaceDim: "#060503",
m3surfaceBright: "#2A2420",
m3surfaceContainerLowest: "#080604",
m3surfaceContainerLow: "#161210",
m3surfaceContainer: "#1E1A16",
m3surfaceContainerHigh: "#2A2420",
m3surfaceContainerHighest: "#3A3430",
```

All other apolloColors tokens (primary, secondary, tertiary, error, success, on* variants) remain unchanged.

- [ ] **Step 3: Verify via hot-reload**

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No QML errors. Visual: bar and dashboard surfaces shift slightly warmer. The change is subtle on transparent surfaces, noticeable on opaque cards.

- [ ] **Step 4: Commit**

```bash
git add modules/common/ThemePresets.qml
git commit -m "palette: warm-shift Apollo background tokens for Command Room"
```

---

### Task 2: Add preset-aware properties to Appearance.mission

**Files:**
- Modify: `modules/common/Appearance.qml:719-756`

The `Appearance.mission` object currently has hardcoded `radiusLarge: 18`, `cardPadding: 18`. When `dashboard.stylePreset` is `"command"`, these should tighten to `6` and `16`. Since `Appearance.mission` is consumed ONLY by dashboard components (confirmed by grep: DashboardCard, ProfileCard, QuickTogglesCard, AgentLoopCard, PerformanceBar, ActivityConsoleCard), switching these values at the `mission` level propagates to all cards without per-card branching.

- [ ] **Step 1: Add preset property and conditional values**

In `Appearance.qml`, inside the `mission: QtObject {` block (around line 719), add a preset reader and make `radiusLarge` and `cardPadding` conditional. Replace the existing hardcoded values:

Find lines 750-755:
```qml
        readonly property int radiusSmall: 7
        readonly property int radiusNormal: 12
        readonly property int radiusLarge: 18
        readonly property int cardPadding: 18
        readonly property int cardSpacing: 10
        readonly property real borderWidth: 1
```

Replace with:
```qml
        readonly property bool commandPreset: {
            const preset = String(Config.options?.dashboard?.stylePreset ?? "default").toLowerCase()
            return preset === "command"
        }

        readonly property int radiusSmall: 7
        readonly property int radiusNormal: 12
        readonly property int radiusLarge: commandPreset ? 6 : 18
        readonly property int cardPadding: commandPreset ? 16 : 18
        readonly property int cardSpacing: 10
        readonly property real borderWidth: 1
```

- [ ] **Step 2: Verify no QML errors**

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No errors. Visual: no visible change yet (preset defaults to `"default"`).

- [ ] **Step 3: Commit**

```bash
git add modules/common/Appearance.qml
git commit -m "mission: add command preset toggle for radius and padding"
```

---

### Task 3: Add config keys to defaults/config.json

**Files:**
- Modify: `defaults/config.json:592-660`

- [ ] **Step 1: Add `stylePreset` key to dashboard section**

In the `"dashboard"` object (line 592), add `"stylePreset": "default"` as the first key after the opening brace:

```json
  "dashboard": {
    "stylePreset": "default",
    "layout": {
```

- [ ] **Step 2: Add `heroZone` to sections**

In `"dashboard" > "sections"` (around line 631), add after the last existing entry:

```json
      "agentCompanion": false,
      "heroZone": false
```

- [ ] **Step 3: Add `variant` to bar.rings**

Find the `"bar"` section. Locate or create the `"rings"` subsection. Add:

```json
    "rings": {
      "variant": "arc",
```

If `"rings"` already exists with sub-keys like `cpu`, `gpu`, etc., add `"variant": "arc"` as the first key in that object.

Run: `grep -n '"rings"' defaults/config.json` to find the exact location.

- [ ] **Step 4: Verify JSON validity**

Run: `python3 -c "import json; json.load(open('defaults/config.json'))"`

Expected: No output (valid JSON).

- [ ] **Step 5: Commit**

```bash
git add defaults/config.json
git commit -m "config: add dashboard.stylePreset, heroZone section, bar.rings.variant"
```

---

### Task 4: Create BarcodeMeter.qml primitive

**Files:**
- Create: `modules/common/widgets/BarcodeMeter.qml`
- Modify: `modules/common/widgets/qmldir`

- [ ] **Step 1: Read the widgets qmldir to understand registration pattern**

Run: `cat modules/common/widgets/qmldir`

- [ ] **Step 2: Create BarcodeMeter.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property real value
    property string label: ""
    property color color: Appearance.mission.colActive
    property string variant: "block"
    property bool showLabel: true
    property bool showValue: true
    property int inlineTrackWidth: 48

    property real cautionThreshold: 0
    property real warningThreshold: 100
    readonly property bool _caution: cautionThreshold > 0
        && (value * 100) >= cautionThreshold && !_warning
    readonly property bool _warning: (value * 100) >= warningThreshold
    readonly property color _fillColor: _warning ? Appearance.mission.colCritical
        : _caution ? Appearance.colors.colError : root.color

    readonly property bool _isBlock: variant === "block"
    readonly property int _barWidth: _isBlock ? 2 : 2
    readonly property int _barSpacing: _isBlock ? 2 : 1
    readonly property int _pitch: _barWidth + _barSpacing
    readonly property int _trackHeight: _isBlock ? 16 : 10
    readonly property int _trackRadius: 2

    implicitHeight: _isBlock ? _blockLayout.implicitHeight : _inlineLayout.implicitHeight
    implicitWidth: _isBlock ? 200 : _inlineLayout.implicitWidth

    ColumnLayout {
        id: _blockLayout
        anchors.fill: parent
        visible: root._isBlock
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            visible: root.showLabel || root.showValue
            spacing: 4

            StyledText {
                visible: root.showLabel
                text: root.label
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
                font.family: Appearance.font.family.monospace
                font.capitalization: Font.AllUppercase
                color: Appearance.mission.colTextMuted
            }

            Item { Layout.fillWidth: true }

            StyledText {
                visible: root.showValue
                text: Math.round(root.value * 100) + "%"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: Appearance.font.family.numbers
                color: root._fillColor
            }
        }

        Rectangle {
            id: blockTrack
            Layout.fillWidth: true
            Layout.preferredHeight: root._trackHeight
            radius: root._trackRadius
            color: Appearance.mission.colPanel
            clip: true

            Item {
                id: blockFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.value * parent.width

                Behavior on width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: blockTrack.width > 0 ? Math.ceil(blockTrack.width / root._pitch) : 0

                    Rectangle {
                        required property int index
                        x: index * root._pitch
                        y: 0
                        width: root._barWidth
                        height: blockTrack.height
                        color: root._fillColor

                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 250 }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        id: _inlineLayout
        anchors.fill: parent
        visible: !root._isBlock
        spacing: 4

        StyledText {
            visible: root.showLabel
            text: root.label
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.family: Appearance.font.family.monospace
            font.capitalization: Font.AllUppercase
            color: Appearance.mission.colTextMuted
            Layout.preferredWidth: implicitWidth
        }

        Rectangle {
            id: inlineTrack
            Layout.preferredWidth: root.inlineTrackWidth
            Layout.preferredHeight: root._trackHeight
            radius: root._trackRadius
            color: Qt.rgba(Appearance.mission.colText.r,
                           Appearance.mission.colText.g,
                           Appearance.mission.colText.b, 0.04)
            clip: true

            Item {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.value * parent.width

                Behavior on width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: inlineTrack.width > 0 ? Math.ceil(inlineTrack.width / root._pitch) : 0

                    Rectangle {
                        required property int index
                        x: index * root._pitch
                        y: 0
                        width: root._barWidth
                        height: inlineTrack.height
                        color: root._fillColor
                    }
                }
            }
        }

        StyledText {
            visible: root.showValue
            text: Math.round(root.value * 100)
            font.pixelSize: 9
            font.weight: Font.Bold
            font.family: Appearance.font.family.numbers
            color: root._fillColor
            Layout.preferredWidth: implicitWidth
        }
    }
}
```

- [ ] **Step 3: Register in qmldir**

Add to `modules/common/widgets/qmldir`:

```
BarcodeMeter 1.0 BarcodeMeter.qml
```

- [ ] **Step 4: Verify hot-reload**

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No QML errors. Component is registered but not yet instantiated anywhere.

- [ ] **Step 5: Commit**

```bash
git add modules/common/widgets/BarcodeMeter.qml modules/common/widgets/qmldir
git commit -m "widgets: add BarcodeMeter primitive with block and inline variants"
```

---

### Task 5: Create StatusPill.qml primitive

**Files:**
- Create: `modules/common/widgets/StatusPill.qml`
- Modify: `modules/common/widgets/qmldir`

- [ ] **Step 1: Create StatusPill.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common

Rectangle {
    id: root

    property string status: "idle"

    readonly property color _statusColor: {
        switch (status) {
        case "active": return Appearance.mission.colActive
        case "running": return Appearance.mission.colDone
        case "error": return Appearance.mission.colCritical
        case "waiting": return Appearance.colors.colSecondary
        case "scheduled": return Appearance.colors.colSecondary
        default: return Qt.rgba(Appearance.mission.colText.r,
                                Appearance.mission.colText.g,
                                Appearance.mission.colText.b, 0.3)
        }
    }

    readonly property string _label: {
        switch (status) {
        case "active": return "ACTIVE"
        case "running": return "RUNNING"
        case "error": return "ERROR"
        case "waiting": return "WAITING"
        case "scheduled": return "SCHEDULED"
        default: return "IDLE"
        }
    }

    implicitWidth: pillRow.implicitWidth + 20
    implicitHeight: pillRow.implicitHeight + 8
    radius: 4
    color: Qt.rgba(_statusColor.r, _statusColor.g, _statusColor.b, 0.08)
    border.width: 1
    border.color: Qt.rgba(_statusColor.r, _statusColor.g, _statusColor.b, 0.2)

    RowLayout {
        id: pillRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            id: dot
            width: 6
            height: 6
            radius: 3
            color: root._statusColor

            SequentialAnimation on opacity {
                running: root.status === "active" && Appearance.animationsEnabled
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 1000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
            }
        }

        StyledText {
            text: root._label
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
            font.family: Appearance.font.family.monospace
            color: root._statusColor
        }
    }
}
```

- [ ] **Step 2: Register in qmldir**

Add to `modules/common/widgets/qmldir`:

```
StatusPill 1.0 StatusPill.qml
```

- [ ] **Step 3: Verify hot-reload**

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No QML errors.

- [ ] **Step 4: Commit**

```bash
git add modules/common/widgets/StatusPill.qml modules/common/widgets/qmldir
git commit -m "widgets: add StatusPill primitive with pulse animation"
```

---

### Task 6: Create PerformanceBarcodeCard.qml

**Files:**
- Create: `modules/dashboard/PerformanceBarcodeCard.qml`
- Modify: `modules/dashboard/qmldir`

This replaces `PerformanceBarsCard` when the command preset is active. Four horizontal BarcodeMeter rows (CPU, GPU, RAM, VRAM) plus a temperature row. Same data sources as the existing card (`ResourceUsage` service).

- [ ] **Step 1: Create PerformanceBarcodeCard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "Performance"
    accentHeader: true

    function tempColor(temp) {
        const t = Math.min(1, Math.max(0, (temp - 40) / 55))
        return ColorUtils.mix(Appearance.mission.colCritical, Appearance.mission.colTextMuted, t)
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.cpuUsage
            label: "CPU"
            color: Appearance.mission.colActive
            variant: "block"
            cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        }

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.gpuUsage
            label: "GPU"
            color: Appearance.colors.colSecondary
            variant: "block"
            cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        }

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.memoryUsedPercentage
            label: "RAM"
            color: Appearance.colors.colTertiary
            variant: "block"
            cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
            warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        }

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.vramUsedPercentage
            label: "VRAM"
            color: Appearance.mission.colAccentMuted
            variant: "block"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Appearance.mission.colGrid
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: "CPU " + ResourceUsage.cpuTemp + "°"
                font.pixelSize: 12
                font.family: Appearance.font.family.monospace
                color: root.tempColor(ResourceUsage.cpuTemp)
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                radius: 1
                color: root.tempColor(Math.max(ResourceUsage.cpuTemp, ResourceUsage.gpuTemp))

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: 300 }
                }
            }

            StyledText {
                text: "GPU " + ResourceUsage.gpuTemp + "°"
                font.pixelSize: 12
                font.family: Appearance.font.family.monospace
                color: root.tempColor(ResourceUsage.gpuTemp)
            }
        }
    }
}
```

- [ ] **Step 2: Register in qmldir**

Add to `modules/dashboard/qmldir`:

```
PerformanceBarcodeCard 1.0 PerformanceBarcodeCard.qml
```

- [ ] **Step 3: Verify hot-reload**

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No QML errors. Component registered but not instantiated yet.

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/PerformanceBarcodeCard.qml modules/dashboard/qmldir
git commit -m "dashboard: add PerformanceBarcodeCard with barcode meters"
```

---

## Phase 1b — HeroZone, Layout Restructure, Bar Meters

### Task 7: Create HeroZone.qml

**Files:**
- Create: `modules/dashboard/HeroZone.qml`
- Modify: `modules/dashboard/qmldir`

Idle-only in Phase 1: full-width card with "COMMAND ROOM STANDING BY" hero text. Active state (compact status strip driven by `active-session.json`) is deferred to Phase 2/3 where the state file writers will be implemented.

- [ ] **Step 1: Create HeroZone.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    accentHeader: false
    showHeader: false

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            text: "READY"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 2.0
            font.family: Appearance.font.family.monospace
            color: Appearance.mission.colTextMuted
        }

        Flow {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: "COMMAND ROOM "
                font.pixelSize: 28
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colText
            }

            StyledText {
                text: "STANDING BY"
                font.pixelSize: 28
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colAccent
            }
        }

        StyledText {
            text: "ALL SYSTEMS NOMINAL · AWAITING OPERATOR INPUT"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
            font.family: Appearance.font.family.monospace
            color: Appearance.mission.colTextFaint
        }
    }
}
```

- [ ] **Step 2: Register in qmldir**

Add to `modules/dashboard/qmldir`:

```
HeroZone 1.0 HeroZone.qml
```

- [ ] **Step 3: Verify hot-reload**

Save the file and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No QML errors. Component registered but not instantiated yet.

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/HeroZone.qml modules/dashboard/qmldir
git commit -m "dashboard: add HeroZone idle-state card (active state deferred to Phase 2)"
```

---

### Task 8: Restructure DashboardContent.qml center column

**Files:**
- Modify: `modules/dashboard/DashboardContent.qml:80-135`

The center column currently stacks: PerformanceBarsCard → NetworkSparklinesCard → ActivityConsoleCard → agent cards. In the command preset, it becomes: PerformanceBarcodeCard → HeroZone → (Activity side-by-side with Widget Stack) → IntegrationStatus placeholder. The widget stack is empty in Phase 1 with a "SUBSYSTEMS OFFLINE" placeholder. Activity stretches to fill if the widget stack is empty.

- [ ] **Step 1: Add preset and section properties**

At the top of DashboardContent.qml, after the existing section properties (around line 35), add:

```qml
    readonly property bool commandPreset: Appearance.mission.commandPreset
    readonly property bool sectionHeroZone: commandPreset
        && (Config.options?.dashboard?.sections?.heroZone ?? true)
```

- [ ] **Step 2: Restructure center column content**

Replace the center column ColumnLayout content (lines 89-134) with:

```qml
            ColumnLayout {
                id: centerColumn
                width: parent.width
                spacing: 12

                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 270
                    active: root.sectionPerformance && !root.commandPreset
                    visible: active
                    sourceComponent: PerformanceBarsCard {}
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.sectionPerformance && root.commandPreset
                    visible: active
                    sourceComponent: PerformanceBarcodeCard {}
                }

                NetworkSparklinesCard {
                    Layout.fillWidth: true
                    visible: root.sectionPerformance && !root.commandPreset
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.sectionHeroZone
                    visible: active
                    sourceComponent: HeroZone {}
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: root.commandPreset
                    spacing: 12
                    visible: root.sectionActivityConsole || root.commandPreset

                    ActivityConsoleCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.commandPreset ? -1 : (
                            (root.sectionAgentContext || root.sectionAgentLoop || root.sectionAgentTrust) ? 260 : 340
                        )
                        Layout.fillHeight: root.commandPreset
                        visible: root.sectionActivityConsole
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 280
                        Layout.fillHeight: true
                        visible: root.commandPreset
                        spacing: 8

                        DashboardCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            headerText: "Subsystems"

                            StyledText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignCenter
                                text: "SUBSYSTEMS OFFLINE"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.5
                                font.family: Appearance.font.family.monospace
                                color: Qt.rgba(Appearance.mission.colText.r,
                                               Appearance.mission.colText.g,
                                               Appearance.mission.colText.b, 0.15)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.sectionAgentContext && !root.commandPreset
                    visible: active
                    sourceComponent: AgentContextCard {}
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.sectionAgentLoop && !root.commandPreset
                    visible: active
                    sourceComponent: AgentLoopCard {}
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.sectionAgentTrust && !root.commandPreset
                    visible: active
                    sourceComponent: AgentTrustCard {}
                }
            }
```

**Important:** This replaces ONLY the `ColumnLayout { id: centerColumn ... }` block inside the center Flickable, not the Flickable itself. The surrounding `Flickable { Layout.fillWidth: true ... }` wrapper remains unchanged.

- [ ] **Step 3: Verify the default preset is unchanged**

With `stylePreset: "default"` (the default), the center column should render identically to before: PerformanceBarsCard → NetworkSparklinesCard → ActivityConsoleCard → agent cards. The Loaders for command-specific components should be `active: false`.

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No QML errors. Dashboard opens and looks identical to before.

- [ ] **Step 4: Test command preset**

Temporarily edit `defaults/config.json` to set `"stylePreset": "command"`. Open the dashboard. Expected:
- PerformanceBarcodeCard visible (horizontal barcode meters)
- PerformanceBarsCard hidden
- HeroZone visible with "COMMAND ROOM STANDING BY"
- Activity + widget stack side-by-side (widget stack showing "SUBSYSTEMS OFFLINE")
- NetworkSparklinesCard hidden
- Card radius visibly tighter (6px vs 18px)

Then revert `stylePreset` back to `"default"`.

- [ ] **Step 5: Commit**

```bash
git add modules/dashboard/DashboardContent.qml
git commit -m "dashboard: restructure center column with preset-aware layout"
```

---

### Task 9: Create BarcodeMiniMeters.qml for bar

**Files:**
- Create: `modules/bar/BarcodeMiniMeters.qml`

Inline barcode meters for the bar, parallel to MiniRings. Uses BarcodeMeter with `variant: "inline"`. Same data sources and warning thresholds as MiniRings. Must degrade gracefully at narrow widths.

- [ ] **Step 1: Create BarcodeMiniMeters.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    Component.onCompleted: ResourceUsage.ensureRunning()

    readonly property real _availWidth: width
    readonly property string _layout: _availWidth >= 320 ? "full"
        : _availWidth >= 200 ? "compact"
        : "stacked"

    implicitWidth: _layout === "stacked" ? 160 : (_layout === "compact" ? 240 : 340)
    implicitHeight: _layout === "stacked" ? 48 : 24

    Loader {
        anchors.fill: parent
        active: root._layout === "full" || root._layout === "compact"
        visible: active

        sourceComponent: RowLayout {
            spacing: root._layout === "full" ? 10 : 6

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.cpu ?? true
                value: ResourceUsage.cpuUsage
                label: "CPU"
                color: Appearance.colors.colPrimary
                variant: "inline"
                showLabel: root._layout === "full"
                inlineTrackWidth: root._layout === "full" ? 48 : 32
                cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
                warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
            }

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.gpu ?? true
                value: ResourceUsage.gpuUsage
                label: "GPU"
                color: Appearance.colors.colSecondary
                variant: "inline"
                showLabel: root._layout === "full"
                inlineTrackWidth: root._layout === "full" ? 48 : 32
                cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
                warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
            }

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.temp ?? true
                value: Math.min(ResourceUsage.cpuTemp / 100, 1.0)
                label: "TMP"
                color: Appearance.colors.colError
                variant: "inline"
                showLabel: root._layout === "full"
                inlineTrackWidth: root._layout === "full" ? 48 : 32
                cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
                warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
            }

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.ram ?? true
                value: ResourceUsage.memoryUsedPercentage
                label: "RAM"
                color: Appearance.colors.colTertiary
                variant: "inline"
                showLabel: root._layout === "full"
                inlineTrackWidth: root._layout === "full" ? 48 : 32
                cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
                warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root._layout === "stacked"
        visible: active

        sourceComponent: GridLayout {
            columns: 2
            rowSpacing: 4
            columnSpacing: 8

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.cpu ?? true
                value: ResourceUsage.cpuUsage
                label: "CPU"
                color: Appearance.colors.colPrimary
                variant: "inline"
                showLabel: false
                inlineTrackWidth: 32
                cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
                warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
            }

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.gpu ?? true
                value: ResourceUsage.gpuUsage
                label: "GPU"
                color: Appearance.colors.colSecondary
                variant: "inline"
                showLabel: false
                inlineTrackWidth: 32
                cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
                warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
            }

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.temp ?? true
                value: Math.min(ResourceUsage.cpuTemp / 100, 1.0)
                label: "TMP"
                color: Appearance.colors.colError
                variant: "inline"
                showLabel: false
                inlineTrackWidth: 32
                cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
                warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
            }

            BarcodeMeter {
                visible: Config.options?.bar?.rings?.ram ?? true
                value: ResourceUsage.memoryUsedPercentage
                label: "RAM"
                color: Appearance.colors.colTertiary
                variant: "inline"
                showLabel: false
                inlineTrackWidth: 32
                cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
                warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
            }
        }
    }
}
```

- [ ] **Step 2: Verify hot-reload**

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

Expected: No QML errors.

- [ ] **Step 3: Commit**

```bash
git add modules/bar/BarcodeMiniMeters.qml
git commit -m "bar: add BarcodeMiniMeters with adaptive sizing breakpoints"
```

---

### Task 10: Wire BarcodeMiniMeters into BarContent.qml

**Files:**
- Modify: `modules/bar/BarContent.qml:1082-1091`

Currently the MiniRings Loader at line 1082 is unconditional (when `showRingsLaneItem` is true). Add a config check to swap between MiniRings and BarcodeMiniMeters based on `bar.rings.variant`.

- [ ] **Step 1: Add variant property**

Find the `showRingsLaneItem` property (around line 141):

```qml
    readonly property bool showRingsLaneItem: showAmbientLane
        && (Config.options?.bar?.modules?.resources ?? true)
```

After it, add:

```qml
    readonly property string ringsVariant: {
        const v = String(Config.options?.bar?.rings?.variant ?? "arc").toLowerCase()
        return v === "barcode" ? "barcode" : "arc"
    }
```

- [ ] **Step 2: Replace the MiniRings Loader**

Find lines 1082-1091:
```qml
            Loader {
                active: root.showRingsLaneItem
                visible: active
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                sourceComponent: BarGroup {
                    padding: root.ambientClusterPadding
                    MiniRings {}
                }
            }
```

Replace with:
```qml
            Loader {
                active: root.showRingsLaneItem && root.ringsVariant === "arc"
                visible: active
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                sourceComponent: BarGroup {
                    padding: root.ambientClusterPadding
                    MiniRings {}
                }
            }

            Loader {
                active: root.showRingsLaneItem && root.ringsVariant === "barcode"
                visible: active
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                sourceComponent: BarGroup {
                    padding: root.ambientClusterPadding
                    BarcodeMiniMeters {}
                }
            }
```

- [ ] **Step 3: Add import for bar module if needed**

Check if `BarcodeMiniMeters` is accessible from `BarContent.qml`. Since both are in `modules/bar/` and bar modules use file-relative resolution (no qmldir), the type should be automatically available. Verify:

Run: `head -10 modules/bar/BarContent.qml` to check existing imports.

If `BarcodeMiniMeters` is not resolved, the file is in the same directory as BarContent.qml so it should be auto-discovered. If errors appear, add an explicit `import qs.modules.common.widgets` at the top of BarContent.qml.

- [ ] **Step 4: Test with `variant: "arc"` (default)**

With `bar.rings.variant` set to `"arc"` (default), the bar should show the existing MiniRings. No visual change expected.

Save and open the dashboard to trigger hot-reload. Quickshell logs to its own stdout (not journalctl) — check for QML errors in the terminal where qs was started, or visually confirm no crash.

- [ ] **Step 5: Test with `variant: "barcode"`**

Temporarily edit `defaults/config.json` to set `"variant": "barcode"` under `bar.rings`. Expected: bar shows inline barcode meters instead of arc rings. Then revert.

- [ ] **Step 6: Commit**

```bash
git add modules/bar/BarContent.qml
git commit -m "bar: wire BarcodeMiniMeters loader conditional on rings.variant"
```

---

### Task 11: End-to-end verification

**Files:** None (verification only)

- [ ] **Step 1: Set command preset in config**

Edit `defaults/config.json`:
- `"stylePreset": "command"`
- `"heroZone": true` in sections
- `"variant": "barcode"` in bar.rings

- [ ] **Step 2: Open dashboard and verify all Phase 1 components**

Checklist:
1. Warm palette visible (background should be warm-black, not cool-gray)
2. Card radius is tight (6px, visibly angular vs the old 18px rounded)
3. Card padding is slightly tighter (16px vs 18px)
4. PerformanceBarcodeCard shows 4 horizontal barcode meter rows (CPU, GPU, RAM, VRAM) with temperature row below
5. HeroZone shows "COMMAND ROOM STANDING BY" (idle-only in Phase 1)
6. Activity console and widget stack are side-by-side. Widget stack shows "SUBSYSTEMS OFFLINE"
7. Left and right columns are unchanged (profile, system info, toggles, calendar, weather, notifications)
8. Bar shows inline barcode meters instead of arc rings

- [ ] **Step 3: Revert to default preset and verify no regression**

Set `"stylePreset": "default"`, `"variant": "arc"`, `"heroZone": false`. Dashboard should look identical to before the entire Phase 1 implementation. No visible changes.

- [ ] **Step 4: Revert config.json to ship state**

Set `"stylePreset": "default"` (ship default — user opts into command), `"heroZone": false`, `"variant": "arc"`. These are the safe defaults.

- [ ] **Step 5: Final commit with config**

```bash
git add defaults/config.json
git commit -m "config: finalize Phase 1 defaults (default preset, arc rings)"
```
