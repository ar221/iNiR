pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    configEntryName: "thermalBloom"

    readonly property var bloomConfig: configEntry
    readonly property real cardOpacity: bloomConfig.cardOpacity ?? 0.85
    readonly property int cardWidth: bloomConfig.cardWidth ?? 240
    readonly property point screenPos: root.mapToItem(null, 0, 0)

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    Component.onCompleted: ResourceUsage.ensureRunning()
    Component.onDestruction: ResourceUsage.stop()

    Timer {
        running: root.visible
        interval: 10000
        repeat: true
        onTriggered: ResourceUsage.ensureRunning()
    }

    // --- Animation state ---
    property real _phase: 0.0

    Timer {
        id: pulseTimer
        running: root.visible && Appearance.animationsEnabled
        interval: 60
        repeat: true
        onTriggered: {
            root._phase += (2.0 * Math.PI * interval) / 2000.0; // 2s period
            if (root._phase > 2.0 * Math.PI) root._phase -= 2.0 * Math.PI;
            bloomCanvas.requestPaint();
        }
    }

    // --- Temperature color helpers ---
    function _lerpColor(a: color, b: color, t: real): color {
        const ct = Math.max(0, Math.min(1, t));
        return Qt.rgba(
            a.r + (b.r - a.r) * ct,
            a.g + (b.g - a.g) * ct,
            a.b + (b.b - a.b) * ct,
            a.a + (b.a - a.a) * ct
        );
    }

    function _tempToColor(temp: int): color {
        // 0-40 cool, 40-70 warm amber, 70-85 orange, 85+ red
        if (temp <= 40) {
            const t = Math.max(0, temp) / 40.0;
            return _lerpColor(Appearance.colors.colSecondary, Qt.rgba(1.0, 0.75, 0.0, 1.0), t);
        } else if (temp <= 70) {
            const t = (temp - 40) / 30.0;
            return _lerpColor(Qt.rgba(1.0, 0.75, 0.0, 1.0), Qt.rgba(1.0, 0.5, 0.0, 1.0), t);
        } else if (temp <= 85) {
            const t = (temp - 70) / 15.0;
            return _lerpColor(Qt.rgba(1.0, 0.5, 0.0, 1.0), Qt.rgba(1.0, 0.07, 0.0, 1.0), t);
        } else {
            return "#ff1100";
        }
    }

    // --- Drop shadow ---
    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    // --- Glass card background ---
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

    // --- Content ---
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8

        // Header
        StyledText {
            Layout.alignment: Qt.AlignLeft
            text: "THERMAL"
            font {
                pixelSize: Appearance.font.pixelSize.smallest
                weight: Font.DemiBold
                letterSpacing: 2.0
                capitalization: Font.AllUppercase
            }
            color: Appearance.colors.colSubtext
        }

        // Bloom canvas
        Canvas {
            id: bloomCanvas
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 200
            Layout.preferredHeight: 200

            readonly property int temp: ResourceUsage.gpuTemp
            readonly property real normalizedTemp: Math.max(0, Math.min(temp, 100)) / 100.0

            onPaint: {
                const ctx = getContext("2d");
                const w = width;
                const h = height;
                const cx = w / 2;
                const cy = h / 2;

                ctx.clearRect(0, 0, w, h);

                const baseRadius = Math.min(cx, cy) * 0.35;
                const maxRadius = Math.min(cx, cy) * 0.95;
                // Pulse amplitude scales with temperature
                const pulseAmp = 4 + normalizedTemp * 12;
                const currentRadius = baseRadius + pulseAmp * Math.sin(root._phase);

                const coreColor = root._tempToColor(temp);
                const ringCount = 6;

                // Heat shimmer offset at high temps
                const shimmerEnabled = temp > 70;
                const shimmerStrength = shimmerEnabled ? (temp - 70) / 30.0 * 3.0 : 0;

                for (let i = ringCount - 1; i >= 0; i--) {
                    const ringFraction = i / (ringCount - 1); // 0 = innermost, 1 = outermost
                    const ringRadius = currentRadius + (maxRadius - currentRadius) * ringFraction;
                    const opacity = 1.0 - ringFraction * 0.8; // 1.0 at center, 0.2 at edge

                    // Shimmer: slight positional noise at high temps
                    let ox = 0;
                    let oy = 0;
                    if (shimmerEnabled && i > 0) {
                        ox = Math.sin(root._phase * 3.7 + i * 1.3) * shimmerStrength;
                        oy = Math.cos(root._phase * 2.9 + i * 0.9) * shimmerStrength;
                    }

                    const grad = ctx.createRadialGradient(
                        cx + ox, cy + oy, 0,
                        cx + ox, cy + oy, ringRadius
                    );

                    // Core color at center, fading to transparent
                    const r = Math.round(coreColor.r * 255);
                    const g = Math.round(coreColor.g * 255);
                    const b = Math.round(coreColor.b * 255);

                    grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + "," + (opacity * 0.9).toFixed(3) + ")");
                    grad.addColorStop(0.4, "rgba(" + r + "," + g + "," + b + "," + (opacity * 0.5).toFixed(3) + ")");
                    grad.addColorStop(0.7, "rgba(" + r + "," + g + "," + b + "," + (opacity * 0.2).toFixed(3) + ")");
                    grad.addColorStop(1.0, "rgba(" + r + "," + g + "," + b + ",0)");

                    ctx.fillStyle = grad;
                    ctx.beginPath();
                    ctx.arc(cx + ox, cy + oy, ringRadius, 0, 2 * Math.PI);
                    ctx.fill();
                }

                // Bright center dot
                const dotGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, currentRadius * 0.3);
                const dr = Math.round(coreColor.r * 255);
                const dg = Math.round(coreColor.g * 255);
                const db = Math.round(coreColor.b * 255);
                dotGrad.addColorStop(0, "rgba(255,255,255,0.9)");
                dotGrad.addColorStop(0.3, "rgba(" + dr + "," + dg + "," + db + ",0.8)");
                dotGrad.addColorStop(1.0, "rgba(" + dr + "," + dg + "," + db + ",0)");
                ctx.fillStyle = dotGrad;
                ctx.beginPath();
                ctx.arc(cx, cy, currentRadius * 0.3, 0, 2 * Math.PI);
                ctx.fill();
            }

            // Repaint when temperature changes
            onTempChanged: requestPaint()
        }

        // Temperature readout
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: ResourceUsage.gpuTemp > 0 ? ResourceUsage.gpuTemp + "\u00B0C" : "--"
                font {
                    pixelSize: Appearance.font.pixelSize.huge
                    weight: Font.Bold
                }
                color: root._tempToColor(ResourceUsage.gpuTemp)
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "GPU"
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.DemiBold
                    letterSpacing: 1.5
                    capitalization: Font.AllUppercase
                }
                color: Appearance.colors.colSubtext
            }
        }
    }
}
