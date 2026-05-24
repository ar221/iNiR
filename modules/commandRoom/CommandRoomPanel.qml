pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Command Room Panel — read-only ops overlay, summoned on demand.
// MIRROR shell: modules/cheatsheet/Cheatsheet.qml
// MIRROR styling: modules/background/widgets/commandRoom/CommandRoomWidget.qml
Scope {
    id: root

    property bool panelOpen: false

    function open()   { root.panelOpen = true }
    function close()  { root.panelOpen = false }
    function toggle() { root.panelOpen = !root.panelOpen }

    IpcHandler {
        target: "commandRoomPanel"
        function toggle(): void { root.toggle() }
        function open(): void   { root.open() }
        function close(): void  { root.close() }
    }

    // Hyprland-only shortcuts
    Loader {
        active: CompositorService.isHyprland
        sourceComponent: Item {
            GlobalShortcut {
                name: "commandRoomPanelToggle"
                description: "Toggles Command Room ops panel"
                onPressed: root.toggle()
            }
        }
    }

    PanelWindow {
        id: window
        visible: root.panelOpen
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "quickshell:commandRoomPanel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.panelOpen
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors { top: true; bottom: true; left: true; right: true }

        // Scrim backdrop — MIRROR Cheatsheet.qml:86-108
        Rectangle {
            anchors.fill: parent
            z: -1
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, 1 - 0.80)
            opacity: root.panelOpen ? 1 : 0
            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root.panelOpen
                        ? (Appearance.animation.elementMoveEnter.duration)
                        : (Appearance.animation.elementMoveExit.duration)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.panelOpen
                        ? Appearance.animationCurves.emphasizedDecel
                        : Appearance.animationCurves.emphasizedAccel
                }
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: mouse => {
                const lp = mapToItem(panelBackground, mouse.x, mouse.y)
                if (lp.x < 0 || lp.x > panelBackground.width
                        || lp.y < 0 || lp.y > panelBackground.height)
                    root.close()
                else
                    mouse.accepted = false
            }
        }

        StyledRectangularShadow {
            target: panelBackground
            radius: panelBackground.radius
        }

        Rectangle {
            id: panelBackground
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 860)
            height: Math.min(parent.height - 80, 680)
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.windowRounding

            scale: root.panelOpen ? 1.0 : 0.95
            opacity: root.panelOpen ? 1 : 0

            Behavior on scale {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root.panelOpen
                        ? (Appearance.animation.elementMoveEnter.duration ?? 400)
                        : (Appearance.animation.elementMoveExit.duration ?? 200)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.panelOpen
                        ? (Appearance.animationCurves.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1])
                        : (Appearance.animationCurves.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }
            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root.panelOpen
                        ? (Appearance.animation.elementMoveEnter.duration ?? 400)
                        : (Appearance.animation.elementMoveExit.duration ?? 200)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.panelOpen
                        ? (Appearance.animationCurves.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1])
                        : (Appearance.animationCurves.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }

            Keys.onPressed: event => {
                if (!root.panelOpen) return
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }

            ColumnLayout {
                id: panelContent
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // ── Header strip ────────────────────────────────────────
                // MIRROR: CommandRoomWidget.qml:118-163
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    StyledText {
                        text: "COMMAND ROOM"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                        font.letterSpacing: 2.5
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: CommandRoom.usingFallback ? "LEGACY" : "PROJECTION"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.letterSpacing: 1.2
                        color: Appearance.colors.colSubtext
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: freshnessRow.implicitWidth + 14
                        implicitHeight: freshnessRow.implicitHeight + 8
                        radius: Appearance.rounding.unsharpen
                        color: ColorUtils.transparentize(root._freshnessColor, 0.86)
                        border.width: 1
                        border.color: ColorUtils.transparentize(root._freshnessColor, 0.45)

                        RowLayout {
                            id: freshnessRow
                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                implicitWidth: 6; implicitHeight: 6; radius: 3
                                color: root._freshnessColor
                            }
                            StyledText {
                                text: root._freshnessLabel
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.1
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }

                // Source path
                StyledText {
                    Layout.fillWidth: true
                    text: CommandRoom.generatedAt.length > 0
                        ? "generated " + CommandRoom.generatedAt
                        : Directories.shortHomePath(CommandRoom.sourcePath)
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.letterSpacing: 1
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
                }

                // ── Observability rail ── all 7 metrics
                // MIRROR: CommandRoomWidget.qml:215-224
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 0

                    MetricPill { label: "OPEN";     value: String(CommandRoom.openTaskCount);             hot: false }
                    MetricPill { label: "RUNNING";  value: String(CommandRoom.runningRunCount);           hot: CommandRoom.staleRunCount > 0 }
                    MetricPill { label: "PAUSED";   value: String(CommandRoom.pausedRunCount);            hot: CommandRoom.pausedRunCount > 0 }
                    MetricPill { label: "STALE";    value: String(CommandRoom.staleRunCount);             hot: CommandRoom.staleRunCount > 0 }
                    MetricPill { label: "APPROVE";  value: String(CommandRoom.pendingApprovalCount);      hot: CommandRoom.pendingApprovalCount > 0 }
                    MetricPill { label: "DELIVER";  value: String(CommandRoom.queuedDeliveryCount);       hot: CommandRoom.queuedDeliveryCount > 0 }
                    MetricPill { label: "MEMORY";   value: String(CommandRoom.pendingMemoryWriteCount);   hot: CommandRoom.pendingMemoryWriteCount > 0 }
                }

                // ── Main body: two columns ─────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    // Left column: tasks + anomalies
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        // Open tasks list
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            StyledText {
                                text: "OPEN TASKS"
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.Bold
                                font.letterSpacing: 1.4
                                color: Appearance.colors.colSubtext
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: CommandRoom.openTaskCount === 0 && CommandRoom.cards.length === 0 && CommandRoom.lastError.length === 0
                                text: "Board is clear."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: CommandRoom.lastError.length > 0
                                text: CommandRoom.lastError
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colError
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Scrollable task list
                        // MIRROR: CommandRoomWidget.qml:299-426 (task row pattern)
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            ColumnLayout {
                                width: parent.width
                                spacing: 6

                                // Cards (inir-cards projection)
                                Repeater {
                                    model: CommandRoom.cards

                                    delegate: Rectangle {
                                        id: cardDelegate
                                        required property var modelData
                                        required property int index

                                        width: parent.width
                                        implicitHeight: cardDelegateContent.implicitHeight + 14
                                        radius: Appearance.rounding.unsharpen
                                        color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.34)
                                        border.width: 1
                                        border.color: ColorUtils.transparentize(
                                            root._severityColor(String(cardDelegate.modelData?.severity ?? "UNKNOWN")), 0.62)

                                        ColumnLayout {
                                            id: cardDelegateContent
                                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                            anchors.leftMargin: 10; anchors.rightMargin: 10
                                            spacing: 3

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 7
                                                StyledText {
                                                    text: String(cardDelegate.modelData?.severity ?? "UNKNOWN").toUpperCase()
                                                    font.family: Appearance.font.family.monospace
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: root._severityColor(String(cardDelegate.modelData?.severity ?? "UNKNOWN"))
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: String(cardDelegate.modelData?.title ?? cardDelegate.modelData?.id ?? "Card")
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: Font.DemiBold
                                                    color: Appearance.colors.colOnLayer0
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                }
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: String(cardDelegate.modelData?.summary ?? "")
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: Appearance.colors.colSubtext
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }
                                        }
                                    }
                                }

                                // Open task rows (legacy cockpit projection)
                                Repeater {
                                    model: CommandRoom.openTasks

                                    delegate: Rectangle {
                                        id: taskDelegate
                                        required property var modelData
                                        required property int index

                                        width: parent.width
                                        implicitHeight: taskDelegateContent.implicitHeight + 14
                                        radius: Appearance.rounding.unsharpen
                                        color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.34)
                                        border.width: 1
                                        border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.90)

                                        ColumnLayout {
                                            id: taskDelegateContent
                                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                            anchors.leftMargin: 10; anchors.rightMargin: 10
                                            spacing: 3

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 7
                                                StyledText {
                                                    text: "#" + String(taskDelegate.modelData?.id ?? taskDelegate.index + 1)
                                                    font.family: Appearance.font.family.monospace
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: Appearance.colors.colPrimary
                                                }
                                                StyledText {
                                                    text: String(taskDelegate.modelData?.priority ?? "normal").toUpperCase()
                                                    font.family: Appearance.font.family.monospace
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.DemiBold
                                                    font.letterSpacing: 1.1
                                                    color: Appearance.colors.colTertiary
                                                }
                                                StyledText {
                                                    text: String(taskDelegate.modelData?.status ?? "open").toUpperCase()
                                                    font.family: Appearance.font.family.monospace
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.DemiBold
                                                    font.letterSpacing: 1.1
                                                    color: Appearance.colors.colSubtext
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: String(taskDelegate.modelData?.owner ?? "unassigned")
                                                    font.family: Appearance.font.family.monospace
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.letterSpacing: 1.1
                                                    color: Appearance.colors.colSubtext
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                }
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: String(taskDelegate.modelData?.title ?? "Untitled task")
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnLayer0
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                wrapMode: Text.WordWrap
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                visible: {
                                                    const ns = taskDelegate.modelData?.metadata?.next_slice ?? ""
                                                    return ns.length > 0
                                                }
                                                text: "NEXT: " + String(taskDelegate.modelData?.metadata?.next_slice ?? "")
                                                font.family: Appearance.font.family.monospace
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                font.letterSpacing: 1
                                                color: Appearance.m3colors.m3primary
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Anomaly section — only when anomalyCount > 0
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: CommandRoom.anomalyCount > 0
                            spacing: 6

                            StyledText {
                                text: "ANOMALIES"
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.Bold
                                font.letterSpacing: 1.4
                                color: Appearance.colors.colError
                            }

                            Repeater {
                                model: CommandRoom.anomalies

                                delegate: Rectangle {
                                    id: anomalyDelegate
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    implicitHeight: anomalyDelegateText.implicitHeight + 12
                                    radius: Appearance.rounding.unsharpen
                                    color: ColorUtils.transparentize(Appearance.colors.colError, 0.90)
                                    border.width: 1
                                    border.color: ColorUtils.transparentize(Appearance.colors.colError, 0.55)

                                    StyledText {
                                        id: anomalyDelegateText
                                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                        anchors.leftMargin: 10; anchors.rightMargin: 10
                                        text: String(anomalyDelegate.modelData?.type ?? "anomaly").replace(/_/g, " ").toUpperCase()
                                        font.family: Appearance.font.family.monospace
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1.1
                                        color: Appearance.colors.colOnLayer0
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillHeight: true
                        implicitWidth: 1
                        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.90)
                    }

                    // Right column: recent events ribbon
                    ColumnLayout {
                        Layout.preferredWidth: 280
                        Layout.fillHeight: true
                        spacing: 8

                        StyledText {
                            text: "RECENT EVENTS"
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            font.letterSpacing: 1.4
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            visible: CommandRoom.events.length === 0
                            text: "No events in projection."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            ColumnLayout {
                                width: parent.width
                                spacing: 4

                                Repeater {
                                    model: CommandRoom.events.slice(0, 10)

                                    delegate: ColumnLayout {
                                        id: eventDelegate
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        spacing: 1

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            // Timestamp — show HH:MM only
                                            StyledText {
                                                text: {
                                                    const ts = String(eventDelegate.modelData?.created_at ?? "")
                                                    if (ts.length < 16) return "--:--"
                                                    // ISO timestamp: 2026-05-24T18:59:11+00:00 → 18:59
                                                    const t = ts.indexOf("T")
                                                    return t >= 0 ? ts.substring(t + 1, t + 6) : ts.substring(0, 5)
                                                }
                                                font.family: Appearance.font.family.monospace
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                font.letterSpacing: 1
                                                color: Appearance.colors.colSubtext
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: String(eventDelegate.modelData?.event_type ?? "event").replace(/\./g, " ")
                                                font.family: Appearance.font.family.monospace
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                font.weight: Font.DemiBold
                                                font.letterSpacing: 1
                                                color: Appearance.m3colors.m3primary
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: {
                                                const ev = eventDelegate.modelData
                                                const t = String(ev?.entity_type ?? "")
                                                const id = ev?.entity_id != null ? "#" + ev.entity_id : ""
                                                const adapter = ev?.payload?.adapter ?? ev?.payload?.applier ?? ""
                                                const parts = [t, id, adapter].filter(s => s.length > 0)
                                                return parts.join(" ")
                                            }
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.letterSpacing: 1
                                            color: Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        // Divider between events
                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 1
                                            color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.94)
                                            visible: eventDelegate.index < Math.min(CommandRoom.events.length, 10) - 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Helper functions — MIRROR CommandRoomWidget.qml:49-58 ──
    function _severityColor(severity) {
        const value = String(severity || "UNKNOWN").toUpperCase()
        if (value === "FAIL")  return Appearance.colors.colError
        if (value === "WARN")  return Appearance.colors.colTertiary
        if (value === "OK")    return Appearance.m3colors.m3primary
        return Appearance.colors.colSubtext
    }

    readonly property color _freshnessColor: {
        if (CommandRoom.anomalyCount > 0)       return Appearance.colors.colError
        if (CommandRoom.staleRunCount > 0)      return Appearance.colors.colTertiary
        if (CommandRoom.freshnessState === "fresh") return Appearance.m3colors.m3primary
        if (CommandRoom.freshnessState === "stale") return Appearance.colors.colTertiary
        return Appearance.colors.colError
    }

    readonly property string _freshnessLabel: {
        const state = CommandRoom.freshnessState
        const age   = CommandRoom.ageMinutes
        const ageStr = age < 0 ? "no signal" : age === 0 ? "now" : age + "m ago"
        return state.toUpperCase() + " / " + ageStr
    }

    // ── MetricPill component — MIRROR CommandRoomWidget.qml:430-464 ──
    component MetricPill: Rectangle {
        required property string label
        required property string value
        property bool hot: false

        Layout.fillWidth: true
        implicitHeight: _mpRow.implicitHeight + 8
        radius: Appearance.rounding.unsharpen
        color: ColorUtils.transparentize(
            hot ? Appearance.colors.colTertiary : Appearance.colors.colLayer1,
            hot ? 0.86 : 0.42)
        border.width: 1
        border.color: ColorUtils.transparentize(
            hot ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer0,
            hot ? 0.45 : 0.9)

        ColumnLayout {
            id: _mpRow
            anchors.centerIn: parent
            spacing: 1

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: value
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                color: hot ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer0
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: label
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest - 1
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                color: Appearance.colors.colSubtext
            }
        }
    }
}
