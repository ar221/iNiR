import QtQuick
import QtQuick.Layouts
import qs.modules.common

Rectangle {
    id: root

    property string status: "idle"

    readonly property color _statusColor: {
        switch (status) {
        case "active": return Appearance.mission.colActive
        case "running": return Appearance.mission.colDone
        case "error": return Appearance.mission.colCritical
        case "waiting": return Appearance.colors.colSecondary
        case "scheduled": return Appearance.colors.colSecondary
        default: return Qt.rgba(Appearance.mission.colText.r,
                                Appearance.mission.colText.g,
                                Appearance.mission.colText.b, 0.3)
        }
    }

    readonly property string _label: {
        switch (status) {
        case "active": return "ACTIVE"
        case "running": return "RUNNING"
        case "error": return "ERROR"
        case "waiting": return "WAITING"
        case "scheduled": return "SCHEDULED"
        default: return "IDLE"
        }
    }

    implicitWidth: pillRow.implicitWidth + 20
    implicitHeight: pillRow.implicitHeight + 8
    radius: 4
    color: Qt.rgba(_statusColor.r, _statusColor.g, _statusColor.b, 0.08)
    border.width: 1
    border.color: Qt.rgba(_statusColor.r, _statusColor.g, _statusColor.b, 0.2)

    RowLayout {
        id: pillRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            id: dot
            width: 6
            height: 6
            radius: 3
            color: root._statusColor

            SequentialAnimation on opacity {
                running: root.status === "active" && Appearance.animationsEnabled
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 1000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
            }
        }

        StyledText {
            text: root._label
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
            font.family: Appearance.font.family.monospace
            color: root._statusColor
        }
    }
}
