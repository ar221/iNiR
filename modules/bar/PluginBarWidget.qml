import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Generic bar widget for rendering external plugin data.
 * Displays an icon + text, with color driven by the plugin's status field.
 */
Item {
    id: root

    required property string pluginId
    required property string pluginIcon
    required property string pluginText
    required property string pluginTooltip
    required property string pluginStatus
    required property real pluginValue

    clip: true
    visible: width > 0 && height > 0
    implicitWidth: pluginText.length > 0 ? contentRow.implicitWidth : 0
    implicitHeight: Appearance.sizes.barHeight

    readonly property color statusColor: {
        switch (pluginStatus) {
            case "error": return Appearance.inirEverywhere ? Appearance.inir.colError : Appearance.colors.colError
            case "warning": return Appearance.inirEverywhere ? (Appearance.inir.colWarning ?? Appearance.m3colors.m3tertiary) : Appearance.m3colors.m3tertiary
            default: return Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        property bool hovered: containsMouse

        PopupToolTip {
            extraVisibleCondition: root.pluginTooltip.length > 0
            text: root.pluginTooltip
        }
    }

    RowLayout {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        MaterialSymbol {
            visible: root.pluginIcon.length > 0
            text: root.pluginIcon
            iconSize: Appearance.font.pixelSize.normal
            fill: 1
            color: root.statusColor
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: root.pluginText
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.statusColor
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
