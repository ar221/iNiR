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
        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

        RowLayout {
            id: diskRow
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol { text: "hard_drive"; iconSize: 14; color: Appearance.colors.colPrimary }
            StyledText {
                text: Math.round(ResourceUsage.diskUsedPercentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // Swap pill
    Rectangle {
        visible: (configEntry.showStats ?? true) && ResourceUsage.swapTotal > 1024
        Layout.preferredHeight: 28
        Layout.preferredWidth: swapRow.implicitWidth + 16
        radius: 14
        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

        RowLayout {
            id: swapRow
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol { text: "swap_horiz"; iconSize: 14; color: Appearance.colors.colSecondary }
            StyledText {
                text: Math.round(ResourceUsage.swapUsedPercentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // Temp pill
    Rectangle {
        visible: (configEntry.showStats ?? true) && ResourceUsage.maxTemp > 0
        Layout.preferredHeight: 28
        Layout.preferredWidth: tempRow.implicitWidth + 16
        radius: 14
        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

        RowLayout {
            id: tempRow
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                text: "thermostat"
                iconSize: 14
                color: ResourceUsage.maxTemp >= 80 ? Appearance.colors.colError : Appearance.colors.colTertiary
            }
            StyledText {
                text: ResourceUsage.maxTemp + "°C"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    Item { Layout.fillWidth: true }
}
