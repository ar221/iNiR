import QtQuick
import QtQuick.Layouts
import qs.modules.common

Rectangle {
    id: root
    height: 2
    radius: 1
    Layout.fillWidth: true

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Appearance.colors.colPrimary }
        GradientStop { position: 0.55; color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15) }
        GradientStop { position: 1.0; color: "transparent" }
    }
}
