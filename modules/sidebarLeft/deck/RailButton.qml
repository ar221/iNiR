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

    width: 34
    height: 34

    // Active indicator bar (left edge, positioned relative to rail parent)
    Rectangle {
        x: -root.x  // Align to rail's left edge
        width: 2.5
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        radius: 1.25
        color: Appearance.colors.colPrimary
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
        color: root.active
            ? Qt.rgba(
                Appearance.colors.colPrimary.r,
                Appearance.colors.colPrimary.g,
                Appearance.colors.colPrimary.b,
                mouseArea.pressed ? 0.18 : 0.10
              )
            : mouseArea.pressed
                ? Appearance.colors.colLayer2Hover
                : mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
        border.width: root.active || mouseArea.containsMouse ? 1 : 0
        border.color: root.active
            ? Qt.rgba(
                Appearance.colors.colPrimary.r,
                Appearance.colors.colPrimary.g,
                Appearance.colors.colPrimary.b,
                0.35
            )
            : Qt.rgba(
                Appearance.colors.colOnSurfaceVariant.r,
                Appearance.colors.colOnSurfaceVariant.g,
                Appearance.colors.colOnSurfaceVariant.b,
                0.14
            )
        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
            }
        }
        Behavior on border.width {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
            }
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.iconName
        iconSize: 18
        color: root.active
            ? Appearance.colors.colPrimary
            : mouseArea.containsMouse
                ? Qt.rgba(
                    Appearance.colors.colOnSurfaceVariant.r,
                    Appearance.colors.colOnSurfaceVariant.g,
                    Appearance.colors.colOnSurfaceVariant.b,
                    0.72
                  )
                : Qt.rgba(
                    Appearance.colors.colOnSurfaceVariant.r,
                    Appearance.colors.colOnSurfaceVariant.g,
                    Appearance.colors.colOnSurfaceVariant.b,
                    0.52
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
