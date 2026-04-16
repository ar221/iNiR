# Command Center Dashboard (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Command Center Dashboard — a full-screen overlay that flies in from the top when `GlobalStates.dashboardOpen` toggles true (wired in Phase 1 via monogram click). Three-column layout with identity/controls on the left, placeholder center for Phase 3 perf bars, and calendar/weather/notifications on the right.

**Architecture:** A new `modules/dashboard/` directory houses the overlay and all card components. `Dashboard.qml` is a `PanelWindow` anchored to all screen edges (full-screen overlay pattern from SidebarShell.qml), with a dimmed scrim backdrop, fly-from-top entry animation, and click-outside dismiss. `DashboardContent.qml` arranges cards in a three-column `RowLayout`. Each card is a self-contained component using a shared `DashboardCard.qml` base for consistent styling. Config keys register under a top-level `dashboard` JsonObject in Config.qml (sibling of `bar`, NOT nested under it). The dashboard loads in `shell.qml` via `LazyLoader` — it's compositor-agnostic and panel-family-agnostic (works in both Material ii and Waffle).

**Tech Stack:** QML (Qt 6), Quickshell framework, Quickshell.Wayland (PanelWindow + WlrLayershell), Quickshell.Io (Process for system info), Qt5Compat.GraphicalEffects (LinearGradient for avatar)

**Spec:** `docs/superpowers/specs/2026-04-16-bar-dashboard-redesign.md` — Part 2 (Command Center Dashboard).

---

## Visual Primitives: CSS → QML Mapping

| Spec (CSS) | QML Equivalent |
|---|---|
| `rgba(14,14,26,0.96)` container bg with `backdrop-filter: blur(30px)` | `Rectangle { color: Qt.rgba(0.055, 0.055, 0.102, 0.96) }` — blur handled by Quickshell panel layer |
| `rgba(255,255,255,0.025)` card bg | `Rectangle { color: Qt.rgba(1, 1, 1, 0.025) }` |
| `1px rgba(255,255,255,0.04)` card border | `border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.04)` |
| `border-radius: 16px` card | `radius: 16` |
| `border-radius: 24px` container | `radius: 24` |
| `rgba(0,0,0,0.45)` backdrop dim | Modal scrim Rectangle with `opacity: 0.45` and `color: Appearance.m3colors.m3scrim` |
| `linear-gradient(135deg, #fb923c, #f472b6)` avatar | `LinearGradient` from Qt5Compat.GraphicalEffects with `start: Qt.point(0, 0); end: Qt.point(width, height)` |
| `box-shadow: 0 24px 80px rgba(...)` container | `StyledRectangularShadow` (existing component) |
| `grid-template-columns: 260px 1fr 240px` | `RowLayout` with `Layout.preferredWidth: 260`, `Layout.fillWidth: true`, `Layout.preferredWidth: 240` |
| Gradient text on hero date | Solid `Appearance.colors.colPrimary` (QML has no native gradient text fill — use themed color) |
| Fly-in from top | Translate Y from `-height` to `0` + opacity `0→1` with `Appearance.animationCurves.emphasizedDecel` |

---

## Implementation Notes

**Service property names (verified from DashboardTab.qml and service singletons):**
- Weather: `Weather.enabled`, `Weather.data?.temp`, `Weather.data?.city`, `Weather.data?.humidity`, `Weather.data?.windSpeed`, `Weather.data?.tempFeelsLike`, `Weather.data?.wCode`, `Weather.isNightNow()`
- Media: `MprisController.activePlayer?.trackTitle`, `.trackArtist`, `.trackArtUrl`, `.isPlaying`, `.togglePlaying()`, `.next()`, `.previous()`, `.canGoNext`, `.canGoPrevious`
- Resources: `ResourceUsage.cpuUsage`, `.memoryUsedPercentage`, `.gpuUsage`, `.cpuTemp`, `.gpuTemp`, `.maxTemp`, `.diskUsedPercentage`
- DateTime: `DateTime.uptime`, `DateTime.clock.date`
- Notifications: `Notifications.list` — each entry has `.summary`, `.body`, `.appName`, `.appIcon`, `.image`, `.time`
- Events: `Events.list`
- Network: `Network.networkName`, `Network.materialSymbol`, `Network.wifiStatus`, `Network.toggleWifi()`
- Bluetooth: `BluetoothStatus.enabled`, `.connected`, `.available`

**Toggle substitution:** The spec lists "Screen Cast" as the sixth toggle, but no `ScreenCastToggle.qml` model exists in the codebase. Substitute Night Light (`NightLightToggle.qml` / `Hyprsunset` service) — same utility-toggle feel, already implemented. The toggle list in the plan's config is user-configurable, so if screen cast gets added later, users can swap it in.

