import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.services

RowLayout {
    id: root

    property var configEntry: ({})
    property bool showGpu: configEntry.showGpu ?? true

    spacing: 16

    CircularProgressRing {
        Layout.alignment: Qt.AlignTop
        value: ResourceUsage.cpuUsage
        ringColor: Appearance.colors.colPrimary
        icon: "settings"
        label: "CPU"
        valueText: Math.round(ResourceUsage.cpuUsage * 100) + "%"
    }

    CircularProgressRing {
        Layout.alignment: Qt.AlignTop
        value: ResourceUsage.memoryUsedPercentage
        ringColor: Appearance.colors.colSecondary
        icon: "grid_view"
        label: "RAM"
        valueText: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
    }

    CircularProgressRing {
        Layout.alignment: Qt.AlignTop
        value: ResourceUsage.cpuTemp > 0 ? Math.min(ResourceUsage.cpuTemp / 100, 1.0) : 0
        ringColor: Appearance.colors.colTertiary
        icon: "thermostat"
        label: "TEMP"
        valueText: ResourceUsage.cpuTemp > 0 ? ResourceUsage.cpuTemp + "\u00B0C" : "--"
    }

    CircularProgressRing {
        Layout.alignment: Qt.AlignTop
        visible: root.showGpu && ResourceUsage.vramTotal > 1
        value: ResourceUsage.vramUsedPercentage
        ringColor: Appearance.m3colors.m3error
        icon: "memory"
        label: "VRAM"
        valueText: {
            const gb = ResourceUsage.vramUsed / (1024 * 1024 * 1024)
            return gb.toFixed(1) + " GB"
        }
    }
}
