import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property real value: 0
    property int ringSize: 72
    property int lineWidth: 5
    property color ringColor: Appearance.colors.colPrimary
    property color trackColor: ColorUtils.transparentize(ringColor, 0.75)
    property string label: ""
    property string secondaryText: ""

    implicitWidth: ringSize
    implicitHeight: contentColumn.implicitHeight

    property real _animatedValue: 0
    Behavior on _animatedValue {
        NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
    }
    onValueChanged: _animatedValue = value

    Column {
        id: contentColumn
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

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
                    ctx.strokeStyle = root.trackColor.toString()
                    ctx.lineCap = "round"
                    ctx.stroke()

                    // Value arc
                    if (root._animatedValue > 0.005) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startAngle, startAngle + root._animatedValue * 2 * Math.PI)
                        ctx.lineWidth = root.lineWidth
                        ctx.strokeStyle = root.ringColor.toString()
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
                function onRingColorChanged() { canvas.requestPaint() }
                function onTrackColorChanged() { canvas.requestPaint() }
            }

            StyledText {
                anchors.centerIn: parent
                text: Math.round(root._animatedValue * 100) + "%"
                font.pixelSize: root.ringSize * 0.22
                font.family: Appearance.font.family.monospace
                font.weight: Font.Bold
                color: root.ringColor
            }
        }

        StyledText {
            visible: root.label !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer0
        }

        StyledText {
            visible: root.secondaryText !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.secondaryText
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colSubtext
        }
    }
}
