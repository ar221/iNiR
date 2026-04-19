pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.services

/**
 * EqCurveViz — smooth filled-curve visualization of the active preset's
 * equalizer. Reads `EasyEffects.currentPresetEqBands` (array of {freq, gain})
 * and renders a quadratic-bezier spline through the band points, filled
 * with a vertical gradient toward the zero-line, with a crisp stroke on top
 * and tiny anchor dots at each band so the underlying data is still legible.
 *
 * Aesthetic choice: bar graphs read as "data," smooth curves read as
 * "audio gear." This view is small and decorative, not for precise reading,
 * so the curve serves the vibe better. A static EqEditor view (future)
 * would use a proper draggable bar/dot graph instead.
 *
 * Empty state when active preset has no equalizer plugin.
 */
Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: 110

    readonly property var bands: EasyEffects.currentPresetEqBands ?? []
    readonly property bool _hasData: bands.length > 0

    // Visual gain clamp — most presets stay within ±12 dB.
    readonly property real _clampDb: 12.0

    // Theme color cached for Canvas (Canvas can't reference Appearance directly
    // inside onPaint without re-eval cost; pull it once and watch for changes).
    readonly property color _accent: Appearance.colors.colPrimary
    readonly property color _muted: Appearance.colors.colOnSurfaceVariant

    onBandsChanged: curveCanvas.requestPaint()
    on_AccentChanged: curveCanvas.requestPaint()

    // ── Empty state ───────────────────────────────────────────────────────
    Text {
        anchors.centerIn: parent
        visible: !root._hasData
        text: "no EQ in this preset"
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.family: Appearance.font.family.main
        color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.35)
    }

    // ── Curve area ────────────────────────────────────────────────────────
    Item {
        id: curveBox
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 4
        anchors.bottomMargin: 14  // room for axis labels
        visible: root._hasData

        readonly property real _zeroY: height / 2

        // Zero-line reference
        Rectangle {
            id: zeroLine
            width: parent.width
            height: 1
            y: parent._zeroY
            color: ColorUtils.applyAlpha(root._muted, 0.25)
            z: 1
        }

        // ±6 / ±12 dB grid lines
        Repeater {
            model: [-12, -6, 6, 12]
            Rectangle {
                required property real modelData
                width: curveBox.width
                height: 1
                y: curveBox._zeroY - (modelData / root._clampDb) * (curveBox.height / 2)
                color: ColorUtils.applyAlpha(root._muted, 0.06)
            }
        }

        // ── The curve itself ──────────────────────────────────────────────
        Canvas {
            id: curveCanvas
            anchors.fill: parent
            antialiasing: true
            renderStrategy: Canvas.Cooperative

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const bands = root.bands
                if (!bands || bands.length < 2) return

                const w = width
                const h = height
                const zeroY = h / 2
                const halfH = h / 2
                const clamp = root._clampDb

                // Build evenly-spaced point list
                const pts = []
                for (let i = 0; i < bands.length; i++) {
                    const x = (i / (bands.length - 1)) * w
                    const gainRaw = bands[i].gain ?? 0
                    const gain = Math.max(-clamp, Math.min(clamp, gainRaw))
                    const y = zeroY - (gain / clamp) * halfH
                    pts.push({x: x, y: y})
                }

                // Smooth path using midpoint-quadratic-bezier method:
                // Move to first point, then for each adjacent pair use a
                // quadratic curve where the control point is the actual data
                // point and the curve passes through the midpoint of each
                // segment. Simple, robust, no overshoot.
                function tracePath() {
                    ctx.beginPath()
                    ctx.moveTo(pts[0].x, pts[0].y)
                    for (let i = 0; i < pts.length - 1; i++) {
                        const mx = (pts[i].x + pts[i+1].x) / 2
                        const my = (pts[i].y + pts[i+1].y) / 2
                        if (i === 0) {
                            ctx.lineTo(mx, my)
                        } else {
                            ctx.quadraticCurveTo(pts[i].x, pts[i].y, mx, my)
                        }
                    }
                    // Final segment to last point
                    ctx.lineTo(pts[pts.length-1].x, pts[pts.length-1].y)
                }

                // Fill: extend path down to zero line, then back. This creates
                // the band-between-curve-and-zero shape. Use a vertical
                // gradient — full-alpha at the curve, transparent at zero.
                tracePath()
                ctx.lineTo(pts[pts.length-1].x, zeroY)
                ctx.lineTo(pts[0].x, zeroY)
                ctx.closePath()

                // Two gradients: top (above zero, positive gain) and a faint
                // mirror below. Doing it as one gradient anchored at zeroY
                // gets us both regions in a single fill pass.
                const grad = ctx.createLinearGradient(0, 0, 0, h)
                const ar = root._accent.r
                const ag = root._accent.g
                const ab = root._accent.b
                function rgba(a) {
                    return "rgba(" + Math.round(ar*255) + "," + Math.round(ag*255) +
                           "," + Math.round(ab*255) + "," + a + ")"
                }
                grad.addColorStop(0.0, rgba(0.55))   // top (max positive)
                grad.addColorStop(0.5, rgba(0.05))   // zero line — almost gone
                grad.addColorStop(1.0, rgba(0.30))   // bottom (max negative)
                ctx.fillStyle = grad
                ctx.fill()

                // Stroke: crisp curve on top
                tracePath()
                ctx.strokeStyle = rgba(1.0)
                ctx.lineWidth = 2
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                ctx.stroke()

                // Anchor dots at each band point — tiny, just for legibility
                ctx.fillStyle = rgba(1.0)
                for (let i = 0; i < pts.length; i++) {
                    ctx.beginPath()
                    ctx.arc(pts[i].x, pts[i].y, 2.0, 0, Math.PI * 2)
                    ctx.fill()
                }
            }

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation { duration: 220 }
            }
        }
    }

    // ── Frequency axis labels ─────────────────────────────────────────────
    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 3
        visible: root._hasData

        readonly property real _w: (width - spacing * (root.bands.length - 1)) / Math.max(1, root.bands.length)

        Repeater {
            model: root.bands

            Item {
                required property var modelData
                required property int index
                width: parent._w
                height: 12

                Text {
                    anchors.centerIn: parent
                    text: {
                        const f = modelData.freq ?? 0
                        if (f >= 1000) return Math.round(f / 1000) + "k"
                        return Math.round(f).toString()
                    }
                    // Show every other label on tight chains to avoid crowding
                    visible: parent.index % 2 === 0 || root.bands.length <= 6
                    font.pixelSize: 7
                    font.family: Appearance.font.family.monospace
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.45)
                }
            }
        }
    }
}
