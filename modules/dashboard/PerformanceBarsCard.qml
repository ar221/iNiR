import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Dashboard card showing 4 vertical performance bars: CPU, GPU, RAM, VRAM.
// Temperature row (CPU/GPU) is inlined below the bars — temps are perf signals.
DashboardCard {
    id: root
    headerText: "Performance"
    headerFontSize: 11

    function tempColor(temp) {
        // Blend from colSubtext (40°C) to colError (95°C)
        const t = Math.min(1, Math.max(0, (temp - 40) / 55))
        return ColorUtils.mix(Appearance.colors.colError, Appearance.colors.colSubtext, t)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 160
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

    // ── Thin separator ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    // ── Temperature row ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            text: "CPU " + ResourceUsage.cpuTemp + "°"
            font.pixelSize: 12
            font.family: Appearance.font.family.numbers
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
            font.family: Appearance.font.family.numbers
            color: root.tempColor(ResourceUsage.gpuTemp)
        }
    }
}
