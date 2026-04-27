import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "Performance"
    accentHeader: true

    function tempColor(temp) {
        const t = Math.min(1, Math.max(0, (temp - 40) / 55))
        return ColorUtils.mix(Appearance.mission.colCritical, Appearance.mission.colTextMuted, t)
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.cpuUsage
            label: "CPU"
            color: Appearance.mission.colActive
            variant: "block"
            cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        }

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.gpuUsage
            label: "GPU"
            color: Appearance.colors.colSecondary
            variant: "block"
            cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
            warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        }

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.memoryUsedPercentage
            label: "RAM"
            color: Appearance.colors.colTertiary
            variant: "block"
            cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
            warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        }

        BarcodeMeter {
            Layout.fillWidth: true
            value: ResourceUsage.vramUsedPercentage
            label: "VRAM"
            color: Appearance.mission.colAccentMuted
            variant: "block"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Appearance.mission.colGrid
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: "CPU " + ResourceUsage.cpuTemp + "°"
                font.pixelSize: 12
                font.family: Appearance.font.family.monospace
                color: root.tempColor(ResourceUsage.cpuTemp)
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                radius: 1
                color: root.tempColor(Math.max(ResourceUsage.cpuTemp, ResourceUsage.gpuTemp))

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: 300 }
                }
            }

            StyledText {
                text: "GPU " + ResourceUsage.gpuTemp + "°"
                font.pixelSize: 12
                font.family: Appearance.font.family.monospace
                color: root.tempColor(ResourceUsage.gpuTemp)
            }
        }
    }
}
