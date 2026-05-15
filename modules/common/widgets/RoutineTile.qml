import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    property string timestamp: ""
    property string label: ""
    property string actionText: "OPEN"

    signal actionClicked()

    implicitHeight: tileRow.implicitHeight + 14
    implicitWidth: 200

    RowLayout {
        id: tileRow
        anchors.fill: parent
        anchors.topMargin: 7
        anchors.bottomMargin: 7
        spacing: 8

        StyledText {
            text: root.timestamp
            font.pixelSize: 10
            font.family: Appearance.font.family.monospace
            color: ColorUtils.transparentize(Appearance.mission.colText, 0.8)
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: root.label
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.family: Appearance.font.family.monospace
            font.letterSpacing: 0.8
            color: Appearance.m3colors.m3onBackground
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        StyledText {
            text: root.actionText + " ↗"
            font.pixelSize: 10
            font.family: Appearance.font.family.monospace
            color: ColorUtils.transparentize(Appearance.mission.colText, 0.8)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionClicked()
            }
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
