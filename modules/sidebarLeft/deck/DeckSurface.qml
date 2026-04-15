pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.services

Item {
    id: root

    property int currentView: Config.options?.sidebar?.deck?.defaultView ?? 0

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_1) { root.currentView = 0; event.accepted = true }
        else if (event.key === Qt.Key_2) { root.currentView = 1; event.accepted = true }
        else if (event.key === Qt.Key_3) { root.currentView = 2; event.accepted = true }
        else if (event.key === Qt.Key_Escape) {
            GlobalStates.sidebarLeftOpen = false
            event.accepted = true
        }
    }

    // ── Layout: Rail | Content ───────────────────────────────────────
    NavigationRail {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        currentView: root.currentView
        onViewRequested: (index) => { root.currentView = index }
    }

    // ── Content area ─────────────────────────────────────────────────
    Item {
        id: contentArea
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        // View 0: Media (placeholder)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            color: "transparent"
            visible: root.currentView === 0
            opacity: root.currentView === 0 ? 1 : 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "MEDIA VIEW"
                    color: "#ff1100"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 2
                }
                Item { Layout.fillHeight: true }
                SystemStrip {}
            }

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        // View 1: Wallhaven (placeholder)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            color: "transparent"
            visible: root.currentView === 1
            opacity: root.currentView === 1 ? 1 : 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "WALLHAVEN VIEW"
                    color: "#ff1100"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 2
                }
                Item { Layout.fillHeight: true }
                SystemStrip {}
            }

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        // View 2: System (placeholder — SystemStrip excluded per spec)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            color: "transparent"
            visible: root.currentView === 2
            opacity: root.currentView === 2 ? 1 : 0

            Text {
                text: "SYSTEM VIEW"
                color: "#ff1100"
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 2
            }

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
        }
    }
}
