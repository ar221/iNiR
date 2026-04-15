pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property string iconName
    required property bool active
    property string tooltip: ""

    signal clicked()

    width: 32
    height: 32

    // Active indicator bar (left edge, positioned relative to rail parent)
    Rectangle {
        x: -root.x  // Align to rail's left edge
        width: 2
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        radius: 1
        color: "#ff1100"
        opacity: root.active ? 1 : 0
        Behavior on opacity {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.active ? Qt.rgba(1, 0.067, 0, 0.08)
             : mouseArea.containsMouse ? Appearance.colors.colLayer1Hover
             : "transparent"
        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
            }
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.iconName
        iconSize: 18
        color: root.active ? "#ff1100"
             : Qt.rgba(
                 Appearance.colors.colOnSurfaceVariant.r,
                 Appearance.colors.colOnSurfaceVariant.g,
                 Appearance.colors.colOnSurfaceVariant.b,
                 0.4
               )
        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
