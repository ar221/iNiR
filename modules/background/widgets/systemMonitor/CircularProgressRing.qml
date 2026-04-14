import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property real value: 0
    property int ringSize: 80
    property int lineWidth: 5
    property color ringColor: Appearance.colors.colPrimary
    property string label: ""
    property string icon: ""
    property string valueText: ""
    property var history: []  // Optional: list<real> 0–1, drawn as lower-half area fill

    // Critical threshold — ring turns #ff1100 when value exceeds this
    property real criticalThreshold: 0.85
    property bool isCritical: value >= criticalThreshold
    property color effectiveRingColor: isCritical ? "#ff1100" : ringColor
    property color effectiveTrackColor: ColorUtils.transparentize(effectiveRingColor, 0.82)

    implicitWidth: ringSize
    implicitHeight: contentColumn.implicitHeight

    property real _animatedValue: 0
    Behavior on _animatedValue {
        enabled: Appearance.animationsEnabled
        NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutQuart }
    }
    onValueChanged: _animatedValue = value

    Column {
        id: contentColumn
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        Item {
            width: root.ringSize
            height: root.ringSize

            Canvas {
                id: canvas
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width / 2
                    const cy = height / 2
                    const r = (Math.min(width, height) - root.lineWidth) / 2
                    const startAngle = -Math.PI / 2

                    // Track
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                    ctx.lineWidth = root.lineWidth
                    ctx.strokeStyle = root.effectiveTrackColor.toString()
                    ctx.lineCap = "round"
                    ctx.stroke()

                    // Value arc
                    if (root._animatedValue > 0.005) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startAngle, startAngle + root._animatedValue * 2 * Math.PI)
                        ctx.lineWidth = root.lineWidth
                        ctx.strokeStyle = root.effectiveRingColor.toString()
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }

                    // In-ring sparkline (lower half, area fill)
                    if (root.history.length >= 2) {
                        const innerR = r - root.lineWidth - 2
                        const sparkH = innerR * 0.45  // lower 45% of ring interior
                        const sparkTop = cy + innerR * 0.1  // start just below center
                        const sparkLeft = cx - innerR * 0.7
                        const sparkW = innerR * 1.4
                        const count = root.history.length
                        const stepX = sparkW / (count - 1)

                        // Find local max for scaling
                        let maxVal = 0.01
                        for (let i = 0; i < count; i++)
                            maxVal = Math.max(maxVal, root.history[i])

                        // Build points
                        const pts = []
                        for (let i = 0; i < count; i++) {
                            const x = sparkLeft + i * stepX
                            const norm = Math.min(root.history[i] / maxVal, 1.0)
                            const y = sparkTop + sparkH - norm * sparkH
                            pts.push({x: x, y: y})
                        }

                        // Clip to circle
                        ctx.save()
                        ctx.beginPath()
                        ctx.arc(cx, cy, innerR, 0, 2 * Math.PI)
                        ctx.clip()

                        // Area fill
                        ctx.beginPath()
                        ctx.moveTo(pts[0].x, sparkTop + sparkH)
                        ctx.lineTo(pts[0].x, pts[0].y)
                        for (let i = 1; i < pts.length; i++) {
                            const prev = pts[i - 1]
                            const curr = pts[i]
                            const cpx1 = prev.x + (curr.x - prev.x) * 0.3
                            const cpx2 = curr.x - (curr.x - prev.x) * 0.3
                            ctx.bezierCurveTo(cpx1, prev.y, cpx2, curr.y, curr.x, curr.y)
                        }
                        ctx.lineTo(pts[pts.length - 1].x, sparkTop + sparkH)
                        ctx.closePath()

                        const c = root.effectiveRingColor
                        ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.12)
                        ctx.fill()

                        // Thin stroke on top
                        ctx.beginPath()
                        ctx.moveTo(pts[0].x, pts[0].y)
                        for (let i = 1; i < pts.length; i++) {
                            const prev = pts[i - 1]
                            const curr = pts[i]
                            const cpx1 = prev.x + (curr.x - prev.x) * 0.3
                            const cpx2 = curr.x - (curr.x - prev.x) * 0.3
                            ctx.bezierCurveTo(cpx1, prev.y, cpx2, curr.y, curr.x, curr.y)
                        }
                        ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.25)
                        ctx.lineWidth = 0.8
                        ctx.stroke()

                        ctx.restore()
                    }
                }
            }

            Connections {
                target: root
                function on_AnimatedValueChanged() { canvas.requestPaint() }
            }
            Connections {
                target: root
                function onEffectiveRingColorChanged() { canvas.requestPaint() }
                function onEffectiveTrackColorChanged() { canvas.requestPaint() }
                function onHistoryChanged() { canvas.requestPaint() }
            }

            // Icon centered in ring
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.icon
                iconSize: root.ringSize * 0.36
                color: root.effectiveRingColor
                visible: root.icon !== ""
            }
        }

        // Combined label + value text below ring
        StyledText {
            visible: root.label !== "" || root.valueText !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (root.label !== "" && root.valueText !== "")
                    return root.label + " " + root.valueText
                return root.label || root.valueText
            }
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer0
        }
    }
}
