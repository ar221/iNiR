import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

DashboardCard {
    id: root

    headerText: "Agent Loop"

    property var phases: [
        { id: "context", label: "Context" },
        { id: "prompt", label: "Prompt" },
        { id: "execute", label: "Execution" },
        { id: "review", label: "Review" },
        { id: "iterate", label: "Iterate" }
    ]

    readonly property int activePhase: {
        if (Ai.waitingForApproval) return 3
        if (Ai.requestRunning) return 2
        if ((Ai.messageIDs ?? []).length === 0) return 0
        const lastId = Ai.messageIDs[Ai.messageIDs.length - 1]
        const lastMsg = Ai.messageByID[lastId]
        if (lastMsg?.role === "user") return 1
        return 4
    }

    readonly property bool running: Ai.requestRunning
    readonly property color activeCol: Appearance.colors.colPrimary

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.phases

            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 9
                color: index === root.activePhase
                    ? ColorUtils.transparentize(root.activeCol, 0.8)
                    : Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: index === root.activePhase
                    ? ColorUtils.transparentize(root.activeCol, 0.45)
                    : Qt.rgba(1, 1, 1, 0.06)

                StyledText {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: index === root.activePhase ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            MaterialSymbol {
                text: Ai.waitingForApproval ? "rule" : (root.running ? "progress_activity" : "task_alt")
                iconSize: 16
                color: Ai.waitingForApproval
                    ? Appearance.colors.colWarn
                    : (root.running ? Appearance.colors.colPrimary : Appearance.colors.colDone)
            }

            StyledText {
                Layout.fillWidth: true
                text: Ai.waitingForApproval
                    ? "Awaiting tool approval"
                    : (root.running ? "Running · request in flight" : "Idle · ready")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                text: `Model: ${Ai.currentModelId ?? "n/a"}`
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.03)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                MaterialSymbol {
                    text: "lan"
                    iconSize: 14
                    color: ClaudeCodeProxy.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }
                StyledText {
                    text: ClaudeCodeProxy.active ? "Claude Proxy: ON" : "Claude Proxy: OFF"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                MaterialSymbol {
                    text: "hub"
                    iconSize: 14
                    color: GptProxy.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }
                StyledText {
                    text: GptProxy.active ? "GPT Proxy: ON" : "GPT Proxy: OFF"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnLayer1
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 32
            buttonRadius: 9
            enabled: Ai.requestRunning
            colBackground: Qt.rgba(1, 1, 1, 0.04)
            colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
            onClicked: Ai.cancelCurrentRequest()

            contentItem: StyledText {
                anchors.centerIn: parent
                text: "Interrupt Current Request"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnLayer1
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 32
            buttonRadius: 9
            enabled: ClaudeCodeProxy.active || GptProxy.active
            colBackground: Qt.rgba(1, 0.35, 0.35, 0.15)
            colBackgroundHover: Qt.rgba(1, 0.35, 0.35, 0.24)
            onClicked: {
                if (ClaudeCodeProxy.active) ClaudeCodeProxy.stop()
                if (GptProxy.active) GptProxy.stop()
            }

            contentItem: StyledText {
                anchors.centerIn: parent
                text: "Stop Proxies"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colError
            }
        }
    }
}