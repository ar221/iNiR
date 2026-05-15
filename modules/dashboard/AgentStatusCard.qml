import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Agents"
    accentHeader: true

    readonly property var agents: Config.options?.dashboard?.agentStatus?.agents ?? []
    readonly property bool hasData: agents.length > 0

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.hasData

        Repeater {
            model: root.agents

            AgentTile {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                name: modelData.name ?? ""
                initial: modelData.initial ?? ""
                route: modelData.domain ?? ""
                lastActive: ""
                status: "idle"
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "AWAITING AGENT ACTIVITY"
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
