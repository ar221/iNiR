import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services

RowLayout {
    id: root
    spacing: 12

    // Ensure resource polling is active while rings are visible
    Component.onCompleted: ResourceUsage.ensureRunning()

    // CPU ring — orange → pink
    MiniRing {
        visible: Config.options?.bar?.rings?.cpu ?? true
        value: ResourceUsage.cpuUsage
        label: "CPU"
        gradientStart: "#fb923c"
        gradientEnd: "#f472b6"
        cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
        warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        Layout.alignment: Qt.AlignVCenter
    }

    // GPU ring — sky → indigo
    MiniRing {
        visible: Config.options?.bar?.rings?.gpu ?? true
        value: ResourceUsage.gpuUsage
        label: "GPU"
        gradientStart: "#38bdf8"
        gradientEnd: "#818cf8"
        cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
        warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        Layout.alignment: Qt.AlignVCenter
    }

    // Temperature ring — green → cyan
    MiniRing {
        visible: Config.options?.bar?.rings?.temp ?? true
        value: Math.min(ResourceUsage.cpuTemp / 100, 1.0)
        label: "TMP"
        gradientStart: "#4ade80"
        gradientEnd: "#22d3ee"
        cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
        warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
        Layout.alignment: Qt.AlignVCenter
    }

    // RAM ring — purple → pink
    MiniRing {
        visible: Config.options?.bar?.rings?.ram ?? true
        value: ResourceUsage.memoryUsedPercentage
        label: "RAM"
        gradientStart: "#c084fc"
        gradientEnd: "#f472b6"
        cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
        warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        Layout.alignment: Qt.AlignVCenter
    }
}
