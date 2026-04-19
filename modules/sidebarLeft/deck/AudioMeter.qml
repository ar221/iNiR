pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

/**
 * AudioMeter — compact live spectrum strip for AudioView.
 *
 * Dedicated CAVA process (10 bars, separate from the MediaView visualizer)
 * gated on `active` so it only runs while the AudioView is visible. This
 * meter shows whenever ANY system audio plays, independent of MPRIS state.
 *
 * Bars use colPrimary with alpha falloff toward edges for a center-weighted
 * spectral curve aesthetic.
 */
Item {
    id: root

    // Caller drives this — true while AudioView is visible.
    property bool active: false

    Layout.fillWidth: true
    implicitHeight: 84

    // ── CAVA state ────────────────────────────────────────────────────────
    property var values: new Array(10).fill(0)
    property bool cavaRunning: false

    // Write a dedicated CAVA config so we don't collide with MediaView's.
    Process {
        id: configWriter
        command: [
            "bash", "-c",
            "printf '[general]\\nbars = 10\\nframerate = 30\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100\\n[smoothing]\\nnoise_reduction = 60\\n' > /tmp/cava-inir-audiofx.conf"
        ]
        running: false
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", "/tmp/cava-inir-audiofx.conf"]
        // Gate strictly on AudioView visibility — runs whenever this view
        // is on-screen, independent of MPRIS. CAVA naturally outputs zeros
        // when nothing's playing, so bars idle at floor.
        running: root.active
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const trimmed = data.trim().replace(/;$/, "")
                if (trimmed.length === 0) return
                const parts = trimmed.split(";")
                if (parts.length !== 10) return
                root.values = parts.map(v => parseInt(v) || 0)
                root.cavaRunning = true
            }
        }
        onRunningChanged: if (!running) root.cavaRunning = false
    }

    Component.onCompleted: configWriter.running = true

    // ── Bars ──────────────────────────────────────────────────────────────
    Row {
        id: barRow
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        spacing: 4

        readonly property real _barWidth: (width - spacing * 9) / 10

        Repeater {
            model: 10

            Item {
                required property int index
                width: barRow._barWidth
                height: barRow.height

                // Center-weighted alpha — outer bars dimmer for a focused look.
                readonly property real _centerWeight: {
                    const dist = Math.abs(index - 4.5) / 4.5
                    return 0.45 + (1.0 - dist) * 0.55
                }

                // Bar value 0–100, normalize to 0–1 against container height.
                readonly property real _normVal: {
                    if (!root.active || !root.cavaRunning) return 0
                    return Math.min(1.0, (root.values[index] || 0) / 100.0)
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(2, parent.height * parent._normVal)
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, parent._centerWeight)

                    Behavior on height {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                    }
                }

                // Floor indicator — faint baseline so the meter feels "live"
                // even when silent (otherwise looks broken/empty).
                Rectangle {
                    width: parent.width
                    height: 2
                    anchors.bottom: parent.bottom
                    radius: 1
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.15)
                    visible: parent._normVal < 0.05
                }
            }
        }
    }
}
