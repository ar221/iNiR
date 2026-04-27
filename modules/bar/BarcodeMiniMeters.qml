import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    Component.onCompleted: ResourceUsage.ensureRunning()

    readonly property real _availWidth: width
    readonly property string _layout: _availWidth >= 320 ? "full"
        : _availWidth >= 200 ? "compact"
        : "minimal"

    implicitWidth: _layout === "minimal" ? 160 : (_layout === "compact" ? 240 : 340)
    implicitHeight: 24

    RowLayout {
        anchors.fill: parent
        spacing: root._layout === "full" ? 10 : 6

        BarcodeMeter {
            visible: Config.options?.bar?.rings?.cpu ?? true
            value: Math.min(1, Math.max(0, ResourceUsage.cpuUsage))
            label: "CPU"
            color: Appearance.colors.colPrimary
            variant: "inline"
            showLabel: root._layout === "full"
            showValue: root._layout !== "minimal" || true
            inlineTrackWidth: root._layout === "full" ? 48 : 32
            cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        }

        BarcodeMeter {
            visible: Config.options?.bar?.rings?.gpu ?? true
            value: Math.min(1, Math.max(0, ResourceUsage.gpuUsage))
            label: "GPU"
            color: Appearance.colors.colSecondary
            variant: "inline"
            showLabel: root._layout === "full"
            inlineTrackWidth: root._layout === "full" ? 48 : 32
            cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        }

        BarcodeMeter {
            visible: (Config.options?.bar?.rings?.temp ?? true) && root._layout !== "minimal"
            value: Math.min(1, Math.max(0, ResourceUsage.cpuTemp / 100))
            label: "TMP"
            color: Appearance.colors.colError
            variant: "inline"
            showLabel: root._layout === "full"
            inlineTrackWidth: root._layout === "full" ? 48 : 32
            cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
            warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
        }

        BarcodeMeter {
            visible: Config.options?.bar?.rings?.ram ?? true
            value: Math.min(1, Math.max(0, ResourceUsage.memoryUsedPercentage))
            label: "RAM"
            color: Appearance.colors.colTertiary
            variant: "inline"
            showLabel: root._layout === "full"
            inlineTrackWidth: root._layout === "full" ? 48 : 32
            cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
            warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        }
    }
}