**`GlobalStates.dashboardOpen` already exists.** Phase 1 added both the property (line 27) and the overlay-closing handler (lines 145-152). Do NOT re-add.

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| **Create** | `modules/dashboard/DashboardCard.qml` | Reusable card container (shared background, border, padding, header) |
| **Create** | `modules/dashboard/ProfileCard.qml` | Avatar + name + subtitle |
| **Create** | `modules/dashboard/SystemInfoCard.qml` | Neofetch-style key-value system info (Process invocations) |
| **Create** | `modules/dashboard/QuickTogglesCard.qml` | 3-column toggle grid with service bindings |
| **Create** | `modules/dashboard/MediaCard.qml` | Album art + track info + playback controls |
| **Create** | `modules/dashboard/CalendarCard.qml` | Hero date + mini calendar + upcoming events |
| **Create** | `modules/dashboard/WeatherCard.qml` | Weather icon + temp + details |
| **Create** | `modules/dashboard/NotificationsCard.qml` | Scrollable notification list |
| **Create** | `modules/dashboard/DashboardContent.qml` | Three-column layout assembling all cards |
| **Create** | `modules/dashboard/Dashboard.qml` | PanelWindow overlay + scrim + animation + IPC |
| **Modify** | `modules/common/Config.qml` | Register `dashboard` JsonObject config keys |
| **Modify** | `shell.qml` | Load Dashboard via LazyLoader |

---

## Tasks

### Task 1: Register Dashboard Config Keys

**Files:**
- Modify: `modules/common/Config.qml` (~line 869, after the `bar` JsonObject block)

- [ ] **Step 1: Add dashboard config keys**

In `modules/common/Config.qml`, find the end of the `property JsonObject bar: JsonObject { ... }` block (around line 869). Add a new top-level `dashboard` JsonObject immediately after it:

```qml
property JsonObject dashboard: JsonObject {
    property bool enable: true
    property int animationDuration: 350
    property string animationType: "flyFromTop"
    property JsonObject backdrop: JsonObject {
        property real dimOpacity: 0.45
    }
    property JsonObject sections: JsonObject {
        property bool profile: true
        property bool systemInfo: true
        property bool quickToggles: true
        property bool media: true
        property bool performance: true
        property bool sparklines: true
        property bool activityConsole: true
        property bool calendar: true
        property bool weather: true
        property bool notifications: true
    }
    property JsonObject profile: JsonObject {
        property string displayName: ""
        property string subtitle: "{user}@{hostname} · {wm} · {shell}"
        property string avatarPath: ""
    }
    property JsonObject quickToggles: JsonObject {
        property int columns: 3
        property list<string> toggles: ["dnd", "darkMode", "wifi", "powerProfile", "bluetooth", "nightLight"]
    }
    property JsonObject layout: JsonObject {
        property int leftColumnWidth: 260
        property int rightColumnWidth: 240
    }
}
```

- [ ] **Step 2: Verify hot-reload**

Save the file. Check that Quickshell doesn't crash:

```bash
qs log -c inir 2>&1 | tail -5
```

Verify the key is readable:

```bash
qs msg -c inir eval "Config.options?.dashboard?.enable"
```

