import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Dashboard card showing 4 vertical performance bars: CPU, GPU, RAM, VRAM.
DashboardCard {
    id: root
    headerText: "Performance"

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Item { Layout.fillWidth: true }

        PerformanceBar {
            value: ResourceUsage.cpuUsage
            label: "CPU"
            lowColor: Appearance.colors.colPrimary
            highColor: Appearance.colors.colError
        }

        Item { Layout.fillWidth: true }

        PerformanceBar {
            value: ResourceUsage.gpuUsage
            label: "GPU"
            lowColor: Appearance.colors.colSecondary
            highColor: Appearance.colors.colError
        }

        Item { Layout.fillWidth: true }

        PerformanceBar {
            value: ResourceUsage.memoryUsedPercentage
            label: "RAM"
            lowColor: Appearance.colors.colTertiary
            highColor: Appearance.colors.colError
        }

        Item { Layout.fillWidth: true }

        PerformanceBar {
            value: ResourceUsage.vramUsedPercentage
            label: "VRAM"
            lowColor: Appearance.colors.colPrimary
            highColor: Appearance.colors.colError
        }

        Item { Layout.fillWidth: true }
    }
}
