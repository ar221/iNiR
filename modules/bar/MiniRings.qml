import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services

RowLayout {
    id: root
    spacing: 12

    // Ensure resource polling is active while rings are visible
    Component.onCompleted: ResourceUsage.ensureRunning()

    // CPU ring — primary → secondary
    MiniRing {
        visible: Config.options?.bar?.rings?.cpu ?? true
        value: ResourceUsage.cpuUsage
        label: "CPU"
        gradientStart: Appearance.colors.colPrimary
        gradientEnd: Appearance.colors.colSecondary
        cautionThreshold: Config.options?.bar?.resources?.cpuCautionThreshold ?? 70
        warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        Layout.alignment: Qt.AlignVCenter
    }

    // GPU ring — secondary → tertiary
    MiniRing {
        visible: Config.options?.bar?.rings?.gpu ?? true
        value: ResourceUsage.gpuUsage
        label: "GPU"
        gradientStart: Appearance.colors.colSecondary
        gradientEnd: Appearance.colors.colTertiary
        cautionThreshold: Config.options?.bar?.resources?.gpuCautionThreshold ?? 70
        warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        Layout.alignment: Qt.AlignVCenter
    }

    // Temperature ring — tertiary → primary
    MiniRing {
        visible: Config.options?.bar?.rings?.temp ?? true
        value: Math.min(ResourceUsage.cpuTemp / 100, 1.0)
        label: "TMP"
        gradientStart: Appearance.colors.colTertiary
        gradientEnd: Appearance.colors.colPrimary
        cautionThreshold: Config.options?.bar?.resources?.tempCautionThreshold ?? 65
        warningThreshold: Config.options?.bar?.resources?.tempWarningThreshold ?? 80
        Layout.alignment: Qt.AlignVCenter
    }

    // RAM ring — secondary → primary
    MiniRing {
        visible: Config.options?.bar?.rings?.ram ?? true
        value: ResourceUsage.memoryUsedPercentage
        label: "RAM"
        gradientStart: Appearance.colors.colSecondary
        gradientEnd: Appearance.colors.colPrimary
        cautionThreshold: Config.options?.bar?.resources?.memoryCautionThreshold ?? 80
        warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        Layout.alignment: Qt.AlignVCenter
    }
}