Expected: `true`.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/common/Config.qml
git commit -m "dashboard: register config keys for Command Center"
```

---

### Task 2: Create DashboardCard.qml (Reusable Card Container)

**Files:**
- Create: `modules/dashboard/DashboardCard.qml`

- [ ] **Step 1: Create the modules/dashboard directory and DashboardCard.qml**

```bash
mkdir -p ~/Github/inir/modules/dashboard
```

Write `modules/dashboard/DashboardCard.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Shared card container for all dashboard cards.
// Provides consistent background, border, radius, padding, and optional header.
Rectangle {
    id: root

    property string headerText: ""
    property bool showHeader: headerText !== ""
    default property alias content: contentColumn.data

    color: Qt.rgba(1, 1, 1, 0.025)
    border.width: 1
    border.color: hoverHandler.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
    radius: 16

    Behavior on border.color {
        enabled: Appearance.animationsEnabled
        ColorAnimation { duration: 150 }
    }

    HoverHandler {
        id: hoverHandler
    }

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Section header (optional)
        StyledText {
            visible: root.showHeader
            text: root.headerText.toUpperCase()
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            color: Qt.rgba(1, 1, 1, 0.3)
            Layout.fillWidth: true
        }

        // Card content slot
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/DashboardCard.qml
git commit -m "dashboard: add DashboardCard reusable card container"
```

---

### Task 3: Create ProfileCard.qml

**Files:**
- Create: `modules/dashboard/ProfileCard.qml`

- [ ] **Step 1: Write ProfileCard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: ""

    // Config-driven profile data
    readonly property string displayName: {
        const configured = Config.options?.dashboard?.profile?.displayName ?? ""
        return configured !== "" ? configured : root._userName
    }
    readonly property string avatarPath: Config.options?.dashboard?.profile?.avatarPath ?? ""

    // System info for subtitle template
    property string _userName: "user"
    property string _hostName: "host"
    property string _wmName: "niri"
    property string _shellName: "fish"

    readonly property string subtitle: {
        const template = Config.options?.dashboard?.profile?.subtitle ?? "{user}@{hostname} · {wm} · {shell}"
        return template
            .replace("{user}", root._userName)
            .replace("{hostname}", root._hostName)
            .replace("{wm}", root._wmName)
            .replace("{shell}", root._shellName)
    }

    Process {
        id: userProc
        command: ["/usr/bin/whoami"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._userName = data.trim() } }
    }
    Process {
        id: hostProc
        command: ["/usr/bin/hostname"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._hostName = data.trim() } }
    }
    Process {
        id: wmProc
        command: ["/usr/bin/bash", "-c", "echo $XDG_CURRENT_DESKTOP"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._wmName = data.trim() || "niri" } }
    }
    Process {
        id: shellProc
        command: ["/usr/bin/bash", "-c", "basename $SHELL"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._shellName = data.trim() || "fish" } }
    }
    Component.onCompleted: {
        userProc.running = true
        hostProc.running = true
        wmProc.running = true
        shellProc.running = true
    }

    // ── Avatar ──
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        implicitWidth: 72
        implicitHeight: 72

        // Gradient background circle
        Rectangle {
            id: avatarBg
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            clip: true

            LinearGradient {
                anchors.fill: parent
                start: Qt.point(0, 0)
                end: Qt.point(parent.width, parent.height)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Appearance.colors.colPrimary }
                    GradientStop { position: 1.0; color: Appearance.colors.colTertiary }
                }
            }

            // Avatar image (overrides gradient when loaded)
            Image {
                id: avatarImage
                anchors.fill: parent
                source: root.avatarPath !== "" ? ("file://" + root.avatarPath) : "file:///home/" + root._userName + "/.face"
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            // Fallback monogram initials
            StyledText {
                anchors.centerIn: parent
                visible: avatarImage.status !== Image.Ready
                text: {
                    const name = root.displayName
                    if (name.length === 0) return "?"
                    const parts = name.split(" ")
                    if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
                    return name.substring(0, 2).toUpperCase()
                }
                font.pixelSize: 24
                font.weight: Font.Bold
                color: Qt.rgba(1, 1, 1, 0.9)
            }
        }

        // Outer glow
        RectangularGlow {
            anchors.fill: avatarBg
            glowRadius: 12
            spread: 0.1
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)
            cornerRadius: avatarBg.radius + glowRadius
        }
    }

    // ── Display name ──
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: root.displayName
        font.pixelSize: 18
        font.weight: Font.DemiBold
        color: Appearance.colors.colOnLayer0
    }

    // ── Subtitle ──
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: root.subtitle
        font.pixelSize: 11
        color: Qt.rgba(1, 1, 1, 0.35)
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/ProfileCard.qml
git commit -m "dashboard: add ProfileCard with avatar, name, and subtitle"
```

---

### Task 4: Create SystemInfoCard.qml

**Files:**
- Create: `modules/dashboard/SystemInfoCard.qml`

- [ ] **Step 1: Write SystemInfoCard.qml**

```qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "System"

    property string _osName: "..."
    property string _kernelVersion: "..."
    property string _packageCount: "..."
    property string _gpuName: "..."

    Process {
        id: osProc
        command: ["/usr/bin/bash", "-c", "grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '\"'"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._osName = data.trim() || "Linux" } }
    }
    Process {
        id: kernelProc
        command: ["/usr/bin/uname", "-r"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._kernelVersion = data.trim() } }
    }
    Process {
        id: pkgProc
        command: ["/usr/bin/bash", "-c", "pacman -Q 2>/dev/null | wc -l"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._packageCount = data.trim() } }
    }
    Process {
        id: gpuProc
        command: ["/usr/bin/bash", "-c", "lspci 2>/dev/null | grep -i 'vga\\|3d' | sed 's/.*: //' | head -1 | cut -c1-40"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._gpuName = data.trim() || "Unknown" } }
    }

    Component.onCompleted: {
        osProc.running = true
        kernelProc.running = true
        pkgProc.running = true
        gpuProc.running = true
    }

    // ── Key-value rows ──
    Repeater {
        model: [
            { label: "UPTIME", value: DateTime.uptime },
            { label: "KERNEL", value: root._kernelVersion },
            { label: "PACKAGES", value: root._packageCount },
            { label: "SHELL", value: "fish" },
            { label: "GPU", value: root._gpuName },
            { label: "WM", value: "niri" }
        ]

        ColumnLayout {
            id: infoRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 0

            // Separator (skip for first item)
            Rectangle {
                visible: infoRow.index > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.04)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                spacing: 8

                StyledText {
                    text: infoRow.modelData.label
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                    color: Qt.rgba(1, 1, 1, 0.3)
                    Layout.preferredWidth: 70
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: infoRow.modelData.value
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.7)
                    elide: Text.ElideRight
                    Layout.maximumWidth: 150
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/SystemInfoCard.qml
git commit -m "dashboard: add SystemInfoCard with neofetch-style key-value pairs"
```

---

### Task 5: Create QuickTogglesCard.qml

**Files:**
- Create: `modules/dashboard/QuickTogglesCard.qml`

- [ ] **Step 1: Write QuickTogglesCard.qml**

```qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "Quick Toggles"

    readonly property int columns: Config.options?.dashboard?.quickToggles?.columns ?? 3

    // Toggle definitions — each maps to an existing service action
    readonly property var toggleDefs: [
        {
            id: "dnd",
            label: "DND",
            icon: Notifications.silent ? "notifications_paused" : "notifications_active",
            toggled: Notifications.silent,
            action: () => { Notifications.silent = !Notifications.silent }
        },
        {
            id: "darkMode",
            label: "Dark Mode",
            icon: "contrast",
            toggled: Appearance.m3colors.darkmode,
            action: () => { MaterialThemeLoader.setDarkMode(!Appearance.m3colors.darkmode) }
        },
        {
            id: "wifi",
            label: "WiFi",
            icon: Network.materialSymbol,
            toggled: Network.wifiStatus !== "disabled",
            action: () => { Network.toggleWifi() }
        },
        {
            id: "powerProfile",
            label: "Power",
            icon: (() => {
                switch (PowerProfiles.profile) {
                    case PowerProfile.PowerSaver: return "energy_savings_leaf"
                    case PowerProfile.Performance: return "local_fire_department"
                    default: return "airwave"
                }
            })(),
            toggled: PowerProfiles.profile !== PowerProfile.Balanced,
            action: () => {
                if (PowerProfiles.hasPerformanceProfile) {
                    switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced; break
                        case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance; break
                        case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver; break
                    }
                } else {
                    PowerProfiles.profile = PowerProfiles.profile === PowerProfile.Balanced
                        ? PowerProfile.PowerSaver : PowerProfile.Balanced
                }
            }
        },
        {
            id: "bluetooth",
            label: "Bluetooth",
            icon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled",
            toggled: BluetoothStatus.enabled,
            action: () => {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
        },
        {
            id: "nightLight",
            label: "Night Light",
            icon: Hyprsunset.active ? "nightlight" : "nightlight_off",
            toggled: Hyprsunset.active,
            action: () => { Hyprsunset.toggle() }
        }
    ]

    // Filter toggles based on config
    readonly property var activeToggles: {
        const configured = Config.options?.dashboard?.quickToggles?.toggles ?? ["dnd", "darkMode", "wifi", "powerProfile", "bluetooth", "nightLight"]
        return root.toggleDefs.filter(t => configured.includes(t.id))
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.columns
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            model: root.activeToggles

            Rectangle {
                id: toggleBtn
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 12
                color: toggleBtn.modelData.toggled
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                    : Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: toggleBtn.modelData.toggled
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)
                    : Qt.rgba(1, 1, 1, 0.04)

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: 200 }
                }
                Behavior on border.color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: 200 }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: toggleBtn.modelData.icon
                        iconSize: 20
                        color: toggleBtn.modelData.toggled
                            ? Appearance.colors.colPrimary
                            : Qt.rgba(1, 1, 1, 0.45)
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: toggleBtn.modelData.label
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: toggleBtn.modelData.toggled
                            ? Appearance.colors.colPrimary
                            : Qt.rgba(1, 1, 1, 0.35)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleBtn.modelData.action()
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/QuickTogglesCard.qml
git commit -m "dashboard: add QuickTogglesCard with configurable toggle grid"
```

---

### Task 6: Create MediaCard.qml

**Files:**
- Create: `modules/dashboard/MediaCard.qml`

- [ ] **Step 1: Write MediaCard.qml**

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
    headerText: "Now Playing"

    // Only visible when a media player is active
    visible: MprisController.activePlayer !== null

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        // Album art thumbnail
        Rectangle {
            implicitWidth: 52
            implicitHeight: 52
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.5)
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: MprisController.activePlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: albumArt.status !== Image.Ready
                text: "album"
                iconSize: 28
                color: Appearance.colors.colSubtext
            }
        }

        // Track info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: MprisController.activePlayer?.trackTitle ?? "No media"
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: MprisController.activePlayer?.trackArtist ?? ""
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                visible: text !== ""
            }
        }
    }

    // ── Playback controls ──
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        spacing: 8

        RippleButton {
            implicitWidth: 32; implicitHeight: 32; buttonRadius: 16
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
            enabled: MprisController.canGoPrevious
            opacity: enabled ? 1.0 : 0.3
            onClicked: MprisController.activePlayer?.previous()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "skip_previous"
                iconSize: 20
                color: Appearance.colors.colOnLayer0
            }
        }

        RippleButton {
            implicitWidth: 40; implicitHeight: 40; buttonRadius: 20
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)
            enabled: MprisController.canTogglePlaying
            onClicked: MprisController.activePlayer?.togglePlaying()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: MprisController.isPlaying ? "pause" : "play_arrow"
                iconSize: 24
                color: Appearance.colors.colOnLayer0
            }
        }

        RippleButton {
            implicitWidth: 32; implicitHeight: 32; buttonRadius: 16
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
            enabled: MprisController.canGoNext
            opacity: enabled ? 1.0 : 0.3
            onClicked: MprisController.activePlayer?.next()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "skip_next"
                iconSize: 20
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/MediaCard.qml
git commit -m "dashboard: add MediaCard with album art and playback controls"
```

---

### Task 7: Create CalendarCard.qml

**Files:**
- Create: `modules/dashboard/CalendarCard.qml`

- [ ] **Step 1: Write CalendarCard.qml**

```qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: ""

    readonly property var locale: Qt.locale()
    readonly property date today: DateTime.clock.date

    // ── Hero date display ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // Large day number
        StyledText {
            text: root.today.getDate().toString()
            font.pixelSize: 42
            font.weight: Font.Bold
            font.family: Appearance.font.family.numbers
            color: Appearance.colors.colPrimary
        }

        ColumnLayout {
            Layout.fillHeight: true
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            StyledText {
                text: root.today.toLocaleDateString(root.locale, "MMMM").toUpperCase()
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
                color: Qt.rgba(1, 1, 1, 0.35)
            }

            StyledText {
                text: root.today.toLocaleDateString(root.locale, "yyyy")
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.25)
            }

            StyledText {
                text: root.today.toLocaleDateString(root.locale, "dddd")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // ── Separator ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(1, 1, 1, 0.04)
    }

    // ── Upcoming events ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: Events.list.length > 0

        StyledText {
            text: "UPCOMING"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            color: Qt.rgba(1, 1, 1, 0.3)
        }

        Repeater {
            // Show up to 3 upcoming events
            model: Events.list.slice(0, 3)

            RowLayout {
                id: eventRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                // Color dot
                Rectangle {
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: Appearance.colors.colPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: eventRow.modelData.title ?? eventRow.modelData.summary ?? ""
                        font.pixelSize: 11
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: eventRow.modelData.time ?? ""
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.3)
                        visible: text !== ""
                    }
                }
            }
        }
    }

    // ── No events placeholder ──
    StyledText {
        visible: Events.list.length === 0
        Layout.fillWidth: true
        text: "No upcoming events"
        font.pixelSize: 11
        color: Qt.rgba(1, 1, 1, 0.2)
        horizontalAlignment: Text.AlignHCenter
        Layout.topMargin: 8
    }

    Item { Layout.fillHeight: true }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/CalendarCard.qml
