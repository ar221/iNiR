pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.sidebarLeft
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

    // ── Background ───────────────────────────────────────────────────
    AmbientBackground {
        anchors.fill: parent
        z: 0
    }

    // ── Layout: Rail | Content ───────────────────────────────────────
    NavigationRail {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        currentView: root.currentView
        onViewRequested: (index) => { root.currentView = index }
        z: 1
    }

    // ── Content area ─────────────────────────────────────────────────
    Item {
        id: contentArea
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 1

        // View 0: Media
        MediaView {
            anchors.fill: parent
            anchors.margins: 12
            visible: root.currentView === 0
            opacity: root.currentView === 0 ? 1 : 0
            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        // View 1: Wallhaven
        Item {
            anchors.fill: parent
            visible: root.currentView === 1
            opacity: root.currentView === 1 ? 1 : 0

            // Wallhaven browser fills the content area
            WallhavenView {
                id: wallhavenView
                anchors.fill: parent
                anchors.margins: 4
                // Reserve space at the bottom for palette + system strip
                anchors.bottomMargin: paletteColumn.implicitHeight + 4 + 4
            }

            // Palette extract bar + SystemStrip pinned at bottom
            ColumnLayout {
                id: paletteColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                anchors.bottomMargin: 4
                spacing: 4
                z: 2

                PaletteExtractBar {}
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

        // View 2: System
        SystemView {
            anchors.fill: parent
            anchors.margins: 12
            visible: root.currentView === 2
            opacity: root.currentView === 2 ? 1 : 0
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
