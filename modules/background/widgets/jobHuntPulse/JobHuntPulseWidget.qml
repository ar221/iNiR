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

    // — Content (layout lands in Task 5; this is a placeholder) —
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        StyledText {
            Layout.fillWidth: true
            text: "JOB HUNT · PULSE"
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Bold
            font.letterSpacing: 2
            color: Appearance.colors.colPrimary
        }

        StyledText {
            Layout.fillWidth: true
            text: root.lastError.length > 0
                ? ("error: " + root.lastError)
                : root.lastSuccessAt === 0
                    ? "loading…"
                    : ("loaded · " + root.applied.length + " applied · "
                       + root.shortlist.length + " shortlist · " + root.lastFetchTimeStr)
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.smallie
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
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
                    root.packageReady = apps.filter(a => a.is_placeholder === true)
                    root.shortlist = data.shortlist || []
                    root.nextAction = data.next_best_action || null
                    root.directSubmittedTotal = (data.applications && data.applications.direct_submitted_total) || 0
                    root.waitingFollowup = (data.applications && data.applications.waiting_followup) || 0
                    root.staleCount = (data.applications && data.applications.stale_count) || 0
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
