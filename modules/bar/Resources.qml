import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options?.bar?.borderless ?? false
    property bool alwaysShowAllResources: false
    property bool hideWhenIdle: Config.options?.bar?.resources?.hideWhenIdle ?? false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    Component.onCompleted: ResourceUsage.ensureRunning()

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
            warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
            shown: (Config.options?.bar?.resources?.showMemoryIndicator ?? true) &&
                (!root.hideWhenIdle || root.containsMouse || root.alwaysShowAllResources ||
                    ResourceUsage.memoryUsedPercentage * 100 >= (Config.options?.bar?.resources?.memoryCautionThreshold ?? 80))
        }

        Resource {
            iconName: "thermostat"
            percentage: Math.min(ResourceUsage.cpuTemp / 100, 1.0)
            cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
            warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
            shown: (Config.options?.bar?.resources?.showTempIndicator ?? true) &&
                (!root.hideWhenIdle
                    ? ((Config.options?.bar?.resources?.alwaysShowTemp ?? true) ||
                        (MprisController.activePlayer?.trackTitle == null) ||
                        root.alwaysShowAllResources)
                    : (root.containsMouse || root.alwaysShowAllResources ||
                        ResourceUsage.cpuTemp >= (Config.options?.bar?.resources?.tempCautionThreshold ?? 65)))
            Layout.leftMargin: shown ? 6 : 0
        }

        Resource {
            iconName: "developer_board"
            percentage: Math.min(ResourceUsage.gpuTemp / 100, 1.0)
            cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
            warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
            shown: (Config.options?.bar?.resources?.showTempIndicator ?? true) &&
                (!root.hideWhenIdle
                    ? ((Config.options?.bar?.resources?.alwaysShowTemp ?? true) ||
                        (MprisController.activePlayer?.trackTitle == null) ||
                        root.alwaysShowAllResources)
                    : (root.containsMouse || root.alwaysShowAllResources ||
                        ResourceUsage.gpuTemp >= (Config.options?.bar?.resources?.tempCautionThreshold ?? 65)))
            Layout.leftMargin: shown ? 6 : 0
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
            shown: (Config.options?.bar?.resources?.showCpuIndicator ?? true) &&
                (!root.hideWhenIdle
                    ? ((Config.options?.bar?.resources?.alwaysShowCpu ?? true) ||
                        !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                        root.alwaysShowAllResources)
                    : (root.containsMouse || root.alwaysShowAllResources ||
                        ResourceUsage.cpuUsage * 100 >= (Config.options?.bar?.resources?.cpuCautionThreshold ?? 70)))
            Layout.leftMargin: shown ? 6 : 0
        }

        Resource {
            iconName: "memory_alt"
            percentage: ResourceUsage.gpuUsage
            cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
            shown: (Config.options?.bar?.resources?.showGpuIndicator ?? true) &&
                (!root.hideWhenIdle
                    ? ((Config.options?.bar?.resources?.alwaysShowGpu ?? true) ||
                        !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                        root.alwaysShowAllResources)
                    : (root.containsMouse || root.alwaysShowAllResources ||
                        ResourceUsage.gpuUsage * 100 >= (Config.options?.bar?.resources?.gpuCautionThreshold ?? 70)))
            Layout.leftMargin: shown ? 6 : 0
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
