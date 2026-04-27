# Command Room Phase 2 — Operational Widgets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the six operational widget cards + two tile primitives + integration status bar to the Command Room dashboard, wired to dormant-state shells (no live data sources — that's Phase 3).

**Architecture:** Each card extends `DashboardCard`, uses Phase 1 primitives (`BarcodeMeter`, `StatusPill`), and shows a contextual dormant message when no data is available. Two new tile primitives (`AgentTile`, `RoutineTile`) live in `common/widgets/`. The center column gets restructured into Activity + WidgetStack side-by-side in command mode. Config keys gate every new widget independently.

**Tech Stack:** QML (Quickshell runtime), `Config.options?.` nullish coalescing, `Appearance.mission.*` semantic tokens, `ColorUtils.transparentize()`.

**Phase 2 = shells only.** No `Process` calls, no new service singletons, no `acquire()`/`release()` leases. Data plumbing is Phase 3.

**Verification:** No test suite — save → hot-reload → visually check. Three scenarios: (1) default preset, (2) command preset with new section toggles off, (3) command preset with toggles on.

---

### Task 1: AgentTile primitive

**Files:**
- Create: `modules/common/widgets/AgentTile.qml`
- Modify: `modules/common/widgets/qmldir` (add entry between `AddressBreadcrumb` and `AngelAccentBar`)

