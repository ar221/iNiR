pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// MiniSpectrum — a compact Cava bar visualizer on the generic CavaProcess.
// No sidebar coupling; the parent decides when to run by setting `active`.
// CavaProcess spawns the native `cava` process only while `active` is true
// (with an internal 800ms stop debounce) and exposes `points` (~0-255 per
// band, [] when not running). Follows the CavaVisualizer.qml pattern: a
// fixed barCount drives the Repeater model, delegates index into `points`.
Item {
    id: root

    // Parent sets this true only when playing + visible + showVisualizer.
    property bool active: false
    // Album-art dominant tint for the bars.
    property color barColor: Appearance.colors.colPrimary
    // Fixed bar count — decouples layout from the live stream's band count,
    // so a cava config regen can't tear down + rebuild the Repeater mid-stream.
    // 50 mirrors `bars = 50` in scripts/cava/generate_config.sh (the shared
    // CavaProcess config); keep in sync if that script's bar count changes.
    property int barCount: 50
    // Cava raw output runs ~0-1000 per band on the shared CavaProcess config
    // (no ascii_max_range set) — matches AudioVisualizer.qml / WaveformFossilWidget.qml.
    readonly property real maxValue: 1000
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
            model: root.barCount

            Rectangle {
                required property int index
                width: Math.max(1,
                    (barRow.width - (root.barCount - 1) * root.barSpacing) / Math.max(1, root.barCount))
                height: Math.max(root.minBarHeight,
                    (Math.min(root.maxValue, cavaProc.points[index] ?? 0) / root.maxValue) * barRow.height)
                anchors.bottom: parent.bottom
                radius: Appearance.rounding.unsharpen
                color: root.barColor
                opacity: 0.55 + 0.45 * (index / Math.max(1, root.barCount))

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
