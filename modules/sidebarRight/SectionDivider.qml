import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Clean section divider - just text with subtle styling, no lines
Item {
    id: root
    
    required property string text
    property int fontSize: Appearance.font.pixelSize.smaller
    property int fontWeight: Font.Medium

    Layout.fillWidth: true
    implicitHeight: labelText.implicitHeight + 8

    // Signature accent tick — 2px wide, #ff1100 @ 60% opacity, aligned with label
    Rectangle {
        id: accentTick
        anchors.left: parent.left
        anchors.verticalCenter: labelText.verticalCenter
        width: 2
        height: labelText.implicitHeight
        color: "#ff1100"
        opacity: 0.6
    }

    StyledText {
        id: labelText
        anchors.left: accentTick.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: root.fontSize
        font.weight: root.fontWeight
        font.letterSpacing: 0.5
        color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary
            : Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
            : Appearance.colors.colSubtext
        opacity: 0.8
    }
}
