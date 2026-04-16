import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    // Data
    required property real value          // 0.0 – 1.0 normalized
    property string label: ""             // e.g. "CPU", "GPU"
    property bool showLabel: Config.options?.bar?.rings?.showLabels ?? true

    // Warning thresholds (0-100 scale, 0 = disabled)
    property real cautionThreshold: 0
    property real warningThreshold: 100
    property bool _caution: cautionThreshold > 0 && (value * 100) >= cautionThreshold && !_warning
    property bool _warning: (value * 100) >= warningThreshold

    // Theming — shifts to red/hot on warning
    property color gradientStart: _warning ? "#ef4444" : _caution ? "#f59e0b" : Appearance.colors.colPrimary
    property color gradientEnd: _warning ? "#dc2626" : _caution ? "#f97316" : Appearance.colors.colTertiary
    property color trackColor: Appearance.inirEverywhere
        ? Qt.rgba(Appearance.inir.colText.r, Appearance.inir.colText.g, Appearance.inir.colText.b, 0.08)
        : Qt.rgba(1, 1, 1, 0.06)
    property color valueColor: Appearance.inirEverywhere
        ? Appearance.inir.colText
        : Appearance.colors.colOnLayer0

    // Sizing
    property real ringSize: 28
    property real lineWidth: 3
    property real labelOffset: 2  // gap between ring and label

    implicitWidth: ringSize
    implicitHeight: showLabel ? ringSize + labelOffset + labelText.implicitHeight : ringSize

    // Redraw when value or colors change
    onValueChanged: canvas.requestPaint()
    onGradientStartChanged: canvas.requestPaint()
    onGradientEndChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: root.ringSize
        height: root.ringSize
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width / 2
            var cy = height / 2
            var radius = (Math.min(width, height) - root.lineWidth) / 2
            var startAngle = -Math.PI / 2  // 12 o'clock
            var endAngle = startAngle + (2 * Math.PI * Math.min(Math.max(root.value, 0), 1))

            // Track (full circle, dim)
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
            ctx.lineWidth = root.lineWidth
            ctx.strokeStyle = root.trackColor.toString()
            ctx.lineCap = "round"
            ctx.stroke()

            // Value arc (gradient)
            if (root.value > 0.005) {
                // Create a linear gradient across the canvas for the arc color
                var grad = ctx.createLinearGradient(0, 0, width, height)
                grad.addColorStop(0.0, root.gradientStart.toString())
                grad.addColorStop(1.0, root.gradientEnd.toString())

                ctx.beginPath()
                ctx.arc(cx, cy, radius, startAngle, endAngle)
                ctx.lineWidth = root.lineWidth
                ctx.strokeStyle = grad
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }

    // Center value text
    StyledText {
        anchors.centerIn: canvas
        text: Math.round(root.value * 100).toString()
        font.pixelSize: 10
        font.weight: Font.Bold
        color: root.valueColor
    }

    // Label below ring
    StyledText {
        id: labelText
        anchors.top: canvas.bottom
        anchors.topMargin: root.labelOffset
        anchors.horizontalCenter: canvas.horizontalCenter
        visible: root.showLabel && root.label !== ""
        text: root.label
        font.pixelSize: 9
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        color: Qt.rgba(root.valueColor.r, root.valueColor.g, root.valueColor.b, 0.6)
        horizontalAlignment: Text.AlignHCenter
    }
}
