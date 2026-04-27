import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    accentHeader: false
    showHeader: false

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            text: "READY"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 2.0
            font.family: Appearance.font.family.monospace
            color: Appearance.mission.colTextMuted
        }

        Flow {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: "COMMAND ROOM "
                font.pixelSize: 28
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colText
            }

            StyledText {
                text: "READY"
                font.pixelSize: 28
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colAccent
            }
        }

        StyledText {
            text: "Awaiting operator input"
            font.pixelSize: 11
            font.family: Appearance.font.family.main
            color: Appearance.mission.colTextFaint
        }
    }
}