git commit -m "dashboard: add CalendarCard with hero date and upcoming events"
```

---

### Task 8: Create WeatherCard.qml

**Files:**
- Create: `modules/dashboard/WeatherCard.qml`

- [ ] **Step 1: Write WeatherCard.qml**

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
    headerText: ""

    visible: Weather.enabled

    // ── Temperature + icon hero row ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        MaterialSymbol {
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 36
            color: Appearance.colors.colPrimary
            layer.enabled: true
            layer.effect: Item {
                // Warm drop shadow behind weather icon
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 8
                    height: parent.height + 8
                    radius: width / 2
                    color: "transparent"
                    // The icon glow is handled by the layer being enabled on the parent
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Weather.data?.temp ?? "--°C"
                font.pixelSize: 28
                font.weight: Font.Bold
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                text: Weather.data?.weatherDesc ?? ""
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.35)
                visible: text !== ""
            }
        }
    }

    // ── Feels like ──
    StyledText {
        text: "Feels like " + (Weather.data?.tempFeelsLike ?? "--")
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colSubtext
        Layout.fillWidth: true
    }

    // ── Separator ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(1, 1, 1, 0.04)
    }

    // ── Detail row ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 16

        // Wind
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "air"; iconSize: 14; color: Appearance.colors.colSecondary }
            StyledText {
                text: (Weather.data?.windSpeed ?? "--") + " km/h"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }

        // Humidity
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "humidity_percentage"; iconSize: 14; color: Appearance.colors.colSecondary }
            StyledText {
                text: (Weather.data?.humidity ?? "--") + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }

        // City
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "location_on"; iconSize: 14; color: Appearance.colors.colSecondary }
            StyledText {
                text: Weather.data?.city ?? ""
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                Layout.maximumWidth: 80
                visible: text !== ""
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/WeatherCard.qml
git commit -m "dashboard: add WeatherCard with current conditions and details"
```

