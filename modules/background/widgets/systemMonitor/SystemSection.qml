import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})
    property bool showGpu: configEntry.showGpu ?? true

    spacing: 8

    StyledText {
        text: "SYSTEM"
        font.pixelSize: Appearance.font.pixelSize.smallest
        font.weight: Font.DemiBold
        font.letterSpacing: 2.0
        font.family: Appearance.font.family.monospace
        color: Appearance.mission.colTextSecondary
    }

    RowLayout {
        spacing: 16

        CircularProgressRing {
            Layout.alignment: Qt.AlignTop
            value: ResourceUsage.cpuUsage
            ringColor: Appearance.mission.colAccent
            icon: "settings"
            label: "CPU"
            valueText: Math.round(ResourceUsage.cpuUsage * 100) + "%"
            history: ResourceUsage.cpuUsageHistory
        }

        CircularProgressRing {
            Layout.alignment: Qt.AlignTop
            value: ResourceUsage.memoryUsedPercentage
            ringColor: Appearance.mission.colTextSecondary
            icon: "grid_view"
            label: "RAM"
            valueText: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
            history: ResourceUsage.memoryUsageHistory
        }

        CircularProgressRing {
            Layout.alignment: Qt.AlignTop
            value: ResourceUsage.cpuTemp > 0 ? Math.min(ResourceUsage.cpuTemp / 100, 1.0) : 0
            ringColor: Appearance.mission.colTextMuted
            icon: "thermostat"
            label: "TEMP"
            valueText: ResourceUsage.cpuTemp > 0 ? ResourceUsage.cpuTemp + "\u00B0C" : "--"
        }

        CircularProgressRing {
            Layout.alignment: Qt.AlignTop
            visible: root.showGpu && ResourceUsage.vramTotal > 1
            value: ResourceUsage.vramUsedPercentage
            ringColor: Appearance.mission.colCritical
            icon: "memory"
            label: "VRAM"
            valueText: {
                const gb = ResourceUsage.vramUsed / (1024 * 1024 * 1024)
                return gb.toFixed(1) + " GB"
            }
            history: ResourceUsage.gpuUsageHistory
        }
    }
}
