pragma ComponentBehavior: Bound

import QtQuick
import qs
import QtQuick.Layouts
import qs.modules.common
import qs.services

RowLayout {
    id: root
    spacing: 4
    Layout.fillWidth: true
    height: 36

    property bool polling: GlobalStates.sidebarLeftOpen

    onPollingChanged: {
        if (polling) ResourceUsage.ensureRunning()
    }

    component StripCell : Rectangle {
        id: cell
        required property string label
        required property string value
        property bool hot: false

        Layout.fillWidth: true
        implicitHeight: 36
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer1
        radius: 2

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 1
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: cell.label
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
                color: Qt.rgba(
                    Appearance.colors.colOnSurfaceVariant.r,
                    Appearance.colors.colOnSurfaceVariant.g,
                    Appearance.colors.colOnSurfaceVariant.b,
                    0.25
                )
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: cell.value
                font.pixelSize: 13
                font.family: Appearance.font.numbers?.family ?? Appearance.font.family.main
                color: cell.hot ? "#ff3333" : Appearance.colors.colOnSurfaceVariant
                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMoveEnter.duration }
                }
            }
        }
    }

    // cpuUsage / gpuUsage are 0–1 floats
    StripCell {
        label: "CPU"
        value: Math.round(ResourceUsage.cpuUsage * 100) + "%"
        hot: ResourceUsage.cpuUsage > 0.8
    }
    StripCell {
        label: "GPU"
        value: Math.round(ResourceUsage.gpuUsage * 100) + "%"
        hot: ResourceUsage.gpuUsage > 0.8
    }
    // memoryUsed is in kB — kbToGbString handles the conversion
    StripCell {
        label: "MEM"
        value: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)
        hot: ResourceUsage.memoryUsedPercentage > 0.9
    }
    // vramUsed is in bytes — divide by 1073741824 (1024^3) for GB
    StripCell {
        label: "VRAM"
        value: (ResourceUsage.vramUsed / 1073741824).toFixed(1) + " GB"
        hot: ResourceUsage.vramUsedPercentage > 0.9
    }
}
