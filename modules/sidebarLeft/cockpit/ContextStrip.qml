pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * ContextStrip — cockpit footer rail, 52px fixed height.
 *
 * Session H: full implementation replacing the stub.
 *   - Three rotating slots: ProjectPulse → SteamStatus → NextUp
 *   - Pip row (active pip elongates to 18px) indicates active slot
 *   - Accent-tinted background wash (6% alpha, below the 12% AmbientBackground ceiling)
 *   - Tap to cycle. defaultWidget config key sets initial slot on open.
 *   - All three widgets are inline components — each ≤40 lines of real content.
 *   - Data scanned once per sidebar-open. Scan trigger lives on root (not inside
 *     inline components) to avoid ComponentBehavior: Bound scope limitations.
 *   - Fixed height: strip never collapses even when slot content is empty.
 */
Item {
    id: root

    // ── Layout (fixed — never reflows) ─────────────────────────────────────
    Layout.fillWidth: true
    Layout.preferredHeight: (Config.options.sidebar?.contextStrip?.enable ?? true) ? 52 : 0
    Layout.minimumHeight:   (Config.options.sidebar?.contextStrip?.enable ?? true) ? 52 : 0
    Layout.maximumHeight:   (Config.options.sidebar?.contextStrip?.enable ?? true) ? 52 : 0
    visible: (Config.options.sidebar?.contextStrip?.enable ?? true)

    // ── Active slot state ──────────────────────────────────────────────────
    property int _activeIndex: 0    // 0=projectPulse 1=steamStatus 2=nextUp
    readonly property int _slotCount: 3

    // Accent from the currently active widget — drives the background wash.
    readonly property color _activeAccent: _activeIndex === 0
        ? projectPulse._accent
        : _activeIndex === 1
            ? steamStatus._accent
            : nextUp._accent

    function _cycle(): void {
        _activeIndex = (_activeIndex + 1) % _slotCount
    }

    // ── Scan trigger — lives on root to access GlobalStates ────────────────
    // Inline components can't see singleton imports with ComponentBehavior: Bound.
    // Root owns the trigger. A generation counter avoids the QML binding-coalesce
    // issue (same-tick false→true may be swallowed) and the binding-break issue
    // (Quickshell Process sets running=false on exit, potentially breaking a
    // declarative binding). Components watch scanGen imperatively via onScanGenChanged.
    property int scanGen: 0

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged(): void {
            if (GlobalStates.sidebarLeftOpen) root.scanGen++
        }
    }

    // Map config defaultWidget string → index on first load; fire initial scan.
    // Single Component.onCompleted — QML forbids duplicates.
    Component.onCompleted: {
        const name = Config.options.sidebar?.contextStrip?.defaultWidget ?? "projectPulse"
        if (name === "steamStatus")  _activeIndex = 1
        else if (name === "nextUp")  _activeIndex = 2
        else                         _activeIndex = 0

        if (GlobalStates.sidebarLeftOpen) root.scanGen++
    }

    // ── Accent wash (signature move, §2) ───────────────────────────────────
    // Tints strip toward active widget's state. Max 6% alpha — below AmbientBackground
    // album wash ceiling (12%) so the strip never competes with the wash above it.
    Rectangle {
        anchors.fill: parent
        color: ColorUtils.applyAlpha(root._activeAccent, 0.06)
        radius: 0
        z: 0
        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }
    }

    // ── Cycle tap target (full-strip hit area) ─────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: 1
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root._cycle()
    }

    // ── Main layout ────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12
        z: 2

        // ── Pip row ────────────────────────────────────────────────────────
        // Active pip elongates (6→18px). Both width and color Behavior on
        // elementMoveFast for a quick snap, not a slow crawl.
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index

                    readonly property bool _isActive: root._activeIndex === index

                    implicitHeight: 6
                    implicitWidth: _isActive ? 18 : 6
                    radius: 3
                    color: _isActive
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colOnLayer1Inactive
                    opacity: _isActive ? 1.0 : 0.35

                    Behavior on implicitWidth {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                    Behavior on opacity {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                }
            }
        }

        // ── Widget body ────────────────────────────────────────────────────
        // All three widgets stack here; only the active one is opacity:1 + scale:1.
        // visible:opacity>0 prevents hit-test bleed through invisible layers.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ProjectPulseStrip {
                id: projectPulse
                anchors.fill: parent
                _active: root._activeIndex === 0
                scanGen: root.scanGen
            }
            SteamStatusStrip {
                id: steamStatus
                anchors.fill: parent
                _active: root._activeIndex === 1
                scanGen: root.scanGen
            }
            NextUpStrip {
                id: nextUp
                anchors.fill: parent
                _active: root._activeIndex === 2
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // § ProjectPulseStrip — most-recently-touched vault project + age.
    // Data: scan ~/Documents/Ayaz OS/03 Projects/ once per sidebar-open.
    // ══════════════════════════════════════════════════════════════════════
    component ProjectPulseStrip: Item {
        id: ppRoot

        property bool _active: false
        property int  scanGen: 0   // bump from root to fire scan
        onScanGenChanged: if (scanGen > 0) ppScan.running = true

        // Expose accent up to root for the background wash.
        readonly property color _accent:
            _noData               ? Appearance.colors.colOnLayer1Inactive
            : _ageSeconds < 3600  ? Appearance.colors.colPrimary    // < 1h  fresh
            : _ageSeconds < 172800? Appearance.colors.colTertiary   // < 2d  warm
            :                       Appearance.colors.colError       // ≥ 2d  stale

        // ── Cycle visibility / scale ───────────────────────────────────────
        opacity: _active ? 1.0 : 0.0
        scale:   _active ? 1.0 : 0.94
        visible: opacity > 0.0
        transformOrigin: Item.Center

        Behavior on opacity {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }
        Behavior on scale {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        // ── Data state ─────────────────────────────────────────────────────
        property string _freshProject: ""
        property real   _freshMtime:   0
        property real   _ageSeconds:   999999   // default → stale tint until data arrives
        property bool   _noData:       true

        function _formatAge(sec): string {
            if (sec < 60)    return "just now"
            if (sec < 3600)  return Math.floor(sec / 60)    + "m ago"
            if (sec < 86400) return Math.floor(sec / 3600)  + "h ago"
            return                   Math.floor(sec / 86400) + "d ago"
        }

        // ── Process ────────────────────────────────────────────────────────
        // Scans Ayaz OS Projects dir, one level deep, strips hidden files.
        // Excludes "(PROJECT TEMPLATE)". Outputs: <epoch>\t<name>, newest-first.
        // Uses $HOME to handle the "™" character naturally via the shell.
        Process {
            id: ppScan
            command: [
                "/usr/bin/bash", "-c",
                "cd \"$HOME/Documents/Ayaz OS/03 Projects\" 2>/dev/null || exit 0; " +
                "for d in */; do " +
                "  d=\"${d%/}\"; " +
                "  case \"$d\" in '(PROJECT TEMPLATE)') continue;; esac; " +
                "  mt=$(find \"$d\" -maxdepth 2 -type f -not -path '*/.*' -printf '%T@\\n' 2>/dev/null | sort -n | tail -1); " +
                "  [ -z \"$mt\" ] || printf '%s\\t%s\\n' \"${mt%.*}\" \"$d\"; " +
                "done | sort -rn | head -5"
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    const raw = text.trim()
                    if (raw.length === 0) {
                        ppRoot._noData = true
                        ppRoot._freshProject = ""
                        return
                    }
                    const firstLine = raw.split("\n")[0]
                    const parts = firstLine.split("\t")
                    if (parts.length < 2) {
                        ppRoot._noData = true
                        return
                    }
                    ppRoot._freshMtime   = parseFloat(parts[0])
                    ppRoot._freshProject = parts.slice(1).join("\t")
                    ppRoot._ageSeconds   = (Date.now() / 1000) - ppRoot._freshMtime
                    ppRoot._noData       = false
                }
            }
        }

        // ── Layout ─────────────────────────────────────────────────────────
        RowLayout {
            anchors.fill: parent
            spacing: 8

            // State dot — colour reflects freshness (matches strip accent tint)
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: ppRoot._accent
                Layout.alignment: Qt.AlignVCenter
                visible: !ppRoot._noData
            }

            // Project name
            StyledText {
                Layout.fillWidth: true
                text: ppRoot._noData ? "no projects" : ppRoot._freshProject
                color: ppRoot._noData
                    ? Appearance.colors.colOnLayer1Inactive
                    : Appearance.colors.colOnLayer1
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }

            // Separator + age (hidden in no-data state)
            StyledText {
                visible: !ppRoot._noData
                text: "· " + ppRoot._formatAge(ppRoot._ageSeconds)
                color: Appearance.colors.colOnLayer1Inactive
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.small
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // § SteamStatusStrip — last-played game (runtime-filtered).
    // Data: scan ~/.steam/steam/steamapps/appmanifest_*.acf once per sidebar-open.
    // Critical: must skip Runtime / Proton / Steamworks entries.
    // ══════════════════════════════════════════════════════════════════════
    component SteamStatusStrip: Item {
        id: ssRoot

        property bool _active: false
        property int  scanGen: 0
        onScanGenChanged: if (scanGen > 0) ssScan.running = true

        // Gaming context → tertiary always (no staleness gradient per spec §5).
        readonly property color _accent: _hasGame
            ? Appearance.colors.colTertiary
            : Appearance.colors.colOnLayer1Inactive

        // ── Cycle visibility / scale ───────────────────────────────────────
        opacity: _active ? 1.0 : 0.0
        scale:   _active ? 1.0 : 0.94
        visible: opacity > 0.0
        transformOrigin: Item.Center

        Behavior on opacity {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }
        Behavior on scale {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        // ── Data state ─────────────────────────────────────────────────────
        property string _gameName:  ""
        property real   _gameMtime: 0
        property bool   _hasGame:   false

        function _formatAge(sec): string {
            if (sec < 60)     return "just now"
            if (sec < 3600)   return Math.floor(sec / 60)     + "m ago"
            if (sec < 86400)  return Math.floor(sec / 3600)   + "h ago"
            if (sec < 604800) return Math.floor(sec / 86400)  + "d ago"
            return                    Math.floor(sec / 604800) + "w ago"
        }

        // ── Process ────────────────────────────────────────────────────────
        // Iterates appmanifest_*.acf in mtime order, skips Runtime/Proton/Steamworks.
        // Outputs single line: <epoch>\t<game name>
        Process {
            id: ssScan
            command: [
                "/usr/bin/bash", "-c",
                "ls -t ~/.steam/steam/steamapps/appmanifest_*.acf 2>/dev/null | " +
                "while read m; do " +
                "  n=$(sed -n 's/.*\"name\"[[:space:]]*\"\\(.*\\)\".*/\\1/p' \"$m\" | head -1); " +
                "  case \"$n\" in " +
                "    *Runtime*|*Proton*|*Steamworks*|'Steam Linux Runtime'*|'') continue;; " +
                "  esac; " +
                "  printf '%s\\t%s\\n' \"$(stat -c %Y \"$m\")\" \"$n\"; " +
                "  break; " +
                "done"
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    const raw = text.trim()
                    if (raw.length === 0) {
                        ssRoot._hasGame = false
                        return
                    }
                    const parts = raw.split("\t")
                    if (parts.length < 2) {
                        ssRoot._hasGame = false
                        return
                    }
                    ssRoot._gameMtime = parseFloat(parts[0])
                    ssRoot._gameName  = parts.slice(1).join("\t")
                    ssRoot._hasGame   = true
                }
            }
        }

        // ── Layout ─────────────────────────────────────────────────────────
        RowLayout {
            anchors.fill: parent
            spacing: 8

            // Steam/gamepad glyph
            MaterialSymbol {
                text: "sports_esports"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1Inactive
                Layout.alignment: Qt.AlignVCenter
            }

            // Game name (or status placeholder)
            StyledText {
                Layout.fillWidth: true
                text: ssRoot._hasGame ? ssRoot._gameName : "steam offline"
                color: ssRoot._hasGame
                    ? Appearance.colors.colOnLayer1
                    : Appearance.colors.colOnLayer1Inactive
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }

            // "last played <age>" — only when a game is found
            StyledText {
                visible: ssRoot._hasGame
                text: "last played " + ssRoot._formatAge((Date.now() / 1000) - ssRoot._gameMtime)
                color: Appearance.colors.colOnLayer1Inactive
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.small
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // § NextUpStrip — next calendar event within 7 days.
    // Data: CalendarSync.getUpcomingEvents(7) — pure reactive binding, no Process.
    // CalendarSync owns the file-watch; strip just filters and displays.
    // ══════════════════════════════════════════════════════════════════════
    component NextUpStrip: Item {
        id: nuRoot

        property bool _active: false

        // Primary when there's an event, neutral otherwise.
        readonly property color _accent: _hasEvent
            ? Appearance.colors.colPrimary
            : Appearance.colors.colOnLayer1Inactive

        // ── Cycle visibility / scale ───────────────────────────────────────
        opacity: _active ? 1.0 : 0.0
        scale:   _active ? 1.0 : 0.94
        visible: opacity > 0.0
        transformOrigin: Item.Center

        Behavior on opacity {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }
        Behavior on scale {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        // ── Data state (reactive — CalendarSync.list drives rebind) ────────
        readonly property var _upcoming: CalendarSync.available
            ? CalendarSync.getUpcomingEvents(7).slice(0, 1)
            : []
        readonly property var  _next:     _upcoming.length > 0 ? _upcoming[0] : null
        readonly property bool _hasEvent: _next !== null

        function _formatUntil(eventDate): string {
            const now = new Date()
            const diffMs  = eventDate - now
            const diffMin = Math.floor(diffMs / 60000)
            if (diffMin < 60)      return "in " + diffMin + "m"
            if (diffMin < 720)     return "in " + Math.floor(diffMin / 60) + "h"
            const sameDay = eventDate.toDateString() === now.toDateString()
            if (sameDay)           return "today " + Qt.formatTime(eventDate, "HH:mm")
            const tomorrow = new Date(now)
            tomorrow.setDate(now.getDate() + 1)
            if (eventDate.toDateString() === tomorrow.toDateString())
                return "tomorrow " + Qt.formatTime(eventDate, "HH:mm")
            return Qt.formatDate(eventDate, "ddd") + " " + Qt.formatTime(eventDate, "HH:mm")
        }

        // ── Layout ─────────────────────────────────────────────────────────
        RowLayout {
            anchors.fill: parent
            spacing: 8

            // Calendar glyph
            MaterialSymbol {
                text: "event"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1Inactive
                Layout.alignment: Qt.AlignVCenter
            }

            // Event title (or placeholder)
            StyledText {
                Layout.fillWidth: true
                text: nuRoot._hasEvent
                    ? (nuRoot._next?.title ?? nuRoot._next?.summary ?? "")
                    : "no upcoming events"
                color: nuRoot._hasEvent
                    ? Appearance.colors.colOnLayer1
                    : Appearance.colors.colOnLayer1Inactive
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }

            // Time-until label
            StyledText {
                visible: nuRoot._hasEvent
                text: nuRoot._hasEvent
                    ? nuRoot._formatUntil(new Date(nuRoot._next?.dateTime ?? 0))
                    : ""
                color: Appearance.colors.colOnLayer1Inactive
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.small
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
