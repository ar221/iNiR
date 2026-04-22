import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    // Slightly denser surface for clearer separation from neighboring cards
    color: Qt.rgba(1, 1, 1, 0.02)

    // Config toggles — default true so the card works before config keys exist
    readonly property bool consoleEnabled: Config.options?.dashboard?.activityConsole?.enable       ?? true
    readonly property bool srcClaude:  Config.options?.dashboard?.activityConsole?.sources?.claude  ?? true
    readonly property bool srcGit:     Config.options?.dashboard?.activityConsole?.sources?.git     ?? true
    readonly property bool srcPacman:  Config.options?.dashboard?.activityConsole?.sources?.pacman  ?? true
    readonly property bool srcSystem:  Config.options?.dashboard?.activityConsole?.sources?.system  ?? true

    visible: consoleEnabled

    // Local interactive filters (mission-control style)
    property bool filterClaude: srcClaude
    property bool filterGit: srcGit
    property bool filterPacman: srcPacman
    property bool filterSystem: srcSystem
    property bool criticalOnly: false

    // Collapsible time buckets
    property bool expandNow: true
    property bool expandRecent: true
    property bool expandEarlier: true

    readonly property bool allFiltersActive: filterClaude && filterGit && filterPacman && filterSystem

    readonly property int visibleEntryCount: {
        let count = 0
        for (let i = 0; i < entryModel.count; i++) {
            if (entryPasses(entryModel.get(i))) count++
        }
        return count
    }

    // -------------------------------------------------------------------------
    // Palette-tinted source color map — matugen vocabulary, distinct per source
    //   claude  → colPrimary    (identity — current session's work)
    //   git     → colSecondary  (creative output register)
    //   pacman  → colTertiary   (system ops, matches SystemInfoCard family)
    //   system  → colError      (warnings/noise tone — degraded gracefully)
    // -------------------------------------------------------------------------
    function sourceColor(src) {
        switch (src) {
            case "claude": return Appearance.colors.colPrimary
            case "git": return Appearance.colors.colSecondary
            case "pacman": return Appearance.colors.colTertiary
            case "system": return Appearance.colors.colError
            default: return Qt.rgba(1, 1, 1, 0.5)
        }
    }

    function sourceLabel(src) {
        switch (src) {
            case "claude": return "APOLLO"
            case "git": return "CODE"
            case "pacman": return "SYSTEM"
            case "system": return "ALERT"
            default: return String(src).toUpperCase()
        }
    }

    function sourcePriority(src, summary) {
        const text = (summary ?? "").toLowerCase()
        if (src === "system" || text.includes("error") || text.includes("failed")) return "HIGH"
        if (src === "pacman" || text.includes("update") || text.includes("warning")) return "MED"
        return "LOW"
    }

    function isSourceVisible(src) {
        switch (src) {
            case "claude": return filterClaude
            case "git": return filterGit
            case "pacman": return filterPacman
            case "system": return filterSystem
            default: return true
        }
    }

    function isCritical(src, summary) {
        return sourcePriority(src, summary) === "HIGH"
    }

    function entryPasses(entry) {
        if (!entry) return false
        if (!isSourceVisible(entry.source)) return false
        if (criticalOnly && !isCritical(entry.source, entry.summary)) return false
        return true
    }

    function bucketForTs(epochSecs) {
        const age = Math.max(0, Math.floor(Date.now() / 1000) - epochSecs)
        if (age <= 3600) return "now"
        if (age <= 21600) return "recent"
        return "earlier"
    }

    function bucketLabel(bucket) {
        switch (bucket) {
            case "now": return "NOW"
            case "recent": return "LAST 6H"
            case "earlier": return "EARLIER"
            default: return "TIMELINE"
        }
    }

    function bucketExpanded(bucket) {
        switch (bucket) {
            case "now": return expandNow
            case "recent": return expandRecent
            case "earlier": return expandEarlier
            default: return true
        }
    }

    function toggleBucket(bucket) {
        switch (bucket) {
            case "now": expandNow = !expandNow; break
            case "recent": expandRecent = !expandRecent; break
            case "earlier": expandEarlier = !expandEarlier; break
        }
    }

    function isFirstVisibleInBucket(index) {
        if (index < 0 || index >= entryModel.count) return false
        const current = entryModel.get(index)
        if (!entryPasses(current)) return false
        const bucket = bucketForTs(current.ts)

        for (let i = index - 1; i >= 0; i--) {
            const prev = entryModel.get(i)
            if (!entryPasses(prev)) continue
            if (bucketForTs(prev.ts) === bucket) return false
        }
        return true
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
        spacing: 10

        Rectangle {
            id: liveDot
            implicitWidth: 8
            implicitHeight: 8
            radius: 4
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 0.45; duration: 850; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 850; easing.type: Easing.InOutSine }
            }
        }

        StyledText {
            text: "MISSION FEED"
            font.pixelSize: 13
            font.weight: Font.ExtraBold
            font.letterSpacing: 1.4
            color: Qt.rgba(1, 1, 1, 0.76)
        }

        StyledText {
            text: visibleEntryCount + " items"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Qt.rgba(1, 1, 1, 0.56)
            Layout.fillWidth: true
        }

        StyledText {
            text: "LIVE"
            font.pixelSize: 10
            font.weight: Font.Bold
            color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.95)
            font.letterSpacing: 1.2
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.preferredHeight: 26
            Layout.preferredWidth: 48
            radius: 7
            color: root.allFiltersActive && !root.criticalOnly
                ? Qt.rgba(1, 1, 1, 0.14)
                : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: root.allFiltersActive && !root.criticalOnly
                ? Qt.rgba(1, 1, 1, 0.26)
                : Qt.rgba(1, 1, 1, 0.14)

            StyledText {
                anchors.centerIn: parent
                text: "ALL"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Qt.rgba(1, 1, 1, 0.88)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.filterClaude = true
                    root.filterGit = true
                    root.filterPacman = true
                    root.filterSystem = true
                }
            }
        }

        Repeater {
            model: [
                { key: "claude", label: "Apollo" },
                { key: "git", label: "Code" },
                { key: "pacman", label: "System" },
                { key: "system", label: "Alert" }
            ]

            delegate: Rectangle {
                required property var modelData
                readonly property bool active: {
                    switch (modelData.key) {
                        case "claude": return root.filterClaude
                        case "git": return root.filterGit
                        case "pacman": return root.filterPacman
                        case "system": return root.filterSystem
                        default: return true
                    }
                }

                Layout.preferredHeight: 26
                Layout.preferredWidth: 68
                radius: 7
                color: active
                    ? Qt.rgba(root.sourceColor(modelData.key).r, root.sourceColor(modelData.key).g, root.sourceColor(modelData.key).b, 0.22)
                    : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: active
                    ? Qt.rgba(root.sourceColor(modelData.key).r, root.sourceColor(modelData.key).g, root.sourceColor(modelData.key).b, 0.52)
                    : Qt.rgba(1, 1, 1, 0.12)

                StyledText {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: active ? Qt.rgba(1, 1, 1, 0.94) : Qt.rgba(1, 1, 1, 0.56)
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        switch (parent.modelData.key) {
                            case "claude": root.filterClaude = !root.filterClaude; break
                            case "git": root.filterGit = !root.filterGit; break
                            case "pacman": root.filterPacman = !root.filterPacman; break
                            case "system": root.filterSystem = !root.filterSystem; break
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            Layout.preferredHeight: 26
            Layout.preferredWidth: 90
            radius: 7
            color: root.criticalOnly
                ? Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.20)
                : Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: root.criticalOnly
                ? Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.52)
                : Qt.rgba(1, 1, 1, 0.10)

            StyledText {
                anchors.centerIn: parent
                text: "CRITICAL"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: root.criticalOnly ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.56)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.criticalOnly = !root.criticalOnly
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            text: "GROUPS"
            font.pixelSize: 9
            font.weight: Font.Bold
            color: Qt.rgba(1, 1, 1, 0.50)
            font.letterSpacing: 1.1
        }

        Repeater {
            model: [
                { key: "now", label: "Now" },
                { key: "recent", label: "Last 6h" },
                { key: "earlier", label: "Earlier" }
            ]

            delegate: Rectangle {
                required property var modelData
                readonly property bool expanded: root.bucketExpanded(modelData.key)

                Layout.preferredHeight: 24
                Layout.preferredWidth: 78
                radius: 7
                color: expanded ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: expanded ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.10)

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        text: expanded ? "expand_more" : "chevron_right"
                        iconSize: 12
                        color: Qt.rgba(1, 1, 1, 0.68)
                    }

                    StyledText {
                        text: modelData.label
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: Qt.rgba(1, 1, 1, expanded ? 0.84 : 0.48)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleBucket(parent.modelData.key)
                }
            }
        }

        Item { Layout.fillWidth: true }
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
            anchors.topMargin: 2
            model: entryModel

            // Show newest-first; JSONL is already sorted newest-first so we
            // display from index 0 downward — no reversal needed.
            // The contentY is positioned at the top (default), which shows the
            // most-recent entries. User can scroll down toward older entries.

            spacing: 0
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2500
            clip: true
            ScrollBar.vertical: StyledScrollBar {}

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
                required property int index
                required property int ts
                required property string source
                required property string summary
                required property string context
                required property string cwd
                required property string repo
                required property string sha
                required property string pkg
                required property string action
                required property string unit
                required property bool is_user_unit

                readonly property bool passes: root.entryPasses({ source: source, summary: summary, ts: ts })
                readonly property string bucket: root.bucketForTs(ts)
                readonly property bool showBucketHeader: root.isFirstVisibleInBucket(index)
                readonly property bool expanded: root.bucketExpanded(bucket)
                readonly property bool filteredOut: !passes || (!expanded && !showBucketHeader)
                readonly property bool isClickable: {
                    switch (source) {
                        case "claude": return true
                        case "git": return repo !== "" && sha !== ""
                        case "pacman": return true
                        case "system": return unit !== ""
                        default: return false
                    }
                }
                readonly property string priority: root.sourcePriority(source, summary)
                property bool hovered: false

                width: feedList.width
                height: filteredOut ? 0 : (bucketHeader.visible ? bucketHeader.implicitHeight + 4 : 0) + (expanded ? feedBody.implicitHeight + 10 : 0)
                visible: !filteredOut

                HoverHandler {
                    enabled: expanded && entryDelegate.isClickable
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: entryDelegate.hovered = hovered
                }

                TapHandler {
                    enabled: expanded && entryDelegate.isClickable
                    onTapped: {
                        root.openEntryAction({
                            source: entryDelegate.source,
                            cwd: entryDelegate.cwd,
                            repo: entryDelegate.repo,
                            sha: entryDelegate.sha,
                            pkg: entryDelegate.pkg,
                            action: entryDelegate.action,
                            unit: entryDelegate.unit,
                            is_user_unit: entryDelegate.is_user_unit,
                        })
                    }
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        id: bucketHeader
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        visible: showBucketHeader
                        radius: 7
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.14)

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            MaterialSymbol {
                                text: expanded ? "expand_more" : "chevron_right"
                                iconSize: 12
                                color: Qt.rgba(1, 1, 1, 0.62)
                            }

                            StyledText {
                                text: root.bucketLabel(bucket)
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Qt.rgba(1, 1, 1, 0.70)
                                font.letterSpacing: 1.0
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleBucket(entryDelegate.bucket)
                        }
                    }

                    Rectangle {
                        id: feedBody
                        Layout.fillWidth: true
                        visible: expanded
                        implicitHeight: rowContent.implicitHeight + 20
                        radius: 11
                        color: Qt.rgba(1, 1, 1, entryDelegate.hovered ? 0.09 : 0.05)
                        border.width: 1
                        border.color: Qt.rgba(root.sourceColor(entryDelegate.source).r,
                                              root.sourceColor(entryDelegate.source).g,
                                              root.sourceColor(entryDelegate.source).b,
                                              entryDelegate.hovered ? 0.50 : 0.30)
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Behavior on border.color { ColorAnimation { duration: 110 } }

                        ColumnLayout {
                            id: rowContent
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 7

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: 46
                                    radius: 5
                                    color: Qt.rgba(1, 1, 1, 0.08)

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: root.formatTime(entryDelegate.ts)
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Qt.rgba(1, 1, 1, 0.84)
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: 66
                                    radius: 5
                                    color: Qt.rgba(root.sourceColor(entryDelegate.source).r,
                                                   root.sourceColor(entryDelegate.source).g,
                                                   root.sourceColor(entryDelegate.source).b,
                                                   0.22)
                                    border.width: 1
                                    border.color: Qt.rgba(root.sourceColor(entryDelegate.source).r,
                                                          root.sourceColor(entryDelegate.source).g,
                                                          root.sourceColor(entryDelegate.source).b,
                                                          0.52)

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: root.sourceLabel(entryDelegate.source)
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: Qt.rgba(1, 1, 1, 0.92)
                                        font.letterSpacing: 0.8
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: 42
                                    radius: 5
                                    color: entryDelegate.priority === "HIGH"
                                        ? Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.24)
                                        : entryDelegate.priority === "MED"
                                            ? Qt.rgba(Appearance.colors.colTertiary.r, Appearance.colors.colTertiary.g, Appearance.colors.colTertiary.b, 0.24)
                                            : Qt.rgba(1, 1, 1, 0.08)

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: entryDelegate.priority
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: Qt.rgba(1, 1, 1, 0.86)
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: entryDelegate.context !== ""
                                    text: entryDelegate.context
                                    font.pixelSize: 10
                                    color: Qt.rgba(1, 1, 1, 0.50)
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: entryDelegate.summary
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Qt.rgba(1, 1, 1, 0.92)
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.visibleEntryCount === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "travel_explore"
                    iconSize: 24
                    color: Qt.rgba(1, 1, 1, 0.30)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No events in current filters"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Qt.rgba(1, 1, 1, 0.52)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Press ALL to restore feed"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.36)
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
            height: 24
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
            height: 24
            z: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }
    }
}
