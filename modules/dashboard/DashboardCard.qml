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
    property int headerFontSize: 11
    property bool accentHeader: false
    default property alias content: contentColumn.data

    // Content-driven sizing: the card is as tall as its content needs
    implicitHeight: cardLayout.implicitHeight + 2 * cardLayout.anchors.topMargin
    implicitWidth: 200

    clip: true
    color: hoverHandler.hovered ? Appearance.mission.colSurfaceHover : Appearance.mission.colSurface
    border.width: Appearance.mission.borderWidth
    border.color: hoverHandler.hovered ? Appearance.mission.colBorderHover : Appearance.mission.colBorderSubtle
    radius: Appearance.mission.radiusLarge

    Behavior on color {
        enabled: Appearance.animationsEnabled
        ColorAnimation { duration: 140 }
    }

    Behavior on border.color {
        enabled: Appearance.animationsEnabled
        ColorAnimation { duration: 150 }
    }

    HoverHandler {
        id: hoverHandler
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: root.accentHeader ? Appearance.mission.colBorderHot : ColorUtils.transparentize(Appearance.mission.colText, 0.92)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        opacity: root.accentHeader ? 1 : 0.5
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Appearance.mission.colScanline }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: Appearance.mission.cardPadding
        spacing: Appearance.mission.cardSpacing

        // Section header (optional)
        StyledText {
            visible: root.showHeader
            text: root.headerText.toUpperCase()
            font.pixelSize: root.headerFontSize
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            font.family: Appearance.font.family.monospace
            color: root.accentHeader ? Appearance.mission.colAccentMuted : Appearance.mission.colTextMuted
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
