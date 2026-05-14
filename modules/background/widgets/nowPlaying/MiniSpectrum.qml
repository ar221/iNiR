pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// MiniSpectrum — a compact Cava bar visualizer on the generic CavaProcess.
// No sidebar coupling; the parent decides when to run by setting `active`.
// CavaProcess spawns the native `cava` process only while `active` is true
// (with an internal 800ms stop debounce) and exposes `points` (~0-255 per
// band, [] when not running).
Item {
    id: root

    // Parent sets this true only when playing + visible + showVisualizer.
    property bool active: false
    // Album-art dominant tint for the bars.
    property color barColor: Appearance.colors.colPrimary
    // Cava raw output is ~0-255 per band (matches CavaProcess + SpectrumVisualizer).
    readonly property real maxValue: 255
    property real barSpacing: 2
    property real minBarHeight: 2

    clip: true

    CavaProcess {
        id: cavaProc
        active: root.active
    }

    Row {
        id: barRow
        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            model: cavaProc.points.length

            Rectangle {
                required property int index
                readonly property int barCount: cavaProc.points.length
                width: Math.max(1,
                    (barRow.width - (barCount - 1) * root.barSpacing) / Math.max(1, barCount))
                height: Math.max(root.minBarHeight,
                    (Math.min(root.maxValue, cavaProc.points[index] ?? 0) / root.maxValue) * barRow.height)
                anchors.bottom: parent.bottom
                radius: Appearance.rounding.unsharpen
                color: root.barColor
                opacity: 0.55 + 0.45 * (index / Math.max(1, barCount))

                Behavior on height {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                }
            }
        }
    }

    // Idle floor — a faint baseline when there are no points (process not running).
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.minBarHeight
        visible: cavaProc.points.length === 0
        color: ColorUtils.transparentize(root.barColor, 0.7)
    }
}
