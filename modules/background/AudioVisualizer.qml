import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    // Config
    readonly property var config: Config.options?.background?.widgets?.audioVisualizer ?? {}
    readonly property string style: config.style ?? "bars"
    readonly property int barCount: config.barCount ?? 50
    readonly property real visualizerOpacity: config.opacity ?? 0.3
    readonly property string position: config.position ?? "bottom"
    readonly property string colorSource: config.colorSource ?? "primary"
    readonly property bool autoHide: config.autoHide ?? true
    readonly property int visualizerHeight: config.height ?? 200
    readonly property real barSpacing: config.barSpacing ?? 2
    readonly property real barRadius: config.barRadius ?? 3

    // Audio state
    readonly property bool audioPlaying: MprisController.activePlayer?.isPlaying ?? false
    readonly property bool shouldShow: audioPlaying || !autoHide

    // Size and position managed by parent — just fill what we're given
    anchors.fill: parent

    opacity: shouldShow ? visualizerOpacity : 0
    visible: opacity > 0
    Behavior on opacity {
        enabled: Appearance.animationsEnabled
        NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
    }

    // Resolve color from Material You palette based on config
    readonly property color resolvedColor: {
        if (Appearance.angelEverywhere) return Appearance.angel.colPrimary
        if (Appearance.inirEverywhere) {
            switch (colorSource) {
                case "secondary": return Appearance.inir.colSecondary
                case "tertiary": return Appearance.inir.colTertiary
                default: return Appearance.inir.colPrimary
            }
        }
        switch (colorSource) {
            case "secondary": return Appearance.m3colors.m3secondary
            case "tertiary": return Appearance.m3colors.m3tertiary
            case "primaryContainer": return Appearance.m3colors.m3primaryContainer
            default: return Appearance.m3colors.m3primary
        }
    }

    readonly property color resolvedColorLow: {
        if (Appearance.angelEverywhere) return Appearance.angel.colGlassCard
        if (Appearance.inirEverywhere) return Appearance.inir.colSecondaryContainer
        return Appearance.m3colors.m3secondaryContainer
    }

    // Cava data source
    CavaProcess {
        id: cava
        active: root.shouldShow && root.visible
    }

    // Bar-style visualizer — single direction, bars grow upward from bottom
    Loader {
        active: root.style === "bars"
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent

            // Use actual cava point count so bars always fill the full width
            readonly property int actualBarCount: cava.points.length > 0 ? cava.points.length : root.barCount

            Repeater {
                model: parent.actualBarCount

                Rectangle {
                    id: bar
                    required property int index

                    readonly property real barValue: {
                        const pts = cava.points
                        if (pts.length === 0 || index >= pts.length) return 0
                        return pts[index] || 0
                    }

                    readonly property real normalizedValue: Math.min(1, barValue / 1000)
                    readonly property string intensity: normalizedValue > 0.7 ? "high" : normalizedValue > 0.35 ? "med" : "low"

                    readonly property real barWidth: (parent.width - (parent.actualBarCount - 1) * root.barSpacing) / parent.actualBarCount

                    x: index * (barWidth + root.barSpacing)
                    y: parent.height - height
                    width: barWidth
                    height: Math.max(2, normalizedValue * parent.height)
                    radius: root.barRadius
                    color: intensity === "high" ? root.resolvedColor
                         : intensity === "med" ? root.resolvedColor
                         : root.resolvedColorLow
                    opacity: 0.9

                    Behavior on height {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                    }
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation { duration: 100 }
                    }
                }
            }
        }
    }

    // Wave-style visualizer
    Loader {
        active: root.style === "wave"
        anchors.fill: parent
        sourceComponent: WaveVisualizer {
            points: cava.points
            color: root.resolvedColor
            live: cava.points.length > 0
        }
    }
}
