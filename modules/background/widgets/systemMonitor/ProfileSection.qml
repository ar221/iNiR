import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

RowLayout {
    id: root

    property var configEntry: ({})

    spacing: 12
    Layout.fillWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        StyledText {
            Layout.fillWidth: true
            property string greeting: {
                const h = new Date().getHours()
                if (h < 6) return "Good night"
                if (h < 12) return "Good morning"
                if (h < 18) return "Good afternoon"
                return "Good evening"
            }
            text: greeting + ", " + (root.configEntry.greetingName ?? "User")
            font.pixelSize: Appearance.font.pixelSize.larger
            font.family: Appearance.font.family.title
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
        }

        RowLayout {
            spacing: 6
            MaterialSymbol {
                text: "schedule"
                iconSize: 13
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: "Uptime: " + DateTime.uptime
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }
    }
}
