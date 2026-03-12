import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property var configEntry: ({})

    readonly property string footerText: configEntry.footerText ?? "Touch Grass"

    implicitWidth: parent ? parent.width : 200
    implicitHeight: footerRow.implicitHeight + 12

    // Top separator line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
    }

    RowLayout {
        id: footerRow
        anchors.centerIn: parent
        spacing: 6

        StyledText {
            text: root.footerText
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colPrimary
        }

        MaterialSymbol {
            text: "spa"
            iconSize: 16
            color: Appearance.colors.colPrimary
        }
    }
}
