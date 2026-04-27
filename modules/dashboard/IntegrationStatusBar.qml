import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    showHeader: false

    readonly property var integrations: Config.options?.dashboard?.integrations ?? []
    readonly property bool hasData: integrations.length > 0

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        visible: root.hasData

        StyledText {
            text: "INTEGRATIONS"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            font.family: Appearance.font.family.monospace
            color: Appearance.mission.colAccentMuted
        }

        Rectangle {
            width: 1
            Layout.fillHeight: true
            color: Appearance.mission.colGrid
        }

        Flow {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: root.integrations

                Row {
                    required property var modelData
                    required property int index
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Appearance.mission.colIdle
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: modelData.name ?? ""
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        font.family: Appearance.font.family.monospace
                        color: Appearance.mission.colTextMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "NO INTEGRATIONS CONFIGURED"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 8
        bottomPadding: 8
    }
}
