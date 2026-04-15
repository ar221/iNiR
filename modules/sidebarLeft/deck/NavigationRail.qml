pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    required property int currentView
    signal viewRequested(int index)

    width: 40
    color: Appearance.colors.colLayer0
    border.width: 0

    // Right border separator
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Appearance.colors.colLayer1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 2

        RailButton {
            Layout.alignment: Qt.AlignHCenter
            iconName: "music_note"
            active: root.currentView === 0
            tooltip: "Media"
            onClicked: root.viewRequested(0)
        }

        RailButton {
            Layout.alignment: Qt.AlignHCenter
            iconName: "image"
            active: root.currentView === 1
            tooltip: "Wallpapers"
            onClicked: root.viewRequested(1)
        }

        RailButton {
            Layout.alignment: Qt.AlignHCenter
            iconName: "monitoring"
            active: root.currentView === 2
            tooltip: "System"
            onClicked: root.viewRequested(2)
        }

        Item { Layout.fillHeight: true }

        RailButton {
            Layout.alignment: Qt.AlignHCenter
            iconName: "settings"
            active: false
            tooltip: "Settings"
            onClicked: {
                // Open sidebar settings — deferred to future task
            }
        }
    }
}
