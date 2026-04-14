pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * SystemPulse — CPU/GPU instrument cluster for the cockpit sidebar.
 *
 * Session D: full implementation replacing the stub.
 * Layout: two paired ComputeGauge rings (CPU/GPU) over two MemoryBar bars (RAM/VRAM).
 * No card chrome, no border, no plate — sits directly on AmbientBackground.
 * Polling is gated on GlobalStates.sidebarLeftOpen (starts on open, stops on close).
 *
 * Replaces StatusRings.qml (deleted in Session D's second commit).
 */
Item {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight

    // ── Helpers ──────────────────────────────────────────────────────────────

    function bytesToGbString(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    // Temp → arc colour. Two-segment piecewise linear: cool → warm → hot.
    // ColorUtils.mix(color1, color2, p): p=1 → color1, p=0 → color2.
    // NOTE: spec §4 corrected version had color1/color2 swapped in both segments —
    //       flipped here to honour the stated intent (cool at ≤50, warm at 70, hot at ≥85).
    function tempColor(temp) {
        const cool = Appearance.colors.colPrimary;
        const warm = Appearance.colors.colTertiary;
        const hot  = Appearance.colors.colError;

        if (temp <= 50) return cool;
        if (temp >= 85) return hot;
        if (temp <= 70) {
            // 50–70: cool → warm
            // at temp=50: (70-50)/20=1 → mix(cool,warm,1) = cool ✓
            // at temp=70: (70-70)/20=0 → mix(cool,warm,0) = warm ✓
            return ColorUtils.mix(cool, warm, (70 - temp) / 20);
        }
        // 70–85: warm → hot
        // at temp=70: (85-70)/15=1 → mix(warm,hot,1) = warm ✓
        // at temp=85: (85-85)/15=0 → mix(warm,hot,0) = hot ✓
        return ColorUtils.mix(warm, hot, (85 - temp) / 15);
    }

    // Memory usage % → bar colour. Hard-stepped (OK / warm / alarming).
    function memColor(pct) {
        if (pct >= 0.90) return Appearance.colors.colError;
        if (pct >= 0.70) return Appearance.colors.colTertiary;
        return Appearance.colors.colPrimary;
    }

    // ── Polling lifecycle: gate on sidebar-open state ─────────────────────────

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) {
                ResourceUsage.ensureRunning();
            } else {
                ResourceUsage.stop();
            }
        }
    }

    Component.onCompleted: {
        if (GlobalStates.sidebarLeftOpen) {
            ResourceUsage.ensureRunning();
        }
    }

    // ── Root layout ───────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 4

        // Ring row
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 88
            spacing: 12

            ComputeGauge {
                id: cpuGauge
                kind: "cpu"
                Layout.fillWidth: true
                Layout.preferredHeight: 88
            }

            ComputeGauge {
                id: gpuGauge
                kind: "gpu"
                Layout.fillWidth: true
                Layout.preferredHeight: 88
            }
        }

        // Memory bar row
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 12

            MemoryBar {
                id: ramBar
                kind: "ram"
                Layout.fillWidth: true
                Layout.preferredHeight: 22
            }

            MemoryBar {
                id: vramBar
                kind: "vram"
                Layout.fillWidth: true
                Layout.preferredHeight: 22
            }
        }
    }

    // ── ComputeGauge ─────────────────────────────────────────────────────────

    component ComputeGauge: Item {
        id: gauge
        required property string kind   // "cpu" or "gpu"

        readonly property real   _usage:     kind === "cpu" ? ResourceUsage.cpuUsage     : ResourceUsage.gpuUsage
        readonly property int    _temp:      kind === "cpu" ? ResourceUsage.cpuTemp      : ResourceUsage.gpuTemp
        readonly property color  _tempColor: root.tempColor(_temp)

        // Behavior-gated intermediaries — Canvas binds only to these, never to raw data.
        // Prevents repaint storms: intermediaries interpolate at 60Hz for 400ms per poll tick.
        property real  _animUsage: _usage
        property color _animColor: _tempColor

        Behavior on _animUsage {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        }

        Behavior on _animColor {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 10

            // Ring container — 72×72
            Item {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                Layout.alignment: Qt.AlignVCenter

                // Background arc: full circle, subtle, transparent on aurora/angel
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: width / 2
                    color: "transparent"
                    border.width: 4
                    border.color: Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colBorderSubtle
                }

                // Progress arc via Canvas
                Canvas {
                    id: gaugeCanvas
                    anchors.fill: parent
                    anchors.margins: 2

                    // Bind to Behavior-gated properties — not raw data
                    property real  progressValue: gauge._animUsage
                    property color progressColor: gauge._animColor

                    onProgressValueChanged: requestPaint()
                    onProgressColorChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = progressColor;
                        ctx.beginPath();
                        const r = width / 2 - 2;
                        ctx.arc(
                            width / 2, height / 2, r,
                            -Math.PI / 2,
                            -Math.PI / 2 + 2 * Math.PI * Math.min(1, Math.max(0, progressValue)),
                            false
                        );
                        ctx.stroke();
                    }
                }
            }

            // Text column: usage % (large) over temp °C (small)
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: -2

                StyledText {
                    text: Math.round(gauge._usage * 100) + "%"
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    text: gauge._temp + "°C"
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1Inactive
                }
            }
        }
    }

    // ── MemoryBar ─────────────────────────────────────────────────────────────

    component MemoryBar: Item {
        id: bar
        required property string kind   // "ram" or "vram"

        readonly property real _pct: kind === "ram"
            ? ResourceUsage.memoryUsedPercentage
            : ResourceUsage.vramUsedPercentage

        readonly property string _label: kind === "ram"
            ? (ResourceUsage.memoryUsed / 1048576).toFixed(1) + "/" + ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)
            : (ResourceUsage.vramUsed / 1073741824).toFixed(1) + "/" + root.bytesToGbString(ResourceUsage.vramTotal)

        readonly property color _color: root.memColor(_pct)

        // Behavior-gated intermediaries
        property real  _animPct:   _pct
        property color _animColor: _color

        Behavior on _animPct {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        }

        Behavior on _animColor {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 8

            // Bar container — centres 3px bar inside 22px cell height
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height

                // Track (background)
                Rectangle {
                    id: barTrack
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 3
                    radius: 1.5
                    color: Appearance.colors.colBorderSubtle
                }

                // Fill
                Rectangle {
                    anchors.left: barTrack.left
                    anchors.verticalCenter: barTrack.verticalCenter
                    height: 3
                    radius: 1.5
                    width: barTrack.width * Math.min(1, Math.max(0, bar._animPct))
                    color: bar._animColor
                }
            }

            // Label: "14.2/32.0 GB"
            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: bar._label
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1Inactive
            }
        }
    }
}
