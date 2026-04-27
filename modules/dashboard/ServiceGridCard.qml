import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Services"

    readonly property var services: Config.options?.dashboard?.serviceGrid?.services ?? []
    readonly property bool hasData: services.length > 0

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.hasData

        Repeater {
            model: root.services

            Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 32

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Appearance.mission.colIdle
                    }

                    StyledText {
                        text: modelData.replace(".service", "").toUpperCase()
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                        font.family: Appearance.font.family.monospace
                        color: Appearance.m3colors.m3onBackground
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: "—"
                        font.pixelSize: 10
                        font.family: Appearance.font.family.monospace
                        color: ColorUtils.transparentize(Appearance.mission.colText, 0.8)
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: ColorUtils.transparentize(Appearance.mission.colText, 0.96)
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "CONFIGURE SERVICES IN CONFIG"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.monospace
        color: ColorUtils.transparentize(Appearance.mission.colText, 0.85)
        horizontalAlignment: Text.AlignHCenter
        topPadding: 16
        bottomPadding: 16
    }
}
