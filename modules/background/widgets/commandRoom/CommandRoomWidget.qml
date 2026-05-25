pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.background.widgets
import qs.services

// Command Room — pipeline-layer cockpit widget with action rail (Courier Console design language)
AbstractBackgroundWidget {
    id: root

    configEntryName: "commandRoom"

    readonly property var commandRoomConfig: configEntry
    readonly property real cardWidth: commandRoomConfig?.cardWidth ?? 460
    readonly property real cardOpacity: commandRoomConfig?.cardOpacity ?? 0.95
    readonly property int maxTasks: commandRoomConfig?.maxTasks ?? 3
    readonly property int maxAnomalies: commandRoomConfig?.maxAnomalies ?? 2
    readonly property point screenPos: root.mapToItem(null, 0, 0)
    // single-instance widget — one timer per desktop surface
    readonly property bool _isTimerOwner: Qt.application !== null

    // Local tasksByStage — computed in the widget (not relying on Singleton new-property hot-reload)
    readonly property var tasksByStage: {
        const result = { in_progress: [], pending: [], stale: [], anomaly: [] }
        const src = CommandRoom.cards.length > 0 ? CommandRoom.cards : CommandRoom.openTasks
        for (let i = 0; i < src.length; i++) {
            const item = src[i]
            let stage = String(item?.stage ?? item?.status ?? "pending").toLowerCase().replace(/-/g, "_")
            if (stage === "running" || stage === "active" || stage === "in_progress")
                stage = "in_progress"
            else if (stage === "queued" || stage === "todo" || stage === "backlog" || stage === "open" || stage === "new")
                stage = "pending"
            else if (!(stage in result))
                stage = "pending"
            result[stage].push(item)
        }
        for (let j = 0; j < CommandRoom.anomalies.length; j++)
            result.anomaly.push(CommandRoom.anomalies[j])
        return result
    }

    readonly property string statusLabel: CommandRoom.anomalyCount > 0 ? "ALERT" : CommandRoom.freshnessState.toUpperCase()
    readonly property color statusColor: {
        if (CommandRoom.anomalyCount > 0)
            return Appearance.colors.colError
        if (CommandRoom.staleRunCount > 0)
            return Appearance.colors.colTertiary
        if (CommandRoom.freshnessState === "fresh")
            return Appearance.m3colors.m3primary
        if (CommandRoom.freshnessState === "stale")
            return Appearance.colors.colTertiary
        return Appearance.colors.colError
    }
    readonly property string ageLabel: {
        if (CommandRoom.ageMinutes < 0)
            return "no signal"
        if (CommandRoom.ageMinutes === 0)
            return "now"
        return CommandRoom.ageMinutes + "m ago"
    }

    function _stageColor(stage) {
        switch (String(stage)) {
        case "in_progress":
            return Appearance.colors.colPrimary
        case "stale":
            return Appearance.colors.colTertiary
        case "anomaly":
            return Appearance.colors.colError
        default:
            return Appearance.colors.colOnLayer0
        }
    }

    function _severityColor(severity) {
        const value = String(severity || "UNKNOWN").toUpperCase()
        if (value === "FAIL")
            return Appearance.colors.colError
        if (value === "WARN")
            return Appearance.colors.colTertiary
        if (value === "OK")
            return Appearance.m3colors.m3primary
        return Appearance.colors.colSubtext
    }

    function _isValidLogPath(p) {
        const home = Directories.homePath
        return p.length > 0
            && (p.startsWith(home + "/.local/state/command-room/")
                || p.startsWith(home + "/.claude/projects/")
                || p.startsWith(home + "/Github/inir/.agents/"))
    }

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

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
            fallbackColor: ColorUtils.transparentize(Appearance.colors.colLayer0, 1.0 - root.cardOpacity)
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(Appearance.colors.colLayer0, 1.0 - root.cardOpacity)
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

    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ── Header ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: "COMMAND ROOM"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: Appearance.colors.colPrimary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: statusRow.implicitWidth + 14
                implicitHeight: statusRow.implicitHeight + 8
                radius: 3
                color: ColorUtils.transparentize(root.statusColor, 0.86)
                border.width: 1
                border.color: ColorUtils.transparentize(root.statusColor, 0.45)

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: root.statusColor
                    }

                    StyledText {
                        text: root.statusLabel + " / " + root.ageLabel
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
        }

        // ── Stats row ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledText {
                text: CommandRoom.openTaskCount + " OPEN"
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                text: CommandRoom.runningRunCount + " RUNNING"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
                color: CommandRoom.staleRunCount > 0 ? Appearance.colors.colTertiary : Appearance.colors.colSubtext
            }

            StyledText {
                visible: CommandRoom.anomalyCount > 0
                text: CommandRoom.anomalyCount + " ANOM"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Bold
                font.letterSpacing: 1.1
                color: Appearance.colors.colError
            }

            StyledText {
                Layout.fillWidth: true
                text: CommandRoom.generatedAt.length > 0 ? (CommandRoom.usingFallback ? "legacy / " : "projection / ") + CommandRoom.generatedAt : Directories.shortHomePath(CommandRoom.sourcePath)
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 1.1
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // ── Metric pills ───────────────────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 8
            rowSpacing: 8

            MetricPill { label: "RUN"; value: String(CommandRoom.runningRunCount); hot: CommandRoom.staleRunCount > 0 }
            MetricPill { label: "APPROVE"; value: String(CommandRoom.pendingApprovalCount); hot: CommandRoom.pendingApprovalCount > 0 }
            MetricPill { label: "QUEUE"; value: String(CommandRoom.queuedDeliveryCount + CommandRoom.pendingMemoryWriteCount); hot: (CommandRoom.queuedDeliveryCount + CommandRoom.pendingMemoryWriteCount) > 0 }
        }

        // ── Error state ────────────────────────────────────────────────────
        StyledText {
            Layout.fillWidth: true
            visible: CommandRoom.lastError.length > 0
            text: CommandRoom.lastError === "Projection missing" ? "No cockpit projection yet." : CommandRoom.lastError
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: CommandRoom.lastError === "Projection missing" ? Appearance.colors.colSubtext : Appearance.colors.colError
            wrapMode: Text.WordWrap
        }

        // ── Pipeline sections ──────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: CommandRoom.lastError.length === 0

            // IN PROGRESS — always visible
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0Border, 0.4)
                }

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: root.width >= 280 ? "IN PROGRESS" : "RUNNING"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Appearance.colors.colPrimary
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: ipBadge.implicitWidth + 10
                        implicitHeight: ipBadge.implicitHeight + 6
                        radius: 2
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.86)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.45)

                        StyledText {
                            id: ipBadge
                            anchors.centerIn: parent
                            text: String(root.tasksByStage.in_progress.length)
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colPrimary
                        }
                    }
                }

                Repeater {
                    model: root.tasksByStage.in_progress
                    delegate: CardRow {
                        required property var modelData
                        required property int index
                        stage: "in_progress"
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.tasksByStage.in_progress.length === 0
                    text: "—"
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }
            }

            // PENDING — always visible
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0Border, 0.4)
                }

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: root.width >= 280 ? "PENDING" : "QUEUE"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: pendingBadge.implicitWidth + 10
                        implicitHeight: pendingBadge.implicitHeight + 6
                        radius: 2
                        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.9)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.65)

                        StyledText {
                            id: pendingBadge
                            anchors.centerIn: parent
                            text: String(root.tasksByStage.pending.length)
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }

                Repeater {
                    model: root.tasksByStage.pending
                    delegate: CardRow {
                        required property var modelData
                        required property int index
                        stage: "pending"
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.tasksByStage.pending.length === 0
                    text: "—"
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }

                AddTaskControl {
                    Layout.fillWidth: true
                    visible: root.width >= 320
                }
            }

            // STALE — hidden when count = 0
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.tasksByStage.stale.length > 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0Border, 0.4)
                }

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: "STALE"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Appearance.colors.colTertiary
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: staleBadge.implicitWidth + 10
                        implicitHeight: staleBadge.implicitHeight + 6
                        radius: 2
                        color: ColorUtils.transparentize(Appearance.colors.colTertiary, 0.86)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colTertiary, 0.45)

                        StyledText {
                            id: staleBadge
                            anchors.centerIn: parent
                            text: String(root.tasksByStage.stale.length)
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colTertiary
                        }
                    }
                }

                Repeater {
                    model: root.tasksByStage.stale
                    delegate: CardRow {
                        required property var modelData
                        required property int index
                        stage: "stale"
                    }
                }
            }

            // ANOMALY — hidden when count = 0
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.tasksByStage.anomaly.length > 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0Border, 0.4)
                }

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: root.width >= 280 ? "ANOMALY" : "ALERT"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Appearance.colors.colError
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: anomalyBadge.implicitWidth + 10
                        implicitHeight: anomalyBadge.implicitHeight + 6
                        radius: 2
                        color: ColorUtils.transparentize(Appearance.colors.colError, 0.86)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colError, 0.45)

                        StyledText {
                            id: anomalyBadge
                            anchors.centerIn: parent
                            text: String(root.tasksByStage.anomaly.length)
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colError
                        }
                    }
                }

                Repeater {
                    model: root.tasksByStage.anomaly
                    delegate: CardRow {
                        required property var modelData
                        required property int index
                        stage: "anomaly"
                    }
                }
            }
        }
    }

    // 60s fallback refresh — belt-and-suspenders poll since the widget itself
    // has no polling timer (relies on FileView inotify + service retryTimer).
    // _isTimerOwner guard documents the single-instance assumption: two monitor
    // setups would double the poll rate; acceptable given background widget usage.
    Timer {
        running: root._isTimerOwner && root.visible
        interval: 60000
        repeat: true
        onTriggered: CommandRoom.refresh()
    }

    // ── CardRow ─────────────────────────────────────────────────────────────
    component CardRow: Rectangle {
        id: cardRow
        required property var modelData
        required property int index
        property string stage: "pending"
        property bool cancelPending: false
        property bool logExpanded: false
        property bool flashing: false
        property string resolvedLogPath: ""
        property var logLines: []

        Layout.fillWidth: true
        radius: 4
        color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.34)
        border.width: 1
        border.color: cardRow.flashing
            ? Appearance.colors.colPrimary
            : ColorUtils.transparentize(root._stageColor(cardRow.stage), 0.62)
        implicitHeight: cardInnerColumn.implicitHeight
        Behavior on border.color { ColorAnimation { duration: 150 } }

        HoverHandler { id: cardHover }

        Process {
            id: promoteProc
            command: ["inir-widget-action", "commandroom", "promote", "--id", String(cardRow.modelData?.id ?? "")]
            onExited: (code, status) => {
                cardRow.flashing = false
                CommandRoom.refresh()
            }
        }

        Process {
            id: cancelProc
            command: ["inir-widget-action", "commandroom", "cancel", "--id", String(cardRow.modelData?.id ?? "")]
            onExited: (code, status) => {
                cardRow.cancelPending = false
                CommandRoom.refresh()
            }
        }

        Timer {
            id: flashTimer
            interval: 300
            repeat: false
            onTriggered: cardRow.flashing = false
        }

        // Resolve active run log path via command-room CLI
        Process {
            id: resolveProc
            command: ["command-room", "run", "list",
                      "--task-id", String(cardRow.modelData?.id ?? ""),
                      "--status", "running", "--json"]
            stdout: SplitParser {
                splitMarker: ""
                onRead: data => {
                    try {
                        const resp = JSON.parse(data)
                        const runs = resp?.runs ?? []
                        if (runs.length > 0) {
                            const lp = runs[0]?.metadata?.dispatch?.log_path
                            const candidate = (lp && lp.length > 0)
                                ? lp
                                : (CommandRoom.runsDir + "/" + runs[0].id + ".log")
                            cardRow.resolvedLogPath = root._isValidLogPath(candidate) ? candidate : ""
                        } else {
                            const fallback = CommandRoom.resolveLogPath(String(cardRow.modelData?.id ?? ""))
                            cardRow.resolvedLogPath = root._isValidLogPath(fallback) ? fallback : ""
                        }
                    } catch (_) {
                        const fallback = CommandRoom.resolveLogPath(String(cardRow.modelData?.id ?? ""))
                        cardRow.resolvedLogPath = root._isValidLogPath(fallback) ? fallback : ""
                    }
                }
            }
        }

        // Poll last 30 lines from the run log
        Process {
            id: tailProc
            stdout: SplitParser {
                splitMarker: ""
                onRead: data => {
                    const raw = data.trimEnd().split("\n")
                    cardRow.logLines = raw.filter(l => l.length > 0)
                }
            }
        }

        // Drive tailProc while log is expanded and path is resolved
        Timer {
            id: logPollTimer
            interval: 5000
            repeat: true
            triggeredOnStart: true
            running: cardRow.logExpanded && cardRow.resolvedLogPath.length > 0
                     && cardRow.stage === "in_progress"
            onTriggered: {
                if (cardRow.resolvedLogPath.length > 0 && !tailProc.running) {
                    tailProc.command = ["tail", "-n", "30", cardRow.resolvedLogPath]
                    tailProc.running = true
                }
            }
        }

        Component.onCompleted: {
            if (cardRow.stage === "in_progress") {
                if (cardRow.resolvedLogPath.length > 0 || cardRow.resolvedLogPath === "resolving")
                    return
                cardRow.resolvedLogPath = "resolving"
                resolveProc.running = true
            }
        }

        ColumnLayout {
            id: cardInnerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            // Card body with action rail overlay
            Item {
                Layout.fillWidth: true
                implicitHeight: cardBodyContent.implicitHeight + 14

                ColumnLayout {
                    id: cardBodyContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        Rectangle {
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: root._stageColor(cardRow.stage)
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: String(cardRow.modelData?.title ?? cardRow.modelData?.id ?? "Command-room card")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: String(cardRow.modelData?.summary ?? cardRow.modelData?.owner ?? "")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                // Action rail — hover reveal, bottom-right, 150ms fade
                RowLayout {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 6
                    anchors.bottomMargin: 4
                    spacing: 2
                    visible: root.width >= 240
                    opacity: cardHover.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // Promote — pending and stale only
                    Rectangle {
                        visible: cardRow.stage !== "in_progress" && cardRow.stage !== "anomaly"
                        width: 32
                        height: 32
                        radius: 2
                        color: promoteHitHover.hovered ? Appearance.colors.colLayer2 : "transparent"
                        HoverHandler { id: promoteHitHover }
                        TapHandler {
                            onTapped: {
                                if (promoteProc.running)
                                    return
                                cardRow.flashing = true
                                flashTimer.start()
                                promoteProc.running = true
                            }
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "play_arrow"
                            iconSize: 16
                            color: Appearance.colors.colPrimary
                        }
                    }

                    // Log toggle — in_progress + width >= 380 + log available or resolving
                    Rectangle {
                        visible: cardRow.stage === "in_progress" && root.width >= 380
                                 && (resolveProc.running || cardRow.resolvedLogPath.length > 0
                                     || Array.isArray(cardRow.modelData?.log))
                        width: 32
                        height: 32
                        radius: 2
                        color: logToggleHover.hovered ? Appearance.colors.colLayer2 : "transparent"
                        HoverHandler { id: logToggleHover }
                        TapHandler { onTapped: cardRow.logExpanded = !cardRow.logExpanded }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: cardRow.logExpanded ? "expand_less" : "terminal"
                            iconSize: 16
                            color: Appearance.colors.colSubtext
                        }
                    }

                    // Cancel
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 2
                        color: cancelHitHover.hovered ? Appearance.colors.colLayer2 : "transparent"
                        HoverHandler { id: cancelHitHover }
                        TapHandler { onTapped: cardRow.cancelPending = !cardRow.cancelPending }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "cancel"
                            iconSize: 16
                            color: Appearance.colors.colError
                        }
                    }
                }
            }

            // Cancel confirmation strip — inline expand, no modal
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cardRow.cancelPending ? 36 : 0
                clip: true
                color: ColorUtils.transparentize(Appearance.colors.colError, 0.9)
                border.width: cardRow.cancelPending ? 1 : 0
                border.color: ColorUtils.transparentize(Appearance.colors.colError, 0.45)
                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    StyledText {
                        text: "CONFIRM CANCEL"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                        color: Appearance.colors.colError
                        TapHandler {
                            onTapped: {
                                if (cancelProc.running)
                                    return
                                cancelProc.running = true
                            }
                        }
                    }

                    StyledText {
                        text: "KEEP"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.letterSpacing: 1
                        color: Appearance.colors.colSubtext
                        TapHandler {
                            onTapped: {
                                cancelProc.running = false
                                cardRow.cancelPending = false
                            }
                        }
                    }
                }
            }

            // Session log panel — in_progress only, 5-line scrollable
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: (cardRow.logExpanded && cardRow.stage === "in_progress" && root.width >= 380) ? (5 * 18 + 16) : 0
                clip: true
                color: Appearance.colors.colLayer0
                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // Left rail — 2px colPrimary signal
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 2
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.3)
                }

                Flickable {
                    id: logFlickable
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 4
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    contentHeight: logEntries.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: logEntries
                        width: logFlickable.width
                        spacing: 2

                        Repeater {
                            model: {
                                if (cardRow.logLines.length > 0)
                                    return cardRow.logLines
                                const log = cardRow.modelData?.log
                                return Array.isArray(log) ? log.slice(-20) : []
                            }

                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 6

                                StyledText {
                                    text: String(modelData?.ts ?? modelData?.timestamp ?? "")
                                    font.family: Appearance.font.family.monospace
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        const raw = modelData
                                        return typeof raw === "string" ? raw : String(raw?.msg ?? raw?.message ?? "")
                                    }
                                    font.family: Appearance.font.family.monospace
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: {
                                        const m = typeof modelData === "string" ? modelData : String(modelData?.msg ?? modelData?.message ?? "")
                                        if (/^(ERROR|FAIL|✗)/.test(m))
                                            return Appearance.colors.colError
                                        if (/^(WARN|⚠)/.test(m))
                                            return Appearance.colors.colTertiary
                                        if (/^(OK|DONE|✓)/.test(m))
                                            return Appearance.colors.colPrimary
                                        return Appearance.colors.colOnLayer0
                                    }
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── AddTaskControl ───────────────────────────────────────────────────────
    component AddTaskControl: Item {
        id: addTaskCtrl
        property bool active: false
        implicitHeight: 32

        Process {
            id: addProc
            property string taskTitle: ""
            command: ["inir-widget-action", "commandroom", "add", "--title", addProc.taskTitle]
            onExited: (code, status) => {
                addTaskCtrl.active = false
                addInput.text = ""
                CommandRoom.refresh()
            }
        }

        // Inactive: dashed affordance
        Rectangle {
            anchors.fill: parent
            visible: !addTaskCtrl.active
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.7)

            StyledText {
                anchors.centerIn: parent
                text: root.width >= 320 ? "+ ADD TASK" : "+"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 1
                color: Appearance.colors.colSubtext
            }

            TapHandler {
                onTapped: {
                    addTaskCtrl.active = true
                    addInput.forceActiveFocus()
                }
            }
        }

        // Active: single-line text input
        Rectangle {
            anchors.fill: parent
            visible: addTaskCtrl.active
            radius: 2
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colPrimary

            TextInput {
                id: addInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
                clip: true

                Keys.onReturnPressed: {
                    if (addInput.text.trim().length > 0 && !addProc.running) {
                        addProc.taskTitle = addInput.text.trim()
                        addProc.running = true
                    }
                }
                Keys.onEscapePressed: {
                    addTaskCtrl.active = false
                    addInput.text = ""
                }
            }
        }
    }

    // ── MetricPill (unchanged) ───────────────────────────────────────────────
    component MetricPill: Rectangle {
        required property string label
        required property string value
        property bool hot: false

        Layout.fillWidth: true
        implicitHeight: metricRow.implicitHeight + 10
        radius: 4
        color: ColorUtils.transparentize(hot ? Appearance.colors.colTertiary : Appearance.colors.colLayer1, hot ? 0.86 : 0.42)
        border.width: 1
        border.color: ColorUtils.transparentize(hot ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer0, hot ? 0.45 : 0.9)

        RowLayout {
            id: metricRow
            anchors.centerIn: parent
            spacing: 5

            StyledText {
                text: value
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                color: hot ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer0
            }

            StyledText {
                text: label
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                color: Appearance.colors.colSubtext
            }
        }
    }
}
