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
        color: Appearance.colors.colLayer2
        radius: 0
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
                radius: Appearance.rounding.small
                color: backHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            }

            MaterialSymbol {
                id: backIcon
                anchors.centerIn: parent
                text: "arrow_back"
                iconSize: Appearance.font.pixelSize.normal * root.fontScale
                color: Appearance.colors.colOnLayer1
            }

            TapHandler {
                onTapped: root.backClicked()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.pathText
            font.pixelSize: Appearance.font.pixelSize.smaller * root.fontScale
            color: Appearance.colors.colSubtext
            elide: Text.ElideLeft
        }
    }
}
