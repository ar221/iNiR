pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: statsRow.implicitHeight + 12

    readonly property bool compactMode: Config.options?.controlPanel?.compactMode ?? true
    
    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere

    radius: Appearance.controlPanel.radiusSmall
    color: Appearance.controlPanel.colCard
    border.width: Appearance.controlPanel.borderWidth
    border.color: Appearance.controlPanel.colCardBorder

    AngelPartialBorder { targetRadius: parent.radius; coverage: 0.45 }

    RowLayout {
        id: statsRow
        anchors.fill: parent
        anchors.margins: root.compactMode ? 5 : 6
        spacing: root.compactMode ? 6 : 8

        // CPU
        StatBar {
            Layout.fillWidth: true
            label: "CPU"
            value: (ResourceUsage.cpuUsage ?? 0) * 100
            barColor: ((ResourceUsage.cpuUsage ?? 0) * 100) > 80 ? Appearance.controlPanel.colStatusCritical
                    : Appearance.controlPanel.colAccent
        }

        // RAM
        StatBar {
            Layout.fillWidth: true
            label: "RAM"
            value: (ResourceUsage.memoryUsedPercentage ?? 0) * 100
            barColor: (ResourceUsage.memoryUsedPercentage ?? 0) > 0.85 ? Appearance.controlPanel.colStatusCritical
                    : Appearance.controlPanel.colAccent
        }

        // Battery (if available)
        Loader {
            Layout.fillWidth: true
            active: Battery.available
            sourceComponent: StatBar {
                label: "BAT"
                value: (Battery.percentage ?? 0) * 100
                barColor: (Battery.percentage ?? 0) * 100 < 20 ? Appearance.controlPanel.colStatusCritical
                        : Battery.charging ? Appearance.controlPanel.colStatusDone
                        : Appearance.controlPanel.colAccent
            }
        }
    }

    component StatBar: ColumnLayout {
        id: bar
        property string label
        property real value: 0
        property color barColor: Appearance.controlPanel.colAccent

        spacing: 2

        RowLayout {
            spacing: 4
            StyledText {
                text: bar.label
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.controlPanel.colTextSecondary
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: Math.round(bar.value) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.numbers
                color: Appearance.controlPanel.colText
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: root.compactMode ? 3 : 4
            radius: Appearance.controlPanel.commandPreset ? Appearance.controlPanel.radiusSmall : 2
            color: Appearance.controlPanel.colTrack

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, bar.value / 100))
                height: parent.height
                radius: Appearance.controlPanel.commandPreset ? Appearance.controlPanel.radiusSmall : 2
                color: bar.barColor

                Behavior on width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
