import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

// Minimal temperature readout strip, 24px height.
// Shows CPU and GPU temps with color shifting from subtext (cool) to error (hot).
// No DashboardCard wrapper — embeds directly in the center column.
RowLayout {
    id: root

    implicitHeight: 24
    spacing: 8

    function tempColor(temp) {
        // Blend from colSubtext (40°C) to colError (95°C)
        const t = Math.min(1, Math.max(0, (temp - 40) / 55))
        return ColorUtils.mix(Appearance.colors.colError, Appearance.colors.colSubtext, 1.0 - t)
    }

    // CPU label
    StyledText {
        text: "CPU " + ResourceUsage.cpuTemp + "°"
        font.pixelSize: 11
        font.family: Appearance.font.family.numbers
        color: root.tempColor(ResourceUsage.cpuTemp)
    }

    // Center divider bar — color follows the hotter sensor
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

    // GPU label
    StyledText {
        text: "GPU " + ResourceUsage.gpuTemp + "°"
        font.pixelSize: 11
        font.family: Appearance.font.family.numbers
        color: root.tempColor(ResourceUsage.gpuTemp)
    }
}
