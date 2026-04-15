import QtQuick
import QtQuick.Layouts
import qs.modules.common

RowLayout {
    id: root
    required property string text
    spacing: 6
    Layout.fillWidth: true

    Text {
        text: root.text
        font.pixelSize: 8
        font.bold: true
        font.letterSpacing: 2.5
        font.capitalization: Font.AllUppercase
        color: Qt.rgba(
            Appearance.colors.colOnSurfaceVariant.r,
            Appearance.colors.colOnSurfaceVariant.g,
            Appearance.colors.colOnSurfaceVariant.b,
            0.3
        )
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Appearance.colors.colLayer1
    }
}
