import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string pathText: ""
    property real fontScale: 1.0

    signal backClicked()

    implicitHeight: barRow.implicitHeight + 10
    implicitWidth: barRow.implicitWidth

    Rectangle {
        anchors.fill: parent
        color: Appearance.mission.colSurfaceRaised
        radius: 0
    }

    // Bottom separator between breadcrumb bar and file list
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Appearance.mission.colBorderSubtle
    }

    RowLayout {
        id: barRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 6
            rightMargin: 8
        }
        spacing: 4

        // Back button
        Item {
            implicitWidth: backIcon.implicitWidth + 8
            implicitHeight: backIcon.implicitHeight + 8

            HoverHandler { id: backHover }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.unsharpen
                color: backHover.hovered ? Appearance.mission.colSurfaceHover : "transparent"
            }

            MaterialSymbol {
                id: backIcon
                anchors.centerIn: parent
                text: "arrow_back"
                iconSize: Appearance.font.pixelSize.normal * root.fontScale
                color: Appearance.mission.colText
            }

            TapHandler {
                onTapped: root.backClicked()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.pathText
            font.pixelSize: Appearance.font.pixelSize.smaller * root.fontScale
            font.family: Appearance.font.family.monospace
            color: Appearance.mission.colTextSecondary
            elide: Text.ElideLeft
        }
    }
}
