import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})

    spacing: 2

    // Large time display
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: {
            const t = DateTime.time
            return t.split(":")[0] ?? "--"
        }
        font.pixelSize: 52
        font.family: Appearance.font.family.numbers
        font.weight: Font.Bold
        color: Appearance.colors.colPrimary
        lineHeight: 0.9
    }

    // Dots separator
    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4
        Repeater {
            model: 3
            Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: Appearance.colors.colPrimary
            }
        }
    }

    // Minutes
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: {
            const t = DateTime.time
            return t.split(":")[1] ?? "--"
        }
        font.pixelSize: 52
        font.family: Appearance.font.family.numbers
        font.weight: Font.Bold
        color: Appearance.colors.colPrimary
        lineHeight: 0.9
    }

    // Day name + date
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 6
        text: {
            const d = new Date()
            const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days[d.getDay()] + ", " + DateTime.shortDate
        }
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Medium
        color: Appearance.colors.colPrimary
    }
}
