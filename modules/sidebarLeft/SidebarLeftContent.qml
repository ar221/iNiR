import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sidebarLeft.cockpit
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Left sidebar content — the Cockpit.
 *
 * Replaces the old TabBar + SwipeView drawer (pre-Cockpit-Campaign-2026-04) with
 * a single composed surface. All interaction happens within CockpitSurface; deep
 * views (YT Music, Wallhaven) expand in place rather than living as tabs.
 */
Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property int screenWidth: 1920
    property int screenHeight: 1080
    property var panelScreen: null

    function focusActiveItem() {
        cockpit.forceActiveFocus()
    }

    implicitHeight: bg.implicitHeight
    implicitWidth: bg.implicitWidth

    SidebarBackground {
        id: bg
        anchors.fill: parent
        side: "left"
        panelScreen: root.panelScreen
        screenWidth: root.screenWidth
        screenHeight: root.screenHeight
        sidebarWidth: root.sidebarWidth
        sidebarPadding: root.sidebarPadding

        CockpitSurface {
            id: cockpit
            anchors.fill: parent
            anchors.margins: root.sidebarPadding
            anchors.topMargin: Appearance.angelEverywhere ? root.sidebarPadding + 4
                : Appearance.inirEverywhere ? root.sidebarPadding + 6 : root.sidebarPadding
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.sidebarLeftOpen = false
            }
        }
    }
}
