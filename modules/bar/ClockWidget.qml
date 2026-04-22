import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options?.bar?.borderless ?? false
    property bool showDate: Config.options?.bar?.verbose ?? true
    readonly property string monoFamily: (Appearance.font && Appearance.font.family && Appearance.font.family.mono)
        ? Appearance.font.family.mono
        : "monospace"
    readonly property string densityPreset: {
        const preset = String(Config.options?.bar?.density ?? "default").toLowerCase()
        return (preset === "compact" || preset === "airy") ? preset : "default"
    }
    readonly property string stylePreset: {
        const preset = String(Config.options?.bar?.stylePreset ?? "dusky").toLowerCase()
        return (preset === "clean" || preset === "glass") ? preset : "dusky"
    }
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: densityPreset === "compact" ? 5 : (densityPreset === "airy" ? 7 : 6)

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.larger
            font.family: root.monoFamily
            font.weight: root.stylePreset === "clean" ? Font.DemiBold : Font.Bold
            font.letterSpacing: root.stylePreset === "clean" ? 0.4 : (root.stylePreset === "glass" ? 1.05 : 0.9)
            color: Appearance.angelEverywhere ? Appearance.angel.colText
                : Appearance.inirEverywhere ? Appearance.inir.colText
                : clockMouse.containsMouse ? Appearance.colors.colOnLayer0 : Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        Rectangle {
            visible: root.showDate
            implicitWidth: root.stylePreset === "clean" ? 2 : 1
            implicitHeight: densityPreset === "compact" ? 10 : (densityPreset === "airy" ? 14 : 12)
            radius: 1
            color: Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
                : Appearance.inirEverywhere ? Appearance.inir.colTextSecondary
                : Appearance.colors.colOutline
            opacity: root.stylePreset === "glass" ? 0.6 : 0.8
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: root.monoFamily
            font.letterSpacing: root.stylePreset === "clean" ? 0.45 : (root.stylePreset === "glass" ? 0.8 : 0.7)
            font.weight: root.stylePreset === "clean" ? Font.Normal : Font.Medium
            color: Appearance.angelEverywhere ? Appearance.angel.colText
                : Appearance.inirEverywhere ? Appearance.inir.colText
                : clockMouse.containsMouse ? Appearance.colors.colOnLayer1 : Appearance.colors.colOnLayer1Inactive
            text: String(DateTime.date).toUpperCase()
        }
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen
    }
}
