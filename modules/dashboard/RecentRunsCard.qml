import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Recent Runs"

    readonly property bool hasData: false

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.hasData

        Repeater {
            model: []

            RoutineTile {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                timestamp: modelData.timestamp ?? ""
                label: modelData.label ?? ""
                actionText: "OPEN"
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "NO RUNS RECORDED"
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
