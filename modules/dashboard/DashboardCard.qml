import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Shared card container for all dashboard cards.
// Provides consistent background, border, radius, padding, and optional header.
// Height is content-driven by default; cards that need to fill remaining space
// should set Layout.fillHeight: true on themselves.
Rectangle {
    id: root

    property string headerText: ""
    property bool showHeader: headerText !== ""
    default property alias content: contentColumn.data

    // Content-driven sizing: the card is as tall as its content needs
    implicitHeight: cardLayout.implicitHeight + 2 * cardLayout.anchors.topMargin
    implicitWidth: 200

    clip: true
    color: Qt.rgba(1, 1, 1, 0.025)
    border.width: 1
    border.color: hoverHandler.hovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
    radius: 16

    Behavior on border.color {
        enabled: Appearance.animationsEnabled
        ColorAnimation { duration: 150 }
    }

    HoverHandler {
        id: hoverHandler
    }

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Section header (optional)
        StyledText {
            visible: root.showHeader
            text: root.headerText.toUpperCase()
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            color: Qt.rgba(1, 1, 1, 0.4)
            Layout.fillWidth: true
        }

        // Card content slot
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
        }
    }
}
