pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions
import qs.modules.background.widgets

// Job Hunt Pulse — vertical pipeline card on the desktop background.
// Sourced from `job-pulse --no-mail --json` (Process subprocess).
AbstractBackgroundWidget {
    id: root

    configEntryName: "jobHuntPulse"

    readonly property var jhpConfig: configEntry
    readonly property real cardWidth: jhpConfig?.cardWidth ?? 440
    readonly property real cardOpacity: jhpConfig?.cardOpacity ?? 0.95
    readonly property bool showApplied: jhpConfig?.showApplied ?? true
    readonly property bool showPackageReady: jhpConfig?.showPackageReady ?? true
    readonly property bool showShortlist: jhpConfig?.showShortlist ?? true
    readonly property int  refreshIntervalMs: jhpConfig?.refreshIntervalMs ?? 300000
    readonly property string vaultName: jhpConfig?.vaultName ?? "Ayaz OS"
    readonly property point screenPos: root.mapToItem(null, 0, 0)

    // — Parsed JSON state —
    property var nextAction: null    // { task, why, date }
    property var applied: []         // [{ company, role, status, notes, date, is_passive }]
    // Derived from `applied`: array of { date, items[] } groups, newest first.
    readonly property var appliedByDate: {
        const groups = {}
        const order = []
        for (let i = 0; i < applied.length; i++) {
            const app = applied[i]
            const key = (app && app.date && app.date.length > 0) ? app.date : "no date"
            if (groups[key] === undefined) {
                groups[key] = []
                order.push(key)
            }
            groups[key].push(app)
        }
        order.sort((a, b) => {
            if (a === "no date") return 1
            if (b === "no date") return -1
            return b.localeCompare(a)   // newest first
        })
        return order.map(k => ({ date: k, items: groups[k] }))
    }
    property var packageReady: []    // [{ company, role, notes }]
    property var shortlist: []       // [{ priority, company, role, notes }]
    property int directSubmittedTotal: 0
    property int waitingFollowup: 0
    property int staleCount: 0

    // — Freshness —
    property double lastSuccessAt: 0
    property string lastError: ""
    property int    _freshnessTick: 0

    readonly property int ageMin: {
        void root._freshnessTick   // re-eval every minute
        return lastSuccessAt > 0
            ? Math.floor((Date.now() - lastSuccessAt) / 60000)
            : 9999
    }
    readonly property string freshnessColor: {
        if (lastError.length > 0)         return "red"
        if (lastSuccessAt === 0)          return "amber"   // never fetched
        if (ageMin < 10)                  return "green"
        if (ageMin < 60)                  return "amber"
        return "red"
    }
    readonly property string lastFetchTimeStr: {
        if (lastSuccessAt === 0) return "—"
        const d = new Date(lastSuccessAt)
        return String(d.getHours()).padStart(2, "0") + ":"
            + String(d.getMinutes()).padStart(2, "0")
    }

    // — Obsidian paths (static for v1; v1.5 will read from `job-pulse --paths`) —
    readonly property string pathTasks:
        "03 Projects/Job Hunt/™ Job Hunt — Tasks.md"
    readonly property string pathSprint:
        "03 Projects/Job Hunt/02 Applications/™ Application Sprint — 2026-05-07.md"
    readonly property string pathShortlist:
        "03 Projects/Job Hunt/02 Applications/™ Job Shortlist — 2026-05-08.md"

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    // — Drop shadow + glass card background —
    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    Rectangle {
        id: cardBackground
        anchors.fill: parent
        radius: Appearance.rounding.unsharpen
        color: "transparent"
        clip: true

        GlassBackground {
            anchors.fill: parent
            radius: parent.radius
            screenX: root.screenPos.x
            screenY: root.screenPos.y
            fallbackColor: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }
        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 6
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // — Content —
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // — Header —
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            StyledText {
                text: "JOB HUNT · PULSE"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: Appearance.colors.colPrimary
            }

            Item { Layout.fillWidth: true }

            // Freshness dot
            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: {
                    if (root.freshnessColor === "green") return Appearance.m3colors.m3primary
                    if (root.freshnessColor === "amber") return Appearance.colors.colTertiary
                    return Appearance.colors.colError
                }
            }

            StyledText {
                text: root.lastFetchTimeStr
                    + (root.lastError.length > 0 ? "  · stale ·" : "")
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 1.5
                color: Appearance.colors.colSubtext
            }
        }

        // — Header underline —
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
        }

        // — NEXT —
        PulseSection {
            Layout.fillWidth: true
            visible: !!root.nextAction
            label: "NEXT"
            meta: "task"
            accent: Appearance.colors.colPrimary
            showCount: false

            PulseRow {
                anchors.left: parent.left
                anchors.right: parent.right
                variant: "next"
                company: root.nextAction ? (root.nextAction.task ?? "") : ""
                role: root.nextAction ? (root.nextAction.why ?? "") : ""
                obsidianPath: root.pathTasks
                vaultName: root.vaultName
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            visible: !!root.nextAction && (root.showApplied || (root.showPackageReady && root.packageReady.length > 0) || root.showShortlist)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // — APPLIED —
        PulseSection {
            Layout.fillWidth: true
            visible: root.showApplied
            label: "APPLIED"
            count: root.applied.length
            meta: root.waitingFollowup + " waiting · " + root.staleCount + " stale"
            accent: Appearance.colors.colSecondary

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                // Empty state
                PulseRow {
                    Layout.fillWidth: true
                    visible: root.applied.length === 0
                    variant: "applied"
                    company: "—"
                    role: "no submissions yet"
                    passive: true
                }

                Repeater {
                    model: root.appliedByDate
                    delegate: ColumnLayout {
                        id: _appliedGroup
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.topMargin: index === 0 ? 0 : 6
                        spacing: 0

                        // Date header
                        StyledText {
                            Layout.fillWidth: true
                            Layout.leftMargin: 10
                            Layout.bottomMargin: 2
                            text: _appliedGroup.modelData.date
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.letterSpacing: 1.2
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colSubtext
                            opacity: 0.85
                        }

                        Repeater {
                            model: _appliedGroup.modelData.items
                            delegate: PulseRow {
                                required property var modelData
                                Layout.fillWidth: true
                                variant: "applied"
                                company: modelData.company ?? ""
                                role: modelData.role ?? ""
                                status: modelData.status ?? ""
                                notes: modelData.notes ?? ""
                                dateStr: modelData.date ?? ""
                                passive: modelData.is_passive === true
                                obsidianPath: root.pathSprint
                                vaultName: root.vaultName
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            visible: root.showApplied && (root.showPackageReady && root.packageReady.length > 0 || root.showShortlist)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // — PACKAGE READY —
        PulseSection {
            Layout.fillWidth: true
            visible: root.showPackageReady && root.packageReady.length > 0
            label: "PACKAGE READY"
            count: root.packageReady.length
            meta: "not submitted"
            accent: Appearance.colors.colTertiary

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Repeater {
                    model: root.packageReady
                    delegate: PulseRow {
                        required property var modelData
                        Layout.fillWidth: true
                        variant: "ready"
                        company: modelData.company ?? ""
                        role: modelData.role ?? ""
                        notes: modelData.notes ?? ""
                        marker: "SHIP"
                        obsidianPath: root.pathSprint
                        vaultName: root.vaultName
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            visible: root.showPackageReady && root.packageReady.length > 0 && root.showShortlist
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // — SHORTLIST —
        PulseSection {
            Layout.fillWidth: true
            visible: root.showShortlist
            label: "SHORTLIST"
            count: root.shortlist.length
            meta: "to apply"
            accent: Appearance.colors.colSubtext

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                PulseRow {
                    Layout.fillWidth: true
                    visible: root.shortlist.length === 0
                    variant: "shortlist"
                    company: "—"
                    role: "shortlist empty"
                    passive: true
                }

                Repeater {
                    model: root.shortlist
                    delegate: PulseRow {
                        required property var modelData
                        Layout.fillWidth: true
                        variant: "shortlist"
                        company: modelData.company ?? ""
                        role: modelData.role ?? ""
                        notes: modelData.notes ?? ""
                        priorityTag: modelData.priority ?? ""
                        obsidianPath: root.pathShortlist
                        vaultName: root.vaultName
                    }
                }
            }
        }
    }

    // — job-pulse subprocess —
    Process {
        id: pulseFetch
        command: ["job-pulse", "--no-mail", "--json"]
        stdout: StdioCollector {
            id: pulseOut
            onStreamFinished: {
                const raw = pulseOut.text
                if (!raw || raw.length === 0) {
                    root.lastError = "empty stdout"
                    return
                }
                try {
                    const data = JSON.parse(raw)
                    const apps = (data.applications && data.applications.apps) || []
                    root.applied = apps.filter(a => a.is_submitted === true)
                    root.packageReady = (data.applications && data.applications.package_ready) || []
                    root.shortlist = (data.shortlist && data.shortlist.targets) || []
                    const nba = data.next_best_action
                    if (nba && typeof nba === "string") {
                        root.nextAction = { task: nba, why: "", date: "" }
                    } else if (nba && typeof nba === "object") {
                        root.nextAction = nba
                    } else {
                        root.nextAction = null
                    }
                    root.directSubmittedTotal = (data.applications && data.applications.direct_submitted_count) || 0
                    root.waitingFollowup = ((data.applications && data.applications.waiting_followup) || []).length
                    root.staleCount = ((data.applications && data.applications.stale) || []).length
                    root.lastSuccessAt = Date.now()
                    root.lastError = ""
                } catch (e) {
                    root.lastError = "parse: " + e.toString()
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.lastError.length === 0)
                root.lastError = "exit " + exitCode
        }
    }

    function fetchPulse() {
        pulseFetch.running = false
        pulseFetch.running = true
    }

    Component.onCompleted: root.fetchPulse()

    onVisibleChanged: {
        if (visible) _visibleDebounce.restart()
    }
    Timer {
        id: _visibleDebounce
        interval: 200
        repeat: false
        onTriggered: if (root.visible) root.fetchPulse()
    }

    Timer {
        running: root.visible
        interval: root.refreshIntervalMs
        repeat: true
        onTriggered: root.fetchPulse()
    }

    Timer {
        running: root.visible
        interval: 60000
        repeat: true
        onTriggered: root._freshnessTick++
    }
}
