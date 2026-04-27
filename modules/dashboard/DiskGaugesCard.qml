import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard

DashboardCard {
    id: root

    headerText: "Storage"

    readonly property var mounts: Config.options?.dashboard?.diskGauges?.mounts ?? []
    readonly property bool hasData: mounts.length > 0

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: root.hasData

        Repeater {
            model: root.mounts

            BarcodeMeter {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                value: 0
                label: modelData
                color: Appearance.colors.colTertiary
                variant: "block"
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.hasData
        text: "CONFIGURE MOUNTS IN CONFIG"
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
