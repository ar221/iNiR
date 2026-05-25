import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

RowLayout {
    id: root

    property var configEntry: ({})

    spacing: 8

    // Disk pill
    Rectangle {
        visible: configEntry.showStats ?? true
        Layout.preferredHeight: 28
        Layout.preferredWidth: diskRow.implicitWidth + 16
        radius: 14
        color: Appearance.mission.colSurface

        RowLayout {
            id: diskRow
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol { text: "hard_drive"; iconSize: 14; color: Appearance.mission.colAccent }
            StyledText {
                text: Math.round(ResourceUsage.diskUsedPercentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colText
            }
        }
    }

    // Swap pill
    Rectangle {
        visible: (configEntry.showStats ?? true) && ResourceUsage.swapTotal > 1024
        Layout.preferredHeight: 28
        Layout.preferredWidth: swapRow.implicitWidth + 16
        radius: 14
        color: Appearance.mission.colSurface

        RowLayout {
            id: swapRow
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol { text: "swap_horiz"; iconSize: 14; color: Appearance.mission.colTextSecondary }
            StyledText {
                text: Math.round(ResourceUsage.swapUsedPercentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colText
            }
        }
    }

    // Temp pill
    Rectangle {
        visible: (configEntry.showStats ?? true) && ResourceUsage.maxTemp > 0
        Layout.preferredHeight: 28
        Layout.preferredWidth: tempRow.implicitWidth + 16
        radius: 14
        color: Appearance.mission.colSurface

        RowLayout {
            id: tempRow
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                text: "thermostat"
                iconSize: 14
                color: ResourceUsage.maxTemp >= 80 ? Appearance.mission.colCritical : Appearance.mission.colTextMuted
            }
            StyledText {
                text: ResourceUsage.maxTemp + "°C"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colText
            }
        }
    }

    Item { Layout.fillWidth: true }
}