- [ ] **Step 1: Create AgentTile.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    property string name: ""
    property string initial: ""
    property string route: ""
    property string lastActive: ""
    property string status: "idle"

    implicitHeight: tileRow.implicitHeight + 20
    implicitWidth: 200

    RowLayout {
        id: tileRow
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 10

        Rectangle {
            width: 28
            height: 28
            radius: 4
            color: ColorUtils.transparentize(Appearance.mission.colText, 0.94)

            StyledText {
                anchors.centerIn: parent
                text: root.initial
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: ColorUtils.transparentize(Appearance.mission.colText, 0.5)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: root.name
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.family: Appearance.font.family.monospace
                font.letterSpacing: 1.0
                color: Appearance.m3colors.m3onBackground
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            StyledText {
                text: root.route + (root.lastActive ? " · " + root.lastActive : "")
                font.pixelSize: 10
                font.family: Appearance.font.family.monospace
                color: ColorUtils.transparentize(Appearance.mission.colText, 0.75)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        StatusPill {
            status: root.status
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.96)
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/common/widgets/qmldir`, add the following line between `AddressBreadcrumb 1.0 AddressBreadcrumb.qml` and `AngelAccentBar 1.0 AngelAccentBar.qml`:

```
AgentTile 1.0 AgentTile.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. Quickshell hot-reloads. No crash = success (AgentTile isn't rendered anywhere yet — just registered).

- [ ] **Step 4: Commit**

```bash
git add modules/common/widgets/AgentTile.qml modules/common/widgets/qmldir
git commit -m "widgets: add AgentTile primitive for agent status rows"
```

---

### Task 2: RoutineTile primitive

**Files:**
- Create: `modules/common/widgets/RoutineTile.qml`
- Modify: `modules/common/widgets/qmldir` (add entry between `RoundCorner` and `ScrollEdgeFade`)

- [ ] **Step 1: Create RoutineTile.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    property string timestamp: ""
    property string label: ""
    property string actionText: "OPEN"

    signal actionClicked()

    implicitHeight: tileRow.implicitHeight + 14
    implicitWidth: 200

    RowLayout {
        id: tileRow
        anchors.fill: parent
        anchors.topMargin: 7
        anchors.bottomMargin: 7
        spacing: 8

        StyledText {
            text: root.timestamp
            font.pixelSize: 10
            font.family: Appearance.font.family.monospace
            color: ColorUtils.transparentize(Appearance.mission.colText, 0.8)
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: root.label
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.family: Appearance.font.family.monospace
            font.letterSpacing: 0.8
            color: Appearance.m3colors.m3onBackground
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        StyledText {
            text: root.actionText + " ↗"
            font.pixelSize: 10
            font.family: Appearance.font.family.monospace
            color: ColorUtils.transparentize(Appearance.mission.colText, 0.8)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionClicked()
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.96)
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/common/widgets/qmldir`, add the following line between `RoundCorner 1.0 RoundCorner.qml` and `ScrollEdgeFade 1.0 ScrollEdgeFade.qml`:

```
RoutineTile 1.0 RoutineTile.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. No crash = success.

- [ ] **Step 4: Commit**

```bash
git add modules/common/widgets/RoutineTile.qml modules/common/widgets/qmldir
git commit -m "widgets: add RoutineTile primitive for timestamped run rows"
```

---

### Task 3: AgentStatusCard

**Files:**
- Create: `modules/dashboard/AgentStatusCard.qml`
- Modify: `modules/dashboard/qmldir` (append after `HeroZone`)

- [ ] **Step 1: Create AgentStatusCard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Agents"
    accentHeader: true

    readonly property var agents: Config.options?.dashboard?.agentStatus?.agents ?? []
    readonly property bool hasData: agents.length > 0

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.hasData

        Repeater {
            model: root.agents

            AgentTile {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                name: modelData.name ?? ""
                initial: modelData.initial ?? ""
                route: modelData.domain ?? ""
                lastActive: ""
                status: "idle"
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "AWAITING AGENT ACTIVITY"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 16
        bottomPadding: 16
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/dashboard/qmldir`, append after `HeroZone 1.0 HeroZone.qml`:

```
AgentStatusCard 1.0 AgentStatusCard.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. No crash = success (not rendered yet — will be wired in Task 10).

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/AgentStatusCard.qml modules/dashboard/qmldir
git commit -m "dashboard: add AgentStatusCard shell with dormant state"
```

---

### Task 4: ServiceGridCard

**Files:**
- Create: `modules/dashboard/ServiceGridCard.qml`
- Modify: `modules/dashboard/qmldir` (append after `AgentStatusCard`)

- [ ] **Step 1: Create ServiceGridCard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Services"

    readonly property var services: Config.options?.dashboard?.serviceGrid?.services ?? []
    readonly property bool hasData: services.length > 0

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.hasData

        Repeater {
            model: root.services

            Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 32

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Appearance.mission.colIdle
                    }

                    StyledText {
                        text: modelData.replace(".service", "").toUpperCase()
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                        font.family: Appearance.font.family.monospace
                        color: Appearance.m3colors.m3onBackground
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: "—"
                        font.pixelSize: 10
                        font.family: Appearance.font.family.monospace
                        color: ColorUtils.transparentize(Appearance.mission.colText, 0.8)
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: ColorUtils.transparentize(Appearance.mission.colText, 0.96)
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "CONFIGURE SERVICES IN CONFIG"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 16
        bottomPadding: 16
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/dashboard/qmldir`, append after the `AgentStatusCard` entry:

```
ServiceGridCard 1.0 ServiceGridCard.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. No crash = success.

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/ServiceGridCard.qml modules/dashboard/qmldir
git commit -m "dashboard: add ServiceGridCard shell with dormant state"
```

---

### Task 5: DiskGaugesCard

**Files:**
- Create: `modules/dashboard/DiskGaugesCard.qml`
- Modify: `modules/dashboard/qmldir` (append after `ServiceGridCard`)

- [ ] **Step 1: Create DiskGaugesCard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Storage"

    readonly property var mounts: Config.options?.dashboard?.diskGauges?.mounts ?? []
    readonly property bool hasData: mounts.length > 0

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: root.hasData

        Repeater {
            model: root.mounts

            BarcodeMeter {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                value: 0
                label: modelData
                color: Appearance.colors.colTertiary
                variant: "block"
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "CONFIGURE MOUNTS IN CONFIG"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 16
        bottomPadding: 16
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/dashboard/qmldir`, append after the `ServiceGridCard` entry:

```
DiskGaugesCard 1.0 DiskGaugesCard.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. No crash = success.

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/DiskGaugesCard.qml modules/dashboard/qmldir
git commit -m "dashboard: add DiskGaugesCard shell with dormant state"
```

---

### Task 6: VaultPulseCard

**Files:**
- Create: `modules/dashboard/VaultPulseCard.qml`
- Modify: `modules/dashboard/qmldir` (append after `DiskGaugesCard`)

- [ ] **Step 1: Create VaultPulseCard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Vault"

    readonly property string vaultPath: Config.options?.dashboard?.vaultPulse?.vaultPath ?? ""
    readonly property bool hasData: vaultPath.length > 0

    function statRow(label, value) {
        return { label: label, value: value }
    }

    readonly property var stats: [
        statRow("TOTAL NOTES", "—"),
        statRow("EDITED TODAY", "—"),
        statRow("INBOX", "—"),
        statRow("ORPHANS", "—")
    ]

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 10
        columnSpacing: 12
        visible: root.hasData

        Repeater {
            model: root.stats

            Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: statCol.implicitHeight

                ColumnLayout {
                    id: statCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 2

                    StyledText {
                        text: modelData.value
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.m3colors.m3onBackground
                    }

                    StyledText {
                        text: modelData.label
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        font.family: Appearance.font.family.monospace
                        color: Appearance.mission.colTextMuted
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "VAULT PATH NOT SET"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 16
        bottomPadding: 16
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/dashboard/qmldir`, append after the `DiskGaugesCard` entry:

```
VaultPulseCard 1.0 VaultPulseCard.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. No crash = success.

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/VaultPulseCard.qml modules/dashboard/qmldir
git commit -m "dashboard: add VaultPulseCard shell with dormant state"
```

---

### Task 7: RecentRunsCard

**Files:**
- Create: `modules/dashboard/RecentRunsCard.qml`
- Modify: `modules/dashboard/qmldir` (append after `VaultPulseCard`)

- [ ] **Step 1: Create RecentRunsCard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Recent Runs"

    readonly property bool hasData: false

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.hasData

        Repeater {
            model: []

            RoutineTile {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                timestamp: modelData.timestamp ?? ""
                label: modelData.label ?? ""
                actionText: "OPEN"
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "NO RUNS RECORDED"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 16
        bottomPadding: 16
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/dashboard/qmldir`, append after the `VaultPulseCard` entry:

```
RecentRunsCard 1.0 RecentRunsCard.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. No crash = success.

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/RecentRunsCard.qml modules/dashboard/qmldir
git commit -m "dashboard: add RecentRunsCard shell with dormant state"
```

---

### Task 8: IntegrationStatusBar

**Files:**
- Create: `modules/dashboard/IntegrationStatusBar.qml`
- Modify: `modules/dashboard/qmldir` (append after `RecentRunsCard`)

- [ ] **Step 1: Create IntegrationStatusBar.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    showHeader: false

    readonly property var integrations: Config.options?.dashboard?.integrations ?? []
    readonly property bool hasData: integrations.length > 0

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        visible: root.hasData

        StyledText {
            text: "INTEGRATIONS"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            font.family: Appearance.font.family.monospace
            color: Appearance.mission.colAccentMuted
        }

        Rectangle {
            width: 1
            Layout.fillHeight: true
            color: Appearance.mission.colGrid
        }

        Flow {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: root.integrations

                Row {
                    required property var modelData
                    required property int index
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Appearance.mission.colIdle
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: modelData.name ?? ""
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        font.family: Appearance.font.family.monospace
                        color: Appearance.mission.colTextMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "NO INTEGRATIONS CONFIGURED"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 8
        bottomPadding: 8
    }
}
```

- [ ] **Step 2: Add qmldir entry**

In `modules/dashboard/qmldir`, append after the `RecentRunsCard` entry:

```
IntegrationStatusBar 1.0 IntegrationStatusBar.qml
```

- [ ] **Step 3: Verify via hot-reload**

Save both files. No crash = success.

- [ ] **Step 4: Commit**

```bash
git add modules/dashboard/IntegrationStatusBar.qml modules/dashboard/qmldir
git commit -m "dashboard: add IntegrationStatusBar shell with dormant state"
```

---

### Task 9: Config keys

**Files:**
- Modify: `defaults/config.json` (add new keys under `dashboard`)

- [ ] **Step 1: Add section toggles**

In `defaults/config.json`, inside `"dashboard" > "sections"` (after `"heroZone": false`), add:

```json
      "agentStatus": false,
      "serviceGrid": false,
      "diskGauges": false,
      "vaultPulse": false,
      "recentRuns": false,
      "integrationStatus": false
```

- [ ] **Step 2: Add widget config objects**

In `defaults/config.json`, inside `"dashboard"` (after the `"activityConsole"` block which ends around line 662), add the following new config objects:

```json
    "serviceGrid": {
      "services": [
        "syncthing.service",
        "claude-proxy.service",
        "dictation-server.service",
        "pipewire.service",
        "bluetooth.service"
      ],
      "pollIntervalSec": 30
    },
    "diskGauges": {
      "mounts": ["/", "/home"],
      "pollIntervalSec": 60
    },
    "vaultPulse": {
      "vaultPath": "",
      "inboxPath": "00 Inbox/",
      "countOrphans": true
    },
    "integrations": [
      { "name": "GITHUB", "check": "none" },
      { "name": "GMAIL", "check": "none" },
      { "name": "GOOGLE CALENDAR", "check": "none" },
      { "name": "SYNCTHING", "check": "none" },
      { "name": "TELEGRAM", "check": "none" }
    ],
    "agentStatus": {
      "agents": [
        { "name": "ALFRED", "initial": "A", "domain": "system ops" },
        { "name": "ORACLE", "initial": "O", "domain": "portfolio" },
        { "name": "HERMES", "initial": "H", "domain": "messenger" },
        { "name": "ELSA", "initial": "E", "domain": "inir ux" }
      ]
    },
```

- [ ] **Step 3: Verify JSON validity**

Run: `python3 -c "import json; json.load(open('defaults/config.json'))"`

Expected: No output (valid JSON).

- [ ] **Step 4: Commit**

```bash
git add defaults/config.json
git commit -m "config: add Phase 2 widget section toggles and config objects"
```

---

### Task 10: DashboardContent restructure

This is the riskiest task — it restructures the center column and adds AgentStatusCard to the left column.

**Files:**
- Modify: `modules/dashboard/DashboardContent.qml`

**Context:** The current file is 267 lines. The center column (lines 85-153) is a single `ColumnLayout` inside a `Flickable`. In command mode, it needs to become: Performance → HeroZone → [Activity | WidgetStack(280px)] side-by-side → IntegrationStatusBar. The left column (lines 47-79) needs AgentStatusCard between QuickToggles and Media.

- [ ] **Step 1: Add new section toggle properties**

In `DashboardContent.qml`, after the existing `sectionHeroZone` property (currently the last property around line 38), add:

```qml
    readonly property bool sectionAgentStatus: commandPreset
        && (Config.options?.dashboard?.sections?.agentStatus ?? false)
    readonly property bool sectionServiceGrid: commandPreset
        && (Config.options?.dashboard?.sections?.serviceGrid ?? false)
    readonly property bool sectionDiskGauges: commandPreset
        && (Config.options?.dashboard?.sections?.diskGauges ?? false)
    readonly property bool sectionVaultPulse: commandPreset
        && (Config.options?.dashboard?.sections?.vaultPulse ?? false)
    readonly property bool sectionRecentRuns: commandPreset
        && (Config.options?.dashboard?.sections?.recentRuns ?? false)
    readonly property bool sectionIntegrationStatus: commandPreset
        && (Config.options?.dashboard?.sections?.integrationStatus ?? false)
    readonly property bool _anyWidgetStackVisible: sectionServiceGrid
        || sectionDiskGauges || sectionVaultPulse || sectionRecentRuns
```

- [ ] **Step 2: Add AgentStatusCard to left column**

In the left column `ColumnLayout` (id: `leftColumn`), add between `QuickTogglesCard` and `MediaCard`:

```qml
                Loader {
                    Layout.fillWidth: true
                    active: root.sectionAgentStatus
                    visible: active
                    sourceComponent: AgentStatusCard {}
                }
```

- [ ] **Step 3: Restructure center column**

Replace the entire center column `Flickable` (from the second `Flickable {` with `Layout.fillWidth: true` through its closing brace) with:

```qml
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: centerColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

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
                    Layout.preferredHeight: root.commandPreset ? -1 : (
                        (root.sectionAgentContext || root.sectionAgentLoop || root.sectionAgentTrust) ? 260 : 340
                    )
                    spacing: 12
                    visible: root.sectionActivityConsole || root._anyWidgetStackVisible

                    ActivityConsoleCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.sectionActivityConsole
                    }

                    Flickable {
                        Layout.preferredWidth: 280
                        Layout.fillHeight: true
                        contentHeight: widgetStack.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        visible: root._anyWidgetStackVisible

                        ColumnLayout {
                            id: widgetStack
                            width: parent.width
                            spacing: 12

                            Loader {
                                Layout.fillWidth: true
                                active: root.sectionServiceGrid
                                visible: active
                                sourceComponent: ServiceGridCard {}
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: root.sectionDiskGauges
                                visible: active
                                sourceComponent: DiskGaugesCard {}
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: root.sectionVaultPulse
                                visible: active
                                sourceComponent: VaultPulseCard {}
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: root.sectionRecentRuns
                                visible: active
                                sourceComponent: RecentRunsCard {}
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.sectionIntegrationStatus
                    visible: active
                    sourceComponent: IntegrationStatusBar {}
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
        }
```

Key changes from the current center column:
- ActivityConsoleCard moves into a `RowLayout` alongside the WidgetStack
- The `RowLayout` inherits Activity's existing layout behavior (`fillHeight` in command, `preferredHeight` in default)
- WidgetStack is a `Flickable(280px)` containing `ServiceGridCard`, `DiskGaugesCard`, `VaultPulseCard`, `RecentRunsCard`
- WidgetStack only visible when at least one section is enabled (`_anyWidgetStackVisible`)
- `IntegrationStatusBar` sits below the Activity+WidgetStack row as a full-width element
- Existing default-mode cards (`AgentContextCard`, `AgentLoopCard`, `AgentTrustCard`) remain gated by `!commandPreset`

- [ ] **Step 4: Verify via hot-reload**

Save the file. Quickshell hot-reloads. Check that the dashboard opens without crash in current preset mode.

- [ ] **Step 5: Commit**

```bash
git add modules/dashboard/DashboardContent.qml
git commit -m "dashboard: restructure center column for Activity + WidgetStack layout"
```

---

### Task 11: Visual verification matrix

Three scenarios to verify. No code changes — visual check only.

- [ ] **Step 1: Verify default preset (regression check)**

With config at `stylePreset: "default"` and all new section toggles `false`:

1. Open the dashboard
2. Confirm: three-column layout unchanged, no new cards visible, no crashes
3. Confirm: Performance bars (not barcode), NetworkSparklines, no HeroZone
4. Confirm: ActivityConsoleCard full width (no widget stack visible)

Expected: Identical to pre-Phase-2 default layout.

- [ ] **Step 2: Verify command preset with new toggles OFF**

Set `stylePreset: "command"`, keep all new section toggles at `false`:

1. Open the dashboard
2. Confirm: PerformanceBarcodeCard, HeroZone visible
3. Confirm: No AgentStatusCard in left column, no widget stack, no IntegrationStatusBar
4. Confirm: ActivityConsoleCard fills available height (no sibling widget stack)

Expected: Identical to Phase 1 command layout.

- [ ] **Step 3: Verify command preset with new toggles ON**

Set `stylePreset: "command"`, set all new section toggles to `true`:

1. Open the dashboard
2. Confirm: AgentStatusCard appears in left column between QuickToggles and Media
3. Confirm: AgentStatusCard shows 4 agent tiles from config (ALFRED, ORACLE, HERMES, ELSA) with "idle" status
4. Confirm: Widget stack appears to the right of ActivityConsoleCard at 280px width
5. Confirm: ServiceGridCard shows 5 service rows from config with idle dots and "—" status
6. Confirm: DiskGaugesCard shows 2 barcode meters at 0% for "/" and "/home"
7. Confirm: VaultPulseCard shows dormant "VAULT PATH NOT SET" (because `vaultPath` defaults to `""`)
8. Confirm: RecentRunsCard shows dormant "NO RUNS RECORDED"
9. Confirm: IntegrationStatusBar appears full-width below Activity+WidgetStack, showing 5 integration dots

Expected: Full command layout with all Phase 2 shells visible, dormant-state messages where data isn't configured.

- [ ] **Step 4: Revert config to defaults**

Reset `stylePreset` to `"default"`, all new toggles back to `false`. Confirm zero regression.
