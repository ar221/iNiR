import QtQuick
import QtQuick.Layouts
import qs.modules.common

Rectangle {
    id: root
    height: 1
    Layout.fillWidth: true

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#ff1100" }
        GradientStop { position: 0.4; color: Qt.rgba(1, 0.067, 0, 0.15) }
        GradientStop { position: 1.0; color: "transparent" }
    }
}
