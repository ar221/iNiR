pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common

/**
 * ArcGauge — 270° arc gauge for CPU/GPU in the Deck SystemView.
 *
 * The arc spans 270°: starts at the bottom-left (135° = 3π/4 rad) and sweeps
 * clockwise. Track is the full 270° arc in colLayer1; fill rides on top.
 *
 * Hot threshold at `hotThreshold` (default 0.8) — fill goes #ff1100.
 * Temperature colouring: ≤50°C colPrimary → 70°C colTertiary → ≥85°C #ff1100.
 */
Item {
    id: root

    property real value: 0            // 0–1
    property string label: "CPU"
    property int temperature: 0       // °C
    property real hotThreshold: 0.8

    implicitWidth: 80
    implicitHeight: 96               // arc (80) + label row below

    // ── Fill colour based on value vs threshold ────────────────────────
    readonly property color _fillColor: root.value > root.hotThreshold
        ? Qt.color("#ff1100")
        : Appearance.colors.colPrimary

    // ── Temperature colour ─────────────────────────────────────────────
    // ≤50°C → colPrimary, 50–70 → lerp to colTertiary, 70–85 → lerp to #ff1100, ≥85 → #ff1100
    readonly property color _tempColor: {
        const t = root.temperature
        const cool = Appearance.colors.colPrimary
        const warm = Appearance.colors.colTertiary
        if (t <= 50) return cool
        if (t >= 85) return Qt.color("#ff1100")
        if (t <= 70) {
            const f = (t - 50) / 20
            return Qt.rgba(
                cool.r + (warm.r - cool.r) * f,
                cool.g + (warm.g - cool.g) * f,
                cool.b + (warm.b - cool.b) * f,
                1)
        }
        const f = (t - 70) / 15
        return Qt.rgba(
            warm.r + (1.0 - warm.r) * f,
            warm.g + (0.067 - warm.g) * f,
            warm.b + (0.0 - warm.b) * f,
            1)
    }

    // ── Behavior-gated intermediary — prevents Canvas repaint storms ───
    property real _animatedValue: root.value
    Behavior on _animatedValue {
        enabled: Appearance.animationsEnabled
        NumberAnimation { duration: 300 }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // ── Arc area ──────────────────────────────────────────────────
        Item {
            id: arcArea
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            // Background track: full 270° arc
            Canvas {
                id: trackCanvas
                anchors.fill: parent

                readonly property color _trackColor: Appearance.colors.colLayer1
                on_TrackColorChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.lineWidth = 4
                    ctx.lineCap = "round"
                    ctx.strokeStyle = _trackColor.toString()
                    ctx.beginPath()
                    const cx = width / 2
                    const cy = height / 2
                    const r  = Math.min(width, height) / 2 - 4
                    const startAngle = 3 * Math.PI / 4
                    const endAngle   = startAngle + 3 * Math.PI / 2
                    ctx.arc(cx, cy, r, startAngle, endAngle, false)
                    ctx.stroke()
                }

                Component.onCompleted: requestPaint()
            }

            // Progress fill
            Canvas {
                id: arcCanvas
                anchors.fill: parent

                property real  _progress: root._animatedValue
                property color _color:    root._fillColor

                on_ProgressChanged: requestPaint()
                on_ColorChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    if (_progress <= 0) return
                    ctx.lineWidth = 4
                    ctx.lineCap = "round"
                    ctx.strokeStyle = _color.toString()
                    ctx.beginPath()
                    const cx = width / 2
                    const cy = height / 2
                    const r  = Math.min(width, height) / 2 - 4
                    const startAngle = 3 * Math.PI / 4
                    const sweepAngle = (3 * Math.PI / 2) * Math.max(0, Math.min(1, _progress))
                    ctx.arc(cx, cy, r, startAngle, startAngle + sweepAngle, false)
                    ctx.stroke()
                }
            }

            // Center text: percentage + temperature
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(root.value * 100) + "%"
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: 18
                    font.bold: true
                    color: Appearance.colors.colOnLayer1
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.temperature + "°C"
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: 10
                    color: root._tempColor
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation { duration: 400 }
                    }
                }
            }
        }

        // ── Label below arc ───────────────────────────────────────────
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label.toUpperCase()
            font.pixelSize: 8
            font.letterSpacing: 2
            color: Appearance.colors.colOnLayer1Inactive
        }
    }
}
