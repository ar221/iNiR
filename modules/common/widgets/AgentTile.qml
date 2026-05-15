import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    property string name: ""
    property string initial: ""
    property string route: ""
    property string lastActive: ""
    property string status: "idle"

    implicitHeight: tileRow.implicitHeight + 20
    implicitWidth: 200

    RowLayout {
        id: tileRow
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 10

        Rectangle {
            width: 28
            height: 28
            radius: 4
            color: ColorUtils.transparentize(Appearance.mission.colText, 0.94)

            StyledText {
                anchors.centerIn: parent
                text: root.initial
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: ColorUtils.transparentize(Appearance.mission.colText, 0.5)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: root.name
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.family: Appearance.font.family.monospace
                font.letterSpacing: 1.0
                color: Appearance.m3colors.m3onBackground
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            StyledText {
                text: root.route + (root.lastActive ? " · " + root.lastActive : "")
                font.pixelSize: 10
                font.family: Appearance.font.family.monospace
                color: ColorUtils.transparentize(Appearance.mission.colText, 0.75)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        StatusPill {
            status: root.status
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.96)
    }
}
