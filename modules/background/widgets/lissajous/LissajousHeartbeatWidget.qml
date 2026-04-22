pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions
import qs.modules.background.widgets
import qs.services
import "root:"

AbstractBackgroundWidget {
    id: root

    configEntryName: "lissajous"

    readonly property var lissajousConfig: configEntry
    readonly property real cardOpacity: lissajousConfig.cardOpacity ?? 0.85
    readonly property real cardWidth: lissajousConfig.cardWidth ?? 240
    readonly property point screenPos: root.mapToItem(null, 0, 0)

    // CPU data
    readonly property real cpuLoad: ResourceUsage.cpuUsage ?? 0
    readonly property bool cpuCritical: cpuLoad > 0.85

    // Lissajous parameters — CPU load morphs the frequency ratio
    // Low load: clean figure-8 (a=1, b=2), high load: tangled (a=3, b=5+)
    readonly property real freqA: 1.0 + cpuLoad * 2.0   // 1..3
    readonly property real freqB: 2.0 + cpuLoad * 3.0   // 2..5

    // Phase shift that animates over time
    property real phase: 0.0

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    Component.onCompleted: ResourceUsage.acquire()
    Component.onDestruction: ResourceUsage.release()

    Timer {
        running: root.visible
        interval: 10000
        repeat: true
        onTriggered: ResourceUsage.ensureRunning()
    }

    // Animation timer — ~16fps, gated on visibility
    Timer {
        id: animTimer
        running: root.visible && Appearance.animationsEnabled
        interval: 60
        repeat: true
        onTriggered: {
            root.phase += 0.03
            if (root.phase > Math.PI * 200)
                root.phase -= Math.PI * 200
            lissajousCanvas.requestPaint()
        }
    }

    // Drop shadow
    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    // Glass card background
    Rectangle {
        id: cardBackground
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: "transparent"
        clip: true

        GlassBackground {
            anchors.fill: parent
            radius: parent.radius
            screenX: root.screenPos.x
            screenY: root.screenPos.y
            fallbackColor: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }

        // Inset depth — top edge gradient
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 6
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // Content
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Header
        StyledText {
            Layout.alignment: Qt.AlignLeft
            text: "HEARTBEAT"
            font {
                pixelSize: Appearance.font.pixelSize.smallest
                weight: Font.DemiBold
                letterSpacing: 2.0
                capitalization: Font.AllUppercase
            }
            color: Appearance.colors.colSubtext
        }

        // Lissajous canvas
        Canvas {
            id: lissajousCanvas
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(root.cardWidth - 40, 200)
            Layout.preferredHeight: Layout.preferredWidth

            readonly property real curveColor_r: root.cpuCritical ? 1.0 : Qt.color(Appearance.colors.colPrimary).r
            readonly property real curveColor_g: root.cpuCritical ? (0x11 / 0xFF) : Qt.color(Appearance.colors.colPrimary).g
            readonly property real curveColor_b: root.cpuCritical ? 0.0 : Qt.color(Appearance.colors.colPrimary).b

            onPaint: {
                const ctx = getContext("2d")
                const w = width
                const h = height
                ctx.clearRect(0, 0, w, h)

                const cx = w / 2
                const cy = h / 2
                const ampX = (w / 2) * 0.85
                const ampY = (h / 2) * 0.85
                const totalPoints = 300
                const delta = root.phase
                const a = root.freqA
                const b = root.freqB
                const r = curveColor_r
                const g = curveColor_g
                const bv = curveColor_b

                // Draw the parametric curve as segments with fading opacity
                // t sweeps 0..2*PI over totalPoints
                for (let i = 1; i < totalPoints; i++) {
                    // Opacity: newest (end of array) is brightest, oldest fades
                    const alpha = (i / totalPoints)

                    const t0 = ((i - 1) / totalPoints) * Math.PI * 2
                    const t1 = (i / totalPoints) * Math.PI * 2

                    const x0 = cx + ampX * Math.sin(a * t0 + delta)
                    const y0 = cy + ampY * Math.sin(b * t0)
                    const x1 = cx + ampX * Math.sin(a * t1 + delta)
                    const y1 = cy + ampY * Math.sin(b * t1)

                    ctx.beginPath()
                    ctx.moveTo(x0, y0)
                    ctx.lineTo(x1, y1)
                    ctx.strokeStyle = `rgba(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(bv * 255)}, ${alpha.toFixed(3)})`
                    ctx.lineWidth = 2
                    ctx.stroke()
                }
            }
        }

        // CPU label + percentage
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            StyledText {
                text: "CPU"
                font {
                    pixelSize: Appearance.font.pixelSize.small
                    weight: Font.Medium
                    letterSpacing: 1.5
                }
                color: Appearance.colors.colSubtext
            }

            StyledText {
                text: Math.round(root.cpuLoad * 100) + "%"
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.DemiBold
                }
                color: root.cpuCritical
                    ? "#ff1100"
                    : Appearance.colors.colOnLayer0
            }
        }
    }
}
