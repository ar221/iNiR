import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Single network sparkline: canvas area + speed readout.
Item {
    id: root

    property list<real> dataPoints: []
    property color lineColor: Appearance.colors.colPrimary
    property real currentSpeed: 0     // bytes/sec
    property real maxSpeed: 1         // for fill intensity
    property string speedStr: ""      // formatted speed string
    property string label: ""         // "DL" or "UL"

    implicitHeight: 48

    onDataPointsChanged: canvas.requestPaint()
    onLineColorChanged: canvas.requestPaint()
    onCurrentSpeedChanged: canvas.requestPaint()

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Sparkline canvas
        Canvas {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                const points = root.dataPoints
                if (!points || points.length < 2) return

                const norm = root.maxSpeed > 0 ? root.currentSpeed / root.maxSpeed : 0
                // Fill opacity ramps with sqrt for perceptual ease-out
                const fillOpacity = Math.min(0.05 + 0.25 * Math.pow(norm, 0.5), 0.30)

                const lc = root.lineColor

                // Build path across full width
                ctx.beginPath()
                ctx.moveTo(0, height)
                for (let i = 0; i < points.length; i++) {
                    const x = (i / (points.length - 1)) * width
                    const y = (1 - points[i]) * height
                    ctx.lineTo(x, y)
                }
                ctx.lineTo(width, height)
                ctx.closePath()

                // Filled area
                ctx.fillStyle = Qt.rgba(lc.r, lc.g, lc.b, fillOpacity)
                ctx.fill()

                // Stroke the top line only — redraw path without the bottom closure
                ctx.beginPath()
                for (let i = 0; i < points.length; i++) {
                    const x = (i / (points.length - 1)) * width
                    const y = (1 - points[i]) * height
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.strokeStyle = Qt.rgba(lc.r, lc.g, lc.b, 0.8)
                ctx.lineWidth = 1.5
                ctx.stroke()
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        // Speed readout
        ColumnLayout {
            spacing: 1
            Layout.alignment: Qt.AlignVCenter

            StyledText {
                text: root.speedStr || "0 B/s"
                font.pixelSize: 12
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colOnLayer0
                horizontalAlignment: Text.AlignRight
            }

            StyledText {
                text: root.label
                font.pixelSize: 9
                font.family: Appearance.font.family.numbers
                font.letterSpacing: 0.5
                color: Appearance.colors.colSubtext
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
