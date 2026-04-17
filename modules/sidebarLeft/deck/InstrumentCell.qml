import QtQuick
import QtQuick.Layouts
import qs.modules.common

Rectangle {
    id: root
    required property string label
    required property string value
    property bool available: value !== "—"

    Layout.fillWidth: true
    implicitHeight: 44
    color: Appearance.colors.colLayer0
    border.width: 1
    border.color: Appearance.colors.colLayer1
    radius: 2

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 3

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1.5
            font.capitalization: Font.AllUppercase
            color: Qt.rgba(
                Appearance.colors.colOnSurfaceVariant.r,
                Appearance.colors.colOnSurfaceVariant.g,
                Appearance.colors.colOnSurfaceVariant.b,
                0.25
            )
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.value
            font.pixelSize: 15
            font.family: Appearance.font.numbers?.family ?? Appearance.font.family.main
            font.bold: true
            color: root.available ? "#ff1100"
                 : Qt.rgba(
                     Appearance.colors.colOnSurfaceVariant.r,
                     Appearance.colors.colOnSurfaceVariant.g,
                     Appearance.colors.colOnSurfaceVariant.b,
                     0.2
                   )
        }
    }
}
