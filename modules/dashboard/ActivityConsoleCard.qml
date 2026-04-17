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
// with per-source palette-tinted color coding (matugen vocabulary).
// Backend script writes JSONL sorted newest-first; this card assumes that ordering.
//
// v2 features:
//   - Click-through: opens relevant terminal action per source
//   - Incremental model diffing: only new entries animate on refresh
//   - Palette-tinted source tags: matugen tokens instead of hardcoded hex
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

    // -------------------------------------------------------------------------
    // Palette-tinted source color map — matugen vocabulary, distinct per source
    //   claude  → colPrimary    (identity — current session's work)
    //   git     → colSecondary  (creative output register)
    //   pacman  → colTertiary   (system ops, matches SystemInfoCard family)
    //   system  → colError      (warnings/noise tone — degraded gracefully)
    // -------------------------------------------------------------------------
    function sourceColor(src) {
        switch (src) {
            case "claude":  return Appearance.colors.colPrimary
            case "git":     return Appearance.colors.colSecondary
            case "pacman":  return Appearance.colors.colTertiary
            case "system":  return Appearance.colors.colError
            default:        return Qt.rgba(1, 1, 1, 0.5)
        }
    }

    function formatTime(epochSecs) {
        const d = new Date(epochSecs * 1000)
        const h = d.getHours().toString().padStart(2, '0')
        const m = d.getMinutes().toString().padStart(2, '0')
        return h + ":" + m
    }

    // -------------------------------------------------------------------------
    // Click-through: spawn kitty for per-source action
    //   claude  → kitty at project cwd (falls back to HOME)
    //   git     → kitty --hold -e git -C <repo> show --stat <sha>
    //   pacman  → kitty --hold -e pacman -Qi <pkg>  (fallback: less pacman.log)
    //   system  → kitty --hold -e journalctl [--user] -u <unit> -n 50
    // No-op if required metadata is missing.
    // -------------------------------------------------------------------------
    function openEntryAction(entry) {
        const home = Quickshell.env("HOME")
        switch (entry.source) {
            case "claude": {
                const dir = (entry.cwd && entry.cwd !== "") ? entry.cwd : home
                Quickshell.execDetached(["kitty", "--working-directory", dir])
                break
            }
            case "git": {
                if (!entry.repo || entry.repo === "" || !entry.sha || entry.sha === "") return
                Quickshell.execDetached([
                    "kitty", "--hold", "-e",
                    "git", "-C", entry.repo, "show", "--stat", entry.sha
                ])
                break
            }
            case "pacman": {
                if (entry.pkg && entry.pkg !== "") {
                    Quickshell.execDetached([
                        "kitty", "--hold", "-e",
                        "pacman", "-Qi", entry.pkg
                    ])
                } else {
                    // Multi-pkg group fallback: open pacman log at end
                    Quickshell.execDetached([
                        "kitty", "--hold", "-e",
                        "less", "+G", "/var/log/pacman.log"
                    ])
                }
                break
            }
            case "system": {
                if (!entry.unit || entry.unit === "") return
                const args = ["kitty", "--hold", "-e", "journalctl"]
                if (entry.is_user_unit) args.push("--user")
                args.push("-u", entry.unit, "-n", "50")
                Quickshell.execDetached(args)
                break
            }
        }
    }

    // -------------------------------------------------------------------------
    // Incremental model diffing
    // _seenIds: Set of entry ids from prior loads — identifies NEW entries only
    // _firstLoadDone: gate that suppresses animation on initial population
    // Entry id = ts + "|" + source + "|" + summary (stable across refreshes)
    // -------------------------------------------------------------------------
    property var _seenIds: new Set()
    property bool _firstLoadDone: false
    // Toggled to gate the ListView add transition — only true during actual inserts
    property bool _animateInserts: false

    function _entryId(entry) {
        return entry.ts + "|" + entry.source + "|" + entry.summary
    }

    function parseEntries(text) {
        if (!text || text.trim() === "") {
            entryModel.clear()
            _seenIds = new Set()
            _firstLoadDone = false
            return
        }
        const sources = Config.options?.dashboard?.activityConsole?.sources

        // Parse all valid lines into an array
        const rawEntries = []
        for (const line of text.trim().split("\n")) {
            if (!line.trim()) continue
            try {
                const entry = JSON.parse(line)
                // Per-source toggle
                if (sources && sources[entry.source] === false) continue
                // Normalize: ensure all click-through fields exist (backward compat
                // with entries written before the v2 backend was deployed)
                entry.cwd          = entry.cwd          ?? ""
                entry.repo         = entry.repo         ?? ""
                entry.sha          = entry.sha          ?? ""
                entry.pkg          = entry.pkg          ?? ""
                entry.action       = entry.action       ?? ""
                entry.unit         = entry.unit         ?? ""
                entry.is_user_unit = entry.is_user_unit === true
                rawEntries.push(entry)
            } catch (e) {
                // Skip malformed JSONL lines silently
            }
        }

        if (!_firstLoadDone) {
            // First load: populate without animation, seed _seenIds
            _animateInserts = false
            entryModel.clear()
            const newSeen = new Set()
            for (const e of rawEntries) {
                entryModel.append(e)
                newSeen.add(_entryId(e))
            }
            _seenIds = newSeen
            _firstLoadDone = true
            return
        }

        // Subsequent loads: diff against _seenIds
        const currentIds = new Set()
        for (const e of rawEntries) {
            currentIds.add(_entryId(e))
        }

        // Entries not seen before = new
        const newEntries = rawEntries.filter(e => !_seenIds.has(_entryId(e)))

        if (newEntries.length === 0) {
            // No new entries — update seenIds in case some aged out
            _seenIds = currentIds
            return
        }

        // Enable insert animation for the upcoming inserts
        _animateInserts = true

        // Insert new entries at the top (index 0), newest-first.
        // newEntries is newest-first (mirrors rawEntries/JSONL order).
        // Insert in reverse so they land in the correct order at position 0.
        for (let i = newEntries.length - 1; i >= 0; i--) {
            entryModel.insert(0, newEntries[i])
        }

        // Remove entries that aged out (no longer in current parse)
        for (let i = entryModel.count - 1; i >= 0; i--) {
            if (!currentIds.has(_entryId(entryModel.get(i)))) {
                entryModel.remove(i, 1)
            }
        }

        _seenIds = currentIds
        // Clear the animation gate after inserts commit — next cycle is clean
        Qt.callLater(() => { _animateInserts = false })
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

        // Liveness pulse dot — system heartbeat, tertiary register (matches system info family)
        Rectangle {
            id: liveDot
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            color: Appearance.colors.colTertiary
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

            // New-entry insertion animation: slide down from above + fade in.
            // Only fires when root._animateInserts is true (incremental diff path).
            // Static entries and first-load population are never animated.
            add: Transition {
                enabled: root._animateInserts
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 400
                        easing.type: Easing.OutQuart
                    }
                    NumberAnimation {
                        property: "y"
                        from: -8
                        to: 0
                        duration: 400
                        easing.type: Easing.OutQuart
                    }
                }
            }

            delegate: Item {
                id: entryDelegate
                // pragma ComponentBehavior: Bound is set on the card's parent module;
                // explicit required properties avoid implicit context capture warnings.
                required property int index
                required property int ts
                required property string source
                required property string summary
                required property string context
                // click-through metadata (may be "" / false for old entries)
                required property string cwd
                required property string repo
                required property string sha
                required property string pkg
                required property string action
                required property string unit
                required property bool is_user_unit

                width: feedList.width
                height: entryRow.implicitHeight + 4  // 2px padding top + bottom

                // Whether this row has actionable click-through metadata
                readonly property bool isClickable: {
                    switch (source) {
                        case "claude":  return true  // always opens kitty at some dir
                        case "git":     return repo !== "" && sha !== ""
                        case "pacman":  return true  // pkg or fallback to log
                        case "system":  return unit !== ""
                        default:        return false
                    }
                }

                property bool hovered: false

                HoverHandler {
                    enabled: entryDelegate.isClickable
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: entryDelegate.hovered = hovered
                }

                TapHandler {
                    enabled: entryDelegate.isClickable
                    onTapped: {
                        root.openEntryAction({
                            source:       entryDelegate.source,
                            cwd:          entryDelegate.cwd,
                            repo:         entryDelegate.repo,
                            sha:          entryDelegate.sha,
                            pkg:          entryDelegate.pkg,
                            action:       entryDelegate.action,
                            unit:         entryDelegate.unit,
                            is_user_unit: entryDelegate.is_user_unit,
                        })
                    }
                }

                // Subtle hover highlight — 5% white overlay, respects Campaign G density
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Qt.rgba(1, 1, 1, entryDelegate.hovered ? 0.05 : 0)
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

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

                    // Source label — palette-tinted, fixed width column
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
