import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Terminal-styled activity feed card for the dashboard center column.
// Watches ~/.local/state/inir/activity-feed.jsonl and renders entries
// with per-source color coding (claude=amber, git=pink, pacman=green, system=cyan).
// The backend script that writes that file is responsible for keeping it sorted
// newest-first; this card assumes that ordering.
DashboardCard {
    id: root
    // Header is custom (needs liveness dot) — suppress base class header
    headerText: ""

    // Darker than the default 0.025 — this card is a dense info surface
    color: Qt.rgba(1, 1, 1, 0.015)

    // Config toggles — default true so the card works before config keys exist
    readonly property bool consoleEnabled: Config.options?.dashboard?.activityConsole?.enable       ?? true
    readonly property bool srcClaude:  Config.options?.dashboard?.activityConsole?.sources?.claude  ?? true
    readonly property bool srcGit:     Config.options?.dashboard?.activityConsole?.sources?.git     ?? true
    readonly property bool srcPacman:  Config.options?.dashboard?.activityConsole?.sources?.pacman  ?? true
    readonly property bool srcSystem:  Config.options?.dashboard?.activityConsole?.sources?.system  ?? true

    visible: consoleEnabled

    // Source color map — hardcoded semantic identifiers, not theme tokens
    function sourceColor(src) {
        switch (src) {
            case "claude":  return "#fbbf24"  // amber
            case "git":     return "#f472b6"  // pink
            case "pacman":  return "#4ade80"  // green
            case "system":  return "#22d3ee"  // cyan
            default:        return Qt.rgba(1, 1, 1, 0.5)
        }
    }

    function formatTime(epochSecs) {
        const d = new Date(epochSecs * 1000)
        const h = d.getHours().toString().padStart(2, '0')
        const m = d.getMinutes().toString().padStart(2, '0')
        return h + ":" + m
    }

    function parseEntries(text) {
        if (!text || text.trim() === "") {
            entryModel.clear()
            return
        }
        const sources = Config.options?.dashboard?.activityConsole?.sources
        const lines = text.trim().split("\n")
        const entries = []
        for (const line of lines) {
            if (!line.trim()) continue
            try {
                const entry = JSON.parse(line)
                // Per-source toggle: if the key is explicitly false, skip
                if (sources && sources[entry.source] === false) continue
                entries.push(entry)
            } catch (e) {
                // Skip malformed JSONL lines silently
            }
        }
        entryModel.clear()
        for (const e of entries) {
            entryModel.append(e)
        }
    }

    // -------------------------------------------------------------------------
    // Data model
    // -------------------------------------------------------------------------

    ListModel {
        id: entryModel
    }

    FileView {
        id: feedFile
        path: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/state/inir/activity-feed.jsonl")
        watchChanges: true
        onLoaded: root.parseEntries(feedFile.text())
        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound) {
                console.warn("[ActivityConsole] Error loading feed:", error)
            }
            // File doesn't exist yet — retry until it appears
            if (!retryTimer.running) retryTimer.start()
        }
    }

    Timer {
        id: retryTimer
        interval: 60000
        repeat: true
        onTriggered: feedFile.reload()
    }

    // -------------------------------------------------------------------------
    // Custom header row with liveness dot
    // -------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        // Liveness pulse dot — heartbeat, not a party
        Rectangle {
            id: liveDot
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 0.5; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
        }

        StyledText {
            text: "ACTIVITY"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            color: Qt.rgba(1, 1, 1, 0.4)
            Layout.fillWidth: true
        }
    }

    // -------------------------------------------------------------------------
    // List + fade mask wrapper — must be an Item so overlay can use anchors
    // inside a ColumnLayout context
    // -------------------------------------------------------------------------

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Clip so entries don't bleed outside the card during scroll
        clip: true

        ListView {
            id: feedList
            anchors.fill: parent
            model: entryModel

            // Show newest-first; JSONL is already sorted newest-first so we
            // display from index 0 downward — no reversal needed.
            // The contentY is positioned at the top (default), which shows the
            // most-recent entries. User can scroll down toward older entries.

            spacing: 0
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2500

            // NOTE: add transition intentionally omitted. parseEntries() does
            // clear()+append() on every FileView reload (every ~30s), which
            // would re-animate ALL entries simultaneously. Proper incremental
            // diffing is a v2 concern.

            delegate: Item {
                id: entryDelegate
                // pragma ComponentBehavior: Bound is set on the card's parent module;
                // explicit required properties avoid implicit context capture warnings.
                required property int index
                required property int ts
                required property string source
                required property string summary
                required property string context

                width: feedList.width
                height: entryRow.implicitHeight + 4  // 2px padding top + bottom

                RowLayout {
                    id: entryRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 8

                    // HH:MM timestamp — fixed width column
                    Text {
                        text: root.formatTime(entryDelegate.ts)
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Qt.rgba(1, 1, 1, 0.35)
                        Layout.preferredWidth: 34  // wide enough for "00:00"
                    }

                    // Source label — fixed width column (longest: "pacman"/"claude" ~64px)
                    Text {
                        text: entryDelegate.source
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: root.sourceColor(entryDelegate.source)
                        Layout.preferredWidth: 64
                    }

                    // Summary — takes remaining space, elides on overflow
                    Text {
                        text: entryDelegate.summary
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Qt.rgba(1, 1, 1, 0.7)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Context path — right-aligned, very dim, elide left so
                    // the end of the path (the meaningful part) stays visible
                    Text {
                        visible: entryDelegate.context !== ""
                        text: entryDelegate.context
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Qt.rgba(1, 1, 1, 0.25)
                        elide: Text.ElideLeft
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 120
                    }
                }
            }
        }

        // Fade-out gradient mask at the top — softens the scroll edge.
        // Anchored to this Item's top (not the card root's top) so the
        // "ACTIVITY" header remains fully visible above it.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            z: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.6) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Fade-out gradient mask at the bottom — sells the "infinite feed" feel.
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            z: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }
    }
}