---

### Task 9: Create NotificationsCard.qml

**Files:**
- Create: `modules/dashboard/NotificationsCard.qml`

- [ ] **Step 1: Write NotificationsCard.qml**

```qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "Notifications"

    Component.onCompleted: Notifications.ensureInitialized()

    // ── Scrollable notification list ──
    ListView {
        id: notifListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100
        clip: true
        spacing: 6
        model: Notifications.list

        // Fade-out mask at top
        layer.enabled: count > 0
        layer.effect: Item {
            // Fade handled by clip — kept simple for Phase 2
        }

        delegate: Rectangle {
            id: notifDelegate
            required property var modelData
            required property int index
            width: notifListView.width
            implicitHeight: notifRow.implicitHeight + 16
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.015)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.03)

            RowLayout {
                id: notifRow
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                // App icon
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 6
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
                    Layout.alignment: Qt.AlignTop

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: {
                            // Map common app names to icons
                            const appName = (notifDelegate.modelData.appName ?? "").toLowerCase()
                            if (appName.includes("discord")) return "forum"
                            if (appName.includes("firefox")) return "language"
                            if (appName.includes("telegram")) return "send"
                            if (appName.includes("spotify")) return "music_note"
                            return "notifications"
                        }
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }
                }

                // Notification text
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            Layout.fillWidth: true
                            text: notifDelegate.modelData.summary ?? notifDelegate.modelData.appName ?? "Notification"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                        }

                        // Relative timestamp
                        StyledText {
                            text: {
                                const now = Date.now()
                                const elapsed = now - (notifDelegate.modelData.time ?? now)
                                const seconds = Math.floor(elapsed / 1000)
                                if (seconds < 60) return "now"
                                const minutes = Math.floor(seconds / 60)
                                if (minutes < 60) return minutes + "m"
                                const hours = Math.floor(minutes / 60)
                                if (hours < 24) return hours + "h"
                                return Math.floor(hours / 24) + "d"
                            }
                            font.pixelSize: 10
                            color: Qt.rgba(1, 1, 1, 0.2)
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: notifDelegate.modelData.body ?? ""
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.35)
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        visible: text !== ""
                    }
                }
            }
        }

        // Empty state
        Item {
            anchors.fill: parent
            visible: Notifications.list.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "notifications_none"
                    iconSize: 32
                    color: Qt.rgba(1, 1, 1, 0.15)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "All caught up"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.2)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/NotificationsCard.qml
git commit -m "dashboard: add NotificationsCard with scrollable notification list"
```

