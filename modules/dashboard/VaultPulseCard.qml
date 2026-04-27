import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Vault"

    readonly property string vaultPath: Config.options?.dashboard?.vaultPulse?.vaultPath ?? ""
    readonly property bool hasData: vaultPath.length > 0

    function statRow(label, value) {
        return { label: label, value: value }
    }

    readonly property var stats: [
        statRow("TOTAL NOTES", "—"),
        statRow("EDITED TODAY", "—"),
        statRow("INBOX", "—"),
        statRow("ORPHANS", "—")
    ]

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 10
        columnSpacing: 12
        visible: root.hasData

        Repeater {
            model: root.stats

            Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: statCol.implicitHeight

                ColumnLayout {
                    id: statCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 2

                    StyledText {
                        text: modelData.value
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.m3colors.m3onBackground
                    }

                    StyledText {
                        text: modelData.label
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        font.family: Appearance.font.family.monospace
                        color: Appearance.mission.colTextMuted
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "VAULT PATH NOT SET"
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
