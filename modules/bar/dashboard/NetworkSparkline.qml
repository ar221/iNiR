import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root
    spacing: 6

    Component.onCompleted: NetworkUsage.acquire()
    Component.onDestruction: NetworkUsage.release()

    // Sparkline canvas
    Canvas {
        id: sparkCanvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 60

        property var dlHistory: NetworkUsage.downloadHistory
        property var ulHistory: NetworkUsage.uploadHistory

        onDlHistoryChanged: requestPaint()
        onUlHistoryChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            const padding = 2

            function drawSparkline(data, color, fillAlpha) {
                if (!data || data.length < 2) return

                const step = w / Math.max(data.length - 1, 1)

                // Filled area
                ctx.beginPath()
                ctx.moveTo(0, h)
                for (let i = 0; i < data.length; i++) {
                    const x = i * step
                    const y = h - (data[i] * (h - padding * 2)) - padding
                    ctx.lineTo(x, y)
                }
                ctx.lineTo((data.length - 1) * step, h)
                ctx.closePath()
                ctx.fillStyle = Qt.alpha(color, fillAlpha).toString()
                ctx.fill()

                // Stroke line on top
                ctx.beginPath()
                for (let i = 0; i < data.length; i++) {
                    const x = i * step
                    const y = h - (data[i] * (h - padding * 2)) - padding
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.lineWidth = 1.5
                ctx.strokeStyle = color.toString()
                ctx.stroke()
            }

            // Upload behind, download in front
            drawSparkline(ulHistory, Appearance.colors.colTertiary, 0.15)
            drawSparkline(dlHistory, Appearance.colors.colPrimary, 0.25)
        }
    }

    // Speed labels
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            spacing: 4
            MaterialSymbol { text: "arrow_downward"; iconSize: 12; color: Appearance.colors.colPrimary }
            StyledText {
                text: NetworkUsage.downloadSpeedStr
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colOnLayer0
            }
        }

        RowLayout {
            spacing: 4
            MaterialSymbol { text: "arrow_upward"; iconSize: 12; color: Appearance.colors.colTertiary }
            StyledText {
                text: NetworkUsage.uploadSpeedStr
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
