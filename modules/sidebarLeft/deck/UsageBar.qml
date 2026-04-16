pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common

/**
 * UsageBar — horizontal usage bar for the Deck SystemView.
 *
 * Shows: label (left) | "used / total unit" (right)
 * Bar: 8px tall, 2px radius, colLayer1 track, colPrimary fill.
 * Hot: ratio >= hotThreshold → #ff3333.
 */
Item {
    id: root

    property string label: "RAM"
    property real used: 0
    property real total: 1
    property string unit: "GB"
    property real hotThreshold: 0.9

    implicitHeight: 38
    Layout.fillWidth: true

    readonly property real _ratio: root.total > 0
        ? Math.max(0, Math.min(1, root.used / root.total))
        : 0

    readonly property color _fillColor: root._ratio >= root.hotThreshold
        ? "#ff3333"
        : Appearance.colors.colPrimary

    // Behavior-gated intermediaries
    property real  _animRatio: root._ratio
    property color _animColor: root._fillColor

    Behavior on _animRatio {
        enabled: Appearance.animationsEnabled
        NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
    }

    Behavior on _animColor {
        enabled: Appearance.animationsEnabled
        ColorAnimation { duration: 300 }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        // Label row
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.label
                font.family: Appearance.font.family.monospace
                font.pixelSize: 13
                color: Appearance.colors.colOnLayer1Inactive
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.used.toFixed(1) + " / " + root.total.toFixed(1) + " " + root.unit
                font.family: Appearance.font.family.numbers
                font.pixelSize: 13
                color: Appearance.colors.colOnLayer1Inactive
            }
        }

        // Bar
        Item {
            Layout.fillWidth: true
            implicitHeight: 12

            // Track
            Rectangle {
                id: barTrack
                anchors.fill: parent
                radius: 2
                color: Appearance.colors.colLayer1
            }

            // Fill
            Rectangle {
                anchors.left: barTrack.left
                anchors.top: barTrack.top
                anchors.bottom: barTrack.bottom
                radius: 2
                width: barTrack.width * root._animRatio
                color: root._animColor
            }
        }
    }
}
