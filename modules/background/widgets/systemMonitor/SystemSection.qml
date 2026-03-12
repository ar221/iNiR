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
        label: "CPU"
        secondaryText: ResourceUsage.cpuTemp > 0 ? ResourceUsage.cpuTemp + "°C" : ""
    }

    CircularProgressRing {
        Layout.alignment: Qt.AlignTop
        value: ResourceUsage.memoryUsedPercentage
        ringColor: Appearance.colors.colSecondary
        label: "RAM"
        secondaryText: formatMem(ResourceUsage.memoryUsed) + " / " + formatMem(ResourceUsage.memoryTotal)

        function formatMem(kb) {
            if (kb < 1024) return kb + " KB"
            if (kb < 1024 * 1024) return (kb / 1024).toFixed(1) + " MB"
            return (kb / (1024 * 1024)).toFixed(1) + " GB"
        }
    }

    CircularProgressRing {
        Layout.alignment: Qt.AlignTop
        visible: root.showGpu
        value: ResourceUsage.gpuUsage
        ringColor: Appearance.colors.colTertiary
        label: "GPU"
        secondaryText: ResourceUsage.gpuTemp > 0 ? ResourceUsage.gpuTemp + "°C" : ""
    }
}
