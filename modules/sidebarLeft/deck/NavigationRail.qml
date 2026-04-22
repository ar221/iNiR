pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    required property int currentView
    signal viewRequested(int index)

    // AudioFX gated on config — keeps the rail at 3 buttons if user disables it.
    readonly property bool _audioFXEnabled:
        Config.options?.sidebar?.deck?.audioFX?.enable ?? true

    width: 42
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
        anchors.leftMargin: 3
        anchors.rightMargin: 3
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 4

        RailButton {
            Layout.alignment: Qt.AlignHCenter
            iconName: "music_note"
            active: root.currentView === 0
            tooltip: "Listen"
            onClicked: root.viewRequested(0)
        }

        RailButton {
            Layout.alignment: Qt.AlignHCenter
            iconName: "image"
            active: root.currentView === 1
            tooltip: "Look"
            onClicked: root.viewRequested(1)
        }

        RailButton {
            Layout.alignment: Qt.AlignHCenter
            iconName: "monitoring"
            active: root.currentView === 2
            tooltip: "Pulse"
            onClicked: root.viewRequested(2)
        }

        // View 3: AudioFX (EasyEffects). Hidden if disabled in config.
        RailButton {
            Layout.alignment: Qt.AlignHCenter
            visible: root._audioFXEnabled
            iconName: "equalizer"
            active: root.currentView === 3
            tooltip: "Shape"
            onClicked: root.viewRequested(3)
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