---

### Task 10: Create DashboardContent.qml (Three-Column Layout)

**Files:**
- Create: `modules/dashboard/DashboardContent.qml`

- [ ] **Step 1: Write DashboardContent.qml**

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Three-column layout assembling all dashboard cards.
// Left: identity & controls. Center: Phase 3 placeholder. Right: calendar/weather/notifications.
Item {
    id: root

    readonly property int leftColumnWidth: Config.options?.dashboard?.layout?.leftColumnWidth ?? 260
    readonly property int rightColumnWidth: Config.options?.dashboard?.layout?.rightColumnWidth ?? 240
    readonly property bool sectionProfile: Config.options?.dashboard?.sections?.profile ?? true
    readonly property bool sectionSystemInfo: Config.options?.dashboard?.sections?.systemInfo ?? true
    readonly property bool sectionQuickToggles: Config.options?.dashboard?.sections?.quickToggles ?? true
    readonly property bool sectionMedia: Config.options?.dashboard?.sections?.media ?? true
    readonly property bool sectionPerformance: Config.options?.dashboard?.sections?.performance ?? true
    readonly property bool sectionCalendar: Config.options?.dashboard?.sections?.calendar ?? true
    readonly property bool sectionWeather: Config.options?.dashboard?.sections?.weather ?? true
    readonly property bool sectionNotifications: Config.options?.dashboard?.sections?.notifications ?? true

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // ════════════════════════════════════════════
        // LEFT COLUMN — Identity & Controls
        // ════════════════════════════════════════════
        ColumnLayout {
            Layout.preferredWidth: root.leftColumnWidth
            Layout.fillHeight: true
            spacing: 12

            ProfileCard {
                Layout.fillWidth: true
                visible: root.sectionProfile
            }

            SystemInfoCard {
                Layout.fillWidth: true
                visible: root.sectionSystemInfo
            }

            QuickTogglesCard {
                Layout.fillWidth: true
                visible: root.sectionQuickToggles
            }

            MediaCard {
                Layout.fillWidth: true
                visible: root.sectionMedia
            }

            Item { Layout.fillHeight: true }
        }

        // ════════════════════════════════════════════
        // CENTER COLUMN — Performance & Activity (Phase 3 placeholder)
        // ════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Phase 3: PerformanceBars will go here
            // Phase 3: NetworkSparklines will go here
            // Phase 4: ActivityConsole will go here

            // Placeholder card while center column content is pending
            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.sectionPerformance

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "monitoring"
                            iconSize: 48
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Performance metrics"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Bar charts, sparklines, and activity console\ncoming in Phase 3-4"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.1)
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Quick resource summary in the meantime
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 12
                            spacing: 24

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(ResourceUsage.cpuUsage * 100) + "%"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "CPU"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(ResourceUsage.gpuUsage * 100) + "%"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colSecondary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "GPU"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colTertiary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "RAM"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: ResourceUsage.maxTemp + "°"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colError
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "TEMP"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════
        // RIGHT COLUMN — Calendar, Weather, Notifications
        // ════════════════════════════════════════════
        ColumnLayout {
            Layout.preferredWidth: root.rightColumnWidth
            Layout.fillHeight: true
            spacing: 12

            CalendarCard {
                Layout.fillWidth: true
                visible: root.sectionCalendar
            }

            WeatherCard {
                Layout.fillWidth: true
                visible: root.sectionWeather
            }

            NotificationsCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.sectionNotifications
            }
        }
    }

    Component.onCompleted: {
        ResourceUsage.ensureRunning()
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/DashboardContent.qml
git commit -m "dashboard: add DashboardContent three-column layout with Phase 3 placeholder center"
```

---

### Task 11: Create Dashboard.qml (PanelWindow Overlay)

**Files:**
- Create: `modules/dashboard/Dashboard.qml`

This is the core overlay component. It follows the SidebarShell.qml pattern: a `PanelWindow` spanning the entire screen, with a modal scrim, content positioned center-screen, fly-from-top animation, click-outside dismiss, Escape key dismiss, and IPC handler.

- [ ] **Step 1: Write Dashboard.qml**

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Command Center Dashboard — full-screen overlay with three-column layout.
// Triggered by GlobalStates.dashboardOpen (monogram click, IPC, or keybind).
Scope {
    id: root

    readonly property bool dashboardOpen: GlobalStates.dashboardOpen
    readonly property int animDuration: Config.options?.dashboard?.animationDuration ?? 350
    readonly property int exitDuration: Math.round(animDuration * 0.6) // Spec: exit 200-250ms
    readonly property real dimOpacity: Config.options?.dashboard?.backdrop?.dimOpacity ?? 0.45

    // Deferred show to drive animation after visible=true
    property bool _dashboardShown: false

    function _closeDashboard() {
        GlobalStates.dashboardOpen = false
    }

    PanelWindow {
        id: dashboardWindow

        Component.onCompleted: {
            visible = root.dashboardOpen
            root._dashboardShown = root.dashboardOpen
        }

        Connections {
            target: GlobalStates
            function onDashboardOpenChanged() {
                if (GlobalStates.dashboardOpen) {
                    _closeTimer.stop()
                    dashboardWindow.visible = true
                    Qt.callLater(() => { root._dashboardShown = true })
                } else if (!Appearance.animationsEnabled) {
                    root._dashboardShown = false
                    _closeTimer.stop()
                    dashboardWindow.visible = false
                } else {
                    root._dashboardShown = false
                    _closeTimer.restart()
                }
            }
        }

        Timer {
            id: _closeTimer
            interval: root.exitDuration
            onTriggered: dashboardWindow.visible = false
        }

        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:dashboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.dashboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // ── Click-outside dismiss ──
        MouseArea {
            anchors.fill: parent
            onClicked: mouse => {
                const localPos = mapToItem(dashboardContainer, mouse.x, mouse.y)
                if (localPos.x < 0 || localPos.x > dashboardContainer.width
                        || localPos.y < 0 || localPos.y > dashboardContainer.height) {
                    root._closeDashboard()
                }
            }
        }

        // ── Modal scrim (dimmed backdrop) ──
        Rectangle {
            id: modalScrim
            anchors.fill: parent
            color: Appearance.m3colors.m3scrim
            opacity: root._dashboardShown ? root.dimOpacity : 0

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root.animDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves?.standardDecel ?? [0, 0, 0, 1, 1, 1]
                }
            }
        }

        // ── Dashboard container (centered, sized to ~65% x ~75% of screen) ──
        Rectangle {
            id: dashboardContainer

            anchors.centerIn: parent
            // Offset slightly toward top (closer to bar)
            anchors.verticalCenterOffset: -(parent.height * 0.04)

            width: Math.min(parent.width * 0.65, 1100)
            height: Math.min(parent.height * 0.75, 800)

            color: Qt.rgba(0.055, 0.055, 0.102, 0.96)
            radius: 24
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)

            // ── Shadow ──
            StyledRectangularShadow {
                target: dashboardContainer
            }

            // ── Animation properties ──
            property real animTranslateY: root._dashboardShown ? 0 : -(dashboardWindow.height * 0.15)
            property real animOpacity: root._dashboardShown ? 1 : 0
            property real animScale: root._dashboardShown ? 1 : 0.95

            transform: Translate { y: dashboardContainer.animTranslateY }
            opacity: dashboardContainer.animOpacity
            scale: dashboardContainer.animScale

            Behavior on animTranslateY {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root._dashboardShown ? root.animDuration : root.exitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root._dashboardShown
                        ? (Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1])
                        : (Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }

            Behavior on animOpacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root._dashboardShown ? Math.round(root.animDuration * 0.7) : Math.round(root.exitDuration * 0.7)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root._dashboardShown
                        ? (Appearance.animationCurves?.standardDecel ?? [0, 0, 0, 1, 1, 1])
                        : (Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }

            Behavior on animScale {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root._dashboardShown ? root.animDuration : root.exitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root._dashboardShown
                        ? (Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1])
                        : (Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }

            // ── Content ──
            DashboardContent {
                anchors.fill: parent
                anchors.margins: 28
            }

            // ── Keyboard navigation ──
            focus: root.dashboardOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root._closeDashboard()
                    event.accepted = true
                }
            }
        }
    }

    // ── IPC handler ──
    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen
        }
        function open(): void {
            GlobalStates.dashboardOpen = true
        }
        function close(): void {
            GlobalStates.dashboardOpen = false
        }
    }
}
```

- [ ] **Step 2: Verify IPC**

After saving and hot-reload, test the IPC handler:

```bash
qs msg -c inir dashboard toggle
```

The dashboard should appear (fly-in from top). Run again to dismiss. Check logs:

```bash
qs log -c inir 2>&1 | tail -10
```

No QML errors expected.

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add modules/dashboard/Dashboard.qml
git commit -m "dashboard: add Dashboard overlay with fly-from-top animation and IPC"
```

---

### Task 12: Integrate Dashboard into shell.qml

**Files:**
- Modify: `shell.qml` (~line 180, alongside other LazyLoader declarations)

- [ ] **Step 1: Add import and LazyLoader**

In `shell.qml`, add the dashboard module import near the existing module imports (around line 1):

```qml
import qs.modules.dashboard
```

Then add the dashboard LazyLoader. Find the line `LazyLoader { active: Config.ready; component: CloseConfirm {} }` (around line 195). Add the dashboard loader just above it:

```qml
// Command Center Dashboard (loaded regardless of panel family)
LazyLoader {
    active: Config.ready && (Config.options?.dashboard?.enable ?? true)
    component: Dashboard {}
}
```

- [ ] **Step 2: Verify end-to-end flow**

Save. The shell hot-reloads. Test the full flow:

1. Click the monogram in the bar → Dashboard should fly in from top
2. Click the monogram again → Dashboard should fly out
3. Open via IPC: `qs msg -c inir dashboard toggle`
4. Press Escape → Dashboard dismisses
5. Click outside the dashboard container → Dashboard dismisses
6. Open dashboard, then try opening left sidebar: sidebar should NOT open (dashboardOpen handler closes it)

Verify no errors:

```bash
qs log -c inir 2>&1 | tail -20
```

- [ ] **Step 3: Commit**

```bash
cd ~/Github/inir
git add shell.qml
git commit -m "shell: integrate Command Center Dashboard loader"
```

---

### Task 13: Sync Live → Repo and Verify

**Files:**
- All new/modified files

- [ ] **Step 1: Copy live files to repo (if editing live)**

If development was done on the live instance (`~/.config/quickshell/inir/`), sync to the repo:

```bash
# New dashboard module
cp -r ~/.config/quickshell/inir/modules/dashboard/ ~/Github/inir/modules/dashboard/

# Modified files
cp ~/.config/quickshell/inir/modules/common/Config.qml ~/Github/inir/modules/common/Config.qml
cp ~/.config/quickshell/inir/shell.qml ~/Github/inir/shell.qml
```

If development was done directly on the repo, copy to live:

```bash
cp -r ~/Github/inir/modules/dashboard/ ~/.config/quickshell/inir/modules/dashboard/
cp ~/Github/inir/modules/common/Config.qml ~/.config/quickshell/inir/modules/common/Config.qml
cp ~/Github/inir/shell.qml ~/.config/quickshell/inir/shell.qml
```

- [ ] **Step 2: Drift check**

```bash
diff -rq ~/.config/quickshell/inir/modules/dashboard/ ~/Github/inir/modules/dashboard/
diff -q ~/.config/quickshell/inir/modules/common/Config.qml ~/Github/inir/modules/common/Config.qml
diff -q ~/.config/quickshell/inir/shell.qml ~/Github/inir/shell.qml
```

Expected: no differences.

- [ ] **Step 3: Full visual verification**

Reopen the dashboard and verify each card:

1. **Profile card:** Avatar (gradient or image), display name, subtitle with real values
2. **System info:** All 6 rows populated (uptime, kernel, packages, shell, GPU, WM)
3. **Quick toggles:** All 6 toggles visible, clicking each toggles its state and reflects visually
4. **Media card:** Only visible when media is playing. Shows track info and working controls.
5. **Calendar card:** Hero date shows today's date, day of week. Events listed if any.
6. **Weather card:** Only visible when weather is enabled. Shows temp, icon, wind, humidity.
7. **Notifications card:** Shows recent notifications or "All caught up" placeholder.
8. **Center column:** Shows Phase 3 placeholder with live CPU/GPU/RAM/Temp numbers.
9. **Animation:** Fly-in from top (smooth deceleration), fly-out (smooth acceleration).
10. **Dismiss methods:** Click outside, Escape key, monogram re-click, IPC `dashboard close`.

- [ ] **Step 4: Final commit with all files**

```bash
cd ~/Github/inir
git add -A modules/dashboard/
git add modules/common/Config.qml shell.qml
git status  # Verify only expected files are staged
git commit -m "dashboard: Command Center Phase 2 complete — overlay, cards, three-column layout"
```

---

## Phase Boundaries

| Phase | Scope | Status |
|-------|-------|--------|
| **Phase 1** | Bar layout overhaul, MiniRing, monogram rewire, config keys | Done |
| **Phase 2** | Command Center Dashboard overlay + cards (this plan) | **Current** |
| Phase 3 | Performance bar charts, network sparklines in center column | Next |
| Phase 4 | Activity Console (terminal-styled feed + daemon) | Future |
| Phase 5 | Left sidebar edge-pull interaction | Future |

---

## Dependency Graph

```
Task 1 (Config keys)
  └── Task 2 (DashboardCard) ─── shared by all cards
        ├── Task 3 (ProfileCard)
        ├── Task 4 (SystemInfoCard)
        ├── Task 5 (QuickTogglesCard)
        ├── Task 6 (MediaCard)
        ├── Task 7 (CalendarCard)
        ├── Task 8 (WeatherCard)
        └── Task 9 (NotificationsCard)
              └── Task 10 (DashboardContent) ─── assembles all cards
                    └── Task 11 (Dashboard.qml) ─── overlay window
                          └── Task 12 (shell.qml integration)
                                └── Task 13 (Sync & verify)
```

**Parallelism:** Tasks 3-9 are independent of each other and can run in parallel (all depend only on Task 2). Tasks 10-13 are sequential.
