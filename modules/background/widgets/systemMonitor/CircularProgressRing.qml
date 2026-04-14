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
