pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.services

/**
 * PluginChainStrip — compact pill-row showing the active preset's plugin
 * chain in signal-flow order. Reads `EasyEffects.currentPresetPlugins`.
 *
 * Each pill shows a plugin's display name (mapped from its base name).
 * Arrows between pills indicate signal flow direction. Wraps if needed.
 *
 * Empty state when no preset is active.
 */
Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: chainFlow.implicitHeight + 4

    readonly property var plugins: EasyEffects.currentPresetPlugins ?? []
    readonly property bool _hasData: plugins.length > 0

    // Plugin base-name → display label. Covers every EE plugin from the
    // upstream presets_manager.cpp create_wrapper switch.
    readonly property var _pluginLabels: ({
        "autogain": "AutoGain",
        "bass_enhancer": "Bass+",
        "bass_loudness": "BassLoud",
        "compressor": "Comp",
        "convolver": "Conv",
        "crossfeed": "XFeed",
        "crusher": "Crush",
        "crystalizer": "Crystal",
        "deepfilternet": "DeepFN",
        "deesser": "Deess",
        "delay": "Delay",
        "echo_canceller": "EchoCxl",
        "equalizer": "EQ",
        "exciter": "Excite",
        "expander": "Expand",
        "filter": "Filter",
        "gate": "Gate",
        "level_meter": "Level",
        "limiter": "Limit",
        "loudness": "Loud",
        "maximizer": "Max",
        "multiband_compressor": "MBComp",
        "multiband_gate": "MBGate",
        "pitch": "Pitch",
        "reverb": "Verb",
        "rnnoise": "RNNoise",
        "speex": "Speex",
        "stereo_tools": "Stereo",
        "voice_suppressor": "VoiceSup"
    })

    function _label(name) {
        return root._pluginLabels[name] ?? name
    }

    // ── Empty state ───────────────────────────────────────────────────────
    Text {
        anchors.centerIn: parent
        visible: !root._hasData
        text: "load a preset to see the chain"
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.family: Appearance.font.family.main
        color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.35)
    }

    // ── Chain flow ────────────────────────────────────────────────────────
    Flow {
        id: chainFlow
        anchors.fill: parent
        anchors.topMargin: 2
        spacing: 4
        visible: root._hasData

        Repeater {
            model: root.plugins

            Row {
                required property string modelData
                required property int index
                spacing: 4

                // Arrow separator (skip before first pill)
                Text {
                    visible: parent.index > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "→"
                    font.pixelSize: 10
                    font.family: Appearance.font.family.monospace
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
                }

                // Plugin pill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: pillLabel.implicitWidth + 12
                    implicitHeight: 20
                    radius: 10
                    color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12)
                    border.width: 1
                    border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.30)

                    Text {
                        id: pillLabel
                        anchors.centerIn: parent
                        text: root._label(parent.parent.modelData)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.family: Appearance.font.family.main
                        font.weight: Font.Medium
                        color: Appearance.colors.colPrimary
                    }
                }
            }
        }
    }
}
