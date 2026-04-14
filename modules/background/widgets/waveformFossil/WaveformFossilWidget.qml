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

    configEntryName: "waveformFossil"

    readonly property var fossilConfig: configEntry
    readonly property real cardOpacity: fossilConfig.cardOpacity ?? 0.85
    readonly property real cardWidth: fossilConfig.cardWidth ?? 280
    readonly property point screenPos: root.mapToItem(null, 0, 0)

    // Audio state
    readonly property bool audioPlaying: MprisController.activePlayer?.isPlaying ?? false

    // Rolling buffer of waveform snapshots — newest at index 0
    property var layers: []
    readonly property int maxLayers: 30
    readonly property int canvasWidth: 240
    readonly property int canvasHeight: 180
    readonly property real layerSpacing: 5.0

    // Pre-computed color components for Canvas (can't use QML singletons in onPaint)
    readonly property real primaryR: Qt.color(Appearance.colors.colPrimary).r
    readonly property real primaryG: Qt.color(Appearance.colors.colPrimary).g
    readonly property real primaryB: Qt.color(Appearance.colors.colPrimary).b
    readonly property real stoneR: Qt.color(Appearance.colors.colSurfaceContainer).r
    readonly property real stoneG: Qt.color(Appearance.colors.colSurfaceContainer).g
    readonly property real stoneB: Qt.color(Appearance.colors.colSurfaceContainer).b

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    // Cava data source — active when widget is visible
    CavaProcess {
        id: cava
        active: root.visible
    }

    // Capture timer — snapshot cava data into a new layer every 200ms
    Timer {
        id: captureTimer
        running: root.visible && root.audioPlaying
        interval: 200
        repeat: true
        onTriggered: {
            const pts = cava.points
            if (pts.length === 0) return

            // Deep copy + normalize (cava values go to ~1000, not 0-1)
            const snapshot = new Array(pts.length)
            for (let i = 0; i < pts.length; i++)
                snapshot[i] = Math.min(1.0, (pts[i] || 0) / 1000)

            const updated = [snapshot, ...root.layers]
            if (updated.length > root.maxLayers)
                updated.length = root.maxLayers
            root.layers = updated

            fossilCanvas.requestPaint()
        }
    }

    // Render timer — ~16fps smooth paint while audio is playing
    Timer {
        id: renderTimer
        running: root.visible && root.audioPlaying && Appearance.animationsEnabled
        interval: 60
        repeat: true
        onTriggered: fossilCanvas.requestPaint()
    }

    // When audio stops, render one last frame (the frozen fossil)
    onAudioPlayingChanged: {
        if (!audioPlaying)
            fossilCanvas.requestPaint()
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

        // Inset depth -- top edge gradient
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
        spacing: 10

        // Header
        StyledText {
            Layout.alignment: Qt.AlignLeft
            text: "WAVEFORM"
            font {
                pixelSize: Appearance.font.pixelSize.smallest
                weight: Font.DemiBold
                letterSpacing: 2.0
                capitalization: Font.AllUppercase
            }
            color: Appearance.colors.colSubtext
        }

        // Waveform strata canvas
        Canvas {
            id: fossilCanvas
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.canvasWidth
            Layout.preferredHeight: root.canvasHeight

            // Cache paint data from QML properties (Canvas onPaint can't access QML singletons)
            readonly property var layerData: root.layers
            readonly property int layerCount: root.maxLayers
            readonly property real spacing: root.layerSpacing
            readonly property real pR: root.primaryR
            readonly property real pG: root.primaryG
            readonly property real pB: root.primaryB
            readonly property real sR: root.stoneR
            readonly property real sG: root.stoneG
            readonly property real sB: root.stoneB

            onPaint: {
                const ctx = getContext("2d")
                const w = width
                const h = height
                ctx.clearRect(0, 0, w, h)

                const data = layerData
                if (!data || data.length === 0) return

                const count = data.length
                const maxCount = layerCount
                const ySpacing = spacing
                const pr = pR, pg = pG, pb = pB
                const sr = sR, sg = sG, sb = sB

                // Draw from oldest (bottom) to newest (top) so newer layers paint over older
                for (let li = count - 1; li >= 0; li--) {
                    const layer = data[li]
                    if (!layer || layer.length === 0) continue

                    // Age factor: 0 = newest, 1 = oldest
                    const age = count > 1 ? li / (maxCount - 1) : 0

                    // Interpolate color: primary -> stone grey as age increases
                    const r = Math.round((pr * (1 - age) + sr * age) * 255)
                    const g = Math.round((pg * (1 - age) + sg * age) * 255)
                    const b = Math.round((pb * (1 - age) + sb * age) * 255)

                    // Opacity: newest = 0.9, oldest = 0.15
                    const alpha = 0.9 - age * 0.75

                    // Vertical offset: each older layer shifts down
                    const yOffset = li * ySpacing

                    // Baseline Y for this layer (top of canvas + offset)
                    const baseY = 10 + yOffset

                    const numPts = layer.length
                    const xStep = w / (numPts - 1)

                    // Build bezier control points for a smooth waveform
                    ctx.beginPath()

                    // Amplitude: waveform displaces upward from baseline
                    const amp = 25  // max pixel displacement

                    // First point
                    const firstY = baseY - layer[0] * amp
                    ctx.moveTo(0, firstY)

                    // Smooth bezier through points
                    for (let i = 1; i < numPts; i++) {
                        const x0 = (i - 1) * xStep
                        const x1 = i * xStep
                        const y0 = baseY - layer[i - 1] * amp
                        const y1 = baseY - layer[i] * amp
                        const cpx = (x0 + x1) / 2
                        ctx.bezierCurveTo(cpx, y0, cpx, y1, x1, y1)
                    }

                    // Close the area fill: line down to baseline, back to start
                    ctx.lineTo(w, baseY + 2)
                    ctx.lineTo(0, baseY + 2)
                    ctx.closePath()

                    // Area fill
                    ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${(alpha * 0.3).toFixed(3)})`
                    ctx.fill()

                    // Stroke the waveform line
                    // Re-draw the curve path for stroke only
                    ctx.beginPath()
                    ctx.moveTo(0, firstY)
                    for (let i = 1; i < numPts; i++) {
                        const x0 = (i - 1) * xStep
                        const x1 = i * xStep
                        const y0 = baseY - layer[i - 1] * amp
                        const y1 = baseY - layer[i] * amp
                        const cpx = (x0 + x1) / 2
                        ctx.bezierCurveTo(cpx, y0, cpx, y1, x1, y1)
                    }
                    ctx.strokeStyle = `rgba(${r}, ${g}, ${b}, ${alpha.toFixed(3)})`
                    ctx.lineWidth = li === 0 ? 2.0 : 1.2
                    ctx.stroke()
                }
            }
        }

        // Footer: AUDIO label + playing indicator
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            StyledText {
                text: "AUDIO"
                font {
                    pixelSize: Appearance.font.pixelSize.small
                    weight: Font.Medium
                    letterSpacing: 1.5
                }
                color: Appearance.colors.colSubtext
            }

            // Playing/paused indicator dot
            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: root.audioPlaying
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colSubtext
                opacity: root.audioPlaying ? 1.0 : 0.5

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMove.duration }
                }
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMove.duration }
                }
            }

            StyledText {
                text: root.audioPlaying ? "LIVE" : "FOSSIL"
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.DemiBold
                    letterSpacing: 1.0
                }
                color: root.audioPlaying
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colSubtext
                opacity: root.audioPlaying ? 1.0 : 0.6

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMove.duration }
                }
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMove.duration }
                }
            }
        }
    }
}
